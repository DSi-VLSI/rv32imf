.include "startup.s"

main:
    # Test 1: sltu with less than condition (positive)
    li t0, 10
    li t1, 20
    sltu t2, t0, t1
    li t3, 1
    beq t2, t3, test2_greater_than_positive # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test2_greater_than_positive:
    # Test 2: sltu with greater than condition (positive)
    li t0, 20
    li t1, 10
    sltu t2, t0, t1
    li t3, 0
    beq t2, t3, test3_equal_positive # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test3_equal_positive:
    # Test 3: sltu with equal registers (positive)
    li t0, 15
    li t1, 15
    sltu t2, t0, t1
    li t3, 0
    beq t2, t3, test4_less_than_zero # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test4_less_than_zero:
    # Test 4: sltu with less than zero (t0 = 0)
    li t0, 0
    li t1, 10
    sltu t2, t0, t1
    li t3, 1
    beq t2, t3, test5_greater_than_zero # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test5_greater_than_zero:
    # Test 5: sltu with greater than zero (t1 = 0)
    li t0, 10
    li t1, 0
    sltu t2, t0, t1
    li t3, 0
    beq t2, t3, test6_equal_zero # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test6_equal_zero:
    # Test 6: sltu with equal zero registers
    li t0, 0
    li t1, 0
    sltu t2, t0, t1
    li t3, 0
    beq t2, t3, test7_max_unsigned # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test7_max_unsigned:
    # Test 7: sltu with maximum unsigned value (t0 = MAX, t1 = small positive)
    li t0, -1 # Maximum unsigned 32-bit value (0xFFFFFFFF)
    li t1, 10
    sltu t2, t0, t1
    li t3, 0 # Max unsigned is NOT less than small positive
    beq t2, t3, test8_large_unsigned # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test8_large_unsigned:
    # Test 8: sltu with large unsigned numbers (t0 = large, t1 = larger)
    li t0, 0x7FFFFFFF # A large positive number, but smaller unsigned max
    li t1, -1 # Maximum unsigned 32-bit value (0xFFFFFFFF)
    sltu t2, t0, t1
    li t3, 1 # Large positive IS less than max unsigned
    beq t2, t3, success # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit


success:
    addi a0, zero, 0  # Success: exit code 0

exit:
    ret
