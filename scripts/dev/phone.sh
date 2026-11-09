#!/usr/bin/env bash
# Flaky-USB-tolerant phone helper for agent sessions and quick manual checks.
# Every command first waits for the device (restarting the adb server once
# if nothing shows up), then retries on the transient "device not found /
# offline" errors a loose cable or an Android USB-mode switch produces.
# Output is kept short on purpose: one line per fact.
#
# Usage:
#   scripts/dev/phone.sh <command> [args]
#
# Commands:
#   status                 one line: serial, model, android, app version+state
#   wait [seconds]         block until a device is online (default 90 s)
#   install [apk]          adb install -r (default: debug APK), then start
#   start                  launch MainActivity
#   screenshot [file]      PNG to <file> (default: .buildlog/phone-<ts>.png)
#   pull-db [file]         copy the app database to <file> (default
#                          .buildlog/phone.sqlite) and print a short summary;
#                          shared-storage copy first, private copy (debug
#                          build, run-as) as fallback
#   db-sql "<sql>"         run a read-only query on a fresh pull of the database
#   logcat [seconds]       app-related errors of the last N seconds (default 120)
#   ls <path>              list a path on the device (default: shared root)
#   backup [dir]           copy BACKUP_PATHS of the shared folder to the laptop,
#                          default ~/<SHARED_STORAGE_DIR>-Backup/<serial>.
#                          One tar stream over adb for the files that are
#                          missing or differ in size (~15 MB/s instead of one
#                          adb round trip per file), live progress with MB/s
#                          and ETA, size check afterwards; re-run to resume.
#                          The database is always re-pulled (it changes while
#                          the app runs).
#   restore [dir]          push files from a backup that are MISSING on the
#                          device; never overwrites or deletes anything there
#   adb <args...>          any adb command on the resolved device, with retries
#
# Configuration (project.env, all optional):
#   SHARED_STORAGE_DIR     folder under /storage/emulated/0 the app uses for
#                          database + media (default: PROJECT_NAME)
#   DATABASE_FILE          drift database file name (default: app_database.sqlite)
#   BACKUP_PATHS           space-separated paths inside the shared folder to
#                          back up / restore (default: "db media")
# Environment:
#   PHONE_SERIAL           pin a serial; otherwise the only attached device
#   PHONE_TIMEOUT          wait timeout in seconds (default 90)
#   PHONE_SHARED_ROOT      full device path of the shared folder (overrides
#                          SHARED_STORAGE_DIR)
#   PHONE_BACKUP_PATHS     overrides BACKUP_PATHS for one call
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/common.sh"
# Git Bash rewrites /storage/... arguments into C:/Program Files/Git/storage
# before adb.exe sees them; device paths must pass through untouched. Local
# paths handed to adb are converted explicitly with native_path below.
export MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*'

usage() { sed -n '2,46p' "$0" | sed 's/^# \{0,1\}//'; }
[ $# -gt 0 ] || { usage; exit 1; }
case "$1" in -h|--help) usage; exit 0 ;; esac
CMD="$1"; shift

ADB="$(adb_bin)" || die "adb not found (install platform-tools or set ANDROID_SDK_ROOT)"
load_project_env
APP_ID="$ORG.$PROJECT_NAME"
SHARED_ROOT="${PHONE_SHARED_ROOT:-/storage/emulated/0/${SHARED_STORAGE_DIR:-$PROJECT_NAME}}"
DB_FILE="${DATABASE_FILE:-app_database.sqlite}"
BACKUP_PATHS="${PHONE_BACKUP_PATHS:-${BACKUP_PATHS:-db media}}"
TIMEOUT="${PHONE_TIMEOUT:-90}"
OUT_DIR="$REPO_ROOT/.buildlog"
mkdir -p "$OUT_DIR"

# Windows-native form of a local path for adb.exe; unchanged elsewhere.
native_path() { cygpath -w "$1" 2>/dev/null || printf '%s' "$1"; }

local_size() { wc -c < "$1" | tr -d ' '; }

# Serial of the one online device, or empty. (awk collects instead of
# `exit`ing early: an early exit would SIGPIPE adb under `pipefail`.)
online_serial() {
  if [ -n "${PHONE_SERIAL:-}" ]; then
    "$ADB" devices | awk -v s="$PHONE_SERIAL" '$1==s && $2=="device" {print $1}'
  else
    "$ADB" devices | awk 'NR>1 && $2=="device" && !found {found=$1} END {if (found) print found}'
  fi
}

# Waits up to $TIMEOUT seconds; restarts the adb server once halfway through,
# because a stale server is the other common cause of an empty device list.
wait_device() {
  local waited=0 restarted=0 serial
  while :; do
    serial="$(online_serial || true)"
    [ -n "$serial" ] && { printf '%s' "$serial"; return 0; }
    if [ "$waited" -ge "$TIMEOUT" ]; then
      die "no device online after ${TIMEOUT}s (cable? USB mode 'file transfer'? debugging authorised?)"
    fi
    if [ "$restarted" -eq 0 ] && [ "$waited" -ge $((TIMEOUT / 2)) ]; then
      "$ADB" kill-server >/dev/null 2>&1 || true
      "$ADB" start-server >/dev/null 2>&1 || true
      restarted=1
    fi
    sleep 3; waited=$((waited + 3))
  done
}

# Runs adb on the device; on a transient connection error waits again and
# retries (3 attempts). Anything else fails immediately. Device output is
# CRLF; the CR is stripped so callers can compare and parse it.
adb_retry() {
  local attempt serial output status
  for attempt in 1 2 3; do
    serial="$(wait_device)"
    set +e
    output="$("$ADB" -s "$serial" "$@" 2>&1)"; status=$?
    set -e
    output="${output//$'\r'/}"
    if [ "$status" -eq 0 ]; then printf '%s\n' "$output"; return 0; fi
    if printf '%s' "$output" | grep -qiE "not found|offline|closed|no devices|device unauthorized|protocol fault"; then
      warn "adb lost the device (attempt $attempt/3): $(printf '%s' "$output" | tail -1)"
      sleep 3
      continue
    fi
    printf '%s\n' "$output" >&2
    return "$status"
  done
  die "adb kept losing the device"
}

# Binary-safe stream from the device (exec-out); same retry policy.
adb_stream() {
  local attempt serial
  for attempt in 1 2 3; do
    serial="$(wait_device)"
    if "$ADB" -s "$serial" exec-out "$@"; then return 0; fi
    warn "adb stream failed (attempt $attempt/3)"; sleep 3
  done
  die "adb kept losing the device"
}

device_has_file() { adb_retry shell "test -f '$1'" >/dev/null 2>&1; }

# Database to a local file: shared copy when the app keeps it there
# (readable without run-as, release builds included), else the private one.
pull_database() {
  local file="$1"
  if device_has_file "$SHARED_ROOT/db/$DB_FILE"; then
    adb_stream cat "$SHARED_ROOT/db/$DB_FILE" > "$file"
  else
    adb_stream run-as "$APP_ID" cat "app_flutter/$DB_FILE" > "$file"
  fi
  [ -s "$file" ] || die "empty database pull (private copy needs a debug build for run-as)"
}

# "<size> <path>" per file below a device directory, CR-free.
device_listing() {
  adb_retry shell "find '$1' -type f -exec stat -c '%s %n' {} +"
}

# "<size> <relative path>" for every file under the configured BACKUP_PATHS,
# relative to the shared root. A configured path that does not exist on the
# device is reported once and skipped.
backup_listing() {
  local path
  for path in $BACKUP_PATHS; do
    if adb_retry shell "test -e '$SHARED_ROOT/$path'" >/dev/null 2>&1; then
      device_listing "$SHARED_ROOT/$path" | sed "s|^\([0-9]*\) $SHARED_ROOT/|\1 |"
    else
      warn "not on the device, skipped: $SHARED_ROOT/$path"
    fi
  done
}

# stdin -> stdout unchanged, progress on stderr: percent, MiB, MB/s, ETA.
# Python keeps this portable (no pv on Git Bash); without python the stream
# simply runs silently.
progress_meter() {
  local total="$1" meter="$OUT_DIR/progress-meter.py"
  if have python; then
    # Written to a file: a heredoc would occupy stdin, which carries the data.
    cat > "$meter" <<'PY'
import sys, time
total = int(sys.argv[1]); done = 0; start = last = time.time()
inp, out = sys.stdin.buffer, sys.stdout.buffer
while True:
    chunk = inp.read(1 << 20)
    if not chunk:
        break
    out.write(chunk); done += len(chunk)
    now = time.time()
    if now - last >= 0.5:
        last = now; rate = done / max(now - start, 1e-6)
        eta = (total - done) / rate if rate > 0 and total > done else 0
        sys.stderr.write('\r     %3d%%  %6.0f/%.0f MiB  %5.1f MB/s  ETA %d:%02d   ' % (
            min(100, 100 * done // max(total, 1)), done / 1048576, total / 1048576,
            rate / 1e6, eta // 60, eta % 60))
        sys.stderr.flush()
out.flush()
sys.stderr.write('\r     100%%  %6.0f MiB in %.0f s                          \n' % (done / 1048576, time.time() - start))
PY
    python -u "$(native_path "$meter")" "$total"
  else
    cat
  fi
}

case "$CMD" in
  wait)
    TIMEOUT="${1:-$TIMEOUT}"
    ok "$(wait_device) online"
    ;;

  status)
    serial="$(wait_device)"
    model="$(adb_retry shell getprop ro.product.model)"
    release="$(adb_retry shell getprop ro.build.version.release)"
    version="$(adb_retry shell dumpsys package "$APP_ID" | awk '/versionName=/ && !v {sub(/.*versionName=/, ""); v=$0} END {print v}')"
    pid="$(adb_retry shell pidof "$APP_ID" || true)"
    printf '%s %s Android %s | %s %s %s\n' "$serial" "$model" "$release" "$APP_ID" \
      "${version:-not installed}" "${pid:+running (pid $pid)}${pid:-stopped}"
    ;;

  install)
    apk="${1:-$(app_dir)/build/app/outputs/flutter-apk/app-debug.apk}"
    [ -f "$apk" ] || die "APK not found: $apk"
    adb_retry install -r "$(native_path "$apk")" | tail -1
    adb_retry shell am start -W -n "$APP_ID/.MainActivity" | grep -E "Status|Error"
    ;;

  start)
    adb_retry shell am start -W -n "$APP_ID/.MainActivity" | grep -E "Status|Error"
    ;;

  screenshot)
    file="${1:-$OUT_DIR/phone-$(date +%Y%m%d-%H%M%S).png}"
    adb_stream screencap -p > "$file"
    ok "$file ($(local_size "$file") bytes)"
    ;;

  pull-db)
    file="${1:-$OUT_DIR/phone.sqlite}"
    pull_database "$file"
    ok "$file ($(local_size "$file") bytes)"
    if have python; then
      python - "$(native_path "$file")" <<'PY'
import sqlite3, sys
c = sqlite3.connect(sys.argv[1])
print('schema v%s' % c.execute('pragma user_version').fetchone()[0])
tables = [r[0] for r in c.execute("select name from sqlite_master where type='table'")]
if 'media_entries' in tables:
    for row in c.execute('select status, coalesce(error_code, "-"), count(*), sum(received)/1048576 from media_entries group by 1, 2'):
        print('  %-12s %-18s %4d rows %6d MiB' % row)
else:
    print('  tables: ' + ', '.join(tables))
PY
    fi
    ;;

  db-sql)
    [ $# -ge 1 ] || die "usage: phone.sh db-sql \"<sql>\""
    file="$OUT_DIR/phone.sqlite"
    pull_database "$file"
    have python || die "python required"
    python - "$(native_path "$file")" "$1" <<'PY'
import sqlite3, sys
c = sqlite3.connect(sys.argv[1])
for row in c.execute(sys.argv[2]):
    print(' | '.join(str(v) for v in row))
PY
    ;;

  logcat)
    seconds="${1:-120}"
    now="$(adb_retry shell date +%s)"
    since="$(adb_retry shell date -d "@$((now - seconds))" '+%m-%d %H:%M:%S.000')"
    adb_retry logcat -d -t "$since" 2>/dev/null \
      | grep -E "$APP_ID|AudioService|MediaSession|FATAL|AndroidRuntime|flutter" \
      | grep -iE "error|exception|fatal|denied|fail|MediaFailure" \
      | grep -v "hiddenapi" | tail -40 || true
    ;;

  ls)
    adb_retry shell ls -la "${1:-$SHARED_ROOT}"
    ;;

  backup)
    serial="$(wait_device)"
    target="${1:-$HOME/${SHARED_STORAGE_DIR:-$PROJECT_NAME}-Backup/$serial}"
    mkdir -p "$target"
    have tar || die "tar not found on this machine"
    listing="$OUT_DIR/backup-listing.txt"
    wanted="$OUT_DIR/backup-wanted.txt"
    backup_listing > "$listing"
    total=$(wc -l < "$listing" | tr -d ' ')
    [ "$total" -gt 0 ] || die "nothing to back up under $SHARED_ROOT ($BACKUP_PATHS)"
    # Only what is missing or differs in size goes over the wire. The
    # database lives in db/ and changes while the app runs: always taken.
    : > "$wanted"; need_bytes=0; skipped=0
    while read -r size rel; do
      [ -n "$rel" ] || continue
      case "$rel" in db/*) ;; *)
        if [ -f "$target/$rel" ] && [ "$(local_size "$target/$rel")" = "$size" ]; then
          skipped=$((skipped + 1)); continue
        fi ;;
      esac
      printf '%s\n' "$rel" >> "$wanted"; need_bytes=$((need_bytes + size))
    done < "$listing"
    wanted_count=$(wc -l < "$wanted" | tr -d ' ')
    info "$total files on the device, $skipped already present, $wanted_count to copy ($((need_bytes / 1048576)) MiB)"
    if [ "$wanted_count" -gt 0 ]; then
      # The file list is pushed to the device's scratch directory (not app
      # data) and read by toybox tar; nothing under the shared root is written.
      remote_list="/data/local/tmp/$PROJECT_NAME-backup-list.txt"
      adb_retry push "$(native_path "$wanted")" "$remote_list" >/dev/null
      serial="$(wait_device)"
      # tar stream -> progress -> extract; a dropped cable leaves the current
      # file short, which the size check below reports and a re-run repeats.
      "$ADB" -s "$serial" exec-out "cd '$SHARED_ROOT' && tar -cf - -T '$remote_list'" \
        | progress_meter "$need_bytes" \
        | (cd "$target" && tar -xf -) || warn "stream ended early"
      adb_retry shell "rm -f '$remote_list'" >/dev/null 2>&1 || true
    fi
    failed=0; bytes=0
    while read -r size rel; do
      [ -n "$rel" ] || continue
      if [ -f "$target/$rel" ]; then
        actual=$(local_size "$target/$rel"); bytes=$((bytes + actual))
        case "$rel" in db/*) ;; *) [ "$actual" = "$size" ] || { warn "size mismatch: $rel"; failed=$((failed + 1)); } ;; esac
      else
        warn "missing after copy: $rel"; failed=$((failed + 1))
      fi
    done < "$listing"
    ok "$target: $((total - failed))/$total files ($((bytes / 1048576)) MiB), $wanted_count copied, $skipped already present, $failed failed"
    [ "$failed" -eq 0 ] || die "re-run to retry the failed files"
    ;;

  restore)
    serial="$(wait_device)"
    source_dir="${1:-$HOME/${SHARED_STORAGE_DIR:-$PROJECT_NAME}-Backup/$serial}"
    [ -d "$source_dir" ] || die "backup not found: $source_dir"
    # Only files the device lacks are pushed: an existing file is never
    # replaced (it may be newer), nothing is deleted. The database goes
    # last so the app never sees rows for media that is still arriving.
    listing="$OUT_DIR/restore-listing.txt"
    backup_listing > "$listing" 2>/dev/null || : > "$listing"
    pushed=0; present=0
    while IFS= read -r local_file; do
      rel="${local_file#"$source_dir"/}"
      if grep -qF " $rel" "$listing"; then present=$((present + 1)); continue; fi
      adb_retry shell "mkdir -p '$(dirname "$SHARED_ROOT/$rel")'" >/dev/null
      adb_retry push "$(native_path "$local_file")" "$SHARED_ROOT/$rel" >/dev/null
      pushed=$((pushed + 1))
    done < <(find "$source_dir" -type f ! -path "*/db/*" | sort; find "$source_dir/db" -type f 2>/dev/null)
    ok "$SHARED_ROOT: $pushed files pushed, $present already on the device"
    ;;

  adb)
    adb_retry "$@"
    ;;

  *)
    usage; exit 1 ;;
esac
