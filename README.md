3-STAGE PIPELINED RISC-V LOGIC ON FPGA
🛠️ PROJECT SPECS
Parameter	Value
FPGA Board	EDGE Spartan-7 Development Board
FPGA	AMD Xilinx XC7S15FTGB196-1
FPGA Family	Spartan-7
Package	FTGB196
FPGA Clock	50 MHz
Clock Period	20 ns
CPU Step Divider	25,000,000 cycles
CPU Step Interval	0.5 s
CPU Debug Step Frequency	2 Hz
Processor	32-bit RISC-V
Pipeline	3-stage
Stages	Fetch → Decode → Execute
Display	HD44780 16×2 LCD
LCD Interface	8-bit parallel
Tool	AMD Xilinx Vivado 2025
🎯 PROJECT GOAL

Implement a 3-stage pipelined 32-bit RISC-V processor on the Spartan-7 FPGA and demonstrate ALU execution using:

ADD
SUB
MUL

The calculated results are displayed on a 16×2 HD44780 LCD.

🧮 RISC-V OPERATIONS
ADD x7, x1, x2
x7 = x1 + x2

SUB x8, x3, x4
x8 = x3 - x4

MUL x9, x5, x6
x9 = x5 × x6
Input values
x1 = 5      x2 = 4
x3 = 5      x4 = 4
x5 = 5      x6 = 4
Expected output
x7 = 09
x8 = 01
x9 = 20
🧠 BASIC PROCESSOR FLOW
        RISC-V INSTRUCTION
                ↓
             FETCH
                ↓
             DECODE
                ↓
             EXECUTE
                ↓
               ALU
                ↓
          REGISTER FILE
                ↓
          x7 / x8 / x9

The processor is pipelined, so different instructions can occupy different stages at the same time.

Cycle       Fetch       Decode       Execute

  1          ADD
  2          SUB          ADD
  3          MUL          SUB          ADD
  4                       MUL          SUB
  5                                    MUL
📦 RISC-V INSTRUCTION FORMAT

The instructions are 32-bit R-type instructions.

31       25 24    20 19    15 14   12 11     7 6       0
┌──────────┬────────┬────────┬───────┬────────┬─────────┐
│ funct7   │  rs2   │  rs1   │funct3 │   rd   │ opcode  │
└──────────┴────────┴────────┴───────┴────────┴─────────┘
   7 bits     5        5        3        5        7
opcode → instruction type
funct7 → operation variation
funct3 → operation category
rs1    → source register 1
rs2    → source register 2
rd     → destination register

For this project:

ADD → funct7 = 0000000
SUB → funct7 = 0100000
MUL → funct7 = 0000001
⏱️ FPGA CLOCK → CPU DEBUG STEP

The FPGA itself runs at:

50 MHz

Therefore:

1 clock = 20 ns

For easy observation, the CPU is intentionally stepped slowly:

25,000,000 FPGA clocks
        ↓
25,000,000 × 20 ns
        ↓
0.5 second
        ↓
one controlled CPU step

Therefore:

CPU step frequency = 1 / 0.5
                   = 2 Hz

This divider is only for debugging/visualization.

📺 LCD DISPLAY

The LCD is:

16 columns × 2 rows

So:

16 characters
       ×
2 lines

Each character is transferred as 8 bits in the LCD's 8-bit parallel interface.

Therefore one complete line requires:

16 × 8 = 128 bits

Hence:

input wire [127:0] line1;
input wire [127:0] line2;
🔄 HOW TEXT REACHES THE LCD

The 128-bit line is treated as a character buffer.

128-bit buffer
      ↓
take 8 bits
      ↓
send one character
      ↓
shift 8 bits
      ↓
take next 8 bits
      ↓
send next character
      ↓
repeat

Example:

"HELLO           "

H → E → L → L → O → ...

The controller uses:

reg [127:0] line_shift;

and sends:

lcd_d <= line_shift[127:120];

Then shifts the buffer by one character.

char_index keeps track of how many of the 16 characters have already been sent.

🎛️ LCD CONTROL

The FPGA sends three important signals:

RS
EN
D[7:0]
RS — Register Select
RS = 0 → command
RS = 1 → character/data
EN — Enable

The LCD captures the current command/data when the controller generates the required EN pulse.

EN:  0 ─── 1 ─── 0
          ↑
       capture
D[7:0]

The actual 8-bit command or character.

Example:

'A' = 0x41
⚙️ LCD FSM

The LCD controller is implemented as a Finite State Machine.

After reset:

RESET
  ↓
POWER WAIT
  ↓
LCD INITIALIZATION
  ↓
DISPLAY CONFIGURATION
  ↓
LINE 1
  ↓
LINE 2
  ↓
REPEAT

The FSM controls:

RS
EN
D[7:0]
timing
character index
line selection

The timing is generated from the 50 MHz FPGA clock using counters.

🔌 FPGA → LCD CONNECTION

The Verilog signal names are logical signals.

The XDC constraints assign those signals to physical FPGA package pins.

Verilog
   ↓
XDC PACKAGE_PIN
   ↓
FPGA physical pin
   ↓
PCB trace
   ↓
J2 connector
   ↓
LCD
Pin mapping
Verilog	FPGA Pin	Board	LCD
lcd_rs	M5	J2	RS
lcd_en	P5	J2	EN
lcd_d[0]	M4	J2	D0
lcd_d[1]	L5	J2	D1
lcd_d[2]	P11	J2	D2
lcd_d[3]	N11	J2	D3
lcd_d[4]	P13	J2	D4
lcd_d[5]	M14	J2	D5
lcd_d[6]	M12	J2	D6
lcd_d[7]	K12	J2	D7

No CPU/software address is involved here.
This is a direct electrical connection defined by the FPGA's pin assignment and the board PCB routing.
