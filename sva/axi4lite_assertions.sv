
// AXI4-Lite Assertions


module axi4lite_assertions (

  input logic         clk,
  input logic         rst_n,

  // WRITE ADDRESS CHANNEL
  input logic         awvalid,
  input logic         awready,
  input logic [31:0]  awaddr,

  // WRITE DATA CHANNEL
  input logic         wvalid,
  input logic         wready,
  input logic [31:0]  wdata,

  // WRITE RESPONSE CHANNEL
  input logic         bvalid,
  input logic         bready,
  input logic [1:0]   bresp,

  // READ ADDRESS CHANNEL
  input logic         arvalid,
  input logic         arready,
  input logic [31:0]  araddr,

  // READ DATA CHANNEL
  input logic         rvalid,
  input logic         rready,
  input logic [31:0]  rdata,
  input logic [1:0]   rresp
);

  
  // AWVALID must remain asserted until AWREADY
 
  property p_awvalid_stable;
    @(posedge clk)
    disable iff(!rst_n)

    (awvalid && !awready)
      |=> awvalid;
  endproperty

  AST_AWVALID_STABLE:
    assert property(p_awvalid_stable)
    else $error("AXI ERROR: AWVALID dropped before AWREADY");


 
  // AWADDR must remain stable until handshake completes
  
  property p_awaddr_stable;
    @(posedge clk)
    disable iff(!rst_n)

    (awvalid && !awready)
      |=> $stable(awaddr);
  endproperty

  AST_AWADDR_STABLE:
    assert property(p_awaddr_stable)
    else $error("AXI ERROR: AWADDR changed before handshake");


  
 
  // WVALID must remain asserted until WREADY

  property p_wvalid_stable;
    @(posedge clk)
    disable iff(!rst_n)

    (wvalid && !wready)
      |=> wvalid;
  endproperty

  AST_WVALID_STABLE:
    assert property(p_wvalid_stable)
    else $error("AXI ERROR: WVALID dropped before WREADY");


  // WDATA must remain stable until handshake completes
 
  property p_wdata_stable;
    @(posedge clk)
    disable iff(!rst_n)

    (wvalid && !wready)
      |=> $stable(wdata);
  endproperty

  AST_WDATA_STABLE:
    assert property(p_wdata_stable)
    else $error("AXI ERROR: WDATA changed before handshake");


  // ARVALID must remain asserted until ARREADY
 
  property p_arvalid_stable;
    @(posedge clk)
    disable iff(!rst_n)

    (arvalid && !arready)
      |=> arvalid;
  endproperty

  AST_ARVALID_STABLE:
    assert property(p_arvalid_stable)
    else $error("AXI ERROR: ARVALID dropped before ARREADY");



  // ARADDR must remain stable until handshake completes
  
  property p_araddr_stable;
    @(posedge clk)
    disable iff(!rst_n)

    (arvalid && !arready)
      |=> $stable(araddr);
  endproperty

  AST_ARADDR_STABLE:
    assert property(p_araddr_stable)
    else $error("AXI ERROR: ARADDR changed before handshake");


 
  
  // BVALID must stay high until BREADY
 
  property p_bvalid_stable;
    @(posedge clk)
    disable iff(!rst_n)

    (bvalid && !bready)
      |=> bvalid;
  endproperty

  AST_BVALID_STABLE:
    assert property(p_bvalid_stable)
    else $error("AXI ERROR: BVALID dropped before BREADY");


  
  // RVALID must stay high until RREADY
  property p_rvalid_stable;
    @(posedge clk)
    disable iff(!rst_n)

    (rvalid && !rready)
      |=> rvalid;
  endproperty

  AST_RVALID_STABLE:
    assert property(p_rvalid_stable)
    else $error("AXI ERROR: RVALID dropped before RREADY");


  
  // BVALID must occur only after write handshake
  
  property p_bvalid_after_write;
    @(posedge clk)
    disable iff(!rst_n)

    $rose(bvalid)
      |->
      (
        $past(awvalid && awready,1) &&
        $past(wvalid  && wready ,1)
      );
  endproperty

  AST_BVALID_AFTER_WRITE:
    assert property(p_bvalid_after_write)
    else $error("AXI ERROR: BVALID without write handshake");


 
  // RVALID must occur only after AR handshake
 
  property p_rvalid_after_read;
    @(posedge clk)
    disable iff(!rst_n)

    $rose(rvalid)
     |->
    $past(arvalid && arready,1);
  endproperty

  AST_RVALID_AFTER_READ:
    assert property(p_rvalid_after_read)
    else $error("AXI ERROR: RVALID without AR handshake");


  
  // No X/Z on critical control signals
  
  AST_NO_X_AWVALID:
    assert property (
      @(posedge clk)
      disable iff(!rst_n)

      !$isunknown(awvalid)
    )
    else $error("AXI ERROR: X/Z detected on AWVALID");


  AST_NO_X_WVALID:
    assert property (
      @(posedge clk)
      disable iff(!rst_n)

      !$isunknown(wvalid)
    )
    else $error("AXI ERROR: X/Z detected on WVALID");


  AST_NO_X_ARVALID:
    assert property (
      @(posedge clk)
      disable iff(!rst_n)

      !$isunknown(arvalid)
    )
    else $error("AXI ERROR: X/Z detected on ARVALID");


 
  // FUNCTIONAL COVERAGE

  covergroup axi_resp_cg @(posedge clk);

    // Write response coverage
    cp_bresp : coverpoint bresp {
      bins okay = {2'b00};
      bins slverr = {2'b10};
    }

    // Read response coverage
    cp_rresp : coverpoint rresp {
      bins okay = {2'b00};
      bins slverr = {2'b10};
    }

    // Read/write transaction activity
    cp_write : coverpoint (awvalid && awready);
    cp_read  : coverpoint (arvalid && arready);

  endgroup

  axi_resp_cg u_axi_resp_cg = new();

endmodule