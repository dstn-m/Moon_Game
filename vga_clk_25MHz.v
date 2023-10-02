`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Dustin Matthews
// 
// Create Date: 07/02/2023 02:49:43 PM
// Module Name: vga_clk_25Mhz.v
// Project Name: VGA Controller
// Target Devices: BASYS 3
// Description: 25MHz clock divider down from 100MHz
// Revision:
//////////////////////////////////////////////////////////////////////////////////


module vga_clk_25MHz(
    input clk_i, rst_i,
    output reg clk_o
    );
reg cnt;
  
always @(posedge clk_i)
begin
    if(rst_i) begin
        cnt <= 0;
        clk_o <= 1;
    end
    else begin
        cnt <= cnt + 1;        
    end    
    if (cnt) begin
        clk_o <= ~clk_o;
    end    

end     
endmodule
