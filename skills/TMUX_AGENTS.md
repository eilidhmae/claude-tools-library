# Claude tmux Workflow

## Detecting tmux

On startup, check if running inside tmux:
```bash
[ -n "$TMUX" ] && echo "in tmux"
```
If inside tmux, apply the tmux workflow below.

## Pane Naming Convention

- My (Claude's) control pane: `claude-control`
- Sub-agent worker panes: `worker-1`, `worker-2`, `worker-3`, ...
- Use **dashes only** as field separators in pane names.
- Set pane titles on startup:
  ```bash
  tmux select-pane -T "claude-control"
  tmux set-option -w pane-border-status top
  tmux set-option -w pane-border-format " #{pane_title} "
  tmux set-option -g status-style bg=magenta,fg=white
  tmux set-option -g mode-keys vi
  ```

## Sub-Agent Workflow

When asked to run a sub-agent or do research/work in parallel:

1. **Create a new pane** (split or new window):
   ```bash
   tmux split-window -h   # or -v for vertical
   ```
2. **Assign the next available worker number** by checking `/tmp/claude-workers.json`.
3. **Name the pane** and register it:
   ```bash
   tmux select-pane -t <pane_id> -T "worker-N"
   ```
4. **Write the task to the worker registry** at `/tmp/claude-workers.json`:
   ```json
   { "worker-1": { "pane_id": "%5", "task": "summarize network.tf", "status": "running" } }
   ```
5. **Launch the sub-agent in that pane**, streaming output so work is visible:
   ```bash
   tmux send-keys -t <pane_id> 'claude -p "TASK" 2>&1 | tee /tmp/worker-N-output.txt; echo "DONE" >> /tmp/worker-N-output.txt' Enter
   ```
6. **Poll for completion** then read `/tmp/worker-N-output.txt` and return a concise summary to the `claude-control` pane conversation.
7. **Update the worker registry** status to `done`.

## Worker Registry

Maintain `/tmp/claude-workers.json` as a live registry of all worker panes:
```json
{
  "worker-1": { "pane_id": "%3", "task": "summarize network.tf", "status": "done" },
  "worker-2": { "pane_id": "%4", "task": "research S3 bucket config", "status": "running" }
}
```

## Worker Listing Commands

When the user says any of: `show workers`, `list workers`, `ls workers` — display a Markdown table like:

| Pane | Pane ID | Status | Task |
|------|---------|--------|------|
| worker-1 | %3 | done | summarize network.tf |
| worker-2 | %4 | running | research S3 bucket config |

Read live state from both `/tmp/claude-workers.json` and `tmux list-panes -a`.

## Startup Checklist

When launched inside tmux:
- [ ] Rename current pane to `claude-control`
- [ ] Enable pane border status (`pane-border-status top`)
- [ ] Set status bar color to magenta (`status-style bg=magenta,fg=white`)
- [ ] Enable vi mode (`mode-keys vi`) regardless of tmux.conf setting
- [ ] Initialize `/tmp/claude-workers.json` as `{}` if it does not exist
- [ ] Note existing panes (potential pre-existing workers)
