OneQuick
========================
OneQuick 是一款基于autohotkey的windows快捷工具。  
独创的屏幕边缘操作、文本快速搜索功能；还有剪贴板历史纪录、窗口操作菜单等一系列实用功能，操作windows也能如此爽快。  
OneQuick也为扩展代码留下了足够的空间，你可以基于OneQuick提供的大量函数开发自己的ahk脚本。

OneQuick is an Autohotkey script, it is both a convenient tool and an ahk library.  
It provides clipboard manager, screen border operation, window operation, quick menu, etc.  
It's also a useful library to write your own ahk code.  


安装
------------------------
到<https://github.com/XUJINKAI/OneQuick/releases>下载最新的压缩包，解压执行**OneQuick Launcher.exe** 即可。  
_OneQuick基于[AHK][AHK]，如果没有安装的话会先安装AHK。_


帮助 & 文档
------------------------
关于如何配置功能与开发，请[查看这里][DOCUMENT]


默认功能
------------------------
#### 剪贴板增强 · clipboard
ctrl + shift + x：打开剪贴板记录  
ctrl + shift + c：复制并打开操作列表  
ctrl + shift + v：直接打开操作列表  

在操作列表中:  
**TAB**: 粘贴  
**空格**: 执行当前内容 (可以是网址、命令行、甚至b站av号)  
**字母按键**: 使用搜索引擎搜索当前内容 (如b为百度，g为google，m为豆瓣电影等)  
**数字按键**: 切换浏览器 (修改OneQuick内部默认的浏览器)  
你也可以将当前的内容**加入到收藏夹**或**删除**  

#### 屏幕边缘操作 · screen border
**左上角 · LT**  
滚轮/单击滚轮：音量大小/静音  
shift + 滚轮：屏幕亮度  
右键：窗口操作菜单  

**右上角 · RT**  
滚轮/单击滚轮：歌曲上一首/下一首/播放或暂停  
右键：用户自定义菜单（[如何扩展菜单][ext_rt_menu]）  

**左边框 & 右边框 · L-R**  
滚轮：翻页  
shift + 滚轮：翻页x5  
ctrl + shift + 滚轮：翻到第一页/最后一页  

**上边框 · T**  
滚轮：标签页切换  

**下边框 · B**  
滚轮/单击滚轮：(win10) 虚拟桌面切换/查看(win+tab键)

#### 应用增强 · app enhance  
ctrl+w 关闭记事本  
chrome 标签滚轮切换  
使用sublime时，按win+E 打开当前正在编辑的文件所在的目录  

#### 快捷键 · hotkey
**win + Z：显示功能菜单（GreatMenu）**  
win + T：当前窗口最前端  
win + 鼠标右键：弹出当前窗口的操作菜单  
shift + 滚轮：翻页  
win + N：打开系统记事本  
ctrl + W：(当前窗口是记事本时) 关闭记事本  
win + shift + L：立刻锁定计算机并关闭屏幕  
ctrl + alt + R：打开OneQuick Command Run窗口 (可执行命令行、脚本中的函数或Label、b站av号等)  
ctrl + shift + alt + R：重新启动OneQuick  

#### 其他  
左键单击OneQuick托盘图标可以暂停程序运行（在suspended和paused组合的四种状态间循环）；  
右键单击OneQuick托盘图标可打开OneQuick菜单，设置自启动，打开脚本目录，或AHK帮助文件等；  


Q&A
------------------------

#### OneQuick的由来？  
OneQuick开始于2014年初，最初只是自用，经历过几次大的重写，断断续续，到2015年左右成型。用到现在又快一年了，在这一年中，我发现我已经离不开OneQuick了，当临时使用别人的电脑时，会因为没有相关的快捷设置而无所适从。将OneQuick发布出来，也是作为自己研究生生涯的纪念。

#### OneQuick对管理员权限程序（任务管理器等）不起作用？  
运行AHK目录下的EnableUIAccess2AHK.ahk 即可.  

#### 修改 OneQuick 默认的文本编辑器？  
参考[这里][ext_default_editor]  

#### 让OneQuick支持更多ahk功能，如快速输入字符串？  
参考[这里][ext_ahk_code]  

#### 执行b站av号是怎么回事？  
OneQuick可以“执行”【"av"+数字】格式的字串。  
比如，按ctrl + shift + c 复制 `av314` 并弹出菜单后，再按空格即可打开相应视频。  
扩展类似的功能可以参考[这里][run_func]  

#### 剪贴板只能保存文本记录？  
是的，OneQuick的剪贴板记录暂不支持图片等内容。不过，只要不利用OneQuick的剪贴板记录切换内容，系统剪贴板就不会受到影响。


关于
------------------------
博客：http://xujinkai.info/  
微博：http://weibo.com/johnkale  
知乎相关回答：https://www.zhihu.com/question/36847530/answer/92868539 快来点赞！  
简单的问卷调查：https://www.wenjuan.com/s/R7fyEv/  


版权 · License
------------------------
修改、分享请注明作者信息。
> XJK: https://github.com/XUJINKAI  

以GPL协议发布。  

[AHK]: https://autohotkey.com/
[DOCUMENT]: https://github.com/XUJINKAI/OneQuick/wiki
[ext_rt_menu]: https://github.com/XUJINKAI/OneQuick/wiki/OneQuick.Ext.ahk#扩展屏幕右上角右键菜单
[ext_default_editor]: https://github.com/XUJINKAI/OneQuick/wiki/OneQuick.Ext.ahk#设置默认编辑器
[ext_ahk_code]: https://github.com/XUJINKAI/OneQuick/wiki/OneQuick.Ext.ahk#定义额外的快捷键
[run_func]: https://github.com/XUJINKAI/OneQuick/wiki/run_function

------------------------
##### FROM OTHER PROJECT  
JSON: https://github.com/cocobelgica/AutoHotkey-JSON  
YAML：https://github.com/HotKeyIt/Yaml  
ICON: http://www.iconarchive.com/show/flatastic-1-icons-by-custom-icon-design.html, http://www.iconarchive.com/show/flatastic-2-icons-by-custom-icon-design.html  