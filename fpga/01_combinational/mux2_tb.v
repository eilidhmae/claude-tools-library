// mux2_tb.v — Testbench for the 2:1 multiplexer
//
// A testbench is NOT hardware. It's simulation scaffolding — the
// Verilog equivalent of hooking up a signal generator and logic
// analyser to your circuit on the bench. None of this synthesizes
// to gates. The simulator executes it as software.
//
// Run with Icarus Verilog:
//   iverilog -o mux2_test mux2.v mux2_tb.v && vvp mux2_test

// `timescale sets the simulation time units and precision.
// 1ns/1ps means delays are in nanoseconds, resolved to picoseconds.
// Only matters in simulation — the synthesizer ignores it.
`timescale 1ns / 1ps

module mux2_tb;

    // --------------------------------------------------------
    // Signal declarations
    // --------------------------------------------------------
    // `reg` means the testbench drives this signal procedurally
    // (from an initial/always block). It does NOT mean "register"
    // or "flip-flop" here — that's a common early confusion.
    // In testbenches, reg just means "I assign this in procedural code."

    reg a, b, sel;

    // `wire` for signals driven by the module under test.
    // The DUT's output port drives these — we just observe.
    wire y_behavioral;
    wire y_gates;

    // --------------------------------------------------------
    // Instantiate both implementations
    // --------------------------------------------------------
    // This is like plugging two chips into a breadboard and wiring
    // the same inputs to both, so you can compare their outputs.
    // .port_name(signal_name) connects the module's port to our signal.

    mux2 uut_behav (
        .a   (a),
        .b   (b),
        .sel (sel),
        .y   (y_behavioral)
    );

    mux2_gates uut_gates (
        .a   (a),
        .b   (b),
        .sel (sel),
        .y   (y_gates)
    );

    // --------------------------------------------------------
    // Test sequence
    // --------------------------------------------------------
    // `initial` runs once at simulation start. It's procedural code
    // that executes top-to-bottom, like a script. This is the core
    // reason testbenches don't synthesize — real hardware has no
    // concept of "do this, then wait, then do that."

    initial begin
        // $display works like printf. Format codes:
        //   %b = binary, %d = decimal, %t = current sim time
        // $monitor is similar but re-triggers automatically when
        // any listed signal changes — handy, but $display in a
        // loop gives you more control.

        $display("=== 2:1 Mux Truth Table ===");
        $display("sel  a  b | y(beh) y(gate) | expected");
        $display("---------|-----------------|--------");

        // Exhaustive test: 3 inputs = 8 combinations.
        // We drive every combination and check both implementations.

        // #10 means "wait 10 time units (nanoseconds) before
        // continuing." This gives the combinational logic time to
        // settle in simulation. Real propagation delay is sub-ns
        // in an FPGA, but the simulator needs discrete time steps.

        sel = 0; a = 0; b = 0; #10;
        check_and_display(0);  // sel=0 picks a, a=0 -> y=0

        sel = 0; a = 0; b = 1; #10;
        check_and_display(0);  // sel=0 picks a, a=0 -> y=0

        sel = 0; a = 1; b = 0; #10;
        check_and_display(1);  // sel=0 picks a, a=1 -> y=1

        sel = 0; a = 1; b = 1; #10;
        check_and_display(1);  // sel=0 picks a, a=1 -> y=1

        sel = 1; a = 0; b = 0; #10;
        check_and_display(0);  // sel=1 picks b, b=0 -> y=0

        sel = 1; a = 0; b = 1; #10;
        check_and_display(1);  // sel=1 picks b, b=1 -> y=1

        sel = 1; a = 1; b = 0; #10;
        check_and_display(0);  // sel=1 picks b, b=0 -> y=0

        sel = 1; a = 1; b = 1; #10;
        check_and_display(1);  // sel=1 picks b, b=1 -> y=1

        $display("---------|-----------------|---------");
        $display("All 8 input combinations tested.");

        // $finish terminates the simulation. Without it, some
        // simulators hang waiting for more events.
        $finish;
    end

    // --------------------------------------------------------
    // Helper task: display one row and check correctness
    // --------------------------------------------------------
    // A `task` is a reusable block of procedural code. Like initial
    // blocks, tasks are simulation-only — no hardware equivalent.

    task check_and_display(input expected);
        begin
            $display("  %b   %b  %b |   %b       %b     |    %b     %s",
                     sel, a, b,
                     y_behavioral, y_gates, expected,
                     (y_behavioral === expected && y_gates === expected)
                         ? "OK" : "FAIL");

            // Sanity check: both implementations must agree and
            // match the expected value. If not, flag it.
            if (y_behavioral !== expected || y_gates !== expected) begin
                $display("ERROR: mismatch at sel=%b a=%b b=%b", sel, a, b);
            end
        end
    endtask

endmodule
