.include "startup.s"

main:
    # Test 1: and with positive numbers
    li t0, 12
    li t1, 10
    and t2, t0, t1
    li t3, 8
    beq t2, t3, test2_negative_numbers # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test2_negative_numbers:
    # Test 2: and with negative numbers
    li t0, -12
    li t1, -10
    and t2, t0, t1
    li t3, -16 # -12 & -10 = 0xFFFFFFF4 & 0xFFFFFFF6 = 0xFFFFFFF0 = -16
    beq t2, t3, test3_zero # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test3_zero:
    # Test 3: and with zero
    li t0, 35
    li t1, 0
    and t2, t0, t1
    li t3, 0
    beq t2, t3, test4_identical_numbers # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test4_identical_numbers:
    # Test 4: and with identical numbers
    li t0, 25
    li t1, 25
    and t2, t0, t1
    li t3, 25
    beq t2, t3, test5_bitwise_different # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test5_bitwise_different:
    # Test 5: and with different bit patterns
    li t0, 0b10101010 # 170
    li t1, 0b01010101 # 85
    and t2, t0, t1
    li t3, 0b00000000 # 0
    beq t2, t3, test6_large_numbers # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test6_large_numbers:
    # Test 6: and with larger numbers
    li t0, 0xFFF0FFF0 # Large positive number
    li t1, 0x0FFF0FFF # Another large positive number
    and t2, t0, t1
    li t3, 0x0FFF0FFF & 0xFFF0FFF0 # Expected result of bitwise AND
    beq t2, t3, success # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

success:
    addi a0, zero, 0  # Success: exit code 0

exit:
    ret
