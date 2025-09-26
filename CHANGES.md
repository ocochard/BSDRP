# Release 2.0 (xxx)

## Special instruction before upgrade
Need BSDRP 1.994 minimum.
Upgrading will not add the dual UEFI/BIOS mode, a full reinstall is requiered.

## New features
* The Nanobsd framework is now replaced by poudriere-image. This brings:
  * Support for both BIOS and UEFI boot
     * Need a full reinstall to switch to EFI/GPT partition type
  * Migration from MBR to GPT
  * Packages built using the official poudriere method
* New packages:
  * net/vpp
  * net/frr10 has lua scripting enabled
* Removed packages:
  * isc-dhcp44 (use dnsmasq)
  * dhcprelya (use dnsmasq)

## Upgraded packages

TO DO

## Packages list

TO DO
