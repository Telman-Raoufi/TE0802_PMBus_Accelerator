//-----------------------------------------------------------------------------
// Company:          Personal Project
// Engineer:         Telman Raoufi
// 
// Create Date:      02/05/2026
// Design Name:      TE0802 PMBus Accelerator
// Module Name:      pmbus_tb
// Description:      Testbench to verify Start/Stop detection and 
//                   command decoding logic.
// 
// License:          MIT License
//-----------------------------------------------------------------------------

`timescale 1ns / 1ps

module tb_pmbus_top();

    // Clock and Reset
    logic clk = 0;
    logic rst_n = 0;
    always #5 clk = ~clk; // 100MHz clock

    // SMBus Signals
    wire sda_io, scl_io;
    logic sda_drive = 1'b1;
    logic scl_drive = 1'b1;

    // Use pull-ups for open-drain simulation
    pullup(sda_io);
    pullup(scl_io);

    // Drive pins: Only drive '0', else let pull-up take over
    assign sda_io = (sda_drive == 0) ? 1'b0 : 1'bz;
    assign scl_io = (scl_drive == 0) ? 1'b0 : 1'bz;

    // DUT Signals
    logic irq;

    // Instantiate Top-Level
    pmbus_top dut (
        .sda_io(sda_io),
        .scl_io(scl_io),
        .irq_o(irq),
        .s_axi_aclk(clk),
        .s_axi_aresetn(rst_n),
        // AXI signals tied off for basic FSM testing
        .s_axi_awvalid(1'b0),
        .s_axi_wvalid(1'b0),
        .s_axi_arvalid(1'b0),
        .s_axi_rready(1'b1),
        .s_axi_bready(1'b1)
    );

    // Task to simulate a START condition
    task send_start();
        sda_drive = 1; scl_drive = 1; #1000;
        sda_drive = 0; #1000; // SDA falls while SCL high
        scl_drive = 0; #1000;
    endtask

    // Task to send a byte
    task send_byte(input [7:0] data);
        for (int i=7; i>=0; i--) begin
            sda_drive = data[i]; #1000;
            scl_drive = 1;       #2000; // SCL High
            scl_drive = 0;       #1000;
        end
        // ACK bit
        sda_drive = 1; #1000;
        scl_drive = 1; #2000;
        scl_drive = 0; #1000;
    endtask

    initial begin
        #100 rst_n = 1;
        #1000;
        
        // Test Case 1: Send Address 0x55 and Command 0x8B (VOUT_READ)
        send_start();
        send_byte(8'hAA); // Address 0x55 (shifted) + Write bit 0
        send_byte(8'h8B); // PMBus Command ID
        
        #5000;
        if (irq) $display("SUCCESS: Interrupt Triggered on Command Decode!");
        else     $display("ERROR: Interrupt not triggered.");
        
        $finish;
    end

endmodule