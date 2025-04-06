.include "startup.s"

main:
    # Test 1: lui with positive immediate
    lui t0, 0x12345
    li t1, 0x12345000
    beq t0, t1, test2_zero_immediate # Jump if t0 == t1 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test2_zero_immediate:
    # Test 2: lui with zero immediate
    lui t0, 0x0
    li t1, 0x00000000
    beq t0, t1, test3_max_positive_immediate # Jump if t0 == t1 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test3_max_positive_immediate:
    # Test 3: lui with maximum positive immediate (20-bit max)
    lui t0, 0xFFFFF
    li t1, 0xFFFFF000
    beq t0, t1, test4_small_positive_immediate # Jump if t0 == t1 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test4_small_positive_immediate:
    # Test 4: lui with a smaller positive immediate
    lui t0, 0x1
    li t1, 0x00001000
    beq t0, t1, success # Jump if t0 == t1 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

success:
    addi a0, zero, 0  # Success: exit code 0

exit:
    ret
