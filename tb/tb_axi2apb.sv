`timescale 1ns/1ps
module tb_axi2apb;

  // Parameters
  parameter int ADDR_WIDTH = 32;
  parameter int DATA_WIDTH = 32;

  // Clock and reset
  logic clk, rst_n;

  // ===== AXI Write Address Channel =====
  logic [ADDR_WIDTH-1:0] s_axi_awaddr;
  logic                  s_axi_awvalid;
  logic                  s_axi_awready;

  // ===== AXI Write Data Channel =====
  logic [DATA_WIDTH-1:0] s_axi_wdata;
  logic [DATA_WIDTH/8-1:0] s_axi_wstrb;
  logic                  s_axi_wvalid;
  logic                  s_axi_wready;

  // ===== AXI Write Response Channel =====
  logic [1:0]            s_axi_bresp;
  logic                  s_axi_bvalid;
  logic                  s_axi_bready;

  // ===== AXI Read Address Channel =====
  logic [ADDR_WIDTH-1:0] s_axi_araddr;
  logic                  s_axi_arvalid;
  logic                  s_axi_arready;

  // ===== AXI Read Data Channel =====
  logic [DATA_WIDTH-1:0] s_axi_rdata;
  logic [1:0]            s_axi_rresp;
  logic                  s_axi_rvalid;
  logic                  s_axi_rready;

  // ===== APB Interface (from DUT to slave) =====
  logic [ADDR_WIDTH-1:0] m_apb_paddr;
  logic                  m_apb_psel;
  logic                  m_apb_penable;
  logic                  m_apb_pwrite;
  logic [DATA_WIDTH-1:0] m_apb_pwdata;
  logic [DATA_WIDTH-1:0] m_apb_prdata;
  logic                  m_apb_pready;
  logic                  m_apb_pslverr;

  // Instantiate DUT
  axi2apb_fsm dut (
    .clk             (clk),
    .rst_n           (rst_n),
    .s_axi_awaddr    (s_axi_awaddr),
    .s_axi_awvalid   (s_axi_awvalid),
    .s_axi_awready   (s_axi_awready),
    .s_axi_wdata     (s_axi_wdata),
    .s_axi_wstrb     (s_axi_wstrb),
    .s_axi_wvalid    (s_axi_wvalid),
    .s_axi_wready    (s_axi_wready),
    .s_axi_bresp     (s_axi_bresp),
    .s_axi_bvalid    (s_axi_bvalid),
    .s_axi_bready    (s_axi_bready),
    .s_axi_araddr    (s_axi_araddr),
    .s_axi_arvalid   (s_axi_arvalid),
    .s_axi_arready   (s_axi_arready),
    .s_axi_rdata     (s_axi_rdata),
    .s_axi_rresp     (s_axi_rresp),
    .s_axi_rvalid    (s_axi_rvalid),
    .s_axi_rready    (s_axi_rready),

    // APB master side (outputs to slave model)
    .m_apb_paddr    (m_apb_paddr),
    .m_apb_psel     (m_apb_psel),
    .m_apb_penable  (m_apb_penable),
    .m_apb_pwrite   (m_apb_pwrite),
    .m_apb_pwdata   (m_apb_pwdata),
    .m_apb_prdata   (m_apb_prdata),
    .m_apb_pready   (m_apb_pready),
    .m_apb_pslverr  (m_apb_pslverr)
  );

  // Instantiate APB slave model (Layer 1)
  apb_slave_model #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .MEM_DEPTH(16),
    .WAIT_CYCLES(1)
 
)
apb_inst (

  .pclk       (clk),
  .preset_n   (rst_n),

  .paddr      (m_apb_paddr),
  .psel       (m_apb_psel),
  .penable    (m_apb_penable),
  .pwrite     (m_apb_pwrite),
  .pwdata     (m_apb_pwdata),

  .prdata     (m_apb_prdata),
  .pready     (m_apb_pready),
  .pslverr    (m_apb_pslverr),

  .err_inject (1'b0)

);
  

  // Clock generation
  always #5 clk = ~clk;

  // Basic reset sequence and stimulus (Layer 2)
  initial begin
    // Initialize signals
    clk = 0;
    rst_n = 0;
    s_axi_awaddr  = 0;
    s_axi_awvalid = 0;
    s_axi_wdata   = 0;
    s_axi_wstrb   = {DATA_WIDTH/8{1'b1}};
    s_axi_wvalid  = 0;
    s_axi_bready  = 1;
    s_axi_araddr  = 0;
    s_axi_arvalid = 0;
    s_axi_rready  = 1;

    // Deassert reset
    #20;
    rst_n = 1;

    // ********** WRITE TRANSACTION **********
    @(posedge clk);
    s_axi_awaddr  <= 32'h0000_1000;
    s_axi_awvalid <= 1;
    s_axi_wdata   <= 32'hDEAD_BEEF;
    s_axi_wvalid  <= 1;
    // Wait for write handshake
    wait (s_axi_awready && s_axi_wready);
    @(posedge clk);
    s_axi_awvalid <= 0;
    s_axi_wvalid  <= 0;
    // Wait for write response
    wait (s_axi_bvalid);
    @(posedge clk);

    // ********** READ TRANSACTION ***********
    s_axi_araddr  <= 32'h0000_1000;
    s_axi_arvalid <= 1;
    wait (s_axi_arready);
    @(posedge clk);
    s_axi_arvalid <= 0;
    // Wait for read data
    wait (s_axi_rvalid);
    @(posedge clk);

    // All done
    #50;
    $finish;
  end
endmodule
