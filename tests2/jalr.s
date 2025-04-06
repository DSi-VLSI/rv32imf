.include "startup.s"

main:
    # Test 1: jalr to target label with zero offset and verify return address in t1
    la t0, target1
    jalr t1, t0, 0
    addi a0, zero, 1   # Failure if jalr doesn't jump
    j exit

target1:
    addi t2, pc, 4     # Calculate expected return address (PC + 4)
    beq t1, t2, test2_jalr_positive_offset # Jump if t1 == expected return address
    addi a0, zero, 1   # Failure: Return address incorrect
    j exit

test2_jalr_positive_offset:
    # Test 2: jalr to target label with positive offset and verify return address in t1
    la t0, target2
    jalr t1, t0, 8  # Positive offset
    addi a0, zero, 1   # Failure if jalr doesn't jump
    j exit

target2:
    addi t2, pc, 4 + 8   # Calculate expected return address (PC + 4 + offset)
    beq t1, t2, test3_jalr_negative_offset # Jump if t1 == expected return address
    addi a0, zero, 1   # Failure: Return address incorrect
    j exit

test3_jalr_negative_offset:
    # Test 3: jalr to target label with negative offset and verify return address in t1
    la t0, target3_calc
    addi t0, t0, 20 # Adjust address to jump into target3 label
    jalr t1, t0, -20 # Negative offset to jump to start of target3
    addi a0, zero, 1   # Failure if jalr doesn't jump
    j exit

target3_calc: # Dummy label to calculate base address for negative offset jump
target3:
    addi t2, pc, 4 - 20  # Calculate expected return address (PC + 4 - offset)
    beq t1, t2, test4_jalr_ra_register # Jump if t1 == expected return address
    addi a0, zero, 1   # Failure: Return address incorrect
    j exit

test4_jalr_ra_register:
    # Test 4: jalr using ra register and verify return address in ra
    la t0, target4
    jalr ra, t0, 0
    addi a0, zero, 1   # Failure if jalr doesn't jump
    j exit

target4:
    addi t2, pc, 4     # Calculate expected return address (PC + 4)
    beq ra, t2, success # Jump if ra == expected return address
    addi a0, zero, 1   # Failure: Return address incorrect
    j exit


success:
    addi a0, zero, 0   # Success: exit code 0

exit:
    ret
