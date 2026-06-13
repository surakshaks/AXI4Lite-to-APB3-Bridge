`include "uvm_macros.svh"
import uvm_pkg::*;

`include "axi4lite_seq_item.sv"

// ============================================
// axi2apb_scoreboard.sv
// Self-checking scoreboard
// Maintains shadow memory model
// and compares read data automatically
// ============================================

class axi2apb_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(axi2apb_scoreboard)

    // ========================================
    // Analysis Implementation Port
    // Receives transactions from monitor
    // ========================================

    uvm_analysis_imp #(
        axi4lite_seq_item,
        axi2apb_scoreboard
    ) axi_export;

    // ========================================
    // Shadow Memory
    // address -> expected data
    // ========================================

    logic [31:0] shadow_mem [logic[31:0]];

    // ========================================
    // Statistics
    // ========================================

    int wr_pass;
    int wr_fail;

    int rd_pass;
    int rd_fail;

    int slverr_count;

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

        axi_export = new("axi_export", this);

    endfunction

    // ========================================
    // write()
    // Called automatically by monitor
    // ========================================

    function void write(axi4lite_seq_item tr);

        // ====================================
        // WRITE TRANSACTION
        // ====================================

        if(tr.write)
        begin

            // Successful write
            if(tr.resp == 2'b00)
            begin

                // Update shadow memory
                shadow_mem[tr.addr] = tr.data;

                wr_pass++;

                `uvm_info(
                    "SB",
                    $sformatf(
                        "WR OK addr=%08h data=%08h",
                        tr.addr,
                        tr.data
                    ),
                    UVM_HIGH
                )

            end

            // SLVERR
            else begin

                slverr_count++;

                `uvm_info(
                    "SB",
                    $sformatf(
                        "WR ERR addr=%08h",
                        tr.addr
                    ),
                    UVM_MEDIUM
                )

            end

        end

        // ====================================
        // READ TRANSACTION
        // ====================================

        else begin

            // Error response
            if(tr.resp != 2'b00)
            begin

                slverr_count++;

                return;

            end

            // Address never written before
            if(!shadow_mem.exists(tr.addr))
            begin

                `uvm_info(
                    "SB",
                    $sformatf(
                        "RD SKIP addr=%08h",
                        tr.addr
                    ),
                    UVM_HIGH
                )

                return;

            end

            // Compare expected vs actual
            if(tr.rdata === shadow_mem[tr.addr])
            begin

                rd_pass++;

                `uvm_info(
                    "SB",
                    $sformatf(
                        "RD OK addr=%08h exp=%08h got=%08h",
                        tr.addr,
                        shadow_mem[tr.addr],
                        tr.rdata
                    ),
                    UVM_HIGH
                )

            end

            // Mismatch
            else begin

                rd_fail++;

                `uvm_error(
                    "SB",
                    $sformatf(
                        "RD MISMATCH addr=%08h EXPECTED=%08h GOT=%08h",
                        tr.addr,
                        shadow_mem[tr.addr],
                        tr.rdata
                    )
                )

            end

        end

    endfunction

    // ========================================
    // Report Phase
    // Final Summary
    // ========================================

    function void report_phase(uvm_phase phase);

        `uvm_info(
            "SB",
            "========================================",
            UVM_NONE
        )

        `uvm_info(
            "SB",
            " SCOREBOARD SUMMARY ",
            UVM_NONE
        )

        `uvm_info(
            "SB",
            "========================================",
            UVM_NONE
        )

        `uvm_info(
            "SB",
            $sformatf("Write PASS : %0d", wr_pass),
            UVM_NONE
        )

        `uvm_info(
            "SB",
            $sformatf("Read PASS  : %0d", rd_pass),
            UVM_NONE
        )

        `uvm_info(
            "SB",
            $sformatf("Read FAIL  : %0d", rd_fail),
            UVM_NONE
        )

        `uvm_info(
            "SB",
            $sformatf("SLVERR seen: %0d", slverr_count),
            UVM_NONE
        )

        `uvm_info(
            "SB",
            "========================================",
            UVM_NONE
        )

        if(rd_fail == 0)
        begin

            `uvm_info(
                "SB",
                "ALL CHECKS PASSED",
                UVM_NONE
            )

        end
        else begin

            `uvm_fatal(
                "SB",
                $sformatf(
                    "%0d READ FAILURES DETECTED",
                    rd_fail
                )
            )

        end

    endfunction

endclass