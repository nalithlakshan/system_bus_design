module syncRAM( dataIn,
                dataOut,
                Addr, 
                Wr_en, 
                Clk,
                reset
);

   
// parameters for the width 
parameter ADR   = 12;
parameter DAT   = 8;
parameter DPTH  = 4096;

//ports
input      [DAT-1:0]  dataIn;
output reg [DAT-1:0]  dataOut;
input      [ADR-1:0]  Addr;
input                 Wr_en, Clk, reset;
      
//internal variables
integer i;
reg [DAT-1:0] SRAM [DPTH-1:0];

always @ (posedge Clk or negedge reset)
begin
  if(~reset)begin
      for (i=0; i<DPTH; i=i+1) SRAM[i] <= 0;
  end
  else begin
      if (Wr_en == 1'b1 ) begin
       SRAM [Addr] <= dataIn;
      end

      else  begin
       dataOut <= SRAM [Addr]; 
      end
  end
end

endmodule
