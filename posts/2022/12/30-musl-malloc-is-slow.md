+++
title = "Musl Malloc is Slow"
+++

# {{ title }}

So I have [built swoole-cli](/posts/2022/12/28-build-swoole-cli-for-old-machines/), and figured out the [HEPT issue](/posts/2022/12/29-high-hpet-cpu-usage/).

Let's see how it performs.

Start with 1 thread and 10 clients:

```
$ wrk -c 10 -t 1 -d 10s -L http://127.0.0.1:9501
Running 10s test @ http://127.0.0.1:9501
  1 threads and 10 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    22.93ms    1.79ms  50.95ms   93.16%
    Req/Sec   437.09     10.57   450.00     86.00%
  Latency Distribution
     50%   22.74ms
     75%   22.94ms
     90%   23.28ms
     99%   29.29ms
  4357 requests in 10.01s, 702.06KB read
Requests/sec:    435.13
Transfer/sec:     70.11KB

```

OMG, QPS is less than 500. On the same machine, Go can do over 10k qps.

## Flamegraph to help


Flamegraph is my go-to tool for troubleshoting performance issue.

```
$ perf record --call-graph dwarf swoole-cli ./http-hello.php
$ # start wrk in another terminal, after benchmark, Ctrl-C to stop perf
$ perf script | inferno-collapse-perf | inferno-flamegraph > flamegraph.svg
```

And here's the flamegraph(open in new tab to see details), frankly speeking, I don't see any problem in it.


![](/assets/images/swoole-cli-flamegraph.svg)


What about off-CPU time? 

```
$ /usr/share/bcc/tools/offcputime -df -p $(pidof swoole-cli) > wait.stack
$ < wait.stack inferno-flamegraph -c blue > offcputime.svg
```

![](/assets/images/swoole-cli-offcputime.svg)

Hmm, we are waiting for `__munmap` and `enframe` and lots of page faults. Maybe memory issue?

## Mimalloc to help


We all known musl's malloc is slow, and swoole-cli has [support mimalloc](https://github.com/swoole/swoole-cli/pull/6).

Let's see if my swoole-cli using mimalloc:

```
$ MIMALLOC_VERBOSE=1 swoole-cl
(no output)
```

Ah, mimalloc is not linked.

From the build script, I found it didn't add `-lmimalloc` :(

Add that flag back and recompile, it now has mimalloc linked.

```
$ MIMALLOC_VERBOSE=1 swoole-cli
mimalloc: process init: 0x7f708cf35020
mimalloc: secure level: 0
mimalloc: using 1 numa regions
mimalloc: option 'show_errors': 0
mimalloc: option 'show_stats': 0
mimalloc: option 'eager_commit': 1
mimalloc: option 'deprecated_eager_region_commit': 0
mimalloc: option 'deprecated_reset_decommits': 0
mimalloc: option 'large_os_pages': 0
mimalloc: option 'reserve_huge_os_pages': 0
mimalloc: option 'reserve_huge_os_pages_at': -1
mimalloc: option 'reserve_os_memory': 0
mimalloc: option 'deprecated_segment_cache': 0
mimalloc: option 'page_reset': 0
mimalloc: option 'abandoned_page_decommit': 0
mimalloc: option 'deprecated_segment_reset': 0
mimalloc: option 'eager_commit_delay': 1
mimalloc: option 'decommit_delay': 25
mimalloc: option 'use_numa_nodes': 0
mimalloc: option 'limit_os_alloc': 0
mimalloc: option 'os_tag': 100
mimalloc: option 'max_errors': 16
mimalloc: option 'max_warnings': 16
mimalloc: option 'max_segment_reclaim': 8
mimalloc: option 'allow_decommit': 1
mimalloc: option 'segment_decommit_delay': 500
mimalloc: option 'decommit_extend_delay': 2
```

And now it performs much better:

```
Running 10s test @ http://127.0.0.1:9501
  1 threads and 10 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   601.61us  186.81us   4.51ms   87.57%
    Req/Sec    16.52k   378.21    16.91k    89.00%
  Latency Distribution
     50%  531.00us
     75%  550.00us
     90%    1.05ms
     99%    1.12ms
  164353 requests in 10.00s, 25.86MB read
Requests/sec:  16432.60
Transfer/sec:      2.59MB
```

Again, from the on-CPU flamegraph I can't see any problem. But from the off-CPU time flamegraph, it's spends most time doing network calls now.

 
![](/assets/images/swoole-cli-mimalloc-flamegraph.svg)

![](/assets/images/swoole-cli-mimalloc-offcputime.svg)

## What about newer machines?

So I did all above on a Pentium T4500 machine, it's quite old.

I also copy the binary to an AMD Zen3 machine to see how it performs.

With musl malloc (from 400 to 14000):

```
$  wrk -c 250 -t 2 -d 60s -L http://127.0.0.1:9501
Running 1m test @ http://127.0.0.1:9501
  2 threads and 250 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    17.84ms  719.01us  41.92ms   63.52%
    Req/Sec     7.04k   261.63     7.47k    56.83%
  Latency Distribution
     50%   17.54ms
     75%   18.69ms
     90%   18.87ms
     99%   19.02ms
  840619 requests in 1.00m, 132.28MB read
Requests/sec:  14009.94
Transfer/sec:      2.20MB
```

With mimalloc (from 16000 to 160000):

```
Running 1m test @ http://127.0.0.1:9501
  2 threads and 250 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     1.47ms   55.89us   4.78ms   97.60%
    Req/Sec    85.31k     1.93k   88.26k    92.25%
  Latency Distribution
     50%    1.47ms
     75%    1.48ms
     90%    1.50ms
     99%    1.54ms
  10189141 requests in 1.00m, 1.57GB read
Requests/sec: 169815.19
Transfer/sec:     26.72MB

```

Again, over 10x improvement!

And CPU improvement in these 10 years is HUGE.

