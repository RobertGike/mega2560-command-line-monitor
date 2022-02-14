#-------------------------------------------------------------------------------
# Arduino Mega2560 .mk file - Arduino build environment
#
# Include file used to define the Mega2560 build specific configuration.
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

# use the Arduino compiler and support files
ARDUINOPATH := $(HOME)/arduino-1.8.19

# Arduino include paths
ARDUINOINCPATH := $(ARDUINOPATH)/hardware/arduino/avr/cores/arduino
MEGA2560PATH   := $(ARDUINOPATH)/hardware/arduino/avr/variants/mega

# path to avr compilers, avrdude (on Linux)
TOOLSPATH := $(ARDUINOPATH)/hardware/tools/avr/bin

# path to Arduino libraries
LIBRARYPATH := $(ARDUINOPATH)/libraries

GCC     := $(TOOLSPATH)/avr-gcc
GPP     := $(TOOLSPATH)/avr-g++
OBJCOPY := $(TOOLSPATH)/avr-objcopy
OBJDUMP := $(TOOLSPATH)/avr-objdump
SIZE    := $(TOOLSPATH)/avr-size
LOADER  := $(TOOLSPATH)/avrdude

# Arduino Mega2560
MCU_DEF := F_CPU=16000000L ARDUINO=10819 ARDUINO_AVR_MEGA2560 ARDUINO_ARCH_AVR

F_MCU   := $(addprefix -D,$(MCU_DEF))

F_CPU   := -mmcu=atmega2560 
F_OPT   := -Os -w
F_COM   := -c -g -Wall -Werror -MMD -flto

F_CPP   := -std=gnu++11 -fpermissive -fno-exceptions -ffunction-sections -fdata-sections -fno-threadsafe-statics -Wno-error=narrowing
F_C     := -std=gnu11 -ffunction-sections -fdata-sections -fno-fat-lto-objects
F_S     := -x assembler-with-cpp

# link control
F_LD    := -w -Os -g -flto -fuse-linker-plugin -Wl,--gc-sections -mmcu=atmega2560

CPP_FLAGS := $(F_CPU) $(F_COM) $(F_MCU) $(F_CPP) $(F_OPT)
C_FLAGS   := $(F_CPU) $(F_COM) $(F_MCU) $(F_C)   $(F_OPT)
S_FLAGS   := $(F_CPU) $(F_COM) $(F_MCU) $(F_S)
LD_FLAGS  := $(F_LD)

