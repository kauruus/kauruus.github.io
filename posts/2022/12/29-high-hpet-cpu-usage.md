+++
title = "High HPET CPU Usage"
has_code = true
+++

# {{ title }}

After I [built swoole-cli](/posts/2022/12/28-build-swoole-cli-for-old-machines/), I did some benchmark to see how it performs.

I tried `wrk` and `wrk2`, and found that `wrk2` performs much wrost than `wrk`.

From `perf report`, `wrk2` spend over 60% CPU time on `read_hpet`, while `wrk` use less than 20%.

wrk2:

```
Overhead  Command  Shared Object     Symbol
  64.43%  wrk2     [kernel.vmlinux]  [k] read_hpet                                                                                                                                                                                                                  ◆
   2.53%  wrk2     [vdso]            [.] __vdso_gettimeofday                                                                                                                                                                                                        ▒
   1.86%  wrk2     [kernel.vmlinux]  [k] entry_SYSRETQ_unsafe_stack                                                                                                                                                                                                 ▒
   1.44%  wrk2     [kernel.vmlinux]  [k] exit_to_user_mode_prepare                                                                                                                                                                                                  ▒
   0.85%  wrk2     wrk2              [.] http_parser_execute                                                                                                                                                                                                        ▒
   0.80%  wrk2     [kernel.vmlinux]  [k] entry_SYSCALL_64_after_hwframe                                                                                                                                                                                             ▒
   0.79%  wrk2     wrk2              [.] aeProcessEvents.part.0                                                                                                                                                                                                     ▒
   0.66%  wrk2     [kernel.vmlinux]  [k] tcp_ack
   ...
```

wrk:

```
Overhead  Command  Shared Object     Symbol
  19.40%  wrk      [kernel.vmlinux]  [k] read_hpet                                                                                                                                                                                                                  ◆
   3.14%  wrk      wrk               [.] http_parser_execute                                                                                                                                                                                                        ▒
   2.19%  wrk      [kernel.vmlinux]  [k] tcp_ack                                                                                                                                                                                                                    ▒
   1.71%  wrk      [kernel.vmlinux]  [k] do_epoll_ctl                                                                                                                                                                                                               ▒
   1.35%  wrk      [kernel.vmlinux]  [k] tcp_poll                                                                                                                                                                                                                   ▒
   1.35%  wrk      [kernel.vmlinux]  [k] __fget_light                                                                                                                                                                                                               ▒
   1.27%  wrk      [kernel.vmlinux]  [k] tcp_sendmsg_locked                                                                                                                                                                                                         ▒
   1.12%  wrk      [kernel.vmlinux]  [k] __tcp_transmit_skb                                                                                                                                                                                                         ▒
   1.09%  wrk      [kernel.vmlinux]  [k] sock_poll                                                                                                                                                                                                                  ▒
   1.01%  wrk      [kernel.vmlinux]  [k] tcp_v4_rcv
```

## What's HPET?

There are many great articles about HPET and TSC:

- [Wikipedia: Time Stamp Counter](https://en.wikipedia.org/wiki/Time_Stamp_Counter)
- [Wikipedia: High Precision Event Timer](https://en.wikipedia.org/wiki/High_Precision_Event_Timer)
- [Pitfalls of TSC usage](https://oliveryang.net/2015/09/pitfalls-of-TSC-usage/#32-software-tsc-usage-bugs)
- [A Performance Issue Caused by the TSC Clock Source Missing in Linux](https://deeperf.com/2019/04/30/tsc-clock-missing-caused-performance-issues/)

Basically, HPET clock is from a chip on the monitor, while TSC is from inside the CPU. So HPET cost much more than TSC, and it's less accurate.

## Why using HEPT?  

Let's see if my Pentium T4500 support TSC.

From `lscpu`, it supports `tsc` and `constant_tsc`:

```
Flags:                           fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ht tm pbe syscall nx lm constant_tsc arch_perfmon pebs bts rep_good nopl cpuid aperfmperf pni dtes64 monitor ds_cpl est t
m2 ssse3 cx16 xtpr pdcm xsave lahf_lm dtherm
```

But kernel report that the system supports only `hpet` and `acpi_pm`:

```
$ cat /sys/devices/system/clocksource/clocksource0/available_clocksource
hpet acpi_pm
```

Why? Because kernel found TSC skew is too large, and mark TSC as unstable:

```
$ sudo dmesg | rg 'tsc|clocksource'
[    0.000000] tsc: Fast TSC calibration using PIT
[    0.000000] tsc: Detected 2299.946 MHz processor
[    0.035079] clocksource: refined-jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 6370452778343963 ns
[    0.091515] clocksource: hpet: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 133484882848 ns
[    0.108205] clocksource: tsc-early: mask: 0xffffffffffffffff max_cycles: 0x21270226594, max_idle_ns: 440795254730 ns
[    0.254967] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 6370867519511994 ns
[    0.344978] clocksource: Switched to clocksource tsc-early
[    0.354941] clocksource: acpi_pm: mask: 0xffffff max_cycles: 0xffffff, max_idle_ns: 2085701024 ns
[    0.796814] clocksource: timekeeping watchdog on CPU1: Marking clocksource 'tsc-early' as unstable because the skew is too large:
[    0.796817] clocksource:                       'hpet' wd_nsec: 506655001 wd_now: f8d555 wd_last: 8a23ec mask: ffffffff
[    0.796820] clocksource:                       'tsc-early' cs_nsec: 205618777 cs_now: 8eec4900a cs_last: 8d2947f35 mask: ffffffffffffffff
[    0.796823] clocksource:                       'tsc-early' is current clocksource.
[    0.796829] tsc: Marking TSC unstable due to clocksource watchdog
[    0.796906] TSC found unstable after boot, most likely due to broken BIOS. Use 'tsc=unstable'.
[    0.797003] clocksource: Switched to clocksource hpet

```

## Maybe I can use TSC directly?

I tried to port [MengRao/tscns](https://github.com/MengRao/tscns) to C, and plug it into wrk2.

When I run the benchmark, wrk2 encounter negative latency value :(

So, kernel is correct, better not use TSC when it's not stable.

