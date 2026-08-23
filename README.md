# AMBA AXI4-Stream Full-Duplex UART Core

## Architecture Overview
A cycle-accurate, synthesizable Universal Asynchronous Receiver-Transmitter (UART) IP core. This repository demonstrates the architectural evolution from a raw physical layer communication core into a standard AMBA AXI4-Stream System-on-Chip (SoC) peripheral using First-Word Fall-Through (FWFT) synchronous FIFOs.

The core utilizes a **16x oversampling technique** for robust center-eye data recovery and a **double-flop synchronizer** to safely cross physical asynchronous RX signals into the 100 MHz synchronous domain, preventing metastability.

## Architectural Evolution & Performance Comparison
This repository contains two instantiable top-level modules, allowing integrators to balance area overhead versus protocol compliance. The addition of the AMBA AXI4-Stream wrappers and FIFOs (Phase 2) introduced hardware backpressure and effectively pipelined the I/O boundaries, resulting in improved timing closure at the cost of additional memory utilization.

| Metric | Base Core (`uart_top.sv`) | AXI-Stream Core (`uart_axis_top.sv`) |
| :--- | :--- | :--- |
| **Interface** | Raw TX/RX | AMBA AXI4-Stream |
| **Buffering** | 1-Byte internal register | 16-Byte FWFT Synchronous FIFOs |
| **Data Protection** | None (Overwrites on collision) | Strict Hardware Backpressure (`tready`) |
| **Target Clock** | 100 MHz | 100 MHz |
| **WNS (Timing)** | +5.962 ns | +7.242 ns |

## Repository Structure
This IP is architected to industry standards, strictly separating physical design from verification and synthesis artifacts.
* `/RTL`: Synthesizable SystemVerilog source files (Core logic, FIFOs, AXI wrappers).
* `/TESTBENCH`: Self-checking verification testbenches.
* `/DOCS`: Physical timing constraints (`.xdc`), architectural schematics, and verification waveforms.

---

## Phase 1: Base Core Verification & Synthesis
The base `uart_top` module implements raw TX and RX state machines. Verified via a full-duplex loopback stress test in Questa. 

*(Phase 1: Cycle-Accurate Loopback Verification)*
<img width="1290" height="552" alt="phase_1_waveform" src="https://github.com/user-attachments/assets/f4482860-33be-4e65-92d6-37fcf5f989a8" />

> **Validation Analysis:** The waveform demonstrates a successful physical serial loopback. The RX module utilizes a 16x oversampling counter (`clk_count`) to sample the center of the data eye. The state machine successfully tracks the `bit_index` to reconstruct the transmitted bytes (e.g., `03`, `0b`, `2b`) from the raw serial line without data corruption.

Synthesized targeting the Xilinx Artix-7 (`xc7a35tcpg236-1`). 
*(Phase 1: Physical Timing Closure at 100 MHz)*
<img width="1032" height="261" alt="phase_1_timing" src="https://github.com/user-attachments/assets/ce10428b-31ef-4314-8059-96e5d2ef55c3" />


---

## Phase 2: AXI4-Stream Validation & Synthesis
The top-level `uart_axis_top` wrapper provides hardware-level backpressure (`TVALID`/`TREADY` handshaking) to prevent data loss under high-stress system loads.

### Backpressure Verification
Verified via a strict self-checking testbench (`uart_axis_tb.sv`). The verification environment artificially restricts the TX FIFO depth to 4 to force an overflow condition. 

*(Phase 2: AXI4-Stream Backpressure Stall Verification)*
<img width="1281" height="678" alt="phase2_waveform" src="https://github.com/user-attachments/assets/f9993ca3-52a5-4d03-8e6a-2fc04ebcb16d" />

> **Validation Analysis:** This physical capture proves the AXI4-Stream backpressure logic. When the internal memory array reaches maximum occupancy (`count` hits 4), the hardware immediately pulls `s_axis_tready` low. The upstream testbench is successfully stalled, preventing byte `f6` from overwriting the buffer. The stall is held cycle-accurately until the UART transmits a byte and frees a memory slot (`count` drops to 3).

### Hardware Schematic & Pipelined Timing Closure
The addition of I/O boundary FIFOs effectively pipelined the design, isolating the core state machines from external pin delays and yielding a highly optimized routing path.

*(Phase 2: Physical Timing Closure at 100 MHz)*
<img width="1075" height="230" alt="phase2_timing" src="https://github.com/user-attachments/assets/72bf8771-6636-4c14-af14-966f2caca440" />


*(Phase 2: Vivado Synthesized Hardware Schematic)*
<img width="1920" height="887" alt="newfullsche" src="https://github.com/user-attachments/assets/e2990c40-e4a7-464f-becf-e394b8eef2e7" />
