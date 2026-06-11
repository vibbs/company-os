# `os/playbooks/`

Cross-runtime workflows referenced by skills — things that don't fit cleanly
as a skill (procedural) or a tool (deterministic), like interview scripts,
checklists, narrative templates, and shared examples.

A skill in `os/skills/` can point at a playbook here when a procedure step
expects content the agent should read verbatim or fill in.

This directory is intentionally light at first — add playbooks here as patterns
emerge from repeated skill content.
