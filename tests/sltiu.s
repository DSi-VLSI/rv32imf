.include "startup.s"

main:
    # Test 1: sltiu with less than immediate (positive)
    li t0, 10
    sltiu t1, t0, 20
    li t2, 1
    beq t1, t2, test2_greater_than_immediate # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test2_greater_than_immediate:
    # Test 2: sltiu with greater than immediate (positive)
    li t0, 20
    sltiu t1, t0, 10
    li t2, 0
    beq t1, t2, test3_equal_immediate # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test3_equal_immediate:
    # Test 3: sltiu with equal to immediate (positive)
    li t0, 15
    sltiu t1, t0, 15
    li t2, 0
    beq t1, t2, test4_less_than_zero_register # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test4_less_than_zero_register:
    # Test 4: sltiu with zero register and positive immediate
    li t0, 0
    sltiu t1, t0, 5
    li t2, 1
    beq t1, t2, test5_greater_than_zero_register # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test5_greater_than_zero_register:
    # Test 5: sltiu with zero register and zero immediate
    li t0, 0
    sltiu t1, t0, 0
    li t2, 0
    beq t1, t2, test6_max_immediate # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test6_max_immediate:
    # Test 6: sltiu with maximum immediate (2047) and smaller register
    li t0, 1000
    sltiu t1, t0, 2047
    li t2, 1
    beq t1, t2, test7_max_register_small_immediate # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test7_max_register_small_immediate:
    # Test 7: sltiu with maximum register value and smaller immediate (unsigned comparison)
    li t0, -1 # Maximum unsigned value (0xFFFFFFFF)
    sltiu t1, t0, 100 # Immediate is smaller unsigned
    li t2, 0 # Max unsigned is NOT less than 100
    beq t1, t2, test8_equal_max_unsigned # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit

test8_equal_max_unsigned:
    # Test 8: sltiu with equal maximum unsigned values (register and immediate)
    li t0, -1 # Maximum unsigned value (0xFFFFFFFF)
    sltiu t1, t0, -1 # Immediate is also max unsigned (0xFFFFFFFF)
    li t2, 0 # Max unsigned is NOT less than max unsigned
    beq t1, t2, success # Jump if t1 == t2 (success)
    addi a0, zero, 1  # Failure: exit code 1
    j exit


success:
    addi a0, zero, 0  # Success: exit code 0

exit:
    ret
