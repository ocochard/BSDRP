#
# VirtualBox PowerShell lab script for BSD Router Project
# http://bsdrp.net
#
# Copyright (c) 2011, The BSDRP Development Team
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#


# Test: Is VirtualBox installed ?
function check_system () {
    $strComputer = "." 
    $colItems = get-wmiobject -class "Win32_Product" -namespace "root\CIMV2" -computername $strComputer 
    $VBOX_FOUND=$false
    foreach ($objItem in $colItems) { 
        if ($objItem.Name.Contains("VirtualBox")){
            $VBOX_FOUND=$true
            $VBOX_VERSION = $objItem.Version 
            break
        }
    }
    if ($VBOX_FOUND){
        Write-Host "[DEBUG]VBox found, and have release: $VBOX_VERSION"
        if ($VBOX_VERSION -lt 3.1) {
            Write-Host "ERROR: Need VirtualBox 3.1 (minimum)"
            exit
        }
        $global:VB_EXE=($ENV:VBOX_INSTALL_PATH + "VBoxManage.exe")
        $global:VB_HEADLESS=($ENV:VBOX_INSTALL_PATH + "VBoxHeadless.exe")
        if (-not (test-path $VB_EXE -PathType leaf)) {
            Write-Host "ERROR: VBox should be installed, but can't found executable"
            exit
        }
        Write-Host "[DEBUG]vb_exe: $VB_EXE"
        Write-Host "[DEBUG]vb_headless: $VB_HEADLESS"
    } else {
        Write-Host "No VBox found on this computer… exiting"
        exit
    }
}

# No isNumeric function included in PowerShell
# Got from http://rosettacode.org/wiki/Determine_if_a_string_is_numeric#PowerShell
function isNumeric ($x) {
    $x2 = 0
    $isNum = [System.Int32]::TryParse($x, [ref]$x2)
    return $isNum
}

# Check if base BSDRP VDI file is available()
Function check_base_vdi () {
    # TO DO
    Write-Host "[TODO]Check if base VDI exist, and ask user for it if not present"
    return $true
}

# Clone a new VM based on the base BSDRP VDI
Function clone_vm () {
    param ($NAME)
    Write-Host "[TODO]Clone $NAME"
    return $true
}
# Generate all VMs
Function generate_vms () {
    Write-Host "Creating lab with $NUMBER_VM routers"
    Write-Host "- All routers will be connected to $NUMBER_LAN common LAN"
    Write-Host "- Full mesh ethernet point-to-point link between each routers"
    if ($SHARED_LAN) {
        Write-Host "- One NIC connected to the shared LAN with the host"
    }
    
    #Enter the main loop for each VM
    for ($i=1;$i -le $NUMBER_VM;$i++) {
    
        clone_vm ("BSDRP_lab_R" + $i)
        $NIC_NUMBER=0
        Write-Host "Router $i have the folllowing NIC:"
        
        $j=1
        while ($j -le $NUMBER_VM){
            if ($i -ne $j) {
                Write-Host ("em" + $NIC_NUMBER + " connected to Router${j}.")
                $NIC_NUMBER++
                if ($i -le $j) {
                    $CMD=($VB_EXE + " modifyvm BSDRP_lab_R" + $i + "--nic" + $NIC_NUMBER + " intnet --nictype" + $NIC_NUMBER +" 82540EM --intnet" + $NIC_NUMBER + " LAN" + $i + $j + " --macaddress" + $NIC_NUMBER + " AAAA00000" + $i + $i + $j)
					Write-Host "[DEBUG]CMD to run:"
                    Write-Host $CMD
                } else {
                    $CMD=($VB_EXE + " modifyvm BSDRP_lab_R" + $i + "--nic" + $NIC_NUMBER + " intnet --nictype" + $NIC_NUMBER +" 82540EM --intnet" + $NIC_NUMBER +" LAN" + $j + $i + " --macaddress" + $NIC_NUMBER + " AAAA00000" + $i + $j + $i)
					Write-Host "[DEBUG]CMD to run:"
                    Write-Host $CMD
                }
            }
            $j++ 
        }
        
        #Enter in the LAN NIC loop
        $j=1
        while ($j -le $NUMBER_LAN) {
            Write-Host ("em" + $NIC_NUMBER + " connected to LAN number " + $j)
            $NIC_NUMBER++
            $CMD=($VB_EXE + " modifyvm BSDRP_lab_R" + $i + " --nic" + $NIC_NUMBER + " intnet --nictype" + $NIC_NUMBER + " 82540EM --intnet" + $NIC_NUMBER + " LAN10" + $j + " --macaddress" + $NIC_NUMBER + " CCCC00000" + $j + "0" + $i)
		    Write-Host "[DEBUG]CMD to run:"
			Write-Host $CMD
            $j++
        }
        
        #Enter the shared with host lan
		if ($SHARED_LAN) {
			Write-Host ("em" + $NIC_NUMBER + " connected to shared-with-host LAN.")
            $NIC_NUMBER++
			$CMD=($VB_EXE + " modifyvm BSDRP_lab_R" + $i + " --nic" + $NIC_NUMBER + ' hostonly --hostonlyadapter1 "VirtualBox Host-Only Ethernet Adapter" --nictype' + $NIC_NUMBER + " 82540EM --macaddress" + $NIC_NUMBER + " 00bbbb00000" + $i)
		    Write-Host "[DEBUG]CMD to run:"
			Write-Host $CMD
		}
    }
}

#### Main ####

check_system

#Set window title
$window = (Get-Host).UI.RawUI
$window.WindowTitle = "BSD Router Project: VirtualBox lab PowerShell script"

do {
    $NUMBER_VM = Read-Host "How many full-meshed routers do you want to start? (between 2 and 9)"
} until ((isNumeric $NUMBER_VM) -and ($NUMBER_VM -ge 2) -and ($NUMBER_VM -le 9))
do {
    $NUMBER_LAN = Read-Host "How many shared LAN between your routers do you want ? (between 0 and 4)"
} until ((isNumeric $NUMBER_LAN) -and ($NUMBER_LAN -ge 0) -and ($NUMBER_LAN -le 4))

$SHARED_LAN=$false
$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes",""
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No",""
$choices = [System.Management.Automation.Host.ChoiceDescription[]]($yes,$no)
#$caption = "Warning!"
$message = "Do you want a shared LAN between your routers and the host ? (Usefull for IP access to the routers from your host, can be used as shared LAN between routers too)"
$result = $Host.UI.PromptForChoice($caption,$message,$choices,0)
if($result -eq 0) { $SHARED_LAN=$true }

#[DEBUG]
Write-Host "[DEBUG]Number of VM: $NUMBER_VM, number of LAN: $NUMBER_LAN"
if ($SHARED_LAN) {
    Write-Host "[DEBUG]Shared lan: Enabled"
} else {
    Write-Host "[DEBUG]Shared lan: Disabled"
}

check_base_vdi

generate_vms

$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")