module fgof_devloop_types
  use fgof_jobs_types, only : &
    job_handle, &
    job_result, &
    job_spec
  use fgof_process_types, only : &
    FGOF_PROCESS_OK, &
    process_command, &
    process_options, &
    process_result
  implicit none
  private

  integer, parameter, public :: FGOF_DEVLOOP_TRIGGER_NONE = 0
  integer, parameter, public :: FGOF_DEVLOOP_TRIGGER_START = 1
  integer, parameter, public :: FGOF_DEVLOOP_TRIGGER_CHANGE = 2
  integer, parameter, public :: FGOF_DEVLOOP_TRIGGER_MANUAL = 3
  integer, parameter, public :: FGOF_DEVLOOP_DECISION_IDLE = 0
  integer, parameter, public :: FGOF_DEVLOOP_DECISION_RUN = 1
  integer, parameter, public :: FGOF_DEVLOOP_DECISION_RESTART = 2
  integer, parameter, public :: FGOF_DEVLOOP_DECISION_STOP = 3
  integer, parameter, public :: FGOF_DEVLOOP_COMMAND_NONE = 0
  integer, parameter, public :: FGOF_DEVLOOP_COMMAND_BUILD = 1
  integer, parameter, public :: FGOF_DEVLOOP_COMMAND_RUN = 2
  integer, parameter, public :: FGOF_DEVLOOP_COMMAND_SMOKE = 3
  integer, parameter, public :: FGOF_DEVLOOP_JOB_ACTION_NONE = 0
  integer, parameter, public :: FGOF_DEVLOOP_JOB_ACTION_START = 1
  integer, parameter, public :: FGOF_DEVLOOP_JOB_ACTION_STOP = 2
  integer, parameter, public :: FGOF_DEVLOOP_JOB_ACTION_RESTART = 3

  public :: job_handle
  public :: job_result
  public :: job_spec
  public :: process_command
  public :: process_options
  public :: process_result

  type, public :: devloop_options
    logical :: run_on_start = .true.
    logical :: restart_on_change = .true.
    logical :: restart_on_directory_change = .true.
    logical :: ignore_hidden = .false.
    logical :: stop_on_failure = .false.
    integer :: max_failures = 0
    integer :: min_restart_changes = 1
    integer :: debounce_polls = 0
  end type devloop_options

  type, public :: devloop_trigger
    integer :: kind = FGOF_DEVLOOP_TRIGGER_NONE
    integer :: change_count = 0
    character(len=:), allocatable :: reason
  end type devloop_trigger

  type, public :: devloop_cycle
    integer :: id = 0
    integer :: trigger_kind = FGOF_DEVLOOP_TRIGGER_NONE
    integer :: change_count = 0
    integer :: exit_code = 0
    logical :: started = .false.
    logical :: finished = .false.
    logical :: succeeded = .false.
    character(len=:), allocatable :: reason
  end type devloop_cycle

  type, public :: devloop_decision
    integer :: kind = FGOF_DEVLOOP_DECISION_IDLE
    integer :: cycle_id = 0
    integer :: failure_count = 0
    logical :: should_run = .false.
    logical :: should_stop = .false.
    character(len=:), allocatable :: reason
  end type devloop_decision

  type, public :: devloop_watch_summary
    integer :: event_count = 0
    integer :: change_count = 0
    integer :: file_change_count = 0
    integer :: directory_change_count = 0
    integer :: created_count = 0
    integer :: modified_count = 0
    integer :: removed_count = 0
    integer :: moved_count = 0
    integer :: ignored_none_count = 0
    integer :: watch_error_code = 0
    logical :: has_changes = .false.
    logical :: watch_failed = .false.
    character(len=:), allocatable :: watch_error_message
  end type devloop_watch_summary

  type, public :: devloop_command_spec
    integer :: kind = FGOF_DEVLOOP_COMMAND_NONE
    logical :: enabled = .false.
    type(process_command) :: command
    type(process_options) :: options
    character(len=:), allocatable :: label
  end type devloop_command_spec

  type, public :: devloop_command_result
    integer :: kind = FGOF_DEVLOOP_COMMAND_NONE
    logical :: requested = .false.
    logical :: skipped = .true.
    logical :: launched = .false.
    logical :: completed = .false.
    logical :: succeeded = .false.
    logical :: timed_out = .false.
    integer :: exit_code = 0
    integer :: process_error_code = FGOF_PROCESS_OK
    type(process_result) :: process
    character(len=:), allocatable :: label
    character(len=:), allocatable :: error_message
  end type devloop_command_result

  type, public :: devloop_supervision_result
    type(devloop_cycle) :: cycle
    type(devloop_decision) :: decision
    type(devloop_command_result) :: build
    type(devloop_command_result) :: run
    type(devloop_command_result) :: smoke
    integer :: command_count = 0
    integer :: failed_command_kind = FGOF_DEVLOOP_COMMAND_NONE
    integer :: last_exit_code = 0
    integer :: process_error_code = FGOF_PROCESS_OK
    logical :: started = .false.
    logical :: succeeded = .false.
    logical :: failed = .false.
    logical :: timed_out = .false.
  end type devloop_supervision_result

  type, public :: devloop_job_spec
    type(job_spec) :: job
    logical :: enabled = .false.
    logical :: stop_before_restart = .true.
    logical :: release_on_handoff = .false.
    character(len=:), allocatable :: label
  end type devloop_job_spec

  type, public :: devloop_job_state
    type(devloop_job_spec) :: spec
    type(job_handle) :: handle
    integer :: pid = 0
    integer :: process_group = 0
    integer :: signal_scope = 0
    logical :: configured = .false.
    logical :: attached = .false.
    logical :: running = .false.
    logical :: stopped = .false.
    logical :: finished = .false.
    logical :: cleanup_needed = .false.
    logical :: owns_process_group = .false.
    logical :: terminal_handoff_required = .false.
    logical :: released = .false.
    character(len=:), allocatable :: label
  end type devloop_job_state

  type, public :: devloop_job_plan
    integer :: action = FGOF_DEVLOOP_JOB_ACTION_NONE
    integer :: pid = 0
    integer :: process_group = 0
    integer :: signal_scope = 0
    logical :: should_start = .false.
    logical :: should_stop = .false.
    logical :: should_restart = .false.
    logical :: should_release = .false.
    logical :: cleanup_needed = .false.
    logical :: terminal_handoff_required = .false.
    character(len=:), allocatable :: reason
  end type devloop_job_plan

  type, public :: devloop_state
    type(devloop_options) :: options
    type(devloop_cycle) :: last_cycle
    integer :: cycle_count = 0
    integer :: consecutive_failures = 0
    logical :: active = .false.
    logical :: running = .false.
    logical :: stopped = .false.
  end type devloop_state

end module fgof_devloop_types
