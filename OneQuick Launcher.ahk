program_icon := "icon/1.ico"
program_name := "OneQuick"
script_folder := "script/"
AHK_installer := A_ScriptDir "\AHK\AutoHotkey_Install.exe"
AHK_UIAccess := A_ScriptDir "\AHK\EnableUIAccess2AHK.ahk"
#NoTrayIcon

SetWorkingDir, %A_ScriptDir%

if not A_IsCompiled
{
	splitpath, a_ahkpath, , ahk_dir
	Ahk2Exe := ahk_dir "\Compiler\Ahk2Exe.exe"
	u32bin := ahk_dir "\Compiler\Unicode 32-bit.bin"
	if not FileExist(Ahk2Exe)
		MsgBox, can't find Compiler\Ahk2Exe.exe to compile
	else if not FileExist(u32bin)
		MsgBox, can't find Compiler\Unicode 32-bit.bin to compile
	Else
	{
		launcher_exe_name := SubStr(A_ScriptName, 1, StrLen(A_ScriptName) - 4) . ".exe"
		FileDelete, % launcher_exe_name
		run, %Ahk2Exe% /in "%A_ScriptName%" /icon "%program_icon%" /bin "%u32bin%"
	}
}
Else
{
	try
	{
		run AutoHotkey.exe %script_folder%%program_name%.ahk
	}
	catch e
	{
		Gosub, ahk_not_find
		ExitApp
	}
}
ExitApp

ahk_not_find:
msg = Please install Autohotkey first. `n`n需要先安装Autohotkey.
msgbox, 0x0, %program_name%, % msg
if(FileExist(AHK_installer)) {
	RunWait, % AHK_installer,, UseErrorLevel
	RunWait, % AHK_UIAccess,, UseErrorLevel
}
else {
	run, http://autohotkey.com
}
ExitApp