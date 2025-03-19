.include "startup.s"

main:
    # Test 1: lb with zero offset
    la t0, data
    lb t1, 0(t0)
    li t2, 0x12
    beq t1, t2, test2_positive_offset # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test2_positive_offset:
    # Test 2: lb with positive offset
    la t0, data
    lb t1, 1(t0)
    li t2, 0x34
    beq t1, t2, test3_negative_offset # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test3_negative_offset:
    # Test 3: lb with negative offset (relative to data_end label)
    la t0, data_end
    lb t1, -1(t0) # Offset to access the last byte of data
    li t2, 0x78
    beq t1, t2, test4_different_data # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test4_different_data:
    # Test 4: lb from different data label (data2) with zero offset
    la t0, data2
    lb t1, 0(t0)
    li t2, 0xAB
    beq t1, t2, test5_sign_extension_positive # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test5_sign_extension_positive:
    # Test 5: lb sign extension with positive value (no sign extension needed, < 0x80)
    la t0, data3
    lb t1, 0(t0) # Load 0x7F
    li t2, 0x7F # Expecting positive 0x7F after sign extension
    beq t1, t2, test6_sign_extension_negative # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit


test6_sign_extension_negative:
    # Test 6: lb sign extension with negative value (sign extension needed, >= 0x80)
    la t0, data4
    lb t1, 0(t0) # Load 0xF0 (-16 in signed 8-bit)
    li t2, -16   # Expecting negative 0xFFFFFFF0 after sign extension
    beq t1, t2, success # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit


data:
    .byte 0x12, 0x34, 0x56, 0x78
data_end: # Label to point after data section
data2:
    .byte 0xAB
data3:
    .byte 0x7F
data4:
    .byte 0xF0


success:
    addi a0, zero, 0  # Success: exit code 0

exit:
    ret
