.include "startup.s"

main:
    # Test 1: slti with less than immediate (positive)
    li t0, 10
    slti t1, t0, 20
    li t2, 1
    beq t1, t2, test2_greater_than_immediate # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test2_greater_than_immediate:
    # Test 2: slti with greater than immediate (positive)
    li t0, 20
    slti t1, t0, 10
    li t2, 0
    beq t1, t2, test3_equal_immediate # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test3_equal_immediate:
    # Test 3: slti with equal to immediate (positive)
    li t0, 15
    slti t1, t0, 15
    li t2, 0
    beq t1, t2, test4_less_than_negative # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test4_less_than_negative:
    # Test 4: slti with less than immediate (negative)
    li t0, -20
    slti t1, t0, -10
    li t2, 1
    beq t1, t2, test5_greater_than_negative # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test5_greater_than_negative:
    # Test 5: slti with greater than immediate (negative)
    li t0, -10
    slti t1, t0, -20
    li t2, 0
    beq t1, t2, test6_equal_negative # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test6_equal_negative:
    # Test 6: slti with equal to immediate (negative)
    li t0, -15
    slti t1, t0, -15
    li t2, 0
    beq t1, t2, test7_zero_register_positive_immediate # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test7_zero_register_positive_immediate:
    # Test 7: slti with zero register and positive immediate
    li t0, 0
    slti t1, t0, 5
    li t2, 1
    beq t1, t2, test8_zero_register_negative_immediate # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test8_zero_register_negative_immediate:
    # Test 8: slti with zero register and negative immediate
    li t0, 0
    slti t1, t0, -5
    li t2, 0
    beq t1, t2, test9_max_positive_immediate # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test9_max_positive_immediate:
    # Test 9: slti with maximum positive immediate (2047)
    li t0, 1000
    slti t1, t0, 2047
    li t2, 1
    beq t1, t2, test10_min_negative_immediate # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test10_min_negative_immediate:
    # Test 10: slti with minimum negative immediate (-2048)
    li t0, 1000
    slti t1, t0, -2048
    li t2, 0
    beq t1, t2, test11_max_register_value # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test11_max_register_value:
    # Test 11: slti with maximum register value and larger immediate
    li t0, 0x7FFFFFFF # Maximum positive integer
    slti t1, t0, 0x80000000 # Immediate larger than max positive
    li t2, 1 # Should be less than as immediate is interpreted as signed
    beq t1, t2, success # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit


success:
    addi a0, zero, 0  # Success: exit code 0

exit:
    ret