module system_bus_tb;

//Only input variables from tb to the design are clock and reset
reg clk    = 0;
reg reset  = 0;

//asynchronous reset with a 2-flop sychronizer  
reg reset_release_ff1 = 0;
reg reset_release_ff2 = 0;
wire reset_with_synchronous_release;
assign reset_with_synchronous_release = reset_release_ff2 && reset;

always @(posedge clk)begin
	reset_release_ff1 <= reset;
	reset_release_ff2 <= reset_release_ff1;
end

//Initially the design is in reset state
initial begin
	clk = 0;
	#25 reset = 1; //Releasing the initial reset
	#10281 reset = 0; //Reset test in the middle
	#28 reset = 1; //Releasing reset in the reset test
end

//Clock signal generation
always #10 clk = ~clk; 

//System Bus Instantiation
system_bus sb(
    .clk   (clk),
    .reset (reset_with_synchronous_release)
);

endmodule