/*
	@author: XJK
	@github: https://github.com/XUJINKAI/OneQuick
	请保留作者信息。please retain author information.

	此文件是OneQuick的核心，定义了几个主要功能的class，
	此文件的内容不会直接执行，需要OneQuick.ahk引用并依需要的功能启动，
	所以一般无需修改此文件，也欢迎上github提交完善此项目。

	This is main class file of OneQuick, you need NOT modify it generally.
	you can pull requests in github for this project.
*/

; with this label, you can include this file on top of the file
if(A_ScriptName=="OneQuick.Core.ahk") {
	ExitApp
}
Goto, SUB_ONEQUICK_FILE_END_LABEL
#Persistent
#SingleInstance force
#MaxHotkeysPerInterval 200
#MaxThreads, 255
#MaxThreadsPerHotkey, 20
; JSON.ahk From
; https://github.com/cocobelgica/AutoHotkey-JSON
#Include, JSON.ahk
; https://github.com/HotKeyIt/Yaml
; https://autohotkey.com/board/topic/65582-ahk-lv2-yaml-yaml-parser-json/
#Include, Yaml.ahk
; 
#Include, ../
#Include, *i OneQuick.Ext.ahk
#Include, %A_ScriptDir%
; /////////////////////////////////////
/*
OneQuick
*/
class OneQuick
{
	; debug
	static _DEBUG_ := false
	static _DEBUG_LOAD_DEFAULT_YAML_ := false
	; dir
	static _MAIN_WORKDIR := ""
	static _JSON_DIR := "data/"
	static _ICON_DIR := "icon/"
	static _LANG_DIR := "lang/"
	static _SCRIPT_DIR := "script/"
	; file
	static Launcher_Name := A_WorkingDir "\OneQuick Launcher.exe"
	static Ext_ahk_file := OneQuick._MAIN_WORKDIR "OneQuick.Ext.ahk"
	static version_yaml_file := OneQuick._MAIN_WORKDIR OneQuick._SCRIPT_DIR "version.yaml"
	static feature_yaml_file := OneQuick._MAIN_WORKDIR "OneQuick.feature.yaml"
	static feature_yaml_default_file := OneQuick._MAIN_WORKDIR OneQuick._SCRIPT_DIR "OneQuick.feature.default.yaml"
	static config_file := OneQuick._MAIN_WORKDIR "config.ini"
	static user_data_file := OneQuick._MAIN_WORKDIR OneQuick._JSON_DIR "OneQuick.Data." A_ComputerName ".json"
	static icon_default := OneQuick._MAIN_WORKDIR OneQuick._ICON_DIR "1.ico"
	static icon_suspend := OneQuick._MAIN_WORKDIR OneQuick._ICON_DIR "2.ico"
	static icon_pause := OneQuick._MAIN_WORKDIR OneQuick._ICON_DIR "4.ico"
	static icon_suspend_pause := OneQuick._MAIN_WORKDIR OneQuick._ICON_DIR "3.ico"
	; remote
	static remote_version_yaml := "http://raw.githubusercontent.com/XUJINKAI/OneQuick/master/script/version.yaml"
	static remote_release := "https://github.com/XUJINKAI/OneQuick/releases"
	static remote_help := "https://github.com/XUJINKAI/OneQuick/wiki"
	
	;
	; setting object (read only, for feature configuration)
	static FeatureObj =
	; version object (read only, for check update)
	static versionObj =
	; running user data (e.g. clipboard history), read after run & write before exit
	static UserData := {}
	; callback
	static OnExitCmd := []
	static OnClipboardChangeCmd := []
	static OnPauseCmd := []
	static OnSuspendCmd := []
	; static var
	static ProgramName := "OneQuick"
	static Default_lang := "cn"
	static Editor =
	static Browser := ""
	; var/switch
	static alreay_traytip_newversion := false

	Ini()
	{
		SetBatchLines, -1   ; maximize script speed!
		SetWinDelay, -1
		CoordMode, Mouse, Screen
		CoordMode, ToolTip, Screen
		CoordMode, Menu, Screen
		; setting
		this.LoadFeatureYaml()
		; load version yaml file
		this.versionObj := Yaml(this.version_yaml_file)
		; program running cache/variable
		this.LoadUserData()

		; register onexit sub
		OnExit, Sub_OnExit
		; save user data when exit
		this.OnExit("OneQuick.SaveUserData")
		this.OnExit("OneQuick.CheckAutorun")

		; %systmeroot% can't give to this.Editor directly
		if(this.Editor = "")
		{
			defNotepad = %SystemRoot%\notepad.exe
			this.Editor := defNotepad
		}

		; initialize
		this.SetIcon(this.icon_default)
		this.Update_Tray_Menu()
		this.CheckAutorun()
		this.Show_traytip_update()
		; guide
		this.Check_First_Time_Run()
		; 检查更新
		; wait running traytip dispear
		SetTimer, Sub_Auto_Check_update, -7000

		; class initialize
		xClipboard.Ini()
		WinMenu.Ini()
		; Create a OneQuick.Ext.ahk file
		; and add a User_ComputerName class
		this.Run_ext_user_ini()
	}

	Show_traytip_update()
	{
		msg_running := lang("traytip_runing", "OneQuick running...")
		local_rem_new_version := this._get_Local_Rem_New_Version()
		if(local_rem_new_version!="") {
			msg := lang("new_version_traytip", "New version!")
			TrayTip, OneQuick, % msg_running "`n" msg, 1
			this.alreay_traytip_newversion := true
		}
		else {
			TrayTip, OneQuick, % msg_running, 1
		}
	}

	; version
	static _local_rem_new_version_str := ""
	_set_Local_Rem_New_Version(ver)
	{
		OneQuick._local_rem_new_version_str := ver
		OneQuick.Update_Tray_Menu()
		OneQuick.SetConfig("msgbox_tip_version", ver)
	}
	_get_Local_Rem_New_Version()
	{
		this_version := this.versionObj["version"]
		rem_version := this.GetConfig("msgbox_tip_version")
		OneQuick._local_rem_new_version_str := this._version_bigger(OneQuick._local_rem_new_version_str, this_version)
		OneQuick._local_rem_new_version_str := this._version_bigger(OneQuick._local_rem_new_version_str, rem_version)
		if(OneQuick._local_rem_new_version_str==this_version) {
			return ""
		}
		return % OneQuick._local_rem_new_version_str
	}

	Check_First_Time_Run()
	{
		skip_guide := OneQuick.GetConfig("skip_guide")
		if(!skip_guide) {
			this.User_Guide()
			OneQuick.SetConfig("skip_guide", 1)
		}
	}

	User_Guide()
	{
		m("Welcome!")
		msg := lang("first_time_readme_or_online_for_more_info", "you can read README.md or go to project's home page for more information.")
		m(msg)
		ftmsg := lang("first_time_open_readme", "Open Readme file?")
		MsgBox, 0x44, OneQuick, % ftmsg
		IfMsgBox, Yes
		{
			this.Edit("README.md")
		}
		msg := lang("first_time_right_click_tray_for_help", "You can right click on tray icon for more help.")
		m(msg)
	}

	Run_ext_user_ini()
	{
		user_str := "User_" A_ComputerName
		StringReplace, user_str, user_str, - , _, All
		user_str := RegExReplace(user_str, "[^a-zA-Z0-9_]")
		if IsFunc(user_str ".Ini")
		{
			%user_str%.Ini()
		}
		Else
		{
			str := "`nclass " user_str "`n{`n`tIni()`n`t{`n`n`t}`n}`n`n"
			FileAppend, % str, % this.Ext_ahk_file
		}
	}

	_Debug_version()
	{
		; onequick._Debug_version
		fake_type := 2
		OneQuick.SetConfig("msgbox_tip_version", "")
		; fake remote
		if(fake_type==1) {
			fake_version := {"version": "1.3.1"
				,"desc-major": "超级无敌大更新1<br>123"
				,"desc-minor": "超级无敌大更新2<br>456"
				,"desc-build": "超级无敌大更新3<br>789" }
			this._update_version_info(this.versionObj, fake_version)
		}
		; fake local
		else if (fake_type==2) {
			fake_version := {"version": "0.0.0"
				,"desc-major": "will-not-show"
				,"desc-minor": "will-not-show"
				,"desc-build": "will-not-show" }
			this._update_version_info(fake_version, this.versionObj)
		}
	}

	Check_update(show_msg=true)
	{
		; OneQuick.Check_update
		Try
		{
			oHttp := ComObjCreate("WinHttp.Winhttprequest.5.1")
			oHttp.open("GET", this.remote_version_yaml)
			oHttp.send()
			remoteVersionObj := Yaml(oHttp.responseText, 0)
			this._update_version_info(this.versionObj, remoteVersionObj, show_msg)
		}
		catch
		{
			if(show_msg) {
				msg := lang("update_http_error", "Sorry, can't connect network.")
				m(msg)
			}
		}
	}

	_update_version_info(thisVerObj, remoteVerObj, show_msg=true)
	{
		this_version := thisVerObj["version"]
		remote_version := remoteVerObj.version
		remote_desc1 := remoteVerObj["desc-major"]
		remote_desc2 := remoteVerObj["desc-minor"]
		remote_desc3 := remoteVerObj["desc-build"]
		StringReplace, remote_desc1, % remote_desc1, <br>, `n, All
		StringReplace, remote_desc2, % remote_desc2, <br>, `n, All
		StringReplace, remote_desc3, % remote_desc3, <br>, `n, All
		version_compare := this._version_first_larger(remote_version, this_version)
		if(version_compare > 0)
		{
			msg := lang("new_version_traytip", "New version!")
			msgbox_tip_version := OneQuick.GetConfig("msgbox_tip_version")
			if(this._version_first_larger(remote_version, msgbox_tip_version) > 0)
			{
				if(version_compare < 3)
				{
					update_version_str := "v" this_version " -> v" remote_version
					update_title := "OneQuick Update!"
					update_msg := lang("update_msg", "OneQuick has a new version, open browser?")
					update_msg .= "`n" update_version_str
					update_msg .= "`n`n" lang("update_desc", "update log:")
					if(version_compare==1) {
						update_msg .= "`n" remote_desc1
					}
					else if(version_compare==2) {
						update_msg .= "`n" remote_desc2
					}
					else if(version_compare==3) {
						update_msg .= "`n" remote_desc3
					}
					MsgBox, 0x44, % update_title, % update_msg
					IfMsgBox, Yes
					{
						run(this.remote_release)
					}
				}
			}
			OneQuick._set_Local_Rem_New_Version(remote_version)
		}
		else if(show_msg) {
			msg := lang("update_no_newer_ver", "this is the newest version.")
			if(this._version_first_larger(this_version, remote_version)) {
				msgxxx := "`n你已经超过了作者...`n佩服..."
			}
			m(msg "`nv" this_version " -> v" remote_version msgxxx)
		}
	}

	_version_bigger(ver1, ver2)
	{
		if(this._version_first_larger(ver1, ver2) > 0) {
			return ver1
		}
		else {
			Return ver2
		}
	}

	_version_first_larger(version1, version2)
	{
		ver1 := StrSplit(version1, ".")
		ver2 := StrSplit(version2, ".")
		if(ver1[1] > ver2[1]) {
			return 1
		}
		else if(ver1[1] = ver2[1]) {
			if(ver1[2] > ver2[2]) {
				return 2
			}
			else if(ver1[2] = ver2[2]) {
				if(ver1[3] > ver2[3]) {
					return 3
				}
			}
		}
		return 0
	}

	GetFeatureCfg(keyStr, default="")
	{
		keyArray := StrSplit(keyStr, ".")
		obj := OneQuick.FeatureObj
		Loop, % keyArray.MaxIndex()-1
		{
			cur_key := keyArray[A_Index]
			obj := obj[cur_key]
		}
		cur_key := keyArray[keyArray.MaxIndex()]
		if(obj[cur_key]=="")
		{
			return default
		}
		return obj[cur_key]
	}

	LoadFeatureYaml()
	{
		if(this._DEBUG_ && this._DEBUG_LOAD_DEFAULT_YAML_) {
			OneQuick.FeatureObj := Yaml(OneQuick.feature_yaml_default_file)
		}
		else {
			if(!FileExist(this.feature_yaml_file)) {
				FileCopy, % this.feature_yaml_default_file, % this.feature_yaml_file, 0
			}
			OneQuick.FeatureObj := Yaml(OneQuick.feature_yaml_file)
		}
	}

	; var
	static tray_standard_menu := 0
	Update_Tray_Menu(ahk_std="")
	{
		if(ahk_std=="switch") {
			this.tray_standard_menu := !this.tray_standard_menu
		}
		else if(ahk_std!="") {
			this.tray_standard_menu := ahk_std
		}
		Menu, Tray, DeleteAll
		if(this.tray_standard_menu)
		{
			Menu, Tray, Standard
			Menu, Tray, Add
			this.Add_OneQuick_Tray_Menu()
			Menu, Tray, Check, % lang("AHK Standard Menu")
		}
		Else
		{
			Menu, Tray, NoStandard
			this.Add_OneQuick_Tray_Menu()
			Menu, Tray, UnCheck, % lang("AHK Standard Menu")
		}
		this.CheckAutorun()
	}

	Add_OneQuick_Tray_Menu()
	{
		; version
		version_str := this.ProgramName " v" this.versionObj["version"]
		Menu, Tray, Tip, % this.ProgramName
		Menu, Tray, Add, % version_str, SUB_VOID
		Menu, Tray, Disable, % version_str
		Menu, Tray, Add, % lang("help_online", "Help Online"), Sub_OneQuick_Help_Online
		Menu, Tray, Add, % lang("Home Page"), Sub_OneQuick_Home_Page
		if(OneQuick._get_Local_Rem_New_Version()) {
			Menu, Tray, Add, % lang("! New Version !") " v" OneQuick._get_Local_Rem_New_Version(), Sub_OneQuick_Check_Update_NewVer
		}
		else {
			Menu, Tray, Add, % lang("Check Update"), Sub_OneQuick_Check_Update
		}
		Menu, Tray, Add
		Menu, Tray, Add, % lang("Autorun"), Sub_OneQuick_Autorun
		Menu, Tray, Add, % lang("Reload"), Sub_OneQuick_Reload
		Menu, Tray, Add, % lang("Exit"), Sub_OneQuick_Exit
		Menu, Tray, Add
		Menu, Tray, Add, % lang("Suspend Hotkey"), Sub_OneQuick_ToggleSuspend
		Menu, Tray, Add, % lang("Pause Thread"), Sub_OneQuick_TogglePause
		Menu, Tray, Add
		Menu, Tray, Add, % lang("AHK Standard Menu"), Sub_OneQuick_StandardMenu
		Menu, Tray, Add, % lang("Open AutoHotkey.exe Folder"), Sub_OneQuick_EXE_Loc
		Menu, Tray, Add, % lang("AutoHotKey Help"), Sub_OneQuick_AHKHelp
		Menu, Tray, Add
		Menu, Tray, Add, % lang("Open OneQuick Folder"), Sub_OneQuick_WorkDir
		Menu, Tray, Add, % lang("Edit Ext.ahk"), Sub_OneQuick_EditExtFile
		Menu, Tray, Add, % lang("Edit feature.yaml"), Sub_OneQuick_EditFeature

		Menu, Tray, Default, % lang("Suspend Hotkey")
		Menu, Tray, Click, 1
	}

	SetIcon(ico)
	{
		Menu, Tray, Icon, %ico%,,1
	}

	AutoSetIcon()
	{
		if !A_IsSuspended && !A_IsPaused
			this.SetIcon(this.icon_default)
		Else if !A_IsSuspended && A_IsPaused
			this.SetIcon(this.icon_pause)
		Else if A_IsSuspended && !A_IsPaused
			this.SetIcon(this.icon_suspend)
		Else if A_IsSuspended && A_IsPaused
			this.SetIcon(this.icon_suspend_pause)
	}

	CheckAutorun()
	{
		autorun := OneQuick.GetConfig("autorun", 0)
		try
		{
			this.SetAutorun(autorun)
		}
		Return % autorun
	}

	SetAutorun(autorun)
	{
		if(autorun)
		{
			RegWrite, REG_SZ, HKCU, Software\Microsoft\Windows\CurrentVersion\Run , % this.ProgramName, % OneQuick.Launcher_Name
			Menu, Tray, Check, % lang("Autorun")
			OneQuick.SetConfig("autorun", 1)
		}
		Else
		{
			RegDelete, HKCU, Software\Microsoft\Windows\CurrentVersion\Run , % this.ProgramName
			Menu, Tray, UnCheck, % lang("Autorun")
			OneQuick.SetConfig("autorun", 0)
		}
	}

	Edit(filename, admin := 0)
	{
		if not FileExist(filename)
		{
			m("Can't find " filename "")
			Return
		}
		if ((not A_IsAdmin) && admin)
		{
			cmd := this.Editor " """ filename """"
			Run *RunAs %cmd%
		}
		Else
		{
			run(this.Editor " """ filename """")
		}
	}

	OnExit(func)
	{
		this.OnExitCmd.Insert(func)
	}

	OnClipboardChange(func)
	{
		this.OnClipboardChangeCmd.Insert(func)
	}

	OnPause(func)
	{
		this.OnPauseCmd.Insert(func)
	}

	OnSuspend(func)
	{
		this.OnSuspendCmd.Insert(func)
	}

	GetConfig(key, default="", section="onequick", autoWrite=true)
	{
		IniRead, output, % OneQuick.config_file, % section, % key
		if(output=="ERROR")
		{
			OneQuick.SetConfig(key, default, section)
			return default
		}
		return output
	}

	SetConfig(key, value, section="onequick")
	{
		IniWrite, % value, % OneQuick.config_file, % section, % key
	}

	SaveUserData()
	{
		if(!FileExist(this._JSON_DIR)) {
			FileCreateDir, % this._JSON_DIR
		}
		FileDelete, % this.user_data_file
		FileAppend % JSON.stringify(OneQuick.UserData), % this.user_data_file
	}

	LoadUserData()
	{
		FileRead, str, % this.user_data_file
		obj := JSON.parse(str)
		if(IsObject(obj))
			OneQuick.UserData := obj
		Else
			OneQuick.UserData := []
	}

	Command_run()
	{
		Gui +LastFound +OwnDialogs +AlwaysOnTop
		msg := lang("input_command_run", "Input command:")
		InputBox, cmd, OneQuick Command Run, % msg, , 330, 150
		if !ErrorLevel
			run(cmd)
	}
}

OnClipboardChange:
RunArr(OneQuick.OnClipboardChangeCmd)
Return

Sub_OnExit:
RunArr(OneQuick.OnExitCmd)
ExitApp

; --------------------------
SUB_VOID:
Return

Sub_Auto_Check_update:
SetTimer, Sub_Auto_Check_update, -3600000
OneQuick.Check_update(false)
return

Sub_OneQuick_ToggleSuspend:
if A_IsSuspended
{
	Menu, Tray, Default, % lang("Pause Thread")
	Menu, Tray, UnCheck, % lang("Suspend Hotkey")
	Suspend, Off
}
else
{
	Menu, Tray, Default, % lang("Pause Thread")
	Menu, Tray, Check, % lang("Suspend Hotkey")
	RunArr(OneQuick.OnSuspendCmd)
	Suspend, On
}
OneQuick.AutoSetIcon()
Return

Sub_OneQuick_TogglePause:
if A_IsPaused
{
	Menu, Tray, Default, % lang("Suspend Hotkey")
	Menu, Tray, UnCheck, % lang("Pause Thread")
	Pause, Off
}
else
{
	Menu, Tray, Default, % lang("Suspend Hotkey")
	Menu, Tray, Check, % lang("Pause Thread")
	; pause will not run SetIcon(), so set icon First
	OneQuick.SetIcon(A_IsSuspended ? OneQuick.icon_suspend_pause : OneQuick.icon_pause)
	RunArr(OneQuick.OnPauseCmd)
	Pause, On
}
OneQuick.AutoSetIcon()
Return

Sub_OneQuick_StandardMenu:
OneQuick.Update_Tray_Menu("switch")
Return

Sub_OneQuick_Autorun:
OneQuick.SetAutorun(!OneQuick.CheckAutorun())
Return

Sub_OneQuick_Help_Online:
run(OneQuick.remote_help)
Return

Sub_OneQuick_Home_Page:
run("https://github.com/XUJINKAI/OneQuick")
Return

Sub_OneQuick_Check_Update:
OneQuick.Check_update()
Return
Sub_OneQuick_Check_Update_NewVer:
run(OneQuick.remote_release)
Return

Sub_OneQuick_Reload:
Reload
Return

Sub_OneQuick_Exit:
exit_msg := lang("exit_msg", "Sure to Exit?")
msgbox, 0x40034, % OneQuick.ProgramName, % exit_msg
IfMsgBox Yes
	ExitApp
Return

Sub_OneQuick_AHKHelp:
splitpath, a_ahkpath, , dir
helpfile := % dir "\AutoHotKey.chm"
if FileExist(helpfile)
{
	run(helpfile)
}
Else
{
	m("Can't find help file.")
}
Return

Sub_OneQuick_EXE_Loc:
splitpath, a_ahkpath, , dir
run(dir)
Return

Sub_OneQuick_WorkDir:
run(A_WorkingDir)
Return

Sub_OneQuick_EditAll:
OneQuick.Edit(OneQuick.Ext_ahk_file)
OneQuick.Edit(A_ScriptFullPath)
OneQuick.Edit(A_ScriptDir "/OneQuick.Core.ahk")
Return

Sub_OneQuick_EditExtFile:
OneQuick.Edit(OneQuick.Ext_ahk_file)
Return

Sub_OneQuick_EditMain:
OneQuick.Edit(A_ScriptFullPath)
Return

Sub_OneQuick_EditFeature:
OneQuick.Edit(OneQuick.feature_yaml_file)
Return


; //////////////////////////////////////////////////////////////////////////
; //////////////////////////////////////////////////////////////////////////
; //////////////////////////////////////////////////////////////////////////
/*
useful global function
the command pass to run() can be:
1. a label or a function name, even "class.func"
2. a system cmd/run command, like "dir", or "http://google.com"
*/

m(str := "")
{
	MsgBox, , % OneQuick.ProgramName, % str
}

t(str := "")
{
	if (str != "")
		ToolTip, % str
	Else
		ToolTip
}

lang(key, default="")
{
	if(default=="")
		default := key
	lang := OneQuick.GetConfig("lang", OneQuick.Default_lang)
	if(lang=="en") {
		return % default
	}
	lang_file := OneQuick._LANG_DIR "lang-" lang ".ini"
	FileEncoding
	IniRead, out, % lang_file, lang, % key, %A_Space%
	if(out=="") {
		IniWrite,%A_Space%, % lang_file, lang, % key
		out := default
	}
	return out
}

RunArr(arr)
{
	Loop, % arr.MaxIndex()
	{
		run(arr[A_Index])
	}
}

; //////////////////////////////////////////////////////////////////////////
; //////////////////////////////////////////////////////////////////////////
; //////////////////////////////////////////////////////////////////////////
/*
a clipboard enhance class, provide a clipboard history list & quick search menu

1. you can use "xClipboard.SetHotkey(allClips, copyAndShow, clipMenu)" function to set hotkeys,
	parameters are hotkey name,
		"allClips" means open clipboard history list,
		"clipMenu" means show current clipboard content and quick search menu,
		"copyAndShow" will do a copy action (^c) and then show "clipMenu"
	ps.it is strongly recommended to Sethotkey as ("^+x", "^+c", "^+v")

2. use "xClipboard.SetSearchList" function to define quick search menu
 	e.g.xClipboard.SetSearchList([["g","Google","https://www.google.com/search?q=%s"],[...]])
 		means use "Google" search current clipboard when Press "g"
 		"%s" in url will be instead of current clipboard text
*/
class xClipboard
{
	static ClsName := "clipboard"
	static ini_registered := 0
	static Clips := []
	static FavourClips := []
	static BrowserArr := []
	static BrowserItemName := ""
	static SearchArr := []
	static NumOfClipsShownDefault = 
	static ClipsLimitNum = 

	Ini()
	{
		if (this.ini_registered == 1)
			Return
		OneQuick.OnClipboardChange("Sub_xClipboard_OnClipboardChange")
		OneQuick.OnExit("Sub_xClipboard_OnExit")
		this.Clips := OneQuick.UserData["xClipboard_Clips"]
		this.FavourClips := OneQuick.UserData["xClipboard_FavourClips"]
		this.NumOfClipsShownDefault := OneQuick.GetConfig("NumOfClipsShownDefault", 10, this.ClsName)
		this.ClipsLimitNum := OneQuick.GetConfig("ClipsLimitNum", 50, this.ClsName)
		if not IsObject(this.Clips)
			this.Clips := []
		if not IsObject(this.FavourClips)
			this.FavourClips := []
		this.ini_registered := 1
	}

	SetHotkey(allClips, copyAndShow, clipMenu)
	{
		if (allClips != "")
			Hotkey, %allClips%, Sub_xClipboard_ShowAllClips
		if (copyAndShow != "")
			Hotkey, %copyAndShow%, Sub_xClipboard_CopyAndShowMenu
		if (clipMenu != "")
			Hotkey, %clipMenu%, Sub_xClipboard_ShowClipMenu
	}

	SetBrowserList(browserList)
	{
		this.BrowserArr := browserList
		if(this.BrowserArr.MaxIndex())
		{
			this.BrowserItemName := this.BrowserArr[1][2] "`t&" this.BrowserArr[1][1]
			OneQuick.Browser := this.BrowserArr[1][3]
		}
	}

	_setBrowserByItemName(ItemName)
	{
		if(RegExMatch(ItemName, "^([^`t]+)", out))
		{
			Loop, % this.BrowserArr.MaxIndex()
			{
				if(this.BrowserArr[A_Index][2] == out)
				{
					this.BrowserItemName := ItemName
					OneQuick.Browser := this.BrowserArr[A_Index][3]
				}
			}
		}
	}

	SetSearchList(search)
	{
		this.SearchArr := search
	}

	ShowAllClips()
	{
		Try
		{
			Menu, xClipboard_AllclipsMenu, DeleteAll
		}
		Try
		{
			Menu, xClipboard_AllclipsMenu_More, DeleteAll
		}
		Try
		{
			Menu, xClipboard_AllclipsMenu_Favour, DeleteAll
		}
		ClipsCount := this.Clips.MaxIndex()
		Loop, % ClipsCount
		{
			idx := ClipsCount - A_Index + 1
			keyName := this.Clips[idx][2]
			if (A_Index <= this.NumOfClipsShownDefault)
				Menu, xClipboard_AllclipsMenu, Add, % (A_Index<10?"&":"") A_Index ". " keyName, Sub_xClipboard_AllClips_Click
			Else
				Menu, xClipboard_AllclipsMenu_More, Add, % A_Index ". " keyName, Sub_xClipboard_AllClips_MoreClick
		}
		if (ClipsCount >= this.NumOfClipsShownDefault)
			Menu, xClipboard_AllclipsMenu, Add, % lang("More Clips"), :xClipboard_AllclipsMenu_More
		FavoursCount := this.FavourClips.MaxIndex()
		if (FavoursCount >= 0)
		{
			Loop, % FavoursCount
			{
				idx := FavoursCount - A_Index + 1
				keyName := this.FavourClips[idx][2]
				Menu, xClipboard_AllclipsMenu_Favour, Add, % A_Index ". " keyName, Sub_xClipboard_AllClips_FavourClick
			}
			Menu, xClipboard_AllclipsMenu_Favour, Add
			Menu, xClipboard_AllclipsMenu_Favour, Add, % lang("Clear Favour List"), Sub_xClipboard_AllClips_FavourClear
			Menu, xClipboard_AllclipsMenu, Add, % lang("Favour Clips"), :xClipboard_AllclipsMenu_Favour
		}
		if (ClipsCount > 0)
		{
			Menu, xClipboard_AllclipsMenu, Add
			Menu, xClipboard_AllclipsMenu, Add, % lang("Paste All"), Sub_Menu_xClipboard_PasteAll
			Menu, xClipboard_AllclipsMenu, Add
			Menu, xClipboard_AllclipsMenu, Add, % lang("Clear Clipboard") "(" %ClipsCount% " clips)", Sub_Menu_xClipboard_DeleteAll
		}
		Else
		{
			Menu, xClipboard_AllclipsMenu, Add, % lang("Clear Clipboard") " (0 clips)", Sub_Menu_xClipboard_DeleteAll
		}
		Menu, xClipboard_AllclipsMenu, Show
	}

	CopyAndShowMenu()
	{
		send ^c
		clipwait
		sleep 100
		this.ShowClipMenu()
	}

	ShowClipMenu(str := "")
	{
		if (str != "")
		{
			Clipboard := str
			Sleep, 100
		}
		if (Clipboard == "")
			Return
		Try
		{
			Menu, xClipboard_clipMenu, DeleteAll
		}
		cliptrim := this._Trim(Clipboard, 0)
		Menu, xClipboard_clipMenu, Add, % cliptrim, Sub_xClipboard_ClipMenu_CLIPTitle
		Menu, xClipboard_clipMenu, Disable, % cliptrim
		Menu, xClipboard_clipMenu, Add, % lang("Paste (Tab)") "`t&`t", Sub_xClipboard_ClipMenu_Paste
		Menu, xClipboard_clipMenu, Add, % lang("RUN in CMD (Space)") " `t& ", Sub_xClipboard_ClipMenu_CMD
		Menu, xClipboard_clipMenu, Add
		Loop, % this.SearchArr.MaxIndex()
		{
			xC_Ssubobj := this.SearchArr[A_Index]
			xC_item := xC_Ssubobj[2] ((xC_Ssubobj[1]=="")?"":"`t&" xC_Ssubobj[1]) 
			Menu, xClipboard_clipMenu, Add, % xC_item, Sub_xClipboard_ClipCmdMenu_Search
		}
		if(this.BrowserArr.MaxIndex())
		{
			Menu, xClipboard_clipMenu, Add
			Loop, % this.BrowserArr.MaxIndex()
			{
				subobj := this.BrowserArr[A_Index]
				Menu, xClipboard_clipMenu, Add, % subobj[2] "`t&" subobj[1], Sub_xClipboard_ClipCmdMenu_SetBrowser
			}
			if(this.BrowserItemName != "")
			{
				Menu, xClipboard_clipMenu, Check, % this.BrowserItemName
			}
		}
		Menu, xClipboard_clipMenu, Add
		Menu, xClipboard_clipMenu, Add, % lang("Add to Favourite"), Sub_xClipboard_ClipMenu_AddFavour
		Menu, xClipboard_clipMenu, Add, % lang("Remove from Favourite"), Sub_xClipboard_ClipMenu_RemoveFavour
		Menu, xClipboard_clipMenu, Add,
		Menu, xClipboard_clipMenu, Add, % lang("Delete"), Sub_xClipboard_ClipMenu_Delete
		Menu, xClipboard_clipMenu, Show
	}

	DeleteAllClips()
	{
		this.Clips := []
		Clipboard =
	}

	DeleteAllFavourClips()
	{
		this.FavourClips := []
	}

	_Trim(str_ori, add_time := 1)
	{
		str := Trim(str_ori, " `t`r`n")
		tabfind := InStr(str, "`t")
		if (tabfind > 0)
		{
			str := SubStr(str, 1, tabfind -1)
		}
		if (str == "")
			str := "<space>"
		Else if (SubStr(str, 1, 1) != SubStr(str_ori, 1, 1))
			str := "_" str
		if StrLen(str) > 50
			str := SubStr(str, 1, 50)
		str := str "`t[" StrLen(str_ori) "]"
		if(add_time)
		{
			str := str "[" A_Hour ":" A_Min ":" A_Sec "]"
		}
		Return % str
	}

	_AddArrClip(ByRef Arr, str)
	{
		trim_str := xClipboard._Trim(str)
		if str !=
		{
			Loop, % Arr.MaxIndex()
			{
				if (str == Arr[A_Index][1])
				{
					Arr.Remove(A_Index)
				}
			}
			Arr.Insert([str, trim_str])
		}
	}

	_RemoveArrClip(ByRef Arr, str)
	{
		Loop, % Arr.MaxIndex()
		{
			if (str == Arr[A_Index][1])
			{
				Arr.Remove(A_Index)
			}
		}
	}
}
; All Clips Menu
Sub_xClipboard_AllClips_Click:
idx := xClipboard.Clips.MaxIndex() - A_ThisMenuItemPos + 1
xClipboard.ShowClipMenu(xClipboard.Clips[idx][1])
Return

Sub_xClipboard_AllClips_MoreClick:
idx := xClipboard.Clips.MaxIndex() - A_ThisMenuItemPos + 1 - xClipboard.NumOfClipsShownDefault
xClipboard.ShowClipMenu(xClipboard.Clips[idx][1])
Return

Sub_xClipboard_AllClips_FavourClick:
idx := xClipboard.FavourClips.MaxIndex() - A_ThisMenuItemPos + 1
xClipboard.ShowClipMenu(xClipboard.FavourClips[idx][1])
Return

Sub_xClipboard_AllClips_FavourClear:
xClipboard.DeleteAllFavourClips()
Return

Sub_Menu_xClipboard_PasteAll:
ClipboardRem := ClipboardAll
ClipboardPaste =
Loop, % xClipboard.Clips.MaxIndex()
{
	ClipboardPaste := ClipboardPaste A_Index "`r`n" xClipboard.Clips[A_Index][1] "`r`n"
}
Clipboard := ClipboardPaste
Send, ^v
ClipboardPaste =
Clipboard := ClipboardRem
ClipboardRem =
Return

Sub_Menu_xClipboard_DeleteAll:
xClipboard.DeleteAllClips()
Return

; Clip Menu
Sub_xClipboard_ClipMenu_CLIPTitle:
Return

Sub_xClipboard_ClipMenu_Paste:
xC_tmp := % Clipboard
Clipboard := xC_tmp
Send, ^v
Return

Sub_xClipboard_ClipMenu_CMD:
run(Trim(Clipboard, " `t"), 0)
Return

Sub_xClipboard_ClipCmdMenu_Search:
xC_site := xClipboard.SearchArr[A_ThisMenuItemPos-4][3]
StringReplace, xC_site, xC_site, `%s, % UriEncode(clipboard), All
Run(xC_site)
Return

Sub_xClipboard_ClipCmdMenu_SetBrowser:
xClipboard._setBrowserByItemName(A_ThisMenuItem)
xClipboard.ShowClipMenu()
Return

Sub_xClipboard_ClipMenu_Delete:
xClipboard._RemoveArrClip(xClipboard.Clips, Clipboard)
if (xClipboard.Clips.MaxIndex() >= 1)
	Clipboard := xClipboard.Clips[1][1]
Else
	Clipboard =
Return

Sub_xClipboard_ClipMenu_AddFavour:
xClipboard._AddArrClip(xClipboard.FavourClips, Clipboard)
Return

Sub_xClipboard_ClipMenu_RemoveFavour:
xClipboard._RemoveArrClip(xClipboard.FavourClips, Clipboard)
Return
; hotkey
Sub_xClipboard_ShowAllClips:
xClipboard.ShowAllClips()
Return

Sub_xClipboard_CopyAndShowMenu:
xClipboard.CopyAndShowMenu()
Return

Sub_xClipboard_ShowClipMenu:
xClipboard.ShowClipMenu()
Return

; OnEvent
Sub_xClipboard_OnClipboardChange:
xClipboard._AddArrClip(xClipboard.Clips, Clipboard)
while (xClipboard.ClipsLimitNum > 0 && xClipboard.Clips.MaxIndex() > xClipboard.ClipsLimitNum)
	xClipboard.Clips.Remove(1)
Return

Sub_xClipboard_OnExit:
OneQuick.UserData["xClipboard_Clips"] := xClipboard.Clips
OneQuick.UserData["xClipboard_FavourClips"] := xClipboard.FavourClips
Return



; //////////////////////////////////////////////////////////////////////////
; //////////////////////////////////////////////////////////////////////////
; //////////////////////////////////////////////////////////////////////////
/*
config struct: [start_hour, start_min, end_hour, end_min, function_or_label_name [,peroid(seconds) ,weekday(1-7)]]
e.g.
Schedule.Add([[0,0,0,0,"func1"], [8,0,20,0,"func2","3600","12345"]])
Schedule.Start()
*/
class Schedule
{
	static SchdArr := []

	Start()
	{
		SetTimer, Sub_Schedule, 1000
	}

	Stop()
	{
		SetTimer, Sub_Schedule, Off
	}

	Add(config)
	{
		Loop, % config.MaxIndex()
		{
			Schedule.SchdArr.Insert(config[A_Index])
		}
	}
}

Sub_Schedule:
Loop % Schedule.SchdArr.MaxIndex()
{
	schedule_entry := Schedule.SchdArr[A_Index]
	If (schedule_entry.MaxIndex() < 5)
		Continue
	If (schedule_entry.MaxIndex() == 7) && !InStr(schedule_entry[7], mod(A_WDay+5,7)+1) ;A_WDay=1 for Sunday
		Continue
	schedule_t1 := A_Hour > schedule_entry[1]
		|| A_Hour = schedule_entry[1] && A_Min >= schedule_entry[2]
	schedule_t2 :=A_Hour < schedule_entry[3]
		|| A_Hour = schedule_entry[3] && A_Min <= schedule_entry[4]
	schedule_otherday := schedule_entry[1] > schedule_entry[3]
		|| schedule_entry[1] = schedule_entry[3]
			&& schedule_entry[2] >= schedule_entry[4]
	if ( !schedule_otherday && (schedule_t1 && schedule_t2)
		|| schedule_otherday && (schedule_t1 || schedule_t2) )
	{
		A_TimeStamp := A_Now
		A_TimeStamp -= 19700101000000,seconds
		if (schedule_entry.MaxIndex() < 6) || !schedule_last_launch_%A_Index%
			|| (A_TimeStamp - schedule_last_launch_%A_Index% >= schedule_entry[6])
		{
			schedule_t_str := schedule_entry[5]
			schedule_last_launch_%A_Index% := A_TimeStamp
			run(schedule_t_str)
		}
	}
}
Return







; //////////////////////////////////////////////////////////////////////////
; //////////////////////////////////////////////////////////////////////////
; //////////////////////////////////////////////////////////////////////////
/*

*/
class WinMenu
{
	static InfoObj := {}
	static HideIDs := {}
	static ini_registered := 0

	Ini()
	{
		if (this.ini_registered == 1)
			Return
		this.HideIDs := OneQuick.UserData["WinMenu_HideIDs"]
		if not IsObject(this.HideIDs)
			this.HideIDs := {}
		OneQuick.OnExit("Sub_WinMenu_OnExit")
		this.ini_registered := 1
	}

	Show(ID := "")
	{
		if (ID == "")
			ID := Sys.Win.ID()
		Title := Sys.Win.Title(ID)
		Path := Sys.Win.Path(ID)
		Cls := Sys.Win.Class(ID)
		this.InfoObj[1] := Title
		this.InfoObj[2] := Path
		this.InfoObj[3] := ID
		this.InfoObj[4] := Cls
		Title := SubStr(Title, 1, 150)
		Path := SubStr(Path, 1, 150)
		try
		{
			Menu, windowMenu, DeleteAll
		}
		Try
		{
			Menu, windowMenu_ShowWinMenu, DeleteAll
		}
		Try
		{
			Menu, WinMenu_Trans, DeleteAll
		}
		Menu, windowMenu, Add, % lang("Topmost"), Sub_WinMenu_TopMost
		if Sys.Win.IsTopmost(winID)
			Menu, windowMenu, Check, % lang("Topmost")
		Loop, 9
		{
			Menu, WinMenu_Trans, Add, % (110-A_Index*10)`%, Sub_WinMenu_Trans
		}
		Trans := Sys.Win.Transparent()
		Try
		{
			Menu, WinMenu_Trans, Check, %Trans%`%
		}
		Menu, windowMenu, Add, % lang("Transparent") ": " Trans "`%", :WinMenu_Trans
		Menu, windowMenu, Add, % lang("Open Location"), Sub_WinMenu_ExplorerSelect
		Menu, windowMenu, Add
		Menu, windowMenu, Add, Title:     %Title%, Sub_WinMenu_CopyToClipboard
		Menu, windowMenu, Add, Path:    %Path%, Sub_WinMenu_CopyToClipboard
		Menu, windowMenu, Add, ID:        %ID%, Sub_WinMenu_CopyToClipboard
		Menu, windowMenu, Add, Class:   %Cls%, Sub_WinMenu_CopyToClipboard
		Menu, windowMenu, Add
		Menu, windowMenu, Add, Hide Window, Sub_WinMenu_HideWindow
		HideIDs_IsVoid := 1
		For k, v in this.HideIDs
		{
			Menu, windowMenu_ShowWinMenu, Add, % k, Sub_WinMenu_ShowWindow
			HideIDs_IsVoid := 0
		}
		if (HideIDs_IsVoid)
		{
			Menu, windowMenu_ShowWinMenu, Add, <empty>, Sub_WinMenu_ShowWindow
			Menu, windowMenu_ShowWinMenu, Disable, <empty>
		}
		Menu, windowMenu, Add, Show Window, :windowMenu_ShowWinMenu
		Menu, windowMenu, Show
	}
}

Sub_WinMenu_TopMost:
Sys.Win.Topmost(WinMenu.InfoObj[3])
Return

Sub_WinMenu_Trans:
Sys.Win.Transparent(ceil(110-A_ThisMenuItemPos*10))
Return

Sub_WinMenu_ExplorerSelect:
Sys.Win.ExplorerSelect(WinMenu.InfoObj[2])
Return

Sub_WinMenu_CopyToClipboard:
xClipboard.ShowClipMenu(WinMenu.InfoObj[A_ThisMenuItemPos - 4])
Return

Sub_WinMenu_HideWindow:
id := WinMenu.InfoObj[3]
WinHide, ahk_id %id%
WinMenu.HideIDs[id "  " WinMenu.InfoObj[1]] := id
Return

Sub_WinMenu_ShowWindow:
id := WinMenu.HideIDs[A_ThisMenuItem]
Sys.Win.Show(id)
WinMenu.HideIDs.Remove(A_ThisMenuItem)
Return

Sub_WinMenu_OnExit:
OneQuick.UserData["WinMenu_HideIDs"] := WinMenu.HideIDs
Return


; //////////////////////////////////////////////////////////////////////////
; //////////////////////////////////////////////////////////////////////////
; //////////////////////////////////////////////////////////////////////////
/*
e.g.
xMenu.Add("Menu1", [["item1","func1"],["item2","func2"],[]
				,["submenu",["subitem_1","func3"],["subitem_2","func4"]]])
xMenu.Show("Menu1")
*/
class xMenu
{
	static MenuList := {}

	Show(Menu_Name, X := "", Y := "")
	{
		if (X == "" || Y == "")
			Menu, %Menu_Name%, Show
		Else
			Menu, %Menu_Name%, Show, % X, % Y
	}

	Clear(Menu_Name)
	{
		Try
		{
			Menu, %Menu_Name%, DeleteAll
		}
	}

	Add(Menu_Name, Menu_Config)
	{
		ParsedCfg := this._Config_Parse(Menu_Name, Menu_Config)
		Loop, % ParsedCfg.MaxIndex()
		{
			cfg_entry := ParsedCfg[A_Index]
			if (cfg_entry[4].HasKey("sub"))
			{
				sub_name := cfg_entry[4]["sub"]
				Menu, % cfg_entry[1], Add, % cfg_entry[2], :%sub_name%
			}
			Else
			{
				Menu, % cfg_entry[1], Add, % cfg_entry[2], Sub_xMenu_Open
				this.MenuList[cfg_entry[1] "_" cfg_entry[2]] := cfg_entry[3]
			}
			For Key, Value in cfg_entry[4]
			{
				if Value = 0
					Continue
				StringLower, Key, Key
				if(Key == "check")
					Menu, % cfg_entry[1], Check, % cfg_entry[2]
				if(Key == "uncheck")
					Menu, % cfg_entry[1], UnCheck, % cfg_entry[2]
				if(Key == "togglecheck")
					Menu, % cfg_entry[1], ToggleCheck, % cfg_entry[2]
				if(Key == "enable")
					Menu, % cfg_entry[1], Enable, % cfg_entry[2]
				if(Key == "disable")
					Menu, % cfg_entry[1], Disable, % cfg_entry[2]
				if(Key == "toggleenable")
					Menu, % cfg_entry[1], ToggleEnable, % cfg_entry[2]
			}
		}
	}

	_Config_Parse(PName, Config)
	{
		ParsedCfg := {}
		Loop, % Config.MaxIndex()
		{
			cfg_entry := Config[A_Index]
			If IsObject(cfg_entry[2])
			{
				ParsedCfg_Sub := this._Config_Parse(cfg_entry[1], cfg_entry[2])
				Loop, % ParsedCfg_Sub.MaxIndex()
				{
					sub_entry := ParsedCfg_Sub[A_Index]
					ParsedCfg.Insert([sub_entry[1],sub_entry[2],sub_entry[3],sub_entry[4]])
				}
				ParsedCfg.Insert([PName,cfg_entry[1],,{"sub":cfg_entry[1]}])
			}
			Else
			{
				if cfg_entry.MaxIndex() == 3
					cfg_ctrl := cfg_entry[3]
				Else
					cfg_ctrl := {}
				ParsedCfg.Insert([PName,cfg_entry[1],cfg_entry[2],cfg_ctrl])
			}
		}
		Return % ParsedCfg
	}
}

Sub_xMenu_Open:
Run(xMenu.MenuList[A_ThisMenu "_" A_ThisMenuItem])
Return





; //////////////////////////////////////////////////////////////////////////
; //////////////////////////////////////////////////////////////////////////
; //////////////////////////////////////////////////////////////////////////
/*

*/
class Sys
{
	class Power
	{
		MonitorOff()
		{
			SendMessage, 0x112, 0xF170, 2,, Program Manager
		}

		Lock()
		{
			run("Rundll32.exe User32.dll,LockWorkStation")
		}

		LockAndMonitoroff()
		{
			this.Lock()
			sleep 1500
			this.MonitorOff()
		}

		Standby()
		{
			/*
			if you want to use this function, you can download psshutdown.exe from 
			https://technet.microsoft.com/en-us/sysinternals/psshutdown.aspx
			then put psshutdown.exe in tool/ folder
			*/
			if FileExist("tool/psshutdown.exe")
			{
				run % "tool/psshutdown.exe -d -t 0"
			}
			Else
			{
				m("can't find psshutdown.exe, you can download it yourself and put it in tool/ folder.")
				run("https://technet.microsoft.com/en-us/sysinternals/psshutdown.aspx")
			}
		}

		Shutdown(countdown := 0)
		{
			run shutdown /s /f /t %countdown%
		}

		Restart()
		{
			run shutdown /r /f
		}

		BatteryIsCharging()
		{
			VarSetCapacity(powerstatus, 1+1+1+1+4+4)
			success := DllCall("kernel32.dll\GetSystemPowerStatus", "uint", &powerstatus)

			acLineStatus := this._ReadInteger(&powerstatus,0,1,false)
			
			return % acLineStatus
		}

		BatteryPercent()
		{
			VarSetCapacity(powerstatus, 1+1+1+1+4+4)
			success := DllCall("kernel32.dll\GetSystemPowerStatus", "uint", &powerstatus)

			;batteryFlag:=this._ReadInteger(&powerstatus,1,1,false)
			batteryLifePercent := this._ReadInteger(&powerstatus,2,1,false)
			;batteryLifeTime:=this._ReadInteger(&powerstatus,4,4,false)
			;batteryFullLifeTime:=this._ReadInteger(&powerstatus,8,4,false)
			
			return % batteryLifePercent
		}

		_ReadInteger( p_address, p_offset, p_size, p_hex=true )
		{
			value = 0
			old_FormatInteger := a_FormatInteger
			if ( p_hex )
				SetFormat, integer, hex
			else
				SetFormat, integer, dec
			loop, %p_size%
				value := value+( *( ( p_address+p_offset )+( a_Index-1 ) ) << ( 8* ( a_Index-1 ) ) )
			SetFormat, integer, %old_FormatInteger%
			return, value
		}

	}

	class Screen
	{
		Off()
		{
			SendMessage, 0x112, 0xF170, 2,, Program Manager
		}

		_find_display_exe()
		{
			if(FileExist("tool/display.exe"))
			{
				return True
			}
			Else
			{
				m("can't find display.exe, you can download it yourself and put it in tool/ folder.")
				run("http://noeld.com/programs.asp#Display")
			}
		}

		RotateTo(angle)
		{
			if (angle != "0" && angle != "90"
				&& angle != "180" && angle != "270")
			Throw, angle must be 0, 90, 180, or 270
			if(this._find_display_exe())
			{
				Run, tool/display.exe /rotate %angle%,,Hide
			}
		}

		RotateCW()
		{
			if(this._find_display_exe())
			{
				Run, tool/display.exe /rotate cw,,Hide
			}
		}

		RotateCCW()
		{
			if(this._find_display_exe())
			{
				Run, tool/display.exe /rotate ccw,,Hide
			}
		}

		BrightnessUp() {
			this.Brightness(+2)
		}
		BrightnessDown() {
			this.Brightness(-2)
		}

		; http://www.autohotkey.com/board/topic/83100-laptop-screen-brightness/
		Brightness(IndexMove)
		{
			VarSetCapacity(SupportedBrightness, 256, 0)
			VarSetCapacity(SupportedBrightnessSize, 4, 0)
			VarSetCapacity(BrightnessSize, 4, 0)
			VarSetCapacity(Brightness, 3, 0)
			
			hLCD := DllCall("CreateFile"
			, Str, "\\.\LCD"
			, UInt, 0x80000000 | 0x40000000 ;Read | Write
			, UInt, 0x1 | 0x2  ; File Read | File Write
			, UInt, 0
			, UInt, 0x3  ; open any existing file
			, UInt, 0
			  , UInt, 0)
			
			if hLCD != -1
			{
				
				DevVideo := 0x00000023, BuffMethod := 0, Fileacces := 0
				  NumPut(0x03, Brightness, 0, "UChar")   ; 0x01 = Set AC, 0x02 = Set DC, 0x03 = Set both
				  NumPut(0x00, Brightness, 1, "UChar")      ; The AC brightness level
				  NumPut(0x00, Brightness, 2, "UChar")      ; The DC brightness level
				DllCall("DeviceIoControl"
				  , UInt, hLCD
				  , UInt, (DevVideo<<16 | 0x126<<2 | BuffMethod<<14 | Fileacces) ; IOCTL_VIDEO_QUERY_DISPLAY_BRIGHTNESS
				  , UInt, 0
				  , UInt, 0
				  , UInt, &Brightness
				  , UInt, 3
				  , UInt, &BrightnessSize
				  , UInt, 0)
				
				DllCall("DeviceIoControl"
				  , UInt, hLCD
				  , UInt, (DevVideo<<16 | 0x125<<2 | BuffMethod<<14 | Fileacces) ; IOCTL_VIDEO_QUERY_SUPPORTED_BRIGHTNESS
				  , UInt, 0
				  , UInt, 0
				  , UInt, &SupportedBrightness
				  , UInt, 256
				  , UInt, &SupportedBrightnessSize
				  , UInt, 0)
				
				ACBrightness := NumGet(Brightness, 1, "UChar")
				ACIndex := 0
				DCBrightness := NumGet(Brightness, 2, "UChar")
				DCIndex := 0
				BufferSize := NumGet(SupportedBrightnessSize, 0, "UInt")
				MaxIndex := BufferSize-1

				Loop, %BufferSize%
				{
				ThisIndex := A_Index-1
				ThisBrightness := NumGet(SupportedBrightness, ThisIndex, "UChar")
				if ACBrightness = %ThisBrightness%
					ACIndex := ThisIndex
				if DCBrightness = %ThisBrightness%
					DCIndex := ThisIndex
				}
				
				if DCIndex >= %ACIndex%
				  BrightnessIndex := DCIndex
				else
				  BrightnessIndex := ACIndex

				BrightnessIndex += IndexMove
				
				if BrightnessIndex > %MaxIndex%
				   BrightnessIndex := MaxIndex
				   
				if BrightnessIndex < 0
				   BrightnessIndex := 0

				NewBrightness := NumGet(SupportedBrightness, BrightnessIndex, "UChar")
				
				NumPut(0x03, Brightness, 0, "UChar")   ; 0x01 = Set AC, 0x02 = Set DC, 0x03 = Set both
		        NumPut(NewBrightness, Brightness, 1, "UChar")      ; The AC brightness level
		        NumPut(NewBrightness, Brightness, 2, "UChar")      ; The DC brightness level
				
				DllCall("DeviceIoControl"
					, UInt, hLCD
					, UInt, (DevVideo<<16 | 0x127<<2 | BuffMethod<<14 | Fileacces) ; IOCTL_VIDEO_SET_DISPLAY_BRIGHTNESS
					, UInt, &Brightness
					, UInt, 3
					, UInt, 0
					, UInt, 0
					, UInt, 0
					, Uint, 0)
				
				DllCall("CloseHandle", UInt, hLCD)
			}
		}

	}

	class Network
	{
		EditHOSTS()
		{
			hosts = %SystemRoot%\system32\drivers\etc\hosts
			OneQuick.Edit(hosts, 1)
			run ipconfig /flushdns
		}

		SetWifiAP(ssid, pw)
		{
			run *RunAs cmd.exe /c netsh wlan set hostednetwork mode=allow ssid=%ssid% key=%pw%
		}

		OpenWifiAP()
		{
			Run *RunAs cmd.exe /c netsh wlan start hostednetwork
		}

		CloseWifiAP()
		{
			run netsh wlan stop hostednetwork
		}
	}

	class Volume
	{
		static Volume_Interval := 2

		Get()
		{
			SoundGet, volume
			return % round(volume, 1)
		}

		Set(vol)
		{
			if ( vol <= 0 )
				vol := 0.005
			SoundSet, % vol
			return % round(vol, 1)
		}

		Up()
		{
			return % this.Set(this.Get() + this.Volume_Interval)
		}

		Down()
		{
			return % this.Set(this.Get() - this.Volume_Interval)
		}

		IsMute()
		{
			SoundGet, master_mute, , mute
			return % master_mute = "on"
		}

		SetMute()
		{
			SoundSet, 1,, Mute
		}

		UnsetMute()
		{
			SoundSet, 0,, Mute
		}
	}

	class Cursor
	{
		static CornerPixel := 8
		static info_switch := 0

		CornerPos(X := "", Y := "", cornerPix = "")
		{
			if (X = "") or (Y = "")
			{
				MouseGetPos, X, Y
			}
			if(cornerPix = "")
			{
				cornerPix := this.CornerPixel
			}
			; Multi Monitor Support
			SysGet, MonitorCount, MonitorCount
			Loop, % MonitorCount
			{
				SysGet, Mon, Monitor, % A_Index
				if(X>=MonLeft && Y>= MonTop && X<MonRight && Y<MonBottom)
				{
					str =
					if ( X < MonLeft + cornerPix )
						str .= "L"
					else if ( X >= MonRight - cornerPix)
						str .= "R"
					if ( Y < MonTop + cornerPix )
						str .= "T"
					else if ( Y >= MonBottom - cornerPix)
						str .= "B"
					return % str
				}
			}
			return ""
		}

		IsPos(pos, cornerPix = "")
		{
			StringUpper, pos, pos
			pos_now := this.CornerPos("", "", cornerPix)
			if (pos_now == "") && (pos == "")
				Return
			if StrLen(pos_now) == 1
				Return % (pos_now == pos)
			Else
				pos_now2 := SubStr(pos_now,2,1) SubStr(pos_now,1,1)
			Return ((pos_now == pos) || (pos_now2 == pos))
		}

		Info()
		{
			this.info_switch := !this.info_switch
			if (this.info_switch)
			{
				Gosub, Sub_Sys_Cursor_Info
				Settimer, Sub_Sys_Cursor_Info, 500
			}
		}
	}

	class Win
	{
		ID()
		{
			WinGet, winID, ID, A
			return % winID
		}

		Title(winID := "")
		{
			if (winID == "")
				winID := this.ID()
			WinGetTitle, title, ahk_id %winID%
			return % title
		}

		Class(winID := "")
		{
			if (winID == "")
				winID := this.ID()
			WinGetClass, class, ahk_id %winID%
			return % class
		}

		GetParent(winID := "")
		{
			if (winID == "")
				winID := this.ID()
			while (winID != 0)
			{
				lastID := winID
				winID := DllCall("GetParent", UInt, winID)
			}
			return lastID
		}

		Path(winID := "")
		{
			if (winID == "")
				winID := this.ID()
			WinGet, path, ProcessPath, ahk_id %winID%
			return % path
		}

		ExplorerSelect(path)
		{
			run("explorer /select," path)
		}

		IsRunning(class)
		{
			DetectHiddenWindows, On ; 可检测到被hide的窗口
			re := winexist(class)
			DetectHiddenWindows, off
			return %re%
		}

		IsFullScreen(winID := "")
		{
			;checks if the specified window is full screen
			;code from NiftyWindows source
			;(with only slight modification)

			;use WinExist of another means to get the Unique ID (HWND) of the desired window

			if (winID == "")
				winID := this.ID()

			WinGet, WinMinMax, MinMax, ahk_id %WinID%
			WinGetPos, WinX, WinY, WinW, WinH, ahk_id %WinID%

			if (WinMinMax = 0) && (WinX = 0) && (WinY = 0) && (WinW = A_ScreenWidth) && (WinH = A_ScreenHeight)
			{
				WinGetClass, WinClass, ahk_id %WinID%
				WinGet, WinProcessName, ProcessName, ahk_id %WinID%
				SplitPath, WinProcessName, , , WinProcessExt
				
				if (WinClass != "Progman") and (WinClass != "WorkerW") and (WinProcessExt != "scr")
				{
					;program is full-screen
					return 1
				}
		    }
			
			return 0

		}

		IsTopmost(winID = "")
		{
			if (winID == "")
				winID := this.ID()
			WinGet, ExStyle, ExStyle, ahk_id %winID%
			if (ExStyle & 0x8)  ; 0x8 is WS_EX_TOPMOST.
				return true
			else
				return false
		}

		Topmost(winID := "", top := "")
		{
			if (winID == "")
				winID := this.ID()
			if (top = "")
				top := not this.IsTopmost(winID)
			if top
			{
				WinSet, AlwaysOnTop, on, ahk_id %winID%
			} 
			else
			{
				Winset, AlwaysOnTop, off, ahk_id %winID%
			}
		}

		Transparent(moveto := "", winID := "")
		{
			if (winID == "")
				winID := this.ID()
			WinGet, Transparent, Transparent, ahk_id %winID%
			If (Transparent = "")
				Transparent = 255
			if (moveto = "")
				Return % floor(Transparent/2.55)
			Transparent_New := moveto * 2.55
			If (Transparent_New < 51)
				Transparent_New = 51
			If (Transparent_New > 254 )
				Transparent_New = 255
			WinSet, Transparent, %Transparent_New%, ahk_id %winID%
		}

		Show(winID := "")
		{
			if (winID == "")
				winID := this.ID()
			WinShow, ahk_id %winID%
		}

		Hide(winID := "")
		{
			if (winID == "")
				winID := this.ID()
			WinHide, ahk_id %winID%
		}

		DisableCloseButton(hWnd="")
		{
			If hWnd=
				hWnd:=WinExist("A")
			hSysMenu:=DllCall("GetSystemMenu","Int",hWnd,"Int",FALSE)
			nCnt:=DllCall("GetMenuItemCount","Int",hSysMenu)
			DllCall("RemoveMenu","Int",hSysMenu,"UInt",nCnt-1,"Uint","0x400")
			DllCall("RemoveMenu","Int",hSysMenu,"UInt",nCnt-2,"Uint","0x400")
			DllCall("DrawMenuBar","Int",hWnd)
		}

		GotoPreApp()
		{
			send !+{esc}
			winget, x ,MinMax, A
			if x=-1
				WinRestore A
		}

		GotoNextApp()
		{
			send !{esc}
			winget, x ,MinMax, A
			if x=-1
				WinRestore A
		}

		GotoPreTab()
		{
			if winactive("ahk_class IEFrame")
				sendinput ^+{tab}
			else
				send ^{pgup}
		}

		GotoNextTab()
		{
			if winactive("ahk_class IEFrame")
				sendinput ^{tab}
			else
				send ^{pgdn}
		}
	}

	BitLocker_Relock(char_Drive)
	{
		Run *RunAs cmd.exe /c manage-bde -lock %char_Drive%:
	}

}

Sub_Sys_Cursor_Info:
; if write these close code to info() function and use a menu to close, tooltip will not destroyed
if (!Sys.Cursor.info_switch)
{
	ToolTip,,,, 9
	SetTimer, Sub_Sys_Cursor_Info, Off
	Return
}
MouseGetPos, X, Y
PixelGetColor, color, %X%, %Y%, RGB
VarSetCapacity(Point, 8, 0)
DllCall("GetCursorPos", ptr, &Point)
hwnd := DllCall("WindowFromPoint", "int64", NumGet(Point, 0, "int64"))
WinGetClass, mcls, ahk_id %hwnd%
Sys_Cursor_Info_Text := ""
. "Pos:       " . "X " . X . " , Y " . Y . "`r`n"
. "Color:    " . color . "`r`n"
. "hwnd:    " . hwnd . "`r`n"
. "Class:     " . mcls . "`r`n"
. "--------------------`r`n"
. "F1,F2  Calculate position`r`n"
. "F4       Copy to clipboard`r`n"
. "ESC     Close Info`r`n"
ToolTip, % Sys_Cursor_Info_Text,,, 9
Return

#if Sys.Cursor.info_switch
f1::
MouseGetPos, Sys_Cursor_Info_rem_x, Sys_Cursor_Info_rem_y
m("move mouse and press F2")
return

f2::
CoordMode, Mouse, Screen ;设置绝对坐标
MouseGetPos, x, y
m("X" abs(Sys_Cursor_Info_rem_x-x) " Y" abs(Sys_Cursor_Info_rem_y-y))
return

f4::
clipboard := Sys_Cursor_Info_Text
m("Copy to Clipboard")
return

esc::
Sys.Cursor.Info()
return
#if

; //////////////////////////////////////////////////////////////////////////
; //////////////////////////////////////////////////////////////////////////
; //////////////////////////////////////////////////////////////////////////
/*

*/
class DateTime
{
	SecondsToStr(NumberOfSeconds)
	{
	    time = 19990101  ; *Midnight* of an arbitrary date.
	    time += %NumberOfSeconds%, seconds
	    FormatTime, mmss, %time%, mm:ss
	    return NumberOfSeconds//3600 ":" mmss  ; This method is used to support more than 24 hours worth of sections.
	}

	TimeStamp(YYYYMMDDHH24MISS := "")
	{
		if !YYYYMMDDHH24MISS
			A_TimeStamp := A_Now
		Else
			A_TimeStamp := YYYYMMDDHH24MISS
		A_TimeStamp -= 19700101000000,seconds
		Return % A_TimeStamp
	}
}

CountObj(obj)
{
	count := 0
	For Key, val in obj
	{
		count := count + 1
	}
	return % count
}

/*
* http://www.autohotkey.com/forum/viewtopic.php?t=71619
*/
UriEncode(Uri, Enc = "UTF-8")
{
	StrPutVar(Uri, Var, Enc)
	f := A_FormatInteger
	SetFormat, IntegerFast, H
	Loop
	{
		Code := NumGet(Var, A_Index - 1, "UChar")
		If (!Code)
			Break
		If (Code >= 0x30 && Code <= 0x39 ; 0-9
			|| Code >= 0x41 && Code <= 0x5A ; A-Z
			|| Code >= 0x61 && Code <= 0x7A) ; a-z
			Res .= Chr(Code)
		Else
			Res .= "%" . SubStr(Code + 0x100, -1)
	}
	SetFormat, IntegerFast, %f%
	Return, Res
}

UriDecode(Uri, Enc = "UTF-8")
{
	Pos := 1
	Loop
	{
		Pos := RegExMatch(Uri, "i)(?:%[\da-f]{2})+", Code, Pos++)
		If (Pos = 0)
			Break
		VarSetCapacity(Var, StrLen(Code) // 3, 0)
		StringTrimLeft, Code, Code, 1
		Loop, Parse, Code, `%
			NumPut("0x" . A_LoopField, Var, A_Index - 1, "UChar")
		StringReplace, Uri, Uri, `%%Code%, % StrGet(&Var, Enc), All
	}
	Return, Uri
}

StrPutVar(Str, ByRef Var, Enc = "")
{
	Len := StrPut(Str, Enc) * (Enc = "UTF-16" || Enc = "CP1200" ? 2 : 1)
	VarSetCapacity(Var, Len, 0)
	Return, StrPut(Str, &Var, Enc)
}

; ///////////////////////////////////////////////////////////////////////////
; 万能的run 函数
; 参数可以是cmd命令，代码中的sub，function，网址，b站av号，还可以扩展
run(command, throwErr := 1)
{
	if(IsLabel(command))
	{
		Gosub, %command%
	}
	else if (IsFunc(command))
	{
		Array := StrSplit(command, ".")
		If (Array.MaxIndex() >= 2)
		{
			cls := Array[1]
			cls := %cls%
			Loop, % Array.MaxIndex() - 2
			{
				cls := cls[Array[A_Index+1]]
			}
			return cls[Array[Array.MaxIndex()]]()
		}
		Else
		{
			return %command%()
		}
	}
	Else
	{
		if(RegExMatch(command, "^https?://"))
		{
			brw := OneQuick.Browser
			if(brw == "")
				run, %command%
			Else if(brw == "microsoft-edge:")
				run, %brw%%command%
			Else
				run, %brw% %command%
			Return
		}
		else if(RegExMatch(command, "i)av(\d+)", avn))
		{
			run("http://www.bilibili.com/video/av" avn1)
			return
		}
		else if(RegExMatch(command, "i)send (.*)", sd))
		{
			send, % sd1
			return
		}
		else if(RegExMatch(command, "i)m:(.*)", msg))
		{
			m(msg1)
			return
		}
		Try
		{
			run, %command%
			Return
		}
		Catch
		{
			if(IsFunc("run_user"))
			{
				func_name = run_user
				%func_name%(command)
			}
			else if (throwErr == 1)
				MsgBox, 0x30, % OneQuick.ProgramName, % "Can't run command """ command """"
		}
	}
}
; //////////////////////////////////////////////////////////////////////////
SUB_ONEQUICK_FILE_END_LABEL: