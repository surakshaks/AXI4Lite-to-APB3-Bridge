interface axi4lite_if #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32
)(
    input logic clk,
    input logic rst_n
);

    
    // AXI4-Lite Write Address Channel
  

    logic [ADDR_WIDTH-1:0] awaddr;
    logic                  awvalid;
    logic                  awready;

    
    // AXI4-Lite Write Data Channel
   

    logic [DATA_WIDTH-1:0] wdata;
    logic [(DATA_WIDTH/8)-1:0] wstrb;
    logic                  wvalid;
    logic                  wready;

  
    // AXI4-Lite Write Response Channel
   

    logic [1:0]            bresp;
    logic                  bvalid;
    logic                  bready;

   
    // AXI4-Lite Read Address Channel
  
    logic [ADDR_WIDTH-1:0] araddr;
    logic                  arvalid;
    logic                  arready;

   
    // AXI4-Lite Read Data Channel
  

    logic [DATA_WIDTH-1:0] rdata;
    logic [1:0]            rresp;
    logic                  rvalid;
    logic                  rready;

   
    // Driver Clocking Block
    // Master-side timing control
   

    clocking master_cb @(posedge clk);

        default input #1 output #1;

        // Drive signals to DUT
        output awaddr;
        output awvalid;

        output wdata;
        output wstrb;
        output wvalid;

        output bready;

        output araddr;
        output arvalid;

        output rready;

        // Sample DUT responses
        input awready;
        input wready;

        input bvalid;
        input bresp;

        input arready;

        input rvalid;
        input rdata;
        input rresp;

    endclocking
  
    
    clocking monitor_cb @(posedge clk);

        default input #1;

        input awaddr;
        input awvalid;
        input awready;

        input wdata;
        input wstrb;
        input wvalid;
        input wready;

        input bvalid;
        input bready;
        input bresp;

        input araddr;
        input arvalid;
        input arready;

        input rvalid;
        input rready;
        input rdata;
        input rresp;

    endclocking

    
    // DUT Modport
    

    modport DUT (

        input  clk,
        input  rst_n,

        input  awaddr,
        input  awvalid,
        output awready,

        input  wdata,
        input  wstrb,
        input  wvalid,
        output wready,

        output bresp,
        output bvalid,
        input  bready,

        input  araddr,
        input  arvalid,
        output arready,

        output rdata,
        output rresp,
        output rvalid,
        input  rready

    );

endinterface