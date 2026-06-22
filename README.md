# claude-reaper

Reclaim RAM from **parked, idle, non-working** Claude Code sessions — without
killing the one that's mid-build.

Idle Claude Code sessions each hold ~0.5–1 GB resident. On Linux they don't even
stay flat — they *climb* toward the OOM killer
([#33211](https://github.com/anthropics/claude-code/issues/33211),
[#56693](https://github.com/anthropics/claude-code/issues/56693),
[#4953](https://github.com/anthropics/claude-code/issues/4953)). Nothing in the
CLI reclaims it; there's an open request for exactly this
([#44321](https://github.com/anthropics/claude-code/issues/44321)). The kernel
OOM killer is the only fallback, and it's the dumb version: it shoots the biggest
process, not the idle one, with no recoverability.

`claude-reaper` is the careful version.

## Why it won't eat your work

The Desktop app's idle handling kills sessions on a wall-clock
([it `taskkill /T /F`s the whole tree after 15 min](https://github.com/anthropics/claude-code/issues/68625),
taking running background jobs with it). This doesn't. A session is **spared** if
**any** of these hold — and these spares cannot be configured off:

- it was active within the idle window (read from the transcript, not file mtime)
- it has a live compiler/test descendant (`BUSY_PROCS`)
- it's younger than the grace window (default 30 min)
- **its process tree is burning CPU right now** (sampled live before any kill)
- a custom `spare` hook vetoes it
- its session id or transcript can't be found/parsed → fail-safe, left alone

Kills are SIGTERM → pause → SIGKILL, and every reaped session is logged with its
`claude --resume <id>` line. Nothing is destroyed — only the live process ends;
the transcript stays put and resumes.

## Install

```sh
git clone https://github.com/rgehrkedk/claude-session-reaper
cd claude-session-reaper
./install.sh                  # symlinks claude-reaper into ~/.local/bin
```

Requires bash + coreutils. macOS and Linux.
**Windows:** run it under WSL — there it's just Linux.

## Use

```sh
claude-reaper                 # status: what's parked right now (read-only, default)
claude-reaper reap            # reclaim idle parked sessions
claude-reaper reap --dry-run  # scan, decide, but never kill
claude-reaper install         # run it on a schedule (launchd on macOS, systemd --user on Linux)
claude-reaper uninstall       # remove the scheduler
claude-reaper logs -f         # follow the reap log
claude-reaper config          # show effective settings + where they came from
```

`status` is always safe. Only `reap` (without `--dry-run`) kills anything.

## Configure

Optional. Defaults work out of the box.

```sh
claude-reaper config --init   # writes ~/.config/claude-reaper/config
```

Common knobs (full list in [`config.example`](config.example)):

| Key | Default | Does |
|---|---|---|
| `IDLE_HOURS` | `3` | reap sessions idle longer than this |
| `GRACE_MINS` | `30` | never touch a session younger than this |
| `MAX_RSS` | off | also reap parked sessions over this size (e.g. `4G`) — handy on Linux |
| `BUSY_PROCS_EXTRA` | — | append your build tools to the "spare while working" set |
| `SESSION_MATCH` | `share/claude/versions` | how a session is recognised (npm installs differ) |
| `SESSION_ID_PATTERNS` | `both` | `uuid` (local), `cse` (remote-control), or `both` |

### Hooks

Drop an executable at `~/.config/claude-reaper/hooks/` to extend behaviour
without touching the tool:

- **`spare`** — gets `pid session_id transcript`; exit `0` to protect a session.
  Add-only: it can never force a kill the core wouldn't make.
- **`notify`** — gets the reap summary on stdin. Wire it to Pushover, ntfy,
  Slack, a desktop banner.

Examples: [`hooks/spare.example`](hooks/spare.example),
[`hooks/notify-pushover.example`](hooks/notify-pushover.example).

## Scope

Identifies sessions that expose a session id on their command line — the native
installer's local and remote-control workers. If `claude-reaper status` finds
nothing on your setup, your install lays processes out differently; set
`SESSION_MATCH` / `WORKER_MATCH` to match, or open an issue with a line of
`ps -eo pid,command | grep claude`. The fail-safe design means an unrecognised
session is skipped, never wrongly killed.

## License

MIT — see [LICENSE](LICENSE).
