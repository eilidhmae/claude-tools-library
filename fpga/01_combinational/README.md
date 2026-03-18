# 01: Combinational Logic — The 2:1 Mux

## Verilog is not a programming language

Verilog describes hardware. When you write `assign y = sel ? b : a;` you're
not telling a processor to evaluate a conditional — you're specifying that
wires are connected through a multiplexer. The synthesizer reads your
description and configures transistors (in an FPGA, LUT contents) to match it.

The code doesn't "run." It "exists."

## Modules and ports

A `module` is a self-contained block of hardware with a defined interface —
exactly like an IC with labeled pins. The port list is the pinout:

```verilog
module mux2 (
    input  wire a,
    input  wire b,
    input  wire sel,
    output wire y
);
```

You can instantiate a module the same way you place a chip on a board and
connect its pins to nets. Hierarchy works the same way: a module can contain
instances of other modules, just like a PCB contains ICs.

## Continuous assignment vs procedural

**Continuous assignment** (`assign`) describes combinational wiring. The
right-hand side is evaluated whenever any input changes. There is no clock,
no trigger — it's a direct function of inputs to outputs. Use this for
combinational logic.

**Procedural blocks** (`always @(...)`, `initial`) describe behaviour over
time. `always @(posedge clk)` models a flip-flop — it only updates on clock
edges. `initial` runs once at time zero and is simulation-only.

Rule of thumb for now: combinational logic uses `assign`. Sequential logic
(registers, state machines) uses `always`. We'll get to sequential in a
later lesson.

## How a mux maps to an FPGA

An FPGA's basic logic element is the **lookup table (LUT)** — a small SRAM
that stores a truth table. On most architectures (Lattice iCE40, Xilinx 7,
Intel Cyclone), the smallest LUT has 4-6 inputs.

A 2:1 mux has 3 inputs (a, b, sel) and 1 output. Its truth table has 8
entries — fits trivially in even a 4-input LUT with room to spare. The
synthesizer computes the truth table from your Verilog and programs it into
the LUT's SRAM. At runtime the LUT is purely combinational: inputs go in,
output comes out, no clock required.

When you write `assign y = sel ? b : a;`, exactly one LUT gets configured.
That's the entire implementation. One line of Verilog, one physical resource.

## The key mental shift: everything runs at once

In software, statements execute sequentially. In hardware, all continuous
assignments and all module instances operate **simultaneously**. There is no
instruction pointer stepping through your code.

If you write:

```verilog
assign x = a & b;
assign y = x | c;
```

Both of those exist as hardware at the same time. When `a` changes, `x`
updates, and because `x` changed, `y` updates — all within the same
propagation delay window. This is not two instructions. It's two gates
wired in series.

When you're reading Verilog, don't think "first this line runs, then that
line." Think "these are all circuits sitting on a board, all live, all
reacting to their inputs right now."

## Running the testbench

```
iverilog -o mux2_test mux2.v mux2_tb.v && vvp mux2_test
```

This compiles both files and runs the simulation. You'll see the truth table
printed with pass/fail for every input combination.

## Files

| File | Purpose |
|------|---------|
| `mux2.v` | Two implementations: behavioral (assign/ternary) and gate-level (primitives) |
| `mux2_tb.v` | Exhaustive testbench — drives all 8 input combos, checks both implementations |
