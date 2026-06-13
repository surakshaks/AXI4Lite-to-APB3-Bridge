`include "uvm_macros.svh"
import uvm_pkg::*;

`include "axi4lite_seq_item.sv"

// ============================================
// axi2apb_coverage.sv
// Functional Coverage Collector
// ============================================

class axi2apb_coverage extends uvm_subscriber #(axi4lite_seq_item);

    `uvm_component_utils(axi2apb_coverage)

    // ========================================
    // Current transaction handle
    // ========================================

    axi4lite_seq_item tr;

    // ========================================
    // COVERGROUP
    // ========================================

    covergroup axi2apb_cg;

        // ------------------------------------
        // Slave regions
        // ------------------------------------

        cp_slave : coverpoint tr.addr[13:12]
        {
            bins gpio  = {2'b00};
            bins uart  = {2'b01};
            bins spi   = {2'b10};
            bins timer = {2'b11};
        }

        // ------------------------------------
        // Read / Write operation
        // ------------------------------------

        cp_op : coverpoint tr.write
        {
            bins write = {1'b1};
            bins read  = {1'b0};
        }

        // ------------------------------------
        // AXI response
        // ------------------------------------

        cp_resp : coverpoint tr.resp
        {
            bins okay   = {2'b00};
            bins slverr = {2'b10};

            illegal_bins other = default;
        }

        // ------------------------------------
        // Write strobe patterns
        // ------------------------------------

        cp_strb : coverpoint tr.strb
        {
            bins full_word = {4'b1111};

            bins upper_half = {4'b1100};
            bins lower_half = {4'b0011};

            bins byte0 = {4'b0001};
            bins byte3 = {4'b1000};
        }

        // ------------------------------------
        // Cross Coverage
        // ------------------------------------

        // Every slave:
        // must see read + write

        cx_slave_op : cross cp_slave, cp_op;

        // Every slave:
        // must see okay + slverr

        cx_slave_resp : cross cp_slave, cp_resp;

        // Different strobes for writes

        cx_op_strb : cross cp_op, cp_strb
        {
            // Ignore reads with weird strobes

            ignore_bins rd_strb =
                binsof(cp_op.read) &&
                !binsof(cp_strb.full_word);
        }

    endgroup

    // ========================================
    // Constructor
    // ========================================

    function new(string name, uvm_component parent);

        super.new(name, parent);

        axi2apb_cg = new();

    endfunction

    // ========================================
    // write()
    // Called automatically by monitor
    // ========================================

    function void write(axi4lite_seq_item t);

        tr = t;

        axi2apb_cg.sample();

    endfunction

    // ========================================
    // Report Phase
    // ========================================

    function void report_phase(uvm_phase phase);

        `uvm_info(
            "COV",
            $sformatf(
                "Functional Coverage = %.1f%%",
                axi2apb_cg.get_coverage()
            ),
            UVM_NONE
        )

        if(axi2apb_cg.get_coverage() < 90.0)
        begin

            `uvm_warning(
                "COV",
                "Coverage below 90%"
            )

        end

    endfunction

endclass