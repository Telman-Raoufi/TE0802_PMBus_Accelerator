//-----------------------------------------------------------------------------
// Company:          Personal Project
// Engineer:         Telman Raoufi
// 
// Create Date:      02/05/2026
// Design Name:      TE0802 PMBus Accelerator
// Module Name:      pmbus_top
// Target Devices:   Xilinx Zynq UltraScale+ (TE0802)
// Tool Versions:    Vivado 2023.2+
// Description:      Top-level wrapper integrating AXI-Lite registers, 
//                   SMBus PHY, and command decoder FSM.
// 
// License:          MIT License
//-----------------------------------------------------------------------------

module pmbus_top #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 5
)(
    // Physical SMBus Pins
    inout  wire  sda_io,
    inout  wire  scl_io,

    // Interrupt to Zynq GIC
    output logic irq_o,

    // AXI-Lite Interface
    input  logic                            s_axi_aclk,
    input  logic                            s_axi_aresetn,
    input  logic [C_S_AXI_ADDR_WIDTH-1:0]   s_axi_awaddr,
    input  logic                            s_axi_awvalid,
    output logic                            s_axi_awready,
    input  logic [C_S_AXI_DATA_WIDTH-1:0]   s_axi_wdata,
    input  logic [C_S_AXI_DATA_WIDTH/8-1:0] s_axi_wstrb,
    input  logic                            s_axi_wvalid,
    output logic                            s_axi_wready,
    output logic [1:0]                      s_axi_bresp,
    output logic                            s_axi_bvalid,
    input  logic                            s_axi_bready,
    input  logic [C_S_AXI_ADDR_WIDTH-1:0]   s_axi_araddr,
    input  logic                            s_axi_arvalid,
    output logic                            s_axi_arready,
    output logic [C_S_AXI_DATA_WIDTH-1:0]   s_axi_rdata,
    output logic [1:0]                      s_axi_rresp,
    output logic                            s_axi_rvalid,
    input  logic                            s_axi_rready
);

    // Internal Signal Interconnects
    logic sda_in, scl_in;
    logic sda_out_en, scl_out_en;
    logic start_detect, stop_detect;
    logic decoder_en, irq_clear, irq_status;
    logic [7:0]  decoded_cmd;
    logic [31:0] decoded_data_0;

    // Output Enable Logic: For a "Listener" IP, we keep these 0 (High-Z)
    // unless we decide to implement ACK driving later.
    assign sda_out_en = 1'b0;
    assign scl_out_en = 1'b0;
    assign irq_o = irq_status;

    // 1. Instantiation: SMBus Physical Layer
    smbus_phy i_phy (
        .sda_io(sda_io),
        .scl_io(scl_io),
        .sda_out_en(sda_out_en),
        .sda_in(sda_in),
        .scl_out_en(scl_out_en),
        .scl_in(scl_in)
    );

    // 2. Instantiation: Start/Stop Detector
    pmbus_detector i_detector (
        .clk(s_axi_aclk),
        .rreset_n(s_axi_aresetn),
        .sda_in(sda_in),
        .scl_in(scl_in),
        .start_detect(start_detect),
        .stop_detect(stop_detect)
    );

    // 3. Instantiation: PMBus Finite State Machine
    pmbus_fsm i_fsm (
        .clk(s_axi_aclk),
        .rst_n(s_axi_aresetn & decoder_en),
        .start_detect(start_detect),
        .stop_detect(stop_detect),
        .scl_debounced(scl_in), // Using synchronized inputs
        .sda_debounced(sda_in),
        .decoded_cmd(decoded_cmd),
        .decoded_data_0(decoded_data_0),
        .irq_status(irq_status),
        .irq_clear(irq_clear)
    );

    // 4. Instantiation: AXI-Lite Register Bank
    pmbus_registers i_registers (
        .S_AXI_ACLK(s_axi_aclk),
        .S_AXI_ARESETN(s_axi_aresetn),
        .S_AXI_AWADDR(s_axi_awaddr),
        .S_AXI_AWVALID(s_axi_awvalid),
        .S_AXI_AWREADY(s_axi_awready),
        .S_AXI_WDATA(s_axi_wdata),
        .S_AXI_WSTRB(s_axi_wstrb),
        .S_AXI_WVALID(s_axi_wvalid),
        .S_AXI_WREADY(s_axi_wready),
        .S_AXI_BRESP(s_axi_bresp),
        .S_AXI_BVALID(s_axi_bvalid),
        .S_AXI_BREADY(s_axi_bready),
        .S_AXI_ARADDR(s_axi_araddr),
        .S_AXI_ARVALID(s_axi_arvalid),
        .S_AXI_ARREADY(s_axi_arready),
        .S_AXI_RDATA(s_axi_rdata),
        .S_AXI_RRESP(s_axi_rRESP),
        .S_AXI_RVALID(s_axi_rvalid),
        .S_AXI_RREADY(s_axi_rready),
        .decoder_en(decoder_en),
        .irq_status(irq_status),
        .irq_clear(irq_clear),
        .decoded_cmd(decoded_cmd),
        .decoded_data_0(decoded_data_0),
        .decoded_data_1(32'h0) // Reserved for future use
    );

endmodule