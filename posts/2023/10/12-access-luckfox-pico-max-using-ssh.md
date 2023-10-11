+++
title = "Access LuckFox Pico Max using SSH"
hascode = true
+++

# {{ title }}

# Get The Cross Compile Toolchain

The official toolchain is `arm-rockchip830-linux-uclibcgnueabihf`, which can be obtained [here](https://github.com/LuckfoxTECH/luckfox-pico/tree/main/tools/linux/toolchain/arm-rockchip830-linux-uclibcgnueabihf).

Instead of the official one, I use `armv7l-linux-musleabihf` from [musl.cc](https://musl.cc).

You can chose whatever you want, I just happend to have the musl.cc one and don't bother to download another one.

# Build Dropbear SSH

Here I use [Dropbear](https://matt.ucc.asn.au/dropbear/dropbear.html) instead of OpenSSH, since it's considerable smaller than OpenSSH, and it's easier to compile.

Download current latest release:

```shell
$ wget https://matt.ucc.asn.au/dropbear/releases/dropbear-2022.83.tar.bz3
$ tar xf dropbear-2022.83.tar.bz3
$ cd dropbear-2022.83
```

Configure and build:

```shell
$ ./configure --host=armv7l-linux-musleabihf --disable-zlib --disable-syslog --disable-lastlog --enable-static --disable-wtmp
$ make PROGRAMS='dropbear scp' SCPPROGRESS=1
```

Here I build only the `dropbear` server and `scp`, since i use the ssh client from OpenSSH.

Notice: OpenSSH has deprecated SCP and use SFTP protocol by default. To use SCP, you need `-O` flag, e.g, `scp -O file root@172.32.0.93:/tmp`.

# Setup

Push `dropbear` and `scp` binary using ADB:

```shell
$ adb -s 172.32.0.93:5555 push dropbear /bin
$ adb -s 172.32.0.93:5555 push scp /bin
```

In ADB shell, change root password and correct `/root` permission:

```shell
# passwd 
# chown 0:0 /root
# chmod 700 /root
```

Then run the dropbear server:

```shell
# mkdir /etc/dropbear
# dropbear -R -F
```

`-R` means `Create hostkeys as required`, it will create host key when you connect to it.

Now you can connect to it:

```shell
$ ssh root@172.32.0.93 
```

# Make it Start Automatically

Create a init file `/etc/init.d/S99dropbear`:

```bash
#!/bin/sh
case $1 in
	start)
		/bin/dropbear
		;;
	stop)
		killall dropbear
		;;
	*)
		exit 1
		;;
esac
```

The next you start the system, it will run `dropbear` automatically.

