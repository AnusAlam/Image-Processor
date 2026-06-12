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

module conv_blur #(
    parameter KERNEL_SIZE = 3,                     // kernel
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
    reg [PIXEL_WIDTH-1:0] kernel [0:KERNEL_SIZE*KERNEL_SIZE-1];
    reg [(2*PIXEL_WIDTH)-1:0] multData [0:KERNEL_SIZE*KERNEL_SIZE-1];
    reg [19:0] sumDataInt;  // wide enough to avoid overflow
    reg [19:0] sumData;
    reg multDataValid;
    reg sumDataValid;
    
    // Pipeline registers
    reg [PIXEL_WIDTH-1:0] pixel_reg [0:KERNEL_SIZE*KERNEL_SIZE-1];
    reg pixel_valid_reg;

    // Initialize kernel with default value
    initial begin
        for (i = 0; i < KERNEL_SIZE*KERNEL_SIZE; i = i + 1) begin
            kernel[i] = KERNEL_VAL;
        end
    end    

    // Register input pixels
    always @(posedge i_clk) begin
        pixel_valid_reg <= i_pixel_data_valid;
        for (i = 0; i < KERNEL_SIZE*KERNEL_SIZE; i = i + 1) begin
            pixel_reg[i] <= i_pixel_data[i*PIXEL_WIDTH +: PIXEL_WIDTH];
        end
    end

    // Multiply each pixel by kernel
    always @(posedge i_clk) begin
        for (i = 0; i < KERNEL_SIZE*KERNEL_SIZE; i = i + 1) begin
            multData[i] <= kernel[i] * pixel_reg[i];
        end
        multDataValid <= pixel_valid_reg;
    end

    // Sum products (combinational)
    always @(*) begin
        sumDataInt = 0;
        for (i = 0; i < KERNEL_SIZE*KERNEL_SIZE; i = i + 1) begin
            sumDataInt = sumDataInt + multData[i];
        end
    end

    // Register sum
    always @(posedge i_clk) begin
        sumData <= sumDataInt;
        sumDataValid <= multDataValid;
    end

    // Divide by kernel size
    always @(posedge i_clk) begin
        o_convolved_data <= sumData / (KERNEL_SIZE*KERNEL_SIZE);
        o_convolved_data_valid <= sumDataValid;
    end

endmodule
