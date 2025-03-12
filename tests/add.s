.include "startup.s"

main:
    # Test 1: add with positive numbers
    li t0, 10
    li t1, 15
    add t2, t0, t1
    li t3, 25
    beq t2, t3, test2_positive_add_success # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test2_positive_add_success:
    # Test 2: add with negative numbers
    li t0, -10
    li t1, -15
    add t2, t0, t1
    li t3, -25
    beq t2, t3, test3_zero_add # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test3_zero_add:
    # Test 3: add with zero
    li t0, 50
    li t1, 0
    add t2, t0, t1
    li t3, 50
    beq t2, t3, test4_mixed_add # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test4_mixed_add:
    # Test 4: add with mixed positive and negative numbers
    li t0, 30
    li t1, -10
    add t2, t0, t1
    li t3, 20
    beq t2, t3, test5_large_positive_add # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test5_large_positive_add:
    # Test 5: add with larger positive numbers
    li t0, 1000
    li t1, 2000
    add t2, t0, t1
    li t3, 3000
    beq t2, t3, test6_large_negative_add # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test6_large_negative_add:
    # Test 6: add with larger negative numbers
    li t0, -1000
    li t1, -2000
    add t2, t0, t1
    li t3, -3000
    beq t2, t3, success # Jump if t2 == t3 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

success:
    addi a0, zero, 0  # Success: exit code 0

exit:
    ret
