.include "startup.s"

main:
    # Test 1: bge with greater than condition (positive)
    li t0, 20
    li t1, 10
    bge t0, t1, test2_equal_positive # Jump if t0 >= t1 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test2_equal_positive:
    # Test 2: bge with equal registers (positive)
    li t0, 15
    li t1, 15
    bge t0, t1, test3_less_than_positive # Jump if t0 >= t1 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test3_less_than_positive:
    # Test 3: bge with less than condition (positive) - Should NOT jump
    li t0, 10
    li t1, 20
    bge t0, t1, test4_greater_than_negative # Should NOT jump, continue to failure
    # Fall through to failure if branch incorrectly taken
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test4_greater_than_negative:
    # Test 4: bge with greater than condition (negative)
    li t0, -5
    li t1, -10
    bge t0, t1, test5_equal_negative # Jump if t0 >= t1 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test5_equal_negative:
    # Test 5: bge with equal registers (negative)
    li t0, -8
    li t1, -8
    bge t0, t1, test6_less_than_negative # Jump if t0 >= t1 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test6_less_than_negative:
    # Test 6: bge with less than condition (negative) - Should NOT jump
    li t0, -10
    li t1, -5
    bge t0, t1, test7_zero # Should NOT jump, continue to failure
    # Fall through to failure if branch incorrectly taken
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test7_zero:
    # Test 7: bge with zero values (equal)
    li t0, 0
    li t1, 0
    bge t0, t1, test8_positive_zero # Jump if t0 >= t1 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test8_positive_zero:
    # Test 8: bge with positive and zero (greater than)
    li t0, 5
    li t1, 0
    bge t0, t1, test9_negative_zero # Jump if t0 >= t1 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test9_negative_zero:
    # Test 9: bge with negative and zero (less than) - Should NOT jump
    li t0, -5
    li t1, 0
    bge t0, t1, test10_large_positive # Should NOT jump, continue to failure
    # Fall through to failure if branch incorrectly taken
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test10_large_positive:
    # Test 10: bge with large positive numbers (greater than)
    li t0, 0x7FFFFFFF # Max positive integer
    li t1, 0x10000000 # A large positive integer, but smaller than max
    bge t0, t1, test11_large_negative # Jump if t0 >= t1 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test11_large_negative:
    # Test 11: bge with large negative numbers (equal)
    li t0, -0x80000000 # Min negative integer
    li t1, -0x80000000 # Min negative integer
    bge t0, t1, success # Jump if t0 >= t1 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit


success:
    addi a0, zero, 0  # Success: exit code 0

exit:
    ret
