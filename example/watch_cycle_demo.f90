program watch_cycle_demo
  use fgof_devloop, only : &
    clear_devloop_options, &
    devloop_build_command, &
    devloop_smoke_command, &
    devloop_summarize_watch_events, &
    devloop_watch_trigger, &
    run_devloop_cycle, &
    start_devloop
  use fgof_devloop_types, only : &
    devloop_command_spec, &
    devloop_options, &
    devloop_state, &
    devloop_supervision_result, &
    devloop_trigger, &
    devloop_watch_summary
  use fgof_process, only : &
    process_options, &
    shell
  use fgof_watch_types, only : &
    FGOF_WATCH_EVT_MODIFIED, &
    watch_event
  implicit none

  type(watch_event) :: events(2)
  type(devloop_options) :: loop_options
  type(process_options) :: command_options
  type(devloop_watch_summary) :: summary
  type(devloop_trigger) :: trigger
  type(devloop_state) :: state
  type(devloop_command_spec) :: build
  type(devloop_command_spec) :: smoke
  type(devloop_supervision_result) :: supervision

  loop_options = clear_devloop_options()
  command_options = process_options()
  command_options%capture_stdout = .true.

  events(1)%kind = FGOF_WATCH_EVT_MODIFIED
  events(1)%path = "src/app.f90"
  events(2)%kind = FGOF_WATCH_EVT_MODIFIED
  events(2)%path = "test/app_test.f90"

  summary = devloop_summarize_watch_events(events)
  trigger = devloop_watch_trigger(summary, loop_options, "example watch batch")

  call start_devloop(state, loop_options)
  build = devloop_build_command(shell("printf build-ok"), command_options, "example build")
  smoke = devloop_smoke_command(shell("printf smoke-ok"), command_options, "example smoke")
  supervision = run_devloop_cycle(state, trigger, build_command=build, smoke_command=smoke)

  if (.not. supervision%succeeded) error stop "example devloop cycle should succeed"
  if (supervision%command_count /= 2) error stop "example should run build and smoke"

  print '(a,i0)', "cycle id: ", supervision%cycle%id
  print '(a,i0)', "changed files: ", supervision%cycle%change_count
  print '(a)', "build stdout: " // supervision%build%process%stdout
  print '(a)', "smoke stdout: " // supervision%smoke%process%stdout
end program watch_cycle_demo
