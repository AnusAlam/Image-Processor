`timescale 1ns / 1ps

module filter_select #(
    parameter integer FILTER_MODE = 0,
    parameter KERNEL_SIZE = 3,
    parameter integer PIXEL_WIDTH = 8
)(
    input  wire                        i_clk,
    input  wire [KERNEL_SIZE*KERNEL_SIZE*PIXEL_WIDTH-1:0] i_pixel_data,
    input  wire                        i_pixel_data_valid,
    output wire [PIXEL_WIDTH-1:0]      o_data,
    output wire                        o_data_valid
);


generate
    if (FILTER_MODE == 0) begin : GEN_BLUR
        conv_blur #(
            .KERNEL_SIZE(KERNEL_SIZE)
            ) blur_inst (
            .i_clk(i_clk),
            .i_pixel_data(i_pixel_data),
            .i_pixel_data_valid(i_pixel_data_valid),
            .o_convolved_data(o_data),
            .o_convolved_data_valid(o_data_valid)
        );
    end
    else if (FILTER_MODE == 1) begin : GEN_EDGE
        conv_edge  #(
            .KERNEL_SIZE(KERNEL_SIZE)
            ) edge_inst (
            .i_clk(i_clk),
            .i_pixel_data(i_pixel_data),
            .i_pixel_data_valid(i_pixel_data_valid),
            .o_convolved_data(o_data),
            .o_convolved_data_valid(o_data_valid)
        );
    end
    else if (FILTER_MODE == 2) begin : GEN_NEGATIVE
        conv_negative  #(
            .KERNEL_SIZE(KERNEL_SIZE)
            ) neg_inst (
            .i_clk(i_clk),
            .i_pixel_data(i_pixel_data),
            .i_pixel_data_valid(i_pixel_data_valid),
            .o_convolved_data(o_data),
            .o_convolved_data_valid(o_data_valid)
        );
    end
endgenerate

endmodule
