

import axi2apb_pkg::*;

module axi2apb_fsm #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 32
)(
  input  logic clk, rst_n,

  // AXI WRITE ADDRESS
  input  logic [ADDR_WIDTH-1:0] s_axi_awaddr,
  input  logic s_axi_awvalid,
  output logic s_axi_awready,

  // AXI WRITE DATA
  input  logic [DATA_WIDTH-1:0] s_axi_wdata,
  input  logic [3:0] s_axi_wstrb,
  input  logic s_axi_wvalid,
  output logic s_axi_wready,

  // AXI WRITE RESPONSE
  output logic [1:0] s_axi_bresp,
  output logic s_axi_bvalid,
  input  logic s_axi_bready,

  // AXI READ ADDRESS
  input  logic [ADDR_WIDTH-1:0] s_axi_araddr,
  input  logic s_axi_arvalid,
  output logic s_axi_arready,

  // AXI READ DATA
  output logic [DATA_WIDTH-1:0] s_axi_rdata,
  output logic [1:0] s_axi_rresp,
  output logic s_axi_rvalid,
  input  logic s_axi_rready,

  // APB INTERFACE
  output logic [ADDR_WIDTH-1:0] m_apb_paddr,
  output logic m_apb_psel,
  output logic m_apb_penable,
  output logic m_apb_pwrite,
  output logic [DATA_WIDTH-1:0] m_apb_pwdata,
  input  logic [DATA_WIDTH-1:0] m_apb_prdata,
  input  logic m_apb_pready,
  input  logic m_apb_pslverr
);

  
  // Internal Signals


  apb_state_t state, next_state;

  logic [ADDR_WIDTH-1:0] addr_latch;
  logic [DATA_WIDTH-1:0] wdata_latch;
  logic [3:0] wstrb_latch;

  logic aw_captured, w_captured;
  logic is_write;

  logic apb_done;
  assign apb_done = m_apb_psel && m_apb_penable && m_apb_pready;

 
  // READY Logic (Correct)
 
  assign s_axi_awready = (state == IDLE) && !aw_captured;
  assign s_axi_wready  = (state == IDLE) && !w_captured;
  assign s_axi_arready = (state == IDLE) && !aw_captured && !w_captured;

 
 
  // Capture WRITE ADDRESS
  
  
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      addr_latch  <= '0;
      aw_captured <= 0;
    end else begin
      if (s_axi_awvalid && s_axi_awready) begin
        addr_latch  <= s_axi_awaddr;
        aw_captured <= 1;
      end

      if (apb_done && is_write)
        aw_captured <= 0;
    end
  end

 
 
  // Capture WRITE DATA
  
  
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wdata_latch <= '0;
      wstrb_latch <= '0;
      w_captured  <= 0;
    end else begin
      if (s_axi_wvalid && s_axi_wready) begin
        wdata_latch <= s_axi_wdata;
        wstrb_latch <= s_axi_wstrb;
        w_captured  <= 1;
      end

      if (apb_done && is_write)
        w_captured <= 0;
    end
  end

  wire write_ready = aw_captured && w_captured;


  // STATE REGISTER
 
 
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      state <= IDLE;
    else
      state <= next_state;
  end

  
  
  // NEXT STATE LOGIC
 
 
  always_comb begin
    next_state = state;

    case (state)
      IDLE: begin
        if (write_ready)
          next_state = SETUP;
        else if (s_axi_arvalid && s_axi_arready)
          next_state = SETUP;
      end

      SETUP:  next_state = ENABLE;
      ENABLE: next_state = apb_done ? IDLE : WAIT;
      WAIT:   next_state = apb_done ? IDLE : WAIT;
    endcase
  end

 
 
  // TYPE (READ / WRITE)
 
 
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      is_write <= 0;
    else if (state == IDLE) begin
      if (write_ready)
        is_write <= 1;
      else if (s_axi_arvalid && s_axi_arready)
        is_write <= 0;
    end
  end

  
  // APB OUTPUT
  
  assign m_apb_paddr   = addr_latch;
  assign m_apb_pwdata  = wdata_latch;
  assign m_apb_pwrite  = is_write;
  assign m_apb_psel    = (state != IDLE);
  assign m_apb_penable = (state == ENABLE) || (state == WAIT);

 
 
  // WRITE RESPONSE
  
  
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      s_axi_bvalid <= 0;
      s_axi_bresp  <= OKAY;
    end else begin
      if (apb_done && is_write) begin
        s_axi_bvalid <= 1;
        s_axi_bresp  <= m_apb_pslverr ? SLVERR : OKAY;
      end else if (s_axi_bvalid && s_axi_bready)
        s_axi_bvalid <= 0;
    end
  end

  // READ RESPONSE
  
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      s_axi_rvalid <= 0;
      s_axi_rdata  <= '0;
      s_axi_rresp  <= OKAY;
    end else begin
      if (apb_done && !is_write) begin
        s_axi_rvalid <= 1;
        s_axi_rdata  <= m_apb_prdata;
        s_axi_rresp  <= m_apb_pslverr ? SLVERR : OKAY;
      end else if (s_axi_rvalid && s_axi_rready)
        s_axi_rvalid <= 0;
    end
  end

endmodule