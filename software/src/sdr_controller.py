#!/usr/bin/env python3
"""
SDR Controller Module
Provides interface to embedded SDR control system via serial/USB
"""

import serial
import time
import struct
from enum import Enum
from typing import Optional, Callable


class SDRCommand(Enum):
    """SDR command enumeration"""
    SET_FREQUENCY = 0x01
    SET_SAMPLE_COUNT = 0x02
    SET_DECIMATION = 0x03
    ENABLE_ADC = 0x04
    ENABLE_DAC = 0x05
    ENABLE_DDC = 0x06
    ENABLE_FILTER = 0x07
    GET_STATUS = 0x08
    GET_ERROR = 0x09
    START = 0x0A
    STOP = 0x0B
    RESET = 0x0C
    READ_DATA = 0x0D
    WRITE_DATA = 0x0E


class SDRError(Enum):
    """SDR error codes"""
    OK = 0x00
    SPI_ERROR = 0x01
    TIMEOUT = 0x02
    INVALID_PARAM = 0x03
    HARDWARE_ERROR = 0x04


class SDRController:
    """SDR Controller class for communicating with embedded system"""
    
    def __init__(self, port: str = '/dev/ttyUSB0', baudrate: int = 115200):
        """
        Initialize SDR Controller
        
        Args:
            port: Serial port path
            baudrate: Communication baud rate
        """
        self.port = port
        self.baudrate = baudrate
        self.serial_conn: Optional[serial.Serial] = None
        self.data_callback: Optional[Callable] = None
        self.error_callback: Optional[Callable] = None
        self.running = False
        
    def connect(self) -> bool:
        """
        Connect to SDR embedded system
        
        Returns:
            True if connection successful, False otherwise
        """
        try:
            self.serial_conn = serial.Serial(
                port=self.port,
                baudrate=self.baudrate,
                timeout=1.0
            )
            time.sleep(0.1)  # Wait for connection to stabilize
            return True
        except serial.SerialException as e:
            print(f"Failed to connect to {self.port}: {e}")
            return False
    
    def disconnect(self) -> None:
        """Disconnect from SDR embedded system"""
        if self.serial_conn and self.serial_conn.is_open:
            self.serial_conn.close()
            self.serial_conn = None
    
    def _send_command(self, command: SDRCommand, data: bytes = b'') -> bool:
        """
        Send command to SDR system
        
        Args:
            command: Command to send
            data: Command data
            
        Returns:
            True if command sent successfully
        """
        if not self.serial_conn or not self.serial_conn.is_open:
            print("Not connected to SDR system")
            return False
        
        try:
            # Send command byte
            self.serial_conn.write(bytes([command.value]))
            # Send data length
            self.serial_conn.write(struct.pack('<H', len(data)))
            # Send data
            if data:
                self.serial_conn.write(data)
            
            return True
        except serial.SerialException as e:
            print(f"Failed to send command: {e}")
            return False
    
    def _read_response(self) -> tuple[SDRError, bytes]:
        """
        Read response from SDR system
        
        Returns:
            Tuple of (error code, response data)
        """
        if not self.serial_conn or not self.serial_conn.is_open:
            return SDRError.HARDWARE_ERROR, b''
        
        try:
            # Read error code
            error_byte = self.serial_conn.read(1)
            if not error_byte:
                return SDRError.TIMEOUT, b''
            
            error = SDRError(error_byte[0])
            
            # Read data length
            length_bytes = self.serial_conn.read(2)
            if len(length_bytes) != 2:
                return error, b''
            
            length = struct.unpack('<H', length_bytes)[0]
            
            # Read data
            if length > 0:
                data = self.serial_conn.read(length)
                if len(data) != length:
                    return error, b''
                return error, data
            
            return error, b''
            
        except serial.SerialException as e:
            print(f"Failed to read response: {e}")
            return SDRError.HARDWARE_ERROR, b''
    
    def set_frequency(self, freq_hz: int) -> bool:
        """
        Set SDR frequency
        
        Args:
            freq_hz: Frequency in Hz
            
        Returns:
            True if successful
        """
        data = struct.pack('<I', freq_hz)
        if self._send_command(SDRCommand.SET_FREQUENCY, data):
            error, _ = self._read_response()
            return error == SDRError.OK
        return False
    
    def set_sample_count(self, count: int) -> bool:
        """
        Set sample count
        
        Args:
            count: Number of samples
            
        Returns:
            True if successful
        """
        data = struct.pack('<I', count)
        if self._send_command(SDRCommand.SET_SAMPLE_COUNT, data):
            error, _ = self._read_response()
            return error == SDRError.OK
        return False
    
    def set_decimation(self, decimation: int) -> bool:
        """
        Set decimation factor
        
        Args:
            decimation: Decimation factor
            
        Returns:
            True if successful
        """
        data = struct.pack('<I', decimation)
        if self._send_command(SDRCommand.SET_DECIMATION, data):
            error, _ = self._read_response()
            return error == SDRError.OK
        return False
    
    def enable_adc(self, enable: bool) -> bool:
        """
        Enable/disable ADC
        
        Args:
            enable: True to enable, False to disable
            
        Returns:
            True if successful
        """
        data = struct.pack('<?', enable)
        if self._send_command(SDRCommand.ENABLE_ADC, data):
            error, _ = self._read_response()
            return error == SDRError.OK
        return False
    
    def enable_dac(self, enable: bool) -> bool:
        """
        Enable/disable DAC
        
        Args:
            enable: True to enable, False to disable
            
        Returns:
            True if successful
        """
        data = struct.pack('<?', enable)
        if self._send_command(SDRCommand.ENABLE_DAC, data):
            error, _ = self._read_response()
            return error == SDRError.OK
        return False
    
    def enable_ddc(self, enable: bool) -> bool:
        """
        Enable/disable DDC
        
        Args:
            enable: True to enable, False to disable
            
        Returns:
            True if successful
        """
        data = struct.pack('<?', enable)
        if self._send_command(SDRCommand.ENABLE_DDC, data):
            error, _ = self._read_response()
            return error == SDRError.OK
        return False
    
    def enable_filter(self, enable: bool) -> bool:
        """
        Enable/disable filter
        
        Args:
            enable: True to enable, False to disable
            
        Returns:
            True if successful
        """
        data = struct.pack('<?', enable)
        if self._send_command(SDRCommand.ENABLE_FILTER, data):
            error, _ = self._read_response()
            return error == SDRError.OK
        return False
    
    def get_status(self) -> tuple[bool, int]:
        """
        Get SDR status
        
        Returns:
            Tuple of (success, status register)
        """
        if self._send_command(SDRCommand.GET_STATUS):
            error, data = self._read_response()
            if error == SDRError.OK and len(data) == 4:
                status = struct.unpack('<I', data)[0]
                return True, status
        return False, 0
    
    def get_error(self) -> tuple[bool, int]:
        """
        Get SDR error register
        
        Returns:
            Tuple of (success, error register)
        """
        if self._send_command(SDRCommand.GET_ERROR):
            error, data = self._read_response()
            if error == SDRError.OK and len(data) == 4:
                error_reg = struct.unpack('<I', data)[0]
                return True, error_reg
        return False, 0
    
    def start(self) -> bool:
        """
        Start SDR system
        
        Returns:
            True if successful
        """
        if self._send_command(SDRCommand.START):
            error, _ = self._read_response()
            return error == SDRError.OK
        return False
    
    def stop(self) -> bool:
        """
        Stop SDR system
        
        Returns:
            True if successful
        """
        if self._send_command(SDRCommand.STOP):
            error, _ = self._read_response()
            return error == SDRError.OK
        return False
    
    def reset(self) -> bool:
        """
        Reset SDR system
        
        Returns:
            True if successful
        """
        if self._send_command(SDRCommand.RESET):
            error, _ = self._read_response()
            return error == SDRError.OK
        return False
    
    def read_data(self, length: int) -> tuple[bool, bytes]:
        """
        Read data from SDR system
        
        Args:
            length: Number of bytes to read
            
        Returns:
            Tuple of (success, data)
        """
        data = struct.pack('<I', length)
        if self._send_command(SDRCommand.READ_DATA, data):
            error, response = self._read_response()
            if error == SDRError.OK:
                return True, response
        return False, b''
    
    def write_data(self, data: bytes) -> bool:
        """
        Write data to SDR system
        
        Args:
            data: Data to write
            
        Returns:
            True if successful
        """
        length = struct.pack('<I', len(data))
        full_data = length + data
        if self._send_command(SDRCommand.WRITE_DATA, full_data):
            error, _ = self._read_response()
            return error == SDRError.OK
        return False
    
    def set_data_callback(self, callback: Callable) -> None:
        """
        Set callback for received data
        
        Args:
            callback: Function to call when data is received
        """
        self.data_callback = callback
    
    def set_error_callback(self, callback: Callable) -> None:
        """
        Set callback for errors
        
        Args:
            callback: Function to call when error occurs
        """
        self.error_callback = callback
    
    def start_data_stream(self) -> None:
        """Start continuous data streaming"""
        self.running = True
        while self.running:
            success, data = self.read_data(1024)
            if success and self.data_callback:
                self.data_callback(data)
            time.sleep(0.01)
    
    def stop_data_stream(self) -> None:
        """Stop continuous data streaming"""
        self.running = False
