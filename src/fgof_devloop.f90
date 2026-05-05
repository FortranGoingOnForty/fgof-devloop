module fgof_devloop
  use fgof_jobs, only : &
    attach_job, &
    attach_pipeline_members, &
    clear_job_handle, &
    clear_job_spec, &
    configure_job, &
    FGOF_JOBS_SIGNAL_SCOPE_GROUP, &
    FGOF_JOBS_TERMINAL_HANDOFF_FOREGROUND, &
    job_continue_result, &
    job_exit_result, &
    job_handle, &
    job_is_configured, &
    job_is_finished, &
    job_is_running, &
    job_is_stopped, &
    job_needs_cleanup, &
    job_owns_process_group, &
    job_requires_terminal_handoff, &
    job_result, &
    job_signal_result, &
    job_signal_scope, &
    job_spec, &
    job_stop_result, &
    make_job_spec, &
    observe_wait_result, &
    release_job
  use fgof_process, only : &
    FGOF_PROCESS_OK, &
    process_command, &
    process_options, &
    process_result, &
    run_process => run
  use fgof_watch_types, only : &
    FGOF_WATCH_EVT_CREATED, &
    FGOF_WATCH_EVT_MODIFIED, &
    FGOF_WATCH_EVT_MOVED, &
    FGOF_WATCH_EVT_NONE, &
    FGOF_WATCH_EVT_REMOVED, &
    watch_event, &
    watch_options
  use fgof_devloop_types, only : &
    FGOF_DEVLOOP_DECISION_IDLE, &
    FGOF_DEVLOOP_DECISION_RESTART, &
    FGOF_DEVLOOP_DECISION_RUN, &
    FGOF_DEVLOOP_DECISION_STOP, &
    FGOF_DEVLOOP_COMMAND_BUILD, &
    FGOF_DEVLOOP_COMMAND_NONE, &
    FGOF_DEVLOOP_COMMAND_RUN, &
    FGOF_DEVLOOP_COMMAND_SMOKE, &
    FGOF_DEVLOOP_JOB_ACTION_NONE, &
    FGOF_DEVLOOP_JOB_ACTION_RESTART, &
    FGOF_DEVLOOP_JOB_ACTION_START, &
    FGOF_DEVLOOP_JOB_ACTION_STOP, &
    FGOF_DEVLOOP_TRIGGER_CHANGE, &
    FGOF_DEVLOOP_TRIGGER_MANUAL, &
    FGOF_DEVLOOP_TRIGGER_NONE, &
    FGOF_DEVLOOP_TRIGGER_START, &
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
  private

  character(len=*), parameter :: FGOF_DEVLOOP_BACKEND_MODEL = "model"

  public :: begin_devloop_cycle
  public :: attach_devloop_job
  public :: attach_devloop_pipeline_members
  public :: clear_devloop_command_result
  public :: clear_devloop_command_spec
  public :: clear_devloop_cycle
  public :: clear_devloop_decision
  public :: clear_devloop_job_plan
  public :: clear_devloop_job_spec
  public :: clear_devloop_job_state
  public :: clear_devloop_options
  public :: clear_devloop_state
  public :: clear_devloop_supervision_result
  public :: clear_devloop_trigger
  public :: clear_devloop_watch_summary
  public :: devloop_backend_name
  public :: devloop_build_command
  public :: devloop_change_trigger
  public :: devloop_command_result
  public :: devloop_command_spec
  public :: devloop_cycle
  public :: devloop_decision
  public :: devloop_job_plan
  public :: devloop_job_restart_plan
  public :: devloop_job_spec
  public :: devloop_job_state
  public :: devloop_manual_trigger
  public :: devloop_options
  public :: devloop_run_command
  public :: devloop_service_job
  public :: devloop_smoke_command
  public :: devloop_start_trigger
  public :: devloop_state
  public :: devloop_supervision_result
  public :: devloop_summarize_watch_events
  public :: devloop_trigger
  public :: devloop_watch_failure_summary
  public :: devloop_watch_options
  public :: devloop_watch_summary
  public :: devloop_watch_trigger
  public :: finish_devloop_cycle
  public :: FGOF_DEVLOOP_DECISION_IDLE
  public :: FGOF_DEVLOOP_DECISION_RESTART
  public :: FGOF_DEVLOOP_DECISION_RUN
  public :: FGOF_DEVLOOP_DECISION_STOP
  public :: FGOF_DEVLOOP_COMMAND_BUILD
  public :: FGOF_DEVLOOP_COMMAND_NONE
  public :: FGOF_DEVLOOP_COMMAND_RUN
  public :: FGOF_DEVLOOP_COMMAND_SMOKE
  public :: FGOF_DEVLOOP_JOB_ACTION_NONE
  public :: FGOF_DEVLOOP_JOB_ACTION_RESTART
  public :: FGOF_DEVLOOP_JOB_ACTION_START
  public :: FGOF_DEVLOOP_JOB_ACTION_STOP
  public :: FGOF_DEVLOOP_TRIGGER_CHANGE
  public :: FGOF_DEVLOOP_TRIGGER_MANUAL
  public :: FGOF_DEVLOOP_TRIGGER_NONE
  public :: FGOF_DEVLOOP_TRIGGER_START
  public :: job_continue_result
  public :: job_exit_result
  public :: job_handle
  public :: job_result
  public :: job_signal_result
  public :: job_spec
  public :: job_stop_result
  public :: observe_devloop_job
  public :: release_devloop_job
  public :: run_devloop_command
  public :: run_devloop_cycle
  public :: should_start_on_open
  public :: start_devloop
  public :: stop_devloop

contains

  function clear_devloop_options() result(options)
    type(devloop_options) :: options

    options%run_on_start = .true.
    options%restart_on_change = .true.
    options%restart_on_directory_change = .true.
    options%ignore_hidden = .false.
    options%stop_on_failure = .false.
    options%max_failures = 0
    options%min_restart_changes = 1
    options%debounce_polls = 0
  end function clear_devloop_options

  function clear_devloop_trigger() result(trigger)
    type(devloop_trigger) :: trigger

    trigger%kind = FGOF_DEVLOOP_TRIGGER_NONE
    trigger%change_count = 0
    trigger%reason = ""
  end function clear_devloop_trigger

  function clear_devloop_cycle() result(cycle)
    type(devloop_cycle) :: cycle

    cycle%id = 0
    cycle%trigger_kind = FGOF_DEVLOOP_TRIGGER_NONE
    cycle%change_count = 0
    cycle%exit_code = 0
    cycle%started = .false.
    cycle%finished = .false.
    cycle%succeeded = .false.
    cycle%reason = ""
  end function clear_devloop_cycle

  function clear_devloop_decision() result(decision)
    type(devloop_decision) :: decision

    decision%kind = FGOF_DEVLOOP_DECISION_IDLE
    decision%cycle_id = 0
    decision%failure_count = 0
    decision%should_run = .false.
    decision%should_stop = .false.
    decision%reason = ""
  end function clear_devloop_decision

  function clear_devloop_watch_summary() result(summary)
    type(devloop_watch_summary) :: summary

    summary%event_count = 0
    summary%change_count = 0
    summary%file_change_count = 0
    summary%directory_change_count = 0
    summary%created_count = 0
    summary%modified_count = 0
    summary%removed_count = 0
    summary%moved_count = 0
    summary%ignored_none_count = 0
    summary%watch_error_code = 0
    summary%has_changes = .false.
    summary%watch_failed = .false.
    summary%watch_error_message = ""
  end function clear_devloop_watch_summary

  function clear_devloop_command_spec() result(spec)
    type(devloop_command_spec) :: spec

    spec%kind = FGOF_DEVLOOP_COMMAND_NONE
    spec%enabled = .false.
    spec%options = process_options()
    spec%label = ""
  end function clear_devloop_command_spec

  function clear_devloop_command_result() result(command_result)
    type(devloop_command_result) :: command_result

    command_result%kind = FGOF_DEVLOOP_COMMAND_NONE
    command_result%requested = .false.
    command_result%skipped = .true.
    command_result%launched = .false.
    command_result%completed = .false.
    command_result%succeeded = .false.
    command_result%timed_out = .false.
    command_result%exit_code = 0
    command_result%process_error_code = FGOF_PROCESS_OK
    command_result%process = clear_process_result()
    command_result%label = ""
    command_result%error_message = ""
  end function clear_devloop_command_result

  function clear_devloop_supervision_result() result(supervision)
    type(devloop_supervision_result) :: supervision

    supervision%cycle = clear_devloop_cycle()
    supervision%decision = clear_devloop_decision()
    supervision%build = clear_devloop_command_result()
    supervision%run = clear_devloop_command_result()
    supervision%smoke = clear_devloop_command_result()
    supervision%command_count = 0
    supervision%failed_command_kind = FGOF_DEVLOOP_COMMAND_NONE
    supervision%last_exit_code = 0
    supervision%process_error_code = FGOF_PROCESS_OK
    supervision%started = .false.
    supervision%succeeded = .false.
    supervision%failed = .false.
    supervision%timed_out = .false.
  end function clear_devloop_supervision_result

  function clear_devloop_job_spec() result(spec)
    type(devloop_job_spec) :: spec

    spec%job = clear_job_spec()
    spec%enabled = .false.
    spec%stop_before_restart = .true.
    spec%release_on_handoff = .false.
    spec%label = ""
  end function clear_devloop_job_spec

  function clear_devloop_job_state() result(job_state)
    type(devloop_job_state) :: job_state

    job_state%spec = clear_devloop_job_spec()
    job_state%handle = clear_job_handle()
    job_state%pid = 0
    job_state%process_group = 0
    job_state%signal_scope = FGOF_JOBS_SIGNAL_SCOPE_GROUP
    job_state%configured = .false.
    job_state%attached = .false.
    job_state%running = .false.
    job_state%stopped = .false.
    job_state%finished = .false.
    job_state%cleanup_needed = .false.
    job_state%owns_process_group = .false.
    job_state%terminal_handoff_required = .false.
    job_state%released = .false.
    job_state%label = ""
  end function clear_devloop_job_state

  function clear_devloop_job_plan() result(plan)
    type(devloop_job_plan) :: plan

    plan%action = FGOF_DEVLOOP_JOB_ACTION_NONE
    plan%pid = 0
    plan%process_group = 0
    plan%signal_scope = FGOF_JOBS_SIGNAL_SCOPE_GROUP
    plan%should_start = .false.
    plan%should_stop = .false.
    plan%should_restart = .false.
    plan%should_release = .false.
    plan%cleanup_needed = .false.
    plan%terminal_handoff_required = .false.
    plan%reason = ""
  end function clear_devloop_job_plan

  function clear_devloop_state() result(state)
    type(devloop_state) :: state

    state%options = clear_devloop_options()
    state%last_cycle = clear_devloop_cycle()
    state%cycle_count = 0
    state%consecutive_failures = 0
    state%active = .false.
    state%running = .false.
    state%stopped = .false.
  end function clear_devloop_state

  subroutine start_devloop(state, options)
    type(devloop_state), intent(inout) :: state
    type(devloop_options), intent(in), optional :: options

    state = clear_devloop_state()
    if (present(options)) then
      state%options = options
    end if
    call normalize_options(state%options)
    state%active = .true.
  end subroutine start_devloop

  subroutine stop_devloop(state)
    type(devloop_state), intent(inout) :: state

    state%active = .false.
    state%running = .false.
    state%stopped = .true.
  end subroutine stop_devloop

  function should_start_on_open(state) result(should_start)
    type(devloop_state), intent(in) :: state
    logical :: should_start

    should_start = state%active .and. state%options%run_on_start .and. &
                   .not. state%running .and. .not. state%stopped
  end function should_start_on_open

  function devloop_start_trigger() result(trigger)
    type(devloop_trigger) :: trigger

    trigger = clear_devloop_trigger()
    trigger%kind = FGOF_DEVLOOP_TRIGGER_START
    trigger%reason = "start"
  end function devloop_start_trigger

  function devloop_change_trigger(change_count, reason) result(trigger)
    integer, intent(in) :: change_count
    character(len=*), intent(in), optional :: reason
    type(devloop_trigger) :: trigger

    trigger = clear_devloop_trigger()
    trigger%kind = FGOF_DEVLOOP_TRIGGER_CHANGE
    trigger%change_count = max(0, change_count)
    if (present(reason)) then
      trigger%reason = reason
    else
      trigger%reason = "change"
    end if
  end function devloop_change_trigger

  function devloop_manual_trigger(reason) result(trigger)
    character(len=*), intent(in), optional :: reason
    type(devloop_trigger) :: trigger

    trigger = clear_devloop_trigger()
    trigger%kind = FGOF_DEVLOOP_TRIGGER_MANUAL
    if (present(reason)) then
      trigger%reason = reason
    else
      trigger%reason = "manual"
    end if
  end function devloop_manual_trigger

  function devloop_build_command(command_value, options, label) result(spec)
    type(process_command), intent(in) :: command_value
    type(process_options), intent(in), optional :: options
    character(len=*), intent(in), optional :: label
    type(devloop_command_spec) :: spec

    spec = make_devloop_command(FGOF_DEVLOOP_COMMAND_BUILD, command_value, options, label)
  end function devloop_build_command

  function devloop_run_command(command_value, options, label) result(spec)
    type(process_command), intent(in) :: command_value
    type(process_options), intent(in), optional :: options
    character(len=*), intent(in), optional :: label
    type(devloop_command_spec) :: spec

    spec = make_devloop_command(FGOF_DEVLOOP_COMMAND_RUN, command_value, options, label)
  end function devloop_run_command

  function devloop_smoke_command(command_value, options, label) result(spec)
    type(process_command), intent(in) :: command_value
    type(process_options), intent(in), optional :: options
    character(len=*), intent(in), optional :: label
    type(devloop_command_spec) :: spec

    spec = make_devloop_command(FGOF_DEVLOOP_COMMAND_SMOKE, command_value, options, label)
  end function devloop_smoke_command

  function devloop_service_job(command, argv, label, background, new_process_group, signal_scope, &
                               terminal_handoff, resume_sends_sigcont, stop_before_restart, &
                               release_on_handoff) result(spec)
    character(len=*), intent(in) :: command
    character(len=*), intent(in), optional :: argv(:)
    character(len=*), intent(in), optional :: label
    logical, intent(in), optional :: background
    logical, intent(in), optional :: new_process_group
    integer, intent(in), optional :: signal_scope
    integer, intent(in), optional :: terminal_handoff
    logical, intent(in), optional :: resume_sends_sigcont
    logical, intent(in), optional :: stop_before_restart
    logical, intent(in), optional :: release_on_handoff
    type(devloop_job_spec) :: spec
    logical :: actual_background
    logical :: actual_new_process_group
    integer :: actual_signal_scope
    integer :: actual_terminal_handoff
    logical :: actual_resume_sends_sigcont

    spec = clear_devloop_job_spec()

    actual_background = .true.
    if (present(background)) actual_background = background
    actual_new_process_group = .true.
    if (present(new_process_group)) actual_new_process_group = new_process_group
    actual_signal_scope = FGOF_JOBS_SIGNAL_SCOPE_GROUP
    if (present(signal_scope)) actual_signal_scope = signal_scope
    actual_terminal_handoff = FGOF_JOBS_TERMINAL_HANDOFF_FOREGROUND
    if (present(terminal_handoff)) actual_terminal_handoff = terminal_handoff
    actual_resume_sends_sigcont = .true.
    if (present(resume_sends_sigcont)) actual_resume_sends_sigcont = resume_sends_sigcont

    if (present(argv)) then
      spec%job = make_job_spec(command, argv, background=actual_background, &
                               new_process_group=actual_new_process_group, &
                               signal_scope=actual_signal_scope, &
                               terminal_handoff=actual_terminal_handoff, &
                               resume_sends_sigcont=actual_resume_sends_sigcont)
    else
      spec%job = make_job_spec(command, background=actual_background, &
                               new_process_group=actual_new_process_group, &
                               signal_scope=actual_signal_scope, &
                               terminal_handoff=actual_terminal_handoff, &
                               resume_sends_sigcont=actual_resume_sends_sigcont)
    end if

    spec%enabled = allocated(spec%job%command)
    if (present(stop_before_restart)) spec%stop_before_restart = stop_before_restart
    if (present(release_on_handoff)) spec%release_on_handoff = release_on_handoff
    if (present(label)) then
      spec%label = label
    else if (allocated(spec%job%command)) then
      spec%label = spec%job%command
    end if
  end function devloop_service_job

  function devloop_summarize_watch_events(events) result(summary)
    type(watch_event), intent(in) :: events(:)
    type(devloop_watch_summary) :: summary
    integer :: index_value

    summary = clear_devloop_watch_summary()
    summary%event_count = size(events)

    do index_value = 1, size(events)
      select case (events(index_value)%kind)
      case (FGOF_WATCH_EVT_CREATED)
        summary%created_count = summary%created_count + 1
      case (FGOF_WATCH_EVT_MODIFIED)
        summary%modified_count = summary%modified_count + 1
      case (FGOF_WATCH_EVT_REMOVED)
        summary%removed_count = summary%removed_count + 1
      case (FGOF_WATCH_EVT_MOVED)
        summary%moved_count = summary%moved_count + 1
      case default
        summary%ignored_none_count = summary%ignored_none_count + 1
        cycle
      end select

      summary%change_count = summary%change_count + 1
      if (events(index_value)%is_directory) then
        summary%directory_change_count = summary%directory_change_count + 1
      else
        summary%file_change_count = summary%file_change_count + 1
      end if
    end do

    summary%has_changes = summary%change_count > 0
  end function devloop_summarize_watch_events

  function devloop_watch_failure_summary(error_code, message) result(summary)
    integer, intent(in) :: error_code
    character(len=*), intent(in) :: message
    type(devloop_watch_summary) :: summary

    summary = clear_devloop_watch_summary()
    summary%watch_error_code = error_code
    summary%watch_failed = error_code /= 0
    summary%watch_error_message = message
  end function devloop_watch_failure_summary

  function devloop_watch_options(options) result(watch_config)
    type(devloop_options), intent(in), optional :: options
    type(watch_options) :: watch_config
    type(devloop_options) :: local_options

    local_options = clear_devloop_options()
    if (present(options)) local_options = options
    call normalize_options(local_options)

    watch_config = watch_options()
    watch_config%debounce_polls = local_options%debounce_polls
    watch_config%ignore_hidden = local_options%ignore_hidden
    watch_config%emit_directory_events = local_options%restart_on_directory_change
  end function devloop_watch_options

  function devloop_watch_trigger(summary, options, reason) result(trigger)
    type(devloop_watch_summary), intent(in) :: summary
    type(devloop_options), intent(in), optional :: options
    character(len=*), intent(in), optional :: reason
    type(devloop_trigger) :: trigger
    type(devloop_options) :: local_options
    integer :: effective_change_count

    trigger = clear_devloop_trigger()
    if (summary%watch_failed) return
    if (.not. summary%has_changes) return

    local_options = clear_devloop_options()
    if (present(options)) local_options = options
    call normalize_options(local_options)

    if (.not. local_options%restart_on_change) return

    effective_change_count = summary%change_count
    if (.not. local_options%restart_on_directory_change) then
      effective_change_count = summary%file_change_count
    end if

    if (effective_change_count < local_options%min_restart_changes) return

    if (present(reason)) then
      trigger = devloop_change_trigger(effective_change_count, reason)
    else
      trigger = devloop_change_trigger(effective_change_count, "watch")
    end if
  end function devloop_watch_trigger

  function run_devloop_command(spec) result(command_result)
    type(devloop_command_spec), intent(in) :: spec
    type(devloop_command_result) :: command_result
    type(process_result) :: process_run_result

    command_result = clear_devloop_command_result()
    command_result%kind = spec%kind
    command_result%label = command_kind_label(spec%kind)
    if (allocated(spec%label)) then
      if (len(spec%label) > 0) command_result%label = spec%label
    end if

    if (.not. spec%enabled) return

    command_result%requested = .true.
    command_result%skipped = .false.
    process_run_result = run_process(spec%command, spec%options)
    command_result%process = process_run_result
    command_result%launched = process_run_result%launched
    command_result%completed = process_run_result%completed
    command_result%timed_out = process_run_result%timed_out
    command_result%exit_code = process_run_result%exit_code
    command_result%process_error_code = process_run_result%error_code
    command_result%error_message = process_run_result%error_message
    command_result%succeeded = process_run_result%error_code == FGOF_PROCESS_OK .and. &
                               process_run_result%completed .and. &
                               process_run_result%exited_normally .and. &
                               process_run_result%exit_code == 0
  end function run_devloop_command

  function run_devloop_cycle(state, trigger, build_command, run_command, smoke_command) result(supervision)
    type(devloop_state), intent(inout) :: state
    type(devloop_trigger), intent(in) :: trigger
    type(devloop_command_spec), intent(in), optional :: build_command
    type(devloop_command_spec), intent(in), optional :: run_command
    type(devloop_command_spec), intent(in), optional :: smoke_command
    type(devloop_supervision_result) :: supervision
    logical :: should_continue

    supervision = clear_devloop_supervision_result()
    supervision%cycle = begin_devloop_cycle(state, trigger)
    supervision%started = supervision%cycle%started
    if (.not. supervision%started) return

    should_continue = .true.
    if (present(build_command)) then
      supervision%build = run_devloop_command(build_command)
      call record_supervised_command(supervision, supervision%build, should_continue)
    end if

    if (should_continue .and. present(run_command)) then
      supervision%run = run_devloop_command(run_command)
      call record_supervised_command(supervision, supervision%run, should_continue)
    end if

    if (should_continue .and. present(smoke_command)) then
      supervision%smoke = run_devloop_command(smoke_command)
      call record_supervised_command(supervision, supervision%smoke, should_continue)
    end if

    supervision%succeeded = should_continue
    supervision%failed = .not. should_continue
    supervision%decision = finish_devloop_cycle(state, supervision%succeeded, supervision%last_exit_code)
  end function run_devloop_cycle

  function attach_devloop_job(spec, pid, process_group, owns_process, owns_process_group) result(job_state)
    type(devloop_job_spec), intent(in) :: spec
    integer, intent(in) :: pid
    integer, intent(in), optional :: process_group
    logical, intent(in), optional :: owns_process
    logical, intent(in), optional :: owns_process_group
    type(devloop_job_state) :: job_state
    integer :: actual_process_group
    logical :: actual_owns_process
    logical :: actual_owns_process_group

    job_state = clear_devloop_job_state()
    if (.not. spec%enabled) return

    job_state%spec = spec
    call configure_job(job_state%handle, spec%job)

    actual_process_group = pid
    if (present(process_group)) actual_process_group = process_group
    actual_owns_process = .true.
    if (present(owns_process)) actual_owns_process = owns_process
    actual_owns_process_group = actual_owns_process .and. spec%job%new_process_group .and. &
                                actual_process_group == pid
    if (present(owns_process_group)) actual_owns_process_group = owns_process_group

    call attach_job(job_state%handle, pid, process_group=actual_process_group, &
                    owns_process=actual_owns_process, owns_process_group=actual_owns_process_group)
    call refresh_devloop_job_state(job_state)
  end function attach_devloop_job

  subroutine attach_devloop_pipeline_members(job_state, pids)
    type(devloop_job_state), intent(inout) :: job_state
    integer, intent(in) :: pids(:)

    call attach_pipeline_members(job_state%handle, pids)
    call refresh_devloop_job_state(job_state)
  end subroutine attach_devloop_pipeline_members

  subroutine observe_devloop_job(job_state, result_value)
    type(devloop_job_state), intent(inout) :: job_state
    type(job_result), intent(in) :: result_value

    call observe_wait_result(job_state%handle, result_value)
    call refresh_devloop_job_state(job_state)
  end subroutine observe_devloop_job

  subroutine release_devloop_job(job_state)
    type(devloop_job_state), intent(inout) :: job_state

    call release_job(job_state%handle)
    job_state%released = .true.
    call refresh_devloop_job_state(job_state)
  end subroutine release_devloop_job

  function devloop_job_restart_plan(job_state, trigger) result(plan)
    type(devloop_job_state), intent(in) :: job_state
    type(devloop_trigger), intent(in) :: trigger
    type(devloop_job_plan) :: plan

    plan = clear_devloop_job_plan()
    plan%pid = job_state%pid
    plan%process_group = job_state%process_group
    plan%signal_scope = job_state%signal_scope
    plan%cleanup_needed = job_state%cleanup_needed
    plan%terminal_handoff_required = job_state%terminal_handoff_required

    if (.not. job_state%spec%enabled) return
    if (.not. job_state%configured) return
    if (trigger%kind == FGOF_DEVLOOP_TRIGGER_NONE) return
    if (job_state%released) then
      plan%reason = "job released"
      return
    end if

    if (job_state%terminal_handoff_required .and. job_state%spec%release_on_handoff) then
      plan%should_release = .true.
    end if

    if (job_state%running .or. job_state%stopped .or. job_state%cleanup_needed) then
      plan%action = FGOF_DEVLOOP_JOB_ACTION_RESTART
      plan%should_restart = .true.
      plan%should_start = .true.
      plan%should_stop = job_state%spec%stop_before_restart
      plan%reason = "restart existing job"
    else
      plan%action = FGOF_DEVLOOP_JOB_ACTION_START
      plan%should_start = .true.
      plan%reason = "start job"
    end if
  end function devloop_job_restart_plan

  function begin_devloop_cycle(state, trigger) result(cycle)
    type(devloop_state), intent(inout) :: state
    type(devloop_trigger), intent(in) :: trigger
    type(devloop_cycle) :: cycle

    cycle = clear_devloop_cycle()
    if (.not. state%active) return
    if (state%running) return
    if (state%stopped) return
    if (trigger%kind == FGOF_DEVLOOP_TRIGGER_NONE) return
    if (trigger%kind == FGOF_DEVLOOP_TRIGGER_CHANGE .and. .not. state%options%restart_on_change) return

    state%cycle_count = state%cycle_count + 1
    state%running = .true.

    cycle%id = state%cycle_count
    cycle%trigger_kind = trigger%kind
    cycle%change_count = trigger%change_count
    cycle%started = .true.
    cycle%reason = trigger%reason
    state%last_cycle = cycle
  end function begin_devloop_cycle

  function finish_devloop_cycle(state, succeeded, exit_code) result(decision)
    type(devloop_state), intent(inout) :: state
    logical, intent(in) :: succeeded
    integer, intent(in), optional :: exit_code
    type(devloop_decision) :: decision
    integer :: actual_exit_code

    decision = clear_devloop_decision()
    if (.not. state%running) return

    actual_exit_code = 0
    if (present(exit_code)) actual_exit_code = exit_code

    state%running = .false.
    state%last_cycle%finished = .true.
    state%last_cycle%succeeded = succeeded
    state%last_cycle%exit_code = actual_exit_code

    decision%cycle_id = state%last_cycle%id

    if (succeeded) then
      state%consecutive_failures = 0
      decision%kind = FGOF_DEVLOOP_DECISION_IDLE
      decision%reason = "cycle succeeded"
      return
    end if

    state%consecutive_failures = state%consecutive_failures + 1
    decision%failure_count = state%consecutive_failures
    if (state%options%stop_on_failure .or. failure_limit_reached(state)) then
      decision%kind = FGOF_DEVLOOP_DECISION_STOP
      decision%should_stop = .true.
      decision%reason = "failure policy stopped the loop"
      call stop_devloop(state)
    else
      decision%kind = FGOF_DEVLOOP_DECISION_RESTART
      decision%should_run = .true.
      decision%reason = "cycle failed; restart allowed"
    end if
  end function finish_devloop_cycle

  function devloop_backend_name() result(name)
    character(len=:), allocatable :: name

    name = FGOF_DEVLOOP_BACKEND_MODEL
  end function devloop_backend_name

  function make_devloop_command(kind, command_value, options, label) result(spec)
    integer, intent(in) :: kind
    type(process_command), intent(in) :: command_value
    type(process_options), intent(in), optional :: options
    character(len=*), intent(in), optional :: label
    type(devloop_command_spec) :: spec

    spec = clear_devloop_command_spec()
    spec%kind = kind
    spec%enabled = .true.
    spec%command = command_value
    spec%options = process_options()
    if (present(options)) spec%options = options
    if (present(label)) then
      spec%label = label
    else
      spec%label = command_kind_label(kind)
    end if
  end function make_devloop_command

  function clear_process_result() result(process_run_result)
    type(process_result) :: process_run_result

    process_run_result%launched = .false.
    process_run_result%completed = .false.
    process_run_result%timed_out = .false.
    process_run_result%exited_normally = .false.
    process_run_result%exit_code = -1
    process_run_result%term_signal = 0
    process_run_result%stdout = ""
    process_run_result%stderr = ""
    process_run_result%error_code = FGOF_PROCESS_OK
    process_run_result%error_message = ""
    process_run_result%elapsed_ms = 0
  end function clear_process_result

  function command_kind_label(kind) result(label)
    integer, intent(in) :: kind
    character(len=:), allocatable :: label

    select case (kind)
    case (FGOF_DEVLOOP_COMMAND_BUILD)
      label = "build"
    case (FGOF_DEVLOOP_COMMAND_RUN)
      label = "run"
    case (FGOF_DEVLOOP_COMMAND_SMOKE)
      label = "smoke"
    case default
      label = "none"
    end select
  end function command_kind_label

  subroutine record_supervised_command(supervision, command_result, should_continue)
    type(devloop_supervision_result), intent(inout) :: supervision
    type(devloop_command_result), intent(in) :: command_result
    logical, intent(inout) :: should_continue

    if (.not. command_result%requested) return

    supervision%command_count = supervision%command_count + 1
    supervision%last_exit_code = command_result%exit_code

    if (command_result%succeeded) return

    should_continue = .false.
    supervision%failed_command_kind = command_result%kind
    supervision%process_error_code = command_result%process_error_code
    supervision%timed_out = command_result%timed_out
  end subroutine record_supervised_command

  subroutine refresh_devloop_job_state(job_state)
    type(devloop_job_state), intent(inout) :: job_state
    logical :: was_released

    was_released = job_state%released
    job_state%configured = job_is_configured(job_state%handle)
    job_state%attached = job_state%handle%pid > 0
    job_state%pid = job_state%handle%pid
    job_state%process_group = job_state%handle%process_group
    job_state%signal_scope = job_signal_scope(job_state%handle)
    job_state%running = job_is_running(job_state%handle)
    job_state%stopped = job_is_stopped(job_state%handle)
    job_state%finished = job_is_finished(job_state%handle)
    job_state%cleanup_needed = job_needs_cleanup(job_state%handle)
    job_state%owns_process_group = job_owns_process_group(job_state%handle)
    job_state%terminal_handoff_required = job_requires_terminal_handoff(job_state%handle)
    job_state%released = was_released
    job_state%label = ""
    if (allocated(job_state%spec%label)) job_state%label = job_state%spec%label
  end subroutine refresh_devloop_job_state

  subroutine normalize_options(options)
    type(devloop_options), intent(inout) :: options

    if (options%max_failures < 0) options%max_failures = 0
    if (options%min_restart_changes < 1) options%min_restart_changes = 1
    if (options%debounce_polls < 0) options%debounce_polls = 0
  end subroutine normalize_options

  logical function failure_limit_reached(state) result(reached)
    type(devloop_state), intent(in) :: state

    reached = state%options%max_failures > 0 .and. &
              state%consecutive_failures >= state%options%max_failures
  end function failure_limit_reached

end module fgof_devloop
