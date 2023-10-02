`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/11/2023 07:41:39 PM
// Design Name: 
// Module Name: map_rom
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


module map_rom #(parameter SIZE = 8)
    (
    input clk_i,
    input [SIZE-1:0] mem_addr_i,
    output reg [SIZE-1:0] map_mem_data_o
    );
    
reg[SIZE-1:0] mem_addr;

always @ (posedge clk_i) begin
    mem_addr <= mem_addr_i;            // latch in current address
end    
    
always @*
    case(mem_addr) 
		8'd0: map_mem_data_o = 8'b01111011; // flat @ 3
		8'd1: map_mem_data_o = 8'b01101011; // right edge 3, lwr 1
		8'd2: map_mem_data_o = 8'b00100001; // flat @ 1 
		8'd3: map_mem_data_o = 8'b01001001; // left edge, up 2, lwr 1
		8'd4: map_mem_data_o = 8'b01110001; // left edge, up 3, lwr 2
		8'd5: map_mem_data_o = 8'b01100011; // right edge, upper 3, lwr 0
		8'd6: map_mem_data_o = 8'b00000000;
		8'd7: map_mem_data_o = 8'b01000100; // cube platform @ 2
		8'd8: map_mem_data_o = 8'b00000000;
		8'd9: map_mem_data_o =  8'b01000001; // left edge @ 2
		8'd10: map_mem_data_o = 8'b11110100; // dbl platform
		8'd11: map_mem_data_o = 8'b01001000; // flat @ 2
		8'd12: map_mem_data_o = 8'b01100001; // left edge 
		8'd13: map_mem_data_o = 8'b11111111;
		8'd14: map_mem_data_o = 8'b11111111;
		8'd15: map_mem_data_o = 8'b11111111;
		8'd16: map_mem_data_o = 8'b11111111;
		8'd17: map_mem_data_o = 8'b11111111;
		8'd18: map_mem_data_o = 8'b11111111;
		8'd19: map_mem_data_o = 8'b11111111;
		8'd20: map_mem_data_o = 8'b00000000;
		8'd21: map_mem_data_o = 8'b00000000;
		8'd22: map_mem_data_o = 8'b00000000;
		8'd23: map_mem_data_o = 8'b00000000;
		8'd24: map_mem_data_o = 8'b00000000;
		8'd25: map_mem_data_o = 8'b00000000;
		8'd26: map_mem_data_o = 8'b00000000;
		8'd27: map_mem_data_o = 8'b00000000;
		8'd28: map_mem_data_o = 8'b00000000;
		8'd29: map_mem_data_o = 8'b00000000;
		8'd30: map_mem_data_o = 8'b11111111;
		8'd31: map_mem_data_o = 8'b11111111;
		8'd32: map_mem_data_o = 8'b11111111;
		8'd33: map_mem_data_o = 8'b11111111;
		8'd34: map_mem_data_o = 8'b11111111;
		8'd35: map_mem_data_o = 8'b11111111;
		8'd36: map_mem_data_o = 8'b11111111;
		8'd37: map_mem_data_o = 8'b11111111;
		8'd38: map_mem_data_o = 8'b11111111;
		8'd39: map_mem_data_o = 8'b11111111;
		8'd40: map_mem_data_o = 8'b00000000;
		8'd41: map_mem_data_o = 8'b00000000;
		8'd42: map_mem_data_o = 8'b00000000;
		8'd43: map_mem_data_o = 8'b00000000;
		8'd44: map_mem_data_o = 8'b00000000;
		8'd45: map_mem_data_o = 8'b00000000;
		8'd46: map_mem_data_o = 8'b00000000;
		8'd47: map_mem_data_o = 8'b00000000;
		8'd48: map_mem_data_o = 8'b00000000;
		8'd49: map_mem_data_o = 8'b00000000;
		8'd50: map_mem_data_o = 8'b11111111;
		8'd51: map_mem_data_o = 8'b11111111;
		8'd52: map_mem_data_o = 8'b11111111;
		8'd53: map_mem_data_o = 8'b11111111;
		8'd54: map_mem_data_o = 8'b11111111;
		8'd55: map_mem_data_o = 8'b11111111;
		8'd56: map_mem_data_o = 8'b11111111;
		8'd57: map_mem_data_o = 8'b11111111;
		8'd58: map_mem_data_o = 8'b11111111;
		8'd59: map_mem_data_o = 8'b11111111;
		8'd60: map_mem_data_o = 8'b11111111;
		8'd61: map_mem_data_o = 8'b11111111;
		8'd62: map_mem_data_o = 8'b11111111;
		8'd63: map_mem_data_o = 8'b11111111;
		8'd64: map_mem_data_o = 8'b11111111;
		8'd65: map_mem_data_o = 8'b11111111;
		8'd66: map_mem_data_o = 8'b11111111;
		8'd67: map_mem_data_o = 8'b11111111;
		8'd68: map_mem_data_o = 8'b11111111;
		8'd69: map_mem_data_o = 8'b11111111;
		8'd70: map_mem_data_o = 8'b11111111;
		8'd71: map_mem_data_o = 8'b11111111;
		8'd72: map_mem_data_o = 8'b11111111;
		8'd73: map_mem_data_o = 8'b11111111;
		8'd74: map_mem_data_o = 8'b11111111;
		8'd75: map_mem_data_o = 8'b11111111;
		8'd76: map_mem_data_o = 8'b11111111;
		8'd77: map_mem_data_o = 8'b11111111;
		8'd78: map_mem_data_o = 8'b11111111;
		8'd79: map_mem_data_o = 8'b11111111;
        default: map_mem_data_o = 8'b00000000;     
    endcase      
endmodule
