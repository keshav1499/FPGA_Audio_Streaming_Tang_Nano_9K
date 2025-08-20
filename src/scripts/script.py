#!/usr/bin/env python3

import serial
import wave
import time
import argparse
import os
import struct

# --- Settings ---
CHUNK_SAMPLES = 512  # Samples per chunk (each sample = 2 bytes)
UART_BAUD = 882000   # Match your FPGA UART receiver baud 882000

//Baud rate calculation= sampling rate x Resolution
AUDIO_RATE = 44100   # Must match FPGA playback rate 44100
VOLUME = 0.5         # Volume control (0.0 to 1.0)

# --- Argument Parsing ---
parser = argparse.ArgumentParser(description="Stream 16-bit mono WAV to FPGA over UART (LSB first).")
parser.add_argument("filename", help="Input .wav file (16-bit mono, 44.1kHz)")
parser.add_argument("--port", default="/dev/ttyUSB1", help="Serial port (default: /dev/ttyUSB1)")
parser.add_argument("--loop", action="store_true", help="Loop playback")
args = parser.parse_args()

# --- Validate File ---
if not os.path.exists(args.filename):
    print(f"File {args.filename} not found.")
    exit(1)

wf = wave.open(args.filename, 'rb')
assert wf.getnchannels() == 1, "File must be mono."
assert wf.getsampwidth() == 2, "Must be 16-bit WAV."
assert wf.getframerate() == AUDIO_RATE, f"Must be {AUDIO_RATE} Hz."

# --- Open Serial ---
print(f"Opening {args.port} @ {UART_BAUD} baud...")
ser = serial.Serial(args.port, UART_BAUD)
time.sleep(1)

# --- Fixed-point volume scale factor ---
scale = int(VOLUME * 256)

# --- Streaming Loop ---
print("Streaming...")
try:
    while True:
        frames = wf.readframes(CHUNK_SAMPLES)
        if not frames:
            if args.loop:
                wf.rewind()
                continue
            else:
                break

        # Apply fixed-point volume control with rounding and convert to LSB-first
        lsb_first = bytearray()
        for i in range(0, len(frames), 2):
            sample = struct.unpack_from('<h', frames, i)[0]  # Little-endian 16-bit signed
            scaled_sample = (sample * scale + 128) >> 8       # Fixed-point scaling with rounding
            scaled_sample = max(min(scaled_sample, 32767), -32768)  # Clamp
            lsb_first += struct.pack('<h', scaled_sample)

        ser.write(lsb_first)
except KeyboardInterrupt:
    print("Interrupted.")
finally:
    ser.close()
    wf.close()

