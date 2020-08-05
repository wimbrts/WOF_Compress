#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.5 + file SciTEUser.properties in your UserProfile e.g. C:\Users\User-10

 Author:        WIMB  -  August 05, 2020

 Program:       WOF_Compress_x64.exe - Version 3.5 in rule 160

 Script Function:
	WOF Compression and Uncompression of Files Or Drives and Folders using Status and Compress Functions made by erwan.l
	GUI for WOF Compression and Uncompression of Drives and Folders using WofCompress Tool of JFX

	WOF_Compress_x64.exe needs to be Trusted Installer in case of Path with Windows Operating System folders
	Double-click WOF_Compress_Trusted.cmd so that AdvancedRun.exe is used to Run as Trusted Installer program WOF_Compress_x64.exe

 Credits and Thanks to:
	erwan.l for making the Core of WOF_Compress being Function _Wof_Status_ and _Wof_Uncompress_ and _Wof_Compress_
	JFX for making WofCompress Tool - https://msfn.org/board/topic/149612-winntsetup-v394/?do=findComment&comment=1162805
	alacran for topic on WofCompress Tool - http://reboot.pro/topic/22007-wofcompress-tool-for-win7-win10/
	AZJIO - for making _FO_FileSearch - https://www.autoitscript.com/forum/topic/133224-_filesearch-_foldersearch/
	BiatuAutMiahn[@Outlook.com] and Danyfirex for making Func _WinAPI_WofSetCompression - https://www.autoitscript.com/forum/topic/189211-wof-file-set-compression/
	Nir Sofer of NirSoft for making AdvancedRun - https://www.nirsoft.net/utils/advanced_run.html
	Joakim Schicht for making RunAsTI64.exe - https://github.com/jschicht

	The program is released "as is" and is free for redistribution, use or changes as long as original author,
	credits part and link to the reboot.pro support forum are clearly mentioned
	WOF_Compress - Download http://reboot.pro/files/file/597-wof-compress/ and Support Topic http://reboot.pro/topic/22020-wof-compress/

	Author does not take any responsibility for use or misuse of the program.

#ce ----------------------------------------------------------------------------

#include <guiconstants.au3>
#include <ProgressConstants.au3>
#include <GuiConstantsEx.au3>
#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <EditConstants.au3>
#Include <GuiStatusBar.au3>
#include <Array.au3>
#Include <String.au3>
#include <Process.au3>
#include <Date.au3>
#include <Constants.au3>
#include <WinAPIDlg.au3>
#include <WinAPI.au3>
#include <WinAPIFiles.au3>
#include <WinAPIHObj.au3>

#RequireAdmin

Opt('MustDeclareVars', 1)
Opt("GuiOnEventMode", 1)
Opt("TrayIconHide", 1)

Global Const $sTagWOF_EXTERNAL_INFO = "ulong WOFEI_Version;ulong WOFEI_Provider"
Global Const $sTagFILE_PROVIDER_EXTERNAL_INFO_V1 = "ulong FPEI_Version;ulong FPEI_CompressionFormat;ulong Flags"
Global Const $sTagIOSTATUSBLOCK = "ptr Status;ptr Information"
Global Const $sTagOBJECTATTRIBUTES = "ulong Length;handle RootDirectory;ptr ObjectName;ulong Attributes;ptr SecurityDescriptor;ptr SecurityQualityOfService"
Global Const $sTagUNICODESTRING = "ushort Length;ushort MaximumLength;ptr Buffer"
Global Const $FILE_OPEN = 0x00000001
Global Const $STATUS_PENDING = 0x00000103
Global Const $STATUS_SUCCESS = 0x00000000
Global Const $STATUS_ACCESS_DENIED = 0xC0000022
Global Const $OBJ_CASE_INSENSITIVE = 0x00000040
Global Const $FILE_SHARE_VALID_FLAGS = 0x00000007
Global Const $FILE_OPEN_REPARSE_POINT = 0x00200000
Global Const $FSCTL_SET_EXTERNAL_BACKING = 0x9030C
Global Const $FSCTL_GET_EXTERNAL_BACKING = 0x90310
Global Const $FSCTL_DELETE_EXTERNAL_BACKING = 0x90314
Global Const $FILE_OPEN_FOR_BACKUP_INTENT = 0x00004000
Global Const $STATUS_INVALID_DEVICE_REQUEST = 0xC0000010
Global Const $STATUS_COMPRESSION_NOT_BENEFICIAL = 0xC000046F
Global Const $FILE_PROVIDER_COMPRESSION_FORMAT_XPRESS4K = 0
Global Const $FILE_PROVIDER_COMPRESSION_FORMAT_LZX = 1
Global Const $FILE_PROVIDER_COMPRESSION_FORMAT_XPRESS8K = 2
Global Const $FILE_PROVIDER_COMPRESSION_FORMAT_XPRESS16K = 3
Global Const $FILE_PROVIDER_CURRENT_VERSION = 1
Global Const $WOF_CURRENT_VERSION = 1
Global Const $WOF_PROVIDER_FILE = 2

Global $hDll_NTDLL, $sFilePath = "", $FileSize_Org = 0, $FileSize = 0, $COMPRESSION_FORMAT = 1

; Declaration GUI variables
Global $hGuiParent, $ProgressAll, $hStatus, $EXIT, $ProgStat_Label
Global $COMPRESS_BUTTON, $UNCOMPRESS_BUTTON, $COMPR_TYPE_COMBO, $Use_Tool, $Use_FileList
Global $COMPR_FileSelect, $COMPR_File_GUI, $COMPR_Size_Label, $EXCL_FileData, $EXCL_FileSelect
Global $COMPR_Drive_GUI, $COMPR_DriveSel, $COMPR_DriveSize
; Setting Other variables
Global $comp_type = "LZX", $compr_file="", $compr_Size=0, $compr_fsel_flag = 0, $PE_flag = 0
Global $ComprDrive="", $FSvar_ComprDrive="", $DriveSysType="Fixed", $compr_Path = "", $LogFile = ""

Global $config_file_compress=@ScriptDir & "\makebt\Compress_Exclude.ini", $excl_file = @ScriptDir & "\makebt\WimBootReCompress.ini"
Global $config_file_tool=@ScriptDir & "\makebt\WimBootReCompress.ini"


; Global $compr_exclude = @ScriptDir & "\makebt\Compress_Exclude.txt"
Global $compr_include = @ScriptDir & "\makebt\Compress_FileList.txt"
Global $compr_include_selected = @ScriptDir & "\makebt\Compress_FileList.txt"

Global $excl_list[3000], $incl_list[3000], $mask_list[300], $Mask = "*"

Global $NrFiles, $iFail = 0, $iSkip = 0, $iDirs = 0, $iProcessed = 0, $TotalFileSize_Before = 0, $TotalFileSize_After = 0, $Used_Size_Before = 0, $Used_Size_After = 0

;~ If @OSArch <> "X86" Then
;~    MsgBox(48, "ERROR - Environment", "In x64 environment use WOF_Compress_x64.exe ")
;~    Exit
;~ EndIf

;~ If Not FileExists(@ScriptDir & "\WofCompress\x86\WofCompress.exe") Then
;~ 	MsgBox(48, "ERROR - Missing File", "File " & "\WofCompress\x86\WofCompress.exe" & " NOT Found ")
;~ 	Exit
;~ EndIf

If @OSVersion = "WIN_VISTA" Or @OSVersion = "WIN_2003" Or @OSVersion = "WIN_XP" Or @OSVersion = "WIN_XPe" Or @OSVersion = "WIN_2000" Then
	MsgBox(48, "WARNING - OS Version is Not Valid ", "Use Windows 7/8/10 OS")
	Exit
EndIf

If Not FileExists(@ScriptDir & "\makebt\Compress_Exclude.ini") Then
	MsgBox(48, "ERROR - Missing File", "File " & "\makebt\Compress_Exclude.ini" & " NOT Found ")
	Exit
EndIf

If Not FileExists(@ScriptDir & "\makebt\WimBootReCompress.ini") Then
	MsgBox(48, "ERROR - Missing File", "File " & "\makebt\WimBootReCompress.ini" & " NOT Found ")
	Exit
EndIf

If Not FileExists(@ScriptDir & "\WofCompress\x64\WofCompress.exe") Then
	MsgBox(48, "ERROR - Missing File", "File " & "\WofCompress\x64\WofCompress.exe" & " NOT Found ")
	Exit
EndIf

;~ If Not FileExists($compr_exclude) Then
;~ 	MsgBox(48, "ERROR - Missing File", "File " & $compr_exclude & " NOT Found ")
;~ 	Exit
;~ EndIf

If Not FileExists($compr_include) Then
	MsgBox(48, "ERROR - Missing File", "File " & $compr_include & " NOT Found ")
	Exit
EndIf

If StringLeft(@SystemDir, 1) = "X" Then
	$PE_flag = 1
Else
	$PE_flag = 0
EndIf

If Not FileExists(@ScriptDir & "\processed") Then DirCreate(@ScriptDir & "\processed")

; Creating GUI and controls
$hGuiParent = GUICreate(" WOF_Compress x64 - Files Or Folders ", 400, 430, -1, -1, BitXOR($GUI_SS_DEFAULT_GUI, $WS_MINIMIZEBOX))
GUISetOnEvent($GUI_EVENT_CLOSE, "_Quit")

If $PE_flag = 1 Then
	GUICtrlCreateGroup("Settings - Version 3.5  -   OS = " & @OSVersion & " " & @OSArch & "  PE", 18, 10, 364, 195)
Else
	GUICtrlCreateGroup("Settings - Version 3.5  -   OS = " & @OSVersion & " " & @OSArch, 18, 10, 364, 195)
EndIf

GUICtrlCreateLabel( "  Exclusion File ", 32, 39)
$EXCL_FileData = GUICtrlCreateInput("", 32, 55, 303, 20, $ES_READONLY)
$EXCL_FileSelect = GUICtrlCreateButton("...", 341, 56, 26, 18)
GUICtrlSetTip($EXCL_FileSelect, " Select Exclusion File Compress_Exclude.ini " & @CRLF _
& " Or Select Exclusion File WimBootReCompress.ini " & @CRLF & " Or Use Custom Exclusion File ")
GUICtrlSetOnEvent($EXCL_FileSelect, "_excl_fsel")

$UNCOMPRESS_BUTTON = GUICtrlCreateButton("Un Compress", 265, 105, 90, 30)
GUICtrlSetOnEvent($UNCOMPRESS_BUTTON, "_UnCompress")
GUICtrlSetTip($UNCOMPRESS_BUTTON, " Un Compress Files or Folders on NTFS Drive ")

$COMPRESS_BUTTON = GUICtrlCreateButton("Compress", 265, 150, 90, 30)
GUICtrlSetOnEvent($COMPRESS_BUTTON, "_APPLY_Compress")
GUICtrlSetTip($COMPRESS_BUTTON, " Apply WOF Compression of Files or Folders on NTFS Drive ")

$Use_FileList = GUICtrlCreateCheckbox("", 32, 91, 17, 17)
GUICtrlSetTip($Use_FileList, " Use File List for WOF Compression" & @CRLF _
& " Default is makebt\Compress_FileList.txt " & @CRLF & " Use File Button to Select Custom File List " & @CRLF & " Select Drive where Files are Located ")
GUICtrlCreateLabel( "Use File List for Drive ", 56, 93)

$Use_Tool = GUICtrlCreateCheckbox("", 32, 113, 17, 17)
GUICtrlSetTip($Use_Tool, " Use Wof Compress Tool of JFX - Trusted Installer" & @CRLF _
& " using Exclusions of WimBootReCompress.ini " & @CRLF & " Or Use Custom Exclusion File ")
GUICtrlCreateLabel( "Use Wof Compress Tool", 56, 115)

$COMPR_TYPE_COMBO = GUICtrlCreateCombo("", 32, 150, 90, 24, $CBS_DROPDOWNLIST)
GUICtrlSetTip($COMPR_TYPE_COMBO, " Select Compression Type ")
GUICtrlSetData($COMPR_TYPE_COMBO,"XPRESS4K|XPRESS8K|XPRESS16K|LZX", "LZX")
GUICtrlCreateLabel( "Type", 135, 152)

GUICtrlCreateGroup("Target", 18, 212, 364, 129)

GUICtrlCreateLabel( "  File", 32, 236)
$COMPR_Size_Label = GUICtrlCreateLabel( "", 60, 236, 290, 15, $ES_READONLY)
$COMPR_File_GUI = GUICtrlCreateInput("", 32, 252, 303, 20, $ES_READONLY)
$COMPR_FileSelect = GUICtrlCreateButton("...", 341, 253, 26, 18)
GUICtrlSetTip($COMPR_FileSelect, " Select File on NTFS Drive " & @CRLF & " Compress / Un Compress without Exclusion ")
GUICtrlSetOnEvent($COMPR_FileSelect, "_compr_fsel")

GUICtrlCreateLabel( "  Drive Or Folder", 32, 286)
$COMPR_DriveSize = GUICtrlCreateLabel( "", 140, 286, 190, 15, $ES_READONLY)
$COMPR_Drive_GUI = GUICtrlCreateInput("", 32, 302, 303, 20, $ES_READONLY)
$COMPR_DriveSel = GUICtrlCreateButton("...", 341, 303, 26, 18)
GUICtrlSetTip(-1, " Select Drive Or Folder - NTFS needed ")
GUICtrlSetOnEvent($COMPR_DriveSel, "_compr_drive")

$EXIT = GUICtrlCreateButton("EXIT", 320, 360, 60, 30)
GUICtrlSetOnEvent($EXIT, "_Quit")
$ProgStat_Label = GUICtrlCreateLabel( "", 32, 352, 213, 15, $ES_READONLY)
$ProgressAll = GUICtrlCreateProgress(16, 368, 203, 16, $PBS_SMOOTH)

$hStatus = _GUICtrlStatusBar_Create($hGuiParent, -1, "", $SBARS_TOOLTIPS)
Global $aParts[3] = [305, 350, -1]
_GUICtrlStatusBar_SetParts($hStatus, $aParts)

_GUICtrlStatusBar_SetText($hStatus," Select File Or Drive \ Folder", 0)

DisableMenus(1)

; using WimBootReCompress.ini as Exclusion file
$excl_file = $config_file_compress
GUICtrlSetData($EXCL_FileData, $excl_file)
GUICtrlSetState($EXCL_FileData, $GUI_ENABLE)
GUICtrlSetState($EXCL_FileSelect, $GUI_ENABLE)
GUICtrlSetState($Use_FileList, $GUI_UNCHECKED + $GUI_ENABLE)
GUICtrlSetState($Use_Tool, $GUI_UNCHECKED + $GUI_ENABLE)
GUICtrlSetState($COMPR_TYPE_COMBO, $GUI_ENABLE)
GUICtrlSetState($COMPR_FileSelect, $GUI_ENABLE)
GUICtrlSetState($COMPR_DriveSel, $GUI_ENABLE + $GUI_FOCUS)
GUICtrlSetState($EXIT, $GUI_ENABLE)
GUICtrlSetData($ProgStat_Label, "")

GUISetState(@SW_SHOW)

;===================================================================================================
While 1
	CheckGo()
	Sleep(500)
WEnd   ;==> Loop
;===================================================================================================
Func CheckGo()
	If GUICtrlRead($Use_FileList) = $GUI_CHECKED Then
		GUICtrlSetState($COMPR_FileSelect, $GUI_ENABLE)
		GUICtrlSetState($COMPR_File_GUI, $GUI_ENABLE)
		GUICtrlSetState($Use_Tool, $GUI_UNCHECKED + $GUI_DISABLE)
		GUICtrlSetData($COMPR_File_GUI, $compr_include_selected)
		GUICtrlSetData($COMPR_Size_Label, "")
		$compr_file = ""
		GUICtrlSetData($EXCL_FileData, "")
		GUICtrlSetState($EXCL_FileSelect, $GUI_DISABLE)
	Else
		GUICtrlSetState($Use_Tool, $GUI_ENABLE)
		If $compr_Path <> "" Then
			GUICtrlSetState($COMPR_FileSelect, $GUI_DISABLE)
			GUICtrlSetState($COMPR_File_GUI, $GUI_DISABLE)
			GUICtrlSetData($COMPR_Size_Label, "")
			GUICtrlSetData($COMPR_File_GUI, "")
			GUICtrlSetData($COMPR_Size_Label, "")
			$compr_file = ""
		Else
			GUICtrlSetData($COMPR_File_GUI, $compr_file)
			GUICtrlSetState($EXCL_FileSelect, $GUI_ENABLE)
		EndIf
	EndIf
	If GUICtrlRead($Use_Tool) = $GUI_CHECKED Then
		GUICtrlSetState($COMPR_DriveSel, $GUI_ENABLE)
		GUICtrlSetState($COMPR_Drive_GUI, $GUI_ENABLE)
		GUICtrlSetState($COMPR_FileSelect, $GUI_DISABLE)
		GUICtrlSetState($COMPR_File_GUI, $GUI_DISABLE)
		GUICtrlSetState($Use_FileList, $GUI_UNCHECKED + $GUI_DISABLE)
		GUICtrlSetData($COMPR_File_GUI, "")
		GUICtrlSetData($COMPR_Size_Label, "")
		$compr_file = ""
		If $compr_fsel_flag = 0 Then
			$excl_file = $config_file_tool
			GUICtrlSetData($EXCL_FileData, $excl_file)
		EndIf
	Else
		If $compr_Path = "" Then
			GUICtrlSetState($COMPR_FileSelect, $GUI_ENABLE)
		EndIf
		GUICtrlSetState($Use_FileList, $GUI_ENABLE)
		If $compr_fsel_flag = 0 Then
			$excl_file = $config_file_compress
			GUICtrlSetData($EXCL_FileData, $excl_file)
		EndIf
	EndIf

	If $compr_file <> "" Then
		GUICtrlSetState($Use_FileList, $GUI_UNCHECKED + $GUI_DISABLE)
		GUICtrlSetState($Use_Tool, $GUI_UNCHECKED + $GUI_DISABLE)
		GUICtrlSetData($EXCL_FileData, "")
		GUICtrlSetState($EXCL_FileSelect, $GUI_DISABLE)
	EndIf

	If GUICtrlRead($Use_FileList) = $GUI_CHECKED Then
		GUICtrlSetData($EXCL_FileData, "")
	EndIf

 	If $compr_file <> "" Or $compr_Path <> "" Then
 		GUICtrlSetState($COMPRESS_BUTTON, $GUI_ENABLE)
 		GUICtrlSetState($UNCOMPRESS_BUTTON, $GUI_ENABLE)
	Else
 		GUICtrlSetState($COMPRESS_BUTTON, $GUI_DISABLE)
 		GUICtrlSetState($UNCOMPRESS_BUTTON, $GUI_DISABLE)
	EndIf
EndFunc ;==> _CheckGo
;===================================================================================================
Func _Quit()
	Local $ikey
	DisableMenus(1)
	If @GUI_WinHandle = $hGuiParent Then
		$ikey = MsgBox(48+4+256, " STOP Program ", " STOP Program ? ")
		If $ikey = 6 Then
			Exit
		Else
		DisableMenus(0)
			Return
		EndIf
	Else
		GUIDelete(@GUI_WinHandle)
	EndIf
	DisableMenus(0)
EndFunc   ;==> _Quit
;===================================================================================================
Func SystemFileRedirect($Wow64Number)
	If @OSArch = "X64" Then
		Local $WOW64_CHECK = DllCall("kernel32.dll", "int", "Wow64DisableWow64FsRedirection", "ptr*", 0)
		If Not @error Then
			If $Wow64Number = "On" And $WOW64_CHECK[1] <> 1 Then
				DllCall("kernel32.dll", "int", "Wow64DisableWow64FsRedirection", "int", 1)
			ElseIf $Wow64Number = "Off" And $WOW64_CHECK[1] <> 0 Then
				DllCall("kernel32.dll", "int", "Wow64EnableWow64FsRedirection", "int", 1)
			EndIf
		EndIf
	EndIf
EndFunc   ;==> SystemFileRedirect
;===================================================================================================
Func _compr_fsel()
	Local $pos, $iReS=0, $temp_file = ""

	DisableMenus(1)
	GUICtrlSetData($COMPR_Size_Label, "")
	GUICtrlSetData($COMPR_File_GUI, "")
	$compr_file = ""
	$compr_include_selected = $compr_include

	If GUICtrlRead($Use_FileList) = $GUI_CHECKED Then
		_GUICtrlStatusBar_SetText($hStatus," Select your Compress_FileList.txt File ", 0)
		$temp_file = FileOpenDialog("Select your Compress_FileList.txt File ", "::{20D04FE0-3AEA-1069-A2D8-08002B30309D}", "*.txt Files ( *.txt; )")
		If @error Then
			GUICtrlSetData($COMPR_File_GUI, $compr_include_selected)
			GUICtrlSetData($COMPR_Size_Label, "")
			GUICtrlSetData($EXCL_FileData, $excl_file)
			_GUICtrlStatusBar_SetText($hStatus," Select File Or Drive \ Folder", 0)
			DisableMenus(0)
			Return
		EndIf
		If Not FileExists($temp_file) Then
			MsgBox(48,"ERROR - File Not Valid", "File does Not Exist" & @CRLF & @CRLF & "Selected = " & $temp_file)
			GUICtrlSetData($COMPR_File_GUI, $compr_include_selected)
			GUICtrlSetData($COMPR_Size_Label, "")
			_GUICtrlStatusBar_SetText($hStatus," Select File Or Drive \ Folder", 0)
			DisableMenus(0)
			Return
		EndIf
		_GUICtrlStatusBar_SetText($hStatus," Select File Or Drive \ Folder", 0)
		$compr_include_selected = $temp_file
		GUICtrlSetData($COMPR_File_GUI, $compr_include_selected)
		GUICtrlSetData($COMPR_Size_Label, "")

	Else
		_GUICtrlStatusBar_SetText($hStatus," Select File on NTFS Drive ", 0)

		$temp_file = FileOpenDialog("Select File on NTFS Drive ", "::{20D04FE0-3AEA-1069-A2D8-08002B30309D}", "All Files ( *.*; )")
		If @error Then
			$compr_file = ""
			_GUICtrlStatusBar_SetText($hStatus," Select File Or Drive \ Folder", 0)
			DisableMenus(0)
			Return
		EndIf

		If DriveGetFileSystem(StringLeft($temp_file, 2)) <> "NTFS" Then
			MsgBox(48,"ERROR - File Not Valid ", " Only for NTFS Files " & @CRLF & @CRLF & " Selected File = " & $temp_file & @CRLF & @CRLF _
			& "Select File on NTFS Drive ")
			$compr_file = ""
			_GUICtrlStatusBar_SetText($hStatus," Select File Or Drive \ Folder", 0)
			DisableMenus(0)
			Return
		EndIf

		If Not FileExists($temp_file) Then
			MsgBox(48,"ERROR - File Not Valid", "File does Not Exist" & @CRLF & @CRLF & "Selected = " & $temp_file & @CRLF & @CRLF _
			& "Select File on NTFS Drive ")
			$compr_file = ""
			_GUICtrlStatusBar_SetText($hStatus," Select File Or Drive \ Folder", 0)
			DisableMenus(0)
			Return
		EndIf
		$compr_file = $temp_file
		$sFilePath = "\\.\" & $compr_file

		$FileSize_Org = _WinAPI_GetCompressedFileSize($sFilePath)

		$iReS = _Wof_Status_($sFilePath)

		$compr_Size = FileGetSize($compr_file)
		$compr_Size = Round($compr_Size / 1024)
		GUICtrlSetData($COMPR_Size_Label, DriveGetFileSystem(StringLeft($compr_file, 2)) & "  Size = " & $compr_Size & "   on Disk = " & Round($FileSize_Org / 1024) & " kB   WOF = " & $iReS)
		_GUICtrlStatusBar_SetText($hStatus," Compress Or UnCompress File", 0)

		GUICtrlSetData($COMPR_File_GUI, $compr_file)
	EndIf

	DisableMenus(0)
EndFunc   ;==> _compr_fsel
;===================================================================================================
Func _compr_drive()
	Local $DriveSelect, $Tdrive, $FSvar, $valid = 0, $ValidDrives, $RemDrives
	Local $NoDrive[3] = ["A:", "B:", "X:"], $FileSys[1] = ["NTFS"]
	Local $pos, $len

	DisableMenus(1)
	$compr_Path = ""
	$ValidDrives = DriveGetDrive( "FIXED" )
	_ArrayPush($ValidDrives, "")
	_ArrayPop($ValidDrives)
	$RemDrives = DriveGetDrive( "REMOVABLE" )
	_ArrayPush($RemDrives, "")
	_ArrayPop($RemDrives)
	_ArrayConcatenate($ValidDrives, $RemDrives)
	; _ArrayDisplay($ValidDrives)

	$ComprDrive = ""
	GUICtrlSetData($COMPR_Drive_GUI, "")
	GUICtrlSetData($COMPR_DriveSize, "")
	_GUICtrlStatusBar_SetText($hStatus," Select Drive Or Folder on NTFS Drive", 0)

	$DriveSelect = FileSelectFolder("Select Drive Or Folder on NTFS Drive ", "")
	If @error Then
		_GUICtrlStatusBar_SetText($hStatus," Select File Or Drive \ Folder", 0)
		DisableMenus(0)
		Return
	EndIf

	If StringLen($DriveSelect) <= 3 And StringLeft($DriveSelect, 2) = StringLeft(@WindowsDir, 2) Then
		MsgBox(48,"ERROR - Path Invalid - Windows Drive", "Path Invalid - Windows Drive" & @CRLF & @CRLF & "Selected Path = " & $DriveSelect)
		_GUICtrlStatusBar_SetText($hStatus," Select File Or Drive \ Folder", 0)
		DisableMenus(0)
		Return
	EndIf

	$pos = StringInStr($DriveSelect, "\", 0, -1)
	If $pos = 0 Then
		MsgBox(48,"ERROR - Path Invalid", "Path Invalid - No Backslash Found" & @CRLF & @CRLF & "Selected Path = " & $DriveSelect)
		_GUICtrlStatusBar_SetText($hStatus," Select File Or Drive \ Folder", 0)
		DisableMenus(0)
		Return
	EndIf

	$pos = StringInStr($DriveSelect, ":", 0, 1)
	If $pos <> 2 Then
		MsgBox(48,"ERROR - Path Invalid", "Drive Invalid - : Not found" & @CRLF & @CRLF & "Selected Path = " & $DriveSelect)
		_GUICtrlStatusBar_SetText($hStatus," Select File Or Drive \ Folder", 0)
		DisableMenus(0)
		Return
	EndIf

	$Tdrive = StringLeft($DriveSelect, 2)
	FOR $d IN $ValidDrives
		If $d = $Tdrive Then
			$valid = 1
			ExitLoop
		EndIf
	NEXT
	FOR $d IN $NoDrive
		If $d = $Tdrive Then
			$valid = 0
			MsgBox(48, "ERROR - Drive NOT Valid", " Drive A: B: and X: ", 3)
			_GUICtrlStatusBar_SetText($hStatus," Select File Or Drive \ Folder", 0)
			DisableMenus(0)
			Return
		EndIf
	NEXT
	If $valid And DriveStatus($Tdrive) <> "READY" Then
		$valid = 0
		MsgBox(48, "ERROR - Drive NOT Ready", "Drive NOT READY", 3)
		_GUICtrlStatusBar_SetText($hStatus," Select File Or Drive \ Folder", 0)
		DisableMenus(0)
		Return
	EndIf

	If DriveGetFileSystem(StringLeft($DriveSelect, 2)) <> "NTFS" Then
		$valid = 0
		MsgBox(48,"ERROR - Drive Not Valid ", " Only for NTFS Drives " & @CRLF & @CRLF & " Selected = " & $DriveSelect & @CRLF & @CRLF _
		& "Select Folder on NTFS Drive ")
		_GUICtrlStatusBar_SetText($hStatus," Select File Or Drive \ Folder", 0)
		DisableMenus(0)
		Return
	EndIf

	$DriveSysType=DriveGetType($Tdrive)

	If $DriveSysType="Removable" Or $DriveSysType="Fixed" Then
	Else
		MsgBox(48, "ERROR - Target Drive NOT Valid", "Target Drive = " & $Tdrive & " Not Valid " & @CRLF & @CRLF & _
		" Only Removable Or Fixed Drive allowed ", 0)
		_GUICtrlStatusBar_SetText($hStatus," Select File Or Drive \ Folder", 0)
		DisableMenus(0)
		Return
	EndIf

	If $valid Then
		$ComprDrive = StringLeft($DriveSelect, 2)

		$len = StringLen($DriveSelect)
		If $len = 3 Then
			$compr_Path = $ComprDrive
		Else
			$compr_Path = $DriveSelect
		EndIf

		$FSvar_ComprDrive = DriveGetFileSystem($ComprDrive)

		$DriveSysType=DriveGetType($ComprDrive)

;~ 		If FileExists($ComprDrive & "\Windows") And $PE_flag = 0 Then
;~ 			MsgBox(48,"WARNING - Windows Folder Found - Trusted Installer Needed", "Windows Folder Found in Path" & @CRLF & @CRLF _
;~ 			& "Selected Path = " & $DriveSelect & @CRLF & @CRLF & "Use Wof Compress Tool to be Trusted Installer" & @CRLF & @CRLF _
;~ 			& "Or Run RunAsTI64.exe and launch from Command Window " & @CRLF & @CRLF & "Or be Trusted Installer in Win10XPE Environment", 0)
;~ 		EndIf

		If GUICtrlRead($Use_FileList) = $GUI_CHECKED Then
			GUICtrlSetData($COMPR_Drive_GUI, $ComprDrive)
		Else
			GUICtrlSetData($COMPR_Drive_GUI, $compr_Path)
		EndIf
		$Used_Size_Before = Round((DriveSpaceTotal($ComprDrive) - DriveSpaceFree($ComprDrive)) / 1024, 2)

		; _GUICtrlStatusBar_SetText($hStatus," Calculating Directory Size ....", 0)
		; GUICtrlSetData($COMPR_DriveSize, $FSvar_ComprDrive & "     " & Round(DirGetSize($compr_Path) / 1024 /1024) & " MB")
		GUICtrlSetData($COMPR_DriveSize, $FSvar_ComprDrive & "   Drive Used Size = " & $Used_Size_Before & " GB")
		_GUICtrlStatusBar_SetText($hStatus," Compress Or UnCompress Drive \ Folder", 0)
	EndIf
	DisableMenus(0)
EndFunc   ;==> _compr_drive
;===================================================================================================
Func _excl_fsel()
	Local $pos, $ini_file = ""

	DisableMenus(1)
	GUICtrlSetData($EXCL_FileData, "")
	$excl_file = $config_file_compress
	$compr_fsel_flag = 0

	_GUICtrlStatusBar_SetText($hStatus," Select Exclusion File Compress_Exclude.ini ", 0)

	$ini_file = FileOpenDialog("Select Exclusion File Compress_Exclude.ini ", @ScriptDir & "\makebt\", "INI Files ( *.ini; )")
	; MsgBox(64, "INI file", "ini_file = "& $ini_file)
	If @error Or $ini_file = "" Then
		$excl_file = $config_file_compress
		GUICtrlSetData($EXCL_FileData, $excl_file)
		_GUICtrlStatusBar_SetText($hStatus," Select File Or Drive \ Folder", 0)
		DisableMenus(0)
		Return
	EndIf

	If Not FileExists($excl_file) Then
		MsgBox(48,"ERROR - Exclusion File Not Valid", "File does Not Exist" & @CRLF & @CRLF & "Selected = " & $excl_file & @CRLF & @CRLF _
		& "Select File on NTFS Drive ")
		$excl_file = $config_file_compress
		GUICtrlSetData($EXCL_FileData, $excl_file)
		_GUICtrlStatusBar_SetText($hStatus," Select File Or Drive \ Folder", 0)
		DisableMenus(0)
		Return
	EndIf

	$excl_file = $ini_file
	$compr_fsel_flag = 1

	If $compr_file <> "" Then
		_GUICtrlStatusBar_SetText($hStatus," Compress Or UnCompress File", 0)
	Else
		If $compr_Path <> "" Then
			_GUICtrlStatusBar_SetText($hStatus," Compress Or UnCompress Drive \ Folder", 0)
		Else
			_GUICtrlStatusBar_SetText($hStatus," Select File Or Drive \ Folder", 0)
		EndIf
	EndIf
	GUICtrlSetData($EXCL_FileData, $excl_file)
	DisableMenus(0)
EndFunc   ;==> _excl_fsel
;===================================================================================================
Func _APPLY_Compress()
	Local $val=0, $iPID, $iReS = 1, $iRet = 0, $time_msg = "", $time_sec = 0
	Local $handle, $line, $count=0, $count_entry = 0, $count_section = 0, $Section_Found = 0, $pos, $star, $quest, $count_excl

	DisableMenus(1)

	SystemFileRedirect("On")

	GUICtrlSetData($ProgressAll, 30)

	$comp_type = GUICtrlRead($COMPR_TYPE_COMBO)

	If $comp_type = "XPRESS4K" Then
		$COMPRESSION_FORMAT = $FILE_PROVIDER_COMPRESSION_FORMAT_XPRESS4K
	ElseIf $comp_type = "XPRESS8K" Then
		$COMPRESSION_FORMAT = $FILE_PROVIDER_COMPRESSION_FORMAT_XPRESS8K
	ElseIf $comp_type = "XPRESS16K" Then
		$COMPRESSION_FORMAT = $FILE_PROVIDER_COMPRESSION_FORMAT_XPRESS16K
	Else
		; $comp_type = "LZX"
		$COMPRESSION_FORMAT = $FILE_PROVIDER_COMPRESSION_FORMAT_LZX
	EndIf

	; in case of Drive Or Folder make FileList with _WOF_FileSearch and use _Wof_Progress_Compress
	If $compr_Path <> "" And GUICtrlRead($Use_Tool) = $GUI_UNCHECKED Then

		Local $FileList

;~ 		; test if ObjCreate is possible as it is needed in Func _FileSearch
;~ 		Local $oTest = ObjCreate("Scripting.FileSystemObject")
;~ 		If @error Then
;~ 			SystemFileRedirect("Off")
;~ 			GUICtrlSetData($ProgressAll, 0)
;~ 			MsgBox(64, " ObjCreate Failed ", " Cannot Make FileList " & @CRLF & @CRLF & " Cannot do Compression ")
;~ 			Return
;~ 		EndIf

		Local $hTimer = TimerInit() ; Begin the timer and store the handle in a variable.

		$Used_Size_Before = DriveSpaceTotal($ComprDrive) - DriveSpaceFree($ComprDrive)

		_GUICtrlStatusBar_SetText($hStatus," Preparing FileList ", 0)
		GUICtrlSetData($ProgressAll, 0)
		$NrFiles = 0
		$iFail = 0
		$iSkip = 0
		$iDirs = 0
		$iProcessed = 0
		; $TotalFileSize_Before = 0
		; $TotalFileSize_After = 0

		If GUICtrlRead($Use_FileList) = $GUI_CHECKED And FileExists($compr_include_selected) Then
			$handle = FileOpen($compr_include_selected, 0)
			$count = 0
			While $count < 2999
				$line = FileReadLine($handle)
				If @error = -1 Then ExitLoop
				If $line <> "" And StringLeft($line,1) = "\" And FileExists($ComprDrive & $line) Then
					$count = $count + 1
					$line = StringStripWS($line, 3)
					$incl_list[0] = $count
					$incl_list[$count]=$ComprDrive & $line
				EndIf
			Wend
			FileClose($handle)
		Else
			If $excl_file And FileExists($excl_file) Then
				$handle = FileOpen($excl_file, 0)
				$count = 0
				$count_entry = 0
				$count_section = 0
				$count_excl = 0
				While $count < 299
					$line = FileReadLine($handle)
					If @error = -1 Then ExitLoop
					$count = $count + 1
					$line = StringStripWS($line, 3)
					If $line = "[CompressionExclusionList]" Then
						$Section_Found = 1
						$count_section = $count
					EndIf
					If $Section_Found and $count > $count_section Then
						; end of section
						If $line = "" Or StringLeft($line, 1) = "[" Then ExitLoop
						; use leading ; for comment
						If StringLeft($line, 1) = ";" Then ContinueLoop
						$pos = StringInStr($line, "\", 0, -1)
						If $pos = 0 Then
							; File Mask
							$count_entry = $count_entry + 1
							$mask_list[0] = $count_entry
							$mask_list[$count_entry]=$line
							If $Mask = "*" Then
								$Mask = $line
							Else
								$Mask = $Mask & "|" & $line
							EndIf
						Else
							; Exclude Path\Filename
							If StringRight($line, 3) = "*.*" Then
								$line = StringTrimRight($line, 3)
							Else
								If StringRight($line, 1) = "*" Then
									$line = StringTrimRight($line, 1)
								EndIf
							EndIf
							$star = StringInStr($line, "*", 0, -1)
							$quest = StringInStr($line, "?", 0, -1)
							; If StringRegExp($line, "[^A-Z0-9a-z-_\\]") Then ContinueLoop
							If $star = 0 And $quest = 0 Then
								$count_excl = $count_excl + 1
								$excl_list[0] = $count_excl
								$excl_list[$count_excl]=$line
							EndIf
						EndIf
					EndIf
				Wend
				FileClose($handle)
				; _ArrayDisplay($mask_list)
				; _ArrayDisplay($excl_list)
				; MsgBox(64, "Mask Found", "Mask = "& $Mask)
			EndIf

;~ 			If $compr_exclude And FileExists($compr_exclude) Then
;~ 				$handle = FileOpen($compr_exclude, 0)
;~ 				$count = 0
;~ 				While $count < 2999
;~ 					$line = FileReadLine($handle)
;~ 					If @error = -1 Then ExitLoop
;~ 					If $line <> "" Then
;~ 						$count = $count + 1
;~ 						$line = StringStripWS($line, 3)
;~ 						$excl_list[0] = $count
;~ 						$excl_list[$count]=$line
;~ 					EndIf
;~ 				Wend
;~ 				FileClose($handle)
;~ 				; _ArrayDisplay($excl_list)
;~ 			EndIf

			; 1 = Make List with Only Files
			; $FileList = _FileSearch($compr_Path, "*.*", 1, $compr_exclude)

			$FileList = _WOF_FileSearch($compr_Path, $Mask, 125, 1)

			If UBound($FileList, $UBOUND_ROWS)=0 Then
				SystemFileRedirect("Off")
				MsgBox(64, "FileList Invalid ", " Empty FileList Or Empty Folder Selected = " & $compr_Path)
				_GUICtrlStatusBar_SetText($hStatus," Select Drive Or Folder on NTFS Drive", 0)
				GUICtrlSetData($ProgressAll, 0)
				DisableMenus(0)
				Return
			EndIf
		EndIf

		; _ArrayDisplay($FileList)

		$LogFile = "processed" & "\Compress_" & @YEAR & "-" & @MON & "-" & @MDAY & "_" & @HOUR & "-" & @MIN & "-" & @SEC & ".txt"

		GUICtrlSetData($ProgStat_Label, "  Compression is Running ...")

		If GUICtrlRead($Use_FileList) = $GUI_CHECKED Then
			_Wof_Progress_Compress($incl_list, $incl_list[0])
		Else
			_Wof_Progress_Compress($FileList, $FileList[0])
		EndIf

		Local $fDiff = TimerDiff($hTimer) ; Find the difference in time from the previous call of TimerInit

		$time_sec = Round($fDiff / 1000)
		If $time_sec > 60 Then
			$time_msg = Int($time_sec / 60) & ":" & Mod($time_sec, 60) & " min"
		Else
			$time_msg = $time_sec & " sec"
		EndIf

		$Used_Size_After = DriveSpaceTotal($ComprDrive) - DriveSpaceFree($ComprDrive)

		GUICtrlSetData($ProgStat_Label, "")

		FileWriteLine(@ScriptDir & "\" & $LogFile, "; End of Compression " & $comp_type)
		FileWriteLine(@ScriptDir & "\" & $LogFile, "; Processed Files    = " & $iProcessed)
		FileWriteLine(@ScriptDir & "\" & $LogFile, "; Not   Compressable = " & $iFail)
		FileWriteLine(@ScriptDir & "\" & $LogFile, "; Already Compressed = " & $iSkip)
		FileWriteLine(@ScriptDir & "\" & $LogFile, "; Used Size Drive " & $ComprDrive & " Before = " & Round($Used_Size_Before / 1024, 2) & " GB")
		FileWriteLine(@ScriptDir & "\" & $LogFile, "; Used Size Drive " & $ComprDrive & " After  = " & Round($Used_Size_After / 1024, 2) & " GB")
		FileWriteLine(@ScriptDir & "\" & $LogFile, "; Size  on  Drive " & $ComprDrive & " Saved  = " & Round(($Used_Size_Before  - $Used_Size_After) / 1024, 2) & " GB")
		FileWriteLine(@ScriptDir & "\" & $LogFile, "; Time  = " & $time_msg)

		MsgBox(64, " END of Compression ", " End of Compression " & $comp_type & @CRLF & @CRLF & " Processed = " & $iProcessed & " Files" & @CRLF _
		& @CRLF & " Not Compressable = " & $iFail & @CRLF & @CRLF & " Already Compressed = " & $iSkip & @CRLF _
		& @CRLF & " Used Size Drive " & $ComprDrive & " Before = " & Round($Used_Size_Before / 1024, 2) & " GB" & @CRLF _
		& @CRLF & " Used Size Drive " & $ComprDrive & "  After   = " & Round($Used_Size_After / 1024, 2) & " GB" & @CRLF _
		& @CRLF & " Size  on   Drive  " & $ComprDrive & "  Saved  = " & Round(($Used_Size_Before  - $Used_Size_After) / 1024, 2) & " GB" & @CRLF _
		& @CRLF & " Time  = " & $time_msg)
		GUICtrlSetData($COMPR_DriveSize, $FSvar_ComprDrive & "   Drive Used Size = " & Round($Used_Size_After / 1024, 2) & " GB")
	EndIf

	; in case of Drive Or Folder Otherwise use WofCompress Tool of JFX
	If $compr_Path <> "" And GUICtrlRead($Use_Tool) = $GUI_CHECKED Then
		; Always use -wbc option and Custom Exclusion File $excl_file instead of copying WimBootReCompress.ini to system32
;~ 		If Not FileExists(@WindowsDir & "\system32\WimBootReCompress.ini") Then
;~ 			FileCopy(@ScriptDir & "\makebt\WimBootReCompress.ini", @WindowsDir & "\system32\")
;~ 			sleep(1000)
;~ 		EndIf
		_GUICtrlStatusBar_SetText($hStatus," WOF Compress of " & $compr_Path & " - wait .... ", 0)
		If @OSArch = "X86" Then
				$iPID = Run(@ComSpec & " /k WofCompress\x86\WofCompress.exe -c:" & $comp_type & " -wbc:" & '"' & $excl_file & '"' & " -path:" & '"' & $compr_Path & '"', @ScriptDir)
		Else
				$iPID = Run(@ComSpec & " /k WofCompress\x64\WofCompress.exe -c:" & $comp_type & " -wbc:" & '"' & $excl_file & '"' & " -path:" & '"' & $compr_Path & '"', @ScriptDir)
		EndIf
		ProcessWaitClose($iPID, 1)
		GUICtrlSetData($ProgressAll, 50)
		_GUICtrlStatusBar_SetText($hStatus," DO NOT Close Command Window Until Finish ", 0)
		MsgBox(64, " Compression is Running ", " Wait for Compression of " & $compr_Path & @CRLF _
		& @CRLF & "DO NOT Close Command Window Until Process Finished" & @CRLF _
		& @CRLF & "On Finish then [ Time : ... sec ] is Displayed")

		GUICtrlSetData($ProgressAll, 100)
		_GUICtrlStatusBar_SetText($hStatus," End - Close Cmd Window After Process Finished", 0)
		MsgBox(64, " END of GUI Program ", " End of GUI Program " & @CRLF & @CRLF & "Close the Command Window After Process has Finished")
	EndIf

	; in case of File then ....
	If $compr_file <> "" Then
		GUICtrlSetData($ProgressAll, 50)
 		$sFilePath = "\\.\" & $compr_file
 		$FileSize_Org = _WinAPI_GetCompressedFileSize($sFilePath)

		Local $hTimer = TimerInit() ; Begin the timer and store the handle in a variable.

		$iReS = _Wof_Status_($sFilePath)
		If $iReS = 0 Then
			GUICtrlSetData($ProgStat_Label, "  Compression is Running ...")
;~ 			MsgBox(64, " Start of Compression ", " Start Compression of " & $compr_file & @CRLF _
;~ 			& @CRLF & "  Original FileSize = " & Round($FileSize_Org / 1024) & " kB", 2)
			_GUICtrlStatusBar_SetText($hStatus,"  Compression is Running - Wait .... ", 0)
			$iRet = _Wof_Compress_($sFilePath, $COMPRESSION_FORMAT)

			; $iRet = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\compact.exe /C /EXE:" & $comp_type & " " & $compr_file, @ScriptDir, @SW_HIDE)
			; MsgBox(64, " Return ", " Return Compress 1 is OK - OK = " & $iRet)

			If $iRet <> 1 Then
				MsgBox(64, " Not Compressable ", " Failed Compression of " & $compr_file & @CRLF _
				& @CRLF & "  Original FileSize = " & Round($FileSize_Org / 1024) & " kB")
			EndIf
		Else
			MsgBox(64, " File Already Compressed ", " Skip Compression of " & $compr_file & @CRLF _
			& @CRLF & "  Original FileSize = " & Round($FileSize_Org / 1024) & " kB", 3)
		EndIf

		Local $fDiff = TimerDiff($hTimer) ; Find the difference in time from the previous call of TimerInit

		; Biatu Not used anymore ....
;~ 		$hDll_NTDLL = DllOpen("ntdll.dll")
;~ 		ConsoleWrite(_WinAPI_WofSetCompression($sFilePath, $COMPRESSION_FORMAT, $FSCTL_SET_EXTERNAL_BACKING))
;~ 		DllClose($hDll_NTDLL)

		$FileSize = _WinAPI_GetCompressedFileSize($sFilePath)

		$iReS = _Wof_Status_($sFilePath)

		$compr_Size = FileGetSize($compr_file)
		$compr_Size = Round($compr_Size / 1024)
		GUICtrlSetData($ProgStat_Label, "")
		GUICtrlSetData($ProgressAll, 100)
		_GUICtrlStatusBar_SetText($hStatus," End of Compression ", 0)
		MsgBox(64, "WOF Compressed - Size on Disk", "  Original FileSize = " & Round($FileSize_Org / 1024) & " kB" & @CRLF _
		& @CRLF & "Compressed FileSize = " & Round($FileSize / 1024) & " kB" & @CRLF & @CRLF & " Time  = " & Round($fDiff / 1000) & " sec")
		GUICtrlSetData($COMPR_Size_Label, DriveGetFileSystem(StringLeft($compr_file, 2)) & "  Size = " & $compr_Size & "   on Disk = " & Round($FileSize / 1024) & " kB   WOF = " & $iReS)
	EndIf

	SystemFileRedirect("Off")

	_GUICtrlStatusBar_SetText($hStatus," Select File Or Drive \ Folder", 0)
	_GUICtrlStatusBar_SetText($hStatus,"", 1)
	_GUICtrlStatusBar_SetText($hStatus,"", 2)
	GUICtrlSetData($ProgressAll, 0)
	DisableMenus(0)
	; Exit
EndFunc   ;==> _APPLY_Compress
;===================================================================================================
Func _UnCompress()

	Local $val=0, $iPID, $iReS = 0, $iRet = 1, $time_msg = "", $time_sec = 0
	Local $handle, $line, $count=0

	DisableMenus(1)

	SystemFileRedirect("On")

	GUICtrlSetData($ProgressAll, 30)

	; in case of Drive Or Folder make FileList with _WOF_FileSearch and use _Wof_Progress_Uncompress
	If $compr_Path <> "" And GUICtrlRead($Use_Tool) = $GUI_UNCHECKED Then

		Local $FileList

;~ 		; test if ObjCreate is possible as it is needed in Func _FileSearch
;~ 		Local $oTest = ObjCreate("Scripting.FileSystemObject")
;~ 		If @error Then
;~ 			SystemFileRedirect("Off")
;~ 			GUICtrlSetData($ProgressAll, 0)
;~ 			MsgBox(64, " ObjCreate Failed ", " Cannot Make FileList " & @CRLF & @CRLF & " Cannot do Compression ")
;~ 			Return
;~ 		EndIf

		Local $hTimer = TimerInit() ; Begin the timer and store the handle in a variable.

		$Used_Size_Before = DriveSpaceTotal($ComprDrive) - DriveSpaceFree($ComprDrive)

		_GUICtrlStatusBar_SetText($hStatus," Preparing FileList ", 0)
		GUICtrlSetData($ProgressAll, 0)
		$NrFiles = 0
		$iFail = 0
		$iSkip = 0
		$iDirs = 0
		$iProcessed = 0
		; $TotalFileSize_Before = 0
		; $TotalFileSize_After = 0

		If GUICtrlRead($Use_FileList) = $GUI_CHECKED And FileExists($compr_include_selected) Then
			$handle = FileOpen($compr_include_selected, 0)
			$count = 0
			While $count < 2999
				$line = FileReadLine($handle)
				If @error = -1 Then ExitLoop
				If $line <> "" And StringLeft($line,1) = "\" And FileExists($ComprDrive & $line) Then
					$count = $count + 1
					$line = StringStripWS($line, 3)
					$incl_list[0] = $count
					$incl_list[$count]=$ComprDrive & $line
				EndIf
			Wend
			FileClose($handle)
		Else
			$FileList = _WOF_FileSearch($compr_Path)

			If UBound($FileList, $UBOUND_ROWS)=0 Then
				SystemFileRedirect("Off")
				MsgBox(64, "FileList Invalid ", " Empty FileList Or Empty Folder Selected = " & $compr_Path)
				_GUICtrlStatusBar_SetText($hStatus," Select Drive Or Folder on NTFS Drive", 0)
				GUICtrlSetData($ProgressAll, 0)
				DisableMenus(0)
				Return
			EndIf

		EndIf

		; _ArrayDisplay($FileList)

		$LogFile = "processed" & "\UnCompress_" & @YEAR & "-" & @MON & "-" & @MDAY & "_" & @HOUR & "-" & @MIN & "-" & @SEC & ".txt"

		GUICtrlSetData($ProgStat_Label, "  Un-Compression is Running ...")

		If GUICtrlRead($Use_FileList) = $GUI_CHECKED Then
			_Wof_Progress_Uncompress($incl_list, $incl_list[0])
		Else
			_Wof_Progress_Uncompress($FileList, $FileList[0])
		EndIf

		Local $fDiff = TimerDiff($hTimer) ; Find the difference in time from the previous call of TimerInit

		$time_sec = Round($fDiff / 1000)
		If $time_sec > 60 Then
			$time_msg = Int($time_sec / 60) & ":" & Mod($time_sec, 60) & " min"
		Else
			$time_msg = $time_sec & " sec"
		EndIf

		$Used_Size_After = DriveSpaceTotal($ComprDrive) - DriveSpaceFree($ComprDrive)

		GUICtrlSetData($ProgStat_Label, "")

		FileWriteLine(@ScriptDir & "\" & $LogFile, "; End of Un-Compression ")
		FileWriteLine(@ScriptDir & "\" & $LogFile, "; Processed Files       = " & $iProcessed)
		FileWriteLine(@ScriptDir & "\" & $LogFile, "; Un-Compression Failed = " & $iFail)
		FileWriteLine(@ScriptDir & "\" & $LogFile, "; Already  UnCompressed = " & $iSkip)
		FileWriteLine(@ScriptDir & "\" & $LogFile, "; Used Size Drive " & $ComprDrive & " Before = " & Round($Used_Size_Before / 1024, 2) & " GB")
		FileWriteLine(@ScriptDir & "\" & $LogFile, "; Used Size Drive " & $ComprDrive & " After  = " & Round($Used_Size_After / 1024, 2) & " GB")
		FileWriteLine(@ScriptDir & "\" & $LogFile, "; Size  on  Drive " & $ComprDrive & " Wasted = " & Round(($Used_Size_After  - $Used_Size_Before) / 1024, 2) & " GB")
		FileWriteLine(@ScriptDir & "\" & $LogFile, "; Time  = " & $time_msg)

		MsgBox(64, " END of Un-Compression ", " End of Un-Compression " & @CRLF & @CRLF & " Processed = " & $iProcessed & " Files" & @CRLF _
		& @CRLF & " Un-Compression Failed = " & $iFail & @CRLF & @CRLF & " Already UnCompressed = " & $iSkip & @CRLF _
		& @CRLF & " Used Size Drive " & $ComprDrive & " Before = " & Round($Used_Size_Before / 1024, 2) & " GB" & @CRLF _
		& @CRLF & " Used Size Drive " & $ComprDrive & "  After   = " & Round($Used_Size_After / 1024, 2) & " GB" & @CRLF _
		& @CRLF & " Size  on Drive " & $ComprDrive & "  Wasted  = " & Round(($Used_Size_After  - $Used_Size_Before) / 1024, 2) & " GB" & @CRLF _
		& @CRLF & " Time  = " & $time_msg)
		GUICtrlSetData($COMPR_DriveSize, $FSvar_ComprDrive & "   Drive Used Size = " & Round($Used_Size_After / 1024, 2) & " GB")
	EndIf

	; in case of Drive Or Folder Otherwise use WofCompress Tool of JFX
	If $compr_Path <> "" And GUICtrlRead($Use_Tool) = $GUI_CHECKED Then
	;~ 		If Not FileExists(@WindowsDir & "\system32\WimBootReCompress.ini") Then
	;~ 			FileCopy(@ScriptDir & "\makebt\WimBootReCompress.ini", @WindowsDir & "\system32\")
	;~ 			sleep(1000)
	;~ 		EndIf
		_GUICtrlStatusBar_SetText($hStatus," WOF UnCompress of " & $compr_Path & " - wait .... ", 0)
		If @OSArch = "X86" Then
			$iPID = Run(@ComSpec & " /k WofCompress\x86\WofCompress.exe -u -path:" & '"' & $compr_Path & '"', @ScriptDir)
		Else
			$iPID = Run(@ComSpec & " /k WofCompress\x64\WofCompress.exe -u -path:" & '"' & $compr_Path & '"', @ScriptDir)
		EndIf
		ProcessWaitClose($iPID, 1)
		GUICtrlSetData($ProgressAll, 50)
		_GUICtrlStatusBar_SetText($hStatus," DO NOT Close Command Window Until Finish ", 0)
		MsgBox(64, " Un-Compression is Running ", " Wait for Un-Compression of " & $compr_Path & @CRLF _
		& @CRLF & "DO NOT Close Command Window Until Process Finished" & @CRLF _
		& @CRLF & "On Finish then [ Time : ... sec ] is Displayed")

		GUICtrlSetData($ProgressAll, 100)
		_GUICtrlStatusBar_SetText($hStatus," End - Close Cmd Window After Process Finished", 0)
		MsgBox(64, " END of GUI Program ", " End of GUI Program " & @CRLF & @CRLF & "Close the Command Window After Process has Finished")
	EndIf

	; in case of File then ....
	If $compr_file <> "" Then
 		GUICtrlSetData($ProgressAll, 50)
 		$sFilePath = "\\.\" & $compr_file

 		$FileSize_Org = _WinAPI_GetCompressedFileSize($sFilePath)

		Local $hTimer = TimerInit() ; Begin the timer and store the handle in a variable.

		$iReS = _Wof_Status_($sFilePath)
		If $iReS = 1 Then
			GUICtrlSetData($ProgStat_Label, "  Un-Compression is Running ...")
;~ 			MsgBox(64, " Start of Un-Compression ", " Start Un-Compression of " & $compr_file & @CRLF _
;~ 			& @CRLF & "  Original FileSize = " & Round($FileSize_Org / 1024) & " kB", 2)
			_GUICtrlStatusBar_SetText($hStatus,"  Un-Compression is Running - Wait .... ", 0)
			$iRet = _Wof_Uncompress_($sFilePath)

			; $iRet = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\compact.exe /U /EXE:" & $comp_type & " " & $compr_file, @ScriptDir, @SW_HIDE)
			; MsgBox(64, " Return ", " Return Un-Compress 0 is OK - OK = " & $iRet)

			If $iRet <> 0 Then
				MsgBox(64, " Error - Un-Compression ", " Failed Un-Compression of " & $compr_file & @CRLF _
				& @CRLF & "  Original FileSize = " & Round($FileSize_Org / 1024) & " kB")
			EndIf
		Else
			MsgBox(64, " File Already Un-Compressed ", " Skip Un-Compression of " & $compr_file & @CRLF _
			& @CRLF & "  Original FileSize = " & Round($FileSize_Org / 1024) & " kB", 3)
		EndIf

		Local $fDiff = TimerDiff($hTimer) ; Find the difference in time from the previous call of TimerInit

		; Biatu Not used anymore ....
;~ 		$hDll_NTDLL = DllOpen("ntdll.dll")
;~ 		ConsoleWrite(_WinAPI_WofSetCompression($sFilePath, $FILE_PROVIDER_COMPRESSION_FORMAT_LZX, $FSCTL_DELETE_EXTERNAL_BACKING))
;~ 		DllClose($hDll_NTDLL)

 		$FileSize = _WinAPI_GetCompressedFileSize($sFilePath)

		$iReS = _Wof_Status_($sFilePath)

		$compr_Size = FileGetSize($compr_file)
		$compr_Size = Round($compr_Size / 1024)
		GUICtrlSetData($ProgStat_Label, "")
		GUICtrlSetData($ProgressAll, 100)
		_GUICtrlStatusBar_SetText($hStatus," End of Un-Compression ", 0)
		MsgBox(64, "WOF UnCompressed - Size on Disk", "    Original FileSize = " & Round($FileSize_Org / 1024) & " kB" & @CRLF _
		& @CRLF & "UnCompressed FileSize = " & Round($FileSize / 1024) & " kB" & @CRLF & @CRLF & " Time  = " & Round($fDiff / 1000) & " sec")
		GUICtrlSetData($COMPR_Size_Label, DriveGetFileSystem(StringLeft($compr_file, 2)) & "  Size = " & $compr_Size & "   on Disk = " & Round($FileSize / 1024) & " kB   WOF = " & $iReS)
	EndIf

	SystemFileRedirect("Off")

	_GUICtrlStatusBar_SetText($hStatus," Select File Or Drive \ Folder", 0)
	_GUICtrlStatusBar_SetText($hStatus,"", 1)
	_GUICtrlStatusBar_SetText($hStatus,"", 2)
	GUICtrlSetData($ProgressAll, 0)
	DisableMenus(0)
	; Exit
EndFunc   ;==> _UnCompress
;===================================================================================================
Func DisableMenus($endis)
	If $endis = 0 Then
		$endis = $GUI_ENABLE
	Else
		$endis = $GUI_DISABLE
	EndIf


	If $compr_file <> "" Then
		GUICtrlSetState($COMPR_DriveSel, $GUI_DISABLE)
		GUICtrlSetState($COMPR_Drive_GUI, $GUI_DISABLE)
		GUICtrlSetState($Use_Tool, $GUI_UNCHECKED + $GUI_DISABLE)
		GUICtrlSetState($EXCL_FileSelect, $GUI_DISABLE)
		GUICtrlSetData($EXCL_FileData, "")
	Else
		GUICtrlSetState($COMPR_DriveSel, $endis)
		GUICtrlSetState($COMPR_Drive_GUI, $endis)
		GUICtrlSetState($Use_Tool, $endis)
		GUICtrlSetState($EXCL_FileSelect, $endis)
		GUICtrlSetState($EXCL_FileData, $endis)
		GUICtrlSetData($EXCL_FileData, $excl_file)
	EndIf
	GUICtrlSetState($Use_FileList, $endis)
	GUICtrlSetState($COMPR_TYPE_COMBO, $endis)

	If $ComprDrive <> "" And GUICtrlRead($Use_FileList) = $GUI_UNCHECKED Then
		GUICtrlSetState($COMPR_FileSelect, $GUI_DISABLE)
		GUICtrlSetState($COMPR_File_GUI, $GUI_DISABLE)
	Else
		GUICtrlSetState($COMPR_FileSelect, $endis)
		GUICtrlSetState($COMPR_File_GUI, $endis)
	EndIf

	GUICtrlSetState($COMPRESS_BUTTON, $GUI_DISABLE)
	GUICtrlSetState($UNCOMPRESS_BUTTON, $GUI_DISABLE)

	GUICtrlSetState($EXIT, $endis)

EndFunc ;==>DisableMenus
;===================================================================================================
Func _Wof_Status_($sFilePath)
	; we could/should create a more meaningful structure but hey, who cares :)
	Local $outbuffer=DllStructCreate("char[20]")
	Local $hFile, $IRes
	Local $poutbuffer=DllStructGetPtr($outbuffer)

	$hFile = _WinAPI_CreateFile($sFilePath,2, 2)
	$IReS = _WinAPI_DeviceIoControl($hFile, $FSCTL_GET_EXTERNAL_BACKING, 0, 0, $poutbuffer, 20)
	; the return code is what we care about : 1 means compressed, 0 means not compressed
	_WinAPI_CloseHandle($hFile)

	; MsgBox(64, "ok", $IReS)
	Return $IReS
EndFunc ;==>_Wof_Status_
;===================================================================================================
Func _Wof_Uncompress_($sFilePath)
	Local $hFile, $iRet

	$hFile = _WinAPI_CreateFile($sFilePath, 2, 4)
	$iRet = _WinAPI_DeviceIoControl($hFile, $FSCTL_DELETE_EXTERNAL_BACKING, 0, 0, 0, 0)
	_WinAPI_CloseHandle($hFile)

	Return $iRet
EndFunc ;==>_Wof_Uncompress_
;===================================================================================================
Func _Wof_Compress_($sFilePath, $iFormat)
	Local $hFile, $iRet

    Local $tInputBuffer = DllStructCreate("STRUCT;" & $sTagWOF_EXTERNAL_INFO & ";ENDSTRUCT; STRUCT;" & $sTagFILE_PROVIDER_EXTERNAL_INFO_V1 & ";ENDSTRUCT")
    DllStructSetData($tInputBuffer, "WOFEI_Version", $WOF_CURRENT_VERSION)
    DllStructSetData($tInputBuffer, "WOFEI_Provider", $WOF_PROVIDER_FILE)
    DllStructSetData($tInputBuffer, "FPEI_Version", $FILE_PROVIDER_CURRENT_VERSION)
    DllStructSetData($tInputBuffer, "FPEI_CompressionFormat", $iFormat)
    Local $pInputBuffer = DllStructGetPtr($tInputBuffer)

	$hFile=_WinAPI_CreateFile($sFilePath, 2, 4)
	$iRet = _WinAPI_DeviceIoControl($hFile, $FSCTL_SET_EXTERNAL_BACKING, $pInputBuffer, 20, 0, 0)
	_WinAPI_CloseHandle($hFile)

	Return $iRet
EndFunc ;==>_Wof_Compress_
;===================================================================================================
Func _Wof_Progress_Compress($aFileList, $NrAllFiles)
	Local $fProgressAll, $c, $FileName
	Local $iReS = 1, $iRet = 0

	_GUICtrlStatusBar_SetText($hStatus,$NrAllFiles, 2)
	If $aFileList[0] = 0 Then
		SetError(1)
		Return -1
	EndIf
	FileWriteLine(@ScriptDir & "\" & $LogFile,"; " & $aFileList[0])
	For $c = 1 To $aFileList[0]
		$NrFiles += 1
		$fProgressAll = Int($NrFiles * 100/ $NrAllFiles)
		GUICtrlSetData($ProgressAll, $fProgressAll)
		; _GUICtrlStatusBar_SetText($hStatus, StringRight($aFileList[$c], 45), 0)
		If StringLen($aFileList[$c]) > 45 Then
			_GUICtrlStatusBar_SetText($hStatus, StringLeft($aFileList[$c], 21) & "...." & StringRight($aFileList[$c], 21), 0)
		Else
			_GUICtrlStatusBar_SetText($hStatus, $aFileList[$c], 0)
		EndIf
		_GUICtrlStatusBar_SetText($hStatus,$NrFiles, 1)
		$iProcessed += 1
		$sFilePath = "\\.\" & $aFileList[$c]
		; $TotalFileSize_Before += _WinAPI_GetCompressedFileSize($sFilePath)
		FileWriteLine(@ScriptDir & "\" & $LogFile, "; " & $aFileList[$c])

		$iReS = _Wof_Status_($sFilePath)
		If $iReS = 0 Then
			$iRet = _Wof_Compress_($sFilePath, $COMPRESSION_FORMAT)

			; $iRet = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\compact.exe /C /EXE:" & $comp_type & " " & $aFileList[$c], @ScriptDir, @SW_HIDE)

			If $iRet <> 1 Then
				; Not Compressable
				$iFail += 1
			EndIf
		Else
			; File Already Compressed
			$iSkip += 1
		EndIf
		; $TotalFileSize_After += _WinAPI_GetCompressedFileSize($sFilePath)
	Next
	Return
EndFunc  ;==>_Wof_Progress_Compress
;===================================================================================================
Func _Wof_Progress_Uncompress($aFileList, $NrAllFiles)
	Local $fProgressAll, $c, $FileName
	Local $iReS = 1, $iRet = 0

	_GUICtrlStatusBar_SetText($hStatus,$NrAllFiles, 2)
	If $aFileList[0] = 0 Then
		SetError(1)
		Return -1
	EndIf
	FileWriteLine(@ScriptDir & "\" & $LogFile, "; " & $aFileList[0])
	For $c = 1 To $aFileList[0]
		$NrFiles += 1
		$fProgressAll = Int($NrFiles * 100/ $NrAllFiles)
		GUICtrlSetData($ProgressAll, $fProgressAll)
		; _GUICtrlStatusBar_SetText($hStatus, StringRight($aFileList[$c], 45), 0)
		If StringLen($aFileList[$c]) > 45 Then
			_GUICtrlStatusBar_SetText($hStatus, StringLeft($aFileList[$c], 21) & "...." & StringRight($aFileList[$c], 21), 0)
		Else
			_GUICtrlStatusBar_SetText($hStatus, $aFileList[$c], 0)
		EndIf
		_GUICtrlStatusBar_SetText($hStatus,$NrFiles, 1)
		$iProcessed += 1
		$sFilePath = "\\.\" & $aFileList[$c]
		; $TotalFileSize_Before += _WinAPI_GetCompressedFileSize($sFilePath)
		FileWriteLine(@ScriptDir & "\" & $LogFile, "; " & $aFileList[$c])

		$iReS = _Wof_Status_($sFilePath)
		If $iReS = 1 Then
			$iRet = _Wof_Uncompress_($sFilePath)

			; $iRet = RunWait(@ComSpec & " /c " & @WindowsDir & "\system32\compact.exe /U /EXE:" & $comp_type & " " & $aFileList[$c], @ScriptDir, @SW_HIDE)

			If $iRet <> 0 Then
				; Error Uncompression - should not occur
				$iFail += 1
			EndIf
		Else
			; Already Un-Compressed
			$iSkip += 1
		EndIf
		; $TotalFileSize_After += _WinAPI_GetCompressedFileSize($sFilePath)
	Next
	Return
EndFunc  ;==>_Wof_Progress_Uncompess
;===================================================================================================
; AZJIO - modified by wimb - https://www.autoitscript.com/forum/topic/133224-_filesearch-_foldersearch/
Func _WOF_FileSearch($sPath, $sMask = '*', $iDepth = 125, $iExcludeFlag = 0)
	Local $vFileList

	If Not FileExists($sPath) Then Return SetError(1, 0, '')
	If StringRight($sPath, 1) <> '\' Then $sPath &= '\'

	If $sMask = '*' Or $sMask = '' Then
		__WOF_FileSearchAll($vFileList, $sPath, $iDepth, $iExcludeFlag)
	Else
		If StringInStr($sMask, '*') Or StringInStr($sMask, '?') Or StringInStr($sMask, '.') Then
			__WOF_GetListMask($sPath, $sMask, $iDepth, $iExcludeFlag, $vFileList)
		; Else
		;	__WOF_FileSearchType($vFileList, $sPath, '|' & $sMask & '|', $iDepth, $iExcludeFlag)
		EndIf
	EndIf

	If Not $vFileList Then Return SetError(3, 0, '')
	$vFileList = StringTrimRight($vFileList, 2)
	$vFileList = StringSplit($vFileList, @CRLF, 1)
	Return $vFileList
EndFunc   ;==>_WOF_FileSearch
;===================================================================================================
Func __WOF_FileSearchAll(ByRef $sFileList, $sPath, ByRef $iDepth, ByRef $iExcludeFlag, $iCurD = 0)
	Local $sFile, $s = FileFindFirstFile($sPath & '*')
	Local $iEx
	; MsgBox(64, " In FileSearchAll ", "Mask = " & $sMask & @CRLF & "sFileList = " & $sFileList & @CRLF & "sPath = " & $sPath)
	If $s = -1 Then Return
	While 1
		$sFile = FileFindNextFile($s)
		If @error Then ExitLoop
		If @extended Then
			If $iCurD >= $iDepth Then ContinueLoop
			__WOF_FileSearchAll($sFileList, $sPath & $sFile & '\', $iDepth, $iExcludeFlag, $iCurD + 1)
		Else
			If $iExcludeFlag = 1 Then
				For $iEx = 1 To $excl_list[0]
					If StringInStr($sPath & $sFile, $excl_list[$iEx], 0) Then ContinueLoop 2
				Next
			EndIf
			$sFileList &= $sPath & $sFile & @CRLF
		EndIf
	WEnd
	FileClose($s)
	; MsgBox(64, " Out FileSearchAll ", "Mask = " & $sMask & @CRLF & "sFileList = " & $sFileList & @CRLF & "sPath = " & $sPath)
EndFunc   ;==>__WOF_FileSearchAll
;===================================================================================================
Func __WOF_GetListMask($sPath, $sMask, $iDepth, ByRef $iExcludeFlag, ByRef $sFileList)
	Local $aFileList, $rgex='i' ; $rgex="" is Case sensitive and $rgex='i' is Not case sensitive (only for 'A-z')
	; MsgBox(64, " In GetListMask ", "Mask = " & $sMask & @CRLF & "sFileList = " & $sFileList & @CRLF & "sPath = " & $sPath)
	__WOF_FileSearchMask($sFileList, $sPath, $iDepth, $iExcludeFlag)
	$sFileList = StringTrimRight($sFileList, 2)
	$sMask = StringReplace(StringReplace(StringRegExpReplace($sMask, '[][$^.{}()+]', '\\$0'), '?', '.'), '*', '.*?')

	$sFileList = StringRegExpReplace($sFileList & @CRLF, '(?m' & $rgex & ')^[^|]+\|(' & $sMask & ')\r\n', '')

	$sFileList = StringReplace($sFileList, '|', '')
	; MsgBox(64, " Out GetListMask ", "Mask = " & $sMask & @CRLF & "sFileList = " & $sFileList & @CRLF & "sPath = " & $sPath)

EndFunc   ;==>__WOF_GetListMask
;===================================================================================================
Func __WOF_FileSearchMask(ByRef $sFileList, $sPath, ByRef $iDepth, ByRef $iExcludeFlag, $iCurD = 0)
	Local $sFile, $s = FileFindFirstFile($sPath & '*')
	Local $iEx
	If $s = -1 Then Return
	While 1
		$sFile = FileFindNextFile($s)
		If @error Then ExitLoop
		If @extended Then
			If $iCurD >= $iDepth Then ContinueLoop
			__WOF_FileSearchMask($sFileList, $sPath & $sFile & '\', $iDepth, $iExcludeFlag, $iCurD + 1)
		Else
			If $iExcludeFlag = 1 Then
				For $iEx = 1 To $excl_list[0]
					If StringInStr($sPath & $sFile, $excl_list[$iEx], 0) Then ContinueLoop 2
				Next
			EndIf
			$sFileList &= $sPath & '|' & $sFile & @CRLF
		EndIf
	WEnd
	FileClose($s)
EndFunc   ;==>__WOF_FileSearchMask
;===================================================================================================
;~ 	Func __WOF_FileSearchType(ByRef $sFileList, $sPath, $sMask, ByRef $iDepth, ByRef $iExcludeFlag, $iCurD = 0)
;~ 		Local $iPos, $sFile, $s = FileFindFirstFile($sPath & '*')
;~ 		Local $iEx
;~ 		; MsgBox(64, " In FileSearchType ", "Mask = " & $sMask & @CRLF & "sFileList = " & $sFileList & @CRLF & "sPath = " & $sPath)
;~ 		If $s = -1 Then Return
;~ 		While 1
;~ 			$sFile = FileFindNextFile($s)
;~ 			If @error Then ExitLoop
;~ 			If @extended Then
;~ 				If $iCurD >= $iDepth Then ContinueLoop
;~ 				__WOF_FileSearchType($sFileList, $sPath & $sFile & '\', $sMask, $iDepth, $iExcludeFlag, $iCurD + 1)
;~ 			Else
;~ 				$iPos = StringInStr($sFile, ".", 0, -1)
;~ 				If $iPos And StringInStr($sMask, '|' & StringTrimLeft($sFile, $iPos) & '|') = False Then
;~ 					If $iExcludeFlag = 1 Then
;~ 						For $iEx = 1 To $excl_list[0]
;~ 							If StringInStr($sPath & $sFile, $excl_list[$iEx]) Then ContinueLoop 2
;~ 						Next
;~ 					EndIf
;~ 					$sFileList &= $sPath & $sFile & @CRLF
;~ 				ElseIf Not $iPos Then
;~ 					If $iExcludeFlag = 1 Then
;~ 						For $iEx = 1 To $excl_list[0]
;~ 							If StringInStr($sPath & $sFile, $excl_list[$iEx]) Then ContinueLoop 2
;~ 						Next
;~ 					EndIf
;~ 					$sFileList &= $sPath & $sFile & @CRLF
;~ 				EndIf
;~ 			EndIf
;~ 		WEnd
;~ 		FileClose($s)
;~ 		; MsgBox(64, " Out FileSearchType ", "Mask = " & $sMask & @CRLF & "sFileList = " & $sFileList & @CRLF & "sPath = " & $sPath)
;~ 	EndFunc   ;==>__WOF_FileSearchType
;===================================================================================================
;~ 		Func _FileSearch($sPath, $sFilter = '*.*', $iFlag = 0, $ExcludeFile = '', $iRecurse = True)
;~ 		;===============================================================================
;~ 		;
;~ 		; Description:      lists all or preferred files and or folders in a specified path (Similar to using Dir with the /B Switch)
;~ 		; Syntax:           _FileListToArrayEx($sPath, $sFilter = '*.*', $iFlag = 0, $ExcludeFile = '')
;~ 		; Parameter(s):        $sPath = Path to generate filelist for
;~ 		;                    $sFilter = The filter to use. Search the Autoit3 manual for the word "WildCards" For details, support now for multiple searches
;~ 		;                            Example *.exe; *.txt will find all .exe and .txt files
;~ 		;                   $iFlag = determines weather to return file or folders or both.
;~ 		;                    $ExcludeFile = CustomFile.txt with list of Folders and files to exclude
;~ 		;                     Example: Entry I386\LANG\ will exclude all files from folder LANG
;~ 		;                        $iFlag=0(Default) Return both files and folders
;~ 		;                       $iFlag=1 Return files Only
;~ 		;                        $iFlag=2 Return Folders Only
;~ 		;
;~ 		; Requirement(s):   None
;~ 		; Return Value(s):  On Success - Returns an array containing the list of files and folders in the specified path
;~ 		;                        On Failure - Returns the an empty string "" if no files are found and sets @Error on errors
;~ 		;                        @Error or @extended = 1 Path not found or invalid
;~ 		;                        @Error or @extended = 2 Invalid $sFilter
;~ 		;                       @Error or @extended = 3 Invalid $iFlag
;~ 		;                         @Error or @extended = 4 No File(s) Found
;~ 		;
;~ 		; Author(s):        SmOke_N
;~ 		; Note(s):            The array returned is one-dimensional and is made up as follows:
;~ 		;                    $array[0] = Number of Files\Folders returned
;~ 		;                    $array[1] = 1st File\Folder
;~ 		;                    $array[2] = 2nd File\Folder
;~ 		;                    $array[3] = 3rd File\Folder
;~ 		;                    $array[n] = nth File\Folder
;~ 		;
;~ 		;                    All files are written to a "reserved" .tmp file (Thanks to gafrost) for the example
;~ 		;                    The Reserved file is then read into an array, then deleted
;~ 		;===============================================================================
;~ 		; Modified by wimb for EXCLUDE filelist
;~ 		; $ExcludeFile = CustomFile.txt with list of Folders and files to exclude
;~ 			Local $exfile, $line, $count, $exlist[3000]
;~ 			If $ExcludeFile = -1 Or $ExcludeFile = Default Then $ExcludeFile = ""
;~ 			If $ExcludeFile And FileExists($ExcludeFile) Then
;~ 				$exfile = FileOpen($ExcludeFile, 0)
;~ 				$count = 0
;~ 				While $count < 2999
;~ 					$line = FileReadLine($exfile)
;~ 					If @error = -1 Then ExitLoop
;~ 					If $line <> "" Then
;~ 						$count = $count + 1
;~ 						$line = StringStripWS($line, 3)
;~ 						$exlist[0] = $count
;~ 						$exlist[$count]=$line
;~ 					EndIf
;~ 				Wend
;~ 				FileClose($exfile)
;~ 		;		_ArrayDisplay($exlist)
;~ 			EndIf
		;
;~ 			If Not FileExists($sPath) Then Return SetError(1, 1, '')
;~ 			If $sFilter = -1 Or $sFilter = Default Then $sFilter = '*.*'
;~ 			If $iFlag = -1 Or $iFlag = Default Then $iFlag = 0
;~ 			Local $aBadChar[6] = ['\', '/', ':', '>', '<', '|']
;~ 			$sFilter = StringRegExpReplace($sFilter, '\s*;\s*', ';')
;~ 			If StringRight($sPath, 1) <> '\' Then $sPath &= '\'
;~ 			For $iCC = 0 To 5
;~ 				If StringInStr($sFilter, $aBadChar[$iCC]) Then Return SetError(2, 2, '')
;~ 			Next
;~ 			If StringStripWS($sFilter, 8) = '' Then Return SetError(2, 2, '')
;~ 			If Not ($iFlag = 0 Or $iFlag = 1 Or $iFlag = 2) Then Return SetError(3, 3, '')
;~ 			Local $oFSO = ObjCreate("Scripting.FileSystemObject"), $sTFolder
;~ 			$sTFolder = $oFSO.GetSpecialFolder(2)
;~ 			Local $hOutFile = @TempDir & $oFSO.GetTempName
;~ 			If Not StringInStr($sFilter, ';') Then $sFilter &= ';'
;~ 			Local $aSplit = StringSplit(StringStripWS($sFilter, 8), ';'), $sRead, $sHoldSplit
;~ 			For $iCC = 1 To $aSplit[0]
;~ 				If StringStripWS($aSplit[$iCC],8) = '' Then ContinueLoop
;~ 				If StringLeft($aSplit[$iCC], 1) = '.' And _
;~ 					UBound(StringSplit($aSplit[$iCC], '.')) - 2 = 1 Then $aSplit[$iCC] = '*' & $aSplit[$iCC]
;~ 				$sHoldSplit &= '"' & $sPath & $aSplit[$iCC] & '" '
;~ 			Next
;~ 			$sHoldSplit = StringTrimRight($sHoldSplit, 1)
		;
;~ 			If $iRecurse Then
;~ 				RunWait(@Comspec & ' /c dir /b /s /a ' & $sHoldSplit & ' > "' & $hOutFile & '"', '', @SW_HIDE)
;~ 			Else
;~ 				RunWait(@ComSpec & ' /c dir /b /a ' & $sHoldSplit & ' /o-e /od > "' & $hOutFile & '"', '', @SW_HIDE)
;~ 			EndIf
;~ 			$sRead &= FileRead($hOutFile)
;~ 			If Not FileExists($hOutFile) Then Return SetError(4, 4, '')
;~ 			FileDelete($hOutFile)
;~ 			If StringStripWS($sRead, 8) = '' Then SetError(4, 4, '')
;~ 			Local $aFSplit = StringSplit(StringTrimRight(StringStripCR($sRead), 1), @LF)
;~ 			Local $sHold, $a_AnsiFName
;~ 			For $iCC = 1 To $aFSplit[0]
;~ 				; translate DOS filenames from OEM to ANSI
;~ 				$a_AnsiFName = DllCall('user32.dll','Int','OemToChar','str',$aFSplit[$iCC],'str','')
;~ 				If @error=0 Then $aFSplit[$iCC] = $a_AnsiFName[2]
;~ 				; Exclude Folders and Files from File $ExcludeFile
;~ 				For $iEx = 1 To $exlist[0]
;~ 					; If StringInStr($aFSplit[$iCC], "\" & $exlist[$iEx]) Then ContinueLoop 2
;~ 					If StringInStr($aFSplit[$iCC], $exlist[$iEx]) Then ContinueLoop 2
;~ 				Next
		;
;~ 				Switch $iFlag
;~ 					Case 0
;~ 						; modified by wimb to allow Network Share as XP Source, the double backslash gives problem with the commented code below
;~ 						; If StringRegExp($aFSplit[$iCC], '\w:\\') = 0 Then
;~ 						;    $sHold &= $sPath & $aFSplit[$iCC] & Chr(1)
;~ 						; Else
;~ 						$sHold &= $aFSplit[$iCC] & Chr(1)
;~ 						; EndIf
;~ 					Case 1
;~ 						If StringInStr(FileGetAttrib($sPath & '\' & $aFSplit[$iCC]), 'd') = 0 And _
;~ 							StringInStr(FileGetAttrib($aFSplit[$iCC]), 'd') = 0 Then
;~ 							; If StringRegExp($aFSplit[$iCC], '\w:\\') = 0 Then
;~ 							; 	$sHold &= $sPath & $aFSplit[$iCC] & Chr(1)
;~ 							; Else
;~ 							$sHold &= $aFSplit[$iCC] & Chr(1)
;~ 							; EndIf
;~ 						EndIf
;~ 					Case 2
;~ 						If StringInStr(FileGetAttrib($sPath & '\' & $aFSplit[$iCC]), 'd') Or _
;~ 							StringInStr(FileGetAttrib($aFSplit[$iCC]), 'd') Then
;~ 							; If StringRegExp($aFSplit[$iCC], '\w:\\') = 0 Then
;~ 							;	$sHold &= $sPath & $aFSplit[$iCC] & Chr(1)
;~ 							; Else
;~ 							$sHold &= $aFSplit[$iCC] & Chr(1)
;~ 							; EndIf
;~ 						EndIf
;~ 				EndSwitch
;~ 			Next
;~ 			If StringTrimRight($sHold, 1) Then Return StringSplit(StringTrimRight($sHold, 1), Chr(1))
;~ 			Return SetError(4, 4, '')
;~ 		EndFunc
;===================================================================================================
;~ ; BiatuAutMiahn[@Outlook.com] and Danyfirex have made Func _WinAPI_WofSetCompression - https://www.autoitscript.com/forum/topic/189211-wof-file-set-compression/
;~ ; slightly modified by wimb to use $iFormat, $FSCTL_PAR as parameters to allow different $COMPRESSION_FORMAT and use of $FSCTL_DELETE_EXTERNAL_BACKING for Un-Compressing Files
;~ ; Func _WinAPI_WofSetCompression is working for Un-Compressing Files but may be needs to be further improved for that purpose ....
;~ Func _WinAPI_WofSetCompression($sFilePath, $iFormat, $FSCTL_PAR)
;~     ; Local Const $FILE_FLAG_BACKUP_SEMANTICS = 0x02000000
;~     Local $tFilePath=DllStructCreate("wchar[260]")
;~     Local $tFilePathW=DllStructCreate($sTagUNICODESTRING)
;~     Local $tObjAttr=DllStructCreate($sTagOBJECTATTRIBUTES)
;~     DllStructSetData($tFilePath,1,$sFilePath)
;~     Local $aRet=DllCall($hDll_NTDLL,"none","RtlInitUnicodeString","ptr",DllStructGetPtr($tFilePathW),"ptr",DllStructGetPtr($tFilePath))
;~     DllStructSetData($tObjAttr,"Length",DllStructGetSize($tObjAttr))
;~     DllStructSetData($tObjAttr,"RootDirectory",0)
;~     DllStructSetData($tObjAttr,"ObjectName",DllStructGetPtr($tFilePathW))
;~     DllStructSetData($tObjAttr,"Attributes",$OBJ_CASE_INSENSITIVE)
;~     DllStructSetData($tObjAttr,"SecurityDescriptor",0)
;~     DllStructSetData($tObjAttr,"SecurityQualityOfService",0)
;~     Local $tIOSB=DllStructCreate($sTagIOSTATUSBLOCK)
;~     Local $thFile=DllStructCreate("handle")
;~     Local $phFile=DllStructGetPtr($thFile)
;~     $aRet=DllCall($hDll_NTDLL,"long","NtCreateFile","ptr",$phFile,"ulong",BitOR($GENERIC_READ,$GENERIC_WRITE,0x20),"ptr",DllStructGetPtr($tObjAttr),"ptr",DllStructGetPtr($tIOSB),"int64*",0,"ulong",0,"ulong",$FILE_SHARE_VALID_FLAGS,"ulong",$FILE_OPEN,"ulong",BitOR($FILE_OPEN_FOR_BACKUP_INTENT,$FILE_OPEN_REPARSE_POINT),"ptr",0,"ulong",0)
;~     If @error Or $aRet[0]<>$STATUS_SUCCESS Then Return SetError(@error, @extended, 0)
;~     Local $hFile=DllStructGetData($thFile,1)
;~     Local $tInputBuffer=DllStructCreate("STRUCT;"&$sTagWOF_EXTERNAL_INFO&";ENDSTRUCT;STRUCT;"&$sTagFILE_PROVIDER_EXTERNAL_INFO_V1&";ENDSTRUCT")
;~     DllStructSetData($tInputBuffer,"WOFEI_Version",$WOF_CURRENT_VERSION)
;~     DllStructSetData($tInputBuffer,"WOFEI_Provider",$WOF_PROVIDER_FILE)
;~     DllStructSetData($tInputBuffer,"FPEI_Version",$FILE_PROVIDER_CURRENT_VERSION)
;~     DllStructSetData($tInputBuffer,"FPEI_CompressionFormat",$iFormat)
;~     Local $pInputBuffer=DllStructGetPtr($tInputBuffer)
;~     Local $iInputBuffer=DllStructGetSize($tInputBuffer)
;~     Local $iTried=0, $iRet=0
;~     Do
;~         $iRet=_WinAPI_NtFsControlFile($hFile,$FSCTL_PAR,$pInputBuffer,$iInputBuffer)
;~ 		; MsgBox(64, "Return Value", "$iRet=" & $iRet)
;~         If @error Then Return SetError(@error, @extended, 0)
;~         If $iRet=$STATUS_INVALID_DEVICE_REQUEST And Not $iTried Then
;~             __DriveAttachWOF(__PathGetDrive($sFilePath))
;~             $iTried=1
;~             ContinueLoop
;~         EndIf
;~         $iTried=1
;~     Until $iTried
;~     DllCall($hDll_NTDLL,"long","NtClose","handle",$hFile);close Handle
;~ EndFunc   ;==> _WinAPI_WofSetCompression
;~ ;===================================================================================================
;~ Func _WinAPI_NtFsControlFile($hFile,$iFsControlCode,$pInputBuffer,$iInputBuffer,$pOutputBuffer=0,$iOutputAvail=0)
;~     Local $tIOSB=DllStructCreate($sTagIOSTATUSBLOCK)
;~     Local $pIOSB=DllStructGetPtr($tIOSB)
;~     Local $aRet=DllCall($hDll_NTDLL,"int","NtFsControlFile","HANDLE",$hFile,"ptr",0,"ptr",0,"ptr",0,"ptr",$pIOSB,"uint",$iFsControlCode,"ptr",$pInputBuffer,"uint",$iInputBuffer,"ptr",$pOutputBuffer,"uint",$iOutputAvail)
;~ 	; _ArrayDisplay($aRet)
;~     If @error Or Not $aRet[0] Then Return SetError(@error,@extended,0)
;~     Local $iRet=0, $iError=0
;~     If $aRet[0]=$STATUS_PENDING Then
;~         $iRet=_WinAPI_WaitForSingleObject($hFile)
;~         $iError=_WinAPI_GetLastError()
;~         If Not $iError Then SetError(1,$iError,0)
;~         Return SetError(1,$iRet,0)
;~     EndIf
;~     Return SetError(0,0,$aRet[0])
;~ EndFunc   ;==> _WinAPI_NtFsControlFile
;~ ;===================================================================================================
;~ Func __DriveAttachWOF($sDrive) ; win32_try_to_attach_wof
;~     Local $aRet,$hDll_FltLib
;~     $hDll_FltLib=DllOpen("FltLib.dll")
;~     If @error Then Return SetError(1,0,0)
;~     $aRet=DllCall($hDll_FltLib,"int","FilterAttach","WSTR","wof","wstr",$sDrive,"ptr",0,"int",0,"ptr",0)
;~     If @error Or Not $aRet[0] Then
;~         $aRet=DllCall($hDll_FltLib,"int","FilterAttach","WSTR","wofadk","wstr",$sDrive,"ptr",0,"int",0,"ptr",0)
;~         If @error Or Not $aRet[0] Then Return SetError(@error,@extended,0)
;~     EndIf
;~     DllClose($hDll_FltLib)
;~     Return SetError(0,0,$aRet[0])
;~ EndFunc   ;==> __DriveAttachWOF
;~ ;===================================================================================================
;~ Func __PathGetDrive($sPath)
;~     $sPath=_WinAPI_GetFullPathName($sPath)
;~     If @error Or $sPath="" Then Return SetError(1,0,0)
;~     Local $aTest=StringRegExp($sPath,"^([A-Za-z]\:).*$",1)
;~     If @error Then Return SetError(1,0,0)
;~     Return SetError(0, 0,"\\.\" & StringLower($aTest[0]))
;~ EndFunc   ;==> __PathGetDrive
;~ ;===================================================================================================
