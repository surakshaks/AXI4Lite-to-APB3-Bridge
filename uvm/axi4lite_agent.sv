`include "uvm_macros.svh"
import uvm_pkg::*;

`include "axi4lite_seq_item.sv"
`include "axi4lite_driver.sv"
`include "axi4lite_monitor.sv"

// ============================================
// axi4lite_agent.sv
// Groups:
//   sequencer
//   driver
//   monitor
//
// ACTIVE  = driver + sequencer + monitor
// PASSIVE = monitor only
// ============================================

class axi4lite_agent extends uvm_agent;

    `uvm_component_utils(axi4lite_agent)

    // ========================================
    // Sub-components
    // ========================================

    uvm_sequencer #(axi4lite_seq_item) sequencer;

    axi4lite_driver  driver;
    axi4lite_monitor monitor;

    // ========================================
    // Analysis Port
    // Pass-through from monitor
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

        // Always create monitor
        monitor = axi4lite_monitor::type_id::create(
            "monitor",
            this
        );

        // Create analysis port
        ap = new("ap", this);

        // ACTIVE agent:
        // create sequencer + driver

        if(get_is_active() == UVM_ACTIVE)
        begin

            driver = axi4lite_driver::type_id::create(
                "driver",
                this
            );

            sequencer =
                uvm_sequencer #(axi4lite_seq_item)::type_id::create(
                    "sequencer",
                    this
                );

        end

    endfunction

    // ========================================
    // Connect Phase
    // ========================================

    function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);

        // Pass monitor transactions upward
        monitor.ap.connect(ap);

        // Connect sequencer to driver
        if(get_is_active() == UVM_ACTIVE)
        begin

            driver.seq_item_port.connect(
                sequencer.seq_item_export
            );

        end

    endfunction

endclass