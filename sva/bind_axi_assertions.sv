`timescale 1ns/1ps

// ============================================
// bind_axi_assertions.sv
// Bind AXI protocol assertions to DUT
// ============================================

bind axi2apb_bridge axi4lite_assertions assertions_inst (

    .clk       (clk),
    .rst_n     (rst_n),

    .awvalid   (s_axi_awvalid),
    .awready   (s_axi_awready),

    .wvalid    (s_axi_wvalid),
    .wready    (s_axi_wready),

    .bvalid    (s_axi_bvalid),
    .bready    (s_axi_bready),

    .arvalid   (s_axi_arvalid),
    .arready   (s_axi_arready),

    .rvalid    (s_axi_rvalid),
    .rready    (s_axi_rready)

);