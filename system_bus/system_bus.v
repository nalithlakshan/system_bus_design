module system_bus(
	input clk,
	input reset
);

//Connection wires with arbiter
wire  [1:0]   GRANT;
wire  [1:0]   BUSREQ;
wire  [1:0]   UTIL;
wire  [5:0]   GMASTER;
wire  [5:0]   SPLIT;


//Connection wires of the BUS
wire      rdata_bus;
wire [1:0]response_bus;
wire      addr_bus;
wire      wdata_bus;

//Slave addresses
reg [1:0] slave1_addr = 2'b01;
reg [1:0] slave2_addr = 2'b10;
reg [1:0] slave3_addr = 2'b11;

//arbter instantiation
arbiter a(
    .clk                           (clk),
    .reset                         (reset),
    .req_from_master               (BUSREQ),
    .bus_utilization               (UTIL),
    .grant_to_master               (GRANT),
    .notify_granted_master_to_slave(GMASTER),
    .split_req_from_slave          (SPLIT)
);

//master1 instantiation
master1 m1(
    .clk              (clk),
    .reset            (reset),
    .from_arb_grant   (GRANT[1]),
    .to_arb_req_bus   (BUSREQ[1]),
    .to_arb_bus_util  (UTIL[1]),
    .to_addr_bus      (addr_bus),
    .to_wdata_bus     (wdata_bus),
    .from_rdata_bus   (rdata_bus),
    .from_response_bus(response_bus)
);

//master2 instantiation
master2 m2(
    .clk              (clk),
    .reset            (reset),
    .from_arb_grant   (GRANT[0]),
    .to_arb_req_bus   (BUSREQ[0]),
    .to_arb_bus_util  (UTIL[0]),
    .to_addr_bus      (addr_bus),
    .to_wdata_bus     (wdata_bus),
    .from_rdata_bus   (rdata_bus),
    .from_response_bus(response_bus)
);

//slave1 instantiation
slave_top s1(
    .clock50       (clk),
    .reset         (reset),
    .address_bus   (addr_bus),
    .w_data_bus    (wdata_bus),
    .r_data_bus    (rdata_bus),
    .response_bus  (response_bus),
    .split_request (SPLIT[5:4]),
    .granted_master(GMASTER[5:4]),
    .slave_address (slave1_addr)
);

//slave2 instantiation
slave_top s2(
    .clock50       (clk),
    .reset         (reset),
    .address_bus   (addr_bus),
    .w_data_bus    (wdata_bus),
    .r_data_bus    (rdata_bus),
    .response_bus  (response_bus),
    .split_request (SPLIT[3:2]),
    .granted_master(GMASTER[3:2]),
    .slave_address (slave2_addr)
);

//slave3 instantiation
slave_top s3(
    .clock50       (clk),
    .reset         (reset),
    .address_bus   (addr_bus),
    .w_data_bus    (wdata_bus),
    .r_data_bus    (rdata_bus),
    .response_bus  (response_bus),
    .split_request (SPLIT[1:0]),
    .granted_master(GMASTER[1:0]),
    .slave_address (slave3_addr)
);

endmodule