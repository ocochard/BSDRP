# Release 2.0 (xxx)

## Special instruction before upgrade
Need BSDRP 1.994 minimum.
Upgrading will not add the dual UEFI/BIOS mode, a full reinstall is requiered.

## New features
* The Nanobsd framework is now replaced by poudriere-image. This brings:
  * Support for both BIOS and UEFI boot (you'll need to reinstall to add the EFI boot partition)
  * Migration from MBR to GPT
  * Packages built using the official poudriere method
* New packages:
  * net/vpp
  * net/frr10 has lua scripting enabled
* Removed packages:
  * isc-dhcp44 (use dnsmasq)
  * dhcprelya (use dnsmasq)

## To fix and test before release
* reboot or halt when asking to save modifications, refuse to continue if
  pressed "no" when we don’t want to save.
* "/usr/local/etc/rc.d/pimd: 20: Syntax error: Unterminated quoted string"
* bootonce script that should do:
  * gpart recover da0 (fix 'corrupt' status on gpt partitions)
  * Check for bootfailed attribute and act regarding
  * Update script need to be updated to add bootonce and not removing bootme

## Upgraded packages

TO DO

## Packages list

TO DO
