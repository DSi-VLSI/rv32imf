.include "startup.s"

main:
    # Test 1: auipc with positive immediate
    auipc t0, 0x12345
    li t1, 0x12345000
    add t1, t1, %pcrel_hi(main)
    beq t0, t1, test2_zero_immediate # Jump if t0 == t1 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test2_zero_immediate:
    # Test 2: auipc with zero immediate
    auipc t0, 0x0
    mv t1, pc # PC relative to current instruction
    beq t0, t1, test3_max_positive_immediate # Jump if t0 == t1 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test3_max_positive_immediate:
    # Test 3: auipc with maximum positive immediate (20-bit max)
    auipc t0, 0xFFFFF
    li t1, 0xFFFFF000
    add t1, t1, %pcrel_hi(main)
    beq t0, t1, test4_small_positive_immediate # Jump if t0 == t1 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test4_small_positive_immediate:
    # Test 4: auipc with a smaller positive immediate
    auipc t0, 0x1
    li t1, 0x1000
    add t1, t1, %pcrel_hi(main)
    beq t0, t1, success # Jump if t0 == t1 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

success:
    addi a0, zero, 0  # Success: exit code 0

exit:
    ret
