module fgof_devloop
  use fgof_devloop_types, only : devloop_state
  implicit none
  private

  character(len=*), parameter :: FGOF_DEVLOOP_BACKEND_MODEL = "model"

  public :: clear_devloop_state
  public :: devloop_backend_name
  public :: devloop_state

contains

  function clear_devloop_state() result(state)
    type(devloop_state) :: state

    state%cycle_count = 0
    state%active = .false.
  end function clear_devloop_state

  function devloop_backend_name() result(name)
    character(len=:), allocatable :: name

    name = FGOF_DEVLOOP_BACKEND_MODEL
  end function devloop_backend_name

end module fgof_devloop
