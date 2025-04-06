.include "startup.s"

.align 7
# Interrupt handler
interrupt_handler:
    li a0, 0
    j _exit

main:
    # Set the mtvec to the interrupt handler
    la t0, interrupt_handler
    csrw mtvec, t0

    # Enable global interrupts
    li t0, 0x8
    csrs mstatus, t0

    # Enable external interrupts
    li t0, 0x800
    csrs mie, t0

    # wait for interrupt
    wfi
