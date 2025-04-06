.include "startup.s"

main:
    # Test 1: slt with less than condition (positive)
    li t0, 10
    li t1, 20
    slt t2, t0, t1
    li t3, 1
    beq t2, t3, test2_greater_than_positive # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test2_greater_than_positive:
    # Test 2: slt with greater than condition (positive)
    li t0, 20
    li t1, 10
    slt t2, t0, t1
    li t3, 0
    beq t2, t3, test3_equal_positive # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test3_equal_positive:
    # Test 3: slt with equal registers (positive)
    li t0, 15
    li t1, 15
    slt t2, t0, t1
    li t3, 0
    beq t2, t3, test4_less_than_negative # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test4_less_than_negative:
    # Test 4: slt with less than condition (negative)
    li t0, -20
    li t1, -10
    slt t2, t0, t1
    li t3, 1
    beq t2, t3, test5_greater_than_negative # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test5_greater_than_negative:
    # Test 5: slt with greater than condition (negative)
    li t0, -10
    li t1, -20
    slt t2, t0, t1
    li t3, 0
    beq t2, t3, test6_equal_negative # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test6_equal_negative:
    # Test 6: slt with equal registers (negative)
    li t0, -15
    li t1, -15
    slt t2, t0, t1
    li t3, 0
    beq t2, t3, test7_mixed_sign # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test7_mixed_sign:
    # Test 7: slt with mixed positive and negative
    li t0, -5
    li t1, 5
    slt t2, t0, t1
    li t3, 1
    beq t2, t3, test8_zero_operands # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test8_zero_operands:
    # Test 8: slt with zero operands (equal)
    li t0, 0
    li t1, 0
    slt t2, t0, t1
    li t3, 0
    beq t2, t3, test9_zero_less_than_positive # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test9_zero_less_than_positive:
    # Test 9: slt with zero and positive
    li t0, 0
    li t1, 5
    slt t2, t0, t1
    li t3, 1
    beq t2, t3, test10_positive_less_than_zero # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test10_positive_less_than_zero:
    # Test 10: slt with positive and zero (greater)
    li t0, 5
    li t1, 0
    slt t2, t0, t1
    li t3, 0
    beq t2, t3, test11_large_values # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test11_large_values:
    # Test 11: slt with large values (less than)
    li t0, 0x7FFFFFFF # Max positive integer
    li t1, -1         # Max negative integer (interpreted as large unsigned)
    slt t2, t0, t1
    li t3, 1
    beq t2, t3, success # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit


success:
    addi a0, zero, 0  # Success: exit code 0

exit:
    ret
