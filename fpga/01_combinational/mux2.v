// mux2.v — 2:1 Multiplexer
//
// A mux is signal routing: one control line picks which of two inputs
// reaches the output. You've done this with relays and diode switching
// matrices. Verilog just lets you describe the same thing in text.
//
// This file has two implementations of the same function so you can
// see both abstraction levels Verilog offers for combinational logic.

// ============================================================
// Implementation 1: Behavioral (continuous assignment)
// ============================================================
//
// `module` declares a hardware block — think of it as a chip package.
// The name after `module` is the part number. The port list is the
// pinout. Every signal crossing the boundary must be declared here.

module mux2 (
    input  wire a,    // data input 0
    input  wire b,    // data input 1
    input  wire sel,  // select line: 0 picks a, 1 picks b
    output wire y     // output
);
    // `wire` means a physical connection — copper, nothing more.
    // Inputs are always wires. Outputs default to wire too, but
    // being explicit is good practice.

    // `assign` creates a continuous connection. It's not an instruction
    // that "runs" — it's a description of how signals are wired.
    // The ternary operator works exactly like the C version:
    //   condition ? value_if_true : value_if_false
    //
    // This single line maps directly to one 3-input LUT on the FPGA.
    // The LUT is programmed with the mux truth table and evaluated
    // every time any input changes. There is no clock involved.

    assign y = sel ? b : a;

endmodule


// ============================================================
// Implementation 2: Gate-level (structural)
// ============================================================
//
// Same function built from primitive gates. This is closer to how
// you'd draw it on a schematic: two AND gates feeding an OR gate,
// with an inverter on the select line for one path.
//
//        +-----+
// a -----|     |
//    +---|AND  |---+
//    |   +-----+   |   +----+
//    |             +---|    |
//   NOT(sel)       |   | OR |--- y
//    |             +---|    |
//    |   +-----+   |   +----+
//    +---|     |---+
// b -----|AND  |
//        +-----+
//    sel--^
//
// Verilog has built-in primitives: and, or, not, nand, nor, xor, xnor.
// The first argument is always the output; the rest are inputs.

module mux2_gates (
    input  wire a,
    input  wire b,
    input  wire sel,
    output wire y
);
    // Internal wires — like traces on a PCB connecting one gate's
    // output to another gate's input. These don't leave the module.
    wire sel_n;     // inverted select
    wire a_path;    // a AND (NOT sel)
    wire b_path;    // b AND sel

    not u1 (sel_n, sel);        // sel_n = ~sel
    and u2 (a_path, a, sel_n); // a_path = a & ~sel
    and u3 (b_path, b, sel);   // b_path = b & sel
    or  u4 (y, a_path, b_path); // y = a_path | b_path

    // The gate-level version is four primitives. The behavioral
    // version is one line. Both synthesize to the same hardware.
    // Use behavioral unless you have a specific reason not to.

endmodule
