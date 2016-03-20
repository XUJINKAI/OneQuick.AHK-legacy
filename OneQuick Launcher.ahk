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
		if FileExist("AutoHotkeyU64.exe")
		{
			try
			{
				run AutoHotkeyU64.exe %program_name%.ahk
				ExitApp
			}
			catch
			{ }
		}
		if FileExist("AutoHotkeyU32.exe")
			run AutoHotkeyU32.exe %program_name%.ahk
		else if FileExist("AutoHotkeyA32.exe")
			run AutoHotkeyA32.exe %program_name%.ahk
		else
			msgbox, can't find AutoHotkey.exe to launch
	}
}

ExitApp