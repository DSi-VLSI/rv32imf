# Set the default goal to 'help'
.DEFAULT_GOAL := help

# Define the root directory
ROOT := $(shell echo "$(realpath .)")

# Define the grep command for warnings and errors
GREP_EW := grep -E "WARNING:|ERROR:|" --color=auto

# Define the GCC command for RISC-V
RV64G_GCC := riscv64-unknown-elf-gcc -march=rv32imf -mabi=ilp32 -nostdlib -nostartfiles

# Define the test argument
DEBUG ?= 0
ifeq ($(DEBUG), 1)
	TESTPLUSARGS = --testplusarg DEBUG
else
	TESTPLUSARGS = 
endif

################################################################################
# Add all the RTL source files to the LIB variable
################################################################################

LIB += ${ROOT}/source/rv32imf_pkg.sv
LIB += ${ROOT}/source/rv32imf_fpu_pkg.sv
LIB += ${ROOT}/source/fpnew_pkg.sv
LIB += ${ROOT}/source/rv32imf_clock_gate.sv
LIB += ${ROOT}/source/rv32imf_sleep_unit.sv
LIB += ${ROOT}/source/rv32imf_prefetch_controller.sv
LIB += ${ROOT}/source/rv32imf_fifo.sv
LIB += ${ROOT}/source/rv32imf_obi_interface.sv
LIB += ${ROOT}/source/rv32imf_prefetch_buffer.sv
LIB += ${ROOT}/source/rv32imf_aligner.sv
LIB += ${ROOT}/source/rv32imf_compressed_decoder.sv
LIB += ${ROOT}/source/rv32imf_if_stage.sv
LIB += ${ROOT}/source/rv32imf_register_file.sv
LIB += ${ROOT}/source/rv32imf_decoder.sv
LIB += ${ROOT}/source/rv32imf_controller.sv
LIB += ${ROOT}/source/rv32imf_int_controller.sv
LIB += ${ROOT}/source/rv32imf_id_stage.sv
LIB += ${ROOT}/source/rv32imf_popcnt.sv
LIB += ${ROOT}/source/rv32imf_ff_one.sv
LIB += ${ROOT}/source/rv32imf_alu_div.sv
LIB += ${ROOT}/source/rv32imf_alu.sv
LIB += ${ROOT}/source/rv32imf_mult.sv
LIB += ${ROOT}/source/rv32imf_apu_disp.sv
LIB += ${ROOT}/source/rv32imf_ex_stage.sv
LIB += ${ROOT}/source/rv32imf_load_store_unit.sv
LIB += ${ROOT}/source/rv32imf_cs_registers.sv
LIB += ${ROOT}/source/rv32imf_core.sv
LIB += ${ROOT}/source/fpnew_classifier.sv
LIB += ${ROOT}/source/lzc.sv
LIB += ${ROOT}/source/fpnew_rounding.sv
LIB += ${ROOT}/source/fpnew_fma_multi.sv
LIB += ${ROOT}/source/fpnew_opgroup_multifmt_slice.sv
LIB += ${ROOT}/source/rr_arb_tree.sv
LIB += ${ROOT}/source/fpnew_opgroup_block.sv
LIB += ${ROOT}/source/pa_fdsu_special.sv
LIB += ${ROOT}/source/pa_fdsu_ff1.sv
LIB += ${ROOT}/source/pa_fdsu_prepare.sv
LIB += ${ROOT}/source/gated_clk_cell.sv
LIB += ${ROOT}/source/pa_fdsu_srt_single.sv
LIB += ${ROOT}/source/pa_fdsu_round_single.sv
LIB += ${ROOT}/source/pa_fdsu_pack_single.sv
LIB += ${ROOT}/source/pa_fdsu_ctrl.sv
LIB += ${ROOT}/source/pa_fdsu_top.sv
LIB += ${ROOT}/source/pa_fpu_src_type.sv
LIB += ${ROOT}/source/pa_fpu_dp.sv
LIB += ${ROOT}/source/pa_fpu_frbus.sv
LIB += ${ROOT}/source/fpnew_divsqrt_th_32.sv
LIB += ${ROOT}/source/fpnew_noncomp.sv
LIB += ${ROOT}/source/fpnew_opgroup_fmt_slice.sv
LIB += ${ROOT}/source/fpnew_cast_multi.sv
LIB += ${ROOT}/source/fpnew_top.sv
LIB += ${ROOT}/source/rv32imf_fp_wrapper.sv
LIB += ${ROOT}/source/rv32imf.sv

################################################################################
# Add all the testbench files to the LIB variable
################################################################################

LIB += ${ROOT}/tb/sim_memory.sv
LIB += ${ROOT}/tb/rv32imf_tb.sv

################################################################################
# TARGETS
################################################################################

# Define the 'vivado' target to clean and run the build
.PHONY: vivado
vivado: clean run

# Define the 'clean' target to remove the build directory
.PHONY: clean
clean:
	@rm -rf build
	@make -s build

# Define the 'build' target to create the build directory and add it to gitignore
build:
	@mkdir -p build
	@echo "*" > build/.gitignore
	@git add build > /dev/null 2>&1

# Define the 'build/done' target to compile the project
build/done:
	@make -s compile

# Define the 'compile' target to compile the source files
.PHONY: compile
compile: build
	@cd build; xvlog -i ${ROOT}/include -sv ${LIB} | $(GREP_EW)
	@cd build; xelab rv32imf_tb -s top | $(GREP_EW)
	@echo "build done" > build/done

# Define the 'run' target to run the tests
.PHONY: run
run: build/done
	@make -s test TEST=$(TEST)
	@cd build; xsim top $(TESTPLUSARGS) -runall | $(GREP_EW)
ifeq ($(DEBUG), 1)
	@make -s readable
endif

# Define the 'readable' target to make the trace file more readable
.PHONY: readable
readable: build/trace.txt
	@sed "s/GPR0:/x0\/zero:/g" -i build/trace.txt
	@sed "s/GPR1:/x1\/ra:/g" -i build/trace.txt
	@sed "s/GPR2:/x2\/sp:/g" -i build/trace.txt
	@sed "s/GPR3:/x3\/gp:/g" -i build/trace.txt
	@sed "s/GPR4:/x4\/tp:/g" -i build/trace.txt
	@sed "s/GPR5:/x5\/t0:/g" -i build/trace.txt
	@sed "s/GPR6:/x6\/t1:/g" -i build/trace.txt
	@sed "s/GPR7:/x7\/t2:/g" -i build/trace.txt
	@sed "s/GPR8:/x8\/s0\/fp:/g" -i build/trace.txt
	@sed "s/GPR9:/x9\/s1:/g" -i build/trace.txt
	@sed "s/GPR10:/x10\/a0:/g" -i build/trace.txt
	@sed "s/GPR11:/x11\/a1:/g" -i build/trace.txt
	@sed "s/GPR12:/x12\/a2:/g" -i build/trace.txt
	@sed "s/GPR13:/x13\/a3:/g" -i build/trace.txt
	@sed "s/GPR14:/x14\/a4:/g" -i build/trace.txt
	@sed "s/GPR15:/x15\/a5:/g" -i build/trace.txt
	@sed "s/GPR16:/x16\/a6:/g" -i build/trace.txt
	@sed "s/GPR17:/x17\/a7:/g" -i build/trace.txt
	@sed "s/GPR18:/x18\/s2:/g" -i build/trace.txt
	@sed "s/GPR19:/x19\/s3:/g" -i build/trace.txt
	@sed "s/GPR20:/x20\/s4:/g" -i build/trace.txt
	@sed "s/GPR21:/x21\/s5:/g" -i build/trace.txt
	@sed "s/GPR22:/x22\/s6:/g" -i build/trace.txt
	@sed "s/GPR23:/x23\/s7:/g" -i build/trace.txt
	@sed "s/GPR24:/x24\/s8:/g" -i build/trace.txt
	@sed "s/GPR25:/x25\/s9:/g" -i build/trace.txt
	@sed "s/GPR26:/x26\/s10:/g" -i build/trace.txt
	@sed "s/GPR27:/x27\/s11:/g" -i build/trace.txt
	@sed "s/GPR28:/x28\/t3:/g" -i build/trace.txt
	@sed "s/GPR29:/x29\/t4:/g" -i build/trace.txt
	@sed "s/GPR30:/x30\/t5:/g" -i build/trace.txt
	@sed "s/GPR31:/x31\/t6:/g" -i build/trace.txt
	@sed "s/FPR0:/f0\/ft0:/g" -i build/trace.txt
	@sed "s/FPR1:/f1\/ft1:/g" -i build/trace.txt
	@sed "s/FPR2:/f2\/ft2:/g" -i build/trace.txt
	@sed "s/FPR3:/f3\/ft3:/g" -i build/trace.txt
	@sed "s/FPR4:/f4\/ft4:/g" -i build/trace.txt
	@sed "s/FPR5:/f5\/ft5:/g" -i build/trace.txt
	@sed "s/FPR6:/f6\/ft6:/g" -i build/trace.txt
	@sed "s/FPR7:/f7\/ft7:/g" -i build/trace.txt
	@sed "s/FPR8:/f8\/fs0:/g" -i build/trace.txt
	@sed "s/FPR9:/f9\/fs1:/g" -i build/trace.txt
	@sed "s/FPR10:/f10\/fa0:/g" -i build/trace.txt
	@sed "s/FPR11:/f11\/fa1:/g" -i build/trace.txt
	@sed "s/FPR12:/f12\/fa2:/g" -i build/trace.txt
	@sed "s/FPR13:/f13\/fa3:/g" -i build/trace.txt
	@sed "s/FPR14:/f14\/fa4:/g" -i build/trace.txt
	@sed "s/FPR15:/f15\/fa5:/g" -i build/trace.txt
	@sed "s/FPR16:/f16\/fa6:/g" -i build/trace.txt
	@sed "s/FPR17:/f17\/fa7:/g" -i build/trace.txt
	@sed "s/FPR18:/f18\/fs2:/g" -i build/trace.txt
	@sed "s/FPR19:/f19\/fs3:/g" -i build/trace.txt
	@sed "s/FPR20:/f20\/fs4:/g" -i build/trace.txt
	@sed "s/FPR21:/f21\/fs5:/g" -i build/trace.txt
	@sed "s/FPR22:/f22\/fs6:/g" -i build/trace.txt
	@sed "s/FPR23:/f23\/fs7:/g" -i build/trace.txt
	@sed "s/FPR24:/f24\/fs8:/g" -i build/trace.txt
	@sed "s/FPR25:/f25\/fs9:/g" -i build/trace.txt
	@sed "s/FPR26:/f26\/fs10:/g" -i build/trace.txt
	@sed "s/FPR27:/f27\/fs11:/g" -i build/trace.txt
	@sed "s/FPR28:/f28\/ft8:/g" -i build/trace.txt
	@sed "s/FPR29:/f29\/ft9:/g" -i build/trace.txt
	@sed "s/FPR30:/f30\/ft10:/g" -i build/trace.txt
	@sed "s/FPR31:/f31\/ft11:/g" -i build/trace.txt
	@$(eval list := $(shell grep -r "PROGRAM_COUNTER:0x" build/trace.txt | sed "s/PROGRAM_COUNTER:0x//g"))
	@$(foreach item,$(list),$(call replace,$(item));)
	@echo "build/trace.txt ready for reading"

define replace
$(eval line_f :=$(shell grep -r "PROGRAM_COUNTER:0x$(1)" build/trace.txt))
$(eval line_r :=$(shell grep -r "$(1):" build/$(TEST).dump))
sed "s/$(line_f)/$(line_r)/g" -i build/trace.txt
endef

build/readable:
	@make -s run TEST=$(TEST) DEBUG=1

# Define the 'test' target to compile and run a specific test
.PHONY: test
test: build
	@if [ -z ${TEST} ]; then echo -e "\033[1;31mTEST is not set\033[0m"; exit 1; fi
	@if [ ! -f tests/$(TEST) ]; then echo -e "\033[1;31mtests/$(TEST) does not exist\033[0m"; exit 1; fi
	@$(eval TEST_TYPE := $(shell echo "$(TEST)" | sed "s/.*\.//g"))
	@if [ "$(TEST_TYPE)" = "c" ]; then TEST_ARGS="lib/startup.s"; else TEST_ARGS=""; fi; \
		$(RV64G_GCC) -o build/$(TEST).elf tests/$(TEST) $$TEST_ARGS -Ilib
	@riscv64-unknown-elf-objcopy -O verilog build/$(TEST).elf build/prog.hex
	@riscv64-unknown-elf-nm build/$(TEST).elf > build/prog.sym
	@riscv64-unknown-elf-objdump -d build/$(TEST).elf > build/$(TEST).dump

# Define the 'help' target to display usage information
.PHONY: help
help:
	@echo -e "\033[1;32mUsage:\033[0m"
	@echo -e "\033[1;35m  make help                \033[0m# Display this help message"
	@echo -e "\033[1;35m  make clean               \033[0m# Remove the build directory"
	@echo -e "\033[1;35m  make vivado TEST=<test>  \033[0m# Clean and run the build"
	@echo -e "\033[1;35m  make run TEST=<test>     \033[0m# Run the tests"
	@echo -e "\033[1;35m  make run TEST=<test> DEBUG=1 \033[0m# Run the tests with debug mode"
	@echo -e ""
	@echo -e "\033[1;32mExamples:\033[0m"
	@for file in $(shell ls tests); do \
		if [ $${file##*.} = "c" ] || [ $${file##*.} = "s" ]; then \
			echo -e "\033[1;35m  make run TEST=$${file}\033[0m"; \
		fi; \
	done
