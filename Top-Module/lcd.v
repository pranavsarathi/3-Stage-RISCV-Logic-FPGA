module lcd (
    input  wire        clk50,
    input  wire        reset,

    input  wire [127:0] line1,
    input  wire [127:0] line2,

    output reg         lcd_rs,
    output reg         lcd_en,
    output reg [7:0]   lcd_d
);

    // =========================================================
    // 50 MHz clock
    //
    // 1 clock = 20 ns
    // 50 clocks = 1 us
    // =========================================================

    localparam integer D_1US   = 50;
    localparam integer D_50US  = 2500;
    localparam integer D_100US = 5000;
    localparam integer D_200US = 10000;
    localparam integer D_2MS   = 100000;
    localparam integer D_5MS   = 250000;
    localparam integer D_20MS  = 1000000;

    reg [20:0] count;

    // =========================================================
    // FSM
    // =========================================================

    localparam [5:0]
        S_POWER_WAIT = 6'd0,

        S_INIT1      = 6'd1,
        S_INIT1_P    = 6'd2,
        S_INIT1_W    = 6'd3,

        S_INIT2      = 6'd4,
        S_INIT2_P    = 6'd5,
        S_INIT2_W    = 6'd6,

        S_INIT3      = 6'd7,
        S_INIT3_P    = 6'd8,
        S_INIT3_W    = 6'd9,

        S_FUNC       = 6'd10,
        S_FUNC_P     = 6'd11,
        S_FUNC_W     = 6'd12,

        S_OFF        = 6'd13,
        S_OFF_P      = 6'd14,
        S_OFF_W      = 6'd15,

        S_CLEAR      = 6'd16,
        S_CLEAR_P    = 6'd17,
        S_CLEAR_W    = 6'd18,

        S_ENTRY      = 6'd19,
        S_ENTRY_P    = 6'd20,
        S_ENTRY_W    = 6'd21,

        S_ON         = 6'd22,
        S_ON_P       = 6'd23,
        S_ON_W       = 6'd24,

        S_LINE1_CMD  = 6'd25,
        S_LINE1_CP   = 6'd26,
        S_LINE1_CW   = 6'd27,

        S_LINE1_CHAR = 6'd28,
        S_LINE1_CP2  = 6'd29,
        S_LINE1_CW2  = 6'd30,

        S_LINE2_CMD  = 6'd31,
        S_LINE2_CP   = 6'd32,
        S_LINE2_CW   = 6'd33,

        S_LINE2_CHAR = 6'd34,
        S_LINE2_CP2  = 6'd35,
        S_LINE2_CW2  = 6'd36;

    reg [5:0] state;

    // =========================================================
    // LCD transmission registers
    // =========================================================

    reg [7:0] tx_data;
    reg       tx_rs;

    // =========================================================
    // Line shift registers
    // =========================================================

    reg [127:0] line_shift;

    reg [4:0] char_index;

    // =========================================================
    // Utility: wait counter
    // =========================================================

    always @(posedge clk50) begin

        if (reset) begin

            state      <= S_POWER_WAIT;
            count      <= 21'd0;

            lcd_rs     <= 1'b0;
            lcd_en     <= 1'b0;
            lcd_d      <= 8'h00;

            tx_data    <= 8'h00;
            tx_rs      <= 1'b0;

            line_shift <= 128'd0;
            char_index <= 5'd0;

        end

        else begin

            case (state)

                // =================================================
                // POWER-UP WAIT
                // =================================================

                S_POWER_WAIT: begin

                    lcd_en <= 1'b0;

                    if (count == D_20MS - 1) begin
                        count   <= 21'd0;
                        tx_data <= 8'h30;
                        tx_rs   <= 1'b0;
                        state   <= S_INIT1;
                    end

                    else begin
                        count <= count + 1'b1;
                    end

                end


                // =================================================
                // 0x30 #1
                // =================================================

                S_INIT1: begin

                    lcd_rs <= tx_rs;
                    lcd_d  <= tx_data;
                    lcd_en <= 1'b0;

                    count <= 21'd0;
                    state <= S_INIT1_P;

                end

                S_INIT1_P: begin

                    lcd_en <= 1'b1;

                    if (count == D_1US - 1) begin
                        count <= 21'd0;
                        state <= S_INIT1_W;
                    end

                    else begin
                        count <= count + 1'b1;
                    end

                end

                S_INIT1_W: begin

                    lcd_en <= 1'b0;

                    if (count == D_5MS - 1) begin

                        count   <= 21'd0;
                        tx_data <= 8'h30;
                        tx_rs   <= 1'b0;

                        state <= S_INIT2;

                    end

                    else begin
                        count <= count + 1'b1;
                    end

                end


                // =================================================
                // 0x30 #2
                // =================================================

                S_INIT2: begin

                    lcd_rs <= tx_rs;
                    lcd_d  <= tx_data;
                    lcd_en <= 1'b0;

                    count <= 21'd0;
                    state <= S_INIT2_P;

                end

                S_INIT2_P: begin

                    lcd_en <= 1'b1;

                    if (count == D_1US - 1) begin
                        count <= 21'd0;
                        state <= S_INIT2_W;
                    end

                    else begin
                        count <= count + 1'b1;
                    end

                end

                S_INIT2_W: begin

                    lcd_en <= 1'b0;

                    if (count == D_200US - 1) begin

                        count   <= 21'd0;
                        tx_data <= 8'h30;
                        tx_rs   <= 1'b0;

                        state <= S_INIT3;

                    end

                    else begin
                        count <= count + 1'b1;
                    end

                end


                // =================================================
                // 0x30 #3
                // =================================================

                S_INIT3: begin

                    lcd_rs <= tx_rs;
                    lcd_d  <= tx_data;
                    lcd_en <= 1'b0;

                    count <= 21'd0;
                    state <= S_INIT3_P;

                end

                S_INIT3_P: begin

                    lcd_en <= 1'b1;

                    if (count == D_1US - 1) begin
                        count <= 21'd0;
                        state <= S_INIT3_W;
                    end

                    else begin
                        count <= count + 1'b1;
                    end

                end

                S_INIT3_W: begin

                    lcd_en <= 1'b0;

                    if (count == D_200US - 1) begin

                        count   <= 21'd0;

                        // 8-bit, 2-line, 5x8 font
                        tx_data <= 8'h38;
                        tx_rs   <= 1'b0;

                        state <= S_FUNC;

                    end

                    else begin
                        count <= count + 1'b1;
                    end

                end


                // =================================================
                // FUNCTION SET = 0x38
                // =================================================

                S_FUNC: begin

                    lcd_rs <= tx_rs;
                    lcd_d  <= tx_data;
                    lcd_en <= 1'b0;

                    count <= 21'd0;
                    state <= S_FUNC_P;

                end

                S_FUNC_P: begin

                    lcd_en <= 1'b1;

                    if (count == D_1US - 1) begin
                        count <= 21'd0;
                        state <= S_FUNC_W;
                    end

                    else begin
                        count <= count + 1'b1;
                    end

                end

                S_FUNC_W: begin

                    lcd_en <= 1'b0;

                    if (count == D_50US - 1) begin

                        count   <= 21'd0;
                        tx_data <= 8'h08;

                        state <= S_OFF;

                    end

                    else begin
                        count <= count + 1'b1;
                    end

                end


                // =================================================
                // DISPLAY OFF = 0x08
                // =================================================

                S_OFF: begin

                    lcd_rs <= 1'b0;
                    lcd_d  <= tx_data;
                    lcd_en <= 1'b0;

                    count <= 21'd0;
                    state <= S_OFF_P;

                end

                S_OFF_P: begin

                    lcd_en <= 1'b1;

                    if (count == D_1US - 1) begin
                        count <= 21'd0;
                        state <= S_OFF_W;
                    end

                    else begin
                        count <= count + 1'b1;
                    end

                end

                S_OFF_W: begin

                    lcd_en <= 1'b0;

                    if (count == D_50US - 1) begin

                        count   <= 21'd0;
                        tx_data <= 8'h01;

                        state <= S_CLEAR;

                    end

                    else begin
                        count <= count + 1'b1;
                    end

                end


                // =================================================
                // CLEAR = 0x01
                // =================================================

                S_CLEAR: begin

                    lcd_rs <= 1'b0;
                    lcd_d  <= tx_data;
                    lcd_en <= 1'b0;

                    count <= 21'd0;
                    state <= S_CLEAR_P;

                end

                S_CLEAR_P: begin

                    lcd_en <= 1'b1;

                    if (count == D_1US - 1) begin
                        count <= 21'd0;
                        state <= S_CLEAR_W;
                    end

                    else begin
                        count <= count + 1'b1;
                    end

                end

                S_CLEAR_W: begin

                    lcd_en <= 1'b0;

                    if (count == D_2MS - 1) begin

                        count   <= 21'd0;
                        tx_data <= 8'h06;

                        state <= S_ENTRY;

                    end

                    else begin
                        count <= count + 1'b1;
                    end

                end


                // =================================================
                // ENTRY MODE = 0x06
                // =================================================

                S_ENTRY: begin

                    lcd_rs <= 1'b0;
                    lcd_d  <= tx_data;
                    lcd_en <= 1'b0;

                    count <= 21'd0;
                    state <= S_ENTRY_P;

                end

                S_ENTRY_P: begin

                    lcd_en <= 1'b1;

                    if (count == D_1US - 1) begin
                        count <= 21'd0;
                        state <= S_ENTRY_W;
                    end

                    else begin
                        count <= count + 1'b1;
                    end

                end

                S_ENTRY_W: begin

                    lcd_en <= 1'b0;

                    if (count == D_50US - 1) begin

                        count   <= 21'd0;
                        tx_data <= 8'h0C;

                        state <= S_ON;

                    end

                    else begin
                        count <= count + 1'b1;
                    end

                end


                // =================================================
                // DISPLAY ON = 0x0C
                // =================================================

                S_ON: begin

                    lcd_rs <= 1'b0;
                    lcd_d  <= tx_data;
                    lcd_en <= 1'b0;

                    count <= 21'd0;
                    state <= S_ON_P;

                end

                S_ON_P: begin

                    lcd_en <= 1'b1;

                    if (count == D_1US - 1) begin
                        count <= 21'd0;
                        state <= S_ON_W;
                    end

                    else begin
                        count <= count + 1'b1;
                    end

                end

                S_ON_W: begin

                    lcd_en <= 1'b0;

                    if (count == D_50US - 1) begin

                        count      <= 21'd0;
                        char_index <= 5'd0;

                        line_shift <= line1;

                        tx_data <= 8'h80;
                        tx_rs   <= 1'b0;

                        state <= S_LINE1_CMD;

                    end

                    else begin
                        count <= count + 1'b1;
                    end

                end


                // =================================================
                // SET LINE 1 DDRAM = 0x80
                // =================================================

                S_LINE1_CMD: begin

                    lcd_rs <= 1'b0;
                    lcd_d  <= tx_data;
                    lcd_en <= 1'b0;

                    count <= 21'd0;
                    state <= S_LINE1_CP;

                end

                S_LINE1_CP: begin

                    lcd_en <= 1'b1;

                    if (count == D_1US - 1) begin
                        count <= 21'd0;
                        state <= S_LINE1_CW;
                    end

                    else begin
                        count <= count + 1'b1;
                    end

                end

                S_LINE1_CW: begin

                    lcd_en <= 1'b0;

                    if (count == D_50US - 1) begin

                        count <= 21'd0;
                        state <= S_LINE1_CHAR;

                    end

                    else begin
                        count <= count + 1'b1;
                    end

                end


                // =================================================
                // WRITE LINE 1 CHARACTERS
                // =================================================

                S_LINE1_CHAR: begin

                    lcd_rs <= 1'b1;
                    lcd_d  <= line_shift[127:120];
                    lcd_en <= 1'b0;

                    count <= 21'd0;
                    state <= S_LINE1_CP2;

                end

                S_LINE1_CP2: begin

                    lcd_en <= 1'b1;

                    if (count == D_1US - 1) begin
                        count <= 21'd0;
                        state <= S_LINE1_CW2;
                    end

                    else begin
                        count <= count + 1'b1;
                    end

                end

                S_LINE1_CW2: begin

                    lcd_en <= 1'b0;

                    if (count == D_50US - 1) begin

                        line_shift <= {line_shift[119:0],8'h20};

                        if (char_index == 5'd15) begin

                            char_index <= 5'd0;
                            line_shift <= line2;

                            tx_data <= 8'hC0;
                            tx_rs   <= 1'b0;

                            state <= S_LINE2_CMD;

                        end

                        else begin

                            char_index <= char_index + 1'b1;
                            state <= S_LINE1_CHAR;

                        end

                        count <= 21'd0;

                    end

                    else begin
                        count <= count + 1'b1;
                    end

                end


                // =================================================
                // SET LINE 2 DDRAM = 0xC0
                // =================================================

                S_LINE2_CMD: begin

                    lcd_rs <= 1'b0;
                    lcd_d  <= tx_data;
                    lcd_en <= 1'b0;

                    count <= 21'd0;
                    state <= S_LINE2_CP;

                end

                S_LINE2_CP: begin

                    lcd_en <= 1'b1;

                    if (count == D_1US - 1) begin
                        count <= 21'd0;
                        state <= S_LINE2_CW;
                    end

                    else begin
                        count <= count + 1'b1;
                    end

                end

                S_LINE2_CW: begin

                    lcd_en <= 1'b0;

                    if (count == D_50US - 1) begin

                        count <= 21'd0;
                        state <= S_LINE2_CHAR;

                    end

                    else begin
                        count <= count + 1'b1;
                    end

                end


                // =================================================
                // WRITE LINE 2
                // =================================================

                S_LINE2_CHAR: begin

                    lcd_rs <= 1'b1;
                    lcd_d  <= line_shift[127:120];
                    lcd_en <= 1'b0;

                    count <= 21'd0;
                    state <= S_LINE2_CP2;

                end

                S_LINE2_CP2: begin

                    lcd_en <= 1'b1;

                    if (count == D_1US - 1) begin
                        count <= 21'd0;
                        state <= S_LINE2_CW2;
                    end

                    else begin
                        count <= count + 1'b1;
                    end

                end

                S_LINE2_CW2: begin

                    lcd_en <= 1'b0;

                    if (count == D_50US - 1) begin

                        line_shift <= {line_shift[119:0],8'h20};

                        if (char_index == 5'd15) begin

                            char_index <= 5'd0;

                            // Restart display refresh.
                            line_shift <= line1;

                            tx_data <= 8'h80;
                            tx_rs   <= 1'b0;

                            state <= S_LINE1_CMD;

                        end

                        else begin

                            char_index <= char_index + 1'b1;
                            state <= S_LINE2_CHAR;

                        end

                        count <= 21'd0;

                    end

                    else begin
                        count <= count + 1'b1;
                    end

                end


                default: begin
                    state <= S_POWER_WAIT;
                    count <= 21'd0;
                end

            endcase

        end

    end

endmodule