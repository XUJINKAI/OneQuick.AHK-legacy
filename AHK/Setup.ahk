/*
	@author: XJK
	@github: https://github.com/XUJINKAI/OneQuick
*/
#NoTrayIcon
#SingleInstance force
#Include, Compile.ahk
SetWorkingDir, %A_ScriptDir%

para1 = %1%
para2 = %2%
silent := para1=="/S"
callback := para2

if not A_IsCompiled
{
	compile_ahk(A_ScriptName)
	ExitApp
}

if(!silent)
{
	msg = Install Autohotkey? `n`n安装Autohotkey吗?
	msgbox, 0x24,, % msg
	IfMsgBox, NO
	{
		ExitApp
	}
}

if(!A_IsAdmin)
{
    Run *RunAs %A_ScriptFullPath% /S "%para2%",, UseErrorLevel
    ExitApp
}

; run installer silent
RunWait, AutoHotkey_Install.exe /S,, UseErrorLevel

; enable UIAccess
RunWait, Autohotkey.exe EnableUIAccess2AHK.ahk /S,, UseErrorLevel

if(callback!="")
{
	Run, %callback%,, UseErrorLevel
}
else
{
	msgbox, 0x20,, Autohotkey Installed.
}
ExitApp