program test_scaffold
  use fgof_devloop, only : &
    FGOF_DEVLOOP_DECISION_IDLE, &
    FGOF_DEVLOOP_TRIGGER_NONE, &
    clear_devloop_cycle, &
    clear_devloop_decision, &
    clear_devloop_options, &
    clear_devloop_state, &
    clear_devloop_trigger, &
    devloop_backend_name
  use fgof_devloop_types, only : devloop_cycle, devloop_decision, devloop_options, devloop_state, devloop_trigger
  implicit none

  type(devloop_state) :: state
  type(devloop_options) :: options
  type(devloop_trigger) :: trigger
  type(devloop_cycle) :: cycle
  type(devloop_decision) :: decision

  state = clear_devloop_state()
  options = clear_devloop_options()
  trigger = clear_devloop_trigger()
  cycle = clear_devloop_cycle()
  decision = clear_devloop_decision()

  if (state%options%max_failures /= 0) error stop "devloop options should start with unlimited failures"
  if (.not. state%options%run_on_start) error stop "devloop should default to run on start"
  if (.not. state%options%restart_on_change) error stop "devloop should default to restart on change"
  if (state%last_cycle%id /= 0) error stop "devloop state should clear the last cycle"
  if (state%cycle_count /= 0) error stop "devloop state should start with no cycles"
  if (state%consecutive_failures /= 0) error stop "devloop state should start with no failures"
  if (state%active) error stop "devloop state should start inactive"
  if (state%running) error stop "devloop state should not start running"
  if (state%stopped) error stop "devloop state should not start stopped"
  if (trigger%kind /= FGOF_DEVLOOP_TRIGGER_NONE) error stop "clear trigger should produce no trigger"
  if (cycle%started) error stop "clear cycle should not start a cycle"
  if (decision%kind /= FGOF_DEVLOOP_DECISION_IDLE) error stop "clear decision should idle"
  if (options%stop_on_failure) error stop "clear options should not stop on failure by default"
  if (devloop_backend_name() /= "model") error stop "devloop backend should report model"
end program test_scaffold
