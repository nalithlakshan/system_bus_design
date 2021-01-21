module master_interface(clk,
                reset,
                addr,
                wdata,
                rdata,
                response,
                bus_req,
                grant,
                util,

                addr_from_master,
                write_addr_req_from_master,
                notify_ok_response_to_master,
                write_data_from_master,
                read_data_to_master,
                write_data_req_from_master,
                read_data_req_from_master,
                req_done_to_master,
                force_req_from_master,

                addr_en,
                wdata_en
);
//INPUTS &OUTPUTS:
// from and to the design
input clk;              // clock signal
input reset;            // reset signal
output addr;            //address bus
output wdata;           // data write bus
input rdata;            // data read bus
input [1:0] response;   // response bus from slave
output reg bus_req = 0; // request to arbiter
input grant;            // grant permission from arbiter
output reg util = 0;    // utilized flag of master
output reg addr_en = 0; // enable tristate buffer to addr bus
output reg wdata_en= 0; // enable tristate buffer to wdata bus

//from master module
input [15:0] addr_from_master; //address to write to addr bus
input write_addr_req_from_master;// address write request
output reg notify_ok_response_to_master = 0;
input [7:0] write_data_from_master;     // data to WDATA bus
output reg [7:0] read_data_to_master =0;// data from RDATA bus 
input write_data_req_from_master;       // data write command
input read_data_req_from_master;        // data read command
output reg req_done_to_master = 0;
input force_req_from_master;

// states of state machine
parameter  IDLE         = 4'b0000;
parameter REQUEST_BUS   = 4'b0001;
parameter SENDADDRESS   = 4'b0010; 
parameter READDATA      = 4'b0011;
parameter WRITEDATA     = 4'b0100;
parameter SPLIT         = 4'b0101; 
parameter WAIT_FOR_SPLIT= 4'b0110;
parameter CHECK_NEXT    = 4'b0111;
parameter CHECK_NEXT2   = 4'b1000;

//responses from slave
parameter OK = 2'b10, BUSY = 2'b01, DONE = 2'b11,  NCK = 2'b00;

//internal registers
reg [3:0] state              = IDLE;
reg [1:0] burst_check_cycles = 2;
reg [15:0] serial_slave_address;
reg [7:0] serial_slave_data;

//send values to address and data buses
assign addr  = serial_slave_address[15];
assign wdata = serial_slave_data[7];

//STATE MACHINE:
always @(posedge clk or negedge reset)
begin
    if(~reset) // reseting signals and registers
    begin
        state                <= IDLE;
        bus_req              <= 0;
        util                 <= 0;
        addr_en              <= 0;
        wdata_en             <= 0;
        notify_ok_response_to_master <= 0;
        read_data_to_master  <= 0;
        req_done_to_master   <= 0;
        serial_slave_address <= 0;
        serial_slave_data    <= 0;
        burst_check_cycles   <= 2;
    end
    else begin
        case(state)
            IDLE:begin // idle state
                util <= 0;
                addr_en <= 0;
                wdata_en <= 0;
                notify_ok_response_to_master <= 0;
                read_data_to_master  <= 0;
                serial_slave_address <= 0;
                serial_slave_data    <= 0;
                burst_check_cycles   <= 2;
                /*check for a request from master core to write an address*/
                if(write_addr_req_from_master) begin                                                     
                    state <= REQUEST_BUS;//go to next state if req received
                    req_done_to_master <= 1'b0;  
                end
            end
            
            REQUEST_BUS:begin //requesting bus from arbiter
                bus_req <= 1'b1;
                serial_slave_address <= addr_from_master;
                notify_ok_response_to_master <= 1'b1;
                if(grant)begin //if granted, go to next state
        		    state <= SENDADDRESS;
                    addr_en  <= 1;
                    wdata_en <= 1;
                    util     <= 1; //make utilized flag high
                    bus_req  <= 0;
        		end 
                else begin    //else wait in the same state
                    state <= REQUEST_BUS;        
                end 
            end

            SENDADDRESS:begin // sending address
                notify_ok_response_to_master <= 1'b0;

                //check for OK response from slave
                if(write_data_req_from_master && response == OK)
                begin
                    state <= WRITEDATA; // go to write data state
                    serial_slave_data <= write_data_from_master;
                end
                else if(read_data_req_from_master && response == OK) begin
                    state <= READDATA;  // go to read data state
                end
                else if(response == BUSY) begin //if slave BUSY
                    state    <= WAIT_FOR_SPLIT; //go to split state
                    serial_slave_data <= write_data_from_master; 
                    util     <= 1'b0; //release bus utilization
                    addr_en  <= 0;
                    wdata_en <= 0;
                end
                else begin
                    state <= SENDADDRESS;
                     //send the address serially
                    serial_slave_address[15:0] <= {serial_slave_address[14:0],1'b0};
                end  
            end

            READDATA:begin  //read data state
                if(response == DONE) begin //if slave completed sending data
                    state <= CHECK_NEXT;
                    req_done_to_master <= 1;//notify master core about completion
                end
                else begin
                    state <= READDATA;
                    //read data from data bus serially
                    read_data_to_master[7:0] <= {read_data_to_master[6:0],rdata};
                end
            end

            WRITEDATA:begin  //write data state
                if(response == DONE) begin //if slave responds completion          
                    state <= CHECK_NEXT;
                    req_done_to_master <= 1;//notify master core about completion                                
                end
                else begin
                    state <= WRITEDATA;
                    //write data to data bus serially                            
                    serial_slave_data[7:0] <= {serial_slave_data[6:0],1'b0};
                end
            end

            WAIT_FOR_SPLIT: begin //intermediate state to pass 1 clk cycle
                state <= SPLIT;
            end


            SPLIT:begin //split transaction state
                if(grant)begin //once grant is given back
                    util <= 1'b1; //make the util line high
                    addr_en  <= 1;
                    wdata_en <= 1;
                end
                //if OK response received and having a WRITE req, go to write state
                if(write_data_req_from_master && response == OK && grant) begin
                    state <= WRITEDATA;
                end
                //if OK response received and having a READ req, go to read state
                else if(read_data_req_from_master && response == OK && grant) begin
                    state <= READDATA;
                end
                else begin
                    state <= SPLIT;
                end
            end

            CHECK_NEXT: begin
                state <= CHECK_NEXT2;
                if(force_req_from_master == 1)begin
                    bus_req <= 1;
                end
            end

            CHECK_NEXT2: begin
                state <= IDLE;
                if(force_req_from_master == 1)begin
                    bus_req <= 1;
                end
            end

        endcase
    end
end
endmodule

