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

    //-------------------------------------------------------------------------
    // AXI-Lite Write Logic
    //-------------------------------------------------------------------------
    assign S_AXI_AWREADY = ~S_AXI_BVALID; // Ready for address if not finishing a transaction
    assign S_AXI_WREADY  = ~S_AXI_BVALID; // Ready for data if not finishing a transaction
    assign S_AXI_BRESP   = 2'b00;         // OKAY response

    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_BVALID <= 1'b0;
            reg_control  <= 32'h0;
        end else begin
            // Write Transaction
            if (S_AXI_AWVALID && S_AXI_WVALID && !S_AXI_BVALID) begin
                S_AXI_BVALID <= 1'b1;
                case (S_AXI_AWADDR[4:2])
                    3'b000: reg_control <= S_AXI_WDATA; // Offset 0x00
                endcase
            end else if (S_AXI_BREADY && S_AXI_BVALID) begin
                S_AXI_BVALID <= 1'b0;
            end
        end
    end

    // Map internal signals to registers
    assign decoder_en = reg_control[0];
    assign irq_clear  = reg_control[1];
    
    // Status Register Mapping
    assign reg_status = {31'h0, irq_status};

    //-------------------------------------------------------------------------
    // AXI-Lite Read Logic
    //-------------------------------------------------------------------------
    assign S_AXI_ARREADY = ~S_AXI_RVALID;
    assign S_AXI_RRESP   = 2'b00; // OKAY response

    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_RVALID <= 1'b0;
            S_AXI_RDATA  <= 32'h0;
        end else begin
            if (S_AXI_ARVALID && !S_AXI_RVALID) begin
                S_AXI_RVALID <= 1'b1;
                case (S_AXI_ARADDR[4:2])
                    3'b000: S_AXI_RDATA <= reg_control;
                    3'b001: S_AXI_RDATA <= reg_status;
                    3'b010: S_AXI_RDATA <= {24'h0, decoded_cmd};
                    3'b011: S_AXI_RDATA <= decoded_data_0;
                    3'b100: S_AXI_RDATA <= decoded_data_1;
                    default: S_AXI_RDATA <= 32'hDEADBEEF;
                endcase
            end else if (S_AXI_RREADY && S_AXI_RVALID) begin
                S_AXI_RVALID <= 1'b0;
            end
        end
    end

endmodule