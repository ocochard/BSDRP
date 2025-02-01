# [![BSDRP logo](logos/BSDRP.logo.128.png)BSD Router Project](https://bsdrp.net)

Copyright (c) 2009-2025, The BSDRP Development Team

## Description

The BSD Router Project (BSDRP) is a free, open-source router distribution based on [FreeBSD](https://www.freebsd.org).
It includes software like: [FRRouting](https://frrouting.org), [Bird](http://bird.network.cz/), [ExaBGP](https://github.com/Exa-Networks/exabgp), [OpenVPN](https://openvpn.net/) and [strongSwan](https://www.strongswan.org/).

## Requirements to Build

- FreeBSD 14.2 or higher
- poudriere
- git

## How to build

The build system uses a Makefile. To build BSDRP image disks, run:
```
make
```

And `make help` for more information.

[Learn more in the technical documentation]( https://bsdrp.net/documentation/technical_docs)
