#!/usr/bin/env python3
"""
Scripted hardware test for the UART command interface (docs/UART_CONTROL.md).

Usage:  python util/uart_command_test.py [COMx]
Needs:  pip install pyserial. Board programmed with the demo, no terminal
        program holding the COM port open.

Sends each command, verifies the echoed acknowledgement, prints PASS/FAIL —
paste the output into docs/BRINGUP_TEST_REPORT.md.
"""

import sys
import time

try:
    import serial
    from serial.tools import list_ports
except ImportError:
    sys.exit("pyserial is not installed. Run:  pip install pyserial")

BAUD = 115200

COMMANDS = [
    (b"3", "pattern 3 (alternating)"),
    (b"b", "RGB force blue"),
    (b"f", "speed fast"),
    (b"2", "pattern 2 (nibble flip)"),
    (b"r", "RGB force red"),
    (b"a", "RGB auto-cycle"),
    (b"m", "speed medium"),
    (b"K", "plain echo of non-command byte"),
]


def find_port():
    if len(sys.argv) > 1:
        return sys.argv[1]
    for p in list_ports.comports():
        if "FTDI" in (p.manufacturer or "") or "USB Serial" in (p.description or ""):
            return p.device
    sys.exit("Could not auto-detect the board's COM port; pass it explicitly.")


def drain(ser, seconds):
    end = time.time() + seconds
    buf = b""
    while time.time() < end:
        buf += ser.read(64)
    return buf


def main():
    port = find_port()
    try:
        ser = serial.Serial(port, BAUD, timeout=0.5)
    except Exception as exc:
        sys.exit(f"cannot open {port} (terminal program still running?): {exc}")

    print(f"--- listening on {port} for the heartbeat/banner (3 s):")
    print(drain(ser, 3).decode(errors="replace"))

    all_ok = True
    for cmd, desc in COMMANDS:
        ser.reset_input_buffer()
        ser.write(cmd)
        time.sleep(0.3)
        rx = drain(ser, 0.7)
        ok = cmd in rx
        all_ok &= ok
        status = "PASS" if ok else "FAIL"
        print(f"{status}: '{cmd.decode()}' ({desc}) acked={'yes' if ok else 'NO'}")

    # leave the board in the default state
    ser.write(b"1")
    time.sleep(0.2)
    ser.write(b"a")
    ser.close()

    print("overall:", "ALL PASS" if all_ok else "FAILURES PRESENT")
    sys.exit(0 if all_ok else 1)


if __name__ == "__main__":
    main()
