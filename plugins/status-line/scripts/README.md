# Scripts

`status-line.sh` renders the status-line output for the status-line plugin.

Keep this script fast and dependency-light because status-line integrations can
run frequently. Expensive discovery or setup belongs in the plugin's setup skill
or installation flow, not in the render path.
