#!/usr/bin/env python3

import serial
import wave
import time
import argparse
import os

# --- Settings ---
CHUNK_SIZE = 1024  # bytes per chunk
UART_BAUD = 456000  # Match your FPGA's UART baud rate
AUDIO_RATE = 45600  # Must match FPGA sampling rate

# --- Argument Parsing ---
parser = argparse.ArgumentParser(description="Stream 8-bit mono WAV to FPGA over UART.")
parser.add_argument("filename", help="Input .wav file (8-bit mono, 45.6kHz)")
parser.add_argument("--port", default="/dev/ttyUSB1", help="Serial port (default: /dev/ttyUSB1)")
parser.add_argument("--loop", action="store_true", help="Loop playback")
args = parser.parse_args()

# --- Validate File ---
if not os.path.exists(args.filename):
    print(f"File {args.filename} not found.")
    exit(1)

wf = wave.open(args.filename, 'rb')
assert wf.getnchannels() == 1, "File must be mono."
assert wf.getsampwidth() == 1, "Must be 8-bit WAV."
assert wf.getframerate() == AUDIO_RATE, f"Must be {AUDIO_RATE} Hz."

# --- Open Serial ---
print(f"Opening {args.port} @ {UART_BAUD} baud...")
ser = serial.Serial(args.port, UART_BAUD)
time.sleep(1)  # optional pause for FPGA to be ready

# --- Streaming Loop ---
print("Streaming...")
try:
    while True:
        data = wf.readframes(CHUNK_SIZE)
        if not data:
            if args.loop:
                wf.rewind()
                continue
            else:
                break
        ser.write(data)
        time.sleep(len(data) / AUDIO_RATE)  # Pacing
except KeyboardInterrupt:
    print("Interrupted.")
finally:
    ser.close()
    wf.close()

