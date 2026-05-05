program test_devloop_jobs
  use fgof_devloop, only : &
    FGOF_DEVLOOP_JOB_ACTION_NONE, &
    FGOF_DEVLOOP_JOB_ACTION_RESTART, &
    FGOF_DEVLOOP_JOB_ACTION_START, &
    attach_devloop_job, &
    attach_devloop_pipeline_members, &
    devloop_change_trigger, &
    devloop_job_restart_plan, &
    devloop_manual_trigger, &
    devloop_service_job, &
    job_continue_result, &
    job_exit_result, &
    job_stop_result, &
    observe_devloop_job, &
    release_devloop_job
  use fgof_devloop_types, only : &
    devloop_job_plan, &
    devloop_job_spec, &
    devloop_job_state
  use fgof_jobs, only : &
    FGOF_JOBS_SIGNAL_SCOPE_GROUP, &
    FGOF_JOBS_TERMINAL_HANDOFF_ALWAYS, &
    FGOF_JOBS_TERMINAL_HANDOFF_NEVER
  implicit none

  call test_service_restart_plan()
  call test_terminal_handoff_plan()
  call test_pipeline_wait_observation()

contains

  subroutine test_service_restart_plan()
    type(devloop_job_spec) :: spec
    type(devloop_job_state) :: job
    type(devloop_job_plan) :: plan

    spec = devloop_service_job("serve", label="local service", &
                               terminal_handoff=FGOF_JOBS_TERMINAL_HANDOFF_NEVER)
    job = attach_devloop_job(spec, pid=501, process_group=501)

    if (.not. job%configured) error stop "attached devloop job should be configured"
    if (.not. job%attached) error stop "attached devloop job should record attachment"
    if (.not. job%running) error stop "attached devloop job should be running"
    if (.not. job%cleanup_needed) error stop "owned devloop job should need cleanup"
    if (.not. job%owns_process_group) error stop "service job should own its process group"
    if (job%terminal_handoff_required) error stop "never-handoff service should not require terminal handoff"
    if (job%label /= "local service") error stop "job label should be preserved"

    plan = devloop_job_restart_plan(job, devloop_change_trigger(1, "source changed"))
    if (plan%action /= FGOF_DEVLOOP_JOB_ACTION_RESTART) error stop "running job should restart on changes"
    if (.not. plan%should_restart) error stop "restart plan should mark restart"
    if (.not. plan%should_stop) error stop "restart plan should stop existing job"
    if (.not. plan%should_start) error stop "restart plan should start replacement job"
    if (.not. plan%cleanup_needed) error stop "restart plan should expose cleanup need"
    if (plan%pid /= 501) error stop "restart plan should preserve pid"
    if (plan%process_group /= 501) error stop "restart plan should preserve process group"
    if (plan%signal_scope /= FGOF_JOBS_SIGNAL_SCOPE_GROUP) error stop "restart plan should preserve signal scope"

    call release_devloop_job(job)
    if (.not. job%released) error stop "release should mark devloop job released"
    if (job%cleanup_needed) error stop "release should clear cleanup obligations"
    if (.not. job%running) error stop "release should not alter runtime state"

    plan = devloop_job_restart_plan(job, devloop_change_trigger(1, "source changed"))
    if (plan%action /= FGOF_DEVLOOP_JOB_ACTION_NONE) error stop "released job should not plan action"
    if (plan%should_stop) error stop "released job should not stop"
    if (plan%should_start) error stop "released job should not start"
    if (plan%should_restart) error stop "released job should not restart"
    if (plan%reason /= "job released") error stop "released job reason should be explicit"
  end subroutine test_service_restart_plan

  subroutine test_terminal_handoff_plan()
    type(devloop_job_spec) :: spec
    type(devloop_job_state) :: job
    type(devloop_job_plan) :: plan

    spec = devloop_service_job("foreground", background=.false., &
                               terminal_handoff=FGOF_JOBS_TERMINAL_HANDOFF_ALWAYS, &
                               release_on_handoff=.true.)
    job = attach_devloop_job(spec, pid=601, process_group=601)
    plan = devloop_job_restart_plan(job, devloop_manual_trigger("handoff"))

    if (.not. plan%terminal_handoff_required) error stop "foreground jobs should surface terminal handoff"
    if (.not. plan%should_release) error stop "release-on-handoff should be explicit"
    if (plan%action /= FGOF_DEVLOOP_JOB_ACTION_NONE) error stop "release-on-handoff should not restart"
    if (plan%should_stop) error stop "release-on-handoff should not stop the job"
    if (plan%should_start) error stop "release-on-handoff should not start a replacement"
    if (plan%should_restart) error stop "release-on-handoff should not request restart"
    if (plan%reason /= "release for terminal handoff") then
      error stop "release-on-handoff reason should be explicit"
    end if
  end subroutine test_terminal_handoff_plan

  subroutine test_pipeline_wait_observation()
    type(devloop_job_spec) :: spec
    type(devloop_job_state) :: job
    type(devloop_job_plan) :: plan

    spec = devloop_service_job("pipeline-head")
    job = attach_devloop_job(spec, pid=701, process_group=701)
    call attach_devloop_pipeline_members(job, [701, 702, 703])

    call observe_devloop_job(job, job_exit_result(0, pid=701, process_group=701))
    if (job%finished) error stop "one finished pipeline member should not finish the service"
    if (.not. job%handle%members(1)%finished) error stop "first pipeline member should finish"
    if (job%handle%members(2)%finished) error stop "untouched pipeline member should stay live"

    call observe_devloop_job(job, job_stop_result(20, pid=702, process_group=701))
    if (.not. job%handle%members(1)%finished) error stop "group stop should preserve finished member"
    if (job%handle%members(1)%stopped) error stop "group stop should not stop finished member"
    if (.not. job%handle%members(2)%stopped) error stop "group stop should stop live member"
    if (.not. job%stopped) error stop "group stop should mark service stopped"

    call observe_devloop_job(job, job_continue_result(pid=701, process_group=701))
    if (job%handle%members(1)%running) error stop "group continue should not restart finished member"
    if (.not. job%handle%members(2)%running) error stop "group continue should resume live member"
    if (.not. job%running) error stop "continued pipeline should run"

    call observe_devloop_job(job, job_exit_result(0, pid=702, process_group=701))
    call observe_devloop_job(job, job_exit_result(0, pid=703, process_group=701))
    if (.not. job%finished) error stop "all terminal members should finish service"
    if (job%cleanup_needed) error stop "finished service should not need cleanup"

    plan = devloop_job_restart_plan(job, devloop_change_trigger(2, "restart finished"))
    if (plan%action /= FGOF_DEVLOOP_JOB_ACTION_START) error stop "finished service should start fresh"
    if (.not. plan%should_start) error stop "finished service restart should start"
    if (plan%should_stop) error stop "finished service restart should not stop old job"
  end subroutine test_pipeline_wait_observation

end program test_devloop_jobs
