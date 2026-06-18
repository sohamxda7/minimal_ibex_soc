# AGENTS.md

## Cursor Cloud specific instructions

This repo is the **Ibex Demo System**, an example RISC-V SoC. The hardware-free
development loop is: build the software (C and/or Rust), build a **Verilator**
simulation model of the SoC via **FuseSoC**, then run the simulator with a
software image. FPGA synthesis (Vivado) and on-board debug (OpenOCD/GDB over
JTAG) require Xilinx Vivado and physical hardware and are **not** available in
this environment.

### Toolchains already installed in the VM image (not in the update script)

These are part of the VM snapshot, so the update script does not reinstall them:

- RISC-V GCC toolchain `riscv32-unknown-elf-*` at `/tools/riscv/bin`.
- Verilator `4.210` at `/tools/verilator/v4.210/bin` (the lowRISC-pinned version;
  do **not** rely on the newer apt Verilator 5.x for the FuseSoC sim).
- apt packages: `srecord` (provides `srec_cat`, required by the C CMake build to
  emit `.vmem`), `clang-format`, plus `libelf-dev`/`zlib1g-dev` used by the sim.
- Rust nightly is managed automatically by `rustup` via `sw/rust/rust-toolchain.toml`
  on first `cargo` invocation (uses `build-std`, target `riscv32imc-unknown-none-elf`).

`~/.bashrc` already prepends `/tools/riscv/bin` and `/tools/verilator/v4.210/bin`
to `PATH`, so new interactive shells see the toolchains automatically.

### Python environment (refreshed by the update script)

Python deps (lowRISC forks of **FuseSoC** and **edalize**) live in a venv at
`.venv` (gitignored). The update script creates/refreshes it from
`python-requirements.txt`. Activate it before running FuseSoC:

```sh
source .venv/bin/activate
```

### Build / run cheat sheet

Standard commands live in `README.md`; the non-obvious essentials:

```sh
# 1. Build C software (needs srec_cat on PATH; produces ELF + blank.vmem)
mkdir -p sw/c/build && cd sw/c/build && cmake .. && make -j"$(nproc)" && cd -

# 2. Build the Verilator sim model (needs .venv active + verilator on PATH)
fusesoc --cores-root=. run --target=sim --tool=verilator --setup --build lowrisc:ibex:demo_system

# 3. Run the sim with a software image (runs until Ctrl-C; UART -> uart0.log)
./build/lowrisc_ibex_demo_system_0/sim-verilator/Vtop_verilator \
  --meminit=ram,./sw/c/build/demo/hello_world/demo

# Rust software
cd sw/rust && cargo build --release
```

Gotchas:

- The Verilator simulation **does not self-terminate**; it runs forever and must
  be stopped (e.g. `timeout 30 ...` or Ctrl-C). Program output appears on a UART
  pseudo-terminal and is mirrored to `uart0.log` in the working directory.
- FuseSoC prints `verible-verilog-syntax ... No such file or directory` and falls
  back to a regex parser. This is harmless — Verible is only used for primitive
  selection/linting and is not required to build the sim.

### Lint / test

There are no unit-test suites; CI (`.github/workflows/`) only lint+builds:

- C lint: `cd sw/c && find . -name '*.c' -o -name '*.h' | xargs clang-format -n`
  (reports style deviations; CI does not fail on them).
- Rust lint: `cd sw/rust && cargo fmt --check`.
