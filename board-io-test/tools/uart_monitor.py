"""
Simple UART monitor for the Arty A7 IO test (alternative to PuTTY).

Setup (one time):   pip install pyserial
Run:                python uart_monitor.py

It auto-detects the board's COM port, shows everything the FPGA sends,
and forwards anything you type (each key is echoed back by the FPGA).
Press Ctrl+C to quit.
"""

import sys

try:
    import serial
    from serial.tools import list_ports
except ImportError:
    sys.exit("pyserial is not installed. Run:  pip install pyserial")

BAUD = 115200


def find_port():
    ports = list(list_ports.comports())
    if not ports:
        sys.exit("No COM ports found. Is the board plugged in via USB?")
    # The Arty's FTDI chip usually shows up as "USB Serial Port"
    for p in ports:
        if "FTDI" in (p.manufacturer or "") or "USB Serial" in (p.description or ""):
            return p.device
    print("Could not auto-detect the board. Available ports:")
    for i, p in enumerate(ports):
        print(f"  [{i}] {p.device} - {p.description}")
    choice = input("Pick a number: ")
    return ports[int(choice)].device


def main():
    port = find_port()
    print(f"Opening {port} @ {BAUD} baud. Ctrl+C to quit.")
    print("Flip switches / press buttons on the board, or type here.\n")

    with serial.Serial(port, BAUD, timeout=0.1) as ser:
        try:
            import msvcrt  # Windows keyboard polling
            while True:
                data = ser.read(64)
                if data:
                    sys.stdout.write(data.decode(errors="replace"))
                    sys.stdout.flush()
                while msvcrt.kbhit():
                    ch = msvcrt.getch()
                    if ch in (b"\x03",):  # Ctrl+C
                        raise KeyboardInterrupt
                    ser.write(ch)
        except KeyboardInterrupt:
            print("\nBye!")


if __name__ == "__main__":
    main()
