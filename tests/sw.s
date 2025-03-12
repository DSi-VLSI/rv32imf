.include "startup.s"

main:
    # Test 1: sw with zero offset
    la t0, data
    li t1, 0x12345678
    sw t1, 0(t0)
    lw t2, 0(t0)
    beq t1, t2, test2_positive_offset # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test2_positive_offset:
    # Test 2: sw with positive offset
    la t0, data
    li t1, 0x9ABCDEF0
    sw t1, 4(t0) # Offset to the second word
    lw t2, 4(t0)
    beq t1, t2, test3_negative_offset # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test3_negative_offset:
    # Test 3: sw with negative offset (relative to data_end label)
    la t0, data_end
    li t1, 0x11223344
    sw t1, -4(t0) # Offset to access the last word of data
    lw t2, -4(t0)
    beq t1, t2, test4_different_data # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test4_different_data:
    # Test 4: sw to different data label (data2) with zero offset
    la t0, data2
    li t1, 0x55AA55AA
    sw t1, 0(t0)
    lw t2, 0(t0)
    beq t1, t2, test5_max_word_value # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test5_max_word_value:
    # Test 5: sw with maximum word value (0xFFFFFFFF)
    la t0, data3
    li t1, -1 # Representing 0xFFFFFFFF
    sw t1, 0(t0)
    lw t2, 0(t0)
    beq t1, t2, test6_zero_word_value # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test6_zero_word_value:
    # Test 6: sw with zero word value (0x00000000)
    la t0, data4
    li t1, 0x00000000
    sw t1, 0(t0)
    lw t2, 0(t0)
    beq t1, t2, test7_overwrite_data # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test7_overwrite_data:
    # Test 7: sw to overwrite existing data
    la t0, data5
    li t1, 0xABCDEF12
    sw t1, 0(t0) # Overwrite initial value 0xC0C0C0C0 with 0xABCDEF12
    lw t2, 0(t0)
    beq t1, t2, success # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit


data:
    .word 0x00000000, 0x00000000, 0x00000000, 0x00000000 # Reserve space for multiple word writes
data_end: # Label to point after data section
data2:
    .word 0xAAAAAAAA # Initial data for data2
data3:
    .word 0xBBBBBBBB # Initial data for data3
data4:
    .word 0xCCCCCCCC # Initial data for data4
data5:
    .word 0xC0C0C0C0 # Initial data for data5


success:
    addi a0, zero, 0  # Success: exit code 0

exit:
    ret
