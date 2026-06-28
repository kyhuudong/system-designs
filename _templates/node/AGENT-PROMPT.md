# AGENT-PROMPT.md — __PROJECT_TITLE__

Copy-paste this into a fresh agent session to bootstrap the agent fast.
Edit the bracketed parts.

---

````
I'm working on __CATEGORY__/__PROJECT_NAME__ in the system-designs
repo. Read these first, in order:

1. /Users/dong.kyh/works/system-designs/AGENTS.md
2. ./AGENTS.md (this project's contract)
3. ./README.md (design doc)
4. ./DONE.md (stopping condition)
5. ./notes/gotchas.md (lessons from prior sessions)

My request: [WHAT YOU WANT THE AGENT TO DO]

Constraints:
- Follow the design-first rule. If the design doc is incomplete, fix it
  before writing code.
- Use the existing recipes in /Users/dong.kyh/works/system-designs/_recipes/
  before adding new dependencies.
- Update ./notes/gotchas.md when you encounter anything non-obvious.
- Update ./docs/adr/ for any non-obvious decision.
- When you think you're done, walk through ./DONE.md and confirm every
  checkbox.
````
