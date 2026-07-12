# Project Rules

This is a Godot 4.4 project.

The highest priority is keeping the project buildable at every step.

## Workflow

NEVER perform large refactors.

Fix ONE category of errors at a time.

After every small change:

1. Save files.
2. Run Godot.
3. Verify parse errors decreased.
4. Continue only if project still opens.

If parse errors increase:
STOP.
Explain why.
Do not continue.

---

## Forbidden

Do NOT rewrite systems.

Do NOT regenerate sprites.

Do NOT regenerate audio.

Do NOT redesign gameplay.

Do NOT rename files unless absolutely necessary.

Do NOT change APIs unless required.

---

## Required

Always prefer minimal edits.

Preserve scene hierarchy.

Preserve filenames.

Preserve exported variables.

Preserve resource paths.

---

## Error priority

1. Parse errors
2. Resource loading
3. Scene loading
4. Runtime crashes
5. Gameplay bugs
6. Optimization
7. Polish

Never skip priorities.

---

## Validation

After each batch:

- launch Godot
- ensure parse error count decreased
- ensure no new parse errors
- commit progress

Never continue blindly.

---

## Git

Before risky edits create a commit.

Never modify more than 5 files in one batch.

---

## Reporting

After every batch output:

Files changed

Errors fixed

Remaining errors

Next batch