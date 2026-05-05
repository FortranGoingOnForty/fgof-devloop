program test_devloop_model
  use fgof_devloop, only : &
    FGOF_DEVLOOP_DECISION_IDLE, &
    FGOF_DEVLOOP_DECISION_RESTART, &
    FGOF_DEVLOOP_DECISION_STOP, &
    FGOF_DEVLOOP_TRIGGER_CHANGE, &
    FGOF_DEVLOOP_TRIGGER_NONE, &
    FGOF_DEVLOOP_TRIGGER_START, &
    begin_devloop_cycle, &
    clear_devloop_options, &
    clear_devloop_state, &
    devloop_change_trigger, &
    devloop_manual_trigger, &
    devloop_start_trigger, &
    finish_devloop_cycle, &
    should_start_on_open, &
    start_devloop, &
    stop_devloop
  use fgof_devloop_types, only : devloop_cycle, devloop_decision, devloop_options, devloop_state, devloop_trigger
  implicit none

  type(devloop_state) :: state
  type(devloop_options) :: options
  type(devloop_cycle) :: cycle
  type(devloop_decision) :: decision
  type(devloop_trigger) :: trigger

  state = clear_devloop_state()
  call start_devloop(state)
  if (.not. state%active) error stop "start_devloop should activate the loop"
  if (.not. should_start_on_open(state)) error stop "default options should request a start cycle"

  cycle = begin_devloop_cycle(state, devloop_start_trigger())
  if (.not. cycle%started) error stop "start trigger should begin a cycle"
  if (cycle%id /= 1) error stop "first cycle should use id one"
  if (cycle%trigger_kind /= FGOF_DEVLOOP_TRIGGER_START) error stop "cycle should record start trigger"
  if (.not. state%running) error stop "begin cycle should mark the loop running"

  decision = finish_devloop_cycle(state, succeeded=.true., exit_code=0)
  if (decision%kind /= FGOF_DEVLOOP_DECISION_IDLE) error stop "successful cycle should idle"
  if (state%running) error stop "finished cycle should clear running state"
  if (state%last_cycle%exit_code /= 0) error stop "finish should preserve exit code"

  cycle = begin_devloop_cycle(state, devloop_change_trigger(3, "source changed"))
  if (.not. cycle%started) error stop "change trigger should begin a restart cycle"
  if (cycle%trigger_kind /= FGOF_DEVLOOP_TRIGGER_CHANGE) error stop "change cycle should record trigger kind"
  if (cycle%change_count /= 3) error stop "change cycle should preserve change count"
  decision = finish_devloop_cycle(state, succeeded=.false., exit_code=2)
  if (decision%kind /= FGOF_DEVLOOP_DECISION_RESTART) error stop "failed cycle should restart by default"
  if (.not. decision%should_run) error stop "restart decision should request another run"
  if (state%consecutive_failures /= 1) error stop "failed cycle should increment failure count"

  call start_devloop(state)
  trigger = devloop_change_trigger(0)
  if (trigger%kind /= FGOF_DEVLOOP_TRIGGER_NONE) then
    error stop "zero-count change trigger should be suppressed"
  end if
  trigger = devloop_change_trigger(-2)
  if (trigger%kind /= FGOF_DEVLOOP_TRIGGER_NONE) then
    error stop "negative-count change trigger should be suppressed"
  end if
  cycle = begin_devloop_cycle(state, devloop_change_trigger(0))
  if (cycle%started) error stop "zero-count changes should not start a cycle"

  options = clear_devloop_options()
  options%restart_on_change = .false.
  call start_devloop(state, options)
  cycle = begin_devloop_cycle(state, devloop_change_trigger(1))
  if (cycle%started) error stop "restart_on_change=false should suppress change cycles"
  cycle = begin_devloop_cycle(state, devloop_manual_trigger())
  if (.not. cycle%started) error stop "manual trigger should still begin a cycle"

  options = clear_devloop_options()
  options%max_failures = 1
  call start_devloop(state, options)
  cycle = begin_devloop_cycle(state, devloop_start_trigger())
  decision = finish_devloop_cycle(state, succeeded=.false., exit_code=1)
  if (decision%kind /= FGOF_DEVLOOP_DECISION_STOP) error stop "max failures should stop the loop"
  if (.not. decision%should_stop) error stop "stop decision should request stop"
  if (state%active) error stop "failure limit should deactivate the loop"
  if (.not. state%stopped) error stop "failure limit should mark the loop stopped"

  options = clear_devloop_options()
  options%max_failures = -5
  call start_devloop(state, options)
  if (state%options%max_failures /= 0) error stop "negative max_failures should normalize to unlimited"

  call stop_devloop(state)
  if (state%active) error stop "stop_devloop should deactivate the loop"
end program test_devloop_model
