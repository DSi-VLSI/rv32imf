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
    echo -e "\033[1;32mDone!\033[0m"
done

# grep "TEST PASSED" "TEST FAILED"
clear
clear
echo -e "\033[1;36m TEST RESULTS \033[0m"

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
echo -e -n "  \033[1;32mPASSED \033[0m:$pass_count"
echo -e -n "  \033[1;31mFAILED \033[0m:$fail_count"
echo -e -n "  \033[1;31mERROR  \033[0m:$error_count"
echo -e -n "  \033[1;33mWARNING\033[0m:$warning_count"
echo -e -n "  \033[1;33mSKIPPED\033[0m:$skip_count"
echo ""

exit $(($fail_count + $error_count))
