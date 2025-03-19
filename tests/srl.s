.include "startup.s"

main:
    # Test 1: srl with positive number and small positive shift
    li t0, 8
    li t1, 1
    srl t2, t0, t1
    li t3, 4
    beq t2, t3, test2_negative_number_small_shift # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test2_negative_number_small_shift:
    # Test 2: srl with negative number and small positive shift (logical right shift)
    li t0, -8
    li t1, 1
    srl t2, t0, t1
    li t3, 0x7FFFFFFC # -8 >> 1 (logical) = 0xFFFFFFF8 >> 1 = 0x7FFFFFFC
    beq t2, t3, test3_zero_shift # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test3_zero_shift:
    # Test 3: srl with positive number and zero shift amount
    li t0, 15
    li t1, 0
    srl t2, t0, t1
    li t3, 15
    beq t2, t3, test4_large_shift # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test4_large_shift:
    # Test 4: srl with positive number and larger shift amount
    li t0, 32
    li t1, 4
    srl t2, t0, t1
    li t3, 2
    beq t2, t3, test5_zero_value # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test5_zero_value:
    # Test 5: srl with zero value and positive shift amount
    li t0, 0
    li t1, 5
    srl t2, t0, t1
    li t3, 0
    beq t2, t3, test6_max_positive # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test6_max_positive:
    # Test 6: srl with maximum positive number and positive shift
    li t0, 0x7FFFFFFF # Maximum positive 32-bit integer
    li t1, 3
    srl t2, t0, t1
    li t3, 0x0FFFFFFF # Expected result after logical right shift
    beq t2, t3, test7_min_negative # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test7_min_negative:
    # Test 7: srl with minimum negative number and positive shift - No sign extension for logical shift
    li t0, -0x80000000 # Minimum negative 32-bit integer
    li t1, 3
    srl t2, t0, t1
    li t3, 0x1FFFFFFF # Expected result after logical right shift (no sign extension)
    beq t2, t3, test8_bitwise_pattern # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test8_bitwise_pattern:
    # Test 8: srl with specific bit pattern and positive shift
    li t0, 0b10010000 # 144, sign bit is set
    li t1, 2
    srl t2, t0, t1
    li t3, 0b00100100 # Expected result after logical right shift (zero padded)
    beq t2, t3, success # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit


success:
    addi a0, zero, 0  # Success: exit code 0

exit:
    ret