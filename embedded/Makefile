# Makefile for SDR Embedded Control Application

# Cross-compiler for ARM (adjust for your platform)
CROSS_COMPILE = arm-linux-gnueabihf-
CC = $(CROSS_COMPILE)gcc
LD = $(CROSS_COMPILE)ld
OBJCOPY = $(CROSS_COMPILE)objcopy

# Project name
PROJECT = sdr_control

# Directories
SRC_DIR = src
INC_DIR = inc
BUILD_DIR = build
BIN_DIR = bin

# Source files
SOURCES = $(SRC_DIR)/sdr_control.c $(SRC_DIR)/main.c
OBJECTS = $(BUILD_DIR)/sdr_control.o $(BUILD_DIR)/main.o

# Compiler flags
CFLAGS = -Wall -Wextra -O2 -I$(INC_DIR)
LDFLAGS = -lm

# Default target
all: $(BIN_DIR)/$(PROJECT)

# Create directories
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

# Compile source files
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

# Link executable
$(BIN_DIR)/$(PROJECT): $(OBJECTS) | $(BIN_DIR)
	$(CC) $(OBJECTS) $(LDFLAGS) -o $@

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR) $(BIN_DIR)

# Install (copy to target location)
install: $(BIN_DIR)/$(PROJECT)
	@echo "Install command depends on your target system"
	@echo "For embedded systems, use appropriate flashing method"

# Phony targets
.PHONY: all clean install

# Dependencies
$(BUILD_DIR)/sdr_control.o: $(SRC_DIR)/sdr_control.c $(INC_DIR)/sdr_control.h
$(BUILD_DIR)/main.o: $(SRC_DIR)/main.c $(INC_DIR)/sdr_control.h
