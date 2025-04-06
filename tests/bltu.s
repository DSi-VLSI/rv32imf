.include "startup.s"

main:
    # Test 1: bltu with less than condition (positive)
    li t0, 10
    li t1, 20
    bltu t0, t1, test2_equal_positive # Jump if t0 < t1 (unsigned) (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test2_equal_positive:
    # Test 2: bltu with equal registers (positive) - Should NOT jump
    li t0, 15
    li t1, 15
    bltu t0, t1, test3_greater_than_positive # Should NOT jump, continue to failure
    # Fall through to failure if branch incorrectly taken
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test3_greater_than_positive:
    # Test 3: bltu with greater than condition (positive) - Should NOT jump
    li t0, 20
    li t1, 10
    bltu t0, t1, test4_less_than_zero # Should NOT jump, continue to failure
    # Fall through to failure if branch incorrectly taken
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test4_less_than_zero:
    # Test 4: bltu with less than zero (unsigned comparison - t0 max unsigned)
    li t0, -1 # Representing max unsigned value (0xFFFFFFFF)
    li t1, 1 # A small positive number
    bltu t1, t0, test5_equal_zero # Jump if t1 < t0 (unsigned) (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test5_equal_zero:
    # Test 5: bltu with equal zero registers - Should NOT jump
    li t0, 0
    li t1, 0
    bltu t0, t1, test6_greater_than_zero # Should NOT jump, continue to failure
    # Fall through to failure if branch incorrectly taken
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test6_greater_than_zero:
    # Test 6: bltu with greater than zero (t1 is zero) - Should NOT jump
    li t0, 5
    li t1, 0
    bltu t0, t1, test7_max_unsigned_less_than # Should NOT jump, continue to failure
    # Fall through to failure if branch incorrectly taken
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test7_max_unsigned_less_than:
    # Test 7: bltu with max unsigned and smaller unsigned
    li t0, 0x7FFFFFFF # A large positive number, smaller than max unsigned
    li t1, -1 # Maximum unsigned 32-bit value (0xFFFFFFFF)
    bltu t0, t1, test8_max_unsigned_equal # Jump if t0 < t1 (unsigned) (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test8_max_unsigned_equal:
    # Test 8: bltu with max unsigned equal - Should NOT jump
    li t0, -1 # Maximum unsigned
    li t1, -1 # Maximum unsigned
    bltu t0, t1, success # Should NOT jump, continue to failure
    # Fall through to failure if branch incorrectly taken
    addi a0, zero, 1  # Failure: exit code 1
    j exit


success:
    addi a0, zero, 0  # Success: exit code 0

exit:
    ret
