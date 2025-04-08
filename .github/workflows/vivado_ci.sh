#!/bin/bash

clear
echo -e "\033[1;33mRunning CI script ... \033[0m"

echo -n "Preparing Repository ... "
make clean > /dev/null 2>&1
mkdir -p build/ci_logs
echo -e "\033[1;32mDone!\033[0m"

# Update submodules
echo -n "Updating submodules ... "
git submodule update --init --recursive --depth 1 > /dev/null 2>&1
echo -e "\033[1;32mDone!\033[0m"

# Build the project
echo -n "Building the project ... "
make build/done > build/ci_logs/build_log 2>&1
echo -e "\033[1;32mDone!\033[0m"

tests=$(find tests -type f | sed "s/.*\///g" | sort)
for test in $tests; do
    if [[ $test == _* ]]; then
        continue
    fi
    echo -n "Running test $test ... "
    make run TEST=$test > build/ci_logs/$test.log 2>&1
    sort build/prog.cov | uniq > build/temp_file && mv build/temp_file build/prog.cov
    cat build/prog.cov >> build/ci_coveage.log
    echo -e "\033[1;32mDone!\033[0m"
done

sort build/ci_coveage.log | uniq > build/temp_file && mv build/temp_file build/ci_coveage.log

clear
echo -e "\033[1;36m TEST RESULTS \033[0m"

echo ""
covered_count=0
uncovered_count=0
echo -e "  \033[1;35mInstructions Coverage\033[0m"

get_coverage() {
    local instruction=$1
    local count=$(grep -c "INSTR_COV: $instruction" build/ci_coveage.log)
    if [[ $count -gt 0 ]]; then
        echo -e "    \033[0;32m$instruction\033[0m"
        covered_count=$(($covered_count + 1))
    else
        uncovered_count=$((uncovered_count + 1))
        echo -e "    \033[0;31m$instruction\033[0m"
    fi
}

# if ci_coverage.log contains INSTR_COV: LUI, then print the line & cov_count++
get_coverage LUI
get_coverage AUIPC
get_coverage JAL
get_coverage JALR
get_coverage BEQ
get_coverage BNE
get_coverage BLT
get_coverage BGE
get_coverage BLTU
get_coverage BGEU
get_coverage LB
get_coverage LH
get_coverage LW
get_coverage LBU
get_coverage LHU
get_coverage SB
get_coverage SH
get_coverage SW
get_coverage ADDI
get_coverage SLTI
get_coverage SLTIU
get_coverage XORI
get_coverage ORI
get_coverage ANDI
get_coverage SLLI
get_coverage SRLI
get_coverage SRAI
get_coverage ADD
get_coverage SUB
get_coverage SLL
get_coverage SLT
get_coverage SLTU
get_coverage XOR
get_coverage SRL
get_coverage SRA
get_coverage OR
get_coverage AND
get_coverage FENCE
get_coverage ECALL
get_coverage EBREAK
get_coverage CSRRW
get_coverage CSRRS
get_coverage CSRRC
get_coverage CSRRWI
get_coverage CSRRSI
get_coverage CSRRCI
get_coverage MUL
get_coverage MULH
get_coverage MULHSU
get_coverage MULHU
get_coverage DIV
get_coverage DIVU
get_coverage REM
get_coverage REMU
get_coverage FLW
get_coverage FSW
get_coverage FMADD_S
get_coverage FMSUB_S
get_coverage FNMSUB_S
get_coverage FNMADD_S
get_coverage FADD_S
get_coverage FSUB_S
get_coverage FMUL_S
get_coverage FDIV_S
get_coverage FSQRT_S
get_coverage FSGNJ_S
get_coverage FSGNJN_S
get_coverage FSGNJX_S
get_coverage FMIN_S
get_coverage FMAX_S
get_coverage FCVT_W_S
get_coverage FCVT_WU_S
get_coverage FMV_X_W
get_coverage FEQ_S
get_coverage FLT_S
get_coverage FLE_S
get_coverage FCLASS_S
get_coverage FCVT_S_W
get_coverage FCVT_S_WU
get_coverage FMV_W_X

echo ""
echo -e "  \033[1;32mPASSED\033[0m"
grep -r "TEST PASSED" build/ci_logs/* | sed "s/.*\//    /g" | sed "s/\.log:.*/    /g"
pass_count=$(grep -r "TEST PASSED" build/ci_logs/* | wc -l)

echo ""
echo -e "  \033[1;31mFAILED\033[0m"
grep -r "TEST FAILED" build/ci_logs/* | sed "s/.*\//    /g" | sed "s/\.log:.*/    /g"
fail_count=$(grep -r "TEST FAILED" build/ci_logs/* | wc -l)

echo ""
echo -e "  \033[1;31mERROR\033[0m"
grep -r -i "ERROR" build/ci_logs/* | sed "s/.*\//    /g" | sed "s/\.log:.*/    /g"
error_count=$(grep -r -i "ERROR" build/ci_logs/* | wc -l)

echo ""
echo -e "  \033[1;33mWARNING\033[0m"
grep -r -i "WARNING" build/ci_logs/* | sed "s/.*\//    /g" | sed "s/\.log:.*/    /g"
warning_count=$(grep -r "WARNING" build/ci_logs/* | wc -l)

echo ""
echo -e "  \033[1;33mSKIPPING\033[0m"
find tests -type f -name "_*" | sed "s/.*\//    /g" | sort
skip_count=$(find tests -type f -name "_*" | wc -l)

echo ""

echo ""
echo -e -n "  \033[1;32mPASSED\033[0m:$pass_count"
echo -e -n "  \033[1;31mFAILED\033[0m:$fail_count"
echo -e -n "  \033[1;31mERROR\033[0m:$error_count"
echo -e -n "  \033[1;33mWARNING\033[0m:$warning_count"
echo -e -n "  \033[1;33mSKIPPED\033[0m:$skip_count"
echo ""

echo ""
echo -e -n "  \033[1;35mINSTRUCTION_COVERAGE\033[0m:$((100 * $covered_count / ($covered_count + $uncovered_count)))%"
echo ""

exit $(($fail_count + $error_count))
