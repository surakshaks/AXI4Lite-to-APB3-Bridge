`timescale 1ns/1ps

module axi_slave_model #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 32,
  parameter int NUM_REGS    = 16,
  parameter int WAIT_CYCLES = 1
)(
  input  logic clk,
  input  logic rst_n,

  input  logic [ADDR_WIDTH-1:0] paddr,
  input  logic penable,
  input  logic pwrite,
  input  logic [DATA_WIDTH-1:0] pwdata,

  output logic [DATA_WIDTH-1:0] prdata,
  output logic pready,
  output logic pslverr,

  input  logic err_inject
);

  // ==========================================
  // Register File
  // ==========================================

  logic [DATA_WIDTH-1:0] regfile [NUM_REGS-1:0];

  // ==========================================
  // Wait State Counter
  // ==========================================

  int wait_cnt;

  // ==========================================
  // Initialize Registers
  // ==========================================

  initial begin

    for(int i=0; i<NUM_REGS; i++)
      regfile[i] = i;

  end

  // ==========================================
  // APB Slave Behavior
  // ==========================================

  always_ff @(posedge clk or negedge rst_n)
  begin

    if(!rst_n)
    begin

      pready   <= 1'b0;
      pslverr  <= 1'b0;
      prdata   <= '0;
      wait_cnt <= 0;

    end
    else
    begin

      // ======================================
      // Setup Phase
      // PENABLE = 0
      // ======================================

      if(!penable)
      begin

        wait_cnt <= WAIT_CYCLES;

        pready   <= 1'b0;
        pslverr  <= 1'b0;

        // ------------------------------------
        // WRITE
        // ------------------------------------

        if(pwrite)
        begin

          if(!err_inject &&
             (paddr/4 < NUM_REGS))
          begin

            regfile[paddr/4] <= pwdata;

          end

        end

        // ------------------------------------
        // READ
        // ------------------------------------

        else
        begin

          if(paddr/4 < NUM_REGS)
          begin

            prdata <= regfile[paddr/4];

          end

          pslverr <= err_inject;

        end

      end

      // ======================================
      // Access Phase
      // PENABLE = 1
      // ======================================

      else
      begin

        if(wait_cnt > 0)
        begin

          pready  <= 1'b0;
          wait_cnt <= wait_cnt - 1;

        end
        else
        begin

          pready <= 1'b1;

        end

      end

    end

  end

endmodule