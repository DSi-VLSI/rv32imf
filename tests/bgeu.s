.include "startup.s"

main:
    # Test 1: bgeu with greater than condition (positive)
    li t0, 20
    li t1, 10
    bgeu t0, t1, test2_equal_positive # Jump if t0 >= t1 (unsigned) (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test2_equal_positive:
    # Test 2: bgeu with equal registers (positive)
    li t0, 15
    li t1, 15
    bgeu t0, t1, test3_less_than_positive # Jump if t0 >= t1 (unsigned) (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test3_less_than_positive:
    # Test 3: bgeu with less than condition (positive) - Should NOT jump
    li t0, 10
    li t1, 20
    bgeu t0, t1, test4_greater_than_zero # Should NOT jump, continue to failure
    # Fall through to failure if branch incorrectly taken
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test4_greater_than_zero:
    # Test 4: bgeu with greater than zero
    li t0, 1
    li t1, 0
    bgeu t0, t1, test5_equal_zero # Jump if t0 >= t1 (unsigned) (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test5_equal_zero:
    # Test 5: bgeu with equal zero registers
    li t0, 0
    li t1, 0
    bgeu t0, t1, test6_less_than_zero # Jump if t0 >= t1 (unsigned) (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test6_less_than_zero:
    # Test 6: bgeu with less than zero - Should NOT jump (zero is min unsigned)
    li t0, -1 # Representing a large unsigned number
    li t1, 0
    bgeu t1, t0, test7_max_unsigned # Should NOT jump, continue to failure
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test7_max_unsigned:
    # Test 7: bgeu with maximum unsigned value
    li t0, -1 # Maximum unsigned 32-bit value (0xFFFFFFFF)
    li t1, 0x7FFFFFFF # A large positive number, but smaller unsigned max
    bgeu t0, t1, test8_large_unsigned # Jump if t0 >= t1 (unsigned) (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test8_large_unsigned:
    # Test 8: bgeu with large unsigned numbers (equal)
    li t0, -1 # Maximum unsigned
    li t1, -1 # Maximum unsigned
    bgeu t0, t1, success # Jump if t0 >= t1 (unsigned) (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit


success:
    addi a0, zero, 0  # Success: exit code 0

exit:
    ret
