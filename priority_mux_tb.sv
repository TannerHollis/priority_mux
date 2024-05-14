`timescale 1ns / 1ps

module tb_priority_mux;

    // Parameters matching the DUT
    parameter N_PRIORITY_WIDTH = 3;
    parameter N_SIGNAL_WIDTH = 8;
    parameter N_SIGNALS = 8;

    // Signals to connect to the DUT
    reg clk;
    reg rst;
    reg [N_PRIORITY_WIDTH * N_SIGNALS - 1: 0] priorities_in;
    reg [N_SIGNAL_WIDTH * N_SIGNALS - 1: 0] signals_in;
    wire [N_SIGNAL_WIDTH - 1 : 0] signal_out;
    reg [N_SIGNALS - 1 : 0] signal_req;
    wire [N_SIGNALS - 1 : 0] signal_ack;
    wire busy;

    // Instantiate the DUT
    priority_mux #(
        .N_PRIORITY_WIDTH(N_PRIORITY_WIDTH),
        .N_SIGNAL_WIDTH(N_SIGNAL_WIDTH),
        .N_SIGNALS(N_SIGNALS)
    ) uut (
        .clk(clk),
        .rst(rst),
        .priorities_in(priorities_in),
        .signals_in(signals_in),
        .signal_out(signal_out),
        .signal_req(signal_req),
        .signal_ack(signal_ack),
        .busy(busy)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100 MHz clock
    end

    // Stimulus and checking
    initial begin
        // Initialize inputs
        rst = 1;
        priorities_in = 0;
        signals_in = 0;
        signal_req = 0;

        // Reset the DUT
        #10;
        rst = 0;
        #10;
        rst = 1;

        // Apply test vectors
        signal_req = 8'b1111_1111;  // Request all signals
		priorities_in = {3'd0, 3'd1, 3'd1, 3'd6, 3'd6, 3'd0, 3'd0, 3'd7}; // Random priorities
		signals_in = {8'd10, 8'd20, 8'd30, 8'd40, 8'd40, 8'd40, 8'd40, 8'd40}; // Random signal values

        // Wait for the DUT to process
        #100;
        
        // Display outputs
        $display("Signal Out: %d, Signal Ack: %b, Busy: %b", signal_out, signal_ack, busy);

        // Finish the simulation
        $finish;
    end
  
    initial begin
      $dumpfile("dump.vcd");
      $dumpvars(1);
      $dumpvars(0, uut);
    end

endmodule