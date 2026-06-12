`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/30/2020 07:25:49 PM
// Design Name: 
// Module Name: lineBuffer
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

(* use_dsp = "yes" *)

module lineBuffer #(
    parameter LINE_WIDTH  = 640,
    parameter KERNEL_SIZE = 3
)(
    input  i_clk,
    input  i_rst,
    input  [7:0] i_data,
    input  i_data_valid,
    input  i_rd_data,
    output reg [(KERNEL_SIZE*8)-1:0] o_data
);

    (* ram_style = "block" *)
    reg [7:0] line [0:LINE_WIDTH-1];

    localparam PTR_W = $clog2(LINE_WIDTH);
    reg [PTR_W-1:0] wr_ptr, rd_ptr;

    integer i;

    // Write
    always @(posedge i_clk) begin
        if(i_rst)
            wr_ptr <= 0;
        else if(i_data_valid) begin
            line[wr_ptr] <= i_data;
            wr_ptr <= (wr_ptr == LINE_WIDTH-1) ? 0 : wr_ptr + 1;
        end
    end

    // Read
    always @(posedge i_clk) begin
        if(i_rst)
            rd_ptr <= 0;
        else if(i_rd_data)
            rd_ptr <= (rd_ptr == LINE_WIDTH-1) ? 0 : rd_ptr + 1;
    end

    // Output KERNEL_SIZE horizontal pixels
    always @(posedge i_clk) begin
        for(i=0; i<KERNEL_SIZE; i=i+1)
            o_data[(KERNEL_SIZE-i)*8-1 -: 8] <= line[rd_ptr + i];
    end

endmodule
