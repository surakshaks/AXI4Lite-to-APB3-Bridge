`include "uvm_macros.svh"
import uvm_pkg::*;

`include "axi4lite_agent.sv"
`include "axi4lite_scoreboard.sv"
`include "axi4lite_coverage.sv"

// ============================================
// axi4lite_env.sv
// ============================================

class axi4lite_env extends uvm_env;

    `uvm_component_utils(axi4lite_env)

    // ========================================
    // Components
    // ========================================

    axi4lite_agent agent;

    axi2apb_scoreboard scoreboard;

    axi2apb_coverage coverage;

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

        // Create agent

        agent =
            axi4lite_agent::type_id::create(
                "agent",
                this
            );

        // Create scoreboard

        scoreboard =
            axi2apb_scoreboard::type_id::create(
                "scoreboard",
                this
            );

        // Create coverage

        coverage =
            axi2apb_coverage::type_id::create(
                "coverage",
                this
            );

        // Configure ACTIVE agent

        uvm_config_db #(uvm_active_passive_enum)::set(

            this,
            "agent",
            "is_active",
            UVM_ACTIVE

        );

    endfunction

    // ========================================
    // Connect Phase
    // ========================================

    function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);

        // Monitor → Scoreboard

        agent.ap.connect(
            scoreboard.axi_export
        );

        // Monitor → Coverage

        agent.ap.connect(
            coverage.analysis_export
        );

    endfunction

endclass