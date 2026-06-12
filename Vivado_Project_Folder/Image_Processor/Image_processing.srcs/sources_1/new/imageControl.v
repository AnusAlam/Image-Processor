`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/01/2020 10:53:27 AM
// Design Name: 
// Module Name: imageControl
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

module imageControl #(
    parameter LINE_WIDTH  = 640,
    parameter KERNEL_SIZE = 3
)(
    input  i_clk,
    input  i_rst,
    input  [7:0] i_pixel_data,
    input  i_pixel_data_valid,

    output reg [(KERNEL_SIZE*KERNEL_SIZE*8)-1:0] o_pixel_data,
    output o_pixel_data_valid,
    output reg o_intr
);

    // -------------------------------------------------
    // PARAMETERS
    // -------------------------------------------------
    localparam NUM_BUFFERS = KERNEL_SIZE + 1;
    localparam PTR_W = $clog2(LINE_WIDTH);

    // -------------------------------------------------
    // WRITE SIDE
    // -------------------------------------------------
    reg [$clog2(NUM_BUFFERS)-1:0] wr_buf;
    reg [PTR_W-1:0] pixel_cnt;

    // -------------------------------------------------
    // READ SIDE
    // -------------------------------------------------
    reg [$clog2(NUM_BUFFERS)-1:0] rd_start_buf;
    reg [PTR_W-1:0] rd_cnt;
    reg rd_en, rd_en_d;

    // -------------------------------------------------
    // CONTROL
    // -------------------------------------------------
    reg [31:0] total_pixel_cnt;
    reg state;

    localparam IDLE = 1'b0,
               READ = 1'b1;

    // -------------------------------------------------
    // LINE BUFFERS
    // -------------------------------------------------
    wire [(KERNEL_SIZE*8)-1:0] lb_data [0:NUM_BUFFERS-1];
    reg  [NUM_BUFFERS-1:0] lb_wr_en;
    reg  [NUM_BUFFERS-1:0] lb_rd_en;

    integer i, j;

    assign o_pixel_data_valid = rd_en_d;

    // -------------------------------------------------
    // TOTAL PIXEL COUNT
    // -------------------------------------------------
    always @(posedge i_clk)
        if(i_rst) total_pixel_cnt <= 0;
        else if(i_pixel_data_valid)
            total_pixel_cnt <= total_pixel_cnt + 1;

    // -------------------------------------------------
    // PIXEL COUNTER (PER LINE)
    // -------------------------------------------------
    always @(posedge i_clk)
        if(i_rst) pixel_cnt <= 0;
        else if(i_pixel_data_valid)
            pixel_cnt <= (pixel_cnt == LINE_WIDTH-1) ? 0 : pixel_cnt + 1;

    // -------------------------------------------------
    // WRITE BUFFER ROTATION
    // -------------------------------------------------
    always @(posedge i_clk)
        if(i_rst) wr_buf <= 0;
        else if(i_pixel_data_valid && pixel_cnt == LINE_WIDTH-1)
            wr_buf <= (wr_buf == NUM_BUFFERS-1) ? 0 : wr_buf + 1;

    // -------------------------------------------------
    // WRITE ENABLES (ONLY ONE BUFFER)
    // -------------------------------------------------
    always @(*) begin
        lb_wr_en = {NUM_BUFFERS{1'b0}};
        lb_wr_en[wr_buf] = i_pixel_data_valid;
    end

    // -------------------------------------------------
    // READ FSM (DESIGN-1 STYLE)
    // -------------------------------------------------
    always @(posedge i_clk) begin
        if(i_rst) begin
            state <= IDLE;
            rd_en <= 0;
            rd_cnt <= 0;
            rd_start_buf <= 0;
            o_intr <= 0;
        end else begin
            case(state)
                IDLE: begin
                    rd_en <= 0;
                    o_intr <= 0;
                    if(total_pixel_cnt >= (KERNEL_SIZE+1)*LINE_WIDTH) begin
                        // oldest buffer = write buffer minus kernel depth
                        rd_start_buf <= (wr_buf + NUM_BUFFERS - KERNEL_SIZE) % NUM_BUFFERS;
                        rd_cnt <= 0;
                        rd_en <= 1;
                        state <= READ;
                    end
                end

                READ: begin
                    if(rd_cnt == LINE_WIDTH-1) begin
                        rd_cnt <= 0;
                        rd_en <= 0;
                        o_intr <= 1;
                        state <= IDLE;
                    end else begin
                        rd_cnt <= rd_cnt + 1;
                    end
                end
            endcase
        end
    end

    // -------------------------------------------------
    // READ ENABLES (KERNEL BUFFERS ONLY)
    // -------------------------------------------------
    always @(*) begin
        lb_rd_en = {NUM_BUFFERS{1'b0}};
        if(rd_en)
            for(i=0;i<KERNEL_SIZE;i=i+1)
                lb_rd_en[(rd_start_buf+i)%NUM_BUFFERS] = 1'b1;
    end

    // -------------------------------------------------
    // PIPELINE READ ENABLE (RAM LATENCY)
    // -------------------------------------------------
    always @(posedge i_clk)
        rd_en_d <= rd_en;

    // -------------------------------------------------
    // WINDOW ASSEMBLY (CORRECT ORDER)
    // -------------------------------------------------
    always @(posedge i_clk) begin
        if(rd_en_d) begin
            for(i=0;i<KERNEL_SIZE;i=i+1)
                for(j=0;j<KERNEL_SIZE;j=j+1)
                    o_pixel_data[((KERNEL_SIZE-i-1)*KERNEL_SIZE + j)*8 +: 8]
                        <= lb_data[(rd_start_buf+i)%NUM_BUFFERS]
                           [(KERNEL_SIZE-j-1)*8 +: 8];
        end
    end

    // -------------------------------------------------
    // LINE BUFFER INSTANTIATION
    // -------------------------------------------------
    genvar k;
    generate
        for(k=0;k<NUM_BUFFERS;k=k+1) begin : LBS
            lineBuffer #(
                .LINE_WIDTH(LINE_WIDTH),
                .KERNEL_SIZE(KERNEL_SIZE)
            ) LB (
                .i_clk(i_clk),
                .i_rst(i_rst),
                .i_data(i_pixel_data),
                .i_data_valid(lb_wr_en[k]),
                .i_rd_data(lb_rd_en[k]),
                .o_data(lb_data[k])
            );
        end
    endgenerate

endmodule

