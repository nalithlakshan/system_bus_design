module master1_core (
    input clk,
    input reset,

    //connections with the ports of master interface to the the master side
    //NOTE : mi - master interface
    output reg [15:0]addr_to_mi,
    output reg write_addr_req_to_mi = 0,
    output reg [7:0]write_data_to_mi,
    output reg write_data_req_to_mi = 0,
    output reg read_data_req_to_mi  = 0,
    output reg force_req_to_mi = 0,
    input ok_response_from_mi,
    input [7:0]read_data_from_mi,
    input req_done_from_mi
);

//Address Parameters
parameter STARTBIT = 1'b1;
parameter SLAVE1 = 2'b01, SLAVE2 = 2'b10, SLAVE3 = 2'b11;
parameter WRITE = 1'b1, READ = 1'b0; 

/*_____________________________________________________________________________________
| -------------------------------------------------------------------------------------|
|EXECUTION:
|Flow of execution of master 1 is a predefined set of read, write tasks and idle times.
|Flow starts from WRITE1 and ends with WRITE2 below, but we can customize any sequence.
|Below sequence has the following order,

|         INITIAL_IDLE -> WRITE1 -> READ1 -> IDLE1 -> WRIITE2 -> END
|
|We can change parameters of those 4 tasks from below list of parameters. 
|_____________________________________________________________________________________*/

//Execution Sequence Parameters
parameter INITIAL_IDLE_TIME = 8'd100;

parameter WRITE1_SLAVE      = SLAVE1;
parameter WRITE1_START_ADDR = 12'd500;
parameter WRITE1_DATA       = 8'd170;
parameter WRITE1_DATA_INCR  = 7;
parameter WRITE1_SIZE       = 4'd2;   

parameter READ1_SLAVE       = SLAVE2;
parameter READ1_START_ADDR  = 12'd400;
parameter READ1_SIZE        = 2'd2;  

parameter IDLE1_CYCLES      = 8'd30;

parameter WRITE2_SLAVE      = SLAVE3;
parameter WRITE2_START_ADDR = 12'd2000;
parameter WRITE2_DATA       = 8'd180;
parameter WRITE2_DATA_INCR  = 7;
parameter WRITE2_SIZE       = 4'd6;   


//Registers Needed for the Execution Sequence
reg [5:0]  state              = 5'd0;

reg [7:0]  initial_idle_time  = INITIAL_IDLE_TIME;

reg [11:0] write1_addr        = WRITE1_START_ADDR;
reg [7:0]  write1_data        = WRITE1_DATA;
reg [3:0]  write1_size        = WRITE1_SIZE;

reg [11:0] read1_addr         = READ1_START_ADDR;
reg [3:0]  read1_size         = READ1_SIZE;
reg [7:0]  read1_data[1:0];

reg [7:0]  idle1_cycles       = IDLE1_CYCLES;

reg [11:0] write2_addr        = WRITE2_START_ADDR;
reg [7:0]  write2_data        = WRITE2_DATA;
reg [3:0]  write2_size        = WRITE2_SIZE;


/*################################### STATE MACHINE #################################
------------------------------------------------------------------------------------*/
//STATES:
parameter INITIAL_IDLE                  = 0;

parameter WRITE1_UPDATE_ADDR            = 1;
parameter WRITE1_ADDR_RQ                = 2;
parameter WRITE1_OK_RES                 = 3;
parameter WRITE1_UPDATE_DATA            = 4;
parameter WRITE1_DATA_RQ                = 5;
parameter WRITE1_RQ_DONE                = 6;

parameter READ1_UPDATE_ADDR             = 7;
parameter READ1_ADDR_RQ                 = 8;
parameter READ1_OK_RES                  = 9;
parameter READ1_DATA_RQ                 = 10;
parameter READ1_RQ_DONE                 = 11;

parameter IDLE1                         = 12;

parameter WRITE2_UPDATE_ADDR            = 13;
parameter WRITE2_ADDR_RQ                = 14;
parameter WRITE2_OK_RES                 = 15;
parameter WRITE2_UPDATE_DATA            = 16;
parameter WRITE2_DATA_RQ                = 17;
parameter WRITE2_RQ_DONE                = 18;

parameter ALL_DONE                      = 19;

//STATE MACHINE:
always@(posedge clk or negedge reset) begin
    if(~reset)begin
        addr_to_mi           <= 0;
        write_addr_req_to_mi <= 0;
        write_data_to_mi     <= 0;
        write_data_req_to_mi <= 0;
        read_data_req_to_mi  <= 0;
        force_req_to_mi      <= 0;

        state                <= 5'd0;
        initial_idle_time    <= INITIAL_IDLE_TIME;
        write1_addr          <= WRITE1_START_ADDR;
        write1_data          <= WRITE1_DATA;
        write1_size          <= WRITE1_SIZE;
        read1_addr           <= READ1_START_ADDR;
        read1_size           <= READ1_SIZE;
        idle1_cycles         <= IDLE1_CYCLES;
        write2_addr          <= WRITE2_START_ADDR;
        write2_data          <= WRITE2_DATA;
        write2_size          <= WRITE2_SIZE;
    end

    else begin
        case(state)

            //###################### INITIAL IDLE TIME #########################
            INITIAL_IDLE: begin
                if(initial_idle_time > 0)
                    initial_idle_time <= initial_idle_time -1;
                else
                    state <= WRITE1_UPDATE_ADDR;
            end

            //############################ WRITE1 ##############################
            WRITE1_UPDATE_ADDR: begin  
                if(write1_size == 0)begin
                    state <= READ1_UPDATE_ADDR;
                end
                else begin
                    force_req_to_mi <= 0;
                    write1_size <= write1_size-1;         
                    addr_to_mi <= {STARTBIT, WRITE1_SLAVE, WRITE, write1_addr};
                    write1_addr <= write1_addr + 1;
                    state <= WRITE1_ADDR_RQ;
                end
            end

            WRITE1_ADDR_RQ: begin
                write_addr_req_to_mi <= 1;
                state <= WRITE1_OK_RES;
            end

            WRITE1_OK_RES: begin
                if(ok_response_from_mi == 1)begin
                    write_addr_req_to_mi <= 0;
                    state <= WRITE1_UPDATE_DATA;
                end
            end

            WRITE1_UPDATE_DATA: begin
                write_data_to_mi <= write1_data;
                write1_data <= write1_data + WRITE1_DATA_INCR;
                state <= WRITE1_DATA_RQ;
            end

            WRITE1_DATA_RQ: begin
                write_data_req_to_mi <= 1;
                state <= WRITE1_RQ_DONE;
            end
            WRITE1_RQ_DONE: begin
                if(req_done_from_mi == 1) begin
                    write_data_req_to_mi <= 0;
                    state <= WRITE1_UPDATE_ADDR;

                    if(write1_size != 0)begin
                        force_req_to_mi <= 1;
                    end
                end
            end


            //############################ READ1 ##############################
            READ1_UPDATE_ADDR: begin
                if(read1_size == 0)begin
                    state <= IDLE1;
                end
                else begin
                    force_req_to_mi <= 0;
                    read1_size  <= read1_size-1;         
                    addr_to_mi  <= {STARTBIT, READ1_SLAVE, READ, read1_addr};
                    read1_addr  <= read1_addr + 1;
                    state <= READ1_ADDR_RQ;
                end
            end

            READ1_ADDR_RQ: begin
                write_addr_req_to_mi <= 1;
                state <= READ1_OK_RES;
            end

            READ1_OK_RES: begin
                if(ok_response_from_mi == 1)begin
                    write_addr_req_to_mi <= 0;
                    state <= READ1_DATA_RQ;
                end
            end

            READ1_DATA_RQ: begin
                read_data_req_to_mi <= 1;
                state <= READ1_RQ_DONE;
            end

            READ1_RQ_DONE: begin
                if(req_done_from_mi == 1) begin
                    read_data_req_to_mi <= 0;
                    read1_data[read1_size] <= read_data_from_mi;
                    state <= READ1_UPDATE_ADDR;

                    if(read1_size != 0)begin
                        force_req_to_mi <= 1;
                    end
                end
            end


            //############################ IDLE1 ###############################
            IDLE1: begin
                if(idle1_cycles == 0) begin
                    state <= WRITE2_UPDATE_ADDR;
                end
                idle1_cycles <= idle1_cycles -1;
            end


            //############################ WRITE2 ##############################
            WRITE2_UPDATE_ADDR: begin  
                if(write2_size == 0)begin
                    state <= ALL_DONE;
                end
                else begin
                    force_req_to_mi <= 0;
                    write2_size <= write2_size-1;         
                    addr_to_mi <= {STARTBIT, WRITE2_SLAVE, WRITE, write2_addr};
                    write2_addr <= write2_addr + 1;
                    state <= WRITE2_ADDR_RQ;
                end
            end

            WRITE2_ADDR_RQ: begin
                write_addr_req_to_mi <= 1;
                state <= WRITE2_OK_RES;
            end

            WRITE2_OK_RES: begin
                if(ok_response_from_mi == 1)begin
                    write_addr_req_to_mi <= 0;
                    state <= WRITE2_UPDATE_DATA;
                end
            end

            WRITE2_UPDATE_DATA: begin
                write_data_to_mi <= write2_data;
                write2_data <= write2_data + WRITE2_DATA_INCR;
                state <= WRITE2_DATA_RQ;
            end

            WRITE2_DATA_RQ: begin
                write_data_req_to_mi <= 1;
                state <= WRITE2_RQ_DONE;
            end
            WRITE2_RQ_DONE: begin
                if(req_done_from_mi == 1) begin
                    write_data_req_to_mi <= 0;
                    state <= WRITE2_UPDATE_ADDR;

                    if(write2_size != 0)begin
                        force_req_to_mi <= 1;
                    end
                end
            end


            //############################# END ###############################
            ALL_DONE: begin
                state <= ALL_DONE;
            end

        endcase
    end

end


endmodule