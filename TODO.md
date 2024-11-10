# TODO List

## Bugs #

* if no-mandatory /data had a fsck problem, system refuse go in single user
* add auto-trimming of all log files that are being created

## Boot loader ##
* poudriere-image uses EFI, need to test generated image on APU

## Authentication #

* Need to test PAM (Radius, TACAS+) modules

## misc #

* generate SBOM for each release
* Is utf-8 support for console usefull ?
* Need to publish an OVF (Open Virtualization Format) tar file
* Need to enable nuageinit (usefull for automatic regression tests)
* A netgraph documentation "for dummies" like this: http://nexus.org.ua/weblog/message/406/

## TRIM ##

Adding a rc script that automatically enable TRIM on /dev/ufs/BSDRP* if:
sudo camcontrol identify ada0 | grep TRIM | cut -d ' ' -f 5
give "yes"

## labs #

* Lab script: Generate a lab diagram in DOT language, see example in tools/bsdrp.lab.gv
* Lab script: Add a libvirt script
* Lab script: Add jail based lab

## Security

Embedded the mtree file, and just store its hash online
