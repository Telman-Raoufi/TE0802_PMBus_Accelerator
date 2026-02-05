//-----------------------------------------------------------------------------
// Company:          Personal Project
// Engineer:         Telman Raoufi
// 
// Create Date:      02/05/2026
// Design Name:      TE0802 PMBus Accelerator
// Module Name:      pmbus_fsm
// Target Devices:   Xilinx Zynq UltraScale+ (TE0802)
// Tool Versions:    Vivado 2023.2+
// Description:      Core State Machine to parse SMBus transactions.
//                   Detects Address, Command ID, and Data phases to offload
//                   firmware processing.
// 
// License:          MIT License
//-----------------------------------------------------------------------------

module pmbus_fsm (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start_detect,
    input  logic        stop_detect,
    input  logic        scl_debounced,
    input  logic        sda_debounced,
    
    // Interface to Register Bank
    output logic [7:0]  decoded_cmd,
    output logic [31:0] decoded_data_0,
    output logic        irq_status,
    input  logic        irq_clear
);

    typedef enum logic [2:0] {
        IDLE       = 3'b000,
        ADDR_PHASE = 3'b001,
        CMD_PHASE  = 3'b010,
        DATA_PHASE = 3'b011,
        ACK_WAIT   = 3'b100
    } state_t;

    state_t state;
    logic [3:0] bit_cnt;
    logic [7:0] shift_reg;
    logic scl_prev;

    // Detect SCL Rising Edge for sampling
    always_ff @(posedge clk) begin
        if (!rst_n) scl_prev <= 1'b1;
        else        scl_prev <= scl_debounced;
    end
    wire scl_posedge = (scl_debounced && !scl_prev);

    // Main FSM
    always_ff @(posedge clk) begin
        if (!rst_n || start_detect) begin
            state <= (start_detect) ? ADDR_PHASE : IDLE;
            bit_cnt <= 0;
            irq_status <= 0;
        end else begin
            if (irq_clear) irq_status <= 1'b0;

            case (state)
                IDLE: begin
                    if (start_detect) state <= ADDR_PHASE;
                end

                ADDR_PHASE: begin
                    if (scl_posedge) begin
                        shift_reg <= {shift_reg[6:0], sda_debounced};
                        if (bit_cnt == 7) begin // 7 bits addr + 1 bit R/W
                            bit_cnt <= 0;
                            state <= ACK_WAIT;
                        end else bit_cnt <= bit_cnt + 1;
                    end
                end

                ACK_WAIT: begin // Simplified: Skip ACK bit and move to Command
                    if (scl_posedge) state <= CMD_PHASE;
                end

                CMD_PHASE: begin
                    if (scl_posedge) begin
                        shift_reg <= {shift_reg[6:0], sda_debounced};
                        if (bit_cnt == 7) begin
                            decoded_cmd <= {shift_reg[6:0], sda_debounced};
                            bit_cnt <= 0;
                            irq_status <= 1'b1; // Trigger Interrupt
                            state <= IDLE;      
                        end else bit_cnt <= bit_cnt + 1;
                    end
                end
            endcase
            if (stop_detect) state <= IDLE;
        end
    end

endmodule