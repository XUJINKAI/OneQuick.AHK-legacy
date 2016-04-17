OneQuick
========================
OneQuick 是一款快捷键工具，让你操作电脑事半功倍。

**剪贴板增强**，剪贴板历史纪录，对条目加入收藏夹，一键搜索，或一键执行。  
**屏幕边角操作**，滑动鼠标到屏幕边缘，转动滚轮或点击完成操作，翻页、音量、换歌、虚拟桌面等诸多功能可自定义。  
**窗口操作**，对任意窗口置顶，隐藏，调整透明度，查看程序信息或打开程序目录。  
还有鼠标位置、屏幕取色、编辑HOSTS并刷新DNS缓存等许多快捷功能。  

同时，OneQuick的核心定义在一个独立文件中，引用OneQuick.Core.ahk文件，即是一个AHK增强库。  
OneQuick对托盘、配置文件读写、网盘同步等场景做了许多加强。  

OneQuick is an Autohotkey script, it is both a convenient tool and an ahk library.  
It provides clipboard manager, screen border operation, window operation, quick menu, etc.  
It's also a useful library to write your own ahk code.  
Here for details: [DOCUMENT.md][DOCUMENT]  

[DOCUMENT]:https://github.com/XUJINKAI/OneQuick/blob/master/DOCUMENT.md


简单的问卷调查，让我更好了解你的需求：https://www.wenjuan.com/s/R7fyEv/



安装 · Install
------------------------
OneQuick 脚本本身不需要安装，但执行脚本需要 AHK 支持，你可以到这里
<a href="https://autohotkey.com/" target="_blank">https://autohotkey.com/</a> 下载AHK，安装AHK后，双击 **OneQuick Launcher.exe** 即可运行。

由于系统限制，AHK 无法对任务管理器等管理员权限运行的程序执行窗口操作，若有这方面需要，可以下载 <a href="https://autohotkey.com/board/topic/70449-enable-interaction-with-administrative-programs/" target="_blank">EnableUIAccess</a>，解压后，运行 EnableUIAccess.ahk，定位到AHK的安装目录，选择 autohotkey.exe 并覆盖保存即可。



默认功能 · Default features
------------------------
所有默认的功能配置都在OneQuick.ahk中。

#### 剪贴板增强 · clipboard manager  
ctrl + shift + x：打开剪贴板记录  
ctrl + shift + c：复制并打开操作列表  
ctrl + shift + v：直接打开操作列表  

在操作列表中:  
**TAB**: 粘贴  
**空格**: 直接执行当前内容 (可以是网址、命令行、甚至b站av号)  
**字母按键**: 使用搜索引擎搜索当前内容 (如b为百度，g为google，m为豆瓣电影等)  
**数字按键**: 切换浏览器 (修改OneQuick内部默认的浏览器)  
你也可以将当前的内容**加入到收藏夹**或**删除**  

#### 用户自定义菜单 · custom menu  
按win+z或鼠标在屏幕右上角右击可以打开自定义菜单  
在菜单中可以打开组策略、编辑HOSTS文件、刷新DNS缓存等  
用户还可以自定义自己的程序列表或命令  

#### 屏幕边角操作 · screen border  
**左上角**  
滚轮：音量  
单击滚轮：静音  
shift + 滚轮：屏幕亮度  
右键：窗口操作菜单  

**右上角**  
右键：用户自定义菜单  
滚轮：歌曲上一首/下一首  
单击滚轮：歌曲暂停/播放  

**左边框 & 右边框**  
滚轮：翻页  
shift + 滚轮：翻页x5  
ctrl + shift + 滚轮：翻到第一页/最后一页  

**上边框**  
滚轮：标签页切换  

**下边框**  
滚轮：虚拟桌面切换 (windows 10)  
单击滚轮：查看虚拟桌面 (相当于win+tab)  

#### 快捷键 · shortcut
win + T：当前窗口最前端  
win + 鼠标右键：弹出当前窗口的操作菜单  
shift + 滚轮：翻页  
win + N：打开系统记事本  
ctrl + W：(当前窗口是记事本时) 关闭记事本  
win + shift + L：立刻锁定计算机并关闭屏幕  
win + Z：显示自定义菜单  
lctrl + lalt + R：打开OneQuick Command Run窗口 (可执行命令行、脚本中的函数或Label、b站av号等)  
ctrl + shift + alt + R：重新启动OneQuick  

#### 应用增强 · app enhance  
鼠标放在chrome标签上滚动即可切换标签页；  
使用sublime时，按win+E 打开当前正在编辑的文件所在的目录；  

#### 其他 · other  
左键单击OneQuick托盘处图标可以暂停程序运行（在suspended和paused组合的四种状态间循环）；  
右击OneQuick托盘图标可打开OneQuick菜单，设置自启动，打开脚本目录，或AHK帮助文件等；  
在OneQuick.Core.ahk文件中，定义了类似于计划任务的模块（class Schedule），用户可自行利用；  
在OneQuick.Core.ahk文件中，定义了更多常用系统操作（class Sys），用户可自行查看。



高级功能
------------------------
[文档，示例请参考这里](https://github.com/XUJINKAI/OneQuick/issues?utf8=%E2%9C%93&q=is%3Aissue+label%3Adocument)



文件说明 · Files description
------------------------
**OneQuick Launcher.exe**：OneQuick的引导程序，与直接执行 OneQuick.ahk 作用相同，主要为了设置为自启动时方便（图标也好看）  
**OneQuick.ahk**：运行由这里开始，也是默认功能的配置文件。  
**OneQuick.User.ahk**：本文件将自动生成，用户可在其中定义自己的代码。在此文件中，可以定义只在本机执行的代码，这在云盘同步时非常有用。  
**OneQuick.Core.ahk**：OneQuick 的核心文件，一般不建议修改。  
**OneQuick.Cache.PC-NAME.json**：退出时生成，记录OneQuick的配置及数据。  



Q&A
------------------------

#### OneQuick的由来？  
OneQuick开始于2014年初，最初只是自用，经历过几次大的重写，断断续续，到2015年左右成型。用到现在又快一年了，在这一年中，我发现我已经离不开OneQuick了，当临时使用别人的电脑时，会因为没有相关的快捷设置而无所适从。将OneQuick发布出来，也是作为自己研究生生涯的纪念。

#### 配置OneQuick的功能必须直接修改脚本吗？  
是的。AHK代码本身非常简单，比如`#n::run notepad`即可使用win+n键打开记事本，做图形界反而会吃力不讨好。  

#### 执行b站av号是怎么回事？  
OneQuick可以“执行”【"av"+数字】格式的字串。比如，按ctrl + shift + c 复制 **av314** 并弹出菜单后，再按空格即可打开相应视频。这个功能定义在run() 函数中，也可以在run_user() 函数中扩展。

#### 关于网盘同步？  
在OneQuick.User.ahk文件中，OneQuick会自动创建以计算机名命名的class，在此class中写的代码只会在此计算机中运行。这个功能对有多台电脑的用户非常实用。

#### 不想用默认记事本，如何修改 OneQuick 默认的文本编辑器？  
在OneQuick.User.ahk中，找到以本计算机名命名的class，将下列代码复制到ini() 函数中即可。引号中为编辑器的路径，如下以安装在C盘的sublime举例。

	OneQuick.Editor := "C:\Program Files\Sublime Text 3\sublime_text.exe"

#### 剪贴板只能保存文本？  
是的，OneQuick的剪贴板记录暂不支持图片等内容，复制文件会记录成文件路径。



关于
------------------------
博客：http://xujinkai.info/  
微博链接: http://weibo.com/1657846235/DnitJ1ONc  
知乎相关回答：https://www.zhihu.com/question/36847530/answer/92868539  


版权 · License
------------------------
修改、分享请注明作者信息。
> XJK: https://github.com/XUJINKAI  

以GPL协议发布。  


------------------------
##### FROM OTHER PROJECT  
JSON: https://github.com/cocobelgica/AutoHotkey-JSON  
ICON: http://www.iconarchive.com/show/flatastic-1-icons-by-custom-icon-design.html, http://www.iconarchive.com/show/flatastic-2-icons-by-custom-icon-design.html  
