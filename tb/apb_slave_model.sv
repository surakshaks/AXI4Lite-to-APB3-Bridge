// ============================================
// apb_slave_model.sv
// Simulates a simple APB peripheral
// ============================================

module apb_slave_model #(

  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 32,
  parameter int MEM_DEPTH  = 16,
  parameter int WAIT_CYCLES = 1

)(
  input  logic                     pclk,
  input  logic                     preset_n,

  input  logic [ADDR_WIDTH-1:0]    paddr,
  input  logic                     psel,
  input  logic                     penable,
  input  logic                     pwrite,
  input  logic [DATA_WIDTH-1:0]    pwdata,

  output logic [DATA_WIDTH-1:0]    prdata,
  output logic                     pready,
  output logic                     pslverr,

  input  logic                     err_inject
);

  
  // Internal Register File
 
  logic [DATA_WIDTH-1:0] regfile [0:MEM_DEPTH-1];

  
  
  // Wait-State Counter
  
  logic [$clog2(WAIT_CYCLES+2)-1:0] wait_cnt;

  
  // Address Decode
  // Word aligned:
  // addr[5:2] selects 16 registers
 
  logic [$clog2(MEM_DEPTH)-1:0] reg_idx;

  assign reg_idx = paddr[$clog2(MEM_DEPTH)+1 : 2];

  // APB Slave Logic
  always_ff @(posedge pclk or negedge preset_n) begin

    if (!preset_n) begin

      prdata   <= '0;
      pready   <= 1'b0;
      pslverr  <= 1'b0;
      wait_cnt <= '0;

      // Initialize memory
      for (int i = 0; i < MEM_DEPTH; i++)
        regfile[i] <= i * 32'h1111_1111;

    end

    else begin

      // Default outputs
      pready  <= 1'b0;
      pslverr <= 1'b0;

      
      // ACTIVE APB TRANSFER
   
      if (psel && penable) begin

        // Insert wait states
        if (wait_cnt < WAIT_CYCLES) begin

          wait_cnt <= wait_cnt + 1;
          pready   <= 1'b0;

        end

        else begin

          // Transfer completes here
          pready   <= 1'b1;
          pslverr  <= err_inject;
          wait_cnt <= '0;

          // WRITE
          if (pwrite && !err_inject) begin

            regfile[reg_idx] <= pwdata;

          end

          // READ
          else if (!pwrite) begin

            prdata <= regfile[reg_idx];

          end
        end
      end

      // No APB activity
      else begin

       wait_cnt <= 0;

      end
    end
  end

endmodule