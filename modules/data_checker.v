
/******************************************

   Organization Name: SURE ProEd

   

   Engineer Name: Pera Mamatha

   

   Project Name: ram_system_design

   

   Module Name: data_checker.v

   

   Description: 

         DATA CHECKER:

           - Port list:

              - i_clk           : system clk

              - i_rst           : it will reset the reference data generated to 0

              - i_start         : idicates the incoming rx data, reciever should start checking

                                once this pulse is received: the generator inside the checker should

                                activate itself

                                generating data from the previous stop value (or 0 for first iteration)

              - i_data_valid    : indicates valid data reception in the checker

              - i_data [31:0]   : data recieved from the checker

              - o_checking_done : indicates checker operation is done

              - o_valid_frame   : pulse indicating, the correctness of the recieved frame

           

           Packet received correctly   : o_checking_done &&  o_valid_frame

           Packet received incorrectly : o_checking_done && !o_valid_frame

   Latency: 

   

   Version:

******************************************/

   

module data_checker 

   (

      // ---------- Input signals ----------

      input             i_clk              ,

      input             i_rst              ,

      input             i_start            ,  // control signal to start the data generation

      input             i_data_valid       ,  // indicates valid data recieved from RAM

      input      [31:0] i_data             ,

      // ---------- Output signals ---------

      output            o_checking_done    ,  // pulse indicating end of check operation

      output            o_valid_frame         // pulse indicating correct frame recieved

   );

   

   /*

      Working of Checker

      - We require a generator (Let's reuse the data generator)

        It's latency is 1clk, so the reference data is recieved from

        generator in next clk

      - Pipeline the recieved data with the generated data

      - Compare the two data streams and increment the error_data_cntr 

        on every mismatch

      - At the end of frame if error_data_cntr==0; packet received is valid

      

      - How do we detect end of frame?

         - One way is to use a control counter similar to generator

         - use a falling edge detector on the data_valid signal

      - On the falling edge of the data_valid

         - if error_cnt == 0; frame is valid

      - On the falling edge of the data_valid

         - unconditionally: frame reception is done

   */
    
    //declaring generated data signals
    wire [31:0] ref_data;
    wire        ref_data_valid;
    
    //register to store the delayed verion of the recieved data 
    reg [31:0] data_d;      
    reg        data_valid_d;
    
    // counter to check the no of errors
    reg [6:0] error_data_cntr;
   
    //register to store the delayed verion of the data generated
    reg        ref_data_valid_d;
   
    // to indicate the end of frame
    wire       end_of_frame;
   
    // to show whether the data recived is correct or not
    reg        frame_valid;
    reg        checking_done;
   
    data_generator  data_generator_inst
       (
                          .i_clk        ( i_clk          ),
                          .i_rst        ( i_rst          ),
                          .i_start      ( i_start        ),
                          .o_data_valid ( ref_data_valid ),
                          .o_data       ( ref_data       )    
       );
     
    
    // comparing the recieved data from the RAM with delayed verion of the data generated
    always@ (posedge i_clk)  begin
        if(i_rst) begin
            error_data_cntr <= 7'b0;
        end 
        else begin
            if(i_start) begin
                error_data_cntr <= 7'b0;
            end 
//            else begin
//                if(data_d != i_data) begin
//                    error_data_cntr <= error_data_cntr + 7'b1;
//                end
//            end
             else if(data_d != ref_data && ref_data_valid ) begin
                    error_data_cntr <= error_data_cntr + 7'b1;
             end
        end
    end
   
    //falling edge detection
    assign end_of_frame=(ref_data_valid_d & ~ref_data_valid);
   
    //taking decision on whether recieved frame is correct or not
    always@ (posedge i_clk) begin
        if( end_of_frame && error_data_cntr==7'b0) begin
            frame_valid <= 1'b1;
        end
        else
            frame_valid <= 1'b0;
    end
   
    assign o_valid_frame   = frame_valid;
    assign o_checking_done = checking_done;
   
    //delay unit
    // 1. delaying the recieved data from the RAM to match the latency of the data generated from the generator
    // 2. falling edge detection
    always@ (posedge i_clk)  begin
       data_d           <= i_data;
       data_valid_d     <= i_data_valid;
       ref_data_valid_d <= ref_data_valid;
       checking_done    <= end_of_frame;
    end

endmodule