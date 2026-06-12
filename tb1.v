`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/04/2026 09:38:24 PM
// Design Name: 
// Module Name: tb1
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


`define headerSize 1080

module tb;

    parameter LINE_WIDTH = 640;
    parameter LINE_HEIGHT = 480;

    parameter KERNEL_SIZE = 3;  // Any filter size can be selected e.g; 5 7 9 and so on, for blur filter but for edge detection and negative filter only value 3 should be given
    parameter integer FILTER_MODE = 1; // filter Mode has three values 0,1 and 2, if 0 is given the blur filter will be applied, for 1 edge detection will be applied and for value 2 negative filter will be applied

    localparam IMAGE_SIZE = LINE_WIDTH * LINE_HEIGHT;
    localparam OUT_PIXELS = (LINE_WIDTH)*(LINE_HEIGHT);

    reg clk;
    reg reset;
    reg [7:0] imgData;
    reg imgDataValid;
    integer file, file1, i;
    integer sentSize;
    integer receivedData;

    wire [7:0] outData;
    wire outDataValid;
    wire intr;
    
    

    // Clock generation
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    initial begin
        reset = 0;
        imgDataValid = 0;
        sentSize = 0;
        receivedData = 0;
        #100;
        reset = 1;
        #100;

        file  = $fopen("640x480.bmp","rb");
        file1 = $fopen("edge_640x480.bmp","wb");

        // Copy BMP header
        for(i=0;i<`headerSize;i=i+1) begin
            $fscanf(file,"%c",imgData);
            $fwrite(file1,"%c",imgData);
        end

        // Send first chunk
        for(i=0;i<(KERNEL_SIZE + 1)*LINE_WIDTH;i=i+1) begin
            @(posedge clk);
            $fscanf(file,"%c",imgData);
            imgDataValid <= 1'b1;
        end
        @(posedge clk);
        imgDataValid <= 1'b0;
        sentSize = (KERNEL_SIZE + 1)*LINE_WIDTH;

        // Send remaining image data in chunks
        while(sentSize < IMAGE_SIZE) begin
            @(posedge intr);
            for(i=0;i<LINE_WIDTH;i=i+1) begin
                @(posedge clk);
                $fscanf(file,"%c",imgData);
                imgDataValid <= 1'b1;
                sentSize = sentSize + 1;
            end
            @(posedge clk);
            imgDataValid <= 1'b0;
        end

        // Send zeros to flush line buffer (2 lines for 3x3 kernel)
        repeat(2) begin
           @(posedge intr);
        for(i=0;i<LINE_WIDTH;i=i+1) begin
            @(posedge clk);
            imgDataValid <= 1'b1;
        end
        @(posedge clk);
        imgDataValid <= 1'b0;
        end

        $fclose(file);
    end

    // Capture output data
    always @(posedge clk) begin
        if(outDataValid) begin
            $fwrite(file1,"%c",outData);
            receivedData = receivedData + 1;
        end
        if(receivedData == OUT_PIXELS) begin
            $fclose(file1);
            $stop;
        end
    end

    // DUT instantiation
    imageProcessTop #(
     .LINE_WIDTH(LINE_WIDTH),
    .KERNEL_SIZE(KERNEL_SIZE),
    .FILTER_MODE(FILTER_MODE)
    ) dut (
        .axi_clk(clk),
        .axi_reset_n(reset),
        .i_data_valid(imgDataValid),
        .i_data(imgData),
        .o_data_ready(),
        .o_data_valid(outDataValid),
        .o_data(outData),
        .i_data_ready(1'b1),
        .o_intr(intr)
    );

endmodule
