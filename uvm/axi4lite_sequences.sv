`include "uvm_macros.svh"
import uvm_pkg::*;

`include "axi4lite_seq_item.sv"

// ============================================
// axi2apb_sequences.sv
// ============================================


// ======================================================
// SEQ 1 : Single Write + Readback
// ======================================================

class seq_single_wr_rd extends uvm_sequence #(axi4lite_seq_item);

    `uvm_object_utils(seq_single_wr_rd)

    function new(string name = "seq_single_wr_rd");

        super.new(name);

    endfunction

    task body();

        axi4lite_seq_item item;

        // --------------------------------------
        // WRITE
        // --------------------------------------

        item = axi4lite_seq_item::type_id::create("item");

        start_item(item);

        assert(item.randomize() with {

            addr  == 32'h0000_0000;
            data  == 32'hDEAD_BEEF;
            write == 1'b1;
            strb  == 4'hF;

        });

        finish_item(item);

        // --------------------------------------
        // READ
        // --------------------------------------

        item = axi4lite_seq_item::type_id::create("item");

        start_item(item);

        assert(item.randomize() with {

            addr  == 32'h0000_0000;
            write == 1'b0;

        });

        finish_item(item);

    endtask

endclass


// ======================================================
// SEQ 2 : Random Burst
// ======================================================

class seq_random_burst extends uvm_sequence #(axi4lite_seq_item);

    `uvm_object_utils(seq_random_burst)

    int count = 100;

    function new(string name = "seq_random_burst");

        super.new(name);

    endfunction

    task body();

        axi4lite_seq_item item;

        repeat(count)
        begin

            item = axi4lite_seq_item::type_id::create("item");

            start_item(item);

            assert(item.randomize());

            finish_item(item);

        end

    endtask

endclass


// ======================================================
// SEQ 3 : SLVERR Injection
// ======================================================

class seq_slverr_inject extends uvm_sequence #(axi4lite_seq_item);

    `uvm_object_utils(seq_slverr_inject)

    function new(string name = "seq_slverr_inject");

        super.new(name);

    endfunction

    task body();

        axi4lite_seq_item item;

        for(int slave_idx = 0; slave_idx < 4; slave_idx++)
        begin

            item = axi4lite_seq_item::type_id::create("item");

            start_item(item);

            assert(item.randomize() with {

                addr  == (32'h0000_0000 +
                          slave_idx * 32'h1000);

                write == 1'b1;

                strb  == 4'hF;

            });

            finish_item(item);

        end

    endtask

endclass


// ======================================================
// SEQ 4 : Coverage Directed
// ======================================================

class seq_coverage_directed extends
    uvm_sequence #(axi4lite_seq_item);

    `uvm_object_utils(seq_coverage_directed)

    function new(string name =
                 "seq_coverage_directed");

        super.new(name);

    endfunction

    task body();

        axi4lite_seq_item item;

        logic [31:0] bases[4] = '{

            32'h0000_0000,
            32'h0000_1000,
            32'h0000_2000,
            32'h0000_3000

        };

        logic [3:0] strbs[5] = '{

            4'hF,
            4'hC,
            4'h3,
            4'h1,
            4'h8

        };

        foreach(bases[i])
        begin

            foreach(strbs[j])
            begin

                // ------------------------------
                // WRITE
                // ------------------------------

                item =
                    axi4lite_seq_item::type_id::create(
                        "item"
                    );

                start_item(item);

                assert(item.randomize() with {

                    addr  == bases[i];

                    write == 1'b1;

                    strb  == strbs[j];

                });

                finish_item(item);

                // ------------------------------
                // READ
                // ------------------------------

                item =
                    axi4lite_seq_item::type_id::create(
                        "item"
                    );

                start_item(item);

                assert(item.randomize() with {

                    addr  == bases[i];

                    write == 1'b0;

                });

                finish_item(item);

            end

        end

    endtask

endclass
class axi4lite_single_wr_rd_seq extends uvm_sequence #(axi4lite_seq_item);

   `uvm_object_utils(axi4lite_single_wr_rd_seq)

   axi4lite_seq_item req;

   function new(string name="axi4lite_single_wr_rd_seq");
      super.new(name);
   endfunction

   task body();

      req = axi4lite_seq_item::type_id::create("req");

      start_item(req);

      req.write = 1;
      req.addr  = 32'h00000010;
      req.data = 32'hA5A5A5A5;

      finish_item(req);

   endtask

endclass