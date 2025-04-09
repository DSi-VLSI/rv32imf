.include "startup.s"

.align 7
# trap handler
trap_handler:
    li a0, 0
    j _exit

main:

    # Set up the trap handler
    la t0, trap_handler
    csrw mtvec, t0

    # Enable interrupts
    csrs mstatus, t0

    # Illegal Instruction
    csrr t0, TIME

    # Test Fail
    li a0, 1
    j _exit
