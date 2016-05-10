/*
	@author: XJK
	@github: https://github.com/XUJINKAI

	OneQuick User Guide
*/

SplitPath, A_ScriptDir, , workdir
SetWorkingDir, %workdir%
#NoTrayIcon
#Include %A_ScriptDir%
#Include OneQuick.Core.ahk

msg_hello = 
(
欢迎使用OneQuick，
OneQuick是一款快捷键工具，通过一个简单的配置文件，
你可以得到屏幕边缘操作，剪贴板记录，快速搜索等诸多增强功能。
)

guide_obj := [["", msg_hello]
			,["", "尝试一下：将鼠标移到屏幕左上角并滚动滚轮,`n效果：快速调节音量"]
			,["", "尝试一下：将鼠标移到屏幕左或右边缘，然后滚轮,`n效果：翻页（相当于PageUp或PageDown）"]
			,["", "最后，右击托盘图标，`n你可以`n 查看在线帮助, 了解更多功能、`n 让OneQuick随系统启动、`n 打开功能配置文件、`n ...。`n祝使用愉快~"]]
parse_guide_obj(guide_obj)
ExitApp

parse_guide_obj(obj)
{
	Loop, % obj.MaxIndex()
	{
		line := obj[A_Index]
		m(line[2])
	}
}
