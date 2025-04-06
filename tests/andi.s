.include "startup.s"

main:
    # Test 1: andi with positive numbers
    li t0, 12  # 0b1100
    li t1, 10  # 0b1010
    andi t2, t0, 10 # 0b1010 (immediate)
    li t3, 8   # 0b1000 (12 & 10 = 8)
    beq t2, t3, test2_negative_number # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test2_negative_number:
    # Test 2: andi with negative number and positive immediate
    li t0, -12 # 0xFFFFFFF4
    andi t2, t0, 0x0F # 0b00001111 (immediate)
    li t3, 4      # 0b00000100  (0xFFFFFFF4 & 0x0F = 0x04)
    beq t2, t3, test3_zero_immediate # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test3_zero_immediate:
    # Test 3: andi with positive number and zero immediate
    li t0, 55
    andi t2, t0, 0 # Immediate is zero
    li t3, 0
    beq t2, t3, test4_max_immediate # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test4_max_immediate:
    # Test 4: andi with positive number and max immediate (4095 - 12-bit signed)
    li t0, 0xFFFF # Some bits set in t0
    andi t2, t0, 4095 # Max 12-bit immediate (0xFFF)
    li t3, 4095 # Result should be limited by the immediate mask
    beq t2, t3, test5_identical_register_immediate # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test5_identical_register_immediate:
    # Test 5: andi with identical register and immediate values
    li t0, 0xABC
    andi t2, t0, 0xABC # Register value same as immediate
    li t3, 0xABC
    beq t2, t3, test6_bitwise_pattern # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test6_bitwise_pattern:
    # Test 6: andi with different bit patterns to check bitwise AND operation
    li t0, 0b10110110 # 182
    andi t2, t0, 0b11011011 # 219 (immediate)
    li t3, 0b10010010 # 146 (Expected bitwise AND result)
    beq t2, t3, success # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit


success:
    addi a0, zero, 0  # Success: exit code 0

exit:
    ret
