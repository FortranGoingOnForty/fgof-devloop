# fgof-devloop

Watch-driven rebuild, restart, and smoke-loop helpers for modern Fortran tools.

`fgof-devloop` is intended to be a small standalone library for the reusable
parts of development loops: deciding when file changes should trigger work,
tracking run cycles, modeling restart policy, and eventually wiring those
decisions to `fgof-watch`, `fgof-process`, and `fgof-jobs`.

It is part of the [FortranGoingOnForty lib-modules](https://github.com/FortranGoingOnForty/lib-modules)
catalog, but it is intended to stand on its own as a normal `fpm` package.

Current v1 target:

- stable dev-loop option and state types
- deterministic cycle and restart decision helpers
- watch-event shaping that can consume `fgof-watch`
- process-runner integration that can supervise rebuild and run commands
- examples for command-line tools and local service smoke loops

## Status

Sprint 03 is in place.

Tracked today:

- package layout, CI, and standalone repo setup
- local sprint plan in ignored `.docs/sprints/`
- stable option, trigger, cycle, decision, and state types
- pure run-cycle helpers for start, finish, stop, and restart decisions
- deterministic failure policy through `stop_on_failure` and `max_failures`
- `fgof-watch` integration through shaped event summaries and trigger policy
- loop-owned restart filters for directory events and minimum change counts
- watch option projection for debounce polls, hidden-path ignores, and directory-event emission
- `fgof-process` integration for one-shot build, run, and smoke command supervision
- command results that retain full `process_result` output, exit, timeout, and error detail
- focused model, watch-bridge, and process-supervision coverage in `fpm test`

## Public API Shape

Primary modules:

- `fgof_devloop`
- `fgof_devloop_types`

Current public procedures:

- `clear_devloop_options`
- `clear_devloop_trigger`
- `clear_devloop_cycle`
- `clear_devloop_decision`
- `clear_devloop_watch_summary`
- `clear_devloop_command_spec`
- `clear_devloop_command_result`
- `clear_devloop_supervision_result`
- `devloop_backend_name`
- `clear_devloop_state`
- `start_devloop`
- `stop_devloop`
- `should_start_on_open`
- `devloop_start_trigger`
- `devloop_change_trigger`
- `devloop_manual_trigger`
- `devloop_summarize_watch_events`
- `devloop_watch_failure_summary`
- `devloop_watch_options`
- `devloop_watch_trigger`
- `devloop_build_command`
- `devloop_run_command`
- `devloop_smoke_command`
- `run_devloop_command`
- `run_devloop_cycle`
- `begin_devloop_cycle`
- `finish_devloop_cycle`

Current semantics:

- `devloop_options` carries run-on-start, restart-on-change, directory restart, hidden-path ignore, debounce, stop-on-failure, and max-failure policy
- `devloop_trigger` records why work should begin, such as start, file change, or manual request
- `devloop_watch_summary` condenses `fgof-watch` event batches into file, directory, create, modify, remove, move, ignored, and failure counters
- `devloop_watch_options()` projects dev-loop policy into `fgof-watch` options for debounce polls, hidden-path filtering, and directory event emission
- `devloop_watch_trigger()` turns successful watch summaries into change triggers while suppressing watcher failures, empty batches, directory-only batches when disabled, and batches below `min_restart_changes`
- `devloop_build_command()`, `devloop_run_command()`, and `devloop_smoke_command()` wrap `fgof-process` commands with loop roles and optional process options
- `run_devloop_command()` executes one command spec and preserves the raw `process_result`, including stdout, stderr, exit code, timeout state, and process error details
- `run_devloop_cycle()` starts a cycle, executes enabled build/run/smoke specs in order, skips later specs after the first failure, and feeds the outcome into `finish_devloop_cycle()`
- `begin_devloop_cycle()` increments the cycle counter and starts work only when the loop is active, idle, and policy permits the trigger
- `finish_devloop_cycle()` records success or failure and returns an explicit decision to idle, restart, or stop
- negative `max_failures` values normalize to unlimited failures
- negative `debounce_polls` values normalize to no debounce
- Sprint 03 is intentionally one-shot and synchronous; long-running process groups and cleanup orchestration belong to the later jobs layer

## Dependency

`fgof-devloop` depends on `fgof-watch` `v0.1.0` for watch-event types and
watch option projection, and a pinned `fgof-process` commit for one-shot
process execution:

```toml
[dependencies]
fgof-process = { git = "https://github.com/FortranGoingOnForty/fgof-process.git", rev = "dd71a77c61985380c7e32f4a719fd8bb247625c7" }
fgof-watch = { git = "https://github.com/FortranGoingOnForty/fgof-watch.git", tag = "v0.1.0" }
```

## Build And Test

```bash
fpm test
```

## Supported Platforms

- macOS
- Linux

## Boundaries

- focused on reusable development-loop mechanics, not a full CLI app
- should remain useful on its own even if future tools wrap it with UI policy
- watch, process, and job integration should stay layered over stable state
  transitions

## License

MIT
