program test_devloop_watch
  use fgof_devloop, only : &
    FGOF_DEVLOOP_TRIGGER_CHANGE, &
    FGOF_DEVLOOP_TRIGGER_NONE, &
    begin_devloop_cycle, &
    clear_devloop_options, &
    devloop_summarize_watch_events, &
    devloop_watch_failure_summary, &
    devloop_watch_options, &
    devloop_watch_trigger, &
    start_devloop
  use fgof_devloop_types, only : &
    devloop_cycle, &
    devloop_options, &
    devloop_state, &
    devloop_trigger, &
    devloop_watch_summary
  use fgof_watch_types, only : &
    FGOF_WATCH_EVT_CREATED, &
    FGOF_WATCH_EVT_MODIFIED, &
    FGOF_WATCH_EVT_MOVED, &
    FGOF_WATCH_EVT_NONE, &
    FGOF_WATCH_EVT_REMOVED, &
    watch_event, &
    watch_options
  implicit none

  type(watch_event) :: events(5)
  type(devloop_watch_summary) :: summary
  type(devloop_options) :: options
  type(devloop_trigger) :: trigger
  type(devloop_state) :: state
  type(devloop_cycle) :: cycle
  type(watch_options) :: watch_config

  events(1)%kind = FGOF_WATCH_EVT_CREATED
  events(1)%path = "src/main.f90"
  events(2)%kind = FGOF_WATCH_EVT_MODIFIED
  events(2)%path = "src/lib.f90"
  events(3)%kind = FGOF_WATCH_EVT_REMOVED
  events(3)%path = "build"
  events(3)%is_directory = .true.
  events(4)%kind = FGOF_WATCH_EVT_MOVED
  events(4)%path = "test/new.f90"
  events(4)%previous_path = "test/old.f90"
  events(5)%kind = FGOF_WATCH_EVT_NONE

  summary = devloop_summarize_watch_events(events)
  if (summary%event_count /= 5) error stop "watch summary should preserve event count"
  if (summary%change_count /= 4) error stop "watch summary should count meaningful changes"
  if (summary%file_change_count /= 3) error stop "watch summary should count file changes"
  if (summary%directory_change_count /= 1) error stop "watch summary should count directory changes"
  if (summary%created_count /= 1) error stop "watch summary should count creates"
  if (summary%modified_count /= 1) error stop "watch summary should count modifies"
  if (summary%removed_count /= 1) error stop "watch summary should count removes"
  if (summary%moved_count /= 1) error stop "watch summary should count moves"
  if (summary%ignored_none_count /= 1) error stop "watch summary should ignore none events"
  if (.not. summary%has_changes) error stop "watch summary should report changes"

  options = clear_devloop_options()
  options%debounce_polls = 2
  options%ignore_hidden = .true.
  options%restart_on_directory_change = .false.
  watch_config = devloop_watch_options(options)
  if (watch_config%debounce_polls /= 2) error stop "watch options should carry debounce policy"
  if (.not. watch_config%ignore_hidden) error stop "watch options should carry hidden-path policy"
  if (watch_config%emit_directory_events) error stop "watch options should suppress directory events when requested"

  options%debounce_polls = -3
  watch_config = devloop_watch_options(options)
  if (watch_config%debounce_polls /= 0) error stop "watch options should clamp negative debounce"

  trigger = devloop_watch_trigger(summary)
  if (trigger%kind /= FGOF_DEVLOOP_TRIGGER_CHANGE) error stop "watch changes should create a change trigger"
  if (trigger%change_count /= 4) error stop "watch trigger should carry the change count"

  options = clear_devloop_options()
  options%restart_on_change = .false.
  trigger = devloop_watch_trigger(summary, options)
  if (trigger%kind /= FGOF_DEVLOOP_TRIGGER_NONE) then
    error stop "restart-on-change policy should suppress watch triggers"
  end if

  options = clear_devloop_options()
  options%restart_on_directory_change = .false.
  options%min_restart_changes = 4
  trigger = devloop_watch_trigger(summary, options)
  if (trigger%kind /= FGOF_DEVLOOP_TRIGGER_NONE) then
    error stop "directory-filtered changes below threshold should not restart"
  end if

  options%min_restart_changes = 3
  trigger = devloop_watch_trigger(summary, options, "filtered watch")
  if (trigger%kind /= FGOF_DEVLOOP_TRIGGER_CHANGE) error stop "file changes at threshold should restart"
  if (trigger%change_count /= 3) error stop "filtered watch trigger should carry file count"
  if (trigger%reason /= "filtered watch") error stop "watch trigger should preserve custom reason"

  summary = devloop_watch_failure_summary(7, "snapshot failed")
  if (.not. summary%watch_failed) error stop "watch failure summary should record failure"
  trigger = devloop_watch_trigger(summary)
  if (trigger%kind /= FGOF_DEVLOOP_TRIGGER_NONE) error stop "watch failures should not force restart triggers"

  call start_devloop(state)
  summary = devloop_summarize_watch_events(events(1:2))
  trigger = devloop_watch_trigger(summary)
  cycle = begin_devloop_cycle(state, trigger)
  if (.not. cycle%started) error stop "watch trigger should drive the devloop cycle model"
  if (cycle%change_count /= 2) error stop "watch cycle should preserve trigger change count"
end program test_devloop_watch
