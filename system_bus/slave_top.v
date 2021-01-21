module slave_top(

	input wire clock50,
	input wire reset,
	input wire address_bus,
	input wire w_data_bus,
	output tri r_data_bus,
	output tri [1:0] response_bus,
	output wire [1:0] split_request,
	input wire [1:0] granted_master,
	input wire [1:0] slave_address
);
//-----------WIRES-----------//
wire [7:0]q;
wire [11:0]ram_address;
wire [7:0]ram_data;
wire wr_en;
wire 		sibufin_r_data_bus;
wire [1:0]	sibufin_response_bus;
wire 		sibufin_en;

//-----Trisate Buffers for RDATA,RESPONSE bus-----//
bufif1  buf_r_data_bus(r_data_bus, sibufin_r_data_bus, sibufin_en);
bufif1  buf_response_bus1(response_bus[1], sibufin_response_bus[1], sibufin_en);
bufif1  buf_response_bus0(response_bus[0], sibufin_response_bus[0], sibufin_en);

//----------SLAVE_INTERFACE INSTANTIATION----//
slave_interface SLAVE(
	.clk  				(clock50), 
	.reset  			(reset), 
	.addr  				(address_bus), 
	.w_data  			(w_data_bus),
	.r_data 			(sibufin_r_data_bus), 
	.response 			(sibufin_response_bus), 
	.split_request 		(split_request), 
	.slave_address 		(slave_address), 
	.granted_master 	(granted_master),
	.q 					(q),
	.ram_address 		(ram_address), 
	.ram_data 			(ram_data), 
	.wr_en 				(wr_en),
	.slave_en           (sibufin_en)
);

//---------RAM_INSTANCE-------//
syncRAM RAM_BASIC(
	.dataOut 			(q),
	.dataIn 			(ram_data),
	.Clk 				(clock50),
	.Addr 				(ram_address),
	.Wr_en 				(wr_en),
	.reset 				(reset)
);
endmodule 