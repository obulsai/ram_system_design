
/******************************************
   Organization Name: SURE ProEd
   
   Engineer Name: Pera Mamatha
   
   Project Name: ram_system_design
   
   Module Name: ram_system_design.v
   
   Description: 
   
   Latency: 
   
   Version:
******************************************/

module top_module 
   (
      // ---------- Input signals ----------
      input             i_clk              ,
      input             i_rst              ,
      input             i_start_system  ,  // control pulse to start the data generation : Like a turn on button
      input             i_stop_system   ,  // control pulse to stop the data generation  : Like a turn off button
      // ---------- Output signals ---------
      output     [31:0] data_sets_generated,  // counter indicating total data packets being generated
      output     [31:0] data_sets_matched     // counter indicating correctly receieved data packets
   );
   
   
   /*
      Our objective:
      
      Generator ------->  RAM -----------> Checker
          ^                ^                 ^
          |                |                 |
          ------------control_unit------------
   */
   
   /*
      DATA GENERATOR:
      - Port list:
         - i_clk        : system clk
         - i_rst        : data generated in the generator resets to 0
         - i_start      : whenever start pulse is recieved, generator starts 
                          generating data from the previous stop value (or 0 for first iteration)
                          -- once start pulse is recieved; data generation starts
         - o_data_valid : indicates valid data generated from the generator
         - o_data [31:0]: generated data from the generator
   */
   
   /*
      DATA CHECKER:
         - We require a generator (Let's reuse the data generator)
           It's Latency is 1 clk, so the refernce data is received from 
           generator in next clk
         - Pipeline the recieved data with the generated data
         - Compare the two data streams and increment the error_data_cntr
           on every mismatch
         - At the end of frame if error_data_cntr == 0; packet received is valid

         - How do we detect end of frame ?
           - One way is to use a control counter similar to generator
           - Use a falling edge detector on the data valid signal

   */
    /*
        RAM Instantiation (we will get it thorugh the IP Catalog)
        blk_mem_gen_0 your_instance_name (
            .clka(clka),    // input wire clka
            .ena(ena),      // input wire ena
            .wea(wea),      // input wire [3 : 0] wea
            .addra(addra),  // input wire [5 : 0] addra
            .dina(dina),    // input wire [31 : 0] dina
            .douta(douta)  // output wire [31 : 0] douta
                    );
    */
   
    /*
        COntrol Unit:
        - Control unit becomes active, when it receives i_start_system pulse
            - once it gets the start system pulse, it should send start stimulas
            - along with this it should drive write address to the RAM (wr address with wea=0xf)
            - After 64 addresses generation it should it should stop generating the write address

            - Next it should start - read operation
            - It should send a stimulas to the checker
            - It should send a stimulas to the RAM (Send read address with wea=0)

            - To know that write/read is over: the control unit should run a counter
            - The counter should count in the range? 0-63 (i.e., Counting Data transmitted)
        
        - To Control thr process of write to and read from RAM
        - Control unit's role would be to handle wea signal
            - Control unit should send 4'b1111 when we perform write operation
            - Control unit should send 4'b0000 when we perform read operation
            
    */
     reg start_generator;
     
     reg [5:0] write_address;
     reg generate_wr_addr;
     reg write_done;
     
     wire [31:0] write_data;
     wire write_data_valid;
     
     reg start_checker;
     
     reg [5:0] read_address;
     reg generate_rd_addr;
     reg read_done;
     
     wire [31:0] read_data;
     wire read_data_valid;
     
     wire [31:0] ram_address;
     
     reg generate_rd_addr_d;
     reg start_checker_d;
     reg start_checker_2d;
     
     wire checker_done;
     wire valid_frame;
     
     reg [31:0] frame_count, valid_frame_count;
     
     reg stop_process_flag;
     
     wire [3:0] wea;
     
     data_generator data_generator_inst
            (
                   .i_clk(i_clk)       ,
                   .i_rst(i_rst)       ,
                   .i_start(start_generator)   ,
                   .o_data_valid(write_data_valid)      , 
                   .o_data(write_data)               
            );
            
    blk_mem_gen_0 ram_inst (
              .clka(i_clk),    // input wire clka
              .wea(wea),      // input wire [3 : 0] wea
              .addra(ram_address),  // input wire [5 : 0] addra
              .dina(write_data),    // input wire [31 : 0] dina
              .douta(read_data)  // output wire [31 : 0] douta
        );
        
    data_checker data_checker_inst
            (
                .i_clk(i_clk)              ,
                .i_rst(i_rst)              ,
                .i_start(start_checker_2d)            , 
                .i_data_valid(generate_rd_addr_d)       , 
                .i_data(read_data)             , 
                .o_checking_done(checker_done)    , 
                .o_valid_frame(valid_frame)       
            );

    // Control Logic for the system
    /*
        - It will drive start pulse to the generator
        - It will drive write address to the RAM 
        - It will drive write enable to the RAM
        
        - It will drive start checker pulse 
        - It will drive read address to the RAM
        - It will drive read enable which is ~write enable
        
        - Count no. of frames received 
        - Count no. of frames received correctly
    */
    
    // Control Logic for generator
    always @(posedge i_clk)   begin
        if (i_rst)  begin
                start_generator <= 1'b0;
        end
        else begin
            if ((i_start_system || checker_done) && ~stop_process_flag) begin
                start_generator <= 1'b1;
            end
            else begin
                start_generator <= 1'b0;
            end
        end
    end
    
   always @ (posedge i_clk) begin
      if (i_rst) begin
            generate_wr_addr <= 1'b0;
      end else begin
         if (start_generator) begin
            generate_wr_addr <= 1'b1;
         end else if ( write_address == 6'd63 ) begin
            generate_wr_addr <= 1'b0;
         end
      end
   end
   
   always @ (posedge i_clk) begin
      if (i_rst) begin
         write_address <= 6'b0;
      end else begin
         if (generate_wr_addr) begin
            write_address <= write_address + 6'b1;
         end
      end
   end
    
  always @ (posedge i_clk) begin
      if (i_rst) begin
            write_done <= 1'b0;
      end else begin
         if (write_address == 6'd63 && generate_wr_addr) begin
            write_done <= 1'b1;
         end
         else begin
            write_done <= 1'b0;
         end
      end
   end
   
   // Control Logic for Checker
    always @(posedge i_clk)   begin
        if (i_rst)  begin
                start_checker <= 1'b0;
        end
        else begin
            if (write_done) begin
                start_checker <= 1'b1;
            end
            else begin
                start_checker <= 1'b0;
            end
        end
    end
    
   always @ (posedge i_clk) begin
      if (i_rst) begin
            generate_rd_addr <= 1'b0;
      end else begin
         if (start_checker) begin
            generate_rd_addr <= 1'b1;
         end else if ( read_address == 6'd63 ) begin
            generate_rd_addr <= 1'b0;
         end
      end
   end
   
   always @ (posedge i_clk) begin
      if (i_rst) begin
         read_address <= 6'b0;
      end else begin
         if (generate_rd_addr) begin
            read_address <= read_address + 6'b1;
         end
      end
   end
    
  always @ (posedge i_clk) begin
      if (i_rst) begin
            read_done <= 1'b0;
      end else begin
         if (read_address == 6'd63 && generate_rd_addr) begin
            read_done <= 1'b1;
         end
         else begin
            read_done <= 1'b0;
         end
      end
   end
    
  assign wea = {write_data_valid,write_data_valid,1'b0,write_data_valid};//{4{write_data_valid}};
  assign ram_address = write_data_valid ? write_address : read_address;
  
  // Delay Unit  
  always@ (posedge i_clk) begin
     generate_rd_addr_d <= generate_rd_addr;
     start_checker_d    <= start_checker;
     start_checker_2d   <= start_checker_d;
  end
  
  always @(posedge i_clk) begin
    if (i_rst)  begin
        frame_count <= 32'b0;
        valid_frame_count <= 32'b0;
    end
    else begin
        if (checker_done) begin
            frame_count <= frame_count + 32'b1;
         end
        
        if (valid_frame) begin
            valid_frame_count <= valid_frame_count + 32'b1; 
        end
    end
  end
  
  always@ (posedge i_clk)   begin
    if (i_rst)  begin
        stop_process_flag <= 1'b0;
    end
    else    begin
        if (i_stop_system)  begin
            stop_process_flag <= 1'b1;
        end
        else if (i_start_system) begin
            stop_process_flag <= 1'b0;            
        end
    end
  end
  
  assign read_data_valid= generate_rd_addr_d ;
  assign  data_sets_generated = frame_count;
  assign  data_sets_matched =valid_frame_count;
 
  
endmodule