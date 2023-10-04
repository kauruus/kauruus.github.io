+++
title = "Build CubicSDR for Arch Linux"
hascode = true
+++

# {{ title }}

![](/assets/images/cubicsdr.png)


Currently, there is no prebuilt binary in Arch package repository. 
And the AppImage in Github release page is too old to run.
So I have to build it myself.

## Why Not AUR

There are `cubicsdr-git` and `cubicsdr` in AUR.

I tried `cubicsdr-git`, it need to compile WxWidgets, which is super time-consuming.

Hey, we already have prebuilt WxWidgets in Arch package repository, why bother to compile an old version?

## Building CubisSDR

You can follow dependencies list in `cubicsdr-git`.

Some dependencies like freeglut are already installed in my machine.

So I just install some new dependencies:

```
pacman -S wxwidgets-gtk3 hamlib soapysdr liquid-dsp
```

Clone and build:

```
git clone https://github.com/cjcliffe/CubicSDR.git
cd CubicSDR
mkdir build
cd build
cmake ../ -DCMAKE_BUILD_TYPE=Release -DUSE_HAMLIB=1
make -j $(nproc)
```

Done.

You still need soapy plugins for your device. For rtl-sdr:

```
pacman -S soapyrtlsdr
```

