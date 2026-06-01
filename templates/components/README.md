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
| `hand-driven-camera-y.tdn` (capture deferred — TD was mid-load when first attempted; pattern doc complete and shippable independently) | `references/patterns/hand-driven-camera-controls.md` | RADON_TREE (formerly BANG_RFSU), 2026-05-31 | TBD — re-attempt when TD is idle |
