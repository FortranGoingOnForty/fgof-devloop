module fgof_devloop_types
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
