+++
title = "Access LuckFox Pico Max from Linux"
hascode = true
+++

# {{ title }}

Recently I bought a Luckfox Pico, a low-cost micro Linux development boards.

However the [official docs](https://wiki.luckfox.com/Luckfox-Pico/Luckfox-Pico-quick-start/#network-adb-debugging) is Windows only, I have to figure out how to connect to it from Linux.

## Connect through USB (RNDIS)

When I plug in the board to my machine, `dmesg` shows:

```shell
[106711.735124] usb 1-2: new high-speed USB device number 3 using xhci_hcd
[106711.884152] usb 1-2: New USB device found, idVendor=2207, idProduct=0019, bcdDevice= 3.10
[106711.884168] usb 1-2: New USB device strings: Mfr=1, Product=2, SerialNumber=3
[106711.884173] usb 1-2: Product: rk3xxx
[106711.884177] usb 1-2: Manufacturer: rockchip
[106711.884179] usb 1-2: SerialNumber: ca2b43c81417032
[106712.622333] usbcore: registered new interface driver cdc_ether
[106712.636526] rndis_host 1-2:1.0 usb0: register 'rndis_host' at usb-0000:05:00.3-2, RNDIS device, c6:9e:eb:2b:6b:3f
[106712.636641] usbcore: registered new interface driver rndis_host
[106712.648403] rndis_host 1-2:1.0 enp5s0f3u2: renamed from usb0
```

As you can see, it supports rndis, and the network interface is renamed to `enp5s0f3u2`.

```shell
$ ip link show enp5s0f3u2
4: enp5s0f3u2: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether c6:9e:eb:2b:6b:3f brd ff:ff:ff:ff:ff:ff
```

let's set it up and assign a IP address (take 172.32.0.100 from the docs) to it:

```shell
# ip link set enp5s0f3u2 up
# ip addr add 172.32.0.100 dev enp5s0f3u2
# ip addr show enp5s0f3u2
4: enp5s0f3u2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UNKNOWN group default qlen 1000
    link/ether c6:9e:eb:2b:6b:3f brd ff:ff:ff:ff:ff:ff
    inet 172.32.0.100/32 scope global enp5s0f3u2
       valid_lft forever preferred_lft forever
    inet6 fe80::c49e:ebff:fe2b:6b3f/64 scope link proto kernel_ll
       valid_lft forever preferred_lft forever
```

from the official docs, the default image supports adb, but seems it doesn't work:

```shell
# adb connect 173.32.0.100
* daemon not running; starting now at tcp:5037
* daemon started successfully
failed to connect to '173.32.0.100:5555': Connection refused
```

let's do a port scan:

```shell
# rustscan -a 173.32.0.100
...
PORT     STATE SERVICE   REASON
53/tcp   open  domain    syn-ack
1080/tcp open  socks     syn-ack
9100/tcp open  jetdirect syn-ack
```

ohh, this is my local machine, not the board :(

to access the board, i need the address of the board instead of my machine.

from the docs, it's `172.32.0.93`. let's add a route to it and try again:

```shell
# ip route add 172.32.0.93 dev enp5s0f3u2
# rustscan -a 172.32.0.93
...
PORT     STATE SERVICE REASON
5555/tcp open  freeciv syn-ack
# adb connect 172.32.0.93
* daemon not running; starting now at tcp:5037
* daemon started successfully
connected to 172.32.0.93:5555
```

it succeed :)

```shell
# adb -s 172.32.0.93:5555 shell
# uname -a
Linux Rockchip 5.10.110 #1 Tue Sep 26 17:50:43 CST 2023 armv7l GNU/Linux
# ifconfig
usb0      Link encap:Ethernet  HWaddr 1E:22:8C:FC:6F:FE
          inet addr:172.32.0.93  Bcast:172.32.255.255  Mask:255.255.0.0
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:66302 errors:0 dropped:15 overruns:0 frame:0
          TX packets:66389 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:3978211 (3.7 MiB)  TX bytes:6526339 (6.2 MiB)
```

## Why 172.32.0.93 ?

So how is the board configure it's ip to `172.32.0.93`?

It's hardcoded in `/etc/init.d/S99usb0config`

```bash
TARGET_IP="172.32.0.93"
```

When the system boots, it config the network interface to `TARGET_IP`.

