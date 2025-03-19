.include "startup.s"

main:
    # Test 1: srli with positive number and small positive shift
    li t0, 8
    srli t1, t0, 1
    li t2, 4
    beq t1, t2, test2_negative_number_small_shift # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test2_negative_number_small_shift:
    # Test 2: srli with negative number and small positive shift (logical right shift - no sign extension)
    li t0, -8 # 0xFFFFFFF8
    srli t1, t0, 1
    li t2, 0x7FFFFFFC # 0xFFFFFFF8 >> 1 (logical) = 0x7FFFFFFC
    beq t1, t2, test3_zero_shift # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test3_zero_shift:
    # Test 3: srli with positive number and zero shift amount
    li t0, 123
    srli t1, t0, 0
    li t2, 123
    beq t1, t2, test4_large_shift # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test4_large_shift:
    # Test 4: srli with positive number and larger shift amount
    li t0, 64
    srli t1, t0, 6
    li t2, 1
    beq t1, t2, test5_zero_value # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test5_zero_value:
    # Test 5: srli with zero value and positive shift amount
    li t0, 0
    srli t1, t0, 7
    li t2, 0
    beq t1, t2, test6_max_positive # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test6_max_positive:
    # Test 6: srli with maximum positive number and positive shift
    li t0, 0x7FFFFFFF # Maximum positive 32-bit integer
    srli t1, t0, 4
    li t2, 0x07FFFFFF # Expected result after logical right shift
    beq t1, t2, test7_min_negative # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test7_min_negative:
    # Test 7: srli with minimum negative number and positive shift - No sign extension
    li t0, -0x80000000 # Minimum negative 32-bit integer
    srli t1, t0, 4
    li t2, 0x08000000 # Expected result after logical right shift (no sign extension)
    beq t1, t2, test8_bitwise_pattern # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test8_bitwise_pattern:
    # Test 8: srli with specific bit pattern and positive shift
    li t0, 0b10101000 # 168
    srli t1, t0, 3
    li t2, 0b00010101 # 21 (Expected bitwise logical right shift)
    li t3, 21
    beq t1, t3, success # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit


success:
    addi a0, zero, 0  # Success: exit code 0

exit:
    ret
