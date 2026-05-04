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

Initial scaffold is in place.

Tracked today:

- package layout, CI, and standalone repo setup
- local sprint plan in ignored `.docs/sprints/`
- placeholder public API for `fpm test`

## Public API Shape

Primary modules:

- `fgof_devloop`
- `fgof_devloop_types`

Current public procedures:

- `devloop_backend_name`
- `clear_devloop_state`

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
