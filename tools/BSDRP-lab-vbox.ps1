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
[string] $VM_TPL_NAME="BSDRP_lab_template"

#### enumeration types######
# PowerShell can't import type library from a COM Object
# http://msdn.microsoft.com/en-us/library/hh228154.aspx
# Need to copy/write all enums type used in this script
function set_API_enums() {
    # As "Global" variable, there are not release in the debugger
    # avoid to generate an error
    if (!(Test-Path Variable:Virtualbox_API_Enums)) {
        $Global:Virtualbox_API_Enums=@{
            StorageBus_IDE = 1;
            StorageBus_SATA = 2;
            StorageBus_SCSI = 3;
            StorageBus_Floppy = 4;
            StorageBus_SAS = 5;
            
            StorageControllerType_LsiLogic = 1;
            StorageControllerType_BusLogic = 2;
            StorageControllerType_IntelAhci = 3;
            StorageControllerType_PIIX3 = 4;
            StorageControllerType_PIIX4 = 5;
            StorageControllerType_ICH6 = 6;
            StorageControllerType_I82078 = 7;
            StorageControllerType_LsiLogicSas = 8;
            
            DeviceType_Null = 0;
            DeviceType_Floppy = 1;
            DeviceType_DVD = 2;
            DeviceType_HardDisk = 3;
            DeviceType_Network = 4;
            DeviceType_USB = 5;
            DeviceType_SharedFolder = 6;

            AccessMode_ReadOnly = 1;
            AccessMode_ReadWrite = 2;
             
            LockType_Write = 2;
            LockType_Shared = 1;

            PortMode_Disconnected = 0;
            PortMode_HostPipe = 1;
            PortMode_HostDevice = 2;
            PortMode_RawFile = 3;

            CloneMode_MachineState = 1;
            CloneMode_MachineAndChildStates = 2;
            CloneMode_AllStates = 3;

            CloneOptions_Link = 1;
            CloneOptions_KeepAllMACs = 2;
            CloneOptions_KeepNATMACs = 3;
            CloneOptions_KeepDiskNames = 4;
       
        } #Virtualbox_API_Enums

        $Virtualbox_API_Enums.GetEnumerator() | Foreach-Object {
            Set-Variable $($_.Key) -value $([int32] $_.Value) -option constant -scope Global
        }
    } # endif
} # function set_API_enum

#### Functions definition

# Initialize VirtualBox COM Object
# Return true if yes, and not if not installed, and initialize $VIRTUALBOX object
function init_com_api () {
    Write-Verbose "Initializing VirtualBox COM API...";
    try { $global:VIRTUALBOX = New-Object -ComObject VirtualBox.VirtualBox }
    catch {
        return $false
    }
    return $true 
}

# Create the template
Function create_template () {
    $error.clear()
    Write-Host "Generate BSDRP Lab Template VM..."
	
	# Ask the user for BSDR full-image
	[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    $objForm = New-Object System.Windows.Forms.OpenFileDialog
    $objForm.InitialDirectory = "."
    $objForm.Filter = "BSDRP image Files (*.img)|*.img"
    $objForm.Title = "Select BSDRP full image disk"
    $Show = $objForm.ShowDialog()
    If ($Show -eq "OK") {
    	$FILENAME=$objForm.FileName
    } Else {
    	Write-Error "Operation cancelled"
        clean_exit
    }
	
	# Define $VM_ARCH and $SERIAL from the filename
    $null = parse_filename $FILENAME

    # check if there allready exist folder, and delete it
    # Case where there allready a folder: Script break between converting RAW to VDI and registering the VDI, 
    # then deleting the template from the manager
    $VM_DIR=$VIRTUALBOX.SystemProperties.DefaultMachineFolder + "\$VM_TPL_NAME"
    
    if (test-path $VM_DIR -PathType container) {
    	Write-Host "[WARNING]: Existing old VM folder found, delete it"
        Remove-Item -path $VM_DIR -force -recurse
    }
    #Create VM
    try {$MACHINE=$VIRTUALBOX.createMachine("",$VM_TPL_NAME,$VM_ARCH,"",$false)}
    catch {
        Write-Host "[ERROR] Can't create $VM_TPL_NAME machine"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    #Configure the VM
    
    $MACHINE.MemorySize=128
    $MACHINE.VRAMSize=6
    $MACHINE.Description="BSD Router Project Template VM"
    $MACHINE.setBootOrder(1,$DeviceType_HardDisk)
    $MACHINE.setBootOrder(2,$DeviceType_Null)
    $MACHINE.setBootOrder(3,$DeviceType_Null)
    $MACHINE.setBootOrder(4,$DeviceType_Null)
	# Serial port
	# Link the VM serial port to a pipe into the host
	# You can connect, from the host, to the serial port of the VM 
	$MACHINE_SERIAL=$MACHINE.getSerialPort(0)
	$MACHINE_SERIAL.path="\\.\pipe\$MACHINE_NAME"
	$MACHINE_SERIAL.hostMode=$PortMode_HostPipe
	$MACHINE_SERIAL.server=$true
	$MACHINE_SERIAL.enabled=$true   
    
    # Adding a disk controller to the machine
    try { $MACHINE_STORAGECONTROLLER = $MACHINE.addStorageController("SATA Controller",$StorageBus_SATA) }
	catch {
        Write-Host "[ERROR] Can't Add a Storage Controller to $VM_TPL_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
    }
  
    $MACHINE_STORAGECONTROLLER.portCount=1

    # Save the VM settings
    try { $MACHINE.saveSettings() }
    catch {
        Write-Host "[ERROR] Can't save $VM_TPL_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    # Need to register the VM (mandatory before attaching disk to it)
    try { $VIRTUALBOX.registerMachine($MACHINE) }
    catch {
        Write-Host "[ERROR] Can't register $VM_TPL_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    #Convert the BSDRP raw image disk to VDI using VIRTUALBOXManage.exe
    #Still need to use VIRTUALBOXManage because COM API didn't support all features (like converting RAW)
    #Need to put quote, because there is space in name file
    
    $VDI_FILE=$VIRTUALBOX.SystemProperties.DefaultMachineFolder + "\$VM_TPL_NAME\$VM_TPL_NAME.vdi"
    
    #Call VBoxManage.exe for converting the given .img to VDI.
    $VB_MANAGE ='"' + $env:VBOX_INSTALL_PATH + "VBoxManage.exe" + '"'
    
    $CMD="convertfromraw " + '"' + $FILENAME +'" "' + $VDI_FILE + '"'

    try { invoke-expression "& $VB_MANAGE $CMD" }
    catch {
        Write-Verbose "[BUG] invoke-expression Return $?, even if command successfull."
    }
   
    $error.clear()
    
     # Another if $VDI_FILE exist, because I didn't understand the error code of invoke-expression
    if (!(test-path $VDI_FILE -PathType leaf)) {
    	Write-Host "[ERROR]: RAW to VDI converstion error, no VDI file found"
        clean_exit
    }
    
    # Register the VDI (Mandatory before attaching it to a VM)
    try {
        $MEDIUM=$VIRTUALBOX.openMedium($VDI_FILE,$DeviceType_HardDisk,$AccessMode_ReadWrite,$true)
    } catch {
        Write-Host "[ERROR] Can't Open/register $VDI_FILE"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    # Compact the VDI (and create a process object)
    try { $PROGRESS=$MEDIUM.compact() }
    catch {
        Write-Host "[ERROR] Can't Compact the VDI FILE"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    # Wait for end of compacting the VDI...
    try { $PROGRESS.waitForCompletion(-1) }
    catch {
        Write-Host "[ERROR] Wait for end of VDI compact failed"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    # Need to unclock the VM (put it in "mutable" state) before modifying it
    #  === More I'm using VirtualBox, more I love qemu ! ====
    
    try { $MACHINE.lockMachine($SESSION,$LockType_Write) }
    catch {
        Write-Host "[ERROR] Can't lock $VM_TPL_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    # At last ! Attach the disk to unlocked-copy-object of the VM
    # But need to use the $SESSION.machine and not the $MACHINE object
    try {
        $SESSION.machine.attachDevice("SATA Controller",0,0,$DeviceType_HardDisk,$MEDIUM)
    } catch {
        Write-Host "[ERROR] Can't attach $DST_VDI_FILE to $VM_TPL_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    # Save new settings
    try { $SESSION.machine.saveSettings() }
    catch {
        Write-Host "[ERROR] Can't save $VM_TPL_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    # Create a snapshot (will be mandatory for creating linked type clone)
    try { $PROGRESS=$SESSION.console.takeSnapshot("SNAPSHOT","Initial snapshot used for clone") }
    catch {
        Write-Host "[ERROR] Can't create a snapshot for $VM_TPL_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    # Wait for end of taking the snapshot...
    try { $PROGRESS.waitForCompletion(-1) }
    catch {
        Write-Host "[ERROR] Wait for end of snapshot failed"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    # Unlock the machine
    try { $SESSION.unlockMachine() }
    catch {
        Write-Host "[ERROR] Can't unlock $VM_TPL_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
}

# Parse the BSDRP filename given (is a i386 or amd64, is a vga or serial)
# Modify the global variable:VM_ARCH and CONSOLE
# TO DO: return the results in place of using global variables
Function parse_filename () {
	param ($FILE_NAME)
    Write-Host "Parsing filename given for guesing ARCH and CONSOLE values:"
    if ($FILE_NAME.Contains("_amd64")) {
        $global:VM_ARCH="FreeBSD_64"
        Write-Host "- ARCH: x86-64"
    } elseif ($FILE_NAME.Contains("_i386")) {
        $global:VM_ARCH="FreeBSD"
        Write-Host "- ARCH: i386"
    } else {
        Write-Host "[ERROR] Can't guests arch of this image"
        clean_exit
    }
    if ($FILE_NAME.Contains("_serial")) {
        $global:SERIAL=$true
        Write-Host "- CONSOLE: serial" 
    } elseif ($FILE_NAME.Contains("_vga")) {
        $global:SERIAL=$false
        Write-Host "- CONSOLE: vga"
    } else {
        Write-Host "ERROR: Can't guests arch of this image"
        clean_exit
    }
	return $true
}

# Clone a new VM based on the base BSDRP VDI
Function clone_vm () {
    param ($CLONE_NAME)
	
	try {$MACHINE_TEMPLATE=$VIRTUALBOX.findMachine($VM_TPL_NAME)}
	catch {
		Write-Host "[BUG] clone_vm didn't found $VM_TPL_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
	}
    $error.clear()
    
    # Get the first snapshot of this machine:
    
    try {$MACHINE_TEMPLATE_SNAPSHOT=$MACHINE_TEMPLATE.findSnapshot($null) }
    catch {
		Write-Host "[BUG] clone_vm didn't found the snapshot of $VM_TPL_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
	}
    
	$error.clear()
	try {$MACHINE_CLONE=$VIRTUALBOX.createMachine("",$CLONE_NAME,$VM_ARCH,"",$false)}
    catch {
        Write-Host "[ERROR] Can't create $CLONE_NAME clone"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    # MACHINE.cloneTo need:
    #   To be start from a SNAPSHOT object
    #   an array for CloneOptions
	[Int[]] $CloneOptions=@($CloneOptions_Link)
	try {$PROGRESS=$MACHINE_TEMPLATE_SNAPSHOT.machine.cloneTo($MACHINE_CLONE,$CloneMode_MachineState,$CloneOptions) }
	catch {
		Write-Host "[ERROR] Can't create $CLONE_NAME machine"
        Write-Host "Detail: " $($error)
        clean_exit
	}
	
	 # Wait for end of clonning the VM...
    try { $PROGRESS.waitForCompletion(-1) }
    catch {
        Write-Host "[ERROR] Wait for end of clonning $CLONE_NAME process failed"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    # Change the serial PIPE NAME
    $MACHINE_CLONE_SERIAL=$MACHINE_CLONE.getSerialPort(0)
	$MACHINE_CLONE_SERIAL.path="\\.\pipe\$CLONE_NAME"
    
     # Save the VM settings
    try { $MACHINE_CLONE.saveSettings() }
    catch {
        Write-Host "[ERROR] Can't save $CLONE_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    # Need to register the clone
    try { $VIRTUALBOX.registerMachine($MACHINE_CLONE) }
    catch {
        Write-Host "[ERROR] Can't register $CLONE_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
}

# Modify VM NIC
# First parameter: (string), VM name
# Second parameter: (int), NIC number 
# Third parameter: (string), LAN name
# Forth parameter: (string), MAC address to use
# Fifth parameter: (bool), set true for Host Only NIC
Function modify_lan () {
    param ([string]$VM_NAME,[int]$NIC,[string]$LAN,[string]$MAC,[bool]$HOST_ONLY=$false)
    if ($HOST_ONLY) {
        $CMD=($VB_EXE + " modifyvm $VM_NAME --nic$NIC hostonly --hostonlyadapter1 ""VirtualBox Host-Only Ethernet Adapter"" --nictype$NIC 82540EM --macaddress$NIC $MAC")    
    } else {
        $CMD=($VB_EXE + " modifyvm $VM_NAME --nic$NIC intnet --nictype$NIC 82540EM --intnet$NIC LAN$LAN --macaddress$NIC $MAC")
    }
    write-Host "[DEBUG] Function CMD to run:"
    write-host $CMD
}                        
                        
# Build the lab: Clone and Configure all VMs
# First parameter: (int), number of VM to clone/start
# Second parameter: (int), number of LAN 
# Third parameter: (bool), Shared with host LAN
# Forth parameter: (bool), Full Mesh link
Function build_lab () {
    param ([int]$NUMBER_VM,[int]$LAN,[bool]$SHARED_WITH_HOST_LAN,[bool]$FULL_MESH)
    Write-Host "Setting-up a lab with $NUMBER_VM routers"
    Write-Host "- All routers will be connected to $LAN common LAN"
    Write-Host "- Full mesh ethernet point-to-point link between each routers"
    
    #Enter the main loop for each VM
    for ($i=1;$i -le $NUMBER_VM;$i++) {
		try { $MACHINE_CLONE=$VIRTUALBOX.findMachine("BSDRP_lab_R$i") }
        catch {
			clone_vm ("BSDRP_lab_R$i")
			$MACHINE_CLONE=$VIRTUALBOX.findMachine("BSDRP_lab_R$i")
		}
		
        [int] $NIC_NUMBER=0
        Write-Host "Router $i have the folllowing NIC:"
        
        # Enter the full-mesh links loop
        
        if ($FULL_MESH) {
            $j=1
            while ($j -le $NUMBER_VM){
                if ($i -ne $j) {
                    Write-Host ("em" + $NIC_NUMBER + " connected to Router${j}.")
                    $NIC_NUMBER++
                    if ($i -le $j) {
                        modify_lan "BSDRP_lab_R$i" $NIC_NUMBER ("$i" + "$j") ("AAAA00000" + $i + $i + $j)
                    } else {
                        modify_lan "BSDRP_lab_R$i" $NIC_NUMBER ("$j" + "$i") ("AAAA00000" + $i + $j + $i)
                    }
                } # endif avoiding himself in compute
                $j++ 
            } # end of while NUMBER_VM
        } #endif of FULL_MESH
        
        #Enter in the LAN NIC loop
        $j=1
        while ($j -le $NUMBER_LAN) {
            Write-Host ("em" + $NIC_NUMBER + " connected to LAN number " + $j)
            $NIC_NUMBER++
            modify_lan "BSDRP_lab_R$i" $NIC_NUMBER ("10" + $j) ("CCCC00000" + $j + "0" + $i)
            $j++
        } #end of while LAN
        
        #Enter the shared with host lan
		if ($SHARED_WITH_HOST_LAN) {
            Write-Host "- One NIC connected to the shared LAN with the host"
			Write-Host ("em" + $NIC_NUMBER + " connected to shared-with-host LAN.")
            $NIC_NUMBER++
            modify_lan "BSDRP_lab_R$i" $NIC_NUMBER "" ("00bbbb00000" + $i) $true
		} #endif Shared_with_host_lan
    }
}

function Pause ($Message="Press any key to continue...") {
   # The ReadKey functionality is only supported at the console (not is the ISE)
   if (!$psISE) {
       Write-Host -NoNewLine $Message
       $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
       Write-Host ""
   }

}

Function clean_exit () {
	# Cleaning stuff before exiting...
    Pause
	exit
}

#### Main ####

# Settings VirtualBox COM API static variables
set_API_enums

# A powershell script by default is running in mode MTA, but for displaying dialog box, STA mode is needed
if($host.Runspace.ApartmentState -ne "STA") {
    Write-Host "[Dirty Hack] Relaunching PowerShell script in STA mode"
    powershell -NoProfile -Sta -File $MyInvocation.InvocationName
    return
}

#Set window title
$WINDOW = (Get-Host).UI.RawUI
$TITLE = "BSD Router Project - VirtualBox lab"
$WINDOW.WindowTitle = $TITLE

# Stop if can't init the VIRTUALBOX COM API
if (!(init_com_api)) {
    Write-Host "[ERROR] Can't init VirtualBox COM API...exiting"
    clean_exit
}

try { $global:SESSION = New-Object -ComObject VirtualBox.Session }
catch {
    Write-Host "[ERROR] Can't create a SESSION object"
    Write-Host "Detail: " $($error)
    clean_exit
}

#If BSDRP VM template doesn't exist, ask for a filename
Write-Verbose "Looking for allready existing $VM_TPL_NAME machine"
try { $VIRTUALBOX_VM_TEMPLATE=$VIRTUALBOX.findMachine($VM_TPL_NAME) }
catch {
    Write-Host "No BSDRP VM Template found."
    create_template
}

Write-Host "Note: VirtualBox is limited to only 8 NIC by VM"
[int] $MAX_NIC=8

[bool] $SHARED_WITH_HOST_LAN=$false
$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes",""
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No",""
$CHOICES = [System.Management.Automation.Host.ChoiceDescription[]]($yes,$no)
$MESSAGE = "Enabling one LAN between routers and the host ? (Enbale IP access from host to routers)"
$RESULT = $Host.UI.PromptForChoice($TITLE,$MESSAGE,$CHOICES,0)
if($RESULT -eq 0) {
    $SHARED_WITH_HOST_LAN=$true
    $MAX_NIC--
}

do {
    $LAN = (Read-Host "How many other LAN dedicaced to the lab? (between 0 and $MAX_NIC)") -as [int]
} until (($LAN -ne $null) -and ($LAN -ge 0) -and ($LAN -le $MAX_NIC))
$MAX_NIC=$MAX_NIC - $LAN

[int] $MAX_VM=100
[bool] $FULL_MESH=$false
if ($MAX_NIC -gt 0) {
    $MESSAGE = "Enable full mesh links between all routers ?"
    $RESULT = $Host.UI.PromptForChoice($TITLE,$MESSAGE,$CHOICES,0)
    if($RESULT -eq 0) {
        $FULL_MESH=$true
        switch ($MAX_NIC) {
            1 { $MAX_VM=2 } 
            2 { $MAX_VM=2 } 
            3 { $MAX_VM=3 }  
            4 { $MAX_VM=3 }  
            5 { $MAX_VM=3 }  
            6 { $MAX_VM=4 }
            7 { $MAX_VM=4 } 
            8 { $MAX_VM=4 }  
            default { write-host "[BUG] MAX_NIC too high"; clean_exit}
        } # switch
    } # Endif FULL_MESH
    
}# Endif there is still NIC available 
        

do {
    $NUMBER_VM = (Read-Host "How many routers ? (between 2 and $MAX_VM)") -as [int]
} until (($NUMBER_VM -ne $null) -and ($NUMBER_VM -ge 2) -and ($NUMBER_VM -le $MAX_VM))

build_lab $NUMBER_VM $LAN $SHARED_WITH_HOST_LAN $FULL_MESH

clean_exit
