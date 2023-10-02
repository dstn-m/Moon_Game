`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/16/2023 07:08:33 PM
// Design Name: 
// Module Name: btn_db
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

module btn_db(
    input clk_i, rst_i, btn_i,
    output btn_db_o
    );
reg db1, db2, db3;    
    
always @(posedge clk_i) begin
    if(rst_i) begin
        db1 <= 0;
        db2 <= 0;
        db3 <= 0;
    end    
    else begin
        db1 <= btn_i;
        db2 <= db1;
        db3 <= db2;
    end    
end 

assign btn_db_o = db1 && db2 && db3;    
    
endmodule
