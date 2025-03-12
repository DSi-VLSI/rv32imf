.include "startup.s"

main:
    # Test 1: slli with positive number and positive shift
    li t0, 1
    slli t1, t0, 3
    li t2, 8
    beq t1, t2, test2_negative_number # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test2_negative_number:
    # Test 2: slli with negative number and positive shift (no sign extension in logical shift)
    li t0, -1 # 0xFFFFFFFF
    slli t1, t0, 3
    li t2, -8 # 0xFFFFFFF8. Logical left shift doesn't care about sign.
    beq t1, t2, test3_zero_shift # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test3_zero_shift:
    # Test 3: slli with positive number and zero shift amount
    li t0, 123
    slli t1, t0, 0
    li t2, 123
    beq t1, t2, test4_max_shift # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test4_max_shift:
    # Test 4: slli with positive number and maximum shift amount (less than word size - 31 for RV32I)
    li t0, 1
    slli t1, t0, 31
    li t2, -2147483648 # 0x80000000  (1 << 31)
    beq t1, t2, test5_zero_value # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test5_zero_value:
    # Test 5: slli with zero value and positive shift amount
    li t0, 0
    slli t1, t0, 10
    li t2, 0
    beq t1, t2, test6_bitwise_pattern # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test6_bitwise_pattern:
    # Test 6: slli with specific bit pattern and positive shift
    li t0, 0b00110011 # 51
    slli t1, t0, 4
    li t2, 0b001100110000 # 816 (Expected bitwise left shift result)
    li t3, 816
    beq t1, t3, success # Jump if t1 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit


success:
    addi a0, zero, 0  # Success: exit code 0

exit:
    ret
