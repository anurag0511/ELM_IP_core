`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/19/2018 08:40:44 PM
// Design Name: 
// Module Name: fixed_mult
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

module fixed_mult#(
	//Parameterized values
	parameter Q = 14,
	parameter N = 16
	)
	(
	 input			[N-1:0]	i_multiplicand,
	 input			[N-1:0]	i_multiplier,
	 output			[N-1:0]	o_result
	// output	reg				ovr
	 );

	
	reg [2*N-1:0]	r_result;		
	reg [N-1:0]		r_RetVal;
	
//--------------------------------------------------------------------------------
	assign o_result = r_RetVal;    
	
//---------------------------------------------------------------------------------
	always @(i_multiplicand, i_multiplier)	
	begin						
	   //	Do the multiply any time the inputs change
	   r_result <= i_multiplicand[N-2:0] * i_multiplier[N-2:0];	//	Removing the sign bits from the multiply - that 
															     //		would introduce *big* errors	
	   //ovr <= 1'b0;											     //	reset overflow flag to zero
	end
	

	always @(r_result,i_multiplicand, i_multiplier) 
	//always @(i_multiplicand, i_multiplier)
	begin													
	   //	Any time the result changes, we need to recompute the sign bit,
	   r_RetVal[N-1]   <= i_multiplicand[N-1] ^ i_multiplier[N-1];	//		which is the XOR of the input sign bits...  (you do the truth table...)
	   r_RetVal[N-2:0] <= r_result[N-2+Q:Q];						//	And we also need to push the proper N bits of result up to 
																	//		the calling entity..
    end
endmodule

