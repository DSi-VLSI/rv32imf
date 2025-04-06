.include "startup.s"

main:
    # Test 1: sh with zero offset
    la t0, data
    li t1, 0x1234
    sh t1, 0(t0)
    lh t2, 0(t0)
    beq t1, t2, test2_positive_offset # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test2_positive_offset:
    # Test 2: sh with positive offset
    la t0, data
    li t1, 0x5678
    sh t1, 2(t0) # Offset to the second halfword
    lh t2, 2(t0)
    beq t1, t2, test3_negative_offset # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test3_negative_offset:
    # Test 3: sh with negative offset (relative to data_end label)
    la t0, data_end
    li t1, 0x9ABC
    sh t1, -2(t0) # Offset to access the last halfword of data
    lh t2, -2(t0)
    beq t1, t2, test4_different_data # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test4_different_data:
    # Test 4: sh to different data label (data2) with zero offset
    la t0, data2
    li t1, 0xCDEF
    sh t1, 0(t0)
    lh t2, 0(t0)
    beq t1, t2, test5_max_halfword_value # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test5_max_halfword_value:
    # Test 5: sh with maximum halfword value (0xFFFF)
    la t0, data3
    li t1, 0xFFFF
    sh t1, 0(t0)
    lh t2, 0(t0)
    beq t1, t2, test6_zero_halfword_value # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test6_zero_halfword_value:
    # Test 6: sh with zero halfword value (0x0000)
    la t0, data4
    li t1, 0x0000
    sh t1, 0(t0)
    lh t2, 0(t0)
    beq t1, t2, test7_overwrite_data # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test7_overwrite_data:
    # Test 7: sh to overwrite existing data
    la t0, data5
    li t1, 0x1B2C
    sh t1, 0(t0) # Overwrite initial value 0x3456 with 0x1B2C
    lh t2, 0(t0)
    beq t1, t2, success # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit


data:
    .half 0x0000, 0x0000, 0x0000, 0x0000 # Reserve space for multiple halfword writes
data_end: # Label to point after data section
data2:
    .half 0xAAAA # Initial data for data2
data3:
    .half 0xBBBB # Initial data for data3
data4:
    .half 0xCCCC # Initial data for data4
data5:
    .half 0x3456 # Initial data for data5


success:
    addi a0, zero, 0  # Success: exit code 0

exit:
    ret