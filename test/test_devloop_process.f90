program test_devloop_process
  use fgof_devloop, only : &
    FGOF_DEVLOOP_COMMAND_BUILD, &
    FGOF_DEVLOOP_COMMAND_SMOKE, &
    FGOF_DEVLOOP_DECISION_IDLE, &
    FGOF_DEVLOOP_DECISION_RESTART, &
    FGOF_DEVLOOP_DECISION_STOP, &
    clear_devloop_options, &
    devloop_build_command, &
    devloop_manual_trigger, &
    devloop_run_command, &
    devloop_smoke_command, &
    devloop_start_trigger, &
    run_devloop_cycle, &
    start_devloop
  use fgof_devloop_types, only : &
    devloop_command_spec, &
    devloop_options, &
    devloop_state, &
    devloop_supervision_result
  use fgof_process, only : &
    FGOF_PROCESS_ERR_TIMEOUT, &
    process_options, &
    shell
  implicit none

  call test_successful_build_command()
  call test_build_failure_skips_later_commands()
  call test_timeout_uses_failure_policy()

contains

  subroutine test_successful_build_command()
    type(devloop_state) :: state
    type(devloop_command_spec) :: build
    type(devloop_supervision_result) :: supervision
    type(process_options) :: process_config

    process_config = process_options()
    process_config%capture_stdout = .true.

    call start_devloop(state)
    build = devloop_build_command(shell("printf build"), process_config, "compile")
    supervision = run_devloop_cycle(state, devloop_start_trigger(), build_command=build)

    if (.not. supervision%started) error stop "process supervision should start a cycle"
    if (.not. supervision%succeeded) error stop "successful process should succeed"
    if (supervision%failed) error stop "successful process should not fail"
    if (supervision%command_count /= 1) error stop "one build command should run"
    if (supervision%build%kind /= FGOF_DEVLOOP_COMMAND_BUILD) error stop "build kind should be preserved"
    if (.not. supervision%build%requested) error stop "build command should be requested"
    if (.not. supervision%build%succeeded) error stop "build command should succeed"
    if (supervision%build%label /= "compile") error stop "custom build label should be preserved"
    if (supervision%build%process%stdout /= "build") error stop "build stdout should stay visible"
    if (supervision%decision%kind /= FGOF_DEVLOOP_DECISION_IDLE) error stop "success should idle"
    if (state%running) error stop "finished process cycle should not leave state running"
  end subroutine test_successful_build_command

  subroutine test_build_failure_skips_later_commands()
    type(devloop_state) :: state
    type(devloop_command_spec) :: build
    type(devloop_command_spec) :: run_spec
    type(devloop_supervision_result) :: supervision

    call start_devloop(state)
    build = devloop_build_command(shell("exit 7"))
    run_spec = devloop_run_command(shell("exit 0"))
    supervision = run_devloop_cycle(state, devloop_manual_trigger("manual"), &
                                    build_command=build, run_command=run_spec)

    if (.not. supervision%failed) error stop "failed build should fail supervision"
    if (supervision%succeeded) error stop "failed build should not succeed"
    if (supervision%command_count /= 1) error stop "run command should be skipped after build failure"
    if (supervision%failed_command_kind /= FGOF_DEVLOOP_COMMAND_BUILD) then
      error stop "failed command kind should identify build"
    end if
    if (supervision%last_exit_code /= 7) error stop "failed exit code should be preserved"
    if (supervision%build%exit_code /= 7) error stop "build exit code should be preserved"
    if (supervision%run%requested) error stop "run command should not execute after build failure"
    if (.not. supervision%run%skipped) error stop "skipped run command should stay marked skipped"
    if (supervision%decision%kind /= FGOF_DEVLOOP_DECISION_RESTART) error stop "failure should request restart"
    if (.not. supervision%decision%should_run) error stop "restart decision should be runnable"
    if (state%consecutive_failures /= 1) error stop "failure count should advance"
  end subroutine test_build_failure_skips_later_commands

  subroutine test_timeout_uses_failure_policy()
    type(devloop_state) :: state
    type(devloop_options) :: loop_options
    type(devloop_command_spec) :: smoke
    type(devloop_supervision_result) :: supervision
    type(process_options) :: process_config

    loop_options = clear_devloop_options()
    loop_options%stop_on_failure = .true.
    process_config = process_options()
    process_config%timeout_ms = 100

    call start_devloop(state, loop_options)
    smoke = devloop_smoke_command(shell("sleep 1"), process_config)
    supervision = run_devloop_cycle(state, devloop_manual_trigger("timeout"), smoke_command=smoke)

    if (.not. supervision%failed) error stop "timed-out smoke should fail supervision"
    if (.not. supervision%timed_out) error stop "timeout should be visible on supervision"
    if (supervision%failed_command_kind /= FGOF_DEVLOOP_COMMAND_SMOKE) then
      error stop "failed command kind should identify smoke"
    end if
    if (supervision%process_error_code /= FGOF_PROCESS_ERR_TIMEOUT) then
      error stop "timeout should preserve process error code"
    end if
    if (.not. supervision%smoke%timed_out) error stop "smoke result should preserve timeout"
    if (supervision%decision%kind /= FGOF_DEVLOOP_DECISION_STOP) error stop "stop policy should stop"
    if (.not. state%stopped) error stop "stop policy should mark state stopped"
  end subroutine test_timeout_uses_failure_policy

end program test_devloop_process
