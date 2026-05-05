program test_scaffold
  use fgof_devloop, only : &
    FGOF_DEVLOOP_DECISION_IDLE, &
    FGOF_DEVLOOP_COMMAND_NONE, &
    FGOF_DEVLOOP_TRIGGER_NONE, &
    clear_devloop_command_result, &
    clear_devloop_command_spec, &
    clear_devloop_cycle, &
    clear_devloop_decision, &
    clear_devloop_job_plan, &
    clear_devloop_job_spec, &
    clear_devloop_job_state, &
    clear_devloop_options, &
    clear_devloop_state, &
    clear_devloop_supervision_result, &
    clear_devloop_trigger, &
    clear_devloop_watch_summary, &
    devloop_backend_name
  use fgof_devloop_types, only : &
    devloop_command_result, &
    devloop_command_spec, &
    devloop_cycle, &
    devloop_decision, &
    devloop_job_plan, &
    devloop_job_spec, &
    devloop_job_state, &
    devloop_options, &
    devloop_state, &
    devloop_supervision_result, &
    devloop_trigger, &
    devloop_watch_summary
  implicit none

  type(devloop_state) :: state
  type(devloop_options) :: options
  type(devloop_trigger) :: trigger
  type(devloop_cycle) :: cycle
  type(devloop_decision) :: decision
  type(devloop_command_spec) :: command_spec
  type(devloop_command_result) :: command_result
  type(devloop_supervision_result) :: supervision
  type(devloop_job_spec) :: job_spec_value
  type(devloop_job_state) :: job_state
  type(devloop_job_plan) :: job_plan
  type(devloop_watch_summary) :: watch_summary

  state = clear_devloop_state()
  options = clear_devloop_options()
  trigger = clear_devloop_trigger()
  cycle = clear_devloop_cycle()
  decision = clear_devloop_decision()
  command_spec = clear_devloop_command_spec()
  command_result = clear_devloop_command_result()
  supervision = clear_devloop_supervision_result()
  job_spec_value = clear_devloop_job_spec()
  job_state = clear_devloop_job_state()
  job_plan = clear_devloop_job_plan()
  watch_summary = clear_devloop_watch_summary()

  if (state%options%max_failures /= 0) error stop "devloop options should start with unlimited failures"
  if (.not. state%options%run_on_start) error stop "devloop should default to run on start"
  if (.not. state%options%restart_on_change) error stop "devloop should default to restart on change"
  if (.not. state%options%restart_on_directory_change) error stop "devloop should restart on directory changes by default"
  if (state%options%ignore_hidden) error stop "devloop should not ignore hidden paths by default"
  if (state%options%min_restart_changes /= 1) error stop "devloop should restart after one change by default"
  if (state%options%debounce_polls /= 0) error stop "devloop should not debounce by default"
  if (state%last_cycle%id /= 0) error stop "devloop state should clear the last cycle"
  if (state%cycle_count /= 0) error stop "devloop state should start with no cycles"
  if (state%consecutive_failures /= 0) error stop "devloop state should start with no failures"
  if (state%active) error stop "devloop state should start inactive"
  if (state%running) error stop "devloop state should not start running"
  if (state%stopped) error stop "devloop state should not start stopped"
  if (trigger%kind /= FGOF_DEVLOOP_TRIGGER_NONE) error stop "clear trigger should produce no trigger"
  if (cycle%started) error stop "clear cycle should not start a cycle"
  if (decision%kind /= FGOF_DEVLOOP_DECISION_IDLE) error stop "clear decision should idle"
  if (command_spec%enabled) error stop "clear command spec should be disabled"
  if (command_spec%kind /= FGOF_DEVLOOP_COMMAND_NONE) error stop "clear command spec should have no kind"
  if (command_result%requested) error stop "clear command result should not be requested"
  if (.not. command_result%skipped) error stop "clear command result should be skipped"
  if (supervision%started) error stop "clear supervision should not be started"
  if (supervision%command_count /= 0) error stop "clear supervision should have no commands"
  if (job_spec_value%enabled) error stop "clear job spec should be disabled"
  if (.not. job_spec_value%stop_before_restart) error stop "job specs should stop before restart by default"
  if (job_state%attached) error stop "clear job state should not be attached"
  if (job_state%running) error stop "clear job state should not be running"
  if (job_plan%should_start) error stop "clear job plan should not start"
  if (job_plan%should_stop) error stop "clear job plan should not stop"
  if (options%stop_on_failure) error stop "clear options should not stop on failure by default"
  if (options%ignore_hidden) error stop "clear options should not ignore hidden paths by default"
  if (options%debounce_polls /= 0) error stop "clear options should not debounce by default"
  if (watch_summary%has_changes) error stop "clear watch summary should not have changes"
  if (watch_summary%watch_failed) error stop "clear watch summary should not fail"
  if (devloop_backend_name() /= "model") error stop "devloop backend should report model"
end program test_scaffold
