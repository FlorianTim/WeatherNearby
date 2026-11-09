# Drafts

> **⚠️ Nicht-normativ.** Alles in diesem Ordner ist unfertig, explorativ und nicht verbindlich.
> Agents und Entwickler sollen Drafts **nicht** in Entscheidungen, Implementierungen oder
> Antworten einbeziehen — es sei denn, sie werden explizit darauf hingewiesen.
> Siehe auch: ADR-0005.

## Unterordner

- `init/` — **Sonderfall, siehe unten**: das Eingangsmaterial für eine neue App
- `notes/` — schnelle Markdown-Notizen
- `prompts/` — Agent-/Copilot-/LLM-Prompts
- `experiments/` — technische oder inhaltliche Versuche
- `archive/` — abgelegte Entwürfe

## Sonderfall `init/`

`drafts/init/` ist die **einzige Ausnahme** von der Regel oben — in beide
Richtungen:

- Der Template-Initializer **liest** diesen Ordner. Er ist sein Input:
  Beschreibung, Notizen, Mockups, Icons, Ressourcen der neuen App.
- Er wird beim Erzeugen einer App **nicht gelöscht**, während der Rest von
  `drafts/` geleert wird. Erst wenn `drafts/init/processed.md` jede Zeile
  als `done` oder `dropped` ausweist, darf er weg.

Nicht-normativ bleibt er trotzdem: verbindlich ist erst die Spezifikation,
die daraus entsteht. Details in `drafts/init/README.md`.

## Obsidian-Hinweise

Dieser Ordner ist Obsidian-kompatibel:
- Alle Dateien sind Markdown
- Interne Links funktionieren relativ oder als Wikilinks
- Die Ordnerstruktur ist flach und navigierbar
- Keine Spezialformate, die außerhalb von Obsidian nicht lesbar sind
