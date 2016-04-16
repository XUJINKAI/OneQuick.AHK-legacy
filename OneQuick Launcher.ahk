program_icon := "icon/1.ico"
program_name := "OneQuick"
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
		run AutoHotkey.exe %program_name%.ahk
	}
	catch e
	{
		Gosub, ask_open_ahk_org
		ExitApp
	}
}
ExitApp

ask_open_ahk_org:
msg = Please install Autohotkey first. `nClick YES to open autohotkey.org
msgbox, 0x4, %program_name%, % msg
ifmsgbox Yes
{
	run, http://autohotkey.org
}
ExitApp