# Plugins

Each subdirectory is a standalone Claude plugin with its own
`.claude-plugin/plugin.json`, README, scripts, and optional skills.

## Conventions

- Keep plugin-specific setup and user documentation inside the plugin
  directory.
- Shared marketplace metadata lives in the root `.claude-plugin/` directory.
- Scripts should be executable, self-contained, and avoid depending on the
  developer's dotfiles unless the plugin README documents that dependency.
- Skills should describe the user-facing workflow and delegate implementation
  details to scripts when possible.

The root `install.sh` installs or refreshes the plugin collection from this
repo. Update it when adding a plugin that needs special installation behavior.
