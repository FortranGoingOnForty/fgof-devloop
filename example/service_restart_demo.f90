program service_restart_demo
  use fgof_devloop, only : &
    FGOF_DEVLOOP_JOB_ACTION_NONE, &
    FGOF_DEVLOOP_JOB_ACTION_RESTART, &
    attach_devloop_job, &
    devloop_change_trigger, &
    devloop_job_restart_plan, &
    devloop_service_job, &
    release_devloop_job
  use fgof_devloop_types, only : &
    devloop_job_plan, &
    devloop_job_spec, &
    devloop_job_state
  implicit none

  type(devloop_job_spec) :: spec
  type(devloop_job_state) :: job
  type(devloop_job_plan) :: plan
  type(devloop_job_plan) :: released_plan

  spec = devloop_service_job("serve-example", label="example service")
  job = attach_devloop_job(spec, pid=4242, process_group=4242)
  plan = devloop_job_restart_plan(job, devloop_change_trigger(1, "source changed"))

  if (plan%action /= FGOF_DEVLOOP_JOB_ACTION_RESTART) then
    error stop "running service should plan a restart"
  end if
  if (.not. plan%should_stop) error stop "restart plan should stop the old service"
  if (.not. plan%should_start) error stop "restart plan should start the replacement"

  call release_devloop_job(job)
  released_plan = devloop_job_restart_plan(job, devloop_change_trigger(1, "after release"))
  if (released_plan%action /= FGOF_DEVLOOP_JOB_ACTION_NONE) then
    error stop "released service should no longer be managed"
  end if

  print '(a,i0)', "managed pid: ", plan%pid
  print '(a)', "restart reason: " // plan%reason
  print '(a)', "released reason: " // released_plan%reason
end program service_restart_demo
