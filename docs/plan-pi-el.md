# Emacs pi-coding-agent Integration

**Author:** Sayre Blades  
**Date:** 2026-04-04  
**Status:** Implemented  
**Issue:** [#7](https://github.com/SayreBlades/truman/issues/7)

Integrate [pi-coding-agent](https://github.com/dnouri/pi-coding-agent) (Emacs frontend for pi) with the truman devcontainer so that `M-x pi-coding-agent` spawns pi inside the sandboxed Docker environment.

---

## Key Insight

The issue identified four possible approaches (wrapper script, upstream function support, long-running container, learnings from #4). The shipped devcontainer template model — where each project carries its own `.devcontainer/` with `..:/workspace` binding — eliminates the "dynamic directory binding" problem entirely. No upstream changes to pi-coding-agent are required.

The presence of `.devcontainer/truman.sh` is the discriminator: not every `.devcontainer/` is a truman project, but `truman.sh` is truman-specific and signals that a sandboxed pi agent is available.

---

## What Was Implemented

### 1. `truman.sh run-pi -T` flag

Added `-T` flag to `cmd_run_pi` in `truman.sh`. Matches Docker's convention for "no pseudo-TTY". When passed, finds the running agent container by Docker label and execs into it with pipe-friendly I/O.

```bash
cmd_run_pi() {
    local no_tty=false
    local pi_args=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -T) no_tty=true; shift ;;
            *) pi_args+=("$1"); shift ;;
        esac
    done

    if ! validate_config; then
        exit 1
    fi

    if $no_tty; then
        # Find the agent container by label (works regardless of how
        # containers were started — devcontainer up, docker compose up,
        # VS Code, etc.)
        local container
        container=$(docker ps -q \
            --filter "label=com.docker.compose.service=agent" \
            --filter "label=com.docker.compose.project.working_dir=$SCRIPT_DIR")
        if [ -z "$container" ]; then
            err "Agent container not running. Start with: .devcontainer/truman.sh start"
            exit 1
        fi
        # -i keeps stdin open (no TTY); -u pi because entrypoint runs as root.
        exec docker exec -i -u pi "$container" pi "${pi_args[@]+"${pi_args[@]}"}"
    else
        devcontainer exec --workspace-folder "$PROJECT_ROOT" pi "${pi_args[@]+"${pi_args[@]}"}"
    fi
}
```

**Design decisions:**

- **`docker exec` with label lookup instead of `docker compose exec`:** The `devcontainer up` CLI names the compose project `<dirname>_devcontainer`, but `docker compose -f` derives a different default name from the compose file's directory. This mismatch causes `docker compose exec` to fail with "service is not running." Finding the container by its `com.docker.compose.service` and `com.docker.compose.project.working_dir` labels works regardless of how the containers were started.

- **`-i` (not `-it`):** The `-i` flag keeps stdin open for pipe-based I/O. Omitting `-t` avoids TTY allocation, which would mangle the JSONL stream.

- **`-u pi`:** The agent Dockerfile doesn't set `USER` — the entrypoint runs as root and drops to pi via `gosu`. `docker exec` therefore defaults to root without `-u`.

- **`${pi_args[@]+"${pi_args[@]}"}`:** Bash `set -u` treats empty arrays as unbound variables. This idiom expands to nothing when the array is empty.

### 2. Doom Emacs configuration (`~/.config/doom/config.el`)

Auto-detect function that prompts when a truman project is detected:

```elisp
(defun my/pi-maybe-truman ()
  "Start pi-coding-agent, prompting for truman when available."
  (interactive)
  (let* ((dir (or (when-let ((proj (project-current)))
                    (project-root proj))
                  default-directory))
         (truman-sh (expand-file-name ".devcontainer/truman.sh" dir)))
    (setq pi-coding-agent-executable
          (if (and (file-executable-p truman-sh)
                   (y-or-n-p "Truman devcontainer detected. Run sandboxed? "))
              (list truman-sh "run-pi" "-T")
            '("pi"))))
  (call-interactively #'pi-coding-agent))
```

Bound to leader key: `SPC o p`

**Design decisions:**

- **`setq` not `let`:** The version probe runs asynchronously via `run-at-time`. A `let`-binding would be out of scope when the timer fires. `setq` persists the value so the async probe sees the right executable.

- **Absolute path via `expand-file-name`:** The executable list uses the full expanded path (e.g., `"/Users/sayre/dev/my-app/.devcontainer/truman.sh"`). Relative paths fail when `default-directory` changes between process spawns (as happens with the async version probe).

- **`y-or-n-p` prompt:** When `truman.sh` is detected, the user is asked whether to run sandboxed. This avoids confusion when a truman project is open but the user wants to run pi natively (e.g., containers not started yet).

- **`executable-find` override:** pi-coding-agent's dependency check only searches PATH. An advice override also checks `file-executable-p` against `default-directory` so absolute or relative paths to `truman.sh` pass the check without triggering a spurious warning.

```elisp
(advice-add 'pi-coding-agent--check-pi :override
            (lambda ()
              (let ((cmd (car pi-coding-agent-executable)))
                (or (executable-find cmd)
                    (file-executable-p (expand-file-name cmd default-directory))))))
```

### 3. Files changed

| File | Change |
|------|--------|
| `template/.devcontainer/truman.sh` | Added `-T` flag to `cmd_run_pi`, updated help text and header comment |
| `examples/temperature-converter/.devcontainer/truman.sh` | Synced from template |
| `~/.config/doom/config.el` | Replaced `pi-wrapper.sh` with `my/pi-maybe-truman` auto-detect + prompt |

---

## How It Works

### Session lifecycle

1. User invokes `SPC o p` (or `M-x my/pi-maybe-truman`) from a project buffer
2. Function checks for `.devcontainer/truman.sh` in the project root
3. If found, prompts: "Truman devcontainer detected. Run sandboxed?"
4. If yes: sets executable to `("/path/to/.devcontainer/truman.sh" "run-pi" "-T")`
5. If no (or no truman.sh found): sets executable to `("pi")`
6. `pi-coding-agent--start-process` spawns the process
7. `truman.sh run-pi -T` finds the agent container by Docker label, execs `pi --mode rpc`
8. JSONL flows over stdin/stdout pipes

### Command construction

pi-coding-agent appends `--mode rpc` automatically:

```
executable:    ("/path/to/.devcontainer/truman.sh" "run-pi" "-T")
appended:      "--mode" "rpc"
final command: /path/to/.devcontainer/truman.sh run-pi -T --mode rpc
truman.sh:     consumes -T, forwards --mode rpc to pi
result:        docker exec -i -u pi <container> pi --mode rpc
```

### Why exec into a running container

The truman devcontainer uses `command: sleep infinity` — it's designed to be long-running:

| Approach | What happens | Startup time |
|----------|-------------|-------------|
| `docker compose run --rm -T` | New container, entrypoint, gateway health wait | ~7-8s |
| `docker exec -i` into running container | Direct exec, no overhead | <1s |

---

## Issues Encountered During Implementation

### 1. Compose project name mismatch

`devcontainer up` names the compose project `<dirname>_devcontainer`. `docker compose -f .devcontainer/docker-compose.yml` derives the name `devcontainer`. This caused `docker compose exec` to report "service is not running" even with containers running.

**Fix:** Use `docker exec` with label-based container lookup instead of `docker compose exec`.

### 2. Async version probe and relative paths

The version probe fires asynchronously via `run-at-time`. By the time it executes, `default-directory` may have changed, causing relative paths like `.devcontainer/truman.sh` to fail with "No such file or directory."

**Fix:** Use absolute paths in `pi-coding-agent-executable` (via `expand-file-name`).

### 3. `executable-find` warning

pi-coding-agent's dependency check uses `executable-find`, which only searches PATH. Absolute paths to `truman.sh` (e.g., `/Users/.../truman.sh`) are not in PATH.

**Fix:** Advice override that also checks `file-executable-p`.

### 4. Empty array expansion under `set -u`

`${pi_args[@]}` fails when the array is empty under bash's `set -u` (nounset) option.

**Fix:** Use `${pi_args[@]+"${pi_args[@]}"}` — expands to nothing when empty.

---

## Verification

Tested end-to-end with `~/dev/sandbox/temperature-converter/`:

```bash
# Start containers
.devcontainer/truman.sh start

# Verify -T path works
.devcontainer/truman.sh run-pi -T --version
# → 0.65.0

# Verify JSONL RPC pipe works
echo '{"type":"sendMessage","content":"hello"}' | .devcontainer/truman.sh run-pi -T --mode rpc
# → JSONL response on stdout
```

Emacs: `SPC o p` → prompted "Run sandboxed?" → y → pi-coding-agent session started inside container, full chat interaction working.

---

## Relationship to Other Issues

- **Parallel to [#4](https://github.com/SayreBlades/truman/issues/4)** (VS Code devcontainer) — same container infrastructure, different attachment mechanism
- **Builds on Phase 2** — relies on gateway credential injection for the security model
- **No upstream dependency** — works with pi-coding-agent as-is
