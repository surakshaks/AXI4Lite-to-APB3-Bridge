`timescale 1ns/1ps

// ============================================
// axi2apb_bridge.sv
// AXI4-Lite → APB Bridge
// ============================================

module axi2apb_bridge
#(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter NUM_SLAVES = 4
)
(
    input  logic                     clk,
    input  logic                     rst_n,

    // ========================================
    // AXI4-Lite Slave Interface
    // ========================================

    // Write Address Channel
    input  logic [ADDR_WIDTH-1:0]    s_axi_awaddr,
    input  logic                     s_axi_awvalid,
    output logic                     s_axi_awready,

    // Write Data Channel
    input  logic [DATA_WIDTH-1:0]    s_axi_wdata,
    input  logic [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  logic                     s_axi_wvalid,
    output logic                     s_axi_wready,

    // Write Response Channel
    output logic [1:0]               s_axi_bresp,
    output logic                     s_axi_bvalid,
    input  logic                     s_axi_bready,

    // Read Address Channel
    input  logic [ADDR_WIDTH-1:0]    s_axi_araddr,
    input  logic                     s_axi_arvalid,
    output logic                     s_axi_arready,

    // Read Data Channel
    output logic [DATA_WIDTH-1:0]    s_axi_rdata,
    output logic [1:0]               s_axi_rresp,
    output logic                     s_axi_rvalid,
    input  logic                     s_axi_rready,

    // ========================================
    // APB Master Interface
    // ========================================

    output logic [ADDR_WIDTH-1:0]    m_apb_paddr,
    output logic [NUM_SLAVES-1:0]    m_apb_psel,
    output logic                     m_apb_penable,
    output logic                     m_apb_pwrite,
    output logic [DATA_WIDTH-1:0]    m_apb_pwdata,

    input  logic [DATA_WIDTH-1:0]    m_apb_prdata,
    input  logic                     m_apb_pready,
    input  logic                     m_apb_pslverr
);

    // ========================================
    // Internal Registers
    // ========================================

    logic [ADDR_WIDTH-1:0] addr_reg;
    logic [DATA_WIDTH-1:0] data_reg;
    logic                  write_reg;

    // ========================================
    // FSM States
    // ========================================

    typedef enum logic [2:0]
    {
        IDLE,
        SETUP,
        ACCESS,
        RESP
    } state_t;

    state_t state, next_state;

    // ========================================
    // Slave Decode
    // ========================================

    always_comb
    begin

        m_apb_psel = '0;

        case(addr_reg[13:12])

            2'b00: m_apb_psel[0] = 1'b1;
            2'b01: m_apb_psel[1] = 1'b1;
            2'b10: m_apb_psel[2] = 1'b1;
            2'b11: m_apb_psel[3] = 1'b1;

        endcase

    end

    // ========================================
    // State Register
    // ========================================

    always_ff @(posedge clk or negedge rst_n)
    begin

        if(!rst_n)
            state <= IDLE;
        else
            state <= next_state;

    end

    // ========================================
    // Next State Logic
    // ========================================

    always_comb
    begin

        next_state = state;

        case(state)

            IDLE:
            begin

                if((s_axi_awvalid && s_axi_wvalid) ||
                   s_axi_arvalid)
                    next_state = SETUP;

            end

            SETUP:
                next_state = ACCESS;

            ACCESS:
            begin

                if(m_apb_pready)
                    next_state = RESP;

            end

            RESP:
            begin

                if(write_reg && s_axi_bready)
                    next_state = IDLE;

                else if(!write_reg && s_axi_rready)
                    next_state = IDLE;

            end

        endcase

    end

    // ========================================
    // Main Sequential Logic
    // ========================================

    always_ff @(posedge clk or negedge rst_n)
    begin

        if(!rst_n)
        begin

            addr_reg       <= '0;
            data_reg       <= '0;
            write_reg      <= 1'b0;

            s_axi_awready  <= 1'b0;
            s_axi_wready   <= 1'b0;
            s_axi_bvalid   <= 1'b0;
            s_axi_bresp    <= 2'b00;

            s_axi_arready  <= 1'b0;
            s_axi_rvalid   <= 1'b0;
            s_axi_rresp    <= 2'b00;
            s_axi_rdata    <= '0;

            m_apb_paddr    <= '0;
            m_apb_penable  <= 1'b0;
            m_apb_pwrite   <= 1'b0;
            m_apb_pwdata   <= '0;

        end
        else
        begin

            // Default outputs

            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_arready <= 1'b0;

            case(state)

                // =================================
                // IDLE
                // =================================

                IDLE:
                begin

                    s_axi_bvalid  <= 1'b0;
                    s_axi_rvalid  <= 1'b0;
                    m_apb_penable <= 1'b0;

                    // Write transaction

                    if(s_axi_awvalid && s_axi_wvalid)
                    begin

                        s_axi_awready <= 1'b1;
                        s_axi_wready  <= 1'b1;

                        addr_reg      <= s_axi_awaddr;
                        data_reg      <= s_axi_wdata;
                        write_reg     <= 1'b1;

                    end

                    // Read transaction

                    else if(s_axi_arvalid)
                    begin

                        s_axi_arready <= 1'b1;

                        addr_reg      <= s_axi_araddr;
                        write_reg     <= 1'b0;

                    end

                end

                // =================================
                // SETUP
                // =================================

                SETUP:
                begin

                    m_apb_paddr   <= addr_reg;
                    m_apb_pwrite  <= write_reg;
                    m_apb_pwdata  <= data_reg;

                end

                // =================================
                // ACCESS
                // =================================

                ACCESS:
                begin

                    m_apb_penable <= 1'b1;

                    if(m_apb_pready)
                    begin

                        if(write_reg)
                        begin

                            s_axi_bvalid <= 1'b1;

                            s_axi_bresp <=
                                (m_apb_pslverr) ?
                                2'b10 : 2'b00;

                        end
                        else
                        begin

                            s_axi_rvalid <= 1'b1;

                            s_axi_rdata <=
                                m_apb_prdata;

                            s_axi_rresp <=
                                (m_apb_pslverr) ?
                                2'b10 : 2'b00;

                        end

                    end

                end

                // =================================
                // RESP
                // =================================

                RESP:
                begin

                    if(write_reg && s_axi_bready)
                    begin

                        s_axi_bvalid <= 1'b0;

                    end

                    if(!write_reg && s_axi_rready)
                    begin

                        s_axi_rvalid <= 1'b0;

                    end

                end

            endcase

        end

    end

endmodule