//-----------------------------------------------------------------------------
// Company:          Personal Project
// Engineer:         Telman Raoufi
// 
// Create Date:      02/04/2026
// Design Name:      TE0802 PMBus Accelerator
// Module Name:      pmbus_registers
// Target Devices:   Xilinx Zynq UltraScale+ (TE0802)
// Tool Versions:    Vivado 2023.2+
// Description:      AXI4-Lite register bank for the PMBus decoder.
//                   Stores decoded commands and data for the Zynq ARM core.
// 
// License:          MIT License
//-----------------------------------------------------------------------------

module pmbus_registers #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 5
)(
    // AXI-Lite Interface
    input  logic                            S_AXI_ACLK,
    input  logic                            S_AXI_ARESETN,
    input  logic [C_S_AXI_ADDR_WIDTH-1:0]   S_AXI_AWADDR,
    input  logic                            S_AXI_AWVALID,
    output logic                            S_AXI_AWREADY,
    input  logic [C_S_AXI_DATA_WIDTH-1:0]   S_AXI_WDATA,
    input  logic [C_S_AXI_DATA_WIDTH/8-1:0] S_AXI_WSTRB,
    input  logic                            S_AXI_WVALID,
    output logic                            S_AXI_WREADY,
    output logic [1:0]                      S_AXI_BRESP,
    output logic                            S_AXI_BVALID,
    input  logic                            S_AXI_BREADY,
    input  logic [C_S_AXI_ADDR_WIDTH-1:0]   S_AXI_ARADDR,
    input  logic                            S_AXI_ARVALID,
    output logic                            S_AXI_ARREADY,
    output logic [C_S_AXI_DATA_WIDTH-1:0]   S_AXI_RDATA,
    output logic [1:0]                      S_AXI_RRESP,
    output logic                            S_AXI_RVALID,
    input  logic                            S_AXI_RREADY,

    // Internal Signals to/from PMBus Decoder
    output logic                            decoder_en,
    input  logic                            irq_status,
    output logic                            irq_clear,
    input  logic [7:0]                      decoded_cmd,
    input  logic [31:0]                     decoded_data_0,
    input  logic [31:0]                     decoded_data_1
);

    // Register 0 (0x00): CONTROL_REG [R/W]
    // Bit 0: decoder_en, Bit 1: irq_clear
    logic [C_S_AXI_DATA_WIDTH-1:0] reg_control;

    // Register 1 (0x04): STATUS_REG [R]
    // Bit 0: irq_status
    logic [C_S_AXI_DATA_WIDTH-1:0] reg_status;

    // We will implement the AXI-Lite logic in the next sub-step.

endmodule