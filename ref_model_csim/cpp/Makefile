#
#  Copyright (c) 2025 CEA*
#  *Commissariat a l'Energie Atomique et aux Energies Alternatives (CEA)
#
#  SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
#
#  Licensed under the Solderpad Hardware License v 2.1 (the “License”); you
#  may not use this file except in compliance with the License, or, at your
#  option, the Apache License version 2.0. You may obtain a copy of the
#  License at
#
#  https://solderpad.org/licenses/SHL-2.1/
#
#  Unless required by applicable law or agreed to in writing, any work
#  distributed under the License is distributed on an “AS IS” BASIS, WITHOUT
#  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#  License for the specific language governing permissions and limitations
#  under the License.
#
#
#  Authors       : Ihsane TAHIR
#  Creation Date : March, 2025
#  Description   : Makefile to generate C shared library of reference model
#  History       :
#

RM           = rm -f
CXX          = g++

SRC_DIR      = src
INC_DIR      = include
BUILD_DIR    = build

INCDIR_MPFR  = $(MPFR_DIR)/include
LIBDIR_MPFR  = $(MPFR_DIR)/lib

INCDIR_GMP   = $(GMP_DIR)/include
LIBDIR_GMP   = $(GMP_DIR)/lib

INCDIRS      = $(addprefix -I,. $(QUESTA_PATH)/include $(INCDIR_MPFR) $(INCDIR_GMP) $(INCDIR_SOFTFLOAT) $(INC_DIR))
LIBDIRS      = $(addprefix -L,$(LIBDIR_MPFR) $(LIBDIR_GMP) $(LIBDIR_SOFTFLOAT))
LIBDIRS     += -Wl,-rpath,$(LIBDIR_MPFR)
LIBDIRS     += -Wl,-rpath,$(LIBDIR_GMP)
LIBDIRS     += -Wl,-rpath,$(LIBDIR_SOFTFLOAT)

CXXFLAGS     = -std=c++11 -fPIC -Wall $(INCDIRS)
LDFLAGS      = -m64 -shared -fPIC -Bsymbolic $(LIBDIRS)
LIBS         = -lm -lgmp -lmpfr
TARGET_LIB   = $(BUILD_DIR)/refmodel_csim_lib.so

# Automatically find all sources in cpp/src
SRCS := $(wildcard $(SRC_DIR)/*.cpp)
OBJS := $(patsubst $(SRC_DIR)/%.cpp,$(BUILD_DIR)/%.o,$(SRCS))
DEPS := $(OBJS:.o=.d)

.PHONY: all clean

all: $(TARGET_LIB)

$(TARGET_LIB): $(OBJS)
	@echo "Linking shared object: $@"
	$(CXX) $(LDFLAGS) -o $@ $^ $(LIBS)

# Compile each source into build/ directory (ensure build dir exists first)
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.cpp | $(BUILD_DIR)
	@echo "Compiling: $<"
	$(CXX) $(CXXFLAGS) -c $< -o $@

# Generate dependency files (also in build dir)
$(BUILD_DIR)/%.d: $(SRC_DIR)/%.cpp | $(BUILD_DIR)
	@echo "Generating dependencies for: $<"
	$(CXX) -MM $(CXXFLAGS) $< > $@

# Create build directory if missing
$(BUILD_DIR):
	@echo "Creating build directory: $(BUILD_DIR)"
	mkdir -p $(BUILD_DIR)

-include $(DEPS)

clean:
	@echo "Cleaning..."
	-${RM} $(TARGET_LIB)
	-${RM} -r $(BUILD_DIR)
