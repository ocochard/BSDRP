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

# Error management
$error.clear()
$erroractionpreference = "Stop"

#### Variables #####
$VM_TPL_NAME="BSDRP_lab_template"

#### enumeration types ######
# PowerShell can't import type library from a COM Object
# http://msdn.microsoft.com/en-us/library/hh228154.aspx
# Need to copy/write all enums type

#StorageBus
$StorageBus_IDE = 1
$StorageBus_SATA = 2
$StorageBus_SCSI = 3
$StorageBus_Floppy = 4
$StorageBus_SAS = 5

#StorageControllerType
$StorageControllerType_LsiLogic = 1
$StorageControllerType_BusLogic = 2
$StorageControllerType_IntelAhci = 3
$StorageControllerType_PIIX3 = 4
$StorageControllerType_PIIX4 = 5
$StorageControllerType_ICH6 = 6
$StorageControllerType_I82078 = 7
$StorageControllerType_LsiLogicSas = 8

#DeviceType
$DeviceType_Floppy = 1
$DeviceType_DVD = 2
$DeviceType_HardDisk = 3
$DeviceType_Network = 4
$DeviceType_USB = 5
$DeviceType_SharedFolder = 6

#AccessMode
$AccessMode_ReadOnly = 1
$AccessMode_ReadWrite = 2
 
#LockType
$LockType_Write = 2
$LockType_Shared = 1

#### Functions definition

# Is VirtualBox installed ?
# Return true if yes, and not if not installed, and initialize $VBOX object
function init_vbox_api () {
    Write-Host "Initializing VBOX COM API..";
    #Not a good idea: Only one instance of VirtualBox.VirtualBox can be open
    #and this test can return $false because .VirtualBox is a singleton
    try { $global:VBOX = New-Object -ComObject VirtualBox.VirtualBox }
    catch { 
        return $false
    }
    return $true 
}

# No isNumeric function included in PowerShell
# Function from http://rosettacode.org/wiki/Determine_if_a_string_is_numeric#PowerShell
function isNumeric ($x) {
    $x2 = 0
    $isNum = [System.Int32]::TryParse($x, [ref]$x2)
    return $isNum
}

# Create the template
Function create_vm_template () {
    $error.clear()
    Write-Host "Generate BSDRP Lab Template VM..."
    parse_filename

    #Create VM
    try {$global:VBOX_VM_TPL=$VBOX.createMachine("",$VM_TPL_NAME,$VM_ARCH,"",$false)}
    catch {
        Write-Host "[ERROR] Can't create BSDRP_lab_template VM"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    #Configure the VM
	#try { $VBOX_VM_TPL_CTRL = $VBOX_VM_TPL.addStorageController("PATA Controller",$StorageBus_IDE) }
    try { $VBOX_VM_TPL_CTRL = $VBOX_VM_TPL.addStorageController("SATA Controller",$StorageBus_SATA) }
	catch {
        Write-Host "[ERROR] Can't Add a Storage Controller to BSDRP_lab_template VM "
        Write-Host "Detail: " $($error)
        clean_exit
    }
    #try {$VBOX_VM_TPL_CTRL.controllerType = $StorageControllerType_IntelAhci}
    #catch {
    #    Write-Host "[ERROR] Can't set Storage Controller type to $VM_TPL_NAME VM"
    #    Write-Host "Detail: " $($error)
    #    clean_exit
    #}
    #$VBOX_VM_TPL_CTRL.portCount=1
    $VBOX_VM_TPL.MemorySize=128
    $VBOX_VM_TPL.VRAMSize=6
    $VBOX_VM_TPL.Description="BSD Router Project Template VM"
    $VBOX_VM_TPL.setExtraData("uart1","0x3F8 4")
    #$VBOX_VM_TMPL_SERIAL=$VBOX_VM_TPL.getSerialPort(0)
    
    try { $VBOX_VM_TPL.saveSettings }
    catch {
        Write-Host "[ERROR] Can't save $VM_TPL_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
  
    
    #Now, Convert the disk-img to VDI
    
    # check if there allready exist a VDI in the folder, and delete it
    # Case where there allready a VDI : Script break between converting RAW to VDI and registering the VDI, 
    # then deleting the template from the manager
    $DST_VDI_FILE=$VBOX.SystemProperties.DefaultMachineFolder + "\$VM_TPL_NAME\$VM_TPL_NAME.vdi"
    
    if (test-path $DST_VDI_FILE -PathType leaf) {
    	Write-Host "[WARNING]: Existing old VDI found, delete it"
        Remove-Item -path $DST_VDI_FILE -force
    }

    #Call VBoxManage for converting the given .img to VDI.
    $CMD="convertfromraw " + '"' + $FILENAME +'" "' + $DST_VDI_FILE + '"'
    try { invoke-expression "& $VB_MANAGE $CMD" }
    catch {
        Write-Host "[BUG] Return $?, but error catch triggered"
        Write-Host "Will continue without managing this error"
        #Write-Host "Detail: " $($error)
        Write-Host "Result is $?."
    }
    
    $error.clear()
    
    # Need to register the VM before attaching disk to it
    try { $VBOX.registerMachine($VBOX_VM_TPL) }
    catch {
        Write-Host "[ERROR] Can't register $VM_TPL_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    # Need to register the VDI before using it
    try {
        $VBOX_VM_TPL_VDI=$VBOX.openMedium($DST_VDI_FILE,$DeviceType_HardDisk,$AccessMode_ReadWrite,$true)
    } catch {
        Write-Host "[ERROR] Can't Open/register $DST_VDI_FILE"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    # Need to unclock the VM (put it in "mutable" state) before modifying it

    #  === More I'm using VirtualBox, more I love qemu ! ====
    
    try { $VBOX_VM_TPL.lockMachine($SESSION,$LockType_Write) }
    catch {
        Write-Host "[ERROR] Can't lock $VM_TPL_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    # At last ! Attach the disk to unlocked-copy-object of the VM
    
    try {
        $SESSION.machine.attachDevice("SATA Controller",0,0,$DeviceType_HardDisk,$VBOX_VM_TPL_VDI)
    } catch {
        Write-Host "[ERROR] Can't attach $DST_VDI_FILE to $VM_TPL_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    try { $VBOX_VM_TPL.saveSettings }
    catch {
        Write-Host "[ERROR] Can't save $VM_TPL_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    try { $SESSION.unlockMachine() }
    catch {
        Write-Host "[ERROR] Can't unlock $VM_TPL_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    $VBOX_VM_TPL
    $VBOX_VM_TPL_VDI
    $VBOX_VM_TPL_CTR
    write-host "[DEBUG]SUCCESS... exit!"
   	clean_exit
}

# Parse the BSDRP filename given (is a i386 or amd64, is a vga or serial)
Function parse_filename () {
    Write-Host "Parsing filename given for guesing ARCH and CONSOLE values:"
    if ($FILENAME.Contains("_amd64")) {
        $global:VM_ARCH="FreeBSD_64"
        Write-Host "- ARCH: x86-64"
    } elseif ($FILENAME.Contains("_i386")) {
        $global:VM_ARCH="FreeBSD"
        Write-Host "- ARCH: i386"
    } else {
        Write-Host "[ERROR] Can't guests arch of this image"
        clean_exit
    }
    if ($FILENAME.Contains("_serial")) {
        $global:SERIAL=$true
        Write-Host "- CONSOLE: serial" 
    } elseif ($FILENAME.Contains("_vga")) {
        $global:SERIAL=$false
        Write-Host "- CONSOLE: vga"
    } else {
        Write-Host "ERROR: Can't guests arch of this image"
        clean_exit
    }
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
		    Write-Debug "CMD to run:" $CMD
			Write-Host $CMD
            $j++
        }
        
        #Enter the shared with host lan
		if ($SHARED_LAN) {
			Write-Host ("em" + $NIC_NUMBER + " connected to shared-with-host LAN.")
            $NIC_NUMBER++
			$CMD=($VB_EXE + " modifyvm BSDRP_lab_R" + $i + " --nic" + $NIC_NUMBER + ' hostonly --hostonlyadapter1 "VirtualBox Host-Only Ethernet Adapter" --nictype' + $NIC_NUMBER + " 82540EM --macaddress" + $NIC_NUMBER + " 00bbbb00000" + $i)
		    Write-Debug "CMD to run:" $CMD
			Write-Host $CMD
		}
    }
}

Function clean_exit () {
	# Cleaning stuff before exiting...
	exit
}
#### Main ####

# A powershell script by default is running in mode MTA, but for displaying dialog box, STA mode is needed
if($host.Runspace.ApartmentState -ne "STA") {
    Write-Host "Relaunching PowerShell script in STA mode"
    powershell -NoProfile -Sta -File $MyInvocation.InvocationName
    return
}

# Create Window

#$WINDOW=New-Object System.Windows.Forms.Form
#$WINDOW.ShowDialog()

#Set window title
$WINDOW = (Get-Host).UI.RawUI
$TITLE = "BSD Router Project: VirtualBox lab PowerShell script"
$WINDOW.WindowTitle = $TITLE

# Stop if vbox is not installed
if (!(init_vbox_api)) {
    Write-Host "[ERROR] Can't init vbox COM API...exiting"
    clean_exit
}

try { $global:SESSION = New-Object -ComObject VirtualBox.Session }
catch {
    Write-Host "[ERROR] Can't create a SESSION object"
    Write-Host "Detail: " $($error)
    clean_exit
}

#Still need to use VboxManage because COM API didn't support all features (like converting RAW)
#Need to put quote, because there is space in name file
$global:VB_MANAGE ='"' + $env:VBOX_INSTALL_PATH + "VBoxManage.exe" + '"'

#If BSDRP VM template doesn't exist, ask for a filename

try { $VBOX_VM_TEMPLATE=$VBOX.findMachine($VM_TPL_NAME) }
catch {
    Write-Host "No BSDRP VM Template found."
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    $objForm = New-Object System.Windows.Forms.OpenFileDialog
    $objForm.InitialDirectory = "."
    $objForm.Filter = "BSDRP image Files (*.img)|*.img"
    $objForm.Title = "Select BSDRP full image disk"
    $Show = $objForm.ShowDialog()
    If ($Show -eq "OK") {
    	$global:FILENAME=$objForm.FileName
    } Else {
    	Write-Error "Operation cancelled"
        Write-Host
        clean_exit
    }
    create_vm_template
}

do {
    $NUMBER_VM = Read-Host "How many routers to start? (between 2 and 9)"
} until ((isNumeric $NUMBER_VM) -and ($NUMBER_VM -ge 2) -and ($NUMBER_VM -le 9))
do {
    $NUMBER_LAN = Read-Host "How many shared LAN between all your routers? (between 0 and 4)"
} until ((isNumeric $NUMBER_LAN) -and ($NUMBER_LAN -ge 0) -and ($NUMBER_LAN -le 4))

$SHARED_LAN=$false
$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes",""
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No",""
$CHOICES = [System.Management.Automation.Host.ChoiceDescription[]]($yes,$no)
$MESSAGE = "Enable shared LAN between your routers and the host ? (Permit IP access between the routers and your host)"
$RESULT = $Host.UI.PromptForChoice($TITLE,$MESSAGE,$CHOICES,0)
if($RESULT -eq 0) { $SHARED_LAN=$true }

generate_vms

clean_exit

Write-Host "Press a key to continue"
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")