.include "startup.s"

main:
    # Test 1: lh with zero offset
    la t0, data
    lh t1, 0(t0)
    li t2, 0x1234
    beq t1, t2, test2_positive_offset # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test2_positive_offset:
    # Test 2: lh with positive offset
    la t0, data
    lh t1, 2(t0) # Offset to the second halfword
    li t2, 0x5678
    beq t1, t2, test3_negative_offset # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test3_negative_offset:
    # Test 3: lh with negative offset (relative to data_end label)
    la t0, data_end
    lh t1, -2(t0) # Offset to access the last halfword of data
    li t2, 0x9ABC
    beq t1, t2, test4_different_data # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test4_different_data:
    # Test 4: lh from different data label (data2) with zero offset
    la t0, data2
    lh t1, 0(t0)
    li t2, 0xCDEF
    beq t1, t2, test5_sign_extension_positive # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test5_sign_extension_positive:
    # Test 5: lh sign extension with positive value (no sign extension needed, < 0x8000)
    la t0, data3
    lh t1, 0(t0) # Load 0x7FFF
    li t2, 0x7FFF # Expecting positive 0x00007FFF after sign extension
    beq t1, t2, test6_sign_extension_negative # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit


test6_sign_extension_negative:
    # Test 6: lh sign extension with negative value (sign extension needed, >= 0x8000)
    la t0, data4
    lh t1, 0(t0) # Load 0xF000 (-4096 in signed 16-bit)
    li t2, -4096   # Expecting negative 0xFFFFF000 after sign extension
    beq t1, t2, success # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit


data:
    .half 0x1234, 0x5678, 0x9ABC, 0xDEF0
data_end: # Label to point after data section
data2:
    .half 0xCDEF
data3:
    .half 0x7FFF
data4:
    .half 0xF000


success:
    addi a0, zero, 0  # Success: exit code 0

exit:
    ret
