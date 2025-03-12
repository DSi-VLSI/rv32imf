.include "startup.s"

main:
    # Test 1: srai with positive number and small positive shift
    li t0, 8
    srai t1, t0, 1
    li t2, 4
    beq t1, t2, test2_negative_number_small_shift # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test2_negative_number_small_shift:
    # Test 2: srai with negative number and small positive shift (arithmetic right shift - sign extension)
    li t0, -8 # 0xFFFFFFF8
    srai t1, t0, 1
    li t2, -4 # 0xFFFFFFFE. 0xFFFFFFF8 >> 1 (arithmetic) = 0xFFFFFFFE = -4
    beq t1, t2, test3_zero_shift # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test3_zero_shift:
    # Test 3: srai with positive number and zero shift amount
    li t0, 25
    srai t1, t0, 0
    li t2, 25
    beq t1, t2, test4_large_shift # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test4_large_shift:
    # Test 4: srai with positive number and larger shift amount
    li t0, 128
    srai t1, t0, 5
    li t2, 4
    beq t1, t2, test5_zero_value # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test5_zero_value:
    # Test 5: srai with zero value and positive shift amount
    li t0, 0
    srai t1, t0, 6
    li t2, 0
    beq t1, t2, test6_max_positive # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test6_max_positive:
    # Test 6: srai with maximum positive number and positive shift
    li t0, 0x7FFFFFFF # Maximum positive 32-bit integer
    srai t1, t0, 2
    li t2, 0x1FFFFFFF # Expected result after arithmetic right shift
    beq t1, t2, test7_min_negative # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test7_min_negative:
    # Test 7: srai with minimum negative number and positive shift - Sign extension test
    li t0, -0x80000000 # Minimum negative 32-bit integer
    srai t1, t0, 2
    li t2, -0x20000000 # Expected result after arithmetic right shift and sign extension
    beq t1, t2, test8_bitwise_pattern # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test8_bitwise_pattern:
    # Test 8: srai with specific bit pattern and positive shift
    li t0, 0b10110000 # 176, sign bit is set
    srai t1, t0, 3
    li t2, 0b11110110 # Expected result after arithmetic right shift (sign extended)
    li t3, 0xFFFFFFF6 # Representing -10 in decimal - verifying sign extension with negative result
    li t3, -10 # Representing -10 in decimal - verifying sign extension with negative result
    beq t1, t3, success # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit


success:
    addi a0, zero, 0  # Success: exit code 0

exit:
    ret
