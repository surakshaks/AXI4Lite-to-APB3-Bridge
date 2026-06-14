# AXI4-Lite to APB3 Bridge

### RTL Design, Functional Verification and FPGA Synthesis using SystemVerilog, UVM, QuestaSim and Vivado

![SystemVerilog](https://img.shields.io/badge/SystemVerilog-RTL-blue)
![UVM](https://img.shields.io/badge/UVM-Verification-green)
![QuestaSim](https://img.shields.io/badge/Simulator-QuestaSim-purple)
![Vivado](https://img.shields.io/badge/FPGA-Vivado-orange)
![Coverage](https://img.shields.io/badge/Functional_Coverage-90.47%25-brightgreen)

---

# Project Overview

This project implements an AXI4-Lite to APB3 Bridge using SystemVerilog and verifies its functionality using Universal Verification Methodology (UVM).

The bridge performs protocol conversion between the AXI4-Lite protocol, commonly used for processor register access and memory-mapped control interfaces, and the Advanced Peripheral Bus (APB3), which is widely used for low-power peripherals in System-on-Chip (SoC) architectures.

The design includes protocol translation, address decoding, response generation, error propagation, functional verification, assertion-based checking, functional coverage collection, and FPGA synthesis analysis.

---

# Problem Statement

Modern SoCs use multiple bus protocols optimized for different performance requirements.

* AXI4-Lite is used for high-performance processor communication.
* APB3 is used for low-power peripheral communication.

A bridge is required to translate AXI transactions into APB transactions while preserving protocol correctness, transaction ordering, data integrity, and error reporting.

This project implements such a bridge and verifies its functionality using an industry-standard UVM verification methodology.

---

# System Architecture

## Block Diagram

```text
                    AXI4-Lite Domain

┌──────────────────────────────────────────────┐
│                                              │
│              AXI4-Lite Master                │
│                                              │
│  AWADDR  AWVALID  AWREADY                    │
│  WDATA   WVALID   WREADY                     │
│  BRESP   BVALID   BREADY                     │
│  ARADDR  ARVALID  ARREADY                    │
│  RDATA   RRESP    RVALID                     │
│                                              │
└─────────────────────┬────────────────────────┘
                      │
                      ▼

┌──────────────────────────────────────────────┐
│                                              │
│            AXI4-Lite to APB Bridge           │
│                                              │
│  • AXI Interface Logic                       │
│  • Transaction Controller                    │
│  • Address Decoder                           │
│  • APB Interface Logic                       │
│  • Response Generation                       │
│  • Error Handling Logic                      │
│                                              │
└─────────────────────┬────────────────────────┘
                      │
                      ▼

┌──────────────────────────────────────────────┐
│                 APB Decoder                  │
└───────┬───────────┬───────────┬──────────────┘
        │           │           │
        ▼           ▼           ▼

      GPIO        UART        SPI
      Slave0      Slave1      Slave2

                    ▼
                 TIMER
                 Slave3
```

---

# Protocol Overview

## AXI4-Lite Interface

The bridge supports the following AXI4-Lite channels:

### Write Path

* AW Channel (Write Address)
* W Channel (Write Data)
* B Channel (Write Response)

### Read Path

* AR Channel (Read Address)
* R Channel (Read Data)

AXI communication uses the VALID/READY handshake protocol.

---

## APB3 Interface

The bridge generates APB3 transactions using:

* PADDR
* PSEL
* PENABLE
* PWRITE
* PWDATA
* PRDATA
* PREADY
* PSLVERR

APB transactions occur in two phases:

1. Setup Phase
2. Access Phase

---

# FSM Design

The protocol conversion mechanism is controlled using a Finite State Machine (FSM).

## FSM State Diagram

```text
                 AXI Request
                      │
                      ▼

                ┌──────────┐
                │  IDLE    │
                └────┬─────┘
                     │
                     ▼

                ┌──────────┐
                │  SETUP   │
                └────┬─────┘
                     │
                     ▼

                ┌──────────┐
                │ ENABLE   │
                └────┬─────┘
                     │
             ┌───────┴───────┐
             │               │
        PREADY=1        PREADY=0
             │               │
             ▼               ▼

           IDLE           WAIT
                            │
                       PREADY=1
                            │
                            ▼
                          IDLE
```

## FSM States

| State  | Function                   |
| ------ | -------------------------- |
| IDLE   | Waits for AXI transaction  |
| SETUP  | APB setup phase            |
| ENABLE | APB access phase           |
| WAIT   | Waits for PREADY assertion |

---

# Address Mapping

The APB decoder selects one of four peripheral regions.

| Peripheral | Base Address |
| ---------- | ------------ |
| GPIO       | 0x0000_0000  |
| UART       | 0x0000_1000  |
| SPI        | 0x0000_2000  |
| TIMER      | 0x0000_3000  |

Address decoding is performed using:

```systemverilog
paddr[13:12]
```

---

# RTL Modules

## axi2apb_bridge.sv

Top-level bridge module responsible for:

* AXI transaction capture
* APB transaction generation
* Response generation
* Error propagation

---

## axi2apb_fsm.sv

Implements the protocol conversion FSM.

Responsibilities:

* Transaction sequencing
* APB setup phase generation
* APB access phase generation
* Response control

---

## apb_decoder.sv

Responsible for:

* Address decoding
* PSEL generation
* Peripheral selection

---

# UVM Verification Environment

The design is verified using Universal Verification Methodology (UVM).

## Verification Architecture

```text
                 UVM TEST

                     │

                     ▼

                 UVM ENV

       ┌─────────────┼─────────────┐
       │             │             │
       ▼             ▼             ▼

     AGENT      SCOREBOARD     COVERAGE

       │

       ▼

    DRIVER

       │

       ▼

      DUT

       │

       ▼

    MONITOR

       │

       ▼

   APB SLAVE MODEL
```

---

# Verification Components

## Driver

Converts sequence items into pin-level AXI transactions.

## Monitor

Observes DUT activity and publishes transactions.

## Scoreboard

Performs expected-versus-actual comparison.

## Coverage Collector

Measures verification completeness.

## Assertions

Continuously monitor protocol compliance.

---

# Verification Scenarios

| Test Case                | Objective                  |
| ------------------------ | -------------------------- |
| Single Write Transaction | Verify write path          |
| Single Read Transaction  | Verify read path           |
| Randomized Transactions  | Stress protocol behavior   |
| Error Injection          | Verify PSLVERR propagation |
| Multiple Slave Access    | Verify address decoder     |

---

# Assertion-Based Verification

SystemVerilog Assertions (SVA) were implemented to verify:

* AXI VALID/READY handshakes
* APB setup-access sequence
* Address stability
* Data stability
* Error response behavior

## Assertion Results

| Metric             | Result |
| ------------------ | ------ |
| Assertion Failures | 0      |
| Assertion Status   | PASS   |

---

# Functional Coverage Results

Coverage was collected using covergroups.

## Overall Functional Coverage

```text
90.47%
```

## Coverpoint Results

| Coverpoint            | Coverage |
| --------------------- | -------- |
| APB Slave Selection   | 100%     |
| Read Operations       | 100%     |
| Write Operations      | 100%     |
| Response Coverage     | 100%     |
| Write Strobe Coverage | 100%     |

---

# Scoreboard Results

The scoreboard performed end-to-end transaction checking.

Results:

* Write PASS : 72
* Read PASS : 16
* Read FAIL : 0
* SLVERR Cases Observed : 46

All scoreboard checks passed successfully.

---

# FPGA Synthesis Results

Target Device:

```text
Xilinx Artix-7
xc7a100tcsg324-1
```

## Synthesis Status

| Stage                 | Result |
| --------------------- | ------ |
| RTL Analysis          | PASS   |
| Elaboration           | PASS   |
| Synthesis             | PASS   |
| Synthesized Floorplan | PASS   |
| Implementation        | FAILED |

### Implementation Limitation

The design exposes complete AXI and APB interfaces at the top level.

```text
Required I/O Ports : 248
Available FPGA Pins : 210
```

As a result, FPGA implementation could not be completed on the selected Artix-7 package without introducing a wrapper design.

---

# Repository Structure

```text
axi4lite-to-apb-bridge/
│
├── rtl/
├── uvm/
├── assertions/
├── simulation/
├── docs/
├── reports/
└── README.md
```

---

# Screenshots Included

The repository includes:

* Architecture Diagram
* FSM Diagram
* AXI Write Waveform
* AXI Read Waveform
* Functional Coverage Report
* Assertion Report
* RTL Schematic
* Vivado Synthesized Floorplan

---

# Tools Used

| Tool            | Purpose                 |
| --------------- | ----------------------- |
| SystemVerilog   | RTL Design              |
| UVM             | Functional Verification |
| QuestaSim 10.7c | Simulation              |
| Vivado 2023.x   | FPGA Synthesis          |
| Git             | Version Control         |
| GitHub          | Repository Management   |

---

# Key Learning Outcomes

Through this project, the following concepts were learned and applied:

* AXI4-Lite Protocol
* APB3 Protocol
* Protocol Bridging
* Finite State Machine Design
* RTL Design Methodology
* UVM Verification
* Functional Coverage
* Assertion-Based Verification
* Scoreboard-Based Checking
* FPGA Synthesis Flow
* Vivado Floorplanning

---

# Future Enhancements

* Complete FPGA implementation using wrapper architecture
* Add APB timeout mechanism
* Support configurable slave count
* Add APB4 compatibility
* Add Register Abstraction Layer (RAL)
* Improve coverage beyond 95%

---

# Author

**Suraksha K S**

Bachelor of Engineering (Electronics and Communication Engineering)

Dr. Ambedkar Institute of Technology, Bengaluru

GitHub: https://github.com/surakshaacharyaks

LinkedIn: https://linkedin.com/in/surakshaacharyaks
