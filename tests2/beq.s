.include "startup.s"

main:
    # Test 1: beq with equal registers (positive)
    li t0, 10
    li t1, 10
    beq t0, t1, test2_unequal_registers # Jump if t0 == t1 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test2_unequal_registers:
    # Test 2: beq with unequal registers (positive)
    li t0, 10
    li t1, 11
    beq t0, t1, test3_equal_negative # Should NOT jump, continue to failure
    # Fall through to failure if branch incorrectly taken
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test3_equal_negative:
    # Test 3: beq with equal registers (negative)
    li t0, -5
    li t1, -5
    beq t0, t1, test4_unequal_negative # Jump if t0 == t1 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test4_unequal_negative:
    # Test 4: beq with unequal registers (negative)
    li t0, -5
    li t1, -6
    beq t0, t1, test5_equal_zero # Should NOT jump, continue to failure
    # Fall through to failure if branch incorrectly taken
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test5_equal_zero:
    # Test 5: beq with equal zero registers
    li t0, 0
    li t1, 0
    beq t0, t1, test6_large_equal # Jump if t0 == t1 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test6_large_equal:
    # Test 6: beq with large equal values
    li t0, 0x7FFFFFFF # Maximum positive 32-bit integer
    li t1, 0x7FFFFFFF
    beq t0, t1, success # Jump if t0 == t1 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit


success:
    addi a0, zero, 0  # Success: exit code 0

exit:
    ret
