`timescale 1ns / 1ps

module imageProcessTop #(
    parameter LINE_WIDTH = 640,   // Pixels per line, change for any resolution
    parameter KERNEL_SIZE = 3,      // N for NxN kernel (must be odd)
    parameter integer FILTER_MODE = 0
)(
    input   axi_clk,
    input   axi_reset_n,
    // Slave interface
    input   i_data_valid,
    input  [7:0] i_data,
    output  o_data_ready,
    // Master interface
    output  o_data_valid,
    output [7:0] o_data,
    input   i_data_ready,
    // Interrupt
    output  o_intr
);
    
    // Pixel data width from imageControl (KERNEL_SIZE x KERNEL_SIZE pixels)
    localparam PIXEL_DATA_WIDTH = KERNEL_SIZE * KERNEL_SIZE * 8;
    
    wire [PIXEL_DATA_WIDTH-1:0] pixel_data;
    wire pixel_data_valid;
    wire axis_prog_full;
    wire [7:0] convolved_data;
    wire convolved_data_valid;

    // Ready when output buffer is not full
    assign o_data_ready = !axis_prog_full;
    
    // Pass LINE_WIDTH down so lower modules know the resolution
    imageControl #(
        .LINE_WIDTH(LINE_WIDTH),
        .KERNEL_SIZE(KERNEL_SIZE)
    ) IC (
        .i_clk(axi_clk),
        .i_rst(!axi_reset_n),
        .i_pixel_data(i_data),
        .i_pixel_data_valid(i_data_valid),
        .o_pixel_data(pixel_data),
        .o_pixel_data_valid(pixel_data_valid),
        .o_intr(o_intr)
    );    
  
filter_select #(
        .FILTER_MODE(FILTER_MODE),
        .KERNEL_SIZE(KERNEL_SIZE)
    ) filter_inst (
        .i_clk(axi_clk),
        .i_pixel_data(pixel_data),
        .i_pixel_data_valid(pixel_data_valid),
        .o_data(convolved_data),
        .o_data_valid(convolved_data_valid)
    );

 
    outputBuffer OB (
        .wr_rst_busy(),        // output wire wr_rst_busy
        .rd_rst_busy(),        // output wire rd_rst_busy
        .s_aclk(axi_clk),                  // input wire s_aclk
        .s_aresetn(axi_reset_n),            // input wire s_aresetn
        .s_axis_tvalid(convolved_data_valid),    // input wire s_axis_tvalid
        .s_axis_tready(),                   // output wire s_axis_tready
        .s_axis_tdata(convolved_data),      // input wire [7 : 0] s_axis_tdata
        .m_axis_tvalid(o_data_valid),       // output wire m_axis_tvalid
        .m_axis_tready(i_data_ready),       // input wire m_axis_tready
        .m_axis_tdata(o_data),              // output wire [7 : 0] m_axis_tdata
        .axis_prog_full(axis_prog_full)     // output wire axis_prog_full
    );
   
endmodule

    
        

