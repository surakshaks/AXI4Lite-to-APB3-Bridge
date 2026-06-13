// axi4lite_test.sv
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi4lite_env.sv"
`include "axi4lite_sequences.sv"
// import axi2apb_pkg::*;   // keep only if your test/sequence code uses package types/params

class axi2apb_base_test extends uvm_test;
  `uvm_component_utils(axi2apb_base_test)
  axi4lite_env env;

  function new(string name = "axi2apb_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = axi4lite_env::type_id::create("env", this);
  endfunction
endclass

class test_single_wr_rd extends axi2apb_base_test;
  `uvm_component_utils(test_single_wr_rd)

  function new(string name = "test_single_wr_rd", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    seq_single_wr_rd seq;
    phase.raise_objection(this);
    seq = seq_single_wr_rd::type_id::create("seq");
    seq.start(env.agent.sequencer);
    #100;
    phase.drop_objection(this);
  endtask
endclass

class test_random_burst extends axi2apb_base_test;
  `uvm_component_utils(test_random_burst)

  function new(string name = "test_random_burst", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    seq_random_burst seq;
    phase.raise_objection(this);
    seq = seq_random_burst::type_id::create("seq");
    seq.count = 200; // Run 200 randomized items to close randomized bins
    seq.start(env.agent.sequencer);
    #100;
    phase.drop_objection(this);
  endtask
endclass

class test_slverr_inject extends axi2apb_base_test;
  `uvm_component_utils(test_slverr_inject)

  function new(string name = "test_slverr_inject", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    seq_slverr_inject seq;
    phase.raise_objection(this);
    seq = seq_slverr_inject::type_id::create("seq");
    seq.start(env.agent.sequencer);
    #100;
    phase.drop_objection(this);
  endtask
endclass

class test_coverage_directed extends axi2apb_base_test;
  `uvm_component_utils(test_coverage_directed)

  function new(string name = "test_coverage_directed", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    seq_coverage_directed seq;
    phase.raise_objection(this);
    seq = seq_coverage_directed::type_id::create("seq");
    seq.start(env.agent.sequencer);
    #100;
    phase.drop_objection(this);
  endtask
endclass

class test_all_combined extends axi2apb_base_test;
  `uvm_component_utils(test_all_combined)

  function new(string name = "test_all_combined", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    seq_single_wr_rd seq_single;
    seq_coverage_directed seq_cov;
    seq_slverr_inject seq_err;
    seq_random_burst seq_rand;

    phase.raise_objection(this);

    `uvm_info("TEST", "Starting Combined Test Suite for Coverage Closure...", UVM_LOW)

    seq_single = seq_single_wr_rd::type_id::create("seq_single");
    seq_single.start(env.agent.sequencer);

    seq_cov = seq_coverage_directed::type_id::create("seq_cov");
    seq_cov.start(env.agent.sequencer);

    seq_err = seq_slverr_inject::type_id::create("seq_err");
    seq_err.start(env.agent.sequencer);

    seq_rand = seq_random_burst::type_id::create("seq_rand");
    seq_rand.count = 150;
    seq_rand.start(env.agent.sequencer);

    #100;
    phase.drop_objection(this);
  endtask
endclass