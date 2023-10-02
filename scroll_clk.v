`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/11/2023 07:47:52 PM
// Design Name: 
// Module Name: scroll_clk
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


module scroll_clk(
    input clk_i, rst_i,
    output clk_1k_o, clk_scroll_o
    );
reg[15:0] cnt_1kHz = 50000, cnt_fst;
reg[8:0] cnt_walk = 66, cnt_slo; // .1 second
reg toggle_fst = 1;
reg toggle_slo = 1;
    
always @(posedge clk_i)
begin
    if(rst_i) begin
        cnt_fst <= 0; 
        cnt_slo <= 0;
    end
    else if (cnt_fst == cnt_1kHz) begin
        cnt_fst <= 0; 
        toggle_fst <= ~toggle_fst;
        if(cnt_slo == cnt_walk) begin
            cnt_slo <= 0;
            toggle_slo <= ~ toggle_slo;
        end
        else begin
            cnt_slo <= cnt_slo + 1;
        end      
    end      
    else begin 
        cnt_fst <= cnt_fst + 1;
    end    
end                   
    
assign clk_1k_o = toggle_fst; 
assign clk_scroll_o = toggle_slo;
    

endmodule
