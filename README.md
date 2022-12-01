![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg)

# TinyPID

TinyPID is a tiny 8-bit PID controller made for TinyTapeout 2 (https://tinytapeout.com).

*NOTE: TinyPID has no D term due to space constraints*

## Operation

TODO: block diagram

TODO: pinout

### Configuration

TODO: configuration bits diagram

TODO: configuration bits table

All configuration bits are initialized to zero on reset.

Configuration is supplied by an external SPI master. Shift in exactly 24 bits. There is no configuration latch due to space constraints, so shifting in the wrong number of bits will misconfigure the controller.

### Process Variable Input

TinyPID reads 8 bits of PV input from a SPI slave / shift register. PV is read every 65536 clock cycles.

### Stimulus Output

TinyPID calculates the stimulus as soon as the PV is read, and outputs in two clock cycles later. TinyPID writes 8 bits of stimulus output to a SPI slave / shift register.
