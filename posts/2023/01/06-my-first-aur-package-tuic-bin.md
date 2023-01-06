+++
title = "My First AUR package: tuic-bin"
+++

# {{title}}

For package not in Arch repository or AUR, I usually simply build or download it myself.

That's quite cumbersome and hard to maintain.

For example, to build [tuic](https://github.com/EAimTY/tuic), you need a Rust toolchain and lots of disk space. 

So I usually download it from Github release page, and put it to `$PATH`.

Go to release page, find the correct build, copy the url, wget, put it to `$PATH` ... I'm tired of it.

So I wirte my first PKGBUILD and submit it to AUR: [tuic-bin](https://aur.archlinux.org/packages/tuic-bin).

## Writing PKGBUILD

For prebuilt deliverables, it's quite easy.

Specify the files to download and sha256sum, use `install` to copy it to the expected location.

## Push to AUR

Arch Wiki and AUR use different account system. Not knowing that, I register for both :(

Then comes the most confusing part.

In [AUR submission guidelines](https://wiki.archlinux.org/title/AUR_submission_guidelines), I need to clone a pkgbase.

> If you are creating a new package from scratch, establish a local Git repository and an AUR remote by cloning the intended pkgbase.

> If the package does not yet exist, the following warning is expected: 

And it give this example:

```
git clone ssh://aur@aur.archlinux.org/pkgbase.git
Cloning into 'pkgbase'...
warning: You appear to have cloned an empty repository.
Checking connectivity... done.
```

So I try the command `git clone ssh://aur@aur.archlinux.org/pkgbase.git`, but I got an non empty repository.

Maybe I need to put my PKGBUILD inside it?

The I figured out that `pkgbase` is the package name you want to use. AUR will create the repository dynamically when you clone it.

```
$ git clone ssh://aur@aur.archlinux.org/tuic-bin.git
Cloning into 'tuic-bin'...
warning: You appear to have cloned an empty repository.
```

Add PKGBUILD and .SRCINFO, commit and push, then you can see the package in AUR site.

Cool.

