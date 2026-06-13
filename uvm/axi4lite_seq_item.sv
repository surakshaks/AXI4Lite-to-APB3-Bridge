`ifndef AXI4LITE_SEQ_ITEM_SV
`define AXI4LITE_SEQ_ITEM_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class axi4lite_seq_item extends uvm_sequence_item;

    rand logic [31:0] addr;
    rand logic [31:0] data;
    rand logic [3:0]  strb;
    rand logic        write;

    logic [31:0] rdata;
    logic [1:0]  resp;

    constraint c_addr_align {
        addr[1:0] == 2'b00;
    }

    constraint c_addr_range {
        addr[31:14] == 18'h0;
    }

    constraint c_strb_valid {
        strb inside {4'b1111, 4'b1100, 4'b0011, 4'b0001, 4'b1000};
    }

    `uvm_object_utils_begin(axi4lite_seq_item)
        `uvm_field_int(addr , UVM_ALL_ON)
        `uvm_field_int(data , UVM_ALL_ON)
        `uvm_field_int(strb , UVM_ALL_ON)
        `uvm_field_int(write, UVM_ALL_ON)
        `uvm_field_int(rdata, UVM_ALL_ON)
        `uvm_field_int(resp , UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "axi4lite_seq_item");
        super.new(name);
    endfunction

endclass

`endif