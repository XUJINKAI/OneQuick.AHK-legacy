/*
	@author: XJK
	@github: https://github.com/XUJINKAI/OneQuick
*/

#NoTrayIcon
#SingleInstance force
#Include, AHK\compile.ahk
SetWorkingDir, %A_ScriptDir%

ProgramName = "OneQuick"
program_icon := "icon/1.ico"
OneQuickAHKPath := "script/OneQuick.ahk"
AHK_installer := "AHK\setup.exe"

if not A_IsCompiled
{
	compile_ahk(A_ScriptName, program_icon)
	ExitApp
}

Run, AutoHotkey.exe %OneQuickAHKPath%, , UseErrorLevel
if ErrorLevel = Error
{
	Gosub, SUB_AHK_INSTALL
}
ExitApp

SUB_AHK_INSTALL:
msg = Install Autohotkey?`n`n安装Autohotkey吗?
msgbox, 0x24,, % msg
IfMsgBox, NO
{
	ExitApp
}

RunWait, %AHK_installer% /S "%A_ScriptFullPath%",, UseErrorLevel
if ErrorLevel = ERROR
{
	MsgBox, 0x30, %ProgramName%, Run %AHK_installer% ERROR.
	ExitApp
}

MsgBox, 0x0, , autohotkey installing...
