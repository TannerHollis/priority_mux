`timescale 1ns/1ps

module priority_tb;
  
  /* Define test clock */
  reg clk;
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  /* Define reset */
  reg rst;
  initial begin
    rst = 1;
    #10 rst = 0;
    #25 rst = 1;
    #1000 finish();
  end
  
  /* Define priority I/O */
  reg priority_in
  
  priority_mux 
  	#(
      .N_PRIORITY_WIDTH(2),
      .N_SIGNAL_WIDTH(8),
      .N_SIGNALS(4)
    )
  	priority_mux0
  	(
      .clk(clk),
      .rst(rst)
      
    );
  
endmodule