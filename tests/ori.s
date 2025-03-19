.include "startup.s"

main:
    # Test 1: ori with positive numbers
    li t0, 12  # 0b1100
    li t1, 10  # 0b1010
    ori t2, t0, 10 # 0b1010 (immediate)
    li t3, 14  # 0b1110 (12 | 10 = 14)
    beq t2, t3, test2_negative_number # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test2_negative_number:
    # Test 2: ori with negative number and positive immediate
    li t0, -12 # 0xFFFFFFF4
    ori t2, t0, 0x0F # 0b00001111 (immediate)
    li t3, -1      # 0xFFFFFFFF (0xFFFFFFF4 | 0x0F = 0xFFFFFFFF = -1)
    beq t2, t3, test3_zero_immediate # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test3_zero_immediate:
    # Test 3: ori with positive number and zero immediate
    li t0, 55
    ori t2, t0, 0 # Immediate is zero
    li t3, 55
    beq t2, t3, test4_max_immediate # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test4_max_immediate:
    # Test 4: ori with zero register and max immediate (4095 - 12-bit signed)
    li t0, 0
    ori t2, t0, 4095 # Max 12-bit immediate (0xFFF)
    li t3, 4095 # Result should be the immediate value itself
    beq t2, t3, test5_identical_register_immediate # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test5_identical_register_immediate:
    # Test 5: ori with identical register and immediate values
    li t0, 0x5A5A
    ori t2, t0, 0x5A5A # Register value same as immediate
    li t3, 0x5A5A
    beq t2, t3, test6_bitwise_pattern # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test6_bitwise_pattern:
    # Test 6: ori with different bit patterns to check bitwise OR operation
    li t0, 0b10010110 # 150
    ori t2, t0, 0b01101001 # 105 (immediate)
    li t3, 0b11111111 # 255 (Expected bitwise OR result)
    beq t2, t3, success # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit


success:
    addi a0, zero, 0  # Success: exit code 0

exit:
    ret
