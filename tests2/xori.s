.include "startup.s"

main:
    # Test 1: xori with positive numbers
    li t0, 12  # 0b1100
    li t1, 10  # 0b1010
    xori t2, t0, 10 # 0b1010 (immediate)
    li t3, 6   # 0b0110 (12 ^ 10 = 6)
    beq t2, t3, test2_negative_number # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test2_negative_number:
    # Test 2: xori with negative number and positive immediate
    li t0, -12 # 0xFFFFFFF4
    xori t2, t0, 0x0F # 0b00001111 (immediate)
    li t3, -17     # 0xFFFFFFEF (0xFFFFFFF4 ^ 0x0F = 0xFFFFFFEF = -17)
    beq t2, t3, test3_zero_immediate # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test3_zero_immediate:
    # Test 3: xori with positive number and zero immediate
    li t0, 55
    xori t2, t0, 0 # Immediate is zero
    li t3, 55
    beq t2, t3, test4_max_immediate # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test4_max_immediate:
    # Test 4: xori with zero register and max immediate (4095 - 12-bit signed)
    li t0, 0
    xori t2, t0, 4095 # Max 12-bit immediate (0xFFF)
    li t3, 4095 # Result should be the immediate value itself
    beq t2, t3, test5_identical_register_immediate # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test5_identical_register_immediate:
    # Test 5: xori with identical register and immediate values
    li t0, 0xAAAA
    xori t2, t0, 0xAAAA # Register value same as immediate
    li t3, 0 # Result should be zero because x ^ x = 0
    beq t2, t3, test6_bitwise_pattern # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test6_bitwise_pattern:
    # Test 6: xori with different bit patterns to check bitwise XOR operation
    li t0, 0b11001010 # 202
    xori t2, t0, 0b01011100 # 92 (immediate)
    li t3, 0b10010110 # 150 (Expected bitwise XOR result)
    beq t2, t3, success # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit


success:
    addi a0, zero, 0  # Success: exit code 0

exit:
    ret
