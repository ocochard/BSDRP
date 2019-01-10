BSD Router Project
==================

Copyright (c) 2009-2019, The BSDRP Development Team

Homepage: https://bsdrp.net

## Description

BSDRP is an embedded free and open source router distribution based on [FreeBSD](https://www.freebsd.org) with [FRRouting](https://frrouting.org) and [Bird](http://bird.network.cz/).

## Build-time requirements
 - FreeBSD 12.0 or higher

## Other information

The make.sh script is the build tool for generating BSDRP image:
./make.sh -h for displaying the help

More details on the website:
http://bsdrp.net/documentation/technical_docs

## Child projects
 * BSDRPstable: Same as BSDRP but based on FreeBSD-stable code
 * BSDRPcur: Same as BSDRP but based on FreeBSD-current code
 * TESTING: Generate a small nanobsd image (without packages), used for following network performance evolution in time
 * BSDMC: BSD Media Center, allow to test code factorisation/re-usability on a totally different project
 * [EINE](EINE/README.md): Easy Internet vPn Extender, it's a firmware that allow large scale and plug&play VPN routers deployement over internet. This project is member of [Orange Open Source](http://opensource.orange.com) sponsored by [Orange Business Services](http://orange-business.com).

