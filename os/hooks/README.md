# `os/hooks/`

Portable lifecycle hooks — bash scripts that any runtime adapter can wire into
its own lifecycle event system. Today this is empty because the only runtime
with concrete hook integration is Claude Code (see `.claude/hooks/`).

When other runtimes ship lifecycle support, hook bodies should be moved here
so adapters can install thin runtime-specific shims that call the portable
implementation.

Suggested structure (forward-looking):

```
os/hooks/
  session-start.sh        # context injection at session start
  pre-promote.sh          # validation before artifact promotion
  post-write-artifact.sh  # frontmatter check after write
```
