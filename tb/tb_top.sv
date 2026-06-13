`timescale 1ns/1ps


import uvm_pkg::*;
`include <uvm_macros.svh>
`include "axi4lite_test.sv"  // Loads UVM environment classes & registers them with the factory




module tb_top;

    // ========================================
    // Clock / Reset
    // ========================================

    logic clk;
    logic rst_n;

    initial clk = 0;

    always #5 clk = ~clk;

    // ========================================
    // APB Signals
    // ========================================

    logic [31:0] paddr;
    logic [31:0] pwdata;
    logic [31:0] prdata;

    logic [3:0] psel;

    logic penable;
    logic pwrite;
    logic pready;
    logic pslverr;

    logic err_inject;

    // ========================================
    // Interface
    // ========================================

    axi4lite_if axi_if(
        .clk   (clk),
        .rst_n (rst_n)
    );

    // ========================================
    // DUT
    // ========================================

    axi2apb_bridge #(
        .ADDR_WIDTH (32),
        .DATA_WIDTH (32),
        .NUM_SLAVES (4)
    ) dut (

        .clk              (clk),
        .rst_n            (rst_n),

        // AXI4-Lite Slave Interface

        .s_axi_awaddr     (axi_if.awaddr),
        .s_axi_awvalid    (axi_if.awvalid),
        .s_axi_awready    (axi_if.awready),

        .s_axi_wdata      (axi_if.wdata),
        .s_axi_wstrb      (axi_if.wstrb),
        .s_axi_wvalid     (axi_if.wvalid),
        .s_axi_wready     (axi_if.wready),

        .s_axi_bresp      (axi_if.bresp),
        .s_axi_bvalid     (axi_if.bvalid),
        .s_axi_bready     (axi_if.bready),

        .s_axi_araddr     (axi_if.araddr),
        .s_axi_arvalid    (axi_if.arvalid),
        .s_axi_arready    (axi_if.arready),

        .s_axi_rdata      (axi_if.rdata),
        .s_axi_rresp      (axi_if.rresp),
        .s_axi_rvalid     (axi_if.rvalid),
        .s_axi_rready     (axi_if.rready),

        // APB Master Interface

        .m_apb_paddr      (paddr),
        .m_apb_psel       (psel),
        .m_apb_penable    (penable),
        .m_apb_pwrite     (pwrite),
        .m_apb_pwdata     (pwdata),
        .m_apb_prdata     (prdata),
        .m_apb_pready     (pready),
        .m_apb_pslverr    (pslverr)

    );

    // ========================================
    // APB Slave Models
    // ========================================

    wire pready_s[4];
    wire pslverr_s[4];
    wire [31:0] prdata_s[4];
    wire err_inject_s[4];

    // Connect error injection to the Timer slave to trigger SLVERR responses
    assign err_inject_s[0] = 1'b0;
    assign err_inject_s[1] = 1'b0;
    assign err_inject_s[2] = 1'b0;
    assign err_inject_s[3] = 1'b1; // Slave 3 (Timer) always returns SLVERR

    genvar i;
    generate
        for (i = 0; i < 4; i++) begin : apb_slaves
            apb_slave_model #(
                .ADDR_WIDTH (32),
                .DATA_WIDTH (32),
                .MEM_DEPTH  (16),
                .WAIT_CYCLES(1)
            ) slave_inst (
                .pclk        (clk),
                .preset_n    (rst_n),
                .paddr       (paddr),
                .psel        (psel[i]),
                .penable     (penable),
                .pwrite      (pwrite),
                .pwdata      (pwdata),
                .prdata      (prdata_s[i]),
                .pready      (pready_s[i]),
                .pslverr     (pslverr_s[i]),
                .err_inject  (err_inject_s[i])
            );
        end
    endgenerate

    // Combine slave outputs
    assign pready = pready_s[0] | pready_s[1] | pready_s[2] | pready_s[3];
    assign pslverr = pslverr_s[0] | pslverr_s[1] | pslverr_s[2] | pslverr_s[3];
    assign prdata = (psel[0]) ? prdata_s[0] :
                    (psel[1]) ? prdata_s[1] :
                    (psel[2]) ? prdata_s[2] :
                    (psel[3]) ? prdata_s[3] : 32'h0;

    // ========================================
    // Reset
    // ========================================

    initial begin

        rst_n = 1'b0;

        repeat(10)
            @(posedge clk);

        rst_n = 1'b1;

    end

    // ========================================
    // Pass VIF
    // ========================================

    initial begin

        uvm_config_db#(
            virtual axi4lite_if
        )::set(

            uvm_root::get(),
            "uvm_test_top.*",
            "vif",
            axi_if

        );

   run_test();

    end

    // ========================================
    // Timeout
    // ========================================


    initial begin
    #20_000_000;
    $display("Simulation Timeout");
    $finish;
end

    

    // ========================================
    // Wave Dump
    // ========================================

    initial begin

        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);

    end

endmodule