# [![BSDRP logo](logos/BSDRP.logo.128.png)BSD Router Project](https://bsdrp.net)

Copyright (c) 2009-2025, The BSDRP Development Team

## Description

The BSD Router Project (BSDRP) is a free, open-source router distribution based on [FreeBSD](https://www.freebsd.org).
It includes softwares like: [FRRouting](https://frrouting.org), [Bird](http://bird.network.cz/), [ExaBGP](https://github.com/Exa-Networks/exabgp), [OpenVPN](https://openvpn.net/) and [strongSwan](https://www.strongswan.org/).

## Requirements to Build

- FreeBSD 14.2 or higher
- poudriere
- git

## How to build

The build system uses a Makefile. To build an image, just run:
```
make
```

[Learn more in the technical documentation]( https://bsdrp.net/documentation/technical_docs)
