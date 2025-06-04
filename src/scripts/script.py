import serial
import wave
import time
import argparse
import os

# --- Settings ---
CHUNK_SIZE = 1024  # bytes per chunk
UART_BAUD = 143000 # 230400
AUDIO_RATE = 14000  # must match FPGA setting

# --- Argument Parsing ---
parser = argparse.ArgumentParser(description="Stream 8-bit mono WAV to FPGA over UART.")
parser.add_argument("filename", help="Input .wav file (8-bit mono, 14kHz)")
parser.add_argument("--port", default="COM4", help="Serial port (default: COM4)")
parser.add_argument("--loop", action="store_true", help="Loop playback")
args = parser.parse_args()

# --- Validate File ---
if not os.path.exists(args.filename):
    print(f"File {args.filename} not found.")
    exit(1)

wf = wave.open(args.filename, 'rb')
assert wf.getnchannels() == 1, "File must be mono."
assert wf.getsampwidth() == 1, "Must be 8-bit WAV."
assert wf.getframerate() == AUDIO_RATE, f"Must be {AUDIO_RATE}Hz."

# --- Open Serial ---
print(f"Opening {args.port} @ {UART_BAUD} baud...")
ser = serial.Serial(args.port, UART_BAUD)
time.sleep(1)  # wait for FPGA to reset if needed

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

        # Pacing using actual elapsed time
        expected_duration = len(data) / AUDIO_RATE
        time.sleep(expected_duration)
except KeyboardInterrupt:
    print("Interrupted.")
finally:
    ser.close()
    wf.close()
