+++
title = "Learn MCS51: Blink LED"
+++

# {{ title }}

## Goal

Blink a LED on the board.

## Schematic

![](/assets/images/mcs51-pinecore-pi-nano-led.png)

To light LED1, we need the electric current flow from `VCC` to `P10`.

## Code

```c
#include "stc8fsdcc.h"
#include "delay.h"

void main(void) {
  P55 = 0; // allows electric current flow from VCC

  while (1) {
    P10 = 0;  // output 0v, led on
    delay_ms(1000);

    P10 = 1;  // output 5v, led off
    delay_ms(1000);
  }
}
```

## Build and Upload

```bash
sdcc --Werror --model-small blink.c -o blink.hex
packihx blink.hex > upload.hex
stcgal -P stc8 upload.hex
```

