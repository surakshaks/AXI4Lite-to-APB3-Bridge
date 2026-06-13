`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi4lite_seq_item.sv"

// axi4lite_driver.sv
// Gets seq_items from sequencer.
// Drives AXI4-Lite pins cycle-accurately.

class axi4lite_driver extends uvm_driver #(axi4lite_seq_item);

    `uvm_component_utils(axi4lite_driver)

    // Virtual interface handle
    virtual axi4lite_if vif;

    
    // Constructor

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction


    // build_phase
    // Get interface from config_db

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if(!uvm_config_db#(virtual axi4lite_if)::get(
            this,
            "",
            "vif",
            vif
        ))
        begin
            `uvm_fatal(
                "DRV/NO_VIF",
                "Virtual interface not found in config_db"
            )
        end

    endfunction


    // run_phase
    // Main driver loop

    task run_phase(uvm_phase phase);

        axi4lite_seq_item req;

        // Initialize interface
        init_signals();

        // Wait for reset deassertion
        wait(vif.rst_n === 1'b1);

        @(posedge vif.clk);

        forever begin

            // Get transaction from sequencer
            seq_item_port.get_next_item(req);

            // Decide operation
            if(req.write)
                drive_write(req);
            else
                drive_read(req);

            // Inform sequencer transaction completed
            seq_item_port.item_done();

        end

    endtask


    // Initialize all AXI signals
    

    task init_signals();

        vif.master_cb.awaddr  <= '0;
        vif.master_cb.awvalid <= 1'b0;

        vif.master_cb.wdata   <= '0;
        vif.master_cb.wstrb   <= 4'hF;
        vif.master_cb.wvalid  <= 1'b0;

        vif.master_cb.bready  <= 1'b1;

        vif.master_cb.araddr  <= '0;
        vif.master_cb.arvalid <= 1'b0;

        vif.master_cb.rready  <= 1'b1;

    endtask


   
    // Drive AXI Write Transaction
    

    task drive_write(axi4lite_seq_item req);

        // Present address + data
        @(vif.master_cb);

        vif.master_cb.awaddr  <= req.addr;
        vif.master_cb.awvalid <= 1'b1;

        vif.master_cb.wdata   <= req.data;
        vif.master_cb.wstrb   <= req.strb;
        vif.master_cb.wvalid  <= 1'b1;

        // Wait for handshake
        @(vif.master_cb iff (
            vif.master_cb.awready &&
            vif.master_cb.wready
        ));

        // Deassert valid signals
        vif.master_cb.awvalid <= 1'b0;
        vif.master_cb.wvalid  <= 1'b0;

        // Wait for response
        @(vif.master_cb iff vif.master_cb.bvalid);

        // Capture response
        req.resp = vif.master_cb.bresp;

        `uvm_info(
            "DRV",
            req.convert2string(),
            UVM_HIGH
        )

    endtask


    
    // Drive AXI Read Transaction
   

    task drive_read(axi4lite_seq_item req);

        // Present read address
        @(vif.master_cb);

        vif.master_cb.araddr  <= req.addr;
        vif.master_cb.arvalid <= 1'b1;

        // Wait for ARREADY
        @(vif.master_cb iff vif.master_cb.arready);

        // Remove valid
        vif.master_cb.arvalid <= 1'b0;

        // Wait for read data
        @(vif.master_cb iff vif.master_cb.rvalid);

        // Capture response/data
        req.rdata = vif.master_cb.rdata;
        req.resp  = vif.master_cb.rresp;

        `uvm_info(
            "DRV",
            req.convert2string(),
            UVM_HIGH
        )

    endtask

endclass