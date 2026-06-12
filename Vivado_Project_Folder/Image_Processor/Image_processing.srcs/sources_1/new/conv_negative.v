`timescale 1ns / 1ps

(* use_dsp = "yes" *)

module conv_negative #(
    parameter KERNEL_SIZE = 3,
    parameter PIXEL_WIDTH = 8
)(
    input  wire                                 i_clk,
    input  wire [KERNEL_SIZE*KERNEL_SIZE*PIXEL_WIDTH-1:0] i_pixel_data,
    input  wire                                 i_pixel_data_valid,
    output reg  [PIXEL_WIDTH-1:0]               o_convolved_data,
    output reg                                  o_convolved_data_valid
);
    
    // Extract center pixel from the 3×3 window
    wire [PIXEL_WIDTH-1:0] center_pixel;
    assign center_pixel = i_pixel_data[4*PIXEL_WIDTH +: PIXEL_WIDTH];  // Index 4 is center (0-8)
    
    // Pipeline registers for timing
    reg [PIXEL_WIDTH-1:0] center_pixel_reg;
    reg valid_reg;
    
    always @(posedge i_clk) begin
        // Register inputs
        center_pixel_reg <= center_pixel;
        valid_reg <= i_pixel_data_valid;
        
        // Apply negative filter: 255 - pixel
        o_convolved_data <= {PIXEL_WIDTH{1'b1}} - center_pixel_reg;
        
        // Pass through valid signal
        o_convolved_data_valid <= valid_reg;
    end
    
endmodule
