.include "startup.s"

main:
    # Test 1: xor with positive numbers
    li t0, 12
    li t1, 10
    xor t2, t0, t1
    li t3, 6
    beq t2, t3, test2_negative_numbers # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test2_negative_numbers:
    # Test 2: xor with negative numbers
    li t0, -12
    li t1, -10
    xor t2, t0, t1
    li t3, 6 # -12 ^ -10 = 0xFFFFFFF4 ^ 0xFFFFFFF6 = 0x00000002 = 2, but wait, it should be 6.
    li t3, 6 # Corrected expected value. -12 is ...110100, -10 is ...110110, XOR is ...000010 = 2. Oh, wait. 12 is 0b1100, 10 is 0b1010, XOR is 0b0110 = 6. -12 is 0xFFFFFFF4, -10 is 0xFFFFFFF6. 0xFFFFFFF4 XOR 0xFFFFFFF6 = 0x00000002 = 2.  Let me re-calculate.
    li t3, 2 # Corrected expected value for negative numbers XOR.
    beq t2, t3, test3_zero # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test3_zero:
    # Test 3: xor with zero
    li t0, 45
    li t1, 0
    xor t2, t0, t1
    li t3, 45
    beq t2, t3, test4_identical_numbers # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test4_identical_numbers:
    # Test 4: xor with identical numbers
    li t0, 123
    li t1, 123
    xor t2, t0, t1
    li t3, 0
    beq t2, t3, test5_mixed_sign # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test5_mixed_sign:
    # Test 5: xor with mixed positive and negative numbers
    li t0, -50
    li t1, 50
    xor t2, t0, t1
    li t3, -1 # -50 ^ 50 = 0xFFFFFFCE ^ 0x00000032 = 0xFFFFFFFF = -1
    beq t2, t3, test6_bitwise_different # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test6_bitwise_different:
    # Test 6: xor with different bit patterns
    li t0, 0b11001100 # 204
    li t1, 0b10101010 # 170
    xor t2, t0, t1
    li t3, 0b01100110 # 102
    beq t2, t3, test7_large_numbers # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test7_large_numbers:
    # Test 7: xor with larger numbers
    li t0, 0xFF00FF00
    li t1, 0x00FF00FF
    xor t2, t0, t1
    li t3, 0xFFFF00FF # Expected result of bitwise XOR
    beq t2, t3, success # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

success:
    addi a0, zero, 0  # Success: exit code 0

exit:
    ret
