# Scripts

`sync-memory.sh` is the executable implementation behind the memory-sync
plugin. Keep the script safe to run repeatedly: it may be invoked by setup,
manual refreshes, or future automation.

Plugin behavior and user-facing setup belong in the plugin README and skill.
This directory should contain only executable helpers needed by the plugin.
