.include "startup.s"

main:
    # Test 1: sub with positive numbers (positive result)
    li t0, 20
    li t1, 5
    sub t2, t0, t1
    li t3, 15
    beq t2, t3, test2_positive_negative # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test2_positive_negative:
    # Test 2: sub with positive and negative numbers (positive - negative = positive)
    li t0, 20
    li t1, -5
    sub t2, t0, t1
    li t3, 25 # 20 - (-5) = 25
    beq t2, t3, test3_negative_positive # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test3_negative_positive:
    # Test 3: sub with negative and positive numbers (negative - positive = negative)
    li t0, -20
    li t1, 5
    sub t2, t0, t1
    li t3, -25 # -20 - 5 = -25
    beq t2, t3, test4_negative_negative # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test4_negative_negative:
    # Test 4: sub with negative numbers (negative - negative = negative or positive)
    li t0, -20
    li t1, -5
    sub t2, t0, t1
    li t3, -15 # -20 - (-5) = -20 + 5 = -15
    beq t2, t3, test5_zero_operands # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test5_zero_operands:
    # Test 5: sub with zero operands (0 - 0 = 0)
    li t0, 0
    li t1, 0
    sub t2, t0, t1
    li t3, 0
    beq t2, t3, test6_positive_zero # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test6_positive_zero:
    # Test 6: sub with positive and zero (positive - 0 = positive)
    li t0, 30
    li t1, 0
    sub t2, t0, t1
    li t3, 30
    beq t2, t3, test7_zero_positive # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test7_zero_positive:
    # Test 7: sub with zero and positive (0 - positive = negative)
    li t0, 0
    li t1, 10
    sub t2, t0, t1
    li t3, -10
    beq t2, t3, test8_identical_operands # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test8_identical_operands:
    # Test 8: sub with identical operands (x - x = 0)
    li t0, 42
    li t1, 42
    sub t2, t0, t1
    li t3, 0
    beq t2, t3, test9_large_positive # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test9_large_positive:
    # Test 9: sub with large positive numbers
    li t0, 0x7FFFFFFF # Max positive integer
    li t1, 0x1
    sub t2, t0, t1
    li t3, 0x7FFFFFFE # Max positive - 1
    beq t2, t3, test10_large_negative # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test10_large_negative:
    # Test 10: sub with large negative numbers
    li t0, -0x7FFFFFFF # Large negative integer
    li t1, -0x1
    sub t2, t0, t1
    li t3, -0x7FFFFFFE # Large negative + 1
    beq t2, t3, success # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit


success:
    addi a0, zero, 0  # Success: exit code 0

exit:
    ret
