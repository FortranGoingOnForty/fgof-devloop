program test_scaffold
  use fgof_devloop, only : clear_devloop_state, devloop_backend_name
  use fgof_devloop_types, only : devloop_state
  implicit none

  type(devloop_state) :: state

  state = clear_devloop_state()
  if (state%cycle_count /= 0) error stop "devloop state should start with no cycles"
  if (state%active) error stop "devloop state should start inactive"
  if (devloop_backend_name() /= "model") error stop "devloop backend should report model"
end program test_scaffold
