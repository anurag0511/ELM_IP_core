`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/13/2018 06:35:43 PM
// Design Name: 
// Module Name: Neuron
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Neuron#(
		parameter LFSR_SEED_VALUE       = 575,
		parameter NO_OF_INPUT_NEURONS   = 100,
		parameter NO_OF_HIDDEN_NEURONS  = 200,
		parameter NO_OF_OUTPUT_NEURONS  = 10,
		parameter LEARNING_RATE			= 10,
		parameter INPUT_BIT_WIDTH  		= 8,
		parameter OUTPUT_BIT_WIDTH  	= 4,
		parameter HIDDEN_BIT_WIDTH		= 8,
		parameter Q 					= 14,
		parameter N 					= 16
	) (
		input wire          clk,
		input wire          reset,
		input wire[(HIDDEN_BIT_WIDTH-1):0] neuron_id,
		input wire          data_en,
		input wire [(N-1):0]  pixel,
		input wire          transfer_en,
		input wire[N-1:0]   data_in,
		output reg[N-1:0]	data_out
    );
    
                        
    // Constants used in this module
    parameter [2:0] READ_INPUT_PIXEL    = 3'b001,
                    EXTRA_STATE         = 3'b010,
                    TRANSFER_RESULT     = 3'b011,
                    IDLE                = 3'b111;
    
    //variables used within this module
    reg [2:0] neuron_state;
    reg lfsr_feedback;
    reg [N-1:0] lfsr_temp;
    reg [31:0] lfsr_ptr;
    reg [31:0] counter;
    reg [N-1:0] mul_op1;
    reg [N-1:0] mul_op2;
    reg [(2*N)-1:0] mac_result;
    reg [N-1:0] sigmoid_out;
    reg valid_data;
	wire mul_ovr_flag;
    wire [(2*N)-1:0] temp_mac_result;
    wire [N-1:0] mul_result;
    
    // Instance of Multiplier
    fixed_mult #( 
                    .Q (Q),
                    .N (N)
                ) multiplier (
                    .i_multiplicand (mul_op1),
                    .i_multiplier   (mul_op2),
                    .o_result       (mul_result)
                );
    // Instance of Adder
    fixed_add #( 
                    .Q (Q),
                    .N (N)
                ) adder (
                    .a (mul_result),
                    .b (mac_result),
                    .c (temp_mac_result)
                );            
    
    always @(posedge clk)
    begin
        if(reset == 1'b0)
        begin
            neuron_state    = READ_INPUT_PIXEL;
            lfsr_feedback   = 0;
            lfsr_temp       = LFSR_SEED_VALUE * (neuron_id + 1);
            lfsr_ptr        = 0;
            counter         = 0;
            mul_op1         = 0;
            mul_op2         = 0;
            mac_result      = 0;
            valid_data      = 1'b0;
        end
        else
        begin
            case(neuron_state)
				READ_INPUT_PIXEL:
				begin
					mac_result = temp_mac_result;
					if(data_en)
					begin
						input_weight_lfsr();
						mul_op1 	= pixel[N-1:0]; 
						mul_op2 	= lfsr_temp[N-1:0];
						valid_data 	= 1'b1;  
					end 
					else if(~data_en && valid_data)
					begin
						lfsr_temp       = LFSR_SEED_VALUE * (neuron_id + 1);
						neuron_state    = EXTRA_STATE;
						valid_data      = 1'b0;
					end  
				end
				EXTRA_STATE:
				begin
					if (temp_mac_result[(2*N)-2:N-2] >= 2)
					begin
					   if (temp_mac_result[(2*N)-1] == 1'b1)
					   begin
							sigmoid_out = 0;
					   end
					   else
					   begin
							sigmoid_out = 0;    
							sigmoid_out[N-2] = 1'b1; 
					   end
					end
					else
					begin
						sigmoid_out[N-1] 	= 1'b0;
						sigmoid_out[N-2:0] 	= temp_mac_result[N:2];
						if (temp_mac_result[(2*N)-1] == 0)
						begin
							sigmoid_out[N-2:0] = sigmoid_out[N-2:0] + {{1'b0},{1'b1},{(N-3){1'b0}}};
						end
						else
						begin 
							sigmoid_out[N-2:0] = {{1'b0},{1'b1},{(N-3){1'b0}}} - sigmoid_out[N-2:0];
						end     
					end
					data_out        = sigmoid_out;
					mac_result      = 0;
					mul_op1         = 0;
					mul_op2         = 0;
					if(transfer_en)
					begin
						neuron_state    = TRANSFER_RESULT;
					end 
				end
				TRANSFER_RESULT:
				begin
					if(transfer_en)
					begin
						data_out = data_in;
					end
					else
					begin
						neuron_state = IDLE;
					end
				end
				IDLE:
				begin
					neuron_state    = READ_INPUT_PIXEL;
					lfsr_feedback   = 0;
					lfsr_temp       = LFSR_SEED_VALUE * (neuron_id + 1);
					lfsr_ptr        = 0;
					counter         = 0;
					mul_op1         = 0;
					mul_op2         = 0;
					mac_result      = 0;
					valid_data      = 1'b0;
				end
				default:
				begin
						// Do nothing
				end
            endcase
        end
    end
    
    // LFSR function to generate input weights I still need to play aroung ith this LFSR
    task input_weight_lfsr;
        begin        
            lfsr_feedback = lfsr_temp[15] ^ lfsr_temp[14] ^lfsr_temp[13] ^ lfsr_temp[3];
            lfsr_temp     = lfsr_temp >> 1;
            lfsr_temp[N-1] = lfsr_feedback;
            lfsr_ptr      = lfsr_ptr + 1;
        end
    endtask

endmodule
