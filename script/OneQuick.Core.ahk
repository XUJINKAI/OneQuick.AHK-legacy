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

; parameters passed in
argv1 = %1%
; Tray.Tip
if(argv1="-traytip") {
	argv2 = %2%
	argv3 = %3%
	argv4 = %4%
	TrayTip, % argv2, % argv3,, % argv4
}
if(A_ScriptName=="OneQuick.Core.ahk") {
	ExitApp
}
; with this label, you can include this file on top of the file
Goto, SUB_ONEQUICK_FILE_END_LABEL
#Persistent
#MaxHotkeysPerInterval 200
#MaxThreads, 255
#MaxThreadsPerHotkey, 20
#Include %A_ScriptDir%
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
	; dir
	static _MAIN_WORKDIR := ""
	static _JSON_DIR := "data/"
	static _ICON_DIR := "icon/"
	static _LANG_DIR := "lang/"
	static _SCRIPT_DIR := "script/"
	static _Update_bkp_DIR := "_bkp/"
	static _Update_dl_DIR := "_bkp/dl/"
	static _Update_bkp_folder_prefix := "_auto_"
	; file
	static Launcher_Name := A_WorkingDir "\OneQuick Launcher.exe"
	static Ext_ahk_file := "OneQuick.Ext.ahk"
	static version_yaml_file := OneQuick._SCRIPT_DIR "version.yaml"
	static feature_yaml_file := "OneQuick.feature.yaml"
	static feature_yaml_default_file := OneQuick._SCRIPT_DIR "OneQuick.feature.default.yaml"
	static config_file := "config.ini"
	static user_data_file := OneQuick._JSON_DIR "OneQuick.Data." A_ComputerName ".json"
	static icon_default := OneQuick._ICON_DIR "1.ico"
	static icon_suspend := OneQuick._ICON_DIR "2.ico"
	static icon_pause := OneQuick._ICON_DIR "4.ico"
	static icon_suspend_pause := OneQuick._ICON_DIR "3.ico"
	; remote file path
	static remote_branch := "master"
	static remote_raw := "http://raw.githubusercontent.com/XUJINKAI/OneQuick/" OneQuick.remote_branch "/"
	static remote_releases_dir := "https://github.com/XUJINKAI/OneQuick/releases/download/"
	static remote_update_dl_dir := OneQuick.remote_releases_dir "beta0/"
	; github api has limit
	; static remote_contents := "https://api.github.com/repos/XUJINKAI/OneQuick/contents/"
	; update
	static check_update_first_after := 1
	static check_update_period := 1000*3600*24
	static Bkp_limit := 5
	static update_list_path := OneQuick._SCRIPT_DIR "update_list.json"
	; online
	static Project_Home_Page := "https://github.com/XUJINKAI/OneQuick"
	static Project_Issue_page := "https://github.com/XUJINKAI/OneQuick/issues"
	static remote_download_html := "https://github.com/XUJINKAI/OneQuick/releases"
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
	static Editor = notepad
	static Browser := "default"

	Ini(asLib=false)
	{
		SetBatchLines, -1   ; maximize script speed!
		SetWinDelay, -1
		CoordMode, Mouse, Screen
		CoordMode, ToolTip, Screen
		CoordMode, Menu, Screen
		; %systmeroot% can't give to this.Editor directly
		if(this.Editor = "" or this.Editor = "notepad")
		{
			defNotepad = %SystemRoot%\notepad.exe
			this.Editor := defNotepad
		}
		if(asLib) {
			Return
		}
		; set _DEBUG_ value
		; add show=1 to config.ini [debug] to show debug switch in menu
		OneQuick._DEBUG_ := OneQuick.debugConfig("debug", 0)

		; register onexit sub
		OnExit, Sub_OnExit

		; setting
		this.LoadFeatureYaml()
		; load version yaml file
		this.versionObj := Yaml(this.version_yaml_file)
		; program running cache/variable
		this.LoadUserData()

		; initialize module
		xClipboard.Ini()
		WinMenu.Ini()

		; initialize
		this.Update_Tray_Menu()
		this.SetAutorun("config")
		this.Show_StartInfo()
		; guide
		this.Check_First_Time_Run()
		; update
		SetTimer, Sub_Auto_Check_update, % -OneQuick.check_update_first_after
		; ext.ahk
		this.Run_ext_user_ini()
	}
	; when start
	Show_StartInfo()
	{
		msg := lang("traytip_runing")
		auto_update := OneQuick.GetConfig("auto_update")
		from_ver := OneQuick.GetConfig("update_from_version", "")
		msgbox_from_version := OneQuick.GetConfig("msgbox_from_version")
		if(OneQuick._DEBUG_) {
			msg .= "`n【DEBUG mode】"
		}
		if(msgbox_from_version!=from_ver) {
			update_tip := lang("Updated to version v") OneQuick.versionObj["version"]
			msg .= "`n" update_tip
		}
		bigver := this.GetBiggerRemVersion()
		if(bigver!="") {
			msg .= "`n" lang("new_version_traytip") " v" bigver
		}
		; 先弹tip再弹msgbox
		Tray.Tip(msg)
		; 从旧版本升级上来的提示
		; 仅在第一次重启后显示
		if(msgbox_from_version!=from_ver) {
			if(!auto_update) {
				update_msg := OneQuick._new_version_info({"version": from_ver }, OneQuick.versionObj)
				m(update_tip "`n" update_msg)
			}
			OneQuick.SetConfig("msgbox_from_version", from_ver)
		}
		if(!auto_update) {
			if(bigver!="") {
				msgbox_newer_version := OneQuick.GetConfig("msgbox_newer_version")
				if(msgbox_newer_version!=bigver) {
					; OneQuick.Check_update 弹窗， msgbox_newer_version 限制仅一次
					OneQuick.Check_update(true, false)
					OneQuick.SetConfig("msgbox_newer_version", bigver)
				}
			}
		}
	}
	; user guide
	Check_First_Time_Run()
	{
		skip_guide := OneQuick.GetConfig("skip_guide")
		if(OneQuick._DEBUG_) {
			; skip_guide := 0
		}
		if(!skip_guide) {
			run("autohotkey.exe " OneQuick._script_DIR "user_guide.ahk")
			OneQuick.SetConfig("skip_guide", 1)
		}
	}

	; ext.ahk
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

	; Get
	Get_Remote_File(path)
	{
		StringReplace, path, % path, \, /, All
		url := OneQuick.remote_raw path
		content := http.get(url)
		return % content
	}
	;
	Get_Remote_versionObj()
	{
		remoteVerTxt := OneQuick.Get_Remote_File(OneQuick.version_yaml_file)
		if(remoteVerTxt="") {
			return ""
		}
		remoteVerObj := Yaml(remoteVerTxt, 0)
		return remoteVerObj
	}

	; check update
	; show_msg=1, 弹窗升级; =0 静默升级; 
	; show_msg=1时, error_msg控制无需更新时的提示
	; 默认由右键菜单调用，所以为true, true
	Check_update(show_msg=True, error_msg=True)
	{
		thisVerObj := OneQuick.versionObj
		remoteVerObj := OneQuick.Get_Remote_versionObj()
		this_version := thisVerObj["version"]
		remote_version := remoteVerObj["version"]
		if(remoteVerObj="")
		{
			if(show_msg&&error_msg) {
				msg := lang("update_http_error")
				m(msg)
			}
			Return
		}
		OneQuick.SetConfig("remote_version", remote_version)
		OneQuick.Update_Tray_Menu()
		ver_compare := OneQuick._version_compare(this_version, remote_version)
		if(ver_compare>=0) {
			if(show_msg&&error_msg) {
				msg := lang("update_no_newer_ver")
				if(ver_compare>0) {
					msg .= "`n你的版本号超过了作者...(ง •̀_•́)ง "
				}
				msg .= "`nv" this_version " -> v" remote_version
				m(msg)
			}
			Return
		}
		if(show_msg) {
			update_msg := lang("update_msg")
			if(OneQuick._DEBUG_) {
				update_msg := "【DEBUG Mode】`n" update_msg
			}
			new_version_info := OneQuick._new_version_info(thisVerObj, remoteVerObj)
			nv_msg := lang("new_version")
			MsgBox, 0x1024, % OneQuick.ProgramName " " nv_msg, % update_msg "`n" new_version_info
			IfMsgBox, NO
			{
				Return
			}
		}
		else {
			if(OneQuick.GetConfig("auto_update")=0) {
				Return
			}
		}
		; set var
		FormatTime, timestr,, yyyyMMddHHmmss
		backup_dir := OneQuick._Update_bkp_DIR OneQuick._Update_bkp_folder_prefix timestr "_v" this_version "/"
		dl_dir := OneQuick._Update_dl_DIR
		update_background_tip := lang("update_background_tip", "Update in background") "..."
		; 两种升级策略
		; 1. 获取升级列表，并按列表按需下载所需文件（raw repo contents）
		; 2. 下载压缩包
		bool_auto_update := OneQuick._version_compare(this_version, remoteVerObj["auto-update-version"]) >= 0
		if( ! bool_auto_update) {
			; 由于smartscreen筛选，exe无法下载
			; 故下载zip文件后告知用户手动解压
			; download zip file
			if(show_msg) {
				d("method 2")
				Tray.Tip(update_background_tip)
				zip_name := "OneQuick.v" remote_version ".zip"
				remote_zip_file := OneQuick.remote_releases_dir "v" remote_version "/" zip_name
				ErrorLevel := File.Download(remote_zip_file, zip_name)
				d("dl zip, error: " ErrorLevel)
				if(ErrorLevel) {
					if(show_msg&&error_msg) {
						msg := lang("dl_zip_error")
						m(msg)
						run(OneQuick.remote_download_html)
					}
					Return
				}
				msg := lang("dl_zip_success")
				m(msg)
				run("explorer /select, " zip_name)
			}
			Return
		}
		d("method 1")
		; tray tip
		Tray.Tip(update_background_tip)
		; start operate files
		; future: compare file & 增量升级
		OneQuick.Generate_update_list()
		; clear bkp
		OneQuick._clear_bkp_folders()
		; delete dl folder
		FileRemoveDir, % dl_dir, 1
		d("del dl")
		; get update list in repo
		remote_json_str := OneQuick.Get_Remote_File(OneQuick.update_list_path)
		obj := JSON.parse(remote_json_str)
		; download
		OneQuick._update_copy_file(obj, OneQuick.remote_raw, dl_dir)
		d("dl raw files")
		; update count
		count_file_name := "v" remote_version ".txt"
		remote_update_count_file := OneQuick.remote_update_dl_dir count_file_name
		update_count_file := OneQuick._Update_bkp_DIR count_file_name
		ErrorLevel := File.Download(remote_update_count_file, update_count_file)
		d("dl count, error: " ErrorLevel)
		FileDelete, % update_count_file
		d("del count")
		; backup
		OneQuick._update_copy_file(obj, "", backup_dir)
		; Copy back
		d("[CAUTION] DEBUG mode: source code will be changed.")
		OneQuick._update_copy_file(obj, dl_dir, "")
		; delete dl
		FileRemoveDir, % dl_dir, 1
		; reload
		OneQuick.SetConfig("update_from_version", this_version)
		RunWait autohotkey.exe %A_ScriptFullPath%
		; only if restart fail
		; if reload onequick fail, will rollback
		OneQuick.SetConfig("update_from_version", "")
		msg := lang("update_error")
		m(msg)
		OneQuick._update_copy_file(obj, backup_dir, "")
		FileRemoveDir, % backup_dir, 1
	}

	_ZIP_OneQuick_self()
	{
		zip_file_ne := "OneQuick.v" OneQuick.versionObj["version"]
		FileDelete, % zip_file_ne ".exe"
		FileDelete, % zip_file_ne ".zip"
		rar_exe := OneQuick.versionObj["winrar-path"]
		zip_file_list := OneQuick.versionObj["zip-path-list"]
		cmd = %rar_exe% a %zip_file_ne%.zip %zip_file_list%
		run(cmd)
	}

	_new_version_info(thisVerObj, remoteVerObj)
	{
		this_version := thisVerObj["version"]
		remote_version := remoteVerObj["version"]
		version_compare := this._version_compare(remote_version, this_version)
		if(version_compare > 0)
		{
			remote_desc1 := remoteVerObj["desc-major"]
			remote_desc2 := remoteVerObj["desc-minor"]
			remote_desc3 := remoteVerObj["desc-revision"]
			StringReplace, remote_desc1, % remote_desc1, ``n, `n, All
			StringReplace, remote_desc2, % remote_desc2, ``n, `n, All
			StringReplace, remote_desc3, % remote_desc3, ``n, `n, All
			update_msg := "v" this_version " -> v" remote_version
			update_msg .= "`n`n" lang("update_desc")
			if(version_compare==1) {
				update_msg .= "`n" remote_desc1
			}
			else if(version_compare==2) {
				update_msg .= "`n" remote_desc2
			}
			else if(version_compare==3) {
				update_msg .= "`n" remote_desc3
			}
			return % update_msg
		}
		else {
			return ""
		}
	}

	; update
	_debug_version()
	{
		; onequick._debug_version
		fake_type := 1
		; fake remote
		if(fake_type==1) {
			fake_version := {"version": "0.9.3"
				,"desc-major": "超级无敌大更新1`n123"
				,"desc-minor": "超级无敌大更新2`n456"
				,"desc-revision": "超级无敌大更新3`n789" }
			m(this._new_version_info(this.versionObj, fake_version))
		}
		; fake local
		else if (fake_type==2) {
			fake_version := {"version": "0.0.0"
				,"desc-major": "will-not-show"
				,"desc-minor": "will-not-show"
				,"desc-revision": "will-not-show" }
			m(this._new_version_info(fake_version, this.versionObj))
		}
	}

	_version_bigger(ver1, ver2)
	{
		if(this._version_compare(ver1, ver2) > 0) {
			return ver1
		}
		else {
			Return ver2
		}
	}

	_version_compare(ver1, ver2)
	{
		pos := OneQuick._version_first_larger(ver1, ver2)
		if(pos > 0) {
			return % pos
		}
		else {
			neg := OneQuick._version_first_larger(ver2, ver1)
			if (neg > 0) {
				return % -neg
			}
		}
		return 0
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

	_update_copy_file(listObj, sourcePath, destPath)
	{
		Loop, % listObj.MaxIndex()
		{
			path := listObj[A_Index]["name"]
			source := sourcePath path
			dest := destPath path
			if(RegExMatch(source, "^https?://")) {
				StringReplace, source, % source, \, /, All
				File.Download(source, dest)
			}
			else {
				StringReplace, source, % source, /, \, All
				StringReplace, dest, % dest, /, \, All
				File.Copy(source, dest, 1)
			}
		}
	}

	_clear_bkp_folders(nlimit="")
	{
		if(nlimit="") {
			nlimit := OneQuick.Bkp_limit
		}
		bkp_folders := []
		; count bkp
		Loop Files, % OneQuick._Update_bkp_DIR OneQuick._Update_bkp_folder_prefix "*", D
		{
			bkp_folders.Insert(A_LoopFileFullPath)
		}
		; delete bkp
		Loop, % bkp_folders.MaxIndex() + 1 - nlimit
		{
			FileRemoveDir, % OneQuick._Update_bkp_DIR bkp_folders[A_Index], 1
		}
	}

	; update list local
	_reGenerate_update_list()
	{
		obj := OneQuick.Generate_update_list()
		m("update_list.json:`n`n" Yaml_dump(obj))
	}
	Generate_update_list()
	{
		verObj := OneQuick.versionObj
		obj_list := OneQuick._yaml_obj_to_list(verObj["update-path"])
		jsonObj := OneQuick._scan_file_list_obj(obj_list)
		; write
		FileDelete, % OneQuick.update_list_path
		FileAppend, % JSON.stringify(jsonObj) "`n", % OneQuick.update_list_path
		return jsonObj
	}
	_yaml_obj_to_list(obj)
	{
		ret_list := []
		Loop, % obj.()
		{
			ret_list.Insert(obj.(A_Index))
		}
		return ret_list
	}
	_scan_file_list_obj(scan_array)
	{
		file_list := []
		Loop, % scan_array.MaxIndex()
		{
			scan_array[A_Index] := StrReplace(scan_array[A_Index], "/", "\")
		}
		; adding all
		Loop, % scan_array.MaxIndex()
		{
			path := scan_array[A_Index]
			if(SubStr(path, 1, 1)!="!") {
				para := InStr(path, "*") ? "FR" : "F"
				Loop Files, % path, %para%
				{
					file_list.Insert(A_LoopFileFullPath)
				}
			}
		}
		; remove !
		Loop, % scan_array.MaxIndex()
		{
			path := scan_array[A_Index]
			if(SubStr(path, 1, 1)="!") {
				path := SubStr(path, 2)
				Loop Files, % path, FR
				{
					file_list := xArray.remove(file_list, A_LoopFileFullPath)
				}
			}
		}
		; implement obj
		obj := []
		Loop, % file_list.MaxIndex()
		{
			item := {"name": file_list[A_Index]}
			obj.Insert(item)
		}
		return obj
	}
	GetBiggerRemVersion()
	{
		this_version := this.versionObj["version"]
		rem_version := this.GetConfig("remote_version")
		ver := this._version_bigger(this_version, rem_version)
		if(this_version=ver) {
			return ""
		}
		else {
			return % ver
		}
	}

	; tray icon
	SetIcon(ico)
	{
		Tray.SetIcon(ico)
	}
	; callback register
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

	; feature.yaml
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

	Edit_feature_yaml()
	{
		if(OneQuick._DEBUG_ && this.debugConfig("load_default_feature_yaml", 0)) {
			OneQuick.Edit(OneQuick.feature_yaml_default_file)
		}
		else {
			OneQuick.Edit(OneQuick.feature_yaml_file)
		}
	}

	LoadFeatureYaml()
	{
		if(OneQuick._DEBUG_ && this.debugConfig("load_default_feature_yaml", 0)) {
			OneQuick.FeatureObj := Yaml(OneQuick.feature_yaml_default_file)
		}
		else {
			if(!FileExist(this.feature_yaml_file)) {
				FileCopy, % this.feature_yaml_default_file, % this.feature_yaml_file, 0
			}
			OneQuick.FeatureObj := Yaml(OneQuick.feature_yaml_file)
		}
	}
	; config.ini
	debugConfig(key, default)
	{
		return OneQuick.GetConfig(key, default, "debug", OneQuick._DEBUG_)
	}

	GetConfig(key, default="", section="onequick", autoWrite=true)
	{
		IniRead, output, % OneQuick.config_file, % section, % key
		if(output=="ERROR")
		{
			if(autoWrite) {
				OneQuick.SetConfig(key, default, section)
			}
			return default
		}
		return output
	}

	SetConfig(key, value, section="onequick")
	{
		IniWrite, % value, % OneQuick.config_file, % section, % key
	}

	; user data
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

	; 
	; run inputbox
	Command_run()
	{
		Gui +LastFound +OwnDialogs +AlwaysOnTop
		msg := lang("input_command_run")
		InputBox, cmd, OneQuick Command Run, % msg, , 330, 150
		if !ErrorLevel
			run(cmd)
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
			cmd := this.Editor " """ filename """"
			Run % cmd
		}
	}

	; Tray Menu
	Update_Tray_Menu()
	{
		version_str := lang("About") " v" this.versionObj["version"]
		autorun := OneQuick.GetConfig("autorun", 0)
		autoupdate := OneQuick.GetConfig("auto_update", 0)
		bigVer := OneQuick.GetBiggerRemVersion()
		if(bigVer!="") {
			check_update_name := lang("! New Version !") " v" bigVer
		}
		else {
			check_update_name := lang("Check Update")
		}
		lang := OneQuick.GetConfig("lang")
		Menu, Tray, Tip, % this.ProgramName
		xMenu.New("TrayLanguage"
			,[["English", "OneQuick.SetLang", {check: lang=="en"}]
			, ["中文", "OneQuick.SetLang", {check: lang=="cn"}]])
		xMenu.New("TrayAdvanced"
			,[["Suspend Hotkey", "OneQuick.SetSuspend", {check: A_IsSuspended}]
			,["Pause Thread", "OneQuick.SetPause", {check: A_IsPaused}]
			,[]
			,[lang("AHK Standard Menu"), "OneQuick.Standard_Tray_Menu", {check: OneQuick._switch_tray_standard_menu}]
			,[]
			,[lang("Reset Program"), "OneQuick.ResetProgram"]])
		TrayMenuList := []
		debug_show := OneQuick.debugConfig("show", 0)
		if(OneQuick._DEBUG_||debug_show) {
			TrayMenuList := xArray.merge(TrayMenuList
				,[["DEBUG Mode: " (OneQuick._DEBUG_?"ON":"OFF"), "OneQuick.debug_mode"],[]])
		}
		if(OneQuick._DEBUG_) {
			TrayMenuList := xArray.merge(TrayMenuList
				,[["ZIP files", "OneQuick._ZIP_OneQuick_self"]
				,["Generate_update_list.json", "OneQuick._reGenerate_update_list"]
				,["Count_Download_Online", "OneQuick._SumGithubDownloadCount"]
				,[]
				,["config.ini", "notepad " OneQuick.config_file]
				,["core.ahk", "edit: script/OneQuick.Core.ahk"]
				,["version.yaml", "edit:" OneQuick.version_yaml_file]
				,[]])
		}
		TrayMenuList := xArray.merge(TrayMenuList
			,[[version_str, "OneQuick.About"]
			,[lang("help_online"), OneQuick.remote_help]
			,[check_update_name, "OneQuick.Check_update"]
			,[]
			,[lang("Autorun"), "OneQuick.SetAutorun", {check: autorun}]
			,[lang("AutoUpdate"), "OneQuick.SetAutoUpdate", {check: autoupdate}]
			,["Language",, {"sub": "TrayLanguage"}]
			,[lang("Advanced"),, {"sub": "TrayAdvanced"}]
			,[]
			,[lang("Disable"), "OneQuick.SetDisable", {check: A_IsPaused&&A_IsSuspended}]
			,[lang("Reload"), "OneQuick.Reload"]
			,[lang("Exit"), "OneQuick.Exit"]
			,[]
			,[lang("Open AutoHotkey.exe Folder"), "Sub_OneQuick_EXE_Loc"]
			,[lang("AutoHotKey Help"), "Sub_OneQuick_AHKHelp"]
			,[]
			,[lang("Open OneQuick Folder"), A_WorkingDir]
			,[lang("Edit Ext.ahk"), "edit:" OneQuick.Ext_ahk_file]
			,[lang("Edit feature.yaml"), "OneQuick.Edit_feature_yaml"] ])
		Tray.SetMenu(TrayMenuList, OneQuick._switch_tray_standard_menu)
		Menu, Tray, Default, % lang("Disable")
		Menu, Tray, Click, 1
		OneQuick.Update_Icon()
	}
	static _switch_tray_standard_menu := 0
	Standard_Tray_Menu(act="toggle")
	{
		OneQuick._switch_tray_standard_menu := (act="toggle")? !OneQuick._switch_tray_standard_menu :act
		OneQuick.Update_Tray_Menu()
	}
	Update_Icon()
	{
		setsuspend := A_IsSuspended
		setpause := A_IsPaused
		if !setpause && !setsuspend {
			this.SetIcon(this.icon_default)
		}
		Else if !setpause && setsuspend {
			this.SetIcon(this.icon_pause)
		}
		Else if setpause && !setsuspend {
			this.SetIcon(this.icon_suspend)
		}
		Else if setpause && setsuspend {
			this.SetIcon(this.icon_suspend_pause)
		}
	}
	SetState(setsuspend="", setpause="")
	{
		setsuspend := (setsuspend="")? A_IsSuspended: setsuspend
		setpause := (setpause="")? A_IsPaused: setpause
		if(!A_IsSuspended && setsuspend) {
			RunArr(OneQuick.OnSuspendCmd)
		}
		if(!A_IsPaused && setpause) {
			RunArr(OneQuick.OnPauseCmd)
		}
		if(setsuspend) {
			Suspend, On
		}
		else {
			Suspend, Off
		}
		if(setpause) {
			Pause, On, 1
		}
		else {
			Pause, Off
		}
		OneQuick.Update_Tray_Menu()
	}
	;
	About()
	{
		lang := OneQuick.GetConfig("lang", "cn")
		Gui, OneQuick_About: New
		Gui OneQuick_About:+Resize +AlwaysOnTop +MinSize400 -MaximizeBox -MinimizeBox
		Gui, Font, s12
		s := "OneQuick v" OneQuick.versionObj["version"]
		Gui, Add, Text,, % s
		s := "<a href=""" OneQuick.Project_Home_Page """>" lang("Home Page") "</a>"
		Gui, Add, Link,, % s
		s := "<a href=""" OneQuick.Project_Issue_page """>" lang("Feedback") "</a>"
		Gui, Add, Link,, % s
		s := "Author: XJK <a href=""mailto:jack8461@msn.cn"">jack8461@msn.cn</a>"
		Gui, Add, Link,, % s
		dnt := lang="cn" ? "捐赠" : "Donate!"
		s := "<a href=""http://xujinkai.github.io/my/donate/"">" dnt "</a>"
		s .= " <a href=""https://www.zhihu.com/question/36847530/answer/92868539"">去知乎点赞!</a>"
		Gui, Add, Link,, % s
		Gui, Add, Text
		Gui, Add, Button, Default gSub_Close_OneQuick_About, Close
		GuiControl, Focus, Close
		Gui, Show,, About OneQuick
	}
	; OneQuick._SumGithubDownloadCount
	_SumGithubDownloadCount()
	{
		json_str := http.get("https://api.github.com/repos/XUJINKAI/OneQuick/releases")
		obj := JSON.Parse(json_str)
		sum := 0
		msg := ""
		Loop, % obj.MaxIndex()
		{
			rel := obj[A_Index]
			tag_name := rel["tag_name"]
			assets := rel["assets"]
			msg .= "`n" tag_name ":"
			Loop, % assets.MaxIndex()
			{
				file := assets[A_Index]
				name := file["name"]
				dlcount := file["download_count"]
				sum += dlcount
				msg .= "`n  " name ": " dlcount
			}
		}
		msg := "github download sum: " sum msg
		m(msg)
	}
	Reload()
	{
		Reload
	}
	ResetProgram()
	{
		lang := OneQuick.GetConfig("lang")
		msg := lang="cn" ? "重置会删除config.ini, OneQuick.feature.yaml并重启OneQuick." : "Reset program will delete config.ini, OneQuick.feature.yaml,`nAnd reload OneQuick."
		if(mq(msg, 0x1124)) {
			FileDelete, config.ini
			FileDelete, OneQuick.feature.yaml
			OneQuick.Reload()
		}
	}
	Exit(show_msg=true)
	{
		if(mq(lang("exit_msg"), 0x1134)) {
			ExitApp
		}
	}
	SetDisable(act="toggle")
	{
		setdisable := (act="toggle")? !(A_IsPaused&&A_IsSuspended): act
		OneQuick.SetState(setdisable, setdisable)
	}
	; hotkey
	SetSuspend(act="toggle")
	{
		setsuspend := (act="toggle")? !A_IsSuspended: act
		OneQuick.SetState(setsuspend, A_IsPaused)
	}
	; thread
	SetPause(act="toggle")
	{
		setpause := (act="toggle")? !A_IsPaused: act
		OneQuick.SetState(A_IsSuspended, setpause)
	}

	SetAutorun(act="toggle")
	{
		cfg := OneQuick.GetConfig("autorun", 0)
		autorun := (act="config")? cfg :act
		autorun := (act="toggle")? !cfg :autorun
		Regedit.Autorun(autorun, OneQuick.ProgramName, OneQuick.Launcher_Name)
		OneQuick.SetConfig("autorun", autorun)
		if(autorun)
		{
			Menu, Tray, Check, % lang("Autorun")
		}
		Else
		{
			Menu, Tray, UnCheck, % lang("Autorun")
		}
	}

	SetAutoUpdate(act="toggle")
	{
		cfg := OneQuick.GetConfig("auto_update", 0)
		au := (act="toggle") ?!cfg :act
		OneQuick.SetConfig("auto_update", au)
		if(au)
		{
			Menu, Tray, Check, % lang("AutoUpdate")
			OneQuick.Check_update(false)
		}
		Else
		{
			Menu, Tray, UnCheck, % lang("AutoUpdate")
		}
	}

	debug_mode(act="toggle")
	{
		debug := (act="toggle") ? !OneQuick._DEBUG_ :act
		OneQuick.SetConfig("debug", debug, "debug")
		OneQuick.Reload()
	}

	SetLang(act="itemname")
	{
		if(act="itemname")
		{
			lang_map := {"English": "en", "中文": "cn"}
			lang := lang_map[A_ThisMenuItem]
		}
		else {
			lang := act
		}
		OneQuick.SetConfig("lang", lang)
		OneQuick.Reload()
	}

}

; event callback
OnClipboardChange:
RunArr(OneQuick.OnClipboardChangeCmd)
Return

Sub_OnExit:
RunArr(OneQuick.OnExitCmd)
OneQuick.SaveUserData()
ExitApp

; --------------------------
SUB_VOID:
Return

Sub_Close_OneQuick_About:
Gui, Cancel
Return

Sub_Auto_Check_update:
SetTimer, Sub_Auto_Check_update, % -OneQuick.check_update_period
OneQuick.Check_update(false)
return

Sub_OneQuick_AHKHelp:
splitpath, a_ahkpath, , dir
helpfile := % dir "\AutoHotKey.chm"
if FileExist(helpfile){
	run(helpfile)
}
Else{
	m("Can't find help file.")
}
Return

Sub_OneQuick_EXE_Loc:
splitpath, a_ahkpath, , dir
run(dir)
Return

; //////////////////////////////////////////////////////////////////////////
; //////////////////////////////////////////////////////////////////////////
; //////////////////////////////////////////////////////////////////////////
; //////////////////////////////////////////////////////////////////////////
; //////////////////////////////////////////////////////////////////////////
; //////////////////////////////////////////////////////////////////////////

lang(key, default="")
{
	lang := OneQuick.GetConfig("lang", OneQuick.Default_lang)
	lang_file := OneQuick._LANG_DIR "" lang ".ini"
	FileEncoding
	IniRead, out, % lang_file, lang, % key, %A_Space%
	if(out=="") {
		if(lang!="en"||default!="")
			IniWrite,%A_Space%, % lang_file, lang, % key
		if(default=="")
			out := key
		else
			out := default
	}
	return out
}

class xArray
{
	; xArray.merge
	merge(arr1, arr2)
	{
		Loop, % arr2.MaxIndex()
		{
			arr1.Insert(arr2[A_Index])
		}
		return % arr1
	}
	; xArray.remove
	remove(arr, value)
	{
		Loop, % arr.MaxIndex()
		{
			if(arr[A_Index]=value) {
				arr.RemoveAt(A_Index)
				return % xArray.remove(arr, value)
			}
		}
		return % arr
	}
}

class http
{
	get(url)
	{
		try
		{
			oHttp := ComObjCreate("WinHttp.Winhttprequest.5.1")
			oHttp.open("GET", url)
			oHttp.send()
			return % oHttp.responseText
		}
		catch e
		{
			return ""
		}
	}
}

class File
{
	CreateDir(path)
	{
		if(path="") {
			Return
		}
		StringReplace, path, % path, /, \, All
		if(FileExist(path)) {
			return
		}
		SplitPath, % path,, OutDir
		if(OutDir!="" && !FileExist(OutDir)) {
			File.CreateDir(OutDir)
		}
		FileCreateDir, % path
	}

	; File.Download
	Download(url, path)
	{
		SplitPath, % path, , OutDir
		File.CreateDir(OutDir)
		UrlDownloadToFile, % url, % path
		return ErrorLevel
	}

	Append(content, path)
	{
		SplitPath, % path, , OutDir
		File.CreateDir(OutDir)
		FileAppend, % content, % path
	}

	Copy(SourcePattern, DestPattern, Flag = 0)
	{
		IfNotExist, % SourcePattern
			return -1
		SplitPath, % DestPattern, , OutDir
		File.CreateDir(OutDir)
		FileCopy, % SourcePattern, % DestPattern, % Flag
		return ErrorLevel
	}
}

class Tray
{
	; Tray.Tip
	Tip(msg, seconds=1, opt=0x1)
	{
		; //BUG traytip弹出后，第一次单击托盘图标的动作将失效，第二次单击或显示托盘菜单后正常
		TrayTip, % OneQuick.ProgramName, % msg, % seconds, % opt
		Return
		title := OneQuick.ProgramName
		cmd = "%A_AhkPath%" "%A_ScriptDir%\OneQuick.Core.ahk" -traytip "%title%" "%msg%" "%opt%"
		Run, %cmd%
		Return
	}

	; Tray.SetMenu
	SetMenu(menuList, ahk_std_menu=0)
	{
		Menu, Tray, DeleteAll
		if(ahk_std_menu) {
			Menu, Tray, Standard
			Menu, Tray, Add
		}
		else {
			Menu, Tray, NoStandard
		}
		xMenu.add("Tray", menuList)
	}

	; Tray.SetIcon
	SetIcon(path)
	{
		if(FileExist(path))
			Menu, Tray, Icon, %path%,,1
	}
}

class Regedit
{
	static Subkey_Autorun := "Software\Microsoft\Windows\CurrentVersion\Run"
	; Regedit.Autorun
	Autorun(switch, name, path="")
	{
		if(switch)
		{
			RegWrite, REG_SZ, HKCU, % Regedit.Subkey_Autorun, % name, % path
		}
		Else
		{
			RegDelete, HKCU, % Regedit.Subkey_Autorun, % name
		}
	}
	; Regedit.IsAutorun
	IsAutorun(name, path)
	{
		RegRead, output, HKCU, % Regedit.Subkey_Autorun, % name
		return % output==path
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
	static ClipsFirstShowNum = 
	static ClipsTotalNum = 

	Ini()
	{
		if (this.ini_registered == 1)
			Return
		OneQuick.OnClipboardChange("Sub_xClipboard_OnClipboardChange")
		OneQuick.OnExit("Sub_xClipboard_OnExit")
		this.Clips := OneQuick.UserData["xClipboard_Clips"]
		this.FavourClips := OneQuick.UserData["xClipboard_FavourClips"]
		this.ClipsFirstShowNum := OneQuick.GetFeatureCfg("clipboard.ClipsFirstShowNum", 10)
		this.ClipsTotalNum := OneQuick.GetFeatureCfg("clipboard.ClipsTotalNum", 50)
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
			if (A_Index <= this.ClipsFirstShowNum)
				Menu, xClipboard_AllclipsMenu, Add, % (A_Index<10?"&":"") A_Index ". " keyName, Sub_xClipboard_AllClips_Click
			Else
				Menu, xClipboard_AllclipsMenu_More, Add, % A_Index ". " keyName, Sub_xClipboard_AllClips_MoreClick
		}
		if (ClipsCount >= this.ClipsFirstShowNum)
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
idx := xClipboard.Clips.MaxIndex() - A_ThisMenuItemPos + 1 - xClipboard.ClipsFirstShowNum
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
while (xClipboard.ClipsTotalNum > 0 && xClipboard.Clips.MaxIndex() > xClipboard.ClipsTotalNum)
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
				,["submenu",["subitem_1","func3"]
				,["subitem_2",, {sub: "SubMenu", "disable"}]]])
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

	New(Menu_Name, Menu_Config)
	{
		this.Clear(Menu_Name)
		this.Add(Menu_Name, Menu_Config)
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

	; Sys.Win
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

		; Sys.Win.GotoPreTab
		GotoPreTab()
		{
			if(Sys.Win.Class()="PX_WINDOW_CLASS") {
				send ^{PgUp}
			}
			else {
				send ^+{tab}
			}
		}

		; Sys.Win.GotoNextTab
		GotoNextTab()
		{
			if(Sys.Win.Class()="PX_WINDOW_CLASS") {
				send ^{PgDn}
			}
			else {
				send ^{tab}
			}
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
d(str := "")
{
	if(OneQuick._DEBUG_)
	{
		m("[DEBUG]: " str)
	}
}

m(str := "")
{
	if(IsObject(str)) {
		str := "[Object]`n" Yaml_dump(str)
	}
	MsgBox, , % OneQuick.ProgramName, % str
}

mq(msg:="", opt:=0x1024, title:="")
{
	title := title="" ? OneQuick.ProgramName : title
	MsgBox, % opt, % title, % msg
	IfMsgBox YES
		return True
	return False
}

t(str := "")
{
	if (str != "")
		ToolTip, % str
	Else
		ToolTip
}

RunArr(arr)
{
	Loop, % arr.MaxIndex()
	{
		run(arr[A_Index])
	}
}

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
			if(brw=""||brw="default")
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
		else if(RegExMatch(command, "i)edit:\s*(.*)", f))
		{
			OneQuick.Edit(f1)
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