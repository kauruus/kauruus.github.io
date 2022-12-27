+++
title = "First Post"
+++

# {{ title }}

Just setup LunarVIM, Neovide and Franklin.

They all work out of box, save me so many time.

## LunarVIM

Follow the [installation guide](https://www.lunarvim.org/docs/installation), I install the Nightly version.

I run LunarVIM in a remote machine, so I start it with `--listen 0.0.0.0:<port>`

## Neovide

Simply download the prebuilt binary from github.

Connect to remove LunarVIM with `neovide --remote-tcp <host>:<port>`.

I just add one config to `~/.config/lvim/config.lua`:

```
vim.g.neovide_scale_factor = 1.5
```

But clipboard and input method doesn't work :(

## Franklin

Again, follow the official docs. 

I also copy the util function `hfun_posts` from [tlienart.github.io](https://tlienart.github.io).

