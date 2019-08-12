# SVGameBoy
A systemVerilog implementation of the Game Boy on DE1-SoC

This was for CSEE 4840 Embedded System Design @ Columbia University

To make target files for DE1-SoC

make qsys && make quartus && make rbf

## Accuracy

### Blargg's tests

| Test           | mooneye-gb | BGB  | Gambatte | Higan | MESS | VerilogBoy | Ours |
| -------------- | ---------- | ---- | -------- | ----- | ---- | ---------- | ---- |
| cpu instrs     | :+1:       | :+1: | :+1:     | :+1:  | :+1: | :+1:       | :+1: |
| dmg sound      | :x:        | :+1: | N/A      | N/A   | N/A  | N/A        | :x:  |
| instr timing   | :+1:       | :+1: | N/A      | N/A   | N/A  | N/A        | :+1: |
| interrupt time | N/A        | :x:  | N/A      | N/A   | N/A  | N/A        | :x:  |
| mem timing     | N/A        | :+1: | N/A      | N/A   | N/A  | N/A        | :+1: |
| mem timing 2   | :+1:       | :+1: | N/A      | N/A   | N/A  | N/A        | :+1: |
| oam bug        | :x:        | :x:  | N/A      | N/A   | N/A  | N/A        | :x:  |

### Mooneye GB acceptance tests

| Test                    | mooneye-gb | BGB  | Gambatte | Higan | MESS | VerilogBoy | Ours |
| ----------------------- | ---------- | ---- | -------- | ----- | ---- | ---------- | ---- |
| add sp e timing         | :+1:       | :x:  | :+1:     | :+1:  | :+1: | :+1:       | :+1: |
| call timing             | :+1:       | :x:  | :+1:     | :+1:  | :+1: | :+1:       | :+1: |
| call timing2            | :+1:       | :x:  | :+1:     | :+1:  | :+1: | :+1:       | :+1: |
| call cc_timing          | :+1:       | :x:  | :+1:     | :+1:  | :+1: | :+1:       | :+1: |
| call cc_timing2         | :+1:       | :x:  | :+1:     | :+1:  | :+1: | :+1:       | :+1: |
| di timing GS            | :+1:       | :+1: | :+1:     | :+1:  | :+1: | :+1:       | :+1: |
| div timing              | :+1:       | :+1: | :+1:     | :+1:  | :+1: | :+1:       | :+1: |
| ei sequence             | :+1:       | :+1: | :+1:     | :+1:  | :x:  | :+1:       | :+1: |
| ei timing               | :+1:       | :+1: | :+1:     | :+1:  | :+1: | :+1:       | :+1: |
| halt ime0 ei            | :+1:       | :+1: | :+1:     | :+1:  | :+1: | :+1:       | :+1: |
| halt ime0 nointr_timing | :+1:       | :+1: | :+1:     | :+1:  | :+1: | :x:        | :+1: |
| halt ime1 timing        | :+1:       | :+1: | :+1:     | :+1:  | :+1: | :+1:       | :+1: |
| halt ime1 timing2 GS    | :+1:       | :+1: | :+1:     | :+1:  | :+1: | :x:        | :+1: |
| if ie registers         | :+1:       | :+1: | :+1:     | :+1:  | :+1: | :x:        | :+1: |
| intr timing             | :+1:       | :+1: | :+1:     | :+1:  | :+1: | :x:        | :+1: |
| jp timing               | :+1:       | :x:  | :+1:     | :+1:  | :+1: | :+1:       | :+1: |
| jp cc timing            | :+1:       | :x:  | :+1:     | :+1:  | :+1: | :+1:       | :+1: |
| ld hl sp e timing       | :+1:       | :x:  | :+1:     | :+1:  | :+1: | :+1:       | :+1: |
| oam dma_restart         | :+1:       | :x:  | :+1:     | :+1:  | :+1: | :+1:       | :x:  |
| oam dma start           | :+1:       | :x:  | :+1:     | :+1:  | :+1: | :+1:       | :+1: |
| oam dma timing          | :+1:       | :x:  | :+1:     | :+1:  | :+1: | :+1:       | :x:  |
| pop timing              | :+1:       | :x:  | :+1:     | :+1:  | :+1: | :+1:       | :+1: |
| push timing             | :+1:       | :x:  | :x:      | :+1:  | :+1: | :+1:       | :+1: |
| rapid di ei             | :+1:       | :+1: | :+1:     | :+1:  | :+1: | :+1:       | :+1: |
| ret timing              | :+1:       | :x:  | :+1:     | :+1:  | :+1: | :+1:       | :+1: |
| ret cc timing           | :+1:       | :x:  | :+1:     | :+1:  | :+1: | :+1:       | :+1: |
| reti timing             | :+1:       | :x:  | :+1:     | :+1:  | :+1: | :+1:       | :+1: |
| reti intr timing        | :+1:       | :+1: | :+1:     | :+1:  | :+1: | :+1:       | :+1: |
| rst timing              | :+1:       | :x:  | :x:      | :+1:  | :+1: | :+1:       | :+1: |

#### Instructions

| Test | mooneye-gb | BGB  | Gambatte | Higan | MESS | VerilogBoy | Ours |
| ---- | ---------- | ---- | -------- | ----- | ---- | ---------- | ---- |
| daa  | :+1:       | :+1: | :+1:     | :+1:  | :+1: | :+1:       | :+1: |

#### Interrupt handling

| Test    | mooneye-gb | BGB  | Gambatte | Higan | MESS | VerilogBoy | Ours |
| ------- | ---------- | ---- | -------- | ----- | ---- | ---------- | ---- |
| ie push | :+1:       | :x:  | :x:      | :x:   | :x:  | :+1:       | :+1: |

#### OAM DMA

| Test               | mooneye-gb | BGB  | Gambatte | Higan | MESS | VerilogBoy | Ours |
| ------------------ | ---------- | ---- | -------- | ----- | ---- | ---------- | ---- |
| basic              | :+1:       | :+1: | :+1:     | :+1:  | :+1: | :+1:       | :+1: |
| reg_read           | :+1:       | :+1: | :+1:     | :x:   | :x:  | :+1:       | :+1: |
| sources dmgABCmgbS | :+1:       | :+1: | :x:      | :x:   | :x:  | :x:        | :+1: |

#### Serial

| Test                      | mooneye-gb | BGB  | Gambatte | Higan | MESS | VerilogBoy | Ours |
| ------------------------- | ---------- | ---- | -------- | ----- | ---- | ---------- | ---- |
| boot sclk align dmgABCmgb | :x:        | :+1: | :+1:     | :x:   | :x:  | :+1:       | :+1: |

#### PPU

| Test                        | mooneye-gb | BGB  | Gambatte | Higan | MESS | VerilogBoy | Ours |
| --------------------------- | ---------- | ---- | -------- | ----- | ---- | ---------- | ---- |
| hblank ly scx timing GS     | :+1:       | :+1: | :x:      | :x:   | :+1: | :x:        | :x:  |
| intr 1 2 timing GS          | :+1:       | :+1: | :+1:     | :+1:  | :+1: | :x:        | :x:  |
| intr 2 0 timing             | :+1:       | :+1: | :x:      | :+1:  | :+1: | :x:        | :x:  |
| intr 2 mode0 timing         | :+1:       | :+1: | :x:      | :x:   | :+1: | :x:        | :+1: |
| intr 2 mode3 timing         | :+1:       | :+1: | :x:      | :x:   | :+1: | :x:        | :+1: |
| intr 2 oam ok timing        | :+1:       | :+1: | :x:      | :x:   | :+1: | :x:        | :+1: |
| intr 2 mode0 timing sprites | :x:        | :+1: | :x:      | :x:   | :+1: | :x:        | :x:  |
| lcdon timing dmgABCmgbS     | :x:        | :+1: | :x:      | :x:   | :x:  | :x:        | :x:  |
| lcdon write timing GS       | :x:        | :+1: | :x:      | :x:   | :x:  | :x:        | :x:  |
| stat irq blocking           | :x:        | :+1: | :+1:     | :x:   | :+1: | :x:        | :+1: |
| stat lyc onoff              | :x:        | :+1: | :x:      | :x:   | :x:  | :x:        | :x:  |
| vblank stat intr GS         | :+1:       | :+1: | :x:      | :+1:  | :+1: | :x:        | :+1: |

#### Timer

| Test                 | mooneye-gb | BGB  | Gambatte | Higan | MESS | VerilogBoy | Ours |
| -------------------- | ---------- | ---- | -------- | ----- | ---- | ---------- | ---- |
| div write            | :+1:       | :+1: | :x:      | :+1:  | :+1: | :+1:       | :+1: |
| rapid toggle         | :+1:       | :+1: | :x:      | :x:   | :+1: | :+1:       | :+1: |
| tim00 div trigger    | :+1:       | :+1: | :+1:     | :x:   | :+1: | :+1:       | :+1: |
| tim00                | :+1:       | :+1: | :x:      | :+1:  | :+1: | :+1:       | :+1: |
| tim01 div trigger    | :+1:       | :+1: | :x:      | :x:   | :+1: | :+1:       | :+1: |
| tim01                | :+1:       | :+1: | :+1:     | :+1:  | :+1: | :+1:       | :+1: |
| tim10 div trigger    | :+1:       | :+1: | :x:      | :x:   | :+1: | :+1:       | :+1: |
| tim10                | :+1:       | :+1: | :x:      | :+1:  | :+1: | :+1:       | :+1: |
| tim11 div trigger    | :+1:       | :+1: | :x:      | :x:   | :+1: | :+1:       | :+1: |
| tim11                | :+1:       | :+1: | :x:      | :+1:  | :+1: | :+1:       | :+1: |
| tima reload          | :+1:       | :+1: | :x:      | :x:   | :+1: | :+1:       | :+1: |
| tima write reloading | :+1:       | :+1: | :x:      | :x:   | :+1: | :+1:       | :+1: |
| tma write reloading  | :+1:       | :+1: | :x:      | :x:   | :+1: | :+1:       | :+1: |

#### MBC

| Test | mooneye-gb | BGB  | Gambatte | Higan | MESS | VerilogBoy | Ours |
| ---- | ---------- | ---- | -------- | ----- | ---- | ---------- | ---- |
| MBC1 | N/A        | :+1: | N/A      | N/A   | N/A  | N/A        | :+1: |
| MBC5 | N/A        | :+1: | N/A      | N/A   | N/A  | N/A        | :+1: |

Note: MBC3 test ROM was not created at the time of testing. 
