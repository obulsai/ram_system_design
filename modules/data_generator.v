
/******************************************
   Organization Name: SURE ProEd
   
   Engineer Name:  obul sai
   
   Project Name: ram_system_design
   
   Module Name: data_generator.v
   
   Description: DATA GENERATOR:
      - Port list:
         - i_clk              : system clk
         - i_rst        	    : data generated in the generator resets to 0
         - i_start            : whenever start pulse is recieved, generator starts 
                                  generating data from the previous stop value (or 0 for first iteration)
                                   -- once start pulse is recieved; data generation starts
         - o_data_valid 	: indicates valid data generated from the generator
         - o_data [31:0]  : generated data from the generator
   
   
   Latency: 
   
   Version:
******************************************/


module data_generator
	(
		//.............input signals...............//
		input					i_clk,
		input					i_rst,
		input					i_start,
		//.............output signals..............//
		output		         	o_data_valid,
		output		[31:0]	    o_data	
    );
	
	   /*
       Design Details
          - Data is of incremental nature: we can generate it
            with an incremental counter
          - Data width is 32-bits, hence, counter would be 32-bit wide
          
          - The counter resets to 0 whenever we get reset
          - The counter starts incrementing when we get i_start pulse
          - The generator generates 64 data for a Tx packet
          - The data generation starts from seed value 
             - seed = 32'b0 for 1st interation
             - seed = last value of previous packet for other interations
      
      - We also require a control counter that keeps 
        a check on number of data begin generated
        It counts from 0-63 for every iteration
        
        This counter will count from 0-63 in every iteration
        Size of the counter [5:0]
    */
	reg				generate_data   ; //signal stays high for 64 clks
	reg	    [ 5:0]	control_counter ;
	reg 	[31:0] 	generated_data ;
	
	// ***  generate_ data flag logic *** //
	
	always @ ( posedge i_clk ) begin
		if( i_rst ) begin
			generate_data <= 1'b0;
		end	else	begin
			if	( i_start ) begin
				generate_data <= 1'b1 ;
			end	else if (control_counter == 6'd63 ) begin
				generate_data <= 1'b0 ;
			end
		end 
	end
	
	// *** control counter logic *** //
	
	always @ ( posedge i_clk ) begin
		if( i_rst ) begin
			control_counter <= 6'b0 ;
		end	else	begin
			if	( generate_data ) begin
				control_counter <= control_counter + 6'b1 ;
			end
		end 
	end
		
	// *** Data counter logic *** //
	
	always @ ( posedge i_clk ) begin
		if( i_rst ) begin
			generated_data <= 32'b0;
		end	else	begin
			if	( generate_data ) begin
				generated_data <= generated_data + 32'b1 ;
			end
		end 
	end
		
	assign o_data = generated_data;
	assign o_data_valid = generate_data;
	
endmodule
