在setting.yaml中，你可以快速配置OneQuick而不需写ahk代码。

**注意**： setting.yaml文件中**不可以**出现任何中文字符，即使是中文标点符号；  
OneQuick会随时读写此文件，所以里边的注释会消失。

第一次运行时，OneQuick会拷贝*script/OneQuick.setting.default.yaml* 到根目录*OneQuick.setting.yaml*。  
你可以任意修改*OneQuick.setting.yaml*，如果出现问题，只要将*script/OneQuick.setting.default.yaml*重新覆盖过去即可 (可能需要在退出OneQuick的状态下操作）。

在setting.yaml中，定义了所有OneQuick的功能配置和开关。  
如将_onequick_.autorun 改为1 即可让OneQuick随系统启动运行。  
将hotkey.switch 改为1，即可一次性禁用所有hotkey下注册的热键。

你可以修改clipboard.browser和clipboard.search配置自己的浏览器选项和快速搜索，可选择的值在相应的default字串中。

在**hotkey.buildin**和**screen-border.action**中，定义了全局热键和屏幕边缘操作。  
- 键名：可以是字母，数字，win, ctrl, shift (包括l/r版本， 如lctrl/rshift），表示鼠标操作的lclick/rclick/wheelclick/wheelup/wheeldown。  
键名是对ahk命令的简单替换，更多可参考ahk文档。
- 值：可以是cmd命令或网址，脚本中的函数或sub名，b站av号，ahk中的send命令
- screen-border 符号：LR表示左右，TB表示上下（top/bottom），如LT表示左上角，B表示下边缘，  
你可以把符号连起来写，用'-'连接，比如L-R表示左右边缘都有效。  
**注意**：LR必须在TB前边，不能写成TL