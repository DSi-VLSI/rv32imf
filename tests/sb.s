.include "startup.s"

main:
    # Test 1: sb with zero offset
    la t0, data
    li t1, 0x12
    sb t1, 0(t0)
    lb t2, 0(t0)
    beq t1, t2, test2_positive_offset # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test2_positive_offset:
    # Test 2: sb with positive offset
    la t0, data
    li t1, 0x34
    sb t1, 1(t0)
    lb t2, 1(t0)
    beq t1, t2, test3_negative_offset # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test3_negative_offset:
    # Test 3: sb with negative offset (relative to data_end label)
    la t0, data_end
    li t1, 0x56
    sb t1, -1(t0) # Offset to access the last byte of data
    lb t2, -1(t0)
    beq t1, t2, test4_different_data # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test4_different_data:
    # Test 4: sb to different data label (data2) with zero offset
    la t0, data2
    li t1, 0x78
    sb t1, 0(t0)
    lb t2, 0(t0)
    beq t1, t2, test5_max_byte_value # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test5_max_byte_value:
    # Test 5: sb with maximum byte value (0xFF)
    la t0, data3
    li t1, 0xFF
    sb t1, 0(t0)
    lb t2, 0(t0)
    beq t1, t2, test6_zero_byte_value # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test6_zero_byte_value:
    # Test 6: sb with zero byte value (0x00)
    la t0, data4
    li t1, 0x00
    sb t1, 0(t0)
    lb t2, 0(t0)
    beq t1, t2, test7_overwrite_data # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test7_overwrite_data:
    # Test 7: sb to overwrite existing data
    la t0, data5
    li t1, 0x9A
    sb t1, 0(t0) # Overwrite initial value 0xBB with 0x9A
    lb t2, 0(t0)
    beq t1, t2, success # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit


data:
    .byte 0x00, 0x00, 0x00, 0x00 # Reserve space for multiple byte writes
data_end: # Label to point after data section
data2:
    .byte 0xAA # Initial data for data2
data3:
    .byte 0xCC # Initial data for data3
data4:
    .byte 0xDD # Initial data for data4
data5:
    .byte 0xBB # Initial data for data5


success:
    addi a0, zero, 0  # Success: exit code 0

exit:
    ret
