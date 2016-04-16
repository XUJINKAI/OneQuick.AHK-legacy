/*
@author: XJK
@github: https://github.com/XUJINKAI

OneQuick starts here, features config file
OneQuick 配置、运行文件
*/

; the following two lines is necessary to initialize OneQuick class
#Include, OneQuick.Core.ahk
OneQuick.Ini()

/*
以下为剪贴板增强功能的定义
定义了ctrl + shift + x/c/v 三个快捷键

xClipboard class is a useful Clipboard enhance class,
it provides history list, quick search list, favourite list, etc..

xClipboard.SetHotkey(HistoryList, CopyAndShowList, CurrentList)
sets three hotkeys, in this case:
** ctrl + shift + x   open a history list
** ctrl + shift + c   do a copy action first and then shows a search list
** ctrl + shift + v   show search list for current clipboard content without copy action

xClipboard.SetSearchList([[key, name, website],[...]])
sets search list, %s in each string will be replaced by the content
*/
xClipboard.SetHotkey("^+x", "^+c", "^+v")
xClipboard.SetBrowserList([["1","Default",""],["2","Edge","microsoft-edge:"],["3","Chrome","chrome.exe"],["4","IE","iexplore.exe"]])
xClipboard.SetSearchList([["g","Google","https://www.google.com/search?q=%s"]
	,["b","百度","http://www.baidu.com/s?wd=%s"]
	,["","百度local","http://www.baidu.com/s?wd=%s&tn=baidulocal"]
	,["w","微博","http://s.weibo.com/weibo/%s"]
	,["z","知乎","http://www.zhihu.com/search?q=%s"]
	,["k","果壳","http://www.guokr.com/search/all/?wd=%s"]
	,["l","哔哩哔哩","http://www.bilibili.com/search?keyword=%s"]
	,["a","Acfun","http://www.acfun.tv/search/#query=%s"]
	,["y","Youtube","https://www.youtube.com/results?search_query=%s"]
	,["","网易云音乐","http://music.163.com/#/search/m/?s=%s&type=1"]
	,["m","豆瓣电影","http://movie.douban.com/subject_search?search_text=%s"]
	,["q","QR-Code","http://api.qrserver.com/v1/create-qr-code/?data=%s"]])


/*
以下为超级菜单的自定义代码
由xMenu模块可以方便地注册自定义菜单
并由xMenu.Show()函数显示出来

xMenu class can help register menus

xMenu.Add(MenuName, [[itemName, Action],[...]])
Action can be a label name, function name, even a submenu object, or any command runs in system cmd
you can read the comments above run() function in OneQuick.Core.ahk for more information

after you register a menu, you can use
---- xMenu.Show(MenuName) ----
to show the menu you registered
*/
xMenu.Add("System"
	,[["Task Schdule","Taskschd.msc"]
	,["Services","services.msc"]
	,[]
	,["Regedit","regedit"]
	,["gpedit.msc","gpedit.msc"]
	,[]
	,["Edit HOSTS","Sys.Network.EditHOSTS"]
	,["Flush DNS","ipconfig /flushdns"]])

xMenu.Add("QuickAppMenu"
	,[["Notepad","notepad"]
	,["Paint","mspaint"]
	,["Calculator","calc"]
	,[]
	,["Screen Keyboard","osk"]])

xMenu.Add("GreatMenu"
	,[["xClipboard`t&x","xClipboard.ShowAllClips"]
	,["Window Info","WinMenu.Show"]
	,["Cursor Info`t&i","Sys.Cursor.Info"]
	,[]
	,["Quick Apps`t&a",,{"sub":"QuickAppMenu"}]
	,[]
	,["Screen`t&s"
		,[["Monitor off`t&c","Sys.Screen.Off"]
		,["Lock && MonitorOff`t&l","Sys.Power.LockAndMonitoroff"]]]
	,["System",,{"sub":"System"}]])

; move mouse to top-right of screen and right click, this menu shows
; 鼠标移到屏幕右上角并右击时出现的菜单
xMenu.Add("ScreenRTMenu"
	,[["Task Manager","taskmgr"]
	,["Resource Monitor","resmon"]
	,["System",,{"sub":"System"}]])

/*
以上为程序初始化时运行的代码，只运行一次

Code above runs just once after OneQuick launch.
the following code defines hotkeys,
they run when you press the hotkey
*/
; make sure codes below will not run when OneQuick start
Return


; //////////////////////////////////////////////
/*
以下是快捷键的定义
shortcuts definitions
*/
; //////////////////////////////////////////////

#t::Sys.Win.Topmost()
#rbutton up::WinMenu.Show()
+wheelup::send {PgUp}
+wheeldown::send {PgDn}
#n::run notepad
$^w::ctrl_w_close_notepad()
#+l::Sys.Power.LockAndMonitoroff()
#z::xMenu.Show("GreatMenu", A_ScreenWidth/2, A_ScreenHeight/2)
<^<!r::OneQuick.Command_run()
^+!r::Reload


ctrl_w_close_notepad()
{
	if(WinActive("ahk_class Notepad"))
	{
		Winclose, A
	}
	else
	{
		send ^w
	}
}


; //////////////////////////////////////////////////////
; 应用增强
; app enhancement
; //////////////////////////////////////////////////////

/*
在chrome标签上滚动滚轮，可切换标签（在不是最大化时仍可用）
scroll on chrome tab to go next/prev tab
*/
#if OnScrollChromeTab() && (!Sys.Cursor.IsPos("LT") && !Sys.Cursor.IsPos("RT"))
wheelup::send ^{PgUp}
wheeldown::send ^{PgDn}
#if
OnScrollChromeTab()
{
	if not WinActive("ahk_class Chrome_WidgetWin_1")
		return 0
	MouseGetPos, X, Y
	WinGetPos, wX, wY, wW, wH , A
	if ( X > 0 and X < wW and Y-wY > 0 and Y-wY < 45 )
		return 1
	else 
		return 0
}

/*
使用sublime时，按win+E 打开当前正在编辑的文件的目录
win + E: (when sublime active) open current edit file folder
*/
#e::
title := Sys.Win.Title()
if(RegExMatch(title, "^(.*)\\.*- Sublime Text", t))
	run(t1)
Else
	run("explorer")
return

; //////////////////////////////////////////////////////
/*
屏幕边角操作
默认定义为8个pixel内
screen border definition
*/
; //////////////////////////////////////////////////////

; ///////////////
; Left Top
#if Sys.Cursor.IsPos("LT")
wheelup::send {volume_up}
wheeldown::send {volume_down}
mbutton::
keywait, mbutton, u
if not Sys.Cursor.IsPos("LT")
	return
send {volume_mute}
return

+wheelup::Sys.Screen.Brightness(+2)
+wheeldown::Sys.Screen.Brightness(-2)

RButton Up::WinMenu.Show()
#if

; ///////////////
; Right Top
#if Sys.Cursor.IsPos("RT")
rbutton::xMenu.Show("ScreenRTMenu")

/*
#InputLevel 提高{media_play_pause}和另外两个命令的优先级，
这样，只要在别处定义
$media_play_pause::
......
这样的命令，就可以全局改变media_play_pause的行为，
比如针对不同的播放器发送不同的命令
*/
#InputLevel 1
wheelup::send {media_prev}
wheeldown::send {media_next}
mbutton::
keywait, mbutton, u
if not Sys.Cursor.IsPos("RT")
	return
send {media_play_pause}
return
#InputLevel 0

#if

; ///////////////
; Left or Right
#if Sys.Cursor.IsPos("L") || Sys.Cursor.IsPos("R")
wheelup::send {pgup}
wheeldown::send {pgdn}
+wheelup::send {pgup}{pgup}{pgup}{pgup}{pgup}
+wheeldown::send {pgdn}{pgdn}{pgdn}{pgdn}{pgdn}
^+wheelup::send {home}
^+wheeldown::send {end}
#if

; ///////////////
; Top
#if Sys.Cursor.IsPos("T")
wheelup::Sys.Win.GotoPreTab()
wheeldown::Sys.Win.GotoNextTab()
#if

; ///////////////
; Bottom
#if Sys.Cursor.IsPos("B")
wheelup::send ^#{Left}
wheeldown::send ^#{Right}
mbutton::
keywait, mbutton, u
if not Sys.Cursor.IsPos("B")
	return
send #{tab}
return
#if
