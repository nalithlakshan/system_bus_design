module slave_interface(

    input wire clk,     //system clock input           
    input wire reset,   //active low reset          
    input wire addr,    //address bus 
    input wire w_data,  //write data bus 
    output wire r_data, //read data bus 
    output [1:0] response,       //response bus 
    output [1:0] split_request,  //request split transaction
    input  [1:0] granted_master, //indicates the active master on the bus 
    input wire [1:0]slave_address, //sets the device address of the slave
    output reg slave_en, // enable signal for tri-state buffers
    input slave_busy,    // indicates that the slave is busy
    //------for ram----//
    input wire [7:0]q,   // output data from the ram 
    output [11:0]ram_address, //address input of the ram
    output [7:0]ram_data, // data input to the ram 
    output wr_en
);
//-----------PARAMETERS-------------//
//---STATES---//
parameter AWATING_GRANT = 4'b0000;
parameter START_BIT =4'b0001;
parameter GET_ADDR = 4'b0010;
parameter SEND_RESPONSE_ADDRESS = 4'b0011 ;
parameter GET_DATA = 4'b0100 ;
parameter SEND_DATA = 4'b0101 ;
parameter SEND_RESPONSE_DATA = 4'b0110 ;
parameter SPLIT =4'b0111;
parameter WAIT_BEFORE_GET_DATA =4'b1000;
//---RESPONSES---//
parameter RESP_NAK =2'b00;
parameter PESP_BUSY=2'b01;
parameter RESP_OK  =2'b10;
parameter RESP_DONE=2'b11;

//-----------REGISTERS--------------//
reg [3:0] state = START_BIT;

reg [15:0]r_addr     =0;
reg [7:0]r_data_in  =0;
reg r_data_out =0;
reg [1:0]r_response =0;
reg [1:0]r_split    =0;
reg [4:0]addr_count =0;
reg [3:0]data_count =0;
reg wr_en_bit =0;
reg [15:0]split_adress=0;
reg [1:0]split_master =0;
reg [1:0]r_split_request =0;
reg [3:0]busy_count=5;


//-----------STATE_MACHINE----------//

always @ (posedge clk or negedge reset) begin
    // This is a active low asynchronous reset. 
    // This will reset all the registers to their defaulst state.
    if (~reset) begin 
    	state <= START_BIT;
		wr_en_bit<=0;
		r_addr<=0;
		r_data_in<=0;
		r_data_out<=0;
		r_response<=RESP_NAK;
		r_split<=0;
		addr_count<=0;
		data_count<=0;
		busy_count<=5;
        slave_en <=0;
        split_adress <= 0;
        split_master <= 0;
        r_split_request <= 0;
    end else begin
    	
    case (state)
    // This is the default state of the module
    // This states ideentifies the start bit of the address 
        START_BIT: begin
            slave_en <= 0;
            if (addr==1) begin
                state <= GET_ADDR;
                addr_count<=14;
				wr_en_bit<=0;
				r_addr<=0;
				r_data_in<=0;
				r_data_out<=0;
            end
            else 
                state <= START_BIT;

            addr_count<=15; 
            r_response<=RESP_NAK;         
        end
    //Capturs the 15-bit address which follows the start bit
        GET_ADDR: begin
            
            if (addr_count>1) begin
                r_addr[15:0] <= {r_addr[14:0],addr};
                addr_count <= addr_count -1;
                state <= GET_ADDR;
            end else begin
            	r_addr[15:0] <= {r_addr[14:0],addr};
                state <= SEND_RESPONSE_ADDRESS;
            end
            wr_en_bit<=0;
            r_response<=RESP_NAK;
        end

    //decode the slave address and the type of transaction (mem r/w)
    //and send the appropriate response to the master.
        SEND_RESPONSE_ADDRESS: begin

        	if (r_addr[14:13] == slave_address) begin // check for slave address
                slave_en <= 1;

                if(slave_busy == 0)begin
            		if (r_addr[12]==1) begin // do this for mem write
            			state<= WAIT_BEFORE_GET_DATA;
            			r_response<=RESP_OK;
            			data_count<=8;
            		end	
            		else begin               // do this for mem read 
            			state<= SEND_OK;
            			r_response<=RESP_DONE;
            			data_count<=7;
            		end
                end
                else begin
                    r_response<=RESP_BUSY;  // send BUSY response
                    split_adress<= r_addr;
                    split_master<= granted_master;
                    state <= SPLIT; 
                end 	
        	end
        	else begin 
        		state<=START_BIT;  
        	end 
        end

    // capturs the 8bit data which is to be written to the ram
        GET_DATA: begin
           if (data_count>1) begin
           	r_data_in[7:0]<= {r_data_in[6:0],w_data};
           	data_count<=data_count-1;
           	state<=GET_DATA;
           end else begin
           	r_data_in[7:0]<= {r_data_in[6:0],w_data};
           	state <= SEND_RESPONSE_DATA;
           	wr_en_bit<=1;
           end
           r_response<=RESP_NAK;
        end

    // send the data from the ram to the master 
        SEND_DATA: begin
            if (data_count>0) begin
           	r_data_out<= q[data_count];
           	data_count<=data_count-1;
           	state<=SEND_DATA;
           end else begin
           	r_data_out<= q[data_count];
           	state <= SEND_RESPONSE_DATA;
           	wr_en_bit<=0;
            end 
            r_response<=RESP_NAK;
        end
    // send the DONE sesponse to the master which indicates 
    // a successfull data transfer.
         SEND_RESPONSE_DATA: begin
            wr_en_bit<=0;
            r_response<=RESP_DONE;
            state <=START_BIT;
        end
    // comes here after sending a BUSY response
    // waits until the slave is ready. 
        SPLIT: begin
            slave_en <= 0;
            if (slave_busy==1) begin 
            	state <= SPLIT;
            end 
            else begin
            	r_split_request<=split_master;
            	state <= AWATING_GRANT;
            end
        end

    // after requesting a split transaction wait here until the 
    // arbiter grants permission
        AWATING_GRANT: begin
            if (granted_master==split_master) begin           	
            	r_addr<=split_adress;
            	state<= SEND_RESPONSE_ADDRESS;
                r_split_request<=0;
            end else begin
            	state <= AWATING_GRANT;
            end
        end
    // wait one clock cycle before capture data
        WAIT_BEFORE_GET_DATA: begin
            state<=GET_DATA;
        end
	endcase // state	  
	
	end
	  
end
assign response = r_response;	
assign ram_address = r_addr[11:0];
assign ram_data = r_data_in;
assign wr_en =wr_en_bit;
assign r_data=r_data_out;
assign split_request=r_split_request;
endmodule