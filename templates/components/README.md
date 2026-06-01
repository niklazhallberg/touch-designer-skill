# templates/components/

**Drop-in TD components captured from real production work.** Each one is a TDN-externalized COMP (JSON, diffable) with a companion pattern doc in `references/patterns/`.

The pattern doc is the **why** and **how to parameterize**. The .tdn is the **what** — drag it into your project, re-wire path references, dial in the custom params to your scene scale.

## Promotion rule

Components land here when **all three** are true:

1. The pattern was built in production at least once and verified working.
2. The accompanying pattern doc in `references/patterns/` is written and explains adaptation.
3. The component is generic enough that the next use will reasonably re-import it (vs rebuilding from scratch).

If 1 + 2 are true but 3 is iffy ("might just be one-off"), let the pattern doc stand alone — skip externalization until a second project triggers reuse.

## Conventions

- **Filenames:** kebab-case, describe the effect not the implementation. `hand-driven-camera-y.tdn`, not `cam_y_chop_chain.tdn`.
- **Path references inside:** the COMP's internal CHOP wiring will reference paths like `/project1/hand_control/pinch_lag` from the originating project. Always swap-and-re-wire after import. Note the path-refs in the corresponding `references/patterns/*.md`.
- **Companion pattern doc is mandatory.** No `.tdn` without `.md`. If the pattern can't be explained in prose, it can't be re-parameterized later.

## Current components

| Component | Pattern doc | Source project | Captured |
|---|---|---|---|
| `hand-driven-camera-y.tdn` | `references/patterns/hand-driven-camera-controls.md` | RADON_TREE (formerly BANG_RFSU), 2026-05-31 | 2026-06-01, refactored for portability (Handsource custom param + relative sibling refs) before commit |

## Portability convention (verified on hand-driven-camera-y.tdn)

Components in this directory MUST pass these checks before commit:

1. **No absolute filesystem paths** anywhere in the JSON (no `/Users/`, no project-folder names like `/RADON_TREE/`, no asset filenames like `.ply` / `.toe`).
2. **No absolute `/project1/...` paths** in operational fields. Help-text documentation may reference example paths for clarity — that's text, not binding.
3. **External dependencies parameterized** via custom params on the COMP (e.g. `Handsource` CHOP-style param), with `val=''` and `default=''` so the importer is forced to wire after import.
4. **Internal sibling references** stored as relative leaf names (`apply`, not `/project1/camera_control/apply`).
5. **Custom params drive internal ops** via `parent().par.X` expressions — not hardcoded constants.

Quick verification grep before committing any new component:

```bash
f=templates/components/<your-component>.tdn
grep -nE "/project1/|/Users/|/RADON_|/BANG_|\.ply|\.toe" "$f" | grep -v '"help":'
# Expected: no hits outside of help-text strings
```
