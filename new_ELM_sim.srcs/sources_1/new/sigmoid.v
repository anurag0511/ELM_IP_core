`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/03/2018 10:46:03 AM
// Design Name: 
// Module Name: sigmoid
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


module sigmoid(
input wire [6:0] value_in,
input wire clk,
output reg[6:0] value_out
    );
    

reg p1;
reg p2;
reg [6:0] temp_out;
reg p3,p4,p5,p6,p7,p8, p9,p10,p11,p12, p13,p14,p15,p16,p17,p18,p19,p20,p21,p22,p23,p24,p25,p26,p27;
always @(posedge clk)
        begin
        
        p1 <= value_in[1] & value_in[2];
        p2 <= value_in[3] & value_in[4];        
        p3 <= value_in[5] & value_in[5];
        p4 <= value_in[5] & value_in[3];
        p5 <= value_in[4] & (! (value_in[3])) & (!(value_in[2])) & (!(value_in[1])) & (!(value_in[0]));
        p6 <= value_in[3] & (! (value_in[4])) & (!(value_in[2])) & (!(value_in[1])) & (!(value_in[0]));
        p7 <= value_in[1] & (value_in[2]) & (!(value_in[3])) & (!(value_in[4])) & (!(value_in[0]));
        p8 <= value_in[1] & (value_in[3]) & (!(value_in[2])) & (!(value_in[0]));
        p9 <= value_in[4] & value_in[3] & value_in[1] & value_in[0];
        p10 <= value_in[4] & (!(value_in[3])) & value_in[1] & value_in[0];
        p11 <= value_in[4] & value_in[2] & value_in[1];
        p12 <= value_in[3] & (!(value_in[4])) & value_in[1] & value_in[0];
        p13 <= value_in[3] & value_in[2] & value_in[1];
        p14 <= value_in[3] & (!(value_in[1])) & value_in[0];
        p15 <= value_in[4] & value_in[2] & value_in[0];
        p16 <= value_in[1] & (value_in[4]) & (!(value_in[2])) & (!(value_in[3]));
        p17 <= value_in[1] & (!(value_in[3])) & (!(value_in[2])) & (!(value_in[4]));
        p18 <= value_in[3] & value_in[2] & (!(value_in[4]));
        p19 <= value_in[3] & value_in[2] & value_in[4];
        p20 <= value_in[2] & (!(value_in[3]));
        p21 <= value_in[2] & (!(value_in[4])) & value_in[1] & value_in[0];
        p22 <= value_in[0] & (value_in[2]) & (!(value_in[4])) & (!(value_in[1]));
        p23 <= value_in[4] & (value_in[2]) & (!(value_in[3])) & (!(value_in[1]));
        p24 <= value_in[0] & (value_in[4]) & (!(value_in[2])) & (!(value_in[1]));
        p25 <= value_in[1] & (value_in[4]) & (!(value_in[2])) & (!(value_in[3]));
        p26 <= value_in[4] & value_in[3];
        p27 <= value_in[3] & (value_in[4]) & (!(value_in[2])) &(!(value_in[0]));
                
        temp_out[6] <= 1'b0;
        temp_out[5] <= (p3 | p5 ) | (p8 | p10) | (p11 | p12) | (p13 | p14) | (p15 | p16) | (p18 | p23) | (p24 | p26);
        temp_out[4] <= (p3 | p5) | (p6 | p10) | (p11 | p15) | (p16 | p20) | (p24 | p26);
        temp_out[3] <= (p3 | p6) | (p11 | p13) | (p17 | p18) | (p21 | p26);
        temp_out[2] <= (p3 | p6) | (p7 | p9) | (p12 | p13) | (p16 | p19) | (p23 | p25);
        temp_out[1] <= (p3 | p6) | (p7 | p8) | (p12 | p21) | (p22 | p23) | (p24 | p27);
        temp_out[0] <= (p1 | p2 ) | (p4 | p5) | (p7 | p8) | (p13 | p10) | (p15 | p14) | (p18 | p22);
        
        value_out <= temp_out;    
end

endmodule
