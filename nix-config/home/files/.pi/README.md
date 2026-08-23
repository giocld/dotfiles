# .pi

Global pi config, managed via nix (home-manager) and installed into `~/.pi`.

## Extension dependency workspace

Package-style global extensions stay in `agent/extensions/` so pi can still auto-discover them from:

- `~/.pi/agent/extensions/*.ts`
- `~/.pi/agent/extensions/*/index.ts`

This directory is the shared npm workspace root for extensions with their own `package.json` files.

Install or refresh all extension dependencies from here:

```bash
npm install
```

Run workspace checks:

```bash
npm run check
```

Current workspace-managed extensions live under:

- `agent/extensions/pi-skill-toggle`
- `agent/extensions/save-md`
- `agent/extensions/pi-worktrees`
- `agent/extensions/handoff`

Standalone extensions:

- `agent/extensions/continue-after-compaction.ts`
- `agent/extensions/git-interceptor.ts`
- `agent/extensions/herdr-agent-state.ts`
- `agent/extensions/whimsical.ts`

After changing extension code or package settings, reload pi with `/reload`.