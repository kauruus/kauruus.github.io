+++
title = "Cross Compile Rust Program for mipsel"
hascode = true
+++

# {{ title }}

Long time ago, I bought one [Xiaomi Mi WiFi Mini](https://openwrt.org/toh/xiaomi/miwifi_mini) and installed OpenWrt on it. And I want to put some Rust program on it, so cross-compilation is needed.

## Choosing a Toolchain

To cross compile program for it, we first need a toolchain.

[musl.cc](https://musl.cc/) provides static build of GCC toolchains.

for mipsel, there are:

- mipsel-linux-musl-cross
- mipsel-linux-musln32-cross
- mipsel-linux-musln32sf-cross
- mipsel-linux-muslsf-cross

`sf` suffix means soft-float API. `n32` is for 64-bit kernel, but with 32-bit pointers. 

here's the `cat /proc/cpuinfo` output:

```
system type             : MediaTek MT7620A ver:2 eco:6
machine                 : Xiaomi MiWiFi Mini
processor               : 0
cpu model               : MIPS 24KEc V5.0
BogoMIPS                : 385.84
wait instruction        : yes
microsecond timers      : yes
tlb_entries             : 32
extra interrupt vector  : yes
hardware watchpoint     : yes, count: 4, address/irw mask: [0x0ffc, 0x0ffc, 0x0ffb, 0x0ffb]
isa                     : mips1 mips2 mips32r1 mips32r2
ASEs implemented        : mips16 dsp
Options implemented     : tlb 4kex 4k_cache prefetch mcheck ejtag llsc pindexed_dcache userlo
cal vint perf_cntr_intr_bit perf
shadow register sets    : 1
kscratch registers      : 0
package                 : 0
core                    : 0
VCED exceptions         : not available
VCEI exceptions         : not available
```

seems it doesn't support FPU, so I am going to use the `sf` variant.

## Testing the Toolchain

let's build an hello world program in C.

```
$ cat hello.c
#include <stdio.h>

int main() {
  printf("Hello, World!\n");
}
$ mipsel-linux-muslsf-gcc hello.c -o hello
$ file hello
hello: ELF 32-bit LSB pie executable, MIPS, MIPS-I version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-mipsel-sf.so.1, not stripped
```

it works since the OpenWrt system has `/lib/ld-musl-mipsel-sf.so.1`:

to static link it, add `-static`

```
$ mipsel-linux-muslsf-gcc hello.c -o hello -static
$ file hello
hello: ELF 32-bit LSB pie executable, MIPS, MIPS-I version 1 (SYSV), static-pie linked, not stripped
```

it also works and the binary is quite small (20KB).


# Cross Compile Rust program

First add a target:

```shell
$ rustup target add mipsel-unknown-linux-musl
```

in `~/.cargo/config`, set up the linker: 

```
[target.mipsel-unknown-linux-musl]
linker = "mipsel-linux-muslsf-gcc"
rustflags = ["-Ctarget-feature=+crt-static"] # static linked
```

let's build a hello world program in Rust:

```shell
$ cargo new hello-world
$ cd hello-world
$ cargo build --target mipsel-unknown-linux-musl --release
$ file ./target/mipsel-unknown-linux-musl/release/hello-world
./target/mipsel-unknown-linux-musl/release/hello-world: ELF 32-bit LSB executable, MIPS, MIPS32 rel2 version 1 (SYSV), statically linked, with debug_info, not stripped
```

the binary is quite big (4.9 MB). stripping the debug info can lower it to 572 KB, still quite big.

# Dose the non `sf` variant work?

I also try the non `sf` variant to see if it works. 

```shell
$ cat sin.c
#include <stdio.h>
#include <math.h>

int main() {
  double x;
  scanf("%lf", &x);
  printf("x = %f\n", x);
  printf("sin(x) = %f\n", sin(x));
}
$ mipsel-linux-musl-gcc -static -lm sin.c -o sin
```

when run in OpenWrt:

```
$ ./sin
0.5
Illegal instruction
```

it doesn't work.

comparing the assembly, we can see the non-sf variant is using `lwc1` and `mfc1` instruction. these instructions are for moving float point numbers.

```diff
--- sin.s       2023-10-09 12:37:41.045638697 +0800
+++ non-sf.s    2023-10-09 12:37:10.228019849 +0800
@@ -2,7 +2,7 @@
        .section .mdebug.abi32
        .previous
        .nan    legacy
-       .module softfloat
+       .module fp=32
        .module nooddspreg
        .abicalls
        .text
@@ -48,8 +48,9 @@
        nop

        lw      $28,16($fp)
-       lw      $2,24($fp)
-       lw      $3,28($fp)
+       lwc1    $f0,24($fp)
+       nop
+       lwc1    $f1,28($fp)
        lw      $6,24($fp)
        lw      $7,28($fp)
        lw      $2,%got($LC1)($28)
@@ -63,10 +64,12 @@
        nop

        lw      $28,16($fp)
-       lw      $2,24($fp)
-       lw      $3,28($fp)
-       lw      $4,24($fp)
-       lw      $5,28($fp)
+       lwc1    $f0,24($fp)
+       nop
+       lwc1    $f1,28($fp)
+       lwc1    $f12,24($fp)
+       nop
+       lwc1    $f13,28($fp)
        lw      $2,%call16(sin)($28)
        nop
        move    $25,$2
@@ -75,8 +78,10 @@
        nop

        lw      $28,16($fp)
-       move    $6,$2
-       move    $7,$3
+       mfc1    $2,$f0
+       mfc1    $3,$f1
+       mfc1    $6,$f0
+       mfc1    $7,$f1
        lw      $2,%got($LC2)($28)
        nop
        addiu   $4,$2,%lo($LC2)
@@ -101,4 +106,3 @@
        .end    main
        .size   main, .-main
        .ident  "GCC: (GNU) 11.2.1 20211120"
-       .section        .note.GNU-stack,"",@progbits
```

## Does the Rust Target Supports FPU?

Nope, the `mipsel-unknown-linux-musl` is [hardcode to use soft-float](https://github.com/rust-lang/rust/blob/1f48cbc3f8dbd393a7e713a0f90d7c6ec72d58ee/compiler/rustc_target/src/spec/mipsel_unknown_linux_musl.rs):

```rust
use crate::spec::{Target, TargetOptions};

pub fn target() -> Target {
    let mut base = super::linux_musl_base::opts();
    base.cpu = "mips32r2".into();
    base.features = "+mips32r2,+soft-float".into();
    base.max_atomic_width = Some(32);
    base.crt_static_default = false;
    Target {
        llvm_target: "mipsel-unknown-linux-musl".into(),
        pointer_width: 32,
        data_layout: "e-m:m-p:32:32-i8:8:32-i16:16:32-i64:64-n32-S64".into(),
        arch: "mips".into(),
        options: TargetOptions { mcount: "_mcount".into(), ..base },
    }
}
```

