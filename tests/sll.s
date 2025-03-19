.include "startup.s"

main:
    # Test 1: sll with positive numbers and positive shift
    li t0, 1
    li t1, 3
    sll t2, t0, t1
    li t3, 8
    beq t2, t3, test2_negative_number # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test2_negative_number:
    # Test 2: sll with negative number and positive shift
    li t0, -1
    li t1, 3
    sll t2, t0, t1
    li t3, -8 # -1 << 3 = 0xFFFFFFFF << 3 = 0xFFFFFFF8 = -8
    beq t2, t3, test3_zero_shift # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test3_zero_shift:
    # Test 3: sll with positive number and zero shift amount
    li t0, 5
    li t1, 0
    sll t2, t0, t1
    li t3, 5
    beq t2, t3, test4_max_shift # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test4_max_shift:
    # Test 4: sll with positive number and maximum shift amount (less than word size - 31 for 32-bit RISC-V)
    li t0, 1
    li t1, 31
    sll t2, t0, t1
    li t3, -2147483648 # 1 << 31 = 0x80000000 = -2147483648 (signed 32-bit)
    beq t2, t3, test5_zero_value # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test5_zero_value:
    # Test 5: sll with zero value and positive shift amount
    li t0, 0
    li t1, 5
    sll t2, t0, t1
    li t3, 0
    beq t2, t3, test6_bitwise_pattern # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test6_bitwise_pattern:
    # Test 6: sll with specific bit pattern and positive shift
    li t0, 0b00010010 # 18
    li t1, 2
    sll t2, t0, t1
    li t3, 0b01001000 # 72
    beq t2, t3, success # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit


success:
    addi a0, zero, 0  # Success: exit code 0

exit:
    ret
