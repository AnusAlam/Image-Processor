`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/31/2020 10:09:05 PM
// Design Name: 
// Module Name: conv
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

module conv_edge #(
    parameter KERNEL_SIZE = 3,                     // 3x3 kernel
    parameter PIXEL_WIDTH = 8,                     // pixel bit width
    parameter KERNEL_VAL  = 1                      // default kernel weight
)(
    input                         i_clk,
    input  [KERNEL_SIZE*KERNEL_SIZE*PIXEL_WIDTH-1:0] i_pixel_data,
    input                         i_pixel_data_valid,
    output reg [PIXEL_WIDTH-1:0]  o_convolved_data,
    output reg                    o_convolved_data_valid
);

    integer i;
    reg [PIXEL_WIDTH-1:0] kernel1 [0:KERNEL_SIZE*KERNEL_SIZE-1];
    reg [PIXEL_WIDTH-1:0] kernel2 [0:KERNEL_SIZE*KERNEL_SIZE-1];
    reg [(2*PIXEL_WIDTH)-1:0] multData1 [0:KERNEL_SIZE*KERNEL_SIZE-1];
    reg [(2*PIXEL_WIDTH)-1:0] multData2 [0:KERNEL_SIZE*KERNEL_SIZE-1];
    reg [(2*PIXEL_WIDTH)-1:0] sumDataInt1;
    reg [(2*PIXEL_WIDTH)-1:0] sumDataInt2;  // wide enough to avoid overflow
    reg [(2*PIXEL_WIDTH)-1:0] sumData1;
    reg [(2*PIXEL_WIDTH)-1:0] sumData2;
    reg multDataValid;
    reg sumDataValid;
    reg convolved_data_valid;
    reg [(3*PIXEL_WIDTH)-1:0] convolved_data_int1;
    reg [(3*PIXEL_WIDTH)-1:0] convolved_data_int2;
    wire [(3*PIXEL_WIDTH)-1:0] convolved_data_int;
    reg convolved_data_int_valid;

    // Initialize kernel with default value
    initial begin
        kernel1[0] =  1;
        kernel1[1] =  0;
        kernel1[2] = -1;
        kernel1[3] =  2;
        kernel1[4] =  0;
        kernel1[5] = -2;
        kernel1[6] =  1;
        kernel1[7] =  0;
        kernel1[8] = -1;
        
        kernel2[0] =  1;
        kernel2[1] =  2;
        kernel2[2] =  1;
        kernel2[3] =  0;
        kernel2[4] =  0;
        kernel2[5] =  0;
        kernel2[6] = -1;
        kernel2[7] = -2;
        kernel2[8] = -1;
    
    end
    
    // Multiply each pixel by kernel
   always @(posedge i_clk) begin
        for (i = 0; i < KERNEL_SIZE*KERNEL_SIZE; i = i + 1) begin
            multData1[i] <= $signed(kernel1[i]) * $signed({1'b0, i_pixel_data[i*PIXEL_WIDTH +: PIXEL_WIDTH]});
            multData2[i] <= $signed(kernel2[i]) * $signed({1'b0, i_pixel_data[i*PIXEL_WIDTH +: PIXEL_WIDTH]});
   
        end
        multDataValid <= i_pixel_data_valid;
    end

    // Sum products (combinational)
    always @(*) begin
        sumDataInt1 = 0;
        sumDataInt2 = 0;
        for (i = 0; i < KERNEL_SIZE*KERNEL_SIZE; i = i + 1) begin
            sumDataInt1 = $signed(sumDataInt1) + $signed(multData1[i]);
            sumDataInt2 = $signed(sumDataInt2) + $signed(multData2[i]);
        end
    end

    // Register sum
    always @(posedge i_clk) begin
        sumData1 <= sumDataInt1;
        sumData2 <= sumDataInt2;
        sumDataValid <= multDataValid;
    end

    // Divide by kernel size
    always @(posedge i_clk) begin
        convolved_data_int1 <= $signed(sumData1) * $signed(sumData1);
        convolved_data_int2 <= $signed(sumData2) * $signed(sumData2);
        convolved_data_int_valid <= sumDataValid;
    end

assign convolved_data_int = convolved_data_int1 + convolved_data_int2;

always @(posedge i_clk) begin
    if(convolved_data_int > 4000)
        o_convolved_data <= 8'hff;
    else
        o_convolved_data <= 8'h00;
    o_convolved_data_valid <= convolved_data_int_valid;
end

endmodule
