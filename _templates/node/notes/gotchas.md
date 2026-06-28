# notes/gotchas.md — __PROJECT_TITLE__

Append a short entry whenever you hit something non-obvious. Future
agents (and you) will thank past you.

Format:

```
## YYYY-MM-DD — <short title>
Problem: <one sentence>
Fix:     <one sentence>
Future:  <what next time's agent should do differently>
```

---

## Examples (delete these once you've added real entries)

## 2026-06-28 — pnpm dlx couldn't import vitest from CWD
Problem: `pnpm dlx vitest run` fails with ERR_MODULE_NOT_FOUND because
         pnpm's dlx store isn't in node_modules of the calling project.
Fix:     Use `npm install vitest && npx vitest run` for ephemeral test
         environments where node_modules has to be local.
Future:  Prefer npm over pnpm for "install vitest into a scratch dir
         and run it" patterns; pnpm 11's build-script policy makes this
         worse.
