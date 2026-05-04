module fgof_devloop_types
  implicit none
  private

  type, public :: devloop_state
    integer :: cycle_count = 0
    logical :: active = .false.
  end type devloop_state

end module fgof_devloop_types
