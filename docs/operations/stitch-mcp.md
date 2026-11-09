# Google Stitch integration (MCP)

[Google Stitch](https://stitch.withgoogle.com) generates UI designs from
natural-language prompts. Via the Stitch MCP server, coding agents (Claude
Code, Copilot/VS Code, Codex, Cursor, Gemini CLI) can pull those designs —
screenshots, HTML exports, colors, typography — directly into this repo.

## Configuration in this repo

The MCP server is pre-configured for all three agent setups; no key is
committed:

| Client | Config file |
|---|---|
| Claude Code | `.mcp.json` (repo root) |
| VS Code / Copilot agent mode | `.vscode/mcp.json` |
| Codex | `.codex/config.toml` (`[mcp_servers.stitch]`) |

All three launch the same server: `npx -y @_davideast/stitch-mcp proxy`.
Node.js 20+ must be on PATH.

## One-time authentication (per developer)

Pick one:

1. **Guided setup (recommended):**

   ```bash
   npx @_davideast/stitch-mcp init
   ```

   Walks through gcloud installation, Google OAuth, and project selection.

2. **API key:** generate a key in the Stitch settings panel and export it as
   `STITCH_API_KEY` in your shell environment. Never commit the key.

3. **Existing gcloud login:** set `STITCH_USE_SYSTEM_GCLOUD=1` in your
   environment.

Verify: restart your agent client; the `stitch` MCP server should list tools
such as `get_screen_code`, `get_screen_image`, and `build_site`.

## Design-to-code workflow (this template)

1. **Design in Stitch** — create/iterate screens with prompts at
   stitch.withgoogle.com (or let the agent call the generation tool).
2. **Import artifacts** — the agent fetches per screen:
   - screenshot → `design/screenshots/`
   - HTML export → `design/exported/`
   - extracted design context (colors, typography, spacing) → note in
     `design/` next to the artifacts
   Register every imported file in a manifest under `design/manifests/`
   (versioning rules: ADR-0004, `design/README.md`).
3. **Map to the design system** — translate the extracted design tokens into
   `packages/design_system` (theme colors, text styles, spacing constants).
4. **Implement in Flutter** — build the screens feature-first in
   `apps/mobile_app` using the design system.

## Rules for agents

- Stitch output (HTML/CSS/Tailwind) is a **design reference, never app
  code**. This is a Flutter app: re-implement screens with widgets from
  `packages/design_system`; do not port or embed the generated HTML.
- Imported artifacts are versioned design inputs under `design/` with a
  manifest entry — the same rules as hand-made mockups (ADR-0004).
- Design tokens flow through `packages/design_system`, never as hard-coded
  values inside features.
- Never commit `STITCH_API_KEY` or gcloud credentials.
- Stitch is a **dev-time tool**: nothing from it may become a runtime
  dependency of the app (privacy-by-default stays intact).
