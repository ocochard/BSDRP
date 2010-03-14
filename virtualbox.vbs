' VirtualBox lab VBscript for BSD Router Project
'
' Copyright (c) 2010, The BSDRP Development Team
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

' Force declaration of variables before use
Option Explicit

Main()

Public VB_EXE, WORKING_DIR, TEXT, RELEASE, VM_ARCH, VM_CONSOLE, BSDRP_FILENAME, RETURN_CODE, NUMBER_VM, NUMBER_LAN

Sub Main()
	' Variables used
	Dim WshShell, WshProcessEnv, fso,InitFSO
	
    ' Get environmeent Variables
	Set WshShell = WScript.CreateObject("WScript.Shell")
	Set WshProcessEnv = WshShell.Environment("Process")
	'WScript.Echo "ProgramFiles = " & WshProcessEnv("ProgramFiles")
	
	' Define variables
    VB_EXE = WshProcessEnv("VBOX_INSTALL_PATH") & "VBoxManage.exe"
	WORKING_DIR = WshProcessEnv("USERPROFILE") & "\.VirtualBox"
	
	Set WshShell = Nothing
	
    RELEASE = "BSD Router Project: VirtualBox lab VBscript"

    VB_EXE=check_VB(VB_EXE)
    
    'Wscript.Echo "DEBUG, You are using the VB in : " & VB_EXE
    
	' TO DO: selecting image is only usefull if no previous base VM exist !
	
    TEXT = "Please select a unzipped BSDRP image file" & vbCrLf & vbCrLf
    RETURN_CODE = MsgBox (TEXT,vbOkCancel,RELEASE)
    If RETURN_CODE = 2 Then
        wscript.quit
    End If

    ' Ask for the BSDRP image file
   
   Set fso = CreateObject("UserAccounts.CommonDialog") 
   fso.Filter = "All BSDRP images file (*.img)|*.img|"
   InitFSO = fso.ShowOpen

   If InitFSO = False Then
        Wscript.Echo "Script Error: Please select a file!"
        Wscript.Quit
    End If
    
	BSDRP_FILENAME=Chr(34) & fso.FileName & Chr(34)
	
	set fso = Nothing
	
    'Wscript.Echo "DEBUG: You selected the file: " & ObjFSO.FileName
	
	VM_ARCH=image_arch(BSDRP_FILENAME)
	VM_CONSOLE=image_console(BSDRP_FILENAME)
	
	'Wscript.Echo "DEBUG: ARCH is " & VM_ARCH & " CONSOLE is " & VM_CONSOLE
	
	NUMBER_VM = InputBox( "How many routers do you want to use ? (between 2 and 9)" )

	if NUMBER_VM < 2 then
		Wscript.Echo "Warning, incorrect user input: Will use 2 routers"
	end if
	
	if NUMBER_VM > 9 then
		Wscript.Echo "Warning, incorrect user input: Will use 9 routers"
	end if
	
	NUMBER_LAN = InputBox( "How many shared LAN between your routers do you want to have ? (between 0 and 9)" )
	
	if NUMBER_LAN < 0 then
		Wscript.Echo "Warning, incorrect user input: Will use 0 shared LAN"
	end if
	
	if NUMBER_LAN > 9 then
		Wscript.Echo "Warning, incorrect user input: Will use 9 shared LAN"
	end if
	
    convert_image(BSDRP_FILENAME)
	
    clone_vm()
	
	call MsgBox (TEXT,vbOk,RELEASE)
	
	Wscript.Quit
	
    start_vm()
   
    TEXT = "Now, we will check IP connectivity by pinging the standby ISG card" & vbCrLf
    TEXT = TEXT & "Click OK for send a ping to the Standby ISG card"
    RESPONSE = MsgBox (TEXT,vbOkCancel,RELEASE)
    If RESPONSE = 2 Then
        wscript.quit
    End If
   
    Set WshShell = WScript.CreateObject("WScript.Shell")

    RETURNCODE = WshShell.Run("ping 172.16.255.1 -n 1", 1, True)
    if RETURNCODE > 0 then
        TEXT = "ERROR for ping the Standby ISG card!" & vbCrLf
        TEXT = TEXT & "Check your workstation IP configuration and cabling!" & vbCrLf
        RESPONSE = MsgBox (TEXT,vbOkCancel,RELEASE)
        If RESPONSE = 2 Then
            wscript.quit
        End If
    end if
   
    TEXT = "IP Connectivty is OK" & vbCrLf & vbCrLf
    TEXT = TEXT & "Step 3: Sending firmware file into the Standby ISG card." & vbCrLf
    TEXT = TEXT & "Click OK for proceding to files transfert"
    RESPONSE = MsgBox (TEXT,vbOkCancel,RELEASE)
    If RESPONSE = 2 Then
        wscript.quit
    End If
   
    FTP_isg()
   
    TEXT = "File should be transferted on the Standby ISG card" & vbCrLf & vbCrLf
    TEXT = TEXT & "Step 4: Sending initial configurations and hosts file into the ISG card." & vbCrLf & vbCrLf
    TEXT = TEXT & "1. Power off the ATM switch" & vbCrLf & vbCrLf
    TEXT = TEXT & "2. Unplug your workstation Ethernet cable from the standby ISG card and plug it on the ISG card" & vbCrLf & vbCrLf
    TEXT = TEXT & "3. Extract the Standby ISG card and change the rotary switch position to 4 but do not re-insert it!: This card will be insered only at the end of this procedure" & vbCrLf & vbCrLf
    TEXT = TEXT & "4. Re-insert all other cards with the expection of the Standby ISG card" & vbCrLf & vbCrLf
    TEXT = TEXT & "5. Power on the ATM switch" & vbCrLf & vbCrLf
    TEXT = TEXT & "6. Wait until the ATM switch is running:" & vbCrLf & vbCrLf
    TEXT = TEXT & "- LED Status for ISG card: FLT and RUN are alternatively blinking" & vbCrLf & vbCrLf
    TEXT = TEXT & "Click OK only when ATM switch is ready"
    RESPONSE = MsgBox (TEXT,vbOkCancel,RELEASE)
    If RESPONSE = 2 Then
        wscript.quit
    End If
   
    TEXT = "Now, we will check IP connectivity by pinging ISG card" & vbCrLf
    TEXT = TEXT & "Click OK for send a ping to the ISG"
    RESPONSE = MsgBox (TEXT,vbOkCancel,RELEASE)
    If RESPONSE = 2 Then
        wscript.quit
    End If

    RETURNCODE = WshShell.Run("ping 172.16.255.1 -n 1", 1, True)
    if RETURNCODE > 0 then
        TEXT = "ERROR for ping the ISG card!" & vbCrLf
        TEXT = TEXT & "Check your workstation IP configuration and cabling!" & vbCrLf
        RESPONSE = MsgBox (TEXT,vbOkCancel,RELEASE)
        If RESPONSE = 2 Then
            wscript.quit
        End If
    end if
   
    TEXT = "IP Connectivty is OK" & vbCrLf & vbCrLf
    TEXT = TEXT & "Step 5: Sending firmware and initial configuration files into the ISG." & vbCrLf
    TEXT = TEXT & "Click OK for proceding to files transfert"
    RESPONSE = MsgBox (TEXT,vbOkCancel,RELEASE)
    If RESPONSE = 2 Then
        wscript.quit
    End If
   
    FTP_isg()
   
    TEXT = "Step 6: Change the rotary switch of the ISG card (slot0) to 0"  & vbCrLf  & vbCrLf
    TEXT = TEXT & "1. Extract the ISG card (slot0) and put the rotary swith in position 0"  & vbCrLf & vbCrLf
    TEXT = TEXT & "2. Re-insert the ISG card (slot0)"  & vbCrLf & vbCrLf
    TEXT = TEXT & "3. Click OK ONLY when (after about 5 minutes):"  & vbCrLf & vbCrLf
    TEXT = TEXT & " - ISG card: The RUN led is solid green, and FLT led is off"  & vbCrLf
    TEXT = TEXT & " - XH cards: All RX leds are flashing orange"  & vbCrLf
    TEXT = TEXT & " - EC2 card (if present): Link Fault led is blinking"  & vbCrLf
    RESPONSE = MsgBox (TEXT,vbOkCancel,RELEASE)
    If RESPONSE = 2 Then
        wscript.quit
    End If
   
    TEXT = "Now, we will check IP connectivity for each slot"  & vbCrLf
    TEXT = TEXT & "Click OK for send the ping of the death"  & vbCrLf
    RESPONSE = MsgBox (TEXT,vbOkCancel,RELEASE)
    If RESPONSE = 2 Then
        wscript.quit
    End If
   
    RETURNCODE=ping_internal()
    if RETURNCODE > 0 then
        TEXT = "ERROR: Can't ping all slots!"  & vbCrLf
        TEXT = TEXT & "Use the procedure for a manual transfer :-("  & vbCrLf
        RESPONSE = MsgBox (TEXT,vbOkCancel,RELEASE)
        If RESPONSE = 2 Then
            wscript.quit
        End If
    end if
   
    TEXT = "Successfull ping all slots"  & vbCrLf & vbCrLf
    TEXT = TEXT & "Step 7: Sending all firmware and configuration files to each slot"  & vbCrLf
    TEXT = TEXT & "Click OK for starting the process"  & vbCrLf
    RESPONSE = MsgBox (TEXT,vbOkCancel,RELEASE)
    If RESPONSE = 2 Then
        wscript.quit
    End If
   
    RETURNCODE=files_upload()
   
    if RETURNCODE <> 0 then
        TEXT = "Error meet during file transfer!"  & vbCrLf
        TEXT = TEXT & "Use the procedure for a manual transfer :-("  & vbCrLf
        RESPONSE = MsgBox (TEXT,vbOkCancel,RELEASE)
        If RESPONSE = 2 Then
            wscript.quit
        End If
    end if
   
    TEXT = "Step 8: Setting definitive rotary switch parameter"  & vbCrLf & vbCrLf
    TEXT = TEXT & " 1. power off the ATM switch"  & vbCrLf  & vbCrLf
    TEXT = TEXT & " 2. Extract each card (with the exeption of ISG card that is allready in good boot mode, standby ISG card that is allready extracted and XH cards)" & vbCrLf  & vbCrLf
    TEXT = TEXT & " 3. Change Rotary switch position to 8 for each extracted card (with the expection of Standby ISG card that is keept in position 4 and ISG card keept in position 0)"  & vbCrLf  & vbCrLf
    TEXT = TEXT & " 4. Re-insert ALL cards (with the exeption of ISG and XH cards that are allready insered)"  & vbCrLf  & vbCrLf
    TEXT = TEXT & " 5. Power on your ATM switch"  & vbCrLf  & vbCrLf
    TEXT = TEXT & " 6. Wait until the switch has started (ISG card with green RUN LED, and Standby ISG with slowly blink RUN LED)"  & vbCrLf  & vbCrLf
    RESPONSE = MsgBox (TEXT,vbOk,RELEASE)
   
    clean()
   
End Sub

Sub FTP_isg()

    Set WshShell = WScript.CreateObject("WScript.Shell")
    Set objFSO = CreateObject("Scripting.FileSystemObject")

    If (objFSO.FileExists("hosts")) Then
        objFSO.DeleteFile("hosts")
    end if

    Set HOSTSFILE = objFSO.CreateTextFile("hosts")
    HOSTSFILE.WriteLine ("ipaddress=10.10.10.10")
    HOSTSFILE.Close
   
    If (objFSO.FileExists("ftpcommands.txt")) Then
        objFSO.DeleteFile("ftpcommands.txt")
    end if

    Set objFile = objFSO.CreateTextFile("ftpcommands.txt")
    objFile.WriteLine ("root")
    objFile.WriteLine ("MANAGER")
    objFile.WriteLine ("bin")
    objFile.WriteLine ("hash")
    objFile.WriteLine ("get vconfig")
    objFile.WriteLine ("cd /mnt/flash0")
    objFile.WriteLine ("put slot0\startup_isg.tz")
    objFile.WriteLine ("put hosts")
    objFile.WriteLine ("bye")
    objFile.Close

   
    RETURNCODE = WshShell.Run("ftp -s:ftpcommands.txt 172.16.255.1", 1, True)

    If (objFSO.FileExists("vconfig")) Then
        objFSO.DeleteFile("vconfig")
    else
        RETURNCODE = RETURNCODE + 1
    end if

    if RETURNCODE > 0 then
        TEXT = "Error meet during the FTP transfert to the ISG card!" & vbCrLf
        TEXT = TEXT & "Use the procedure for a manual transfer :-("
        RESPONSE = MsgBox (TEXT,vbOkCancel,RELEASE)
        If RESPONSE = 2 Then
            wscript.quit
        End If
    end if
   

End Sub

Sub Generate_ftp_script()
    Set objFSO = CreateObject("Scripting.FileSystemObject")

    If (objFSO.FileExists("ftpslot0.txt")) Then
        objFSO.DeleteFile("ftpslot0.txt")
    end if
   
    Set objFile = objFSO.CreateTextFile("ftpslot0.txt")
    objFile.WriteLine ("root")
    objFile.WriteLine ("MANAGER")
    objFile.WriteLine ("bin")
    objFile.WriteLine ("hash")
    objFile.WriteLine ("get vconfig")
    objFile.WriteLine ("cd /mnt/flash0")
   
    set fso = CreateObject("Scripting.FileSystemObject")
    Set WshShell = WScript.CreateObject("WScript.Shell")
    'Get the sub folder list
    set SUBDIR_LIST =  fso.GetFolder(".").SubFolders
  
    For Each SUBDIR In SUBDIR_LIST
        set OBJ_FILE_LIST =  fso.GetFolder(SUBDIR.Path).Files
       
        if SUBDIR.Name = "slot0" then
            For Each OBJ_FILE In OBJ_FILE_LIST
                'Skip the startup file: Allready uploaded
                if OBJ_FILE.Name <> "startup_isg.tz" then
                    objFile.WriteLine ("put slot0\" & OBJ_FILE.Name)   
                end if
           
            Next
       
        end if
   
    next
   
    objFile.WriteLine ("bye")
    objFile.Close
   
End Sub

Sub Check_file()

   ' Create the object
   TEXT = "Step 1: Checking firmware and configuration files presence and validity:" & vbCrLf
   TEXT = TEXT & "Check if your hardware ATM switch correspond to this configuration:" & vbCrLf & vbCrLf
    set fso = CreateObject("Scripting.FileSystemObject")
    'Get the sub folder list
    set SUBDIR_LIST =  fso.GetFolder(".").SubFolders
   
    If SUBDIR_LIST.Count = 0 Then

       MsgBox  "No slot directories found in script directory!" & vbCrLf & "There must be slot0, slot1, slot2, etc... directories that contain firmware and configurations files!"
        wscript.quit
    Else
  
        For Each SUBDIR In SUBDIR_LIST
            TEXT = TEXT & "- " & SUBDIR.Name & " "
            'Get the list of file in this sub folder
            set OBJ_FILE_LIST =  fso.GetFolder(SUBDIR.Path).Files
           
            FILE_CONFIG = 0
            FILE_STARTUP = 0
            FILE_HOSTS = 0
            FILE_VSM = 0
            FILE_MPRO = 0
            FILE_SLAVE = 0
            FILE_LCA = 0
            FILE_CE_LCA = 0
            FILE_ECC = 0
            FILE_EONE= 0
            FILE_OC= 0
           
            For Each OBJ_FILE In OBJ_FILE_LIST
           
                Select Case (OBJ_FILE.Name)

                Case "vsm.bin":
                    FILE_VSM = 1

                Case "mpro1.cod":
                    FILE_MPRO = 1

                Case "slave.cod":
                    FILE_SLAVE = 1
               
                Case "ce_lca.bin":
                    FILE_LCA = 1
                   
                Case "ecc.cod":
                    FILE_ECC = 1
                   
                Case "e1ds1.cod":
                    FILE_EONE = 1
               
                Case "oc3.cod":
                    FILE_OC = 1
               
                Case "hosts":
                    FILE_HOSTS = 1
               
                Case "startup_isg.tz":
                    FILE_STARTUP = 1
                   
                Case "config.cfg":
                    FILE_CONFIG = 1

                End Select
               
            Next
       
            if FILE_CONFIG = 1 then
                if FILE_HOSTS=1 and FILE_STARTUP=1 then
                    TEXT = TEXT & "front: ISG, back: Empty" & vbCrLf
                elseif FILE_CONFIG=1 and FILE_VSM=1 and FILE_MPRO=1 then
                    TEXT = TEXT & "front: VSM, back: DS1-4CS" & vbCrLf
                elseif FILE_CONFIG=1 and FILE_MPRO=1 then
                    TEXT = TEXT & "front: ACP, back: E3-2C" & vbCrLf
                elseif FILE_CONFIG=1 and FILE_ECC=1 and FILE_EONE=1 then
                    TEXT = TEXT & "front: ECC/EC2, back: E1-IMA" & vbCrLf
                elseif FILE_CONFIG=1 and FILE_ECC=1 and FILE_OC=1 then
                    TEXT = TEXT & "front: ECC/EC2, back: 155I/M/H-2" & vbCrLf
                elseif FILE_CONFIG=1 and FILE_SLAVE=1 and FILE_LCA=1 then
                    TEXT = TEXT & "front: CE, back: SI-4C" & vbCrLf
                else
                    TEXT = TEXT & "Unknown!" & vbCrLf
                end if
            else
                TEXT = TEXT & "Missing config.cfg file!" & vbCrLf
            end if
       
        Next

        RESPONSE = MsgBox (TEXT,vbOkCancel,"Checking Switch Files presence")
       
        If RESPONSE = 2 Then
            wscript.quit
        End If
       
    End If
   
End Sub

Function files_upload()
    files_upload=0
    ' Create the object
    set fso = CreateObject("Scripting.FileSystemObject")
    Set WshShell = WScript.CreateObject("WScript.Shell")
    'Get the sub folder list
    set SUBDIR_LIST =  fso.GetFolder(".").SubFolders
  
    For Each SUBDIR In SUBDIR_LIST
        set OBJ_FILE_LIST =  fso.GetFolder(SUBDIR.Path).Files
       
        if SUBDIR.Name = "slot0" then
            ' Do not transfert slot0 in the begining, keept it for the last transfert
            'Must includ and loop exit here
            WScript.Sleep 1
           
        else
            'Extract the number of the folder name: slot1
            'create a 2 element array cuting using the 't'
            TEMPO = Split(SUBDIR.Name, "t", -1, 1)
            SLOT_IP = 10 + TEMPO(1)
            For Each OBJ_FILE In OBJ_FILE_LIST
                RETURNCODE = WshShell.Run("tftp -i 10.10.10." & SLOT_IP &" put " & SUBDIR.Name & "\" & OBJ_FILE.Name, 1, True)
                if RETURNCODE > 0 then

                    WScript.Sleep 1000
                    RETURNCODE = WshShell.Run("tftp -i 10.10.10." & SLOT_IP &" put " & SUBDIR.Name & "\" & OBJ_FILE.Name, 1, True)
                    if RETURNCODE > 0 then
                        TEXT = "Error for TFTP transfer file: " & OBJ_FILE.Name
                        TEXT = TEXT & " into slot IP 10.10.10." & SLOT_IP
                        MsgBox TEXT
                    end if
                end if
                WScript.Sleep 1000
                files_upload = files_upload + RETURNCODE
            Next
       
        end if
       
    next
   
    'After all card, we upload to the ISG card
    Generate_ftp_script()
   
    ' The return code is allways 0 (good) with FTP
    RETURNCODE = WshShell.Run("ftp -s:ftpslot0.txt 10.10.10.10", 1, True)

    ' the FTP script download the vconfig file, this permit to check if FTP connection works

    If (fso.FileExists("vconfig")) Then
        fso.DeleteFile("vconfig")
    else
        RETURNCODE = RETURNCODE + 1
    end if

    files_upload = files_upload + RETURNCODE


End Function

Function Ping_Internal()
    Ping_Internal=0
    ' Create the object
    set fso = CreateObject("Scripting.FileSystemObject")
    Set WshShell = WScript.CreateObject("WScript.Shell")
    'Get the sub folder list
    set SUBDIR_LIST =  fso.GetFolder(".").SubFolders
  
    For Each SUBDIR In SUBDIR_LIST
        set OBJ_FILE_LIST =  fso.GetFolder(SUBDIR.Path).Files   
        'Extract the number of the folder name: slot1
        'create a 2 element array cuting using the 't'
        TEMPO = Split(SUBDIR.Name, "t", -1, 1)
        SLOT_IP = 10 + TEMPO(1)
       
        RETURNCODE = WshShell.Run("ping 10.10.10." & SLOT_IP & " -n 1", 1, True)
        Ping_Internal= Ping_Internal + RETURNCODE       
    next
   
End Function

Function check_file(byval BSDRP_filename)

    strComputer = "."
    Set objWMIService = GetObject("winmgmts:" _
    & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")

    Set IPConfigSet = objWMIService.ExecQuery _
    ("Select * from Win32_NetworkAdapterConfiguration Where IPEnabled=TRUE")
 
    foundip=0
    foundmask=0
    foundgw=0

    For Each IPConfig in IPConfigSet
        If Not IsNull(IPConfig.IPAddress) Then
            For i=LBound(IPConfig.IPAddress) to UBound(IPConfig.IPAddress)
                if IPConfig.IPAddress(i)=ipaddress then
                    foundip=1
                end if
                'WScript.Echo "DEBUG IP: " & IPConfig.IPAddress(i)
            Next
        End If
        If Not IsNull(IPConfig.DefaultIPGateway) Then
            For i=LBound(IPConfig.DefaultIPGateway) to UBound(IPConfig.DefaultIPGateway)
                if IPConfig.DefaultIPGateway(i)=defaultipgateway then
                    foundgw=1
                end if
                'WScript.Echo "DEBUG GW : " & IPConfig.DefaultIPGateway(i)
            Next
        End If
    Next
   
    check_ip = 0
   
    if foundip=1 and foundgw=1 then
        check_ip = 1
    end if

End Function

Function check_VB(ByVal VB_EXE)
	dim fso, ObjFSO, InitFSO
	
    Set fso = CreateObject("Scripting.FileSystemObject")
   
    If Not (fso.FileExists(VB_EXE)) Then
        TEXT = "Can't found VirtualBox in " & vbCrLf & VB_EXE & vbCrLf
        TEXT = TEXT & "Please, select the VBmanager.exe location" & vbCrLf
        MsgBox  TEXT,vbCritical,"Error"
        
        Set ObjFSO = CreateObject("UserAccounts.CommonDialog") 
        InitFSO = ObjFSO.ShowOpen

       If InitFSO = False Then
            Wscript.Echo "Script Error: Please select a file!"
            Wscript.Quit
        Else
            check_VB=Chr(34) & ObjFSO.FileName & Chr(34)
        End If
    else
        check_VB=Chr(34) & VB_EXE & Chr(34)
    end if
	
	set fso = Nothing
   
End Function


Function image_arch(ByVal BSDRP_FileName)
	image_arch=""
	if InStr(BSDRP_FileName, "amd64") then
		image_arch="FreeBSD_64"
	end if
	
	if InStr(BSDRP_FileName, "i386") then
		image_arch="FreeBSD"
	end if
	
    if image_arch = "" then
		Wscript.Echo "WARNING: Can't guests arch of this image, will use i386" & vbCrLf & "Did you rename the file ?"
        image_arch="FreeBSD"
    end if
   
End Function

Function image_console(ByVal BSDRP_FileName)
	image_console=""
	if InStr(BSDRP_FileName, "serial") then
		image_console="serial"
	end if
	
	if InStr(BSDRP_FileName, "vga") then
		image_console="vga"
	end if
	
	if image_console = "" then
		Wscript.Echo "WARNING: Can't guests console type of this image, will use vga" & vbCrLf & "Did you rename the file ?"
        image_console="vga"
    end if
	
   
End Function

Function convert_image (ByVal BSDRP_FileName)
	dim fso, CMD, FILE
	Set fso = CreateObject("Scripting.FileSystemObject")
	FILE=WORKING_DIR & "\BSDRP_lab.vdi"
	If (fso.FileExists(FILE)) Then
			CMD=VB_EXE & " closemedium disk " & Chr(34) & WORKING_DIR & "\BSDRP_lab.vdi" & Chr(34) & " --delete"
			call run (CMD,true)
			' fso.DeleteFile(FILE)
    end if
	
	set fso = Nothing 
	
	' Convert the IMG file into a VDI file
	
	CMD=VB_EXE & " convertfromraw " & BSDRP_FileName & " " & Chr(34) & WORKING_DIR & "\BSDRP_lab.vdi" & Chr(34)
	
	'run(CMD,true)
	call run (CMD,true)
	
	' Now, we need to compress this file, but for this action, this file must be a member of an existing VM
	' *********** IS THE COMPRESSION VERY USEFULL ??? *************************
	
	' Check existing BSDRP_lap_tempo vm before to register it!
	
	if check_vm("BSDRP_Lab_Template") = 0 then
		if delete_vm("BSDRP_Lab_Template") > 0 then
			TEXT = "Can't delete the existing BSDRP_Lab_Template VM !"
			MsgBox  TEXT,vbCritical,"Error"
			wscript.quit
		end if
	end if
	
	' Create the VM
	CMD=VB_EXE & " createvm --name BSDRP_Lab_Template --ostype " & VM_ARCH & " --register"
	
	call run(CMD,true)
	
	' Add a storage controller
	
	CMD=VB_EXE & " storagectl BSDRP_Lab_Template --name " & Chr(34) & "SATA Controller" & Chr(34) & " --add sata --controller IntelAhci"
	
	call run(CMD,true)
	
	' Add the VDI image disk
	
	CMD=VB_EXE & " storageattach BSDRP_Lab_Template --storagectl " & Chr(34) & "SATA Controller" & Chr(34) & " --port 0 --device 0 --type hdd --medium " & Chr(34) & WORKING_DIR & "\BSDRP_lab.vdi" & Chr(34)
	
	call run(CMD,true)
	
	' Reduce the VM Requirement
	
	CMD=VB_EXE & " modifyvm BSDRP_Lab_Template --memory 16 --vram 1 "
	
	call run(CMD,true)
	
	' Compress the VDI…
	
	CMD=VB_EXE & " modifyvdi " & Chr(34) & WORKING_DIR & "\BSDRP_lab.vdi" & Chr(34) & " --compact"
	
	call run(CMD,true)
	
	' Delete the VM
	
	if delete_vm ("BSDRP_Lab_Template") > 0 then
		TEXT = "Error trying to delet the BSDRP_Lab_Template after image compression" & vbCrLf & vbCrLf
		MsgBox  TEXT,vbCritical,"Error"
		wscript.quit
	end if
	

End Function

Function Run(ByVal CMD, ByVal MANAGE_ERROR)
' This function run the command CMD
' if MANAGE_ERROR is true, then this command manage error (display error and exit)
' if RETURNVAL is false, then this command silenty return RETURN_CODE

	Dim shell, ERRTEXT

    Set shell = CreateObject("WScript.Shell")
	'Wscript.Echo "DEBUG:" &  CMD
	Run = Shell.Run(CMD,1,True)
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
	
	'CMD=VB_EXE & " closemedium disk " & Chr(34) & WORKING_DIR & "\" & VM_NAME & ".vdi" & Chr(34) " --delete
	
	'delete_vm=delete_vm + run(CMD,false)
	

	
End Function

' This function generate the clones
Function clone_vm ()
	Dim i,j,NIC_NUMBER,ERRTEXT,CMD
    TEXT = "Creating lab with $NUMBER_VM routers:" & vbCrLf
    TEXT = TEXT & "- $NUMBER_LAN LAN between all routers" & vbCrLf
    TEXT = TEXT &  "- Full mesh ethernet point-to-point link between each routers" & vbCrLf & vbCrLf
    i=1
    'Enter the main loop for each VM
    Do while i <= NUMBER_VM
        create_vm ("BSDRP_lab_R" & i)
        NIC_NUMBER=0
        TEXT = TEXT & "Router" & i & " have the folllowing NIC:" & vbCrLf
        'Enter in the Cross-over (Point-to-Point) NIC loop
        'Now generate X x (X-1)/2 full meshed link
        j=1
        Do while j <= NUMBER_VM
            if i <> j then
                TEXT = TEXT & "em" & NIC_NUMBER & " connected to Router" & j & vbCrLf
                NIC_NUMBER=NIC_NUMBER + 1
				if i <= j then
					CMD=VB_EXE & " modifyvm BSDRP_lab_R" & i & " --nic" & NIC_NUMBER & " intnet --nictype" & NIC_NUMBER & " 82540EM --intnet" & NIC_NUMBER & "  LAN" & i & j & " --macaddress" & NIC_NUMBER & " AAAA00000" & i & i & j
					call run(CMD,true)
                else
					CMD=VB_EXE & " modifyvm BSDRP_lab_R" & i & " --nic" & NIC_NUMBER & " intnet --nictype" & NIC_NUMBER & " 82540EM --intnet" & NIC_NUMBER & "  LAN" & j & i & " --macaddress" & NIC_NUMBER & " AAAA00000" & i & j & i
					call run(CMD,true)
                End if
            End if
			j = j + 1
        Loop
        'Enter in the LAN NIC loop
        j=1
        Do while j <= NUMBER_LAN
            TEXT = TEXT & "em" & NIC_NUMBER & " connected to LAN number " & j & vbCrLf
            NIC_NUMBER=NIC_NUMBER + 1
			CMD=VB_EXE & " modifyvm BSDRP_lab_R" & i & " --nic" & NIC_NUMBER & " intnet --nictype" & NIC_NUMBER & " 82540EM --intnet" & NIC_NUMBER & "  LAN10" & j & " --macaddress" & NIC_NUMBER & " CCCC00000" & j & "0" & i
			call run(CMD,true)			
            j = j + 1
        Loop
		i = i + 1
    Loop
End Function

Function create_vm (ByVal VM_NAME)
	dim ERRTEXT, fso, WshShell,CMD
    ' Check if the vm allready exist
    if check_vm (VM_NAME) > 0 then		
		
		' Create the VM (HOW VM_ARCH is define if re-using existing lab ??)
		CMD=VB_EXE & " createvm --name " & VM_NAME & " --ostype " & VM_ARCH & " --register"
		call run(CMD,true)
		
		' Clone the Template vdi
		CMD=VB_EXE & " clonehd " & Chr(34) & WORKING_DIR & "\BSDRP_lab.vdi" & Chr(34) & " " & VM_NAME & ".vdi"
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
		
    End if
	
	CMD=VB_EXE & " modifyvm " & VM_NAME & " --audio none --memory 92 --vram 1 --boot1 disk --floppy disabled --biosbootmenu disabled"
	call run(CMD,true)

    if VM_CONSOLE="serial" then
		CMD=VB_EXE & " modifyvm " & VM_NAME & " --uart1 0x3F8 4 --uartmode1 server " & Chr(34) & WORKING_DIR & "\" & VM_NAME & ".serial" & Chr(34)
		call run(CMD,true)
    End if

End Function