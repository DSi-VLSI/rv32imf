.include "startup.s"

main:
    # Test 1: blt with less than condition (positive)
    li t0, 10
    li t1, 20
    blt t0, t1, test2_equal_positive # Jump if t0 < t1 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test2_equal_positive:
    # Test 2: blt with equal registers (positive) - Should NOT jump
    li t0, 15
    li t1, 15
    blt t0, t1, test3_greater_than_positive # Should NOT jump, continue to failure
    # Fall through to failure if branch incorrectly taken
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test3_greater_than_positive:
    # Test 3: blt with greater than condition (positive) - Should NOT jump
    li t0, 20
    li t1, 10
    blt t0, t1, test4_less_than_negative # Should NOT jump, continue to failure
    # Fall through to failure if branch incorrectly taken
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test4_less_than_negative:
    # Test 4: blt with less than condition (negative)
    li t0, -20
    li t1, -10
    blt t0, t1, test5_equal_negative # Jump if t0 < t1 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test5_equal_negative:
    # Test 5: blt with equal registers (negative) - Should NOT jump
    li t0, -10
    li t1, -10
    blt t0, t1, test6_greater_than_negative # Should NOT jump, continue to failure
    # Fall through to failure if branch incorrectly taken
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test6_greater_than_negative:
    # Test 6: blt with greater than condition (negative) - Should NOT jump
    li t0, -10
    li t1, -20
    blt t0, t1, test7_mixed_sign # Should NOT jump, continue to failure
    # Fall through to failure if branch incorrectly taken
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test7_mixed_sign:
    # Test 7: blt with mixed positive and negative
    li t0, -5
    li t1, 5
    blt t0, t1, test8_zero # Jump if t0 < t1 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test8_zero:
    # Test 8: blt with zero and positive
    li t0, 0
    li t1, 5
    blt t0, t1, test9_zero_equal # Jump if t0 < t1 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test9_zero_equal:
    # Test 9: blt with zero equal - Should NOT jump
    li t0, 0
    li t1, 0
    blt t0, t1, test10_large_less_than # Should NOT jump, continue to failure
    # Fall through to failure if branch incorrectly taken
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test10_large_less_than:
    # Test 10: blt with large numbers (less than)
    li t0, 0x00000001
    li t1, 0x7FFFFFFF # Max positive integer
    blt t0, t1, test11_large_greater_than # Jump if t0 < t1 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test11_large_greater_than:
    # Test 11: blt with large numbers (greater than) - Should NOT jump
    li t0, 0x7FFFFFFF # Max positive integer
    li t1, 0x00000001
    blt t0, t1, success # Should NOT jump, continue to failure
    # Fall through to failure if branch incorrectly taken
    addi a0, zero, 1  # Failure: exit code 1
    j exit


success:
    addi a0, zero, 0  # Success: exit code 0

exit:
    ret
