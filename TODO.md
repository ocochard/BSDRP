# TODO List

## Bugs #

* if non-critical /data had a fsck problem, system refuses to go into single user
* add auto-trimming of all log files that are being created

## Boot loader ##
* bootonce script that should do:
  * Check for bootfailed attribute and act accordingly
  * Update script needs to be updated to add bootonce and not remove bootme

## Authentication #

* Need to test PAM (Radius, TACACS+) modules

## misc #

* Is UTF-8 support for console useful?
* Need to publish an OVF (Open Virtualization Format) tar file
* Need to enable nuageinit (useful for automatic regression tests)
* A netgraph documentation "for dummies" like this: http://nexus.org.ua/weblog/message/406/
* doc: Using mermaid markdown ? https://github.blog/developer-skills/github/include-diagrams-markdown-files-mermaid/

## TRIM ##

Adding an rc script that automatically enables TRIM on /dev/ufs/BSDRP* if:
sudo camcontrol identify ada0 | grep TRIM | cut -d ' ' -f 5
give "yes"

## labs #

* Lab script: Generate a lab diagram in DOT language, see example in tools/bsdrp.lab.gv
* Lab script: Add a libvirt script
* Lab script: Add jail based lab

## Security

Embedded the mtree file, and just store its hash online
