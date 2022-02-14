#-------------------------------------------------------------------------------
# Arduino Mega2560 Command Line Monitor Program
#
# Makefile for building the target image.
#
# Copyright (c) 2022 Robert I. Gike
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#-------------------------------------------------------------------------------

MKDIR_P := mkdir -p
RM_F    := rm -f
SHELL   := /bin/bash

# target output file name and serial console speed
# the boot loader is fixed at 115200
CONSPEED := 115200
OUTFILE  := cmdline

# project directories
BUILD_DIR    := build
INC_DIR      := include
LINK_DIR     := link
SRC_DIR      := src
MEGA2560_DIR := src/mega2560

# Arduino platform configuration
include $(INC_DIR)/atmega2560.mk

# project configuration
PROJECT_DEFS := CONSPEED=$(CONSPEED)

SRCS := $(shell find $(SRC_DIR) -name *.c -or -name *.cpp -or -name *.S)
OBJS := $(SRCS:%=$(BUILD_DIR)/obj/%.o)
DEPS := $(OBJS:.o=.d)

INCLUDE_DIRS  := $(INC_DIR) $(ARDUINOINCPATH) $(MEGA2560PATH)
INCLUDE_FILES := $(shell find $(INC_DIR) -name *.h)

LIB_DIRS := lib
LIBS     := m

CPP_FLAGS += $(addprefix -I,$(INCLUDE_DIRS)) $(addprefix -D,$(PROJECT_DEFS))
C_FLAGS   += $(addprefix -I,$(INCLUDE_DIRS)) $(addprefix -D,$(PROJECT_DEFS))
S_FLAGS   += $(addprefix -I,$(INCLUDE_DIRS))
LD_FLAGS  += $(addprefix -L,$(LIB_DIRS)) $(addprefix -l,$(LIBS))

OBJCOPY_TO_EEP := -O ihex -j .eeprom --set-section-flags=.eeprom=alloc,load --no-change-warnings --change-section-lma .eeprom=0
OBJCOPY_TO_HEX := -O ihex -R .eeprom

HOST_GPP := g++ -std=gnu++14 -DHOSTTEST -Iinclude -Wall -Werror

MEGA2560SRC := CDC.cpp HardwareSerial0.cpp HardwareSerial.cpp hooks.c
MEGA2560SRC += main.cpp Print.cpp Stream.cpp USBCore.cpp WInterrupts.c
MEGA2560SRC += wiring_analog.c wiring.c wiring_digital.c wiring_pulse.c
MEGA2560SRC += wiring_pulse.S wiring_shift.c

#-----------------------------------------------------------------------
# help
#-----------------------------------------------------------------------
.PHONY: help
help:
	@echo ""
	@echo "Command Line Monitor Targets:"
	@echo ""
	@echo "all       - compile the .hex output file"
	@echo "clean     - remove generated files"
	@echo "edit      - edit files"
	@echo "flash     - program the mega2560 board"
	@echo "hosttest  - build the code for test on PC"
	@echo "megalinks - construct mega2560 source file links"
	@echo ""

#-----------------------------------------------------------------------
.PHONY: all
all: testlinks $(BUILD_DIR)/$(OUTFILE).hex

#-----------------------------------------------------------------------
.PHONY: clean
clean:
	@echo "Remove generated files..."
	@$(RM_F) -r $(BUILD_DIR)

#-----------------------------------------------------------------------
.PHONY: edit
edit:
	ctags -R
	@vi src/cmdline.cpp $(INCLUDE_FILES) makefile $(INC_DIR)/atmega2560.mk

#-----------------------------------------------------------------------
# My build runs in a VM (kvm guest) while the mega2560 is accessed
# through a host USB port. So instead of calling the loader directly
# the .hex file is scp'd to the host and the loader is run via ssh.
flash: $(BUILD_DIR)/$(OUTFILE).hex
	scp $< vm3700:~/mega2560
	ssh vm3700 "cd ~/mega2560; ./flashmega.sh /dev/ArduinoMega2560 $(CONSPEED) $(OUTFILE).hex"

# Use this target when the mega2560 hardware is directly connected
flash2: $(BUILD_DIR)/$(OUTFILE).hex
	scripts/flashmega.sh /dev/ArduinoMega2560 $(CONSPEED) $<

#
# Note: add your username to the dialout group to grant access to
#       the /dev/ArduinoMega2560 device for flashing the firmware.
#
# (as root user) usermod -a -G dialout <username>
#

#-----------------------------------------------------------------------
# standalone host test binary
.PHONY: hosttest
hosttest:
	@$(MKDIR_P) $(BUILD_DIR)
	$(HOST_GPP) $(SRC_DIR)/cmdline.cpp -o $(BUILD_DIR)/hosttest

#-----------------------------------------------------------------------
# construct the mega2560 source file links
# mega2560 *.c and *.cpp files
.PHONY: megalinks
megalinks:
	@$(MKDIR_P) $(MEGA2560_DIR)
	@$(RM_F) $(MEGA2560_DIR)/*
	@for file in $(MEGA2560SRC) ; do \
		echo "ln -s $(ARDUINOINCPATH)/$$file $(MEGA2560_DIR)/." ; \
		ln -s $(ARDUINOINCPATH)/$$file $(MEGA2560_DIR)/. ; \
	done 

#-----------------------------------------------------------------------
# test for presence of file links
.PHONY: testlinks
testlinks:
	@files=( $(MEGA2560SRC) ); \
	if ! [ -L $(MEGA2560_DIR)/$${files[0]} ]; then \
		echo "File link error"; \
		echo "Have you run make megalinks ?"; \
		exit 1; \
	fi

#-----------------------------------------------------------------------
# convert the output file from elf to hex
$(BUILD_DIR)/$(OUTFILE).hex: $(BUILD_DIR)/$(OUTFILE).elf
	@echo "Convert elf to hex..."
	@$(OBJCOPY) $(OBJCOPY_TO_EEP) $(BUILD_DIR)/$(OUTFILE).elf $(BUILD_DIR)/$(OUTFILE).eep
	@$(OBJCOPY) $(OBJCOPY_TO_HEX) $(BUILD_DIR)/$(OUTFILE).elf $(BUILD_DIR)/$(OUTFILE).hex
	@$(OBJDUMP) -d -x $(BUILD_DIR)/$(OUTFILE).elf > $(BUILD_DIR)/$(OUTFILE).dis
	@$(OBJDUMP) -d -S -C $(BUILD_DIR)/$(OUTFILE).elf > $(BUILD_DIR)/$(OUTFILE).lst
	@$(SIZE) -A $(BUILD_DIR)/$(OUTFILE).elf

#-----------------------------------------------------------------------
# link the program
$(BUILD_DIR)/$(OUTFILE).elf: $(OBJS)
	@echo "Linking..."
#	@echo "$(GCC) $(LD_FLAGS) -o $@ $^"
	@$(GCC) $(LD_FLAGS) -o $@ $^

#-----------------------------------------------------------------------
# compile assembler source
$(BUILD_DIR)/obj/%.S.o: %.S
	@echo "Assembling (S)   $<"
	@$(MKDIR_P) $(dir $@)
#	@echo "$(GPP) $(S_FLAGS) -c $< -o $@"
	@$(GPP) $(S_FLAGS) -c $< -o $@

#-----------------------------------------------------------------------
# compile C source
$(BUILD_DIR)/obj/%.c.o: %.c
	@echo "Compiling  (c)   $<"
	@$(MKDIR_P) $(dir $@)
#	@echo "$(GCC) $(C_FLAGS) -c $< -o $@"
	@$(GCC) $(C_FLAGS) -c $< -o $@

#-----------------------------------------------------------------------
# compile C++ source
$(BUILD_DIR)/obj/%.cpp.o: %.cpp
	@echo "Compiling  (c++) $<"
	@$(MKDIR_P) $(dir $@)
#	@echo "$(GPP) ${CPP_FLAGS} -c $< -o $@"
	@$(GPP) ${CPP_FLAGS} -c $< -o $@

