//-----------------------------------------------------------------------------
// Company:          Personal Project
// Engineer:         Telman Raoufi
// 
// Create Date:      02/04/2026
// Design Name:      TE0802 PMBus Accelerator
// Module Name:      pmbus_detector
// Target Devices:   Xilinx Zynq UltraScale+ (TE0802)
// Tool Versions:    Vivado 2023.2+
// Description:      Detects Start and Stop conditions on the SMBus.
//                   Includes a 3-tap debouncer for noise immunity.
// 
// License:          MIT License
//-----------------------------------------------------------------------------

module pmbus_detector (
    input  logic clk,           // High-speed system clock (e.g., 100MHz)
    input  logic rreset_n,
    input  logic sda_in,        // From smbus_phy
    input  logic scl_in,        // From smbus_phy
    output logic start_detect,  // High for one clock cycle on Start/Repeated Start
    output logic stop_detect    // High for one clock cycle on Stop
);

    // Synchronizer & Debouncer Shift Registers
    logic [2:0] sda_sync, scl_sync;
    logic sda_debounced, scl_debounced;
    logic sda_prev;

    // 1. Synchronize and Debounce Inputs
    always_ff @(posedge clk) begin
        if (!rreset_n) begin
            sda_sync <= 3'b111;
            scl_sync <= 3'b111;
            sda_debounced <= 1'b1;
            scl_debounced <= 1'b1;
        end else begin
            sda_sync <= {sda_sync[1:0], sda_in};
            scl_sync <= {scl_sync[1:0], scl_in};
            
            // Majority vote debouncer (2 out of 3)
            sda_debounced <= (sda_sync[2] & sda_sync[1]) | (sda_sync[1] & sda_sync[0]) | (sda_sync[2] & sda_sync[0]);
            scl_debounced <= (scl_sync[2] & scl_sync[1]) | (scl_sync[1] & scl_sync[0]) | (scl_sync[2] & scl_sync[0]);
        end
    end

    // 2. Edge Detection for Start/Stop
    always_ff @(posedge clk) begin
        if (!rreset_n) begin
            sda_prev     <= 1'b1;
            start_detect <= 1'b0;
            stop_detect  <= 1'b0;
        end else begin
            sda_prev <= sda_debounced;
            
            // START: SDA falling while SCL is High
            if (scl_debounced && sda_prev && !sda_debounced) begin
                start_detect <= 1'b1;
            end else begin
                start_detect <= 1'b0;
            end

            // STOP: SDA rising while SCL is High
            if (scl_debounced && !sda_prev && sda_debounced) begin
                stop_detect <= 1'b1;
            end else begin
                stop_detect <= 1'b0;
            end
        end
    end

endmodule