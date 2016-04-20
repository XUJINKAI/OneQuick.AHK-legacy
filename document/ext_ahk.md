扩展自己的AHK代码 (OneQuick.Ext.ahk)
------------------------

在OneQuick.Ext.ahk文件中，你可以添加自己的ahk代码，利用OneQuick自带的函数，可以方便地扩展自己需要的功能。

第一次运行OneQuick会生成ext文件，并且自动包含一个以计算机名命名的class。
```
class User_PC_NAME
{
	Run := 0
	Ini()
	{
		this.Run := 1
	}
}
```

其中，User_PC_NAME.ini()只会在本机中运行，只要计算机名不同。因此你可以利用User_PC_NAME.run做很多个性化的定制。

**tip**: 初始化命令应该写在ini()中，写在外边不会执行。
        

### 设置默认编辑器
OneQuick 默认使用notepad当作文本编辑器，你可以在ext.ahk中修改自己的编辑器。

```
class User_PC_NAME
{
    Run := 0
    Ini()
    {
        this.Run := 1
        OneQuick.Editor := "C:\Program Files\Sublime Text 3\sublime_text.exe"
    }
}

只要在对应的ini() 函数中设置OneQuick.Editor即可。
```


### 扩展屏幕右上角右键菜单
鼠标移到屏幕右上角并点右键，会弹出快捷菜单，你可以扩展此菜单。

```
class User_PC_NAME
{
	Run := 0
	Ini()
	{
		this.Run := 1
		SetTimer, Sub_User_PC_NAME_Late, -1000
	}
}

Sub_User_PC_NAME_Late:
xMenu.Add("ScreenRTMenu"
	,[[],["notepad","notepad"]])
Return
```

延迟1秒是为了让扩展的菜单排在默认菜单后边。

使用**xMenu.Add(MenuName, MenuList)** 函数来添加菜单项。（对应地可以使用xMenu.Show(MenuName) 来显示创建的菜单）  
第一个参数是菜单的名字，这里是右上角菜单的名字`ScreenRTMenu`。  
第二个参数是一个数组，是菜单的内容。  
菜单数组中，[]表示分隔线，第一项是显示的名字，第二项是运行的命令。此数组可以嵌套，可以自由组合，具体格式可以参考OneQuick.ahk文件中的使用方法。