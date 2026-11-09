# Smoke — manual test plan

Number range **T-001 – T-009** (registry: [README.md](README.md)).

| ID | Precondition | Steps | Expected | Status |
|----|--------------|-------|----------|--------|
| T-001 | fresh install | start app | LumbreCode splash (localized animation), then app phase, then first screen | active |
| T-002 | app running | switch language in settings | UI switches immediately; choice survives an app restart | active |
| T-003 | app running | toggle OS dark mode | app follows the system theme | active |
