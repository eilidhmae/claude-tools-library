# FPGA Fundamentals — Curriculum

## Progress

- [x] **01 — Combinational Logic** (`01_combinational/`)
- [ ] **02 — Sequential Logic** (`02_sequential/`)
- [ ] **03 — Finite State Machines** (`03_fsm/`)
- [ ] **04 — Modules & Hierarchy** (`04_hierarchy/`)
- [ ] **05 — Timing & Clocks** (`05_timing/`)
- [ ] **06 — Practical Projects** (`06_projects/`)

---

## Bookmark

**Last completed:** Lesson 01 — Combinational Logic
**Resume at:** Lesson 02 — Sequential Logic (clocks, flip-flops, registers, counters)

---

## Lesson Summaries

### 01 — Combinational Logic
*Directory:* `01_combinational/`

**Covered:**
- Verilog as hardware description, not a program
- `module` / ports = chip with labeled pins
- `assign` = continuous wiring (combinational)
- `always @(posedge clk)` = sequential (next lesson)
- `wire` vs `reg` — physical connection vs testbench-driven signal
- Gate-level primitives (`and`, `or`, `not`) vs behavioral (`assign` with ternary)
- How a 2:1 mux maps to a single 3-input LUT on an FPGA
- Testbench fundamentals: `initial`, `#delay`, `$display`, `$finish`
- Both implementations simulated and verified — all 8 input combinations pass

**Files:**
| File | Purpose |
|------|---------|
| `mux2.v` | 2:1 mux — behavioral and gate-level implementations |
| `mux2_tb.v` | Exhaustive testbench with truth table output |
| `README.md` | Lesson notes and concepts |

**Sim command:** `iverilog -o mux2_test mux2.v mux2_tb.v && vvp mux2_test`

### 02 — Sequential Logic *(next)*
Clocks, flip-flops, registers, counters. The circuit gains memory.

### 03 — Finite State Machines
Control logic — the backbone of protocol handling and sequencing.

### 04 — Modules & Hierarchy
Composing larger designs from smaller, reusable modules.

### 05 — Timing & Clocks
Clock domains, setup/hold times, why FPGAs care about propagation delay.

### 06 — Practical Projects
UART, SPI, LED blinker — real-world interfaces.

---

## Environment

- **Simulator:** Icarus Verilog 11.0 (`iverilog` / `vvp`)
- **Branch:** `fpga`
- **Working dir:** `/home/eilidh/src/claude-tools-library/fpga/`
