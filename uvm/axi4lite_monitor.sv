`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi4lite_seq_item.sv"


// ============================================
// axi4lite_monitor.sv
// Passive AXI4-Lite monitor
// Observes DUT activity and broadcasts
// transactions to scoreboard/coverage
// ============================================

class axi4lite_monitor extends uvm_monitor;

    `uvm_component_utils(axi4lite_monitor)

    // ========================================
    // Virtual Interface
    // ========================================

    virtual axi4lite_if vif;

    // ========================================
    // Analysis Port
    // ========================================

    uvm_analysis_port #(axi4lite_seq_item) ap;

    // ========================================
    // Constructor
    // ========================================

    function new(string name, uvm_component parent);

        super.new(name, parent);

    endfunction


    // ========================================
    // Build Phase
    // ========================================

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        // Create analysis port
        ap = new("ap", this);

        // Get virtual interface
        if(!uvm_config_db#(virtual axi4lite_if)::get(
            this,
            "",
            "vif",
            vif
        ))
        begin

            `uvm_fatal(
                "MON/NO_VIF",
                "Virtual interface not found"
            )

        end

    endfunction


    // ========================================
    // Main Monitor Loop
    // ========================================

    task run_phase(uvm_phase phase);

        axi4lite_seq_item tr;

        // Wait for reset release
        wait(vif.rst_n === 1'b1);

        @(posedge vif.clk);

        forever begin

            // Create transaction object
            tr = axi4lite_seq_item::type_id::create("tr");

            // Wait for either:
            // WRITE handshake
            // OR READ handshake

            @(vif.monitor_cb iff (

                (vif.monitor_cb.awvalid &&
                 vif.monitor_cb.awready)

                 ||

                (vif.monitor_cb.arvalid &&
                 vif.monitor_cb.arready)

            ));

            // =================================
            // WRITE TRANSACTION
            // =================================

            if(vif.monitor_cb.awvalid &&
               vif.monitor_cb.awready)
            begin

                tr.write = 1'b1;

                tr.addr = vif.monitor_cb.awaddr;
                tr.data = vif.monitor_cb.wdata;
                tr.strb = vif.monitor_cb.wstrb;

                // Wait for write response
                @(vif.monitor_cb iff vif.monitor_cb.bvalid);

                tr.resp = vif.monitor_cb.bresp;

                `uvm_info(
                    "MON",
                    $sformatf(
                        "WRITE addr=%08h data=%08h resp=%02b",
                        tr.addr,
                        tr.data,
                        tr.resp
                    ),
                    UVM_MEDIUM
                )

            end

            // =================================
            // READ TRANSACTION
            // =================================

            else begin

                tr.write = 1'b0;

                tr.addr = vif.monitor_cb.araddr;

                // Wait for read response
                @(vif.monitor_cb iff vif.monitor_cb.rvalid);

                tr.rdata = vif.monitor_cb.rdata;
                tr.resp  = vif.monitor_cb.rresp;

                `uvm_info(
                    "MON",
                    $sformatf(
                        "READ addr=%08h data=%08h resp=%02b",
                        tr.addr,
                        tr.rdata,
                        tr.resp
                    ),
                    UVM_MEDIUM
                )

            end

            // =================================
            // Broadcast transaction
            // =================================

            ap.write(tr);

        end

    endtask

endclass