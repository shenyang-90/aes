//============================================================================
// Module: axi4_stream_if
// Description: AXI4-Stream Interface for AES IP data flow
//============================================================================
`timescale 1ns / 1ps

module axi4_stream_if (
    input  wire        clk,
    input  wire        rst_n,
    
    // AXI4-Stream Slave (Input)
    input  wire [127:0] s_axis_tdata,
    input  wire         s_axis_tvalid,
    output wire         s_axis_tready,
    input  wire         s_axis_tlast,
    input  wire [15:0]  s_axis_tuser,
    
    // AXI4-Stream Master (Output)
    output reg  [127:0] m_axis_tdata,
    output reg          m_axis_tvalid,
    input  wire         m_axis_tready,
    output reg          m_axis_tlast,
    output reg  [15:0]  m_axis_tuser,
    
    // Internal Data Interface
    output reg  [127:0] rx_data,
    output reg          rx_valid,
    input  wire         rx_ready,
    input  wire [127:0] tx_data,
    input  wire         tx_valid,
    output reg          tx_ready
);

    // RX Buffer
    reg [127:0] rx_buffer;
    reg         rx_buffer_valid;
    
    assign s_axis_tready = !rx_buffer_valid || rx_ready;
    
    // RX Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_buffer_valid <= 1'b0;
            rx_valid <= 1'b0;
        end else begin
            rx_valid <= 1'b0;
            
            if (s_axis_tvalid && s_axis_tready) begin
                rx_buffer <= s_axis_tdata;
                rx_buffer_valid <= 1'b1;
            end else if (rx_ready && rx_buffer_valid) begin
                rx_buffer_valid <= 1'b0;
            end
            
            if (rx_buffer_valid && rx_ready) begin
                rx_data <= rx_buffer;
                rx_valid <= 1'b1;
            end
        end
    end
    
    // TX Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
            tx_ready <= 1'b0;
        end else begin
            tx_ready <= m_axis_tready && !m_axis_tvalid;
            
            if (tx_valid && tx_ready) begin
                m_axis_tdata <= tx_data;
                m_axis_tvalid <= 1'b1;
                m_axis_tlast <= 1'b1;  // Single beat
            end else if (m_axis_tvalid && m_axis_tready) begin
                m_axis_tvalid <= 1'b0;
                m_axis_tlast <= 1'b0;
            end
        end
    end

endmodule
