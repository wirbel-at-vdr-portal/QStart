# About
This tiny program is intended to be a replacement for the now missing old IE Quick Launch since 24H2.
It cannot do the same, but it will help me to circumvent this missing feature of W1x.

It's intended to be *attached to the taskbar*, so it might be started, but it's not running by default.

As long not beeing started, only it's yellow Q icon is visible in the taskbar.
If you click on it, it opens a new window with program start buttons.

# Configuring QStart
This tool depends on one folder with Windows shortcuts (*.lnk) to programs. The default folder is

**%appdata%\Microsoft\Internet Explorer\Quick Launch**

Any link (shortcut, *.lnk) in this folder will appear in QStart.

This default folder can be changed to any other location. On the first start,
QStart creates a config file, where you may change this folder to your preference:

**C:\users\<USERNAME>\AppData\Local\QStart\settings.ini**

The file is splitted in sections, marked with square brackets. Each section has properties:
```
[Global]
LocalDir=c:\users\MUSTERMANN\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch
```

# What this tool does..
For every shortcut found, the programs reads from the link full path, arguments and working folder. Then, a button is created for each link with this information.


