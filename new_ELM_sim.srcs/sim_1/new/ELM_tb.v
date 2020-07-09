`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:		Rochester Institute of Technology, Neuromorphic AI Lab 
// Engineer:	Anurag Reddy Daram, Karan Raghu Paluru, Vedant Karia 
// Design Name: Reconfigurage hardware for Extreme Learning Machine as an IP core
// Module Name: ELM_tb
// Project Name:Extreme Learning Machine 
// Description: This module instantiates the ELM IP core as an DUT. Provides the 
//				input to the DUT from a file, and reads back the DUT output. 
//				It compares the output of the DUT with the expected output and 
//				provides training and testing accuracy.
// Revision:	V_1.0
//////////////////////////////////////////////////////////////////////////////////

module ELM_tb();
   localparam WIDTH                 	= 8;
   localparam LFSR_SEED_VALUE       	= 575;
   localparam NO_OF_INPUT_NEURONS   	= 100;
   localparam NO_OF_HIDDEN_NEURONS  	= 200;
   localparam NO_OF_OUTPUT_NEURONS  	= 10;
   localparam LEARNING_RATE				= 10;
   localparam INPUT_BIT_WIDTH  			= 7;
   localparam OUTPUT_BIT_WIDTH  		= 4;
   localparam HIDDEN_BIT_WIDTH			= 8;
   localparam TOTAL_NUMBER_OF_BITS 		= 8;
   localparam NUMBER_OF_FRACTION_BITS 	= 6;
   
   
   `define NULL 0
       
    // Variables used for the DUT
    reg clk_tb;
    reg reset_tb, eof;
    reg learn_flag_tb;
    reg [(INPUT_BIT_WIDTH-1):0] pixel_in_tb ;
    reg [(TOTAL_NUMBER_OF_BITS-1):0] pixel_data [0:99];
    wire [(OUTPUT_BIT_WIDTH-1):0] pixel_out_tb;
    wire ready_flag;
    reg [(OUTPUT_BIT_WIDTH-1):0]label;
    parameter [31:0] total_train_samples    = 800;
    parameter [31:0] total_test_samples     = 200;
    
    // Variables used in this module
    integer status_I;
    integer file_I,scan_file ;
    integer counter;
    integer input_counter;
    reg flag;
    reg reset_flag;
    reg complete_one_set;
    integer i;
    integer counter_tb;
    reg [2:0]states_tb;
    reg write_enable_flag;
    wire ready;
    integer testing_counter;
    integer training_counter;
    real testing_accuracy, training_accuracy;

    MCU #(
		.LFSR_SEED_VALUE       	(LFSR_SEED_VALUE),     
		.NO_OF_INPUT_NEURONS   	(NO_OF_INPUT_NEURONS), 
		.NO_OF_HIDDEN_NEURONS  	(NO_OF_HIDDEN_NEURONS),
		.NO_OF_OUTPUT_NEURONS  	(NO_OF_OUTPUT_NEURONS),
		.LEARNING_RATE			(LEARNING_RATE),			
		.INPUT_BIT_WIDTH  		(INPUT_BIT_WIDTH),  			
		.OUTPUT_BIT_WIDTH  		(OUTPUT_BIT_WIDTH), 			
		.HIDDEN_BIT_WIDTH		(HIDDEN_BIT_WIDTH),		
		.Q 						(NUMBER_OF_FRACTION_BITS),					
		.N 						(TOTAL_NUMBER_OF_BITS) 	
    ) DUT(
        .clk            (clk_tb),
        .reset          (reset_tb),
        .learn_flag     (learn_flag_tb),
        .input_enable   (write_enable_flag),
        .pixel_in       (pixel_in_tb),
        .input_label    (label),
        .output_data    (pixel_out_tb),
        .ready          (ready)
    );  

    parameter [2:0] state_read      = 3'b000,
                    state_transmit  = 3'b001,
                    state_complete  = 3'b010,
                    state_IDLE      = 3'b011,
                    state_accuracy  = 3'b101,
                    state_wait_ready= 3'b100;

	initial 
	begin 
		// Resetting the system
		write_enable_flag   = 1'b0;
		reset_tb            = 1'b0;
		reset_flag          = 1'b1;
		counter             = 0;
		complete_one_set    = 1'b0;
		input_counter       = 0;
		pixel_in_tb         = 0;
		states_tb           = state_read;
		learn_flag_tb       = 1;
		training_counter    = 0;
		testing_counter     = 0;
		testing_accuracy    = 0;
		training_accuracy   = 0;
		
		// opeing the input file
		flag    = 1'b0;
		file_I  = $fopen("C://Users/Anurag/Desktop/ELM_final/MNIST_train_ELM_final.dat", "r");
		if((file_I == `NULL)) 
		begin
			$display("file handle was NULL");
			flag = 1'b0;
			$finish;
		end    
		else
		begin
			// Do nothing
		end    
		
		// Reset to the system
		reset_tb 	= 1'b0;
		clk_tb  	= 0;
		for(i=0 ; i< 10 ; i= i+1)
		begin
			#10;clk_tb = ~clk_tb;
		end
		reset_tb 	= 1'b1;
		
		// Generating the clock for the DUT
		forever 
		begin    
			#10 clk_tb = ~clk_tb;
		end
	end
	
	// Providing the input for the DUT to verify the DUT.
	always @(posedge clk_tb)
	begin
	   if(reset_tb == 1)
	   begin
	      case(states_tb)
          state_read:
            begin
                eof = $feof(file_I);
                if(eof == 0)
                begin
                   scan_file = $fscanf(file_I, "%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d\n",
                    label, pixel_data[0], pixel_data[1], pixel_data[2], pixel_data[3], pixel_data[4], pixel_data[5], pixel_data[6], pixel_data[7], pixel_data[8], pixel_data[9],
                     pixel_data[10], pixel_data[11], pixel_data[12], pixel_data[13], pixel_data[14], pixel_data[15], pixel_data[16], pixel_data[17],pixel_data[18], pixel_data[19],
                     pixel_data[20], pixel_data[21], pixel_data[22], pixel_data[23], pixel_data[24], pixel_data[25], pixel_data[26], pixel_data[27], pixel_data[28], pixel_data[29],
                     pixel_data[30], pixel_data[31], pixel_data[32], pixel_data[33], pixel_data[34], pixel_data[35], pixel_data[36], pixel_data[37], pixel_data[38], pixel_data[39],
                     pixel_data[40], pixel_data[41], pixel_data[42], pixel_data[43], pixel_data[44], pixel_data[45], pixel_data[46], pixel_data[47], pixel_data[48], pixel_data[49], 
                     pixel_data[50], pixel_data[51], pixel_data[52], pixel_data[53], pixel_data[54], pixel_data[55], pixel_data[56], pixel_data[57], pixel_data[58], pixel_data[59], 
                     pixel_data[60], pixel_data[61], pixel_data[62], pixel_data[63], pixel_data[64], pixel_data[65], pixel_data[66], pixel_data[67], pixel_data[68], pixel_data[69], 
                     pixel_data[70], pixel_data[71], pixel_data[72], pixel_data[73], pixel_data[74], pixel_data[75], pixel_data[76], pixel_data[77], pixel_data[78], pixel_data[79], 
                     pixel_data[80], pixel_data[81], pixel_data[82], pixel_data[83], pixel_data[84], pixel_data[85], pixel_data[86], pixel_data[87], pixel_data[88], pixel_data[89],
                     pixel_data[90], pixel_data[91], pixel_data[92], pixel_data[93], pixel_data[94], pixel_data[95], pixel_data[96], pixel_data[97], pixel_data[98], pixel_data[99]
                    );
                  end
                  states_tb 		= state_wait_ready;
                  counter_tb 		= 0;
            end 
            
            state_wait_ready:
            begin
                if(ready)
                begin
                    states_tb           = state_transmit;
                    write_enable_flag   = 1'b1;
                    
                end    
            end
            
            state_transmit:
            begin
                 if(counter_tb == 100)
                   begin
                    
                    states_tb 			  = state_IDLE;
                    counter_tb 			  = 0;
                    write_enable_flag     = 1'b0;
                   end
                   else
                   begin
                   write_enable_flag      = 1'b1;
                    pixel_in_tb 	      = pixel_data[counter_tb];
                    counter_tb 	          = counter_tb + 1'b1;
                   end
            end
            
            state_IDLE:
            begin
                if(ready)
                states_tb = state_complete;
            end
            
            state_complete:
            begin
                if(learn_flag_tb)
                begin
                    training_counter = training_counter +1;
                    if(label == pixel_out_tb)
                    begin
                        training_accuracy = training_accuracy+1;
                    end
                end
                else
                begin
                    testing_counter = testing_counter +1;
                    if(label == pixel_out_tb)
                    begin
                        testing_accuracy = testing_accuracy+1;
                    end
                end 
                if(scan_file <= 0)
                $finish;
                states_tb = state_accuracy;
            end
          state_accuracy:
          begin
            if(training_counter == total_train_samples)
            begin
                learn_flag_tb    = 0;
                $fclose(file_I);
                file_I  = $fopen("C://Users/Anurag/Desktop/ELM_final/MNIST_test_ELM_final.dat", "r");
                training_counter =0;
            end
            if(testing_counter == total_test_samples)
            begin
                //testing_accuracy = testing_accuracy*100/total_test_samples;
                learn_flag_tb   = 0;
                $fclose(file_I);
                $finish;
            end
            states_tb	= state_read;
          end
          endcase;   
	   end
	   else
	   begin
	       states_tb = state_read;
	   end
   	end
endmodule
