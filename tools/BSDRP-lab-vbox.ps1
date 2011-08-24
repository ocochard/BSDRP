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
            
            ChipsetType_PIIX3 = 1;
            ChipsetType_ICH9 = 2;
            
            NetworkAdapterType_Null = 0;
            NetworkAdapterType_Am79C970A = 1;
            NetworkAdapterType_Am79C973 = 2;
            NetworkAdapterType_I82540EM = 3;
            NetworkAdapterType_I82543GC = 4;
            NetworkAdapterType_I82545EM = 5;
            NetworkAdapterType_Virtio = 6;
            
            NetworkAttachmentType_Null = 0;
            NetworkAttachmentType_NAT = 1;
            NetworkAttachmentType_Bridged = 2;
            NetworkAttachmentType_Internal = 3;
            NetworkAttachmentType_HostOnly = 4;
            NetworkAttachmentType_Generic = 5;
            
            ProcessorFeature_HWVirtEx = 0;
            ProcessorFeature_PAE = 1;
            ProcessorFeature_LongMode = 2;
            ProcessorFeature_NestedPaging = 3;
       
        } #Virtualbox_API_Enums

        $Virtualbox_API_Enums.GetEnumerator() | Foreach-Object {
            Set-Variable $($_.Key) -value $([int32] $_.Value) -option constant -scope Global
        }
    } # endif
} # function set_API_enum

#### Functions definition

# Create the template
Function create_template () {
	param ([string]$FILENAME)
    $error.clear()
    Write-Host "Generate BSDRP Lab Template VM..."
	
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
        Write-Host "[ERROR] " (Get-PSCallStack)[0].Command ": Can't create $VM_TPL_NAME machine"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    #Configure the VM
    
    # Chipset PIIX3 support a maximum of 8 NIC
    # Chipset ICH9 support a maximum of 36 NIC... But it's not working (experimental)
    
    $MACHINE.ChipsetType=$ChipsetType_PIIX3
    $MACHINE.MemorySize=128
    $MACHINE.VRAMSize=8
    $MACHINE.Description="BSD Router Project Template VM"
    $MACHINE.setBootOrder(1,$DeviceType_HardDisk)
    $MACHINE.setBootOrder(2,$DeviceType_Null)
    $MACHINE.setBootOrder(3,$DeviceType_Null)
    $MACHINE.setBootOrder(4,$DeviceType_Null)
	# Serial port
	# Link the VM serial port to a pipe into the host
	# You can connect, from the host, to the serial port of the VM 
	$MACHINE_SERIAL=$MACHINE.getSerialPort(0)
	$MACHINE_SERIAL.path="\\.\pipe\$VM_TPL_NAME"
	$MACHINE_SERIAL.hostMode=$PortMode_HostPipe
	$MACHINE_SERIAL.server=$true
	$MACHINE_SERIAL.enabled=$true   
    
    # Adding a disk controller to the machine
    try { $MACHINE_STORAGECONTROLLER = $MACHINE.addStorageController("SATA Controller",$StorageBus_SATA) }
	catch {
        Write-Host "[ERROR] " (Get-PSCallStack)[0].Command ": Can't Add a Storage Controller to $VM_TPL_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
    }
  
    $MACHINE_STORAGECONTROLLER.portCount=1

    # Save the VM settings
    try { $MACHINE.saveSettings() }
    catch {
        Write-Host "[ERROR] " (Get-PSCallStack)[0].Command ": Can't save $VM_TPL_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    # Need to register the VM (mandatory before attaching disk to it)
    try { $VIRTUALBOX.registerMachine($MACHINE) }
    catch {
        Write-Host "[ERROR] " (Get-PSCallStack)[0].Command ": Can't register $VM_TPL_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    #Convert the BSDRP raw image disk to VDI using VIRTUALBOXManage.exe
    #Still need to use VIRTUALBOXManage because COM API didn't support all features (like converting RAW)
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
    	Write-Host "[ERROR] " (Get-PSCallStack)[0].Command ": RAW to VDI converstion error, no VDI file found"
        clean_exit
    }
    
    # Register the VDI (Mandatory before attaching it to a VM)
    try {
        $MEDIUM=$VIRTUALBOX.openMedium($VDI_FILE,$DeviceType_HardDisk,$AccessMode_ReadWrite,$true)
    } catch {
        Write-Host "[ERROR] " (Get-PSCallStack)[0].Command ": Can't Open/register $VDI_FILE"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    # Compact the VDI (and create a process object)
    try { $PROGRESS=$MEDIUM.compact() }
    catch {
        Write-Host "[ERROR] " (Get-PSCallStack)[0].Command ": Can't Compact the VDI FILE"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    # Wait for end of compacting the VDI...
    try { $PROGRESS.waitForCompletion(-1) }
    catch {
        Write-Host "[ERROR] " (Get-PSCallStack)[0].Command ": Wait for end of VDI compact failed"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    # Need to lock the VM (put it in "mutable" state) before modifying it
    #  === More I'm using VirtualBox, more I love qemu ! ====
    
    try { $MACHINE.lockMachine($SESSION,$LockType_Write) }
    catch {
        Write-Host "[ERROR] " (Get-PSCallStack)[0].Command ": Can't lock $VM_TPL_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    # At last ! Attach the disk to unlocked-copy-object of the VM
    # But need to use the $SESSION.machine and not the $MACHINE object
    try {
        $SESSION.machine.attachDevice("SATA Controller",0,0,$DeviceType_HardDisk,$MEDIUM)
    } catch {
        Write-Host "[ERROR] " (Get-PSCallStack)[0].Command ": Can't attach $DST_VDI_FILE to $VM_TPL_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    # Save new settings
    try { $SESSION.machine.saveSettings() }
    catch {
        Write-Host "[ERROR] " (Get-PSCallStack)[0].Command ": Can't save $VM_TPL_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    # Create a snapshot (will be mandatory for creating linked type clone)
    try { $PROGRESS=$SESSION.console.takeSnapshot("SNAPSHOT","Initial snapshot used for clone") }
    catch {
        Write-Host "[ERROR] " (Get-PSCallStack)[0].Command ": Can't create a snapshot for $VM_TPL_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    # Wait for end of taking the snapshot...
    try { $PROGRESS.waitForCompletion(-1) }
    catch {
        Write-Host "[ERROR] " (Get-PSCallStack)[0].Command ": Wait for end of snapshot failed"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    # Unlock the machine
    try { $SESSION.unlockMachine() }
    catch {
        Write-Host "[ERROR] " (Get-PSCallStack)[0].Command ": Can't unlock $VM_TPL_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
} # End function create_template

# Parse the BSDRP filename given (is a i386 or amd64, is a vga or serial)
# Modify the global variable:VM_ARCH and CONSOLE
# TO DO: return the results in place of using global variables
Function parse_filename () {
	param ([string]$FILENAME)
    Write-Host "Parsing filename given for guesing ARCH and CONSOLE values:"
    if ($FILENAME.Contains("_amd64")) {
        $global:VM_ARCH="FreeBSD_64"
        Write-Host "- ARCH: x86-64"
        if (!($VIRTUALBOX.Host.getProcessorFeature($ProcessorFeature_HWVirtEx))) {
            write-host "[ERROR] : Your processor didn't support 64bit OS"
            clean_exit
        }
    } elseif ($FILENAME.Contains("_i386")) {
        $global:VM_ARCH="FreeBSD"
        Write-Host "- ARCH: i386"
    } else {
        Write-Host "[ERROR] " (Get-PSCallStack)[0].Command ": parse_filename(): Can't guests arch of this image"
        clean_exit
    }
    if ($FILENAME.Contains("_serial")) {
        $global:SERIAL=$true
        Write-Host "- CONSOLE: serial" 
    } elseif ($FILENAME.Contains("_vga")) {
        $global:SERIAL=$false
        Write-Host "- CONSOLE: vga"
    } else {
        Write-Host "[ERROR] " (Get-PSCallStack)[0].Command ":  Can't guests arch of this image"
        clean_exit
    }
	return $true
} # End function parse_filename

# Clone a new VM based on the base BSDRP VDI
#  first parameter: Name of the cloned machine
#  second parametre: ostype (VM_ARCH)
Function clone_vm () {
    param ([int]$CLONE_ID,[string]$OS_TYPE)
	$CLONE_NAME="BSDRP_lab_R"+ $CLONE_ID
	try {$MACHINE_TEMPLATE=$VIRTUALBOX.findMachine($VM_TPL_NAME)}
	catch {
		Write-Host "[BUG] " (Get-PSCallStack)[0].Command ": clone_vm didn't found $VM_TPL_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
	}
    $error.clear()
    
    # Get the first snapshot of this machine:
    
    try {$MACHINE_TEMPLATE_SNAPSHOT=$MACHINE_TEMPLATE.findSnapshot($null) }
    catch {
		Write-Host "[BUG] " (Get-PSCallStack)[0].Command ": clone_vm didn't found the snapshot of $VM_TPL_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
	}
    
	$error.clear()
	try {$MACHINE_CLONE=$VIRTUALBOX.createMachine("",$CLONE_NAME,$OS_TYPE,"",$false)}
    catch {
        Write-Host "[ERROR] " (Get-PSCallStack)[0].Command ": Can't create $CLONE_NAME clone"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    # MACHINE.cloneTo need:
    #   To be start from a SNAPSHOT object
    #   an array for CloneOptions
	[Int[]] $CloneOptions=@($CloneOptions_Link)
	try {$PROGRESS=$MACHINE_TEMPLATE_SNAPSHOT.machine.cloneTo($MACHINE_CLONE,$CloneMode_MachineState,$CloneOptions) }
	catch {
		Write-Host "[ERROR] " (Get-PSCallStack)[0].Command ": Can't create $CLONE_NAME machine"
        Write-Host "Detail: " $($error)
        clean_exit
	}
	
	 # Wait for end of clonning the VM...
    try { $PROGRESS.waitForCompletion(-1) }
    catch {
        Write-Host "[ERROR] " (Get-PSCallStack)[0].Command ": Wait for end of clonning $CLONE_NAME process failed"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    # Change machine description
    $MACHINE_CLONE.Description="BSD Router Project, Lab router $CLONE_NAME"
    
    # Change the serial PIPE NAME
    $MACHINE_CLONE_SERIAL=$MACHINE_CLONE.getSerialPort(0)
	$MACHINE_CLONE_SERIAL.path="\\.\pipe\$CLONE_NAME"
    
    # Enable remote desktop
    $MACHINE_VRDE=$MACHINE_CLONE.VRDEServer
    $MACHINE_VRDE.enabled=$true
    $MACHINE_VRDE.setVRDEProperty("TCP/Ports","505" + $CLONE_ID)
    
     # Save the VM settings
    try { $MACHINE_CLONE.saveSettings() }
    catch {
        Write-Host "[ERROR] " (Get-PSCallStack)[0].Command ": Can't save $CLONE_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    # Need to register the clone
    try { $VIRTUALBOX.registerMachine($MACHINE_CLONE) }
    catch {
        Write-Host "[ERROR] " (Get-PSCallStack)[0].Command ": Can't register $CLONE_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
} # End function clone_vm

# Delete all LAN interfaces configurations
# parameter: [string], VM name
Function delete_all_nic () {
    param([string]$VM_NAME)
    $MAX_NIC=$VIRTUALBOX.SystemProperties.getMaxNetworkAdapters($ChipsetType_PIIX3)
    
    try {$MACHINE=$VIRTUALBOX.findMachine($VM_NAME)}
	catch {
		Write-Host "[BUG] " (Get-PSCallStack)[0].Command ": Didn't found $VM_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
	}
    # Lock the MACHINE for modifying it
    try { $MACHINE.lockMachine($SESSION,$LockType_Write) }
    catch {
        Write-Host "[ERROR] " (Get-PSCallStack)[0].Command ": Can't lock $VM_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    # Loop for 0 to MAX-1, if interface configured, clean it
    for ($i=1;$i -le $MAX_NIC;$i++) {
        $ADAPTER=$SESSION.machine.getNetworkAdapter([int]($i-1))
        $ADAPTER.attachmentType=$NetworkAttachmentType_Null
        $ADAPTER.enabled=$false
    } #End for loop, MAX_NIC
    
    # Save new settings
    try { $SESSION.machine.saveSettings() }
    catch {
        Write-Host "[ERROR] " (Get-PSCallStack)[0].Command ": Can't save $VM_TPL_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    # Unlock the machine
    try { $SESSION.unlockMachine() }
    catch {
        Write-Host "[ERROR] " (Get-PSCallStack)[0].Command ": Can't unlock $VM_TPL_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
    }  
} #End Function delete_all_nic

# Modify VM NIC
# First parameter: (string), VM name
# Second parameter: (int), NIC number 
# Third parameter: (string), LAN name
# Forth parameter: (string), MAC address to use
# Fifth parameter: (bool), set true for Host Only NIC
Function modify_nic () {
    param ([string]$VM_NAME,[int]$NIC,[string]$LAN,[string]$MAC,[bool]$HOST_ONLY=$false)
    
    # Open the MACHINE object
    try {$MACHINE=$VIRTUALBOX.findMachine($VM_NAME)}
	catch {
		Write-Host "[BUG] " (Get-PSCallStack)[0].Command ": Didn't found $VM_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
	}
    # Lock the MACHINE for modifying it
   try { $MACHINE.lockMachine($SESSION,$LockType_Write) }
    catch {
        Write-Host "[ERROR] " (Get-PSCallStack)[0].Command ": Can't lock $VM_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    # Virtualbox begin to count NIC starting at zero, need to substract 1 to the NIC value
    #Need to open the machine, and the session
    $ADAPTER=$SESSION.machine.getNetworkAdapter($NIC-1)
    $ADAPTER.adapterType=$NetworkAdapterType_I82540EM
    $ADAPTER.MACAddress=$MAC
    
    if ($HOST_ONLY) { 
        $ADAPTER.attachmentType=$NetworkAttachmentType_HostOnly
        $ADAPTER.hostOnlyInterface="VirtualBox Host-Only Ethernet Adapter"
    } else {
        $ADAPTER.attachmentType=$NetworkAttachmentType_Internal
        $ADAPTER.internalNetwork=$LAN
    }
        
    $ADAPTER.enabled=$true
    
    # Save new settings
    try { $SESSION.machine.saveSettings() }
    catch {
        Write-Host "[ERROR] " (Get-PSCallStack)[0].Command ": Can't save $VM_TPL_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
    # Unlock the machine
    try { $SESSION.unlockMachine() }
    catch {
        Write-Host "[ERROR] " (Get-PSCallStack)[0].Command ":Can't unlock $VM_TPL_NAME"
        Write-Host "Detail: " $($error)
        clean_exit
    }
    
} # End function modify_nic       
                        
# Build the lab: Clone and Configure all VMs
# First parameter: (int), number of VM to clone/start
# Second parameter: (int), number of LAN 
# Third parameter: (bool), Shared with host LAN
# Forth parameter: (bool), Full Mesh link
Function build_lab () {
    param ([int]$NUMBER_VM,[int]$LAN,[bool]$SHARED_WITH_HOST_LAN,[bool]$FULL_MESH)
    Write-Host "Setting-up a lab with $NUMBER_VM routers"
    if ($SHARED_WITH_HOST_LAN) {
        Write-Host "- All routers and the host will be connected to a shared LAN"
    }
    if ($LAN -gt 0) {
        Write-Host "- All routers will be connected to $LAN dedicaced LAN"
    }
    if ($FULL_MESH) {
        Write-Host "- Full mesh ethernet point-to-point link between each routers"
    }
    
    if (!($VM_ARCH)) {
        $VM_ARCH=
        try {$MACHINE_TEMPLATE=$VIRTUALBOX.findMachine($VM_TPL_NAME)}
    	catch {
    		Write-Host "[BUG] " (Get-PSCallStack)[0].Command ": build lab didn't found $VM_TPL_NAME"
            Write-Host "Detail: " $($error)
            clean_exit
    	}
        $VM_ARCH=$MACHINE_TEMPLATE.OSTypeId
    }
    
    #Enter the main loop for each VM
    for ($i=1;$i -le $NUMBER_VM;$i++) {
		try { $MACHINE_CLONE=$VIRTUALBOX.findMachine("BSDRP_lab_R$i") }
        catch {
			clone_vm $i $VM_ARCH
			$MACHINE_CLONE=$VIRTUALBOX.findMachine("BSDRP_lab_R$i")
		}
		
        # Delete all NIC on this VM
        delete_all_nic "BSDRP_lab_R$i"
        
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
                        modify_nic "BSDRP_lab_R$i" $NIC_NUMBER ("$i" + "$j") ("AAAA00000" + $i + $i + $j)
                    } else {
                        modify_nic "BSDRP_lab_R$i" $NIC_NUMBER ("$j" + "$i") ("AAAA00000" + $i + $j + $i)
                    }
                } # endif avoiding himself in compute
                $j++ 
            } # end of while NUMBER_VM
        } #endif of FULL_MESH
        
        #Enter in the LAN NIC loop
        $j=1
        while ($j -le $LAN) {
            Write-Host ("em" + $NIC_NUMBER + " connected to dedicated LAN number " + $j)
            $NIC_NUMBER++
            modify_nic "BSDRP_lab_R$i" $NIC_NUMBER ("10" + $j) ("CCCC00000" + $j + "0" + $i)
            $j++
        } #end of while LAN
        
        #Enter the shared with host lan
		if ($SHARED_WITH_HOST_LAN) {
			Write-Host ("em" + $NIC_NUMBER + " connected to the shared-with-host LAN.")
            $NIC_NUMBER++
            modify_nic "BSDRP_lab_R$i" $NIC_NUMBER "" ("00bbbb00000" + $i) $true
		} #endif Shared_with_host_lan
    }
} # End Function build_lab

Function Pause ($Message="Press any key to continue...") {
   # The ReadKey functionality is only supported at the console (not is the ISE)
   if (!$psISE) {
       Write-Host -NoNewLine $Message
       $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
       Write-Host ""
   }

} # End function Pause

Function clean_exit () {
	# Cleaning stuff before exiting...
	[void] [System.Runtime.Interopservices.Marshal]::ReleaseComObject($SESSION)
    [void] [System.Runtime.Interopservices.Marshal]::ReleaseComObject($VIRTUALBOX)
    Pause
	exit
} # End Function clean_exit


Function start_lab () {
    # Start all labs
    param ([int]$NUMBER_VM)
    for ($i=1;$i -le $NUMBER_VM;$i++) {
        # Open the MACHINE object
        try {$MACHINE=$VIRTUALBOX.findMachine("BSDRP_lab_R$i")}
    	catch {
    		Write-Host "[BUG] " (Get-PSCallStack)[0].Command ": Didn't found BSDRP_lab_R$i"
            Write-Host "Detail: " $($error)
            clean_exit
    	}
               
        # Start the VM
        try { $PROGRESS=$MACHINE.launchVMProcess($SESSION,"headless","") }
        catch {
            Write-Host "[ERROR] " (Get-PSCallStack)[0].Command ": Can't start BSDRP_lab_R$i"
            Write-Host "Detail: " $($error)
            clean_exit
        }
       
        # Wait for launching process of the VM
        try { $PROGRESS.waitForCompletion(-1) }
        catch {
            Write-Host "[ERROR] " (Get-PSCallStack)[0].Command ": Wait for endstart BSDRP_lab_R$i"
            Write-Host "Detail: " $($error)
            clean_exit
        }
        
         # Unlock the machine
        try { $SESSION.unlockMachine() }
        catch {
            Write-Host "[ERROR] " (Get-PSCallStack)[0].Command ": Can't unlock BSDRP_lab_R$i"
            Write-Host "Detail: " $($error)
            clean_exit
        }
    } # Endfor
    Write-Host "All routers started, connect to them using:"
    Write-Host " - For BSDRP vga release, with mstsc (included in MS Windows): "
    write-host "     mstsc /v:127.0.0.1:505x (replacing x by router number)"
    write-host " - For BSDRP serial and vga release: Configure PuTTY to connect to:"
    write-host "     connection type: Serial"
    write-host "     serial line: \\.\pipe\BSDRP_lab_Rx (replacing x by router number)"
    #write-host "     baud : 115200"
}

#### Main ####

# Settings VirtualBox COM API static variables
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
# Initialize VirtualBox COM Object

Write-Verbose "Initializing VirtualBox COM API...";
try { $global:VIRTUALBOX = New-Object -ComObject VirtualBox.VirtualBox }
catch {
    Write-Host "[ERROR] " (Get-PSCallStack)[0].Command ": Can't init VirtualBox COM API...exiting"
    clean_exit
}

# Create the SESSION object too
try { $global:SESSION = New-Object -ComObject VirtualBox.Session }
catch {
    Write-Host "[ERROR] " (Get-PSCallStack)[0].Command ": Can't create a SESSION object"
    Write-Host "Detail: " $($error)
    clean_exit
}

#If BSDRP VM template doesn't exist, ask for a filename to user
Write-Verbose "Looking for allready existing $VM_TPL_NAME machine"
try { $VIRTUALBOX_VM_TEMPLATE=$VIRTUALBOX.findMachine($VM_TPL_NAME) }
catch {
    Write-Host "No BSDRP VM Template found."
	# Ask the user for BSDR full-image
    $FileForm = New-Object System.Windows.Forms.OpenFileDialog
    $FileForm.InitialDirectory = "."
    $FileForm.Filter = "BSDRP image Files (*.img)|*.img"
    $FileForm.Title = "Select BSDRP full image disk"
    $Show = $FileForm.ShowDialog()
    If ($Show -eq "OK") {
    	$FILENAME=$FileForm.FileName
    } Else {
    	Write-Error "Operation cancelled"
        clean_exit
    }
    Write-Host "No BSDRP VM Template found."
    create_template $FILENAME 
}

# Incomplete support of ICH9 chipset: Can't create more than 8 NIC (but report 36)
[int] $MAX_NIC=$VIRTUALBOX.SystemProperties.getMaxNetworkAdapters($ChipsetType_PIIX3)

[bool] $SHARED_WITH_HOST_LAN=$false
$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes",""
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No",""
$CHOICES = [System.Management.Automation.Host.ChoiceDescription[]]($yes,$no)
$MESSAGE = "Enabling one LAN between routers and the host ? (Permit IP access between host and routers)"
$RESULT = $Host.UI.PromptForChoice($TITLE,$MESSAGE,$CHOICES,0)
if($RESULT -eq 0) {
    $SHARED_WITH_HOST_LAN=$true
    $MAX_NIC--
}

do {
    $LAN = (Read-Host "How many other LAN dedicaced to the lab? (between 0 and $MAX_NIC)") -as [int]
} until (($LAN -ne $null) -and ($LAN -ge 0) -and ($LAN -le $MAX_NIC))
$MAX_NIC=$MAX_NIC - $LAN

[int] $MAX_VM=20
[bool] $FULL_MESH=$false
if ($MAX_NIC -gt 0) {
    $MESSAGE = "Enable full mesh links between all routers ?"
    $RESULT = $Host.UI.PromptForChoice($TITLE,$MESSAGE,$CHOICES,0)
    if($RESULT -eq 0) {
        $FULL_MESH=$true
        $MAX_VM=$MAX_NIC + 1
    } # Endif FULL_MESH
    
}# Endif there is still NIC available 

do {
    $NUMBER_VM = (Read-Host "How many routers ? (between 2 and $MAX_VM)") -as [int]
} until (($NUMBER_VM -ne $null) -and ($NUMBER_VM -ge 2) -and ($NUMBER_VM -le $MAX_VM))

build_lab $NUMBER_VM $LAN $SHARED_WITH_HOST_LAN $FULL_MESH

start_lab $NUMBER_VM

clean_exit
