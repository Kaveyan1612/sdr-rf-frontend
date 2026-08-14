#!/usr/bin/env python3
"""
SDR GUI Application
Provides graphical interface for SDR control and data visualization
"""

import sys
import numpy as np
from PyQt5.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, 
                             QHBoxLayout, QPushButton, QLabel, QLineEdit, 
                             QSpinBox, QCheckBox, QGroupBox, QTabWidget,
                             QTextEdit, QProgressBar, QMessageBox)
from PyQt5.QtCore import QTimer, Qt
from PyQt5.QtGui import QFont
import matplotlib.pyplot as plt
from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg as FigureCanvas
from matplotlib.figure import Figure

from sdr_controller import SDRController, SDRCommand, SDRError


class SDRPlotCanvas(FigureCanvas):
    """Matplotlib canvas for SDR data visualization"""
    
    def __init__(self, parent=None, width=5, height=4, dpi=100):
        self.fig = Figure(figsize=(width, height), dpi=dpi)
        self.axes = self.fig.add_subplot(111)
        super(SDRPlotCanvas, self).__init__(self.fig)
        self.setParent(parent)
        
    def plot_spectrum(self, frequencies, magnitude):
        """Plot frequency spectrum"""
        self.axes.clear()
        self.axes.plot(frequencies, magnitude)
        self.axes.set_xlabel('Frequency (Hz)')
        self.axes.set_ylabel('Magnitude (dB)')
        self.axes.set_title('Frequency Spectrum')
        self.axes.grid(True)
        self.draw()
    
    def plot_time_domain(self, time, data):
        """Plot time domain signal"""
        self.axes.clear()
        self.axes.plot(time, data)
        self.axes.set_xlabel('Time (s)')
        self.axes.set_ylabel('Amplitude')
        self.axes.set_title('Time Domain Signal')
        self.axes.grid(True)
        self.draw()
    
    def plot_waterfall(self, spectrogram):
        """Plot waterfall spectrogram"""
        self.axes.clear()
        self.axes.imshow(spectrogram, aspect='auto', cmap='viridis')
        self.axes.set_xlabel('Frequency Bin')
        self.axes.set_ylabel('Time')
        self.axes.set_title('Waterfall Spectrogram')
        self.draw()


class SDRControlPanel(QWidget):
    """Control panel for SDR configuration"""
    
    def __init__(self, controller: SDRController):
        super().__init__()
        self.controller = controller
        self.init_ui()
        
    def init_ui(self):
        """Initialize UI components"""
        layout = QVBoxLayout()
        
        # Connection settings
        conn_group = QGroupBox("Connection Settings")
        conn_layout = QHBoxLayout()
        
        self.port_edit = QLineEdit("/dev/ttyUSB0")
        self.port_edit.setPlaceholderText("Serial Port")
        
        self.baud_spin = QSpinBox()
        self.baud_spin.setRange(9600, 3000000)
        self.baud_spin.setValue(115200)
        
        self.connect_btn = QPushButton("Connect")
        self.connect_btn.clicked.connect(self.toggle_connection)
        
        conn_layout.addWidget(QLabel("Port:"))
        conn_layout.addWidget(self.port_edit)
        conn_layout.addWidget(QLabel("Baud:"))
        conn_layout.addWidget(self.baud_spin)
        conn_layout.addWidget(self.connect_btn)
        conn_group.setLayout(conn_layout)
        
        # Frequency control
        freq_group = QGroupBox("Frequency Control")
        freq_layout = QVBoxLayout()
        
        freq_input_layout = QHBoxLayout()
        self.freq_edit = QLineEdit("1000000")
        self.freq_edit.setPlaceholderText("Frequency (Hz)")
        self.set_freq_btn = QPushButton("Set Frequency")
        self.set_freq_btn.clicked.connect(self.set_frequency)
        
        freq_input_layout.addWidget(self.freq_edit)
        freq_input_layout.addWidget(self.set_freq_btn)
        
        freq_layout.addLayout(freq_input_layout)
        freq_group.setLayout(freq_layout)
        
        # Sample control
        sample_group = QGroupBox("Sample Control")
        sample_layout = QVBoxLayout()
        
        sample_input_layout = QHBoxLayout()
        self.sample_spin = QSpinBox()
        self.sample_spin.setRange(1, 65536)
        self.sample_spin.setValue(1024)
        self.set_sample_btn = QPushButton("Set Sample Count")
        self.set_sample_btn.clicked.connect(self.set_sample_count)
        
        sample_input_layout.addWidget(QLabel("Count:"))
        sample_input_layout.addWidget(self.sample_spin)
        sample_input_layout.addWidget(self.set_sample_btn)
        
        decim_input_layout = QHBoxLayout()
        self.decim_spin = QSpinBox()
        self.decim_spin.setRange(1, 256)
        self.decim_spin.setValue(16)
        self.set_decim_btn = QPushButton("Set Decimation")
        self.set_decim_btn.clicked.connect(self.set_decimation)
        
        decim_input_layout.addWidget(QLabel("Decimation:"))
        decim_input_layout.addWidget(self.decim_spin)
        decim_input_layout.addWidget(self.set_decim_btn)
        
        sample_layout.addLayout(sample_input_layout)
        sample_layout.addLayout(decim_input_layout)
        sample_group.setLayout(sample_layout)
        
        # Component control
        comp_group = QGroupBox("Component Control")
        comp_layout = QVBoxLayout()
        
        self.adc_check = QCheckBox("Enable ADC")
        self.adc_check.stateChanged.connect(self.toggle_adc)
        
        self.dac_check = QCheckBox("Enable DAC")
        self.dac_check.stateChanged.connect(self.toggle_dac)
        
        self.ddc_check = QCheckBox("Enable DDC")
        self.ddc_check.stateChanged.connect(self.toggle_ddc)
        
        self.filter_check = QCheckBox("Enable Filter")
        self.filter_check.stateChanged.connect(self.toggle_filter)
        
        comp_layout.addWidget(self.adc_check)
        comp_layout.addWidget(self.dac_check)
        comp_layout.addWidget(self.ddc_check)
        comp_layout.addWidget(self.filter_check)
        comp_group.setLayout(comp_layout)
        
        # System control
        sys_group = QGroupBox("System Control")
        sys_layout = QHBoxLayout()
        
        self.start_btn = QPushButton("Start")
        self.start_btn.clicked.connect(self.start_system)
        
        self.stop_btn = QPushButton("Stop")
        self.stop_btn.clicked.connect(self.stop_system)
        
        self.reset_btn = QPushButton("Reset")
        self.reset_btn.clicked.connect(self.reset_system)
        
        sys_layout.addWidget(self.start_btn)
        sys_layout.addWidget(self.stop_btn)
        sys_layout.addWidget(self.reset_btn)
        sys_group.setLayout(sys_layout)
        
        # Status display
        status_group = QGroupBox("Status")
        status_layout = QVBoxLayout()
        
        self.status_text = QTextEdit()
        self.status_text.setReadOnly(True)
        self.status_text.setMaximumHeight(100)
        
        status_layout.addWidget(self.status_text)
        status_group.setLayout(status_layout)
        
        # Add all groups to main layout
        layout.addWidget(conn_group)
        layout.addWidget(freq_group)
        layout.addWidget(sample_group)
        layout.addWidget(comp_group)
        layout.addWidget(sys_group)
        layout.addWidget(status_group)
        
        self.setLayout(layout)
    
    def toggle_connection(self):
        """Toggle connection to SDR system"""
        if self.connect_btn.text() == "Connect":
            port = self.port_edit.text()
            baud = self.baud_spin.value()
            
            if self.controller.connect():
                self.connect_btn.setText("Disconnect")
                self.log_message(f"Connected to {port} at {baud} baud")
            else:
                self.log_message("Failed to connect")
        else:
            self.controller.disconnect()
            self.connect_btn.setText("Connect")
            self.log_message("Disconnected")
    
    def set_frequency(self):
        """Set SDR frequency"""
        try:
            freq = int(self.freq_edit.text())
            if self.controller.set_frequency(freq):
                self.log_message(f"Frequency set to {freq} Hz")
            else:
                self.log_message("Failed to set frequency")
        except ValueError:
            self.log_message("Invalid frequency value")
    
    def set_sample_count(self):
        """Set sample count"""
        count = self.sample_spin.value()
        if self.controller.set_sample_count(count):
            self.log_message(f"Sample count set to {count}")
        else:
            self.log_message("Failed to set sample count")
    
    def set_decimation(self):
        """Set decimation factor"""
        decim = self.decim_spin.value()
        if self.controller.set_decimation(decim):
            self.log_message(f"Decimation set to {decim}")
        else:
            self.log_message("Failed to set decimation")
    
    def toggle_adc(self, state):
        """Toggle ADC enable"""
        enabled = (state == Qt.Checked)
        if self.controller.enable_adc(enabled):
            self.log_message(f"ADC {'enabled' if enabled else 'disabled'}")
        else:
            self.log_message("Failed to toggle ADC")
    
    def toggle_dac(self, state):
        """Toggle DAC enable"""
        enabled = (state == Qt.Checked)
        if self.controller.enable_dac(enabled):
            self.log_message(f"DAC {'enabled' if enabled else 'disabled'}")
        else:
            self.log_message("Failed to toggle DAC")
    
    def toggle_ddc(self, state):
        """Toggle DDC enable"""
        enabled = (state == Qt.Checked)
        if self.controller.enable_ddc(enabled):
            self.log_message(f"DDC {'enabled' if enabled else 'disabled'}")
        else:
            self.log_message("Failed to toggle DDC")
    
    def toggle_filter(self, state):
        """Toggle Filter enable"""
        enabled = (state == Qt.Checked)
        if self.controller.enable_filter(enabled):
            self.log_message(f"Filter {'enabled' if enabled else 'disabled'}")
        else:
            self.log_message("Failed to toggle Filter")
    
    def start_system(self):
        """Start SDR system"""
        if self.controller.start():
            self.log_message("SDR system started")
        else:
            self.log_message("Failed to start SDR system")
    
    def stop_system(self):
        """Stop SDR system"""
        if self.controller.stop():
            self.log_message("SDR system stopped")
        else:
            self.log_message("Failed to stop SDR system")
    
    def reset_system(self):
        """Reset SDR system"""
        if self.controller.reset():
            self.log_message("SDR system reset")
        else:
            self.log_message("Failed to reset SDR system")
    
    def log_message(self, message):
        """Log message to status display"""
        self.status_text.append(message)
        self.status_text.verticalScrollBar().setValue(
            self.status_text.verticalScrollBar().maximum()
        )


class SDRMainWindow(QMainWindow):
    """Main SDR application window"""
    
    def __init__(self):
        super().__init__()
        self.controller = SDRController()
        self.init_ui()
        
        # Timer for status updates
        self.status_timer = QTimer()
        self.status_timer.timeout.connect(self.update_status)
        self.status_timer.start(1000)  # Update every second
        
    def init_ui(self):
        """Initialize UI"""
        self.setWindowTitle("SDR Control Application")
        self.setGeometry(100, 100, 1200, 800)
        
        # Central widget
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        
        # Main layout
        main_layout = QHBoxLayout()
        
        # Control panel
        self.control_panel = SDRControlPanel(self.controller)
        self.control_panel.setMaximumWidth(400)
        
        # Plot area
        plot_tabs = QTabWidget()
        
        # Spectrum plot
        self.spectrum_canvas = SDRPlotCanvas(self, width=8, height=6)
        plot_tabs.addTab(self.spectrum_canvas, "Spectrum")
        
        # Time domain plot
        self.time_canvas = SDRPlotCanvas(self, width=8, height=6)
        plot_tabs.addTab(self.time_canvas, "Time Domain")
        
        # Waterfall plot
        self.waterfall_canvas = SDRPlotCanvas(self, width=8, height=6)
        plot_tabs.addTab(self.waterfall_canvas, "Waterfall")
        
        # Add widgets to main layout
        main_layout.addWidget(self.control_panel)
        main_layout.addWidget(plot_tabs)
        
        central_widget.setLayout(main_layout)
        
        # Menu bar
        self.create_menu()
        
        # Status bar
        self.statusBar().showMessage("Ready")
    
    def create_menu(self):
        """Create menu bar"""
        menubar = self.menuBar()
        
        # File menu
        file_menu = menubar.addMenu('File')
        
        exit_action = file_menu.addAction('Exit')
        exit_action.triggered.connect(self.close)
        
        # View menu
        view_menu = menubar.addMenu('View')
        
        # Help menu
        help_menu = menubar.addMenu('Help')
        
        about_action = help_menu.addAction('About')
        about_action.triggered.connect(self.show_about)
    
    def update_status(self):
        """Update status display"""
        if self.controller.serial_conn and self.controller.serial_conn.is_open:
            success, status = self.controller.get_status()
            if success:
                self.statusBar().showMessage(f"Status: 0x{status:08X}")
            
            success, error = self.controller.get_error()
            if success and error != 0:
                self.control_panel.log_message(f"Error: 0x{error:08X}")
    
    def show_about(self):
        """Show about dialog"""
        QMessageBox.about(self, "About SDR Control",
                          "SDR Control Application\n"
                          "Software-Defined Radio with FPGA RF Front-end\n"
                          "Version 1.0")
    
    def closeEvent(self, event):
        """Handle close event"""
        if self.controller.serial_conn and self.controller.serial_conn.is_open:
            self.controller.disconnect()
        event.accept()


def main():
    """Main function"""
    app = QApplication(sys.argv)
    
    # Set application style
    app.setStyle('Fusion')
    
    # Create and show main window
    window = SDRMainWindow()
    window.show()
    
    sys.exit(app.exec_())


if __name__ == '__main__':
    main()
