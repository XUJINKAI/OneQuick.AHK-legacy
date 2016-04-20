/*
	@author: XJK
	@github: https://github.com/XUJINKAI

	OneQuick starts here, features config file
	OneQuick 配置、运行文件
*/

; the following lines is necessary to initialize OneQuick class

; set workdir always be ../
SplitPath, A_ScriptDir, , workdir
SetWorkingDir, %workdir%
; include core file
#Include, %A_ScriptDir%
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
if(OneQuick.Setting("clipboard.switch", 1))
{
	; 快捷键设置
	xClipboard.SetHotkey("^+x", "^+c", "^+v")
	; 浏览器
	xClipboard_browser_obj := { default: [0,"Default",""]
		,edge: [1,"Edge","microsoft-edge:"]
		,chrome: [2,"Chrome","chrome.exe"]
		,ie: [3,"IE","iexplore.exe"]}
	xClipboard_browser_setting := OneQuick.Setting("clipboard.browser", "Default, Edge, Chrome, IE")
	xClipboard.SetBrowserList(list_filter(xClipboard_browser_obj, xClipboard_browser_setting))
	; 快速搜索列表
	xClipboard_search_obj := { google: ["g","Google","https://www.google.com/search?q=%s"]
		,baidu: ["b","百度","http://www.baidu.com/s?wd=%s"]
		,baidu_local: ["","百度local","http://www.baidu.com/s?wd=%s&tn=baidulocal"]
		,weibo: ["w","微博","http://s.weibo.com/weibo/%s"]
		,zhihu: ["z","知乎","http://www.zhihu.com/search?q=%s"]
		,guokr: ["k","果壳","http://www.guokr.com/search/all/?wd=%s"]
		,bilibili: ["l","哔哩哔哩","http://www.bilibili.com/search?keyword=%s"]
		,Acfun: ["a","Acfun","http://www.acfun.tv/search/#query=%s"]
		,Youtube: ["y","Youtube","https://www.youtube.com/results?search_query=%s"]
		,netease_music: ["","网易云音乐","http://music.163.com/#/search/m/?s=%s&type=1"]
		,douban_movie: ["m","豆瓣电影","http://movie.douban.com/subject_search?search_text=%s"]
		,QR_code: ["q","QR-Code","http://api.qrserver.com/v1/create-qr-code/?data=%s"] }
	xClipboard_search_setting := OneQuick.Setting("clipboard.search", "google, baidu, baidu_local, weibo, zhihu, guokr, bilibili, acfun, youtube, netease_music, douban_movie, qr_code")
	xClipboard.SetSearchList(list_filter(xClipboard_search_obj, xClipboard_search_setting))
	; set default list
	OneQuick.SetSetting("clipboard.browser_default", obj_key_list(xClipboard_browser_obj))
	OneQuick.SetSetting("clipboard.search_default", obj_key_list(xClipboard_search_obj))
}

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

; 两个函数供调用
xmenu_show_great_menu()
{
	xMenu.Show("GreatMenu", A_ScreenWidth/2, A_ScreenHeight/2)
}
xmenu_show_screen_rt_menu()
{
	xMenu.Show("ScreenRTMenu")
}


/*
以下是快捷键的定义
shortcuts definitions
*/
; 记录快捷键与对应操作
HOTKEY_REGISTER_LIST := {}

; 把两个字符串数组交叉连接起来
str_array_concate(arr, app, deli="")
{
	ret := []
	if(arr.MaxIndex()=="") {
		arr := [arr]
	}
	if(app.MaxIndex()=="") {
		app := [arr]
	}
	Loop, % arr.MaxIndex() {
		idx1 := A_Index
		Loop, % app.MaxIndex() {
			idx2 := A_Index
			ret.insert(arr[idx1] deli app[idx2])
		}
	}
	return % ret
}

register_hotkey(key_name, action, prefix="")
{
	global HOTKEY_REGISTER_LIST
	trans_key := []
	map1 := {win: "#", ctrl: "^", shift: "+", alt: "!"
			,lwin: "<#", rwin: ">#"
			,lctrl: "<^", rctrl: ">^"
			,lshift: "<+", rshift: ">+"
			,lalt: "<!", ralt: ">!"
			,lclick:  "LButton", rclick:  "RButton", wheelclick: "MButton" }
			; ,wheel: ["wheelUp", "wheelDown"] }
	key_split_arr := StrSplit(key_name, "_")
	Loop, % key_split_arr.MaxIndex()
	{
		cur_symbol := key_split_arr[A_Index]
		maped_symbol := map1[cur_symbol]
		if(maped_symbol=="") {
			trans_key := str_array_concate(trans_key, [cur_symbol])
		}
		else if(IsObject(maped_symbol)) {
			trans_key := str_array_concate(trans_key, maped_symbol)
		}
		else {
			trans_key := str_array_concate(trans_key, [maped_symbol])
		}
	}
	prefix_arr := StrSplit(prefix, "-")
	prefix_trans_keys := str_array_concate(prefix_arr, trans_key, "|")
	Loop, % prefix_trans_keys.MaxIndex()
	{
		key := prefix_trans_keys[A_Index]
		StringUpper, key, key
		HOTKEY_REGISTER_LIST[key] := action
		arr := StrSplit(key, "|")
		if(arr[1]!="") {
			Hotkey, IF, border_event_evoke()
			Hotkey, % arr[2], SUB_HOTKEY_ZONE_BORDER
		}
		else {
			Hotkey, IF
			Hotkey, % arr[2], SUB_HOTKEY_ZONE_ANYWAY
		}
	}
}

/*
普通快捷键
*/
if(OneQuick.Setting("hotkey.switch", 1))
{
	For key, value in OneQuick.Setting("hotkey.buildin", {}, False)
		register_hotkey(key, value, "")
}

/*
屏幕边缘操作
*/
if(OneQuick.Setting("screen-border.switch", 1))
{
	For border_key, border_action in OneQuick.Setting("screen-border.action", {}, False)
		for key, value in border_action
			register_hotkey(key, value, border_key)
}

/*
setting rember
*/
SETTING_REM := { notepad_ctrl_w_close: OneQuick.Setting("app_enhance.notepad_ctrl_w_close", 1)
				,chrome_scroll_tab: OneQuick.Setting("app_enhance.chrome_scroll_tab", 1)
				,sublime_file_folder: OneQuick.Setting("app_enhance.sublime_file_folder", 1) }


; ////////////////////////////////////////////////////////////////
/*
以上为程序初始化时运行的代码，只运行一次

Code above runs just once after OneQuick launch.
the following code defines hotkeys,
they run when you press the hotkey
make sure codes below will not run when OneQuick start
*/
Return
; ////////////////////////////////////////////////////////////////

/*
; HOTKEY evoke
*/
SUB_HOTKEY_ZONE_ANYWAY:
SUB_HOTKEY_ZONE_BORDER:
border_code := Sys.Cursor.CornerPos()
action := HOTKEY_REGISTER_LIST[border_code "|" A_ThisHotkey]
if(action=="") {
	run(HOTKEY_REGISTER_LIST["|" A_ThisHotkey])
}
else {
	run(action)
}
Return

#IF border_event_evoke()
#IF

border_event_evoke()
{
	global HOTKEY_REGISTER_LIST
	border_code := Sys.Cursor.CornerPos()
	key := border_code "|" A_ThisHotkey
	StringUpper, key, key
	action := HOTKEY_REGISTER_LIST[key]
	if(action!="")
		return true
}


/*
// from old version
#InputLevel 提高{media_play_pause}和另外两个命令的优先级，
这样，只要在别处定义
$media_play_pause::
......
这样的命令，就可以全局改变media_play_pause的行为，
比如针对不同的播放器发送不同的命令
*/

; ////////////////////////////////////////////////////////////////
/*
; 应用增强
; app enhancement
*/

/*
ctrl + w 关闭记事本
*/
#if SETTING_REM["notepad_ctrl_w_close"]
$^w::ctrl_w_close_notepad()
#if

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

/*
在chrome标签上滚动滚轮，可切换标签（在不是最大化时仍可用）
scroll on chrome tab to go next/prev tab
*/
#if SETTING_REM["chrome_scroll_tab"] && OnScrollChromeTab() && (!Sys.Cursor.IsPos("LT") && !Sys.Cursor.IsPos("RT"))
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
#if SETTING_REM["sublime_file_folder"]
#e::
title := Sys.Win.Title()
if(RegExMatch(title, "^(.*)\\.*- Sublime Text", t))
	run(t1)
Else
	run("explorer")
return
#if

; //////////////////////////////////////////////////////////////
/*
辅助函数
*/
; 从列表中把指定项过滤出来 
list_filter(obj, fil_str){
	fil_arr := StrSplit(fil_str, ",", " ")
	ret := []
	Loop, % fil_arr.MaxIndex()
	{
		cur := fil_arr[A_Index]
		if(cur == "" || obj[cur]=="") {
			Continue
		}
		ret.insert(obj[cur])
	}
	return ret
}
; 将key连成string
obj_key_list(obj)
{
	str := ""
	For key, val in obj
		str .= key ", "
	return SubStr(str, 1, StrLen(str)-2)
}
