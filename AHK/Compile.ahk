/*
	@author: XJK
	@github: https://github.com/XUJINKAI/OneQuick
*/

compile_ahk(target, icon="")
{
	splitpath, a_ahkpath, , ahk_dir
	Ahk2Exe := ahk_dir "\Compiler\Ahk2Exe.exe"
	u32bin := ahk_dir "\Compiler\Unicode 32-bit.bin"
	if not FileExist(Ahk2Exe)
		MsgBox, can't find Compiler\Ahk2Exe.exe
	else if not FileExist(u32bin)
		MsgBox, can't find Compiler\Unicode 32-bit.bin
	Else
	{
		if(icon=="") {
			run, %Ahk2Exe% /in "%target%" /bin "%u32bin%"
		}
		else {
			run, %Ahk2Exe% /in "%target%" /icon "%icon%" /bin "%u32bin%"
		}
	}
}