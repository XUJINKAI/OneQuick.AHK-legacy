[Back to README.md](https://github.com/XUJINKAI/OneQuick#onequick)

# Document

OneQuick is not only a convenient tool but also an autohotkey library. It provides useful classes and several features by default: Clipboard manager, quick search, screen border operation, and more.  
Check [OneQuick.ahk][OneQuick.ahk] for all the default features.

[OneQuick.ahk]:https://github.com/XUJINKAI/OneQuick/blob/master/OneQuick.ahk

### Files description
- **OneQuick Launcher.exe** runs *OneQuick.ahk*. It's useful and good-looking when the script autoruns.  
- **OneQuick.ahk** is like a config file that you can modify it for your own features and it contains default features' definition.  
- **OneQuick.User.ahk** is same as *OneQuick.ahk*. The file will be created and be included automatically. It contains a special class that the code inside only runs on particular PC.  
- **OneQuick.Core.ahk** is core file of OneQuick.  
- **OneQuick.Cache.PC-NAME.json** generates after OneQuick quit and save the information such as clipboard records.

### Classes/functions in *OneQuick.Core.ahk*
- **OneQuick**: main class. You should run _OneQuick.Ini()_ at first.  
It's a framework manages icon, right click menu, default editor, browser (when you open file or link by OneQuick), save config when quit, etc.  
- **m(), t()**: short form of msgbox and tooltip.  
- **run()**: It's a VERY IMPORTANT function in OneQuick. Almost all the commands run by this function. The command can be a label or a function name in OneQuick script, or a system build-in cmd, or other forms you may define. You can extend this function by write run_user().  
- **xClipboard**: clipboard manager class. Provides clipboard memory list, favourite list, quick search ability, run in CMD ability.  
- **Schedule**: schedule class like system's.   
- **WinMenu**: app's window operation class. Set window topmost, transparent, locate app's folder, hide/show window, get window's ID/class.  
- **xMenu**: custom menu class. Define a menu with AHK's list [].  
- **Sys**: system interaction class. Provides lots of functions about system such as power, screen, network, volume, cursor, window.  
With *Sys.Cursor.IsPos()*, OneQuick introduces a important feature: screen border operation.  

### Code Demo
- **Sync between PCs, particular codes run on particular PC**  
In _OneQuick.User.ahk_，a particular class named by your computer name is gererated automaticlly. Only in this computer the _Ini()_ function will be run.  

        class User_Your_Computer_Name
        {
                Run := 0
                Ini()
                {
                        this.Run := 1
                        ; e.g. diffrent pc has diffrent default editor
                        ; OneQuick.Editor := "C:\Program Files\Sublime Text 3\sublime_text.exe"
                        ; your code here (1)
                }
        }
        
        #if User_Your_Computer_Name.Run
        ; e.g. diffrent pc with diffrent shortcut
        ; #m::run calc
        ; your code here (2)
        #if

- **Extend function _run()_**  
_run()_ will find _run_user()_ function to run command if it fails.

        run_user(command)
        {
            ; e.g. if command is a number
            if(RegExMatch(command, "^\d+$"))
            {
                ; short for msgbox
                m(command)
            }
            else
            {
                m("Can't run command """ command """")
            }
        }
