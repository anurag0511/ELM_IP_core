`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/19/2018 09:29:49 PM
// Design Name: 
// Module Name: fixed_add
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

module fixed_add #(
		parameter Q = 14,
		parameter N = 16
	)
	(
		input 	[N-1:0] a,
		input 	[(2*N)-1:0] b,
		output 	[(2*N)-1:0]c
    );

reg [(2*N)-1:0] res;

assign c = res;

always @(a,b) begin
	// both negative or both positive
	if(a[N-1] == b[(2*N)-1]) 
	begin						//	Since they have the same sign, absolute value increases
		res[(2*N)-2:0] = a[N-2:0] + b[(2*N)-2:0];		
		res[(2*N)-1] = a[N-1];							    end												//		Not doing any error checking on this...
	//	one of them is negative...
	else if(a[N-1] == 0 && b[(2*N)-1] == 1) 
	begin		//	subtract a-b
		if( a[N-2:0] > b[(2*N)-2:0] ) 
		begin					
			res[(2*N)-2:0] = a[N-2:0] - b[(2*N)-2:0];			//		then just subtract b from a
			res[(2*N)-1] = 0;										//		and manually set the sign to positive
        end
		else 
		begin												//	if a is less than b,
			res[(2*N)-2:0] = b[(2*N)-2:0] - a[N-2:0];			//		we'll actually subtract a from b to avoid a 2's complement answer
			if (res[(2*N)-2:0] == 0)
				res[(2*N)-1] = 0;										//		I don't like negative zero....
			else
				res[(2*N)-1] = 1;										//		and manually set the sign to negative
			end
		end
	else 
	begin												//	subtract b-a (a negative, b positive)
		if( a[N-2:0] > b[(2*N)-2:0] ) 
		begin					//	if a is greater than b,
			res[(2*N)-2:0] = a[N-2:0] - b[(2*N)-2:0];			//		we'll actually subtract b from a to avoid a 2's complement answer
			if (res[(2*N)-2:0] == 0)
				res[(2*N)-1] = 0;										//		I don't like negative zero....
			else
				res[(2*N)-1] = 1;										//		and manually set the sign to negative
			end
		else 
		begin												//	if a is less than b,
			res[(2*N)-2:0] = b[(2*N)-2:0] - a[N-2:0];			//		then just subtract a from b
			res[(2*N)-1] = 0;										//		and manually set the sign to positive
			end
		end
	end
endmodule

