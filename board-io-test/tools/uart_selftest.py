"""
Automated UART self-test for the Arty A7 IO test design.

Usage:  python uart_selftest.py [COMx]
        (port is auto-detected if omitted)

What it does:
  1. Opens the board's serial port at 115200.
  2. Asks you to flip any slide switch, and verifies a well-formed
     "SW=xxxx BTN=xxxx" status message arrives.
  3. Sends a set of test characters and verifies each is echoed back.
  4. Prints a PASS/FAIL summary block you can paste into the test report.
"""

import re
import sys
import time

try:
    import serial
    from serial.tools import list_ports
except ImportError:
    sys.exit("pyserial is not installed. Run:  pip install pyserial")

BAUD = 115200
STATUS_RE = re.compile(rb"SW=[01]{4} BTN=[01]{4}")


def find_port():
    if len(sys.argv) > 1:
        return sys.argv[1]
    for p in list_ports.comports():
        if "FTDI" in (p.manufacturer or "") or "USB Serial" in (p.description or ""):
            return p.device
    sys.exit("Could not auto-detect the board's COM port. "
             "Pass it explicitly:  python uart_selftest.py COM4")


def main():
    port = find_port()
    results = {}
    print(f"Opening {port} @ {BAUD}...")

    with serial.Serial(port, BAUD, timeout=0.2) as ser:
        ser.reset_input_buffer()

        # --- Test A: status message on switch change (needs a human) -----
        print("\n>>> Flip any slide switch on the board now (15 s window)...")
        deadline = time.time() + 15
        captured = b""
        while time.time() < deadline:
            captured += ser.read(64)
            if STATUS_RE.search(captured):
                break
        m = STATUS_RE.search(captured)
        results["status message (FPGA->PC)"] = bool(m)
        if m:
            print(f"    got: {m.group().decode()}")
        else:
            print("    no status message seen!")

        # --- Test B: echo (fully automatic) ------------------------------
        time.sleep(0.5)
        ser.reset_input_buffer()
        test_bytes = b"Uz5~\x00\xff"          # varied bit patterns
        ok = 0
        for b in test_bytes:
            ser.write(bytes([b]))
            rx = ser.read(1)
            if rx == bytes([b]):
                ok += 1
            else:
                print(f"    echo mismatch: sent {b:#04x}, got {rx!r}")
            time.sleep(0.05)
        results[f"echo (PC->FPGA->PC), {len(test_bytes)} bytes"] = ok == len(test_bytes)
        print(f"    echoed correctly: {ok}/{len(test_bytes)}")

    # --- Summary ----------------------------------------------------------
    print("\n===== UART SELF-TEST SUMMARY (paste into report) =====")
    print(f"port: {port}, baud: {BAUD}, time: {time.strftime('%Y-%m-%d %H:%M:%S')}")
    all_ok = True
    for name, passed in results.items():
        print(f"  {'PASS' if passed else 'FAIL'}  {name}")
        all_ok &= passed
    print(f"overall: {'PASS' if all_ok else 'FAIL'}")
    print("======================================================")
    sys.exit(0 if all_ok else 1)


if __name__ == "__main__":
    main()
