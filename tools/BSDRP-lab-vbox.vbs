' VirtualBox lab VBscript for BSD Router Project
'
' Copyright (c) 2010-2013, The BSDRP Development Team
' All rights reserved.
'
' Redistribution and use in source and binary forms, with or without
' modification, are permitted provided that the following conditions
' are met:
' 1. Redistributions of source code must retain the above copyright
'    notice, this list of conditions and the following disclaimer.
' 2. Redistributions in binary form must reproduce the above copyright
'    notice, this list of conditions and the following disclaimer in the
'    documentation and/or other materials provided with the distribution.
'
' THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS:::: AND
' ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
' IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
' ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
' FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
' DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
' OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
' HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
' LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
' OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
' SUCH DAMAGE.
'

'Force declaration of variables before use
Option Explicit

Main()

Public VB_EXE, VB_HEADLESS, WORKING_DIR, BSDRP_VDI, TEXT, RELEASE, VM_ARCH, VM_CONSOLE, BSDRP_FILENAME, RETURN_CODE, NUMBER_VM, NUMBER_LAN, SHARED_LAN

Sub Main()
	' Variables used
	Dim WshShell, WshProcessEnv
	
    ' Get environmeent Variables
	Set WshShell = WScript.CreateObject("WScript.Shell")
	Set WshProcessEnv = WshShell.Environment("Process")
	'WScript.Echo "ProgramFiles = " & WshProcessEnv("ProgramFiles")
	
	' Define variables
    VB_EXE = WshProcessEnv("VBOX_INSTALL_PATH") & "VBoxManage.exe"
	VB_HEADLESS = WshProcessEnv("VBOX_INSTALL_PATH") & "VBoxHeadless.exe"
	WORKING_DIR = WshProcessEnv("USERPROFILE") & "\.VirtualBox"
	
	Set WshShell = Nothing
	
    RELEASE = "BSD Router Project: VirtualBox lab VBscript"

    VB_EXE=check_VB_EXE(VB_EXE)  
	VB_HEADLESS=check_VB_HEADLESS(VB_HEADLESS)
	BSDRP_VDI=check_existing_VDI()
	
	Do
		NUMBER_VM = InputBox( "How many routers do you want to use ? (between 2 and 9)",RELEASE)
		if NUMBER_VM = "" Then
			WScript.Quit
		End If
	Loop While ((NUMBER_VM < 2) OR (NUMBER_VM > 9))
	
	Do
		NUMBER_LAN = InputBox( "How many shared LAN between your routers do you want ? (between 0 and 4)",RELEASE)
		if NUMBER_LAN = "" Then
			WScript.Quit
		End If
	Loop While ((NUMBER_LAN < 0) OR (NUMBER_LAN > 4))
	
	SHARED_LAN = MsgBox("Do you want a shared LAN between your routers and the host ? (Usefull for IP access to the routers from your host, can be used as shared LAN between routers too)", vbYesNoCancel, RELEASE)
	' SHARED_LAN should contain vbYES or vbNO, if empty "", mean that it's cancelled
	if SHARED_LAN = vbCancel Then
		WScript.Quit
    End If
	
    clone_vm()
	
    start_vm()
	
	call MsgBox (TEXT,vbOk,RELEASE)
   
End Sub

Function check_existing_VDI()
	
	dim fso, InitFSO, FILENAME
	
	Set fso = CreateObject("Scripting.FileSystemObject") 
	
	FILENAME= WORKING_DIR & "\BSDRP_FreeBSD_64_vga.vdi" 
	
    If (fso.FileExists(FILENAME)) Then
		VM_ARCH="FreeBSD_64"
		VM_CONSOLE="vga"
		check_existing_VDI=Chr(34) & FILENAME & Chr(34)
		Exit Function
	End if 
	
	FILENAME=WORKING_DIR & "\BSDRP_FreeBSD_vga.vdi"
	
    If (fso.FileExists(FILENAME)) Then
		VM_ARCH="FreeBSD"
		VM_CONSOLE="vga"
		check_existing_VDI=Chr(34) & FILENAME & Chr(34)
		Exit Function
	End if 
    
    FILENAME=WORKING_DIR & "\BSDRP_FreeBSD_64_serial.vdi"
	
    If (fso.FileExists(FILENAME)) Then
		VM_ARCH="FreeBSD_64"
		VM_CONSOLE="serial"
		check_existing_VDI=Chr(34) & FILENAME & Chr(34)
		Exit Function
	End if
	
	FILENAME=WORKING_DIR & "\BSDRP_FreeBSD_serial.vdi"
	
    If (fso.FileExists(FILENAME)) Then
		VM_ARCH="FreeBSD"
		VM_CONSOLE="serial"
		check_existing_VDI=Chr(34) & FILENAME & Chr(34)
		Exit Function
	End if 
    
    TEXT = "Please select a unzipped and unrenamed BSDRP image file" & vbCrLf & vbCrLf
    RETURN_CODE = MsgBox (TEXT,vbOkCancel,RELEASE)
    If RETURN_CODE = 2 Then
        wscript.quit
    End If

	set fso = Nothing
	
    ' Ask user for the BSDRP image file
   
	Set fso = CreateObject("UserAccounts.CommonDialog") 
	fso.Filter = "All BSDRP images file (*.img)|*.img|"
	InitFSO = fso.ShowOpen

	If InitFSO = False Then
		Wscript.Echo "Script Error: Please select a file!"
        Wscript.Quit
    End If
    
	FILENAME=fso.FileName
	
	set fso = Nothing
	
	' Getting ARCH and Console type for
	
	VM_ARCH=image_arch_detect(FILENAME)
	VM_CONSOLE=image_console_detect(FILENAME)
	
	convert_image_to_vdi(FILENAME)
	
	check_existing_VDI= Chr(34) & WORKING_DIR & "\BSDRP_" & VM_ARCH & "_" & VM_CONSOLE & ".vdi" & Chr(34)
	
End Function

Function check_VB_EXE(ByVal VB_EXE)
	dim fso, ObjFSO, InitFSO
	
    Set fso = CreateObject("Scripting.FileSystemObject")
   
    If Not (fso.FileExists(VB_EXE)) Then
        TEXT = "Can't found VirtualBox in " & vbCrLf & VB_EXE & vbCrLf
        TEXT = TEXT & "Please, select the VBoxManage.exe location" & vbCrLf
        MsgBox  TEXT,vbCritical,"Error"
        
        Set ObjFSO = CreateObject("UserAccounts.CommonDialog") 
        InitFSO = ObjFSO.ShowOpen

       If InitFSO = False Then
            Wscript.Echo "Script Error: Please select a file!"
            Wscript.Quit
        Else
            check_VB_EXE=Chr(34) & ObjFSO.FileName & Chr(34)
        End If
    else
        check_VB_EXE=Chr(34) & VB_EXE & Chr(34)
    end if
	
	set fso = Nothing
   
End Function

Function check_VB_HEADLESS(ByVal VB_EXE)
	dim fso, ObjFSO, InitFSO
	
    Set fso = CreateObject("Scripting.FileSystemObject")
   
    If Not (fso.FileExists(VB_EXE)) Then
        TEXT = "Can't found VirtualBox in " & vbCrLf & VB_EXE & vbCrLf
        TEXT = TEXT & "Please, select the VBoxHeadless.exe location" & vbCrLf
        MsgBox  TEXT,vbCritical,"Error"
        
        Set ObjFSO = CreateObject("UserAccounts.CommonDialog") 
        InitFSO = ObjFSO.ShowOpen

       If InitFSO = False Then
            Wscript.Echo "Script Error: Please select a file!"
            Wscript.Quit
        Else
            check_VB_HEADLESS=Chr(34) & ObjFSO.FileName & Chr(34)
        End If
    else
        check_VB_HEADLESS=Chr(34) & VB_EXE & Chr(34)
    end if
	
	set fso = Nothing
   
End Function

Function image_arch_detect(ByVal BSDRP_FileName)
	if InStr(BSDRP_FileName, "amd64") then
		image_arch_detect="FreeBSD_64"
		Exit Function
	end if
	
	if InStr(BSDRP_FileName, "i386") then
		image_arch_detect="FreeBSD"
		Exit Function
	end if
	
	MsgBox  "Can't guests arch of this image: BSDRP file renamed ?",vbCritical,"Error"
	Wscript.Quit
   
End Function

Function image_console_detect(ByVal BSDRP_FileName)
	if InStr(BSDRP_FileName, "serial") then
		image_console_detect="serial"
		Exit Function
	end if
	
	if InStr(BSDRP_FileName, "vga") then
		image_console_detect="vga"
		Exit Function
	end if
	
	MsgBox  "Can't guests console of this image: BSDRP file renamed ?",vbCritical,"Error"
	Wscript.Quit
   
End Function

Function convert_image_to_vdi (ByVal BSDRP_FileName)
	dim fso, CMD, FILE
	Set fso = CreateObject("Scripting.FileSystemObject")
	FILE=WORKING_DIR & "\BSDRP_lab.vdi"
	'If (fso.FileExists(FILE)) Then
	'		CMD=VB_EXE & " closemedium disk " & Chr(34) & WORKING_DIR & "\BSDRP_lab.vdi" & Chr(34) & " --delete"
	'		call run (CMD,true)
	'		' fso.DeleteFile(FILE)
    'end if
	
	set fso = Nothing 
	
	' Convert the IMG file into a VDI file
	
	CMD=VB_EXE & " convertfromraw " & Chr(34) & BSDRP_FileName & Chr(34) & " " & Chr(34) & WORKING_DIR & "\BSDRP_" & VM_ARCH & "_" & VM_CONSOLE & ".vdi" & Chr(34)
	
	call run (CMD,true)

End Function

Function run(ByVal CMD, ByVal MANAGE_ERROR)
' This function run the command CMD, and wait the execution before continue
' if MANAGE_ERROR is true, then this command manage error (display error and exit)
' if RETURNVAL is false, then this command silenty return RETURN_CODE

	Dim shell, ERRTEXT

    Set shell = CreateObject("WScript.Shell")
	'Wscript.Echo "DEBUG:" &  CMD
	Run = Shell.Run(CMD,2,True)
	if MANAGE_ERROR then
		if Run > 0 then
			ERRTEXT = "Error with this command" & vbCrLf & CMD & vbCrLf
			MsgBox  ERRTEXT,vbCritical,"Error"
			wscript.quit
		end If
	else
		Set shell = Nothing
	End if
	
End Function

Function run_bg(ByVal CMD)
' This function run the command CMD in background
	Dim Shell
    Set Shell = CreateObject("WScript.Shell")
	run_bg = Shell.Run(CMD,2,False)
End Function

'This function check if the given VM exist
Function check_vm(ByVal VM_NAME)
	Dim CMD
	CMD=VB_EXE & " showvminfo " & VM_NAME
	check_vm=run(CMD,false)
End Function

Function delete_vm(ByVal VM_NAME)
	Dim CMD	
	CMD=VB_EXE & " storagectl " & VM_NAME & " --name " & Chr(34) & "SATA Controller" & Chr(34) & " --remove"
	delete_vm=run(CMD,false)
	CMD=VB_EXE & " unregistervm " & VM_NAME & " --delete"
	delete_vm=delete_vm + run(CMD,false)
End Function

' This function generate the clones
Function clone_vm ()
	Dim i,j,NIC_NUMBER,ERRTEXT,CMD
    TEXT = "Creating lab with " & NUMBER_VM & " routers:" & vbCrLf
    TEXT = TEXT & "- " & NUMBER_LAN & " LAN between all routers" & vbCrLf
    TEXT = TEXT &  "- Full mesh ethernet point-to-point link between each routers" & vbCrLf & vbCrLf
    'Enter the main loop for each VM
	For i = 1 To NUMBER_VM
        create_vm ("BSDRP_lab_R" & i)
        NIC_NUMBER=0
        TEXT = TEXT & "Router" & i & " have the folllowing NIC:" & vbCrLf
		'First step: Shared with host NIC
		if SHARED_LAN = vbYES Then
			TEXT = TEXT & "- em" & NIC_NUMBER & " connected to Host" & vbCrLf
                NIC_NUMBER=NIC_NUMBER + 1
				CMD=VB_EXE & " modifyvm BSDRP_lab_R" & i & " --nic" & NIC_NUMBER & " hostonly --nictype" & NIC_NUMBER & " 82540EM " & " --hostonlyadapter1 ""VirtualBox Host-Only Ethernet Adapter"" --macaddress" & NIC_NUMBER & " 00AA0000000" & i 
					call run(CMD,true)
		End if
		
        'Enter in the Cross-over (Point-to-Point) NIC loop
        'Now generate X x (X-1)/2 full meshed link
		For j = 1 to NUMBER_VM
			'Wscript.Echo "[DEBUG] Inside Loop for VM" & i & "/" & NUMBER_VM & " interface full mesh number " & j
            if i <> j then
                TEXT = TEXT & "- em" & NIC_NUMBER & " connected to Router" & j & vbCrLf
                NIC_NUMBER=NIC_NUMBER + 1
				if i <= j then
					CMD=VB_EXE & " modifyvm BSDRP_lab_R" & i & " --nic" & NIC_NUMBER & " intnet --nictype" & NIC_NUMBER & " 82540EM --intnet" & NIC_NUMBER & "  LAN" & i & j & " --macaddress" & NIC_NUMBER & " AAAA00000" & i & i & j
					call run(CMD,true)
                else
					CMD=VB_EXE & " modifyvm BSDRP_lab_R" & i & " --nic" & NIC_NUMBER & " intnet --nictype" & NIC_NUMBER & " 82540EM --intnet" & NIC_NUMBER & "  LAN" & j & i & " --macaddress" & NIC_NUMBER & " AAAA00000" & i & j & i
					call run(CMD,true)
                End if
            End if
		Next
        'Enter in the LAN NIC loop
		for j = 1 to NUMBER_LAN
            TEXT = TEXT & "- em" & NIC_NUMBER & " connected to LAN number " & j & vbCrLf
            NIC_NUMBER=NIC_NUMBER + 1
			CMD=VB_EXE & " modifyvm BSDRP_lab_R" & i & " --nic" & NIC_NUMBER & " intnet --nictype" & NIC_NUMBER & " 82540EM --intnet" & NIC_NUMBER & "  LAN10" & j & " --macaddress" & NIC_NUMBER & " CCCC00000" & j & "0" & i
			call run(CMD,true)			
		Next
		TEXT = TEXT & vbCrLf
    Next
End Function

Function create_vm (ByVal VM_NAME)
	dim ERRTEXT, fso, WshShell,CMD,i
    ' Check if the vm allready exist
    if check_vm (VM_NAME) > 0 then		
		
		' Create the VM
		CMD=VB_EXE & " createvm --name " & VM_NAME & " --ostype " & VM_ARCH & " --register"
		call run(CMD,true)
		
		' Clone the Template vdi
		CMD=VB_EXE & " clonehd " & BSDRP_VDI & " " & VM_NAME & ".vdi"
		
		call run(CMD,true)
		
		' Add SATA controller to the VM
		CMD=VB_EXE & " storagectl " & VM_NAME & " --name " & Chr(34) & "SATA Controller" & Chr(34) & " --add sata --controller IntelAhci"
		call run(CMD,true)
		
    	' Add the controller and disk to the VM...
		CMD=VB_EXE & " storageattach " & VM_NAME & " --storagectl " & Chr(34) & "SATA Controller" & Chr(34) & " --port 0 --device 0 --type hdd --medium " & VM_NAME & ".vdi" 
		call run(CMD,true)
		
    	'echo "Set the UUID of this disk..." >> ${LOG_FILE}
    	'VBoxManage internalcommands sethduuid $1.vdi >> ${LOG_FILE} 2>&1
    else
        ' if existing: Is running ?
		
		CMD=VB_EXE & " controlvm " & VM_NAME & " poweroff" 
		call run(CMD,false)
		
		' Sleep is not simple in VBS :-)
		set fso = CreateObject("Scripting.FileSystemObject")
		Set WshShell = WScript.CreateObject("WScript.Shell")
        WScript.Sleep 5
		
		'Delete all NIC configured on existing VM !
		'It seems that VBox under Windows didn't support more than 9 NIC on a VM
		for i = 1 to 9
			CMD=VB_EXE & " modifyvm " & VM_NAME & " --nic" & i & " none"
			call run(CMD,false)
		next
		
    End if
	
	CMD=VB_EXE & " modifyvm " & VM_NAME & " --audio none --memory 256 --vram 9 --boot1 disk --floppy disabled --biosbootmenu disabled"
	call run(CMD,true)

    if VM_CONSOLE="serial" then
		CMD=VB_EXE & " modifyvm " & VM_NAME & " --uart1 0x3F8 4 --uartmode1 server " & "\\.\pipe\" & VM_NAME
		call run(CMD,true)
    End if

End Function

'Start each vm
Sub start_vm ()
    dim i,CMD
    'Enter the main loop for each VM
	for i=1 to NUMBER_VM
		if VM_CONSOLE="vga" then
			CMD = VB_HEADLESS & " -vrdp on --vrdpport 339" & i & " --startvm " & "BSDRP_lab_R" & i & vbCrLf
			TEXT = TEXT & "Connect to the router " & i & " by an RDP client on port 339" & i & vbCrLf
		else
			CMD = VB_HEADLESS & " -vrdp off --startvm " & "BSDRP_lab_R" & i
			TEXT = TEXT & "Connect to the router " & i & " with Putty configured as:" & vbCrLf
			TEXT = TEXT & "-Con type: serial, baud: 115200, serial line:" & "\\.\pipe\" & "BSDRP_lab_R" & i & vbCrLf
		End if
		call run_bg(CMD)
    next
End Sub
