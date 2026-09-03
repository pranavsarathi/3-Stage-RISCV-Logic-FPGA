# 🛠️ 3-STAGE PIPELINED RISC-V LOGIC ON FPGA

A simple **32-bit 3-stage pipelined RISC-V processor** implemented on an **AMD Xilinx Spartan-7 FPGA**, with ALU results displayed on a **16×2 HD44780-compatible LCD**.

## 📋 PROJECT SPECS

| Parameter | Value |
|---|---|
| FPGA Board | EDGE Spartan-7 Development Board |
| FPGA | AMD Xilinx XC7S15FTGB196-1 |
| FPGA Family | Spartan-7 |
| Package | FTGB196 |
| FPGA Clock | 50 MHz |
| Clock Period | 20 ns |
| CPU Step Divider | 25,000,000 cycles |
| CPU Step Interval | 0.5 s |
| CPU Debug Step Frequency | 2 Hz |
| Processor | 32-bit RISC-V |
| Pipeline | 3-stage |
| Stages | Fetch → Decode → Execute |
| Display | HD44780-compatible 16×2 LCD |
| LCD Interface | 8-bit parallel |
| Tool | AMD Xilinx Vivado 2025 |

## 🎯 PROJECT GOAL

Implement a **3-stage pipelined 32-bit RISC-V processor** on the Spartan-7 FPGA and demonstrate ALU execution using:

**ADD • SUB • MUL**

The calculated results are displayed on a **16×2 LCD**.

## 🧮 RISC-V OPERATIONS

| Instruction | Operation | Result |
|---|---|---|
| `ADD x7, x1, x2` | `x7 = x1 + x2` | `09` |
| `SUB x8, x3, x4` | `x8 = x3 - x4` | `01` |
| `MUL x9, x5, x6` | `x9 = x5 × x6` | `20` |

### Input Values

```text
x1 = 5
x2 = 4

x3 = 5
x4 = 4

x5 = 5
x6 = 4
```

### Expected Output

```text
x7 = 09
x8 = 01
x9 = 20
```

## 🧠 BASIC PROCESSOR FLOW

```text
             RISC-V INSTRUCTION
                     │
                     ▼
                  FETCH
                     │
                     ▼
                  DECODE
                     │
                     ▼
                 EXECUTE
                     │
                     ▼
                    ALU
                     │
                     ▼
               REGISTER FILE
                     │
              ┌──────┼──────┐
              ▼      ▼      ▼
             x7     x8      x9
```

The processor is pipelined, so different instructions can occupy different stages at the same time.

### Pipeline Example

| Cycle | Fetch | Decode | Execute |
|---:|---|---|---|
| 1 | ADD | — | — |
| 2 | SUB | ADD | — |
| 3 | MUL | SUB | ADD |
| 4 | — | MUL | SUB |
| 5 | — | — | MUL |

## 📦 RISC-V INSTRUCTION FORMAT

The instructions used in this project are **32-bit R-type instructions**.

```text
31          25 24     20 19     15 14   12 11      7 6       0
┌─────────────┬─────────┬─────────┬───────┬─────────┬─────────┐
│   funct7    │   rs2   │   rs1   │funct3 │   rd    │ opcode  │
└─────────────┴─────────┴─────────┴───────┴─────────┴─────────┘
     7 bits      5 bits    5 bits   3 bits   5 bits    7 bits
```

| Field | Size | Purpose |
|---|---:|---|
| `opcode` | 7 bits | Instruction type |
| `funct7` | 7 bits | Operation variation |
| `funct3` | 3 bits | Operation category |
| `rs1` | 5 bits | Source register 1 |
| `rs2` | 5 bits | Source register 2 |
| `rd` | 5 bits | Destination register |

For this project:

```text
ADD → funct7 = 0000000
SUB → funct7 = 0100000
MUL → funct7 = 0000001
```

For these R-type ALU operations:

```text
opcode = 0110011
funct3 = 000
```

## ⏱️ FPGA CLOCK → CPU DEBUG STEP

The FPGA itself runs at:

```text
50 MHz
```

Therefore:

```text
1 clock cycle = 20 ns
```

For easy observation, the CPU is intentionally stepped slowly using a clock divider:

```text
25,000,000 FPGA clock cycles
              ↓
25,000,000 × 20 ns
              ↓
          0.5 second
              ↓
     One controlled CPU step
```

Therefore:

```text
CPU step frequency = 1 / 0.5
                   = 2 Hz
```

> **Note:** This divider is only used for debugging and visualization. It is not the maximum operating frequency of the processor.

## 📺 LCD DISPLAY

The LCD is:

**16 columns × 2 rows**

Therefore:

```text
16 characters per line
```

The LCD uses an **8-bit parallel interface**, so each character is transferred as 8 bits.

```text
16 characters × 8 bits
= 128 bits
```

Therefore:

```verilog
input wire [127:0] line1;
input wire [127:0] line2;
```

## 🔄 HOW TEXT REACHES THE LCD

The 128-bit line is treated as a character buffer.

```text
128-bit buffer
      ↓
 Take 8 bits
      ↓
 Send one character
      ↓
 Shift buffer by 8 bits
      ↓
 Take next 8 bits
      ↓
 Send next character
      ↓
    Repeat
```

Example:

```text
"HELLO           "

H → E → L → L → O → ...
```

The controller uses:

```verilog
reg [127:0] line_shift;
```

The next character is taken from:

```verilog
lcd_d <= line_shift[127:120];
```

Then the buffer is shifted by one character:

```verilog
line_shift <= {line_shift[119:0], 8'h20};
```

`8'h20` represents a space character.

A character counter keeps track of the 16 characters being sent:

```verilog
reg [4:0] char_index;
```

## 🎛️ LCD CONTROL

The FPGA sends three important signals:

```text
RS
EN
D[7:0]
```

### RS — Register Select

```text
RS = 0 → Command / Instruction
RS = 1 → Character / Display Data
```

### EN — Enable

The LCD captures the current command/data during the required enable pulse.

```text
EN

0 ───── 1 ───── 0
        ↑
     Capture
```

### D[7:0] — Data Bus

This is the actual 8-bit command or character being sent to the LCD.

Example:

```text
'A' = 0x41
```

## ⚙️ LCD FSM

The LCD controller is implemented using a **Finite State Machine (FSM)**.

After reset:

```text
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
```

The FSM controls:

- RS
- EN
- D[7:0]
- LCD timing
- Character index
- Line selection

The required LCD timing is generated from the **50 MHz FPGA clock** using counters.

## 🔌 FPGA → LCD CONNECTION

The Verilog signal names are **logical signals**.

The XDC constraints assign those signals to physical FPGA package pins.

```text
Verilog Signal
      ↓
XDC PACKAGE_PIN
      ↓
FPGA Physical Pin
      ↓
PCB Trace
      ↓
J2 Connector
      ↓
LCD Pin
```

### LCD Pin Mapping

| Verilog Signal | FPGA Pin | Board Connector | LCD |
|---|---|---|---|
| `lcd_rs` | M5 | J2 | RS |
| `lcd_en` | P5 | J2 | EN |
| `lcd_d[0]` | M4 | J2 | D0 |
| `lcd_d[1]` | L5 | J2 | D1 |
| `lcd_d[2]` | P11 | J2 | D2 |
| `lcd_d[3]` | N11 | J2 | D3 |
| `lcd_d[4]` | P13 | J2 | D4 |
| `lcd_d[5]` | M14 | J2 | D5 |
| `lcd_d[6]` | M12 | J2 | D6 |
| `lcd_d[7]` | K12 | J2 | D7 |

> **Important:** No CPU/software address is involved in this physical connection. The XDC file maps the Verilog ports to the FPGA's physical pins, and the board PCB routes those pins to the LCD connector.

## 🔗 COMPLETE PROJECT FLOW

```text
              50 MHz FPGA CLOCK
                     │
                     ▼
              CLOCK DIVIDER
                     │
                     ▼
              RISC-V PIPELINE
                     │
          ┌──────────┼──────────┐
          ▼          ▼          ▼
        FETCH      DECODE    EXECUTE
                                │
                                ▼
                               ALU
                                │
                    ┌───────────┼───────────┐
                    ▼           ▼           ▼
                 ADD x7      SUB x8      MUL x9
                    │           │           │
                    └───────────┼───────────┘
                                ▼
                         REGISTER FILE
                                │
                                ▼
                         16×2 LCD DISPLAY
                                │
                                ▼
                     ┌─────────────────┐
                     │ ADD : 09        │
                     │ SUB : 01        │
                     │ MUL : 20        │
                     └─────────────────┘
```

## 📁 PROJECT STRUCTURE

```text
3-Stage-RISCV-Logic-FPGA/
│
├── Constraints/
│   └── riscv.xdc
│
├── Top-Module/
│   ├── riscv.v
│   └── lcd.v
│
├── Img.jpeg
│
└── README.md
```

## 🛠️ TOOLS

- AMD Xilinx Vivado
- Verilog HDL
- RISC-V ISA
- Spartan-7 FPGA
- HD44780-compatible LCD

## ✅ RESULT

The processor performs:

```text
ADD → 5 + 4 = 09
SUB → 5 - 4 = 01
MUL → 5 × 4 = 20
```

The results are processed by the **RISC-V ALU** and displayed on the **16×2 LCD** connected directly to the Spartan-7 FPGA.

---

## 🚀 PROJECT STATUS

**Working Prototype ✅**

- [x] 32-bit RISC-V datapath
- [x] Fetch stage
- [x] Decode stage
- [x] Execute stage
- [x] ADD
- [x] SUB
- [x] MUL
- [x] Register file
- [x] 16×2 LCD interface
- [x] LCD FSM
- [x] FPGA pin constraints
- [x] Hardware demonstration
