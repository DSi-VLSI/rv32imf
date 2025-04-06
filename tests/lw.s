.include "startup.s"

main:
    # Test 1: lw with zero offset
    la t0, data
    lw t1, 0(t0)
    li t2, 0x12345678
    beq t1, t2, test2_positive_offset # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test2_positive_offset:
    # Test 2: lw with positive offset
    la t0, data
    lw t1, 4(t0) # Offset to the second word
    li t2, 0x9ABCDEF0
    beq t1, t2, test3_negative_offset # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test3_negative_offset:
    # Test 3: lw with negative offset (relative to data_end label)
    la t0, data_end
    lw t1, -4(t0) # Offset to access the last word of data
    li t2, 0x55AA55AA
    beq t1, t2, test4_different_data # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test4_different_data:
    # Test 4: lw from different data label (data2) with zero offset
    la t0, data2
    lw t1, 0(t0)
    li t2, 0xCAFEBABE
    beq t1, t2, test5_large_positive_value # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test5_large_positive_value:
    # Test 5: lw with large positive value (maximum positive 32-bit integer)
    la t0, data3
    lw t1, 0(t0)
    li t2, 0x7FFFFFFF
    beq t1, t2, test6_negative_value # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test6_negative_value:
    # Test 6: lw with negative value (minimum negative 32-bit integer)
    la t0, data4
    lw t1, 0(t0)
    li t2, -0x80000000 # Minimum negative 32-bit integer
    beq t1, t2, success # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit


data:
    .word 0x12345678, 0x9ABCDEF0, 0x11223344, 0x55AA55AA
data_end: # Label to point after data section
data2:
    .word 0xCAFEBABE
data3:
    .word 0x7FFFFFFF
data4:
    .word 0x80000000 # Representing -0x80000000 as unsigned for .word


success:
    addi a0, zero, 0  # Success: exit code 0

exit:
    ret