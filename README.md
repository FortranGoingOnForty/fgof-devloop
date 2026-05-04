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

Sprint 01 is in place.

Tracked today:

- package layout, CI, and standalone repo setup
- local sprint plan in ignored `.docs/sprints/`
- stable option, trigger, cycle, decision, and state types
- pure run-cycle helpers for start, finish, stop, and restart decisions
- deterministic failure policy through `stop_on_failure` and `max_failures`
- focused model coverage in `fpm test`

## Public API Shape

Primary modules:

- `fgof_devloop`
- `fgof_devloop_types`

Current public procedures:

- `clear_devloop_options`
- `clear_devloop_trigger`
- `clear_devloop_cycle`
- `clear_devloop_decision`
- `devloop_backend_name`
- `clear_devloop_state`
- `start_devloop`
- `stop_devloop`
- `should_start_on_open`
- `devloop_start_trigger`
- `devloop_change_trigger`
- `devloop_manual_trigger`
- `begin_devloop_cycle`
- `finish_devloop_cycle`

Current semantics:

- `devloop_options` carries run-on-start, restart-on-change, stop-on-failure, and max-failure policy
- `devloop_trigger` records why work should begin, such as start, file change, or manual request
- `begin_devloop_cycle()` increments the cycle counter and starts work only when the loop is active, idle, and policy permits the trigger
- `finish_devloop_cycle()` records success or failure and returns an explicit decision to idle, restart, or stop
- negative `max_failures` values normalize to unlimited failures
- Sprint 01 is intentionally process-free so later watch and process integration can build on deterministic state transitions

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
