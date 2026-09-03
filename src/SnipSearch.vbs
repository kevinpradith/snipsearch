' Runs Invoke-SnipSearch.ps1 without a console window flashing on screen.
' An optional argument is passed through as -Mode (lens or text).
Dim folder, mode
folder = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\"))
mode = ""
If WScript.Arguments.Count > 0 Then mode = " -Mode " & WScript.Arguments(0)
CreateObject("WScript.Shell").Run _
    "powershell.exe -NoProfile -Sta -ExecutionPolicy Bypass -File """ & _
    folder & "Invoke-SnipSearch.ps1""" & mode, 0, False
