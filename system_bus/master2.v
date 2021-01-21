module master2(
input      clk,
input      reset,
input      from_arb_grant,
output     to_arb_req_bus,
output     to_arb_bus_util,
output tri to_addr_bus,
output tri to_wdata_bus,
input      from_rdata_bus,
input [1:0]from_response_bus
);

wire mibufin_addr;
wire mibufin_wdata;
wire mibufin_addr_en;
wire mibufin_wdata_en;

//Connection Wires
wire [15:0] mmi_addr;
wire        mmi_write_addr_req;
wire  [7:0] mmi_write_data;
wire        mmi_write_data_req;
wire        mmi_read_data_req;
wire        mmi_ok_response;
wire  [7:0] mmi_read_data;
wire        mmi_req_done;
wire        mmi_force_req;

bufif1  b_addr(to_addr_bus, mibufin_addr, mibufin_addr_en);
bufif1  b_wdata(to_wdata_bus, mibufin_wdata, mibufin_wdata_en);

master2_core mc2(
    .clk                         (clk),
    .reset                       (reset),
    .addr_to_mi                  (mmi_addr),
    .write_addr_req_to_mi        (mmi_write_addr_req),
    .write_data_to_mi            (mmi_write_data),
    .write_data_req_to_mi        (mmi_write_data_req),
    .read_data_req_to_mi         (mmi_read_data_req),
    .ok_response_from_mi         (mmi_ok_response),
    .read_data_from_mi           (mmi_read_data),
    .req_done_from_mi            (mmi_req_done),
    .force_req_to_mi             (mmi_force_req)
);

master_interface mi2(
    .clk                         (clk),
    .reset                       (reset),
    .addr                        (mibufin_addr),
    .wdata                       (mibufin_wdata),
    .rdata                       (from_rdata_bus),
    .response                    (from_response_bus),
    .bus_req                         (to_arb_req_bus),
    .grant                       (from_arb_grant),
    .util                        (to_arb_bus_util),

    .addr_from_master            (mmi_addr),
    .write_addr_req_from_master  (mmi_write_addr_req),
    .notify_ok_response_to_master(mmi_ok_response),
    .write_data_from_master      (mmi_write_data),
    .read_data_to_master         (mmi_read_data),
    .write_data_req_from_master  (mmi_write_data_req),
    .read_data_req_from_master   (mmi_read_data_req),
    .req_done_to_master          (mmi_req_done),
    .force_req_from_master       (mmi_force_req),

    .addr_en                     (mibufin_addr_en),
    .wdata_en                    (mibufin_wdata_en)
);

endmodule