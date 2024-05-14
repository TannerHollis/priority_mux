module priority_mux
  #(
    parameter N_PRIORITY_WIDTH = 2,
    parameter N_SIGNAL_WIDTH = 8,
    parameter N_SIGNALS = 4
  )
  (
    input clk,
    input rst,
    input [N_PRIORITY_WIDTH * N_SIGNALS - 1: 0] priorities_in,
    input [N_SIGNAL_WIDTH * N_SIGNALS - 1: 0] signals_in,
    output [N_SIGNAL_WIDTH - 1 : 0] signal_out,
    input [N_SIGNALS - 1 : 0] signal_req,
    output reg [N_SIGNALS - 1 : 0] signal_ack,
    output busy
  );

  /* Define what operand to use for comparison */
  `define OPERAND <=

  /* Define number of stages required */
  localparam N_STAGES = $clog2(N_SIGNALS);
  localparam MIN_PRIORITY = 2**N_PRIORITY_WIDTH - 1;

  /* Define signals variable for readability */
  wire [N_SIGNAL_WIDTH - 1 : 0] signals_w [N_SIGNALS - 1 : 0];
  wire [N_PRIORITY_WIDTH - 1 : 0] priorities_w [N_SIGNALS - 1 : 0];

  /* Define stages of comparisons */
  reg [N_PRIORITY_WIDTH - 1 : 0] p_compares_q [N_SIGNALS - 2 : 0]; // N_SIGNALS - 1 registers, stores the relevant input signal
  reg [N_STAGES - 1 : 0] p_selections_q [N_SIGNALS - 2 : 0]; // N_SIGNALS - 1 registers, stores the best priority resultant

  genvar stage, i;
  generate
    for(stage = 0; stage < N_STAGES; stage = stage + 1) begin : stage_inst
      for(i = 0; i < (N_SIGNALS / (2 ** (stage + 1))); i = i + 1) begin : compare_inst
        localparam index = i * 2; // Calculated outside procedural blocks
        if(stage == 0) begin
          always @(posedge clk) begin
            if (!rst) begin
              p_compares_q[i] <= MIN_PRIORITY;
              p_selections_q[i] <= 0;
            end else begin
              if (|signal_req[index + 1 : index]) begin
                p_compares_q[i] <= (priorities_w[index] `OPERAND priorities_w[index + 1]) ? priorities_w[index] : priorities_w[index + 1];
                p_selections_q[i] <= (priorities_w[index] `OPERAND priorities_w[index + 1]) ? index : (index + 1);
              end
            end
          end
        end else begin
          localparam j_0 = N_SIGNALS - N_SIGNALS / (2 ** (stage - 1));
          localparam j_1 = N_SIGNALS - N_SIGNALS / (2 ** (stage));
          always @(posedge clk) begin
            if (!rst) begin
              p_compares_q[j_1 + i] <= MIN_PRIORITY;
              p_selections_q[j_1 + i] <= 0;
            end else begin
              p_compares_q[j_1 + i] <= (p_compares_q[j_0 + index] `OPERAND p_compares_q[j_0 + index + 1]) ? p_compares_q[j_0 + index] : p_compares_q[j_0 + index + 1];
              p_selections_q[j_1 + i] <= (p_compares_q[j_0 + index] `OPERAND p_compares_q[j_0 + index + 1]) ? p_selections_q[j_0 + index] : p_selections_q[j_0 + index + 1];
            end
          end
        end
      end
    end
  endgenerate

  /* Assign signals_w wire */
  genvar j;
  generate
    for(j = 0; j < N_SIGNALS; j = j + 1) begin : signal_inst
      assign signals_w[j] = signals_in[(j + 1) * N_SIGNAL_WIDTH - 1 : j * N_SIGNAL_WIDTH];
      assign priorities_w[j] = signal_req[j] ? priorities_in[(j + 1) * N_PRIORITY_WIDTH - 1 : j * N_PRIORITY_WIDTH] : MIN_PRIORITY;
    end
  endgenerate

  /* Define states for state machine */
  localparam [1 : 0] STATE_IDLE = 0,
  STATE_WAIT = 1,
  STATE_DONE = 2;
  reg [1 : 0] state;

  /* Define stage counter for wait operation */
  localparam N_CNT_WIDTH = $clog2(N_STAGES);
  reg [N_CNT_WIDTH - 1 : 0] cnt_stage;
  reg [N_STAGES - 1 : 0] final_selection;

  /* Define state machine logic */
  always @ (posedge clk) begin
    if(!rst) begin
      signal_ack <= 0;
      final_selection <= 0;
      cnt_stage <= 0;
      state <= STATE_IDLE;
    end 
    else begin
      case (state)
        STATE_IDLE : begin
          if(|signal_req) begin
            cnt_stage <= 0;
            state <= STATE_WAIT;
          end
        end

        STATE_WAIT : begin
          if(cnt_stage == N_STAGES - 1) begin
            signal_ack <= 1 << p_selections_q[N_SIGNALS - 2]; // Records indicies of selection at each stage
            final_selection <= p_selections_q[N_SIGNALS - 2]; // Records priorities at each stage
            state <= STATE_DONE;
          end 
          else begin
            cnt_stage <= cnt_stage + 1;
          end
        end

        STATE_DONE : begin
          signal_ack <= 0;
          state <= STATE_IDLE;
        end
      endcase
    end
  end
    
  assign signal_out = signals_w[final_selection];
  assign busy = state != STATE_IDLE;
    
endmodule