# Makefile for SDR Software Components

# Python settings
PYTHON = python3
PIP = pip3

# Directories
SRC_DIR = src
GUI_DIR = gui
BUILD_DIR = build
DIST_DIR = dist

# Source files
CONTROLLER_SRC = $(SRC_DIR)/sdr_controller.py
GUI_SRC = $(SRC_DIR)/sdr_gui.py

# Install requirements
requirements:
	$(PIP) install -r requirements.txt

# Run GUI application
gui: $(GUI_SRC)
	$(PYTHON) $(GUI_SRC)

# Run controller test
test: $(CONTROLLER_SRC)
	$(PYTHON) -c "from sdr_controller import SDRController; print('Controller import successful')"

# Create distribution
dist:
	$(PYTHON) -m build

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR) $(DIST_DIR)
	rm -rf __pycache__ $(SRC_DIR)/__pycache__
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -delete

# Install system-wide (requires sudo)
install:
	$(PIP) install .

# Uninstall
uninstall:
	$(PIP) uninstall sdr-software

# Help
help:
	@echo "SDR Software Build System"
	@echo "======================="
	@echo "Available targets:"
	@echo "  requirements - Install Python dependencies"
	@echo "  gui          - Run GUI application"
	@echo "  test         - Test controller import"
	@echo "  dist         - Create distribution package"
	@echo "  clean        - Clean build artifacts"
	@echo "  install      - Install system-wide"
	@echo "  uninstall    - Uninstall"
	@echo "  help         - Show this help message"

.PHONY: requirements gui test dist clean install uninstall help
