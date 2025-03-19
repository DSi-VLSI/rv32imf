.include "startup.s"

main:
    # Test 1: lhu with zero offset
    la t0, data
    lhu t1, 0(t0)
    li t2, 0x1234
    beq t1, t2, test2_positive_offset # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test2_positive_offset:
    # Test 2: lhu with positive offset
    la t0, data
    lhu t1, 2(t0) # Offset to the second halfword
    li t2, 0x5678
    beq t1, t2, test3_negative_offset # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test3_negative_offset:
    # Test 3: lhu with negative offset (relative to data_end label)
    la t0, data_end
    lhu t1, -2(t0) # Offset to access the last halfword of data
    li t2, 0x9ABC
    beq t1, t2, test4_different_data # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test4_different_data:
    # Test 4: lhu from different data label (data2) with zero offset
    la t0, data2
    lhu t1, 0(t0)
    li t2, 0xCDEF
    beq t1, t2, test5_unsigned_extension_positive # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test5_unsigned_extension_positive:
    # Test 5: lhu unsigned extension with positive value (no extension effect, < 0x8000)
    la t0, data3
    lhu t1, 0(t0) # Load 0x7FFF
    li t2, 0x7FFF # Expecting positive 0x00007FFF after unsigned extension
    beq t1, t2, test6_unsigned_extension_large # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit


test6_unsigned_extension_large:
    # Test 6: lhu unsigned extension with large value (unsigned extension to 32-bit)
    la t0, data4
    lhu t1, 0(t0) # Load 0xF000
    li t2, 0xF000   # Expecting positive 0x0000F000 after unsigned extension
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
