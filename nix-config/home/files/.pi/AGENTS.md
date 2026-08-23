# PI AGENT WORKSPACE

npm workspace for pi agent extensions. TypeScript, ESM-only.

## STRUCTURE

```
.pi/
├── package.json          # Workspace root: workspaces = ["agent/extensions/*"]
├── tsconfig.json         # Strict, bundler mode, ESNext, noEmit
├── agent/
│   ├── settings.json     # Provider, model, theme, packages, interview config
│   ├── cloak.json        # Secret masking patterns for agent output
│   ├── themes/           # Custom themes (JSON, see theme-schema)
│   └── extensions/       # Local TypeScript extensions
│       ├── pi-skill-toggle/      # Skill discovery, toggle UI, frontmatter patching
│       ├── save-md/              # Save assistant responses as Markdown
│       ├── pi-worktrees/         # Git worktree management
│       ├── handoff/              # Session handoff
│       ├── pi-cloak/             # Secret cloaking extension
│       ├── git-interceptor.ts    # Standalone: git command interception
│       ├── whimsical.ts          # Standalone: whimsical diagram integration
│       └── ...
```

## WHERE TO LOOK

| Task | Location |
|------|----------|
| Change default model/provider | `agent/settings.json` |
| Add pi package | `agent/settings.json` → `packages[]` |
| Change theme | `agent/settings.json` → `theme` (themes in `agent/themes/`) |
| Create extension | `agent/extensions/<name>/` with `package.json` |
| Create standalone extension | `agent/extensions/<name>.ts` |
| Secret masking | `agent/cloak.json` |
| Type-check and test local packages | `npm run check` (from .pi root) |

## CONVENTIONS

- Extensions as npm workspace packages: each has own `package.json`
- Standalone extensions: single `.ts` file in `extensions/`
- ESM only: `"type": "module"` everywhere
- Dependencies: `@earendil-works/pi-ai`, `@earendil-works/pi-coding-agent`, `@earendil-works/pi-tui`
- TypeScript strict mode: `noUncheckedIndexedAccess`, `noImplicitOverride`

## ANTI-PATTERNS

- Installing deps at workspace root for extension-specific needs (use per-package)
- Committing `node_modules/` (gitignored per-extension)
- Treating `agent/settings.json`, `auth.json`, `models-store.json`, `sessions/` as config — they are runtime state, not nix-managed
- Adding runtime state files to git

## KEY SETTINGS

```jsonc
// agent/settings.json
{
  "defaultProvider": "opencode-go",
  "defaultModel": "ox-alpha-free",
  "defaultThinkingLevel": "high",
  "theme": "vague"
}
```

## GITIGNORE PATTERN

Most of `agent/` is gitignored by default. Tracked files are explicitly un-ignored:
- `agent/settings.json`, `agent/cloak.json`, `agent/tsconfig.json`, `agent/package.json`
- `agent/extensions/**` (but `node_modules/` within are re-ignored)
- `agent/themes/*.json`

## NOTES

- pi-skill-toggle has a full UI layer (overlay, render, view-model)