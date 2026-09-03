module riscv #(
    parameter integer CPU_STEP_DIV = 25_000_000
)(
    input  wire clk50,
    input  wire reset,

    output wire lcd_rs,
    output wire lcd_en,
    output wire [7:0] lcd_d
);

    // =========================================================
    // REGISTER FILE
    // =========================================================

    reg [31:0] regs [0:31];
    integer i;

    // =========================================================
    // PROGRAM COUNTER
    // =========================================================

    reg [31:0] pc;

    // =========================================================
    // INSTRUCTIONS
    //
    // I1: ADD x7, x1, x2
    // I2: SUB x8, x3, x4
    // I3: MUL x9, x5, x6
    // =========================================================

    localparam [31:0] I1_ADD = 32'h002083B3;
    localparam [31:0] I2_SUB = 32'h40418433;
    localparam [31:0] I3_MUL = 32'h026284B3;

    localparam [31:0] NOP = 32'h00000013;

    // =========================================================
    // PIPELINE REGISTERS
    //
    // FETCH -> IF/ID -> DECODE -> ID/EX -> EXECUTE
    // =========================================================

    reg [31:0] if_id_instr;

    reg [31:0] id_ex_instr;
    reg [31:0] id_ex_rs1_data;
    reg [31:0] id_ex_rs2_data;

    // =========================================================
    // PIPELINE DISPLAY STATE
    //
    // 0 = empty
    // 1 = I1
    // 2 = I2
    // 3 = I3
    // =========================================================

    reg [2:0] fetch_stage;
    reg [2:0] decode_stage;
    reg [2:0] execute_stage;

    // =========================================================
    // CPU STEP
    //
    // 50 MHz / 25,000,000 = 2 Hz
    // One pipeline advance every 0.5 second
    // =========================================================

    reg [31:0] cpu_counter;
    reg        cpu_step;

    always @(posedge clk50) begin

        if (reset) begin
            cpu_counter <= 32'd0;
            cpu_step    <= 1'b0;
        end
        else begin

            if (cpu_counter == CPU_STEP_DIV - 1) begin
                cpu_counter <= 32'd0;
                cpu_step    <= 1'b1;
            end
            else begin
                cpu_counter <= cpu_counter + 1'b1;
                cpu_step    <= 1'b0;
            end

        end
    end

    // =========================================================
    // FETCH
    // =========================================================

    reg [31:0] fetched_instruction;

    always @(*) begin

        case (pc)

            32'd0:
                fetched_instruction = I1_ADD;

            32'd4:
                fetched_instruction = I2_SUB;

            32'd8:
                fetched_instruction = I3_MUL;

            default:
                fetched_instruction = NOP;

        endcase

    end

    // =========================================================
    // DECODE
    // =========================================================

    wire [4:0] dec_rs1;
    wire [4:0] dec_rs2;

    assign dec_rs1 = if_id_instr[19:15];
    assign dec_rs2 = if_id_instr[24:20];

    wire [31:0] dec_rs1_data;
    wire [31:0] dec_rs2_data;

    assign dec_rs1_data =
        (dec_rs1 == 5'd0) ? 32'd0 : regs[dec_rs1];

    assign dec_rs2_data =
        (dec_rs2 == 5'd0) ? 32'd0 : regs[dec_rs2];

    // =========================================================
    // EXECUTE
    // =========================================================

    wire [6:0] ex_opcode;
    wire [6:0] ex_funct7;
    wire [2:0] ex_funct3;

    wire [4:0] ex_rd;

    assign ex_opcode = id_ex_instr[6:0];
    assign ex_funct3 = id_ex_instr[14:12];
    assign ex_funct7 = id_ex_instr[31:25];

    assign ex_rd = id_ex_instr[11:7];

    reg [31:0] alu_result;

    always @(*) begin

        alu_result = 32'd0;

        if (ex_opcode == 7'b0110011) begin

            if (ex_funct3 == 3'b000) begin

                case (ex_funct7)

                    // ADD
                    7'b0000000:
                        alu_result =
                            id_ex_rs1_data +
                            id_ex_rs2_data;

                    // SUB
                    7'b0100000:
                        alu_result =
                            id_ex_rs1_data -
                            id_ex_rs2_data;

                    // MUL
                    7'b0000001:
                        alu_result =
                            id_ex_rs1_data *
                            id_ex_rs2_data;

                    default:
                        alu_result = 32'd0;

                endcase

            end

        end

    end

    // =========================================================
    // PIPELINE
    // =========================================================

    always @(posedge clk50) begin

        if (reset) begin

            pc <= 32'd0;

            if_id_instr <= NOP;

            id_ex_instr    <= NOP;
            id_ex_rs1_data <= 32'd0;
            id_ex_rs2_data <= 32'd0;

            fetch_stage   <= 3'd0;
            decode_stage  <= 3'd0;
            execute_stage <= 3'd0;

            // Clear register file
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'd0;

            // Test operands
            regs[1] <= 32'd5;
            regs[2] <= 32'd4;

            regs[3] <= 32'd5;
            regs[4] <= 32'd4;

            regs[5] <= 32'd5;
            regs[6] <= 32'd4;

        end

        else if (cpu_step) begin

            // =================================================
            // WRITEBACK
            // =================================================

            if (ex_rd != 5'd0)
                regs[ex_rd] <= alu_result;

            regs[0] <= 32'd0;

            // =================================================
            // DECODE -> EXECUTE
            // =================================================

            id_ex_instr    <= if_id_instr;
            id_ex_rs1_data <= dec_rs1_data;
            id_ex_rs2_data <= dec_rs2_data;

            // =================================================
            // FETCH -> DECODE
            // =================================================

            if_id_instr <= fetched_instruction;

            // =================================================
            // PC
            // =================================================

            if (pc < 32'd12)
                pc <= pc + 32'd4;

            // =================================================
            // PIPELINE VISUALIZATION
            // =================================================

            case (pc)

                32'd0:
                    fetch_stage <= 3'd1;

                32'd4:
                    fetch_stage <= 3'd2;

                32'd8:
                    fetch_stage <= 3'd3;

                default:
                    fetch_stage <= 3'd0;

            endcase

            decode_stage  <= fetch_stage;
            execute_stage <= decode_stage;

        end

    end

    // =========================================================
    // CONVERT PIPELINE NUMBER TO ASCII
    // =========================================================

    function [7:0] stage_char;
        input [2:0] stage;

        begin

            case (stage)

                3'd1: stage_char = "1";
                3'd2: stage_char = "2";
                3'd3: stage_char = "3";

                default:
                    stage_char = "-";

            endcase

        end
    endfunction

    // =========================================================
    // 2-DIGIT DECIMAL ASCII
    // =========================================================

    function [15:0] decimal_2;
        input [31:0] value;

        reg [7:0]tens;
        reg [7:0]ones;

        begin

            tens = (value % 100) / 10;
            ones = value % 10;

            decimal_2 = {
                (8'h30 + tens),
                (8'h30 + ones)
            };

        end
    endfunction

    // =========================================================
    // LCD TEXT
    //
    // 16 CHARACTERS EXACTLY
    //
    // LINE 1:
    // F:I1 D:I2 E:I3
    //
    // LINE 2:
    // X7:30 X8:35 X9:42
    // =========================================================

    reg [127:0] lcd_line1;
    reg [127:0] lcd_line2;
// =========================================================

always @(*) begin

    // Line 1:
    // F:I1 D:I2 E:I3
    lcd_line1 = {
        "FET:",
        stage_char(fetch_stage),
        "DEC:",
        stage_char(decode_stage),
        "EXE:",
        stage_char(execute_stage),
        " "
    };

    // Line 2:
    // X7:30 X8:35 X9:42
    lcd_line2 = {
        "X7:",
        decimal_2(regs[7]),
        "X8:",
        decimal_2(regs[8]),
        "X9:",
        decimal_2(regs[9]),
        " "
        
    };

end

// =========================================================
// LCD CONTROLLER
// =========================================================

lcd LCD (
    .clk50   (clk50),
    .reset   (reset),

    .line1   (lcd_line1),
    .line2   (lcd_line2),

    .lcd_rs  (lcd_rs),
    .lcd_en  (lcd_en),
    .lcd_d   (lcd_d)
);

endmodule