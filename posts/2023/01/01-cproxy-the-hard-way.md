+++
title = "cproxy the Hard Way"
has_code = true
+++

# {{title}}

Today, I try to download some Julia packages, but I don't know how to config proxy for Julia.

I tried `HTTP_PROXY` and `HTTPS_PROXY` environment variable, but it didn' work.

So I want to setting up a transparent proxy, so I don't need to figured out the exact config for it.


## cproxy

[cproxy](https://github.com/NOBLES5E/cproxy) is cool project, it utlizes cgroup to manage which program needs to be proxied.

Give that you have a TCP proxy running on port 1081, you can start a new program, and redirect all it's traffic to the proxy.

```
$ cproxy --port 1081 -- julia
```

But when I run it, it failed:

```
Error: Running ["iptables", "-t", "nat", "-N", "nozomi_redirect_out_31731"] exited with error; status code: 111
```

Oh, starting from 1.8.8, [iptables can't be called by a setuid executable](https://git.netfilter.org/iptables/commit/?id=ef7781eb1437a2d6fd37eb3567c599e3ea682b96).

Okay, then I need `sudo`:

```
$ sudo cproxy --port 1081 -- julia
```

But this will download the packages for the root user, that's not what I want.

So I tried to modify cproxy, remove setuid from it, add capabilities to cproxy and iptables, and [it mostly works](https://github.com/NOBLES5E/cproxy/issues/80#issuecomment-1368251799).

Hey cproxy utlizes cgroup, can I start a program in a existing cgroup?

First start cproxy, and get it's pid:

```
$ sudo cproxy --port 1081 -- bash -c 'echo ${PPID}; sleep 1d'
13279
```

Then use `cgexec` to start new program:

```
$ cgexec -g cpu:cproxy-13279 bash
cgroup change of group failed
```

Still need root permission:(

Then I suddenly realized, cgroup is inherited by child process, and I can switch from root to non-root user:

```
$ sudo cproxy --port 1081 -- bash
# su kauruus
$ julia
```

It waste me about 1 hour :(


