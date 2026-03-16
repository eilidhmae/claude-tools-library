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

## Startup Procedure

Run the following steps on startup, in order.

### 1. Capture own pane ID

`$TMUX_PANE` is set by tmux at launch and never changes — use it for all self-referencing
commands regardless of where focus is:

```bash
MY_PANE=$TMUX_PANE
```

### 2. Name own pane and apply window styles

```bash
tmux select-pane -t $TMUX_PANE -T "claude-control"
tmux set-option -w pane-border-status top
tmux set-option -w pane-border-format " #{pane_title} "
tmux set-option -g status-style bg=magenta,fg=white
tmux set-option -g mode-keys vi
```

### 3. Initialize worker registry

```bash
[ -f /tmp/claude-workers.json ] || echo '{}' > /tmp/claude-workers.json
```

### 4. Create initial worker layout (only if alone in window)

Check the current window only. If this is the only pane, proactively create a worker strip:

```bash
PANE_COUNT=$(tmux list-panes | wc -l)
```

If `PANE_COUNT == 1`, run:

```bash
# Bottom strip height: 25% of window height, minimum 5 lines
WIN_H=$(tmux display-message -p '#{window_height}')
LINES_25=$(( WIN_H * 25 / 100 ))
[ $LINES_25 -lt 5 ] && LINES_25=5
SPLIT_PCT=$(( LINES_25 * 100 / WIN_H ))

# Split claude-control horizontally — new pane appears below as the worker strip
WORKER_1=$(tmux split-window -v -p $SPLIT_PCT -t $TMUX_PANE -P -F '#{pane_id}')

# Split the strip vertically into two equal worker panes
WORKER_2=$(tmux split-window -h -t $WORKER_1 -P -F '#{pane_id}')

# Name both panes
tmux select-pane -t $WORKER_1 -T "worker-1"
tmux select-pane -t $WORKER_2 -T "worker-2"

# Register both as idle workers
echo "{
  \"worker-1\": {\"pane_id\": \"$WORKER_1\", \"task\": null, \"status\": \"idle\"},
  \"worker-2\": {\"pane_id\": \"$WORKER_2\", \"task\": null, \"status\": \"idle\"}
}" > /tmp/claude-workers.json

# Return focus to claude-control
tmux select-pane -t $TMUX_PANE
```

## Sub-Agent Workflow

All pane operations are scoped to the **current window only** unless the user explicitly
instructs otherwise. When asked to run a sub-agent or work in parallel:

1. **Find or create a worker pane** in the current window. Prefer an idle worker from the
   registry before creating a new one.
   - If creating a new pane, split from an existing worker pane (not from `claude-control`)
     to preserve the majority of the window for `claude-control`:
     ```bash
     tmux split-window -h -t <worker_pane_id> -p 50
     ```
2. **Assign the next available worker number** by checking `/tmp/claude-workers.json`.
3. **Name the pane**:
   ```bash
   tmux select-pane -t <pane_id> -T "worker-N"
   ```
4. **Write the task to the worker registry**:
   ```json
   { "worker-1": { "pane_id": "%5", "task": "summarize network.tf", "status": "running" } }
   ```
5. **Launch the sub-agent**, streaming output:
   ```bash
   tmux send-keys -t <pane_id> 'claude -p "TASK" 2>&1 | tee /tmp/worker-N-output.txt; echo "DONE" >> /tmp/worker-N-output.txt' Enter
   ```
6. **Return focus to `claude-control`** immediately after launching:
   ```bash
   tmux select-pane -t $TMUX_PANE
   ```
7. **Poll for completion**, then read `/tmp/worker-N-output.txt` and return a concise summary.
8. **Update the worker registry** status to `done`.

## Worker Registry

Maintain `/tmp/claude-workers.json` as a live registry of all worker panes:
```json
{
  "worker-1": { "pane_id": "%3", "task": "summarize network.tf", "status": "done" },
  "worker-2": { "pane_id": "%4", "task": "research S3 bucket config", "status": "running" }
}
```

## Worker Listing Commands

When the user says any of: `show workers`, `list workers`, `ls workers` — display a Markdown
table. Read live state from both `/tmp/claude-workers.json` and `tmux list-panes`
(current window only):

| Pane | Pane ID | Status | Task |
|------|---------|--------|------|
| worker-1 | %3 | done | summarize network.tf |
| worker-2 | %4 | running | research S3 bucket config |

## Startup Checklist

When launched inside tmux:
- [ ] Capture `$TMUX_PANE` as own pane ID
- [ ] Rename own pane to `claude-control` using captured ID (not focus-dependent)
- [ ] Enable pane border status (`pane-border-status top`)
- [ ] Set status bar color to magenta (`status-style bg=magenta,fg=white`)
- [ ] Enable vi mode (`mode-keys vi`) regardless of tmux.conf setting
- [ ] Initialize `/tmp/claude-workers.json` as `{}` if it does not exist
- [ ] If alone in window: create bottom worker strip, split into `worker-1` / `worker-2`, return focus to `claude-control`
- [ ] Note any pre-existing panes as potential workers
