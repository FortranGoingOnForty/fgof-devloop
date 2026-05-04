module fgof_devloop
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
    FGOF_DEVLOOP_TRIGGER_CHANGE, &
    FGOF_DEVLOOP_TRIGGER_MANUAL, &
    FGOF_DEVLOOP_TRIGGER_NONE, &
    FGOF_DEVLOOP_TRIGGER_START, &
    devloop_cycle, &
    devloop_decision, &
    devloop_options, &
    devloop_state, &
    devloop_trigger, &
    devloop_watch_summary
  implicit none
  private

  character(len=*), parameter :: FGOF_DEVLOOP_BACKEND_MODEL = "model"

  public :: begin_devloop_cycle
  public :: clear_devloop_cycle
  public :: clear_devloop_decision
  public :: clear_devloop_options
  public :: clear_devloop_state
  public :: clear_devloop_trigger
  public :: clear_devloop_watch_summary
  public :: devloop_backend_name
  public :: devloop_change_trigger
  public :: devloop_cycle
  public :: devloop_decision
  public :: devloop_manual_trigger
  public :: devloop_options
  public :: devloop_start_trigger
  public :: devloop_state
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
  public :: FGOF_DEVLOOP_TRIGGER_CHANGE
  public :: FGOF_DEVLOOP_TRIGGER_MANUAL
  public :: FGOF_DEVLOOP_TRIGGER_NONE
  public :: FGOF_DEVLOOP_TRIGGER_START
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
