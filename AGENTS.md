# AGENTS.md

## About

A Claude Code plugin marketplace. Each plugin under `plugins/` is
standalone; the marketplace and the plugins are read straight from
`main`. Plugin conventions are in [plugins/README.md](plugins/README.md).

## Layout

- `.claude-plugin/marketplace.json` is the marketplace manifest
  (`cgraf78-claude-plugins`). Each entry's `name` must match the
  plugin's own manifest name.
- `plugins/<name>/.claude-plugin/plugin.json` is the plugin manifest.
  It needs a non-empty `version` and a `skills` entry.
- `plugins/<name>/{README.md,scripts/,skills/}` hold the plugin's docs,
  scripts, and skills (for example, `status-line-setup`).
- `install.sh` is hand-written, not a generated installer.
- `test/claude-plugins-test` is the only test runner.

## Invariants

- Bump `plugin.json` `version` on any user-visible plugin change;
  `claude plugin update` keys on it.
- Keep plugin docs inside the plugin directory.
- Scripts must not depend on the author's dotfiles.
- `install.sh`'s exact `claude plugin` command sequence is pinned by the
  test; change both together.

## Testing

Identical locally and in CI (shared full matrix, profiles
`base,shellcheck,jq`); it needs `jq` and `shellcheck`:

```sh
test/claude-plugins-test
```

It checks:

- `bash -n` and `shellcheck -x` on every `git ls-files '*.sh'` file plus
  the runner itself, so `git add` a new script before running it, or it
  is not linted (no `-P SCRIPTDIR`);
- marketplace and plugin-manifest consistency;
- the installer's exact `claude plugin` calls, and its failure when
  `marketplace.json` can't be fetched;
- status-line rendering and caching.

## Test isolation

The test puts fake `claude` and `curl` first on `PATH` and runs the
status line with a temporary `HOME` and `XDG_CACHE_HOME`. Never run
`install.sh` or `claude plugin` against a real Claude configuration.

## CI and generated files

- `.github/cgraf78-actions.lock` and every `uses: cgraf78/actions/...@sha`
  move together, only via `consumer-ci/sync.sh` from cgraf78/actions;
  the `actions-sync` job checks them. There is no ShellCheck inventory
  file and no generated installer here.
- `retry-infrastructure.yml` keys on the workflow name `Tests`; don't
  rename it.

## Release

None; the marketplace reads `main`.
