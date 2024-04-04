# [![BSDRP logo](logos/BSDRP.logo.128.png)BSD Router Project](https://bsdrp.net)

Copyright (c) 2009-2024, The BSDRP Development Team

## Description

BSD Router Project (BSDRP) is an embedded free and open source router distribution based on [FreeBSD](https://www.freebsd.org) with [FRRouting](https://frrouting.org) and [Bird](http://bird.network.cz/).

## Build-time requirements
 - FreeBSD 14.0 or higher
 - poudriere

## Other information

The build script is the build tool for generating BSDRP image:
```
./build -h
```

[More details on the technical documentations section]( https://bsdrp.net/documentation/technical_docs)

## Child projects
 * MAIN, STABLE-13, STABLE12: Generate a small nanobsd image (without packages), used for following network performance evolution in time
 * [EINE](EINE/README.md): Easy Internet vPn Extender, it's a firmware that allow large scale and plug&play VPN routers deployement over internet. This project is member of [Orange Open Source](http://opensource.orange.com) sponsored by [Orange Business Services](http://orange-business.com).

