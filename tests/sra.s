.include "startup.s"

main:
    # Test 1: sra with positive number and small positive shift
    li t0, 8
    li t1, 1
    sra t2, t0, t1
    li t3, 4
    beq t2, t3, test2_negative_number_small_shift # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test2_negative_number_small_shift:
    # Test 2: sra with negative number and small positive shift
    li t0, -8
    li t1, 1
    sra t2, t0, t1
    li t3, -4 # -8 >> 1 (arithmetic) = 0xFFFFFFF8 >> 1 = 0xFFFFFFFE = -4
    beq t2, t3, test3_zero_shift # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test3_zero_shift:
    # Test 3: sra with positive number and zero shift amount
    li t0, 15
    li t1, 0
    sra t2, t0, t1
    li t3, 15
    beq t2, t3, test4_large_shift # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test4_large_shift:
    # Test 4: sra with positive number and larger shift amount
    li t0, 32
    li t1, 4
    sra t2, t0, t1
    li t3, 2
    beq t2, t3, test5_zero_value # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test5_zero_value:
    # Test 5: sra with zero value and positive shift amount
    li t0, 0
    li t1, 5
    sra t2, t0, t1
    li t3, 0
    beq t2, t3, test6_max_positive # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test6_max_positive:
    # Test 6: sra with maximum positive number and positive shift
    li t0, 0x7FFFFFFF # Maximum positive 32-bit integer
    li t1, 3
    sra t2, t0, t1
    li t3, 0x0FFFFFFF # Expected result after arithmetic right shift
    beq t2, t3, test7_min_negative # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test7_min_negative:
    # Test 7: sra with minimum negative number and positive shift - Sign extension test
    li t0, -0x80000000 # Minimum negative 32-bit integer
    li t1, 3
    sra t2, t0, t1
    li t3, -1073741824 # Expected result after arithmetic right shift and sign extension
    beq t2, t3, test8_bitwise_pattern # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test8_bitwise_pattern:
    # Test 8: sra with specific bit pattern and positive shift
    li t0, 0b10010000 # 144, sign bit is set
    li t1, 2
    sra t2, t0, t1
    li t3, 0b11100100 # Expected result after arithmetic right shift (sign extended)
    beq t2, t3, success # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit


success:
    addi a0, zero, 0  # Success: exit code 0

exit:
    ret
