module arbiter (
	input clk,
	input reset,
	input [1:0]req_from_master,	    //BUSREQ signals in format:[m1,m2]
	
	//SPLIT signals in format:[s1->m1,s1->m2,s2->m1,s2->m2,s3->m1,s3->m2]
	input [5:0]split_req_from_slave,
	
	input [1:0]bus_utilization,	    //UTIL signals in format:[m1,m2]
	output reg [1:0]grant_to_master,//GRANT signals in format:[m1,m2]
	
	//GMASTER signals in format:[s1<-m1,s1<-m2,s2<-m1,s2<-m2,s3<-m1,s3<-m2]
	output reg [5:0]notify_granted_master_to_slave 
);

wire [1:0]current_requests;//[m1 requested?, m2 requested ?]

/*either get responses from masters or get request from slaves waiting in 
the split states to grant permission for corresponding master*/
assign current_requests[1] = req_from_master[1] || split_req_from_slave[5] 
					 || split_req_from_slave[3] || split_req_from_slave[1];
assign current_requests[0] = req_from_master[0] || split_req_from_slave[4] 
					 || split_req_from_slave[2] || split_req_from_slave[0];

// initially no master is granted. no master is notified to slave
initial begin 
	grant_to_master                <= 2'b00;
	notify_granted_master_to_slave <= 6'b000000;
end

always @(posedge clk or negedge reset) begin 
	//asynchronous reset
	if(~reset)begin 
		//reset to no grants and no granted notifications
		grant_to_master                <= 2'b00;
		notify_granted_master_to_slave <= 6'b000000;            
	end 
	
	//bus requests are checked and granted only when bus is not utilized
	else if(bus_utilization == 2'b00) begin 
		case(current_requests) //process the requests from masters and slaves
			2'b00:begin        //no requests
				grant_to_master                 <= 2'b00;
				notify_granted_master_to_slave  <= 6'b000000;
				end
			2'b10:begin        //request to grant master 1
				//grant master 1
				grant_to_master                 <= 2'b10;  
				//notify 3 slaves that master 1 is granted
				notify_granted_master_to_slave  <= 6'b101010;  
				end
			2'b01:begin        //request to grant master 2
				//grant master 2   
				grant_to_master                 <= 2'b01; 
				//notify 3 slaves that master 2 is granted
				notify_granted_master_to_slave  <= 6'b010101;
				end
			//high priority goes to master 1
			2'b11:begin       //request to grant both master 1 and 2
				//master 1 is granted (high priority)
				grant_to_master                 <= 2'b10; 
				//notify 3 slaves that master 1 is granted
				notify_granted_master_to_slave  <= 6'b101010;
				end   
		endcase
	end
end

endmodule 