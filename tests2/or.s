.include "startup.s"

main:
    # Test 1: or with positive numbers
    li t0, 12
    li t1, 10
    or t2, t0, t1
    li t3, 14
    beq t2, t3, test2_negative_numbers # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test2_negative_numbers:
    # Test 2: or with negative numbers
    li t0, -12
    li t1, -10
    or t2, t0, t1
    li t3, -6 # -12 | -10 = 0xFFFFFFF4 | 0xFFFFFFF6 = 0xFFFFFFFA = -6
    beq t2, t3, test3_zero # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test3_zero:
    # Test 3: or with zero
    li t0, 35
    li t1, 0
    or t2, t0, t1
    li t3, 35
    beq t2, t3, test4_identical_numbers # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test4_identical_numbers:
    # Test 4: or with identical numbers
    li t0, 25
    li t1, 25
    or t2, t0, t1
    li t3, 25
    beq t2, t3, test5_bitwise_different # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test5_bitwise_different:
    # Test 5: or with different bit patterns
    li t0, 0b10101010 # 170
    li t1, 0b01010101 # 85
    or t2, t0, t1
    li t3, 0b11111111 # 255
    beq t2, t3, test6_large_numbers # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test6_large_numbers:
    # Test 6: or with larger numbers
    li t0, 0xFFF00000 # Large positive number with some bits set
    li t1, 0x000FFFFF # Another large positive number with different bits set
    or t2, t0, t1
    li t3, 0xFFF0FFFF # Expected result of bitwise OR
    beq t2, t3, success # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

success:
    addi a0, zero, 0  # Success: exit code 0

exit:
    ret
