- ### [修改setting.yaml][setting_yaml]
- ### [扩展Ext.ahk][ext_ahk]

- ### 目录结构
```
│  OneQuick Launcher.ahk            编译生成OneQuick Launcher.exe
│  OneQuick Launcher.exe            执行script/OneQuick.ahk
│  OneQuick.Ext.ahk                 ahk脚本扩展
│  OneQuick.setting.yaml            配置文件
├─AHK           打包autohotkey.exe
├─data          程序运行时保存的数据，如剪贴板记录等
│      OneQuick.Data.PC-NAME.json
├─document          文档
├─icon          托盘图标
├─lang          语言文件
├─script
│      JSON.ahk
│      OneQuick.ahk         入口，加载core，加载ext.ahk，加载setting.yaml
│      OneQuick.Core.ahk
│      OneQuick.setting.default.yaml            默认
│      Yaml.ahk
└─tool          扩展工具
```

[setting_yaml]: https://github.com/XUJINKAI/OneQuick/tree/master/document/setting_yaml.md
[ext_ahk]: https://github.com/XUJINKAI/OneQuick/tree/master/document/ext_ahk.md