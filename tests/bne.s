.include "startup.s"

main:
    # Test 1: bne with different registers (positive)
    li t0, 10
    li t1, 20
    bne t0, t1, test2_equal_registers # Jump if t0 != t1 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test2_equal_registers:
    # Test 2: bne with equal registers (positive) - Should NOT jump
    li t0, 15
    li t1, 15
    bne t0, t1, test3_different_negative # Should NOT jump, continue to failure
    # Fall through to failure if branch incorrectly taken
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test3_different_negative:
    # Test 3: bne with different registers (negative)
    li t0, -10
    li t1, -20
    bne t0, t1, test4_equal_negative # Jump if t0 != t1 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test4_equal_negative:
    # Test 4: bne with equal registers (negative) - Should NOT jump
    li t0, -15
    li t1, -15
    bne t0, t1, test5_one_zero # Should NOT jump, continue to failure
    # Fall through to failure if branch incorrectly taken
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test5_one_zero:
    # Test 5: bne with one register zero and another non-zero
    li t0, 0
    li t1, 5
    bne t0, t1, test6_both_zero # Jump if t0 != t1 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test6_both_zero:
    # Test 6: bne with both registers zero - Should NOT jump
    li t0, 0
    li t1, 0
    bne t0, t1, test7_large_different # Should NOT jump, continue to failure
    # Fall through to failure if branch incorrectly taken
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test7_large_different:
    # Test 7: bne with large different values
    li t0, 0x7FFFFFFF # Max positive integer
    li t1, 0x00000001
    bne t0, t1, success # Jump if t0 != t1 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit


success:
    addi a0, zero, 0  # Success: exit code 0

exit:
    ret
