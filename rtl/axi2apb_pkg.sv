package axi2apb_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  parameter int ADDR_WIDTH = 32;
  parameter int DATA_WIDTH = 32;
  parameter int STRB_WIDTH = DATA_WIDTH / 8;
  parameter int NUM_SLAVES = 4;

  typedef enum logic [1:0] {
    IDLE   = 2'b00,
    SETUP  = 2'b01,
    ENABLE = 2'b10,
    WAIT   = 2'b11
  } apb_state_t;

  typedef enum logic [1:0] {
    OKAY   = 2'b00,
    EXOKAY = 2'b01,
    SLVERR = 2'b10,
    DECERR = 2'b11
  } axi_resp_t;

  parameter logic [31:0] SLAVE0_BASE = 32'h0000_0000;
  parameter logic [31:0] SLAVE1_BASE = 32'h0000_1000;
  parameter logic [31:0] SLAVE2_BASE = 32'h0000_2000;
  parameter logic [31:0] SLAVE3_BASE = 32'h0000_3000;

  

endpackage : axi2apb_pkg