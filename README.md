# TouchDesigner Skill for Claude Code

![Status: active](https://img.shields.io/badge/status-active-brightgreen)
![Version 0.2.0](https://img.shields.io/badge/version-0.2.0-blue)
![Platform: Apple Silicon](https://img.shields.io/badge/platform-Apple%20Silicon-black)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)

A **self-improving Claude Code skill** that lets Claude build, modify, and debug **[TouchDesigner](https://derivative.ca)** projects on Apple Silicon. It drives TouchDesigner live through the **Embody + Envoy MCP** bridge and gets a little sharper after every project.

> **New to the terms?** TouchDesigner is a node-based environment for real-time graphics and interactive installations. A Claude Code *skill* is a knowledge pack that Claude loads when a task calls for it. *MCP* is the protocol that lets Claude call tools, in this case tools that create, wire, and inspect TouchDesigner operators in a running project.

## What this is

This repo holds the recipes, rules, and hard-won gotchas that Claude loads when it detects a TouchDesigner context: a `.toe` file, an `.embody/` folder, or the word "TouchDesigner". With the Embody component loaded in a project, Claude can inspect the network, create and wire operators, run Python, and debug issues, instead of you doing every click by hand.

It grew out of one artist's production work, but everything in it is written to be project-agnostic: patterns, decision rules ("when to use X vs Y"), and gotchas that generalize across TouchDesigner projects.

**What it knows today:** 7 workflow skills, 4 rule sets, 20 reference banks, and a flat index of about 50 named decision rules. Coverage includes POPs, GLSL, Python architecture, audio-reactive systems, projection mapping, MediaPipe hand tracking, Gaussian splatting on Mac, and StreamDiffusion. The bulk of it was captured from real sessions, and each entry is tagged with how it was verified.

## How it's self-improving

"Self-improving" is a concrete, documented mechanism, not model training. During real sessions, Claude captures generalizable discoveries *in flow*, following the [skill-growth protocol](references/skill-growth-protocol.md):

1. **Trigger:** something non-trivial was solved, for example several probe→fix cycles, reality contradicting the model, or a non-obvious workaround.
2. **Generalize:** strip project names and one-off numbers. If it can't be stated generically, it stays in the project.
3. **Gate:** three silent checks. Was both the failure and the fix observed? Does the rule fit in one sentence? Was it genuinely new?
4. **Ask:** the human approves before anything is written.
5. **Record:** the entry goes into `references/` and is logged in [`CHANGELOG.md`](CHANGELOG.md), tagged by evidence strength: own testing (trusted), external source ("verify before relying"), or both.
6. **Sync:** a `SessionStart` hook (`scripts/session-sync.sh`) pulls the latest knowledge and announces new learnings, so improvements travel across machines via git.

## Requirements

- **macOS on Apple Silicon** (M-series). Several patterns are Mac-specific, and some TouchDesigner features (e.g. POPs) crash on Intel/AMD Macs.
- **TouchDesigner 2025.32820** or later
- **[Claude Code](https://claude.com/claude-code)**
- **[Embody](https://github.com/dylanroscover/Embody) v5.0.413+**: a TouchDesigner component (`.tox`) that externalizes the network to git-trackable files and hosts the Claude integration
- **Envoy MCP bridge**: ships with Embody and runs on `localhost:9870`

## Install

```sh
git clone https://github.com/niklazhallberg/touch-designer-skill \
  ~/.claude/skills/touch-designer-skill
```

Optional: add the `SessionStart` hook to `~/.claude/settings.json` to auto-sync learnings. The exact JSON snippet is in the header of [`scripts/session-sync.sh`](scripts/session-sync.sh).

## Start a new TouchDesigner project

```sh
cd ~/Projects/
~/.claude/skills/touch-designer-skill/scripts/td-new my-project
cd my-project
```

Then, in TouchDesigner: **Save As** → `my-project.toe`, drag in **Embody.tox** ([releases](https://github.com/dylanroscover/Embody/releases)), and set `Aiclient=claude`. Run `claude` in the project folder, and Claude can now drive the project through Envoy.

`td-new` scaffolds the folder, initializes git with a sensible `.gitignore`, and drops in a per-project `.claude/settings.local.json` that pre-approves the Envoy tools. Shell commands still ask for confirmation. See [`templates/td-project/`](templates/td-project/) for exactly what it copies, and the [security note](#security-note) for the optional fast path.

## What's in here

| Path | Contents |
|---|---|
| [`SKILL.md`](SKILL.md) | The front door: triggers, mandatory reads, reference lookup table, named decision-rule index |
| [`skills/`](skills/) | Workflow recipes loaded on demand: `create-operator`, `debug-operator`, `externalize-operator`, `create-extension`, `manage-annotations`, plus MCP-tool and TD-API references |
| [`rules/`](rules/) | Operational rules: parameter design, network layout, TD-Python, MCP safety |
| [`references/`](references/) | Knowledge banks: gotchas, patterns, per-component notes, the growth protocol |
| [`scripts/`](scripts/) | `td-new` (project scaffold) and `session-sync.sh` (SessionStart hook) |
| [`templates/`](templates/) | The starter project shell, plus portable components (`.tdn`) |
| [`CHANGELOG.md`](CHANGELOG.md) | The skill's learning log: every captured discovery, with source and confidence |
| [`ROADMAP.md`](ROADMAP.md) | Deferred work, each item with the real-world trigger that brings it back into scope |

## Design decisions

- **Central knowledge, per-project state.** Cross-project knowledge lives in this repo. Everything project-specific (the `.toe`, Embody's generated `CLAUDE.md` and `.claude/` files, runtime caches) lives with the project.

  | Lives in this repo (user-level) | Lives per TD project (mostly generated by Embody) |
  |---|---|
  | `SKILL.md`, `skills/`, `rules/`, `references/` | `<project>.toe`, `.mcp.json`, `.embody/` |
  | `CHANGELOG.md` (learning log) | `CLAUDE.md`, `AGENTS.md`, `.claude/skills/`, `.claude/rules/` |
  | `scripts/`, `templates/` | `.venv/`, `Backup/`, `TDImportCache/`, `logs/` |

- **Explicit conflict rule.** When a project-local file generated by Embody disagrees with the central skill, central wins for *additive* knowledge and project-local wins for *workflow*, because Embody knows the project's tool versions. Conflicts are surfaced, never silently averaged.
- **Evidence over volume.** Knowledge is captured when it's earned in production, not bulk-imported from docs. [`ROADMAP.md`](ROADMAP.md) deliberately defers topics until a real project triggers them, so entries can be written with high confidence.
- **Findability as a feature.** Decision rules are buried in long reference files by nature, so `SKILL.md` keeps a flat index of about 50 "X vs Y" rules that points to their source sections.
- **No project content.** Pipeline specs, phase plans, and anything that only fits one project belong in that project's repo. If an entry can't be stated without a project name or scene-specific numbers, it isn't skill content.

## Scope & limitations

- **Apple Silicon only.** The skill has not been tested on Windows or Intel Macs, and several entries are Mac-specific by design.
- **Single-user workflow.** The growth protocol assumes one maintainer approving entries. A team-scaling path is noted but not built.
- **Tied to Embody/Envoy.** Without the bridge, the skill is still useful as reference material, but Claude can't act on the live network.
- Knowledge reflects TouchDesigner 2025.x. Entries from external sources are marked "verify before relying".

## Security note

The Envoy bridge listens on localhost without authentication, and `execute_python` runs unsandboxed inside the TouchDesigner process. Treat both accordingly.

**Default:** the project template's [`settings.local.json`](templates/td-project/.claude/settings.local.json) pre-approves the Envoy MCP tools, including `execute_python`, because live network iteration is unusable without them. It does **not** pre-approve `Bash`, so every shell command asks first.

**Opt-in fast path (trusted single-user workstation):** if you want Claude to also run shell commands without prompts, replace the project's settings with the fast-path example. It is identical except that it adds `Bash`:

```sh
cp ~/.claude/skills/touch-designer-skill/templates/td-project/.claude/settings.trusted-fastpath.example.json \
  .claude/settings.local.json
```

`settings.local.json` is git-ignored in scaffolded projects, so this choice stays on your machine.

## Contributing

Issues and pull requests are welcome. The knowledge banks follow the [skill-growth protocol](references/skill-growth-protocol.md). If you add a learning, tag it by evidence strength (own testing vs. external source) and log it in `CHANGELOG.md` so its provenance stays clear.

## License

[MIT](LICENSE) © Niklaz Hallberg · [niklaz.a.hallberg@gmail.com](mailto:niklaz.a.hallberg@gmail.com)

## Acknowledgments

- [Derivative](https://derivative.ca), makers of TouchDesigner.
- [Embody](https://github.com/dylanroscover/Embody) and its Envoy MCP bridge by [Dylan Roscover](https://github.com/dylanroscover), the components that make live Claude ↔ TouchDesigner control possible.
