.include "startup.s"

main:
    # Test 1: addi with positive immediate
    li t0, 10
    addi t1, t0, 5
    li t2, 15
    beq t1, t2, test2_negative_immediate # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test2_negative_immediate:
    # Test 2: addi with negative immediate
    li t0, 20
    addi t1, t0, -8
    li t2, 12
    beq t1, t2, test3_zero_immediate # Jump if t1 == t2 (success)
    addi a0, zero, 1 # Failure: exit code 1
    j exit

test3_zero_immediate:
    # Test 3: addi with zero immediate
    li t0, 30
    addi t1, t0, 0
    li t2, 30
    beq t1, t2, test4_large_positive_immediate # Jump if t1 == t2 (success)
    addi a0, zero, 1 # Failure: exit code 1
    j exit

test4_large_positive_immediate:
    # Test 4: addi with large positive immediate
    li t0, 100
    addi t1, t0, 2047 # Maximum positive immediate for addi (RISC-V 32I)
    li t2, 2147
    beq t1, t2, test5_large_negative_immediate # Jump if t1 == t2 (success)
    addi a0, zero, 1 # Failure: exit code 1
    j exit

test5_large_negative_immediate:
    # Test 5: addi with large negative immediate
    li t0, 2047
    addi t1, t0, -2048 # Maximum negative immediate for addi (RISC-V 32I)
    li t2, 0 - 1 # -1 in two's complement
    beq t1, t2, test6_negative_register # Jump if t1 == t2 (success)
    addi a0, zero, 1 # Failure: exit code 1
    j exit

test6_negative_register:
    # Test 6: addi with negative register and positive immediate
    li t0, -50
    addi t1, t0, 25
    li t2, -25
    beq t1, t2, success # Jump if t1 == t2 (success)
    addi a0, zero, 1 # Failure: exit code 1
    j exit


success:
    addi a0, zero, 0  # Success: exit code 0

exit:
    ret
