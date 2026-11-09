#!/usr/bin/env bash
# Shared shell function to read and validate project.env
# Usage: source "scripts/lib/read_env.sh" && read_project_env "/path/to/project.env"

read_project_env() {
  local env_file="$1"

  if [ ! -f "$env_file" ]; then
    echo "ERROR: project.env not found at: $env_file" >&2
    return 1
  fi

  # Source the file
  # shellcheck source=/dev/null
  source "$env_file"

  # Validate required variables
  if [ -z "$ORG" ]; then
    echo "ERROR: ORG not found in project.env" >&2
    return 1
  fi
  if [ -z "$PROJECT_NAME" ]; then
    echo "ERROR: PROJECT_NAME not found in project.env" >&2
    return 1
  fi

  # Optional keys with defaults (older project.env files may not define them)
  APP_PACKAGE="${APP_PACKAGE:-mobile_app}"

  return 0
}
