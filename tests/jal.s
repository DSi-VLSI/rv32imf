.include "startup.s"

main:
    # Test 1: jal to target label and verify return address in t0
    jal t0, target1
    addi a0, zero, 1   # Failure if jal doesn't jump
    j exit

target1:
    addi t1, pc, 4     # Calculate expected return address (PC + 4)
    beq t0, t1, test2_jal_different_label # Jump if t0 == expected return address
    addi a0, zero, 1   # Failure: Return address incorrect
    j exit

test2_jal_different_label:
    # Test 2: jal to a different target label (target2) and verify return address in t0
    jal t0, target2
    addi a0, zero, 1   # Failure if jal doesn't jump
    j exit

target2:
    addi t1, pc, 4     # Calculate expected return address (PC + 4)
    beq t0, t1, test3_jal_ra_register # Jump if t0 == expected return address
    addi a0, zero, 1   # Failure: Return address incorrect
    j exit

test3_jal_ra_register:
    # Test 3: jal using ra register and verify return address in ra
    jal ra, target3
    addi a0, zero, 1   # Failure if jal doesn't jump
    j exit

target3:
    addi t1, pc, 4     # Calculate expected return address (PC + 4)
    beq ra, t1, test4_jal_farther_label # Jump if ra == expected return address
    addi a0, zero, 1   # Failure: Return address incorrect
    j exit

test4_jal_farther_label:
    # Test 4: jal to a label farther down and verify return address in ra
    jal ra, target4
    addi a0, zero, 1   # Failure if jal doesn't jump
    j exit

target4:
    addi t1, pc, 4     # Calculate expected return address (PC + 4)
    beq ra, t1, success # Jump if ra == expected return address
    addi a0, zero, 1   # Failure: Return address incorrect
    j exit


success:
    addi a0, zero, 0   # Success: exit code 0

exit:
    ret
