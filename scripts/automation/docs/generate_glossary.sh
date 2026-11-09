#!/usr/bin/env bash
# Generate 12-glossary.md from glossary.csv
# Usage: ./scripts/automation/docs/generate_glossary.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CSV="$REPO_ROOT/docs/architecture/glossary.csv"
OUT="$REPO_ROOT/docs/architecture/arc42/12-glossary.md"

if [ ! -f "$CSV" ]; then
  echo "ERROR: $CSV not found" >&2
  exit 1
fi

cat > "$OUT" << 'HEADER'
# 12. Glossar

> **Hinweis:** Diese Datei wird automatisch aus `docs/architecture/glossary.csv` generiert.
> Bearbeite die CSV-Datei, nicht dieses Markdown.

HEADER

# Read CSV, skip header, generate definition entries with explicit heading IDs
# Uses Python for correct quoted-CSV parsing so commas inside quoted fields work.
python3 - "$CSV" "$OUT" << 'PYEOF'
import csv, sys, re

csv_path, out_path = sys.argv[1], sys.argv[2]

def slugify(text):
    return re.sub(r'[^a-z0-9-]', '', text.lower().replace(' ', '-'))

with open(csv_path, newline='', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    with open(out_path, 'a', encoding='utf-8') as out:
        for row in reader:
            status = row.get('status', '').strip()
            if status not in ('accepted', ''):
                continue
            term       = row['term'].strip()
            definition = row['definition'].strip()
            context    = row.get('context', '').strip()
            source     = row.get('source', '').strip()
            aliases    = row.get('aliases', '').strip()
            slug       = slugify(term)

            out.write(f'\n### {term} {{#glossary-{slug}}}\n\n')
            out.write(f'{definition}\n\n')
            details = []
            if context: details.append(f'**Kontext:** {context}')
            if source:  details.append(f'**Quelle:** {source}')
            if aliases: details.append(f'**Aliase:** {aliases}')
            if details:
                out.write('  |  '.join(details) + '\n')
PYEOF

echo "" >> "$OUT"
echo "---" >> "$OUT"
echo "" >> "$OUT"
echo "*Generiert am $(date +%Y-%m-%d) aus \`docs/architecture/glossary.csv\`.*" >> "$OUT"

echo "Generated: $OUT"
