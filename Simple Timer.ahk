#Requires AutoHotkey v2.0
; #NoTrayIcon
#Include Libraries\DarkGui.ahk
#Include Libraries\ContextColor.ahk
#Include Libraries\Dark Message Box.ahk
#SingleInstance Force
 CoordMode 'Mouse','screen'
 CoordMode 'ToolTip','screen'
 global iconfolder :=  "Libraries\Icons\"




; =============================================================================
; SIMPLE TIMER
; =============================================================================
SimpleTimer()
class SimpleTimer {
    ; Instance properties
    endTime := 0
    showFormat := "hms"
    tooltipX := 0
    tooltipY := 0
    remind5Min := true
    remind2Min := true
    mainGui := ""
    timerExpired := false
    reminder5MinShown := false
    reminder2MinShown := false
    
    ; Default Pomodoro Options
    static defaultPomodoroType := "25/5"  ; "25/5" or "50/10"
    static defaultRounds := 4 ; 
    
    pomodoroGui := ""
    isPomodoroMode := false
    pomodoroType := ""
    pomodoroRounds := 0
    currentRound := 0
    isBreakTime := false
    workDuration := 0
    breakDuration := 0
    pomodoroRemind5Min := true
    pomodoroRemind2Min := true
    
    ; Theme management
    themeManager := ""
    guiTheme := ""
    themeSwitchManager := ""
    
    ; GUI controls (stored as properties for easy access)
    showHoursCheckbox := ""
    showMinutesCheckbox := ""
    showSecondsCheckbox := ""
    remind5MinCheckbox := ""
    remind2MinCheckbox := ""
    
    ; Pomodoro GUI controls
    pomodoro25Checkbox := ""
    pomodoro50Checkbox := ""
    rounds1Checkbox := ""
    rounds2Checkbox := ""
    rounds3Checkbox := ""
    rounds4Checkbox := ""
    rounds5Checkbox := ""
    pomodoroRemind5MinCheckbox := ""
    pomodoroRemind2MinCheckbox := ""
    
    __New() {
        this.SetTimerIcon() ; Set the tray icon based on the current theme
        this.InitializeThemeManager()
        this.CreateAndShowGUI()
    }


    
    ; Initialize the theme management system
    InitializeThemeManager() {
        this.themeManager := ThemeManager()
        this.guiTheme := GUITheme()
    }
    
    SetTimerIcon() { ; attempts to set the tray icon based on the current theme. Icons must be stored in the icon folder, and that location can be changed at the top.
            try{       
            isDarkMode := RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "SystemUsesLightTheme") = 0
            if isDarkMode
            try {
            TraySetIcon(iconfolder "timerdark.ico")
            }
            catch{
                try {
                TraySetIcon(iconfolder "timer.ico")
                }
            }
            } 
            catch {
            try {
            TraySetIcon(iconfolder "timerdark.ico")
            }
    }
    }
    ; Show the timer GUI 
    ShowTimerGUI() {
        ; Reset timer state flags
        this.timerExpired := false
        this.reminder5MinShown := false
        this.reminder2MinShown := false
        
        if (this.mainGui) {
            this.mainGui.Show()
            ; Reapply theme when showing
            this.ApplyThemeToGui(this.mainGui)
            return
        }

        this.CreateAndShowGUI()
    }
    
    ; Create and show GUI on startup
    CreateAndShowGUI() {
        this.CreateGUI()
        this.SetupThemeManager()
        this.ApplyThemeToGui(this.mainGui)
        this.mainGui.Show()
    }
    
    ; Enhanced theme application with title bar dark mode
    ApplyThemeToGui(guiObj) {
        currentTheme := this.themeManager.GetCurrentTheme()
        this.guiTheme.ApplyTheme(guiObj, currentTheme)
        
        ; Apply dark/light title bar
        if (guiObj.Hwnd) {
            if (currentTheme = "Dark") {
                ; Enable dark mode for title bar
                DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", guiObj.Hwnd, "UInt", 20, "Int*", 1, "UInt", 4)
                ; Set border color to match dark theme
                DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", guiObj.Hwnd, "UInt", 35, "Int*", 0x252526, "UInt", 4)
            } else {
                ; Disable dark mode for title bar
                DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", guiObj.Hwnd, "UInt", 20, "Int*", 0, "UInt", 4)
            }
            ; Force redraw
            DllCall("RedrawWindow", "Ptr", guiObj.Hwnd, "Ptr", 0, "Ptr", 0, "UInt", 0x1 | 0x4)
        }
    }

CreateGUI() {
    ; this.mainGui := Gui("+Resize +AlwaysOnTop", "Simple Timer")

        this.mainGui := Gui("+Resize", "Simple Timer")

    ; Create GUI controls
    this.mainGui.Add("Text", , "Select a timer duration:")
    
    ; Timer duration buttons
    this.mainGui.Add("Button", "w50", "1m").OnEvent("Click", ObjBindMethod(this, "SetCommonTimer"))
    this.mainGui.Add("Button", "x+5 w50", "2m").OnEvent("Click", ObjBindMethod(this, "SetCommonTimer"))
    this.mainGui.Add("Button", "x+5 w50", "5m").OnEvent("Click", ObjBindMethod(this, "SetCommonTimer"))
    this.mainGui.Add("Button", "x+5 w50", "10m").OnEvent("Click", ObjBindMethod(this, "SetCommonTimer"))
    this.mainGui.Add("Button", "x+5 w50", "15m").OnEvent("Click", ObjBindMethod(this, "SetCommonTimer"))
    
    this.mainGui.Add("Button", "xm y+5 w50", "20m").OnEvent("Click", ObjBindMethod(this, "SetCommonTimer"))
    this.mainGui.Add("Button", "x+5 w50", "25m").OnEvent("Click", ObjBindMethod(this, "SetCommonTimer"))
    this.mainGui.Add("Button", "x+5 w50", "30m").OnEvent("Click", ObjBindMethod(this, "SetCommonTimer"))
    this.mainGui.Add("Button", "x+5 w50", "45m").OnEvent("Click", ObjBindMethod(this, "SetCommonTimer"))
    this.mainGui.Add("Button", "x+5 w50", "1h").OnEvent("Click", ObjBindMethod(this, "SetCommonTimer"))
    
    this.mainGui.Add("Button", "xm y+10 w120", "Custom Timer").OnEvent("Click", ObjBindMethod(this, "SetCustomTimer"))
    this.mainGui.Add("Button", "x+5 yp w120", "Pomodoro Timer").OnEvent("Click", ObjBindMethod(this, "ShowPomodoroGUI"))
    
    ; Display format options - checkboxes with vertically centered text labels
    this.mainGui.Add("Text", "xm y+10", "Display format:")
    
    this.showHoursCheckbox := this.mainGui.Add("Checkbox", "xm Checked w20 h20")
    this.mainGui.Add("Text", "x+0 yp w50 h20 0x200", "Hours")
    
    this.showMinutesCheckbox := this.mainGui.Add("Checkbox", "x+5 yp w20 h20 Checked")
    this.mainGui.Add("Text", "x+0 yp w50 h20 0x200", "Minutes")
    
    this.showSecondsCheckbox := this.mainGui.Add("Checkbox", "x+5 yp w20 h20 Checked")
    this.mainGui.Add("Text", "x+0 yp w50 h20 0x200", "Seconds")
    
    ; Reminder options - checkboxes with vertically centered text labels
    this.mainGui.Add("Text", "xm y+10", "Time Remaining Options:")
    
    this.remind5MinCheckbox := this.mainGui.Add("Checkbox", "xm Checked w20 h20")
    this.mainGui.Add("Text", "x+0 yp w120 h20 0x200", "5 minute reminder")
    
    this.remind2MinCheckbox := this.mainGui.Add("Checkbox", "xm y+5 Checked w20 h20")
    this.mainGui.Add("Text", "x+0 yp w120 h20 0x200", "2 minute reminder")

    ; GUI events
    this.mainGui.OnEvent("Close", (*) => this.OnGuiClose())
}


; Show Pomodoro Timer GUI
ShowPomodoroGUI(*) {
    this.mainGui.Hide()
    
    if (this.pomodoroGui) {
        this.pomodoroGui.Show()
        this.ApplyThemeToGui(this.pomodoroGui)
        return
    }
    
    this.CreatePomodoroGUI()
    this.SetupPomodoroThemeManager()
    this.ApplyThemeToGui(this.pomodoroGui)
    this.pomodoroGui.Show()
}

CreatePomodoroGUI() {
    ; Force exact same dimensions as main GUI
    this.pomodoroGui := Gui("+Resize", "Pomodoro Timer")
    
    ; Left column - Pomodoro Options (match main GUI Y positions)
    this.pomodoroGui.Add("Text", "xm", "Pomodoro Options:")
    
    this.pomodoro25Checkbox := this.pomodoroGui.Add("Checkbox", "xm y+5 w20 h20 " . (SimpleTimer.defaultPomodoroType = "25/5" ? "Checked" : ""))
    this.pomodoroGui.Add("Text", "x+0 yp w80 h20 0x200", "25 On/5 Off")
    
    this.pomodoro50Checkbox := this.pomodoroGui.Add("Checkbox", "xm y+5 w20 h20 " . (SimpleTimer.defaultPomodoroType = "50/10" ? "Checked" : ""))
    this.pomodoroGui.Add("Text", "x+0 yp w80 h20 0x200", "50 On/10 Off")
    
    ; Right column - Rounds (side by side with Pomodoro options)
    this.pomodoroGui.Add("Text", "x150 ym", "Rounds:")
    
    this.rounds2Checkbox := this.pomodoroGui.Add("Checkbox", "x150 y+5 w20 h20 " . (SimpleTimer.defaultRounds = 2 ? "Checked" : ""))
    this.pomodoroGui.Add("Text", "x+0 yp w20 h20 0x200", "2")
    
    this.rounds4Checkbox := this.pomodoroGui.Add("Checkbox", "x+10 yp w20 h20 " . (SimpleTimer.defaultRounds = 4 ? "Checked" : ""))
    this.pomodoroGui.Add("Text", "x+0 yp w20 h20 0x200", "4")
    
    this.rounds3Checkbox := this.pomodoroGui.Add("Checkbox", "x150 y+5 w20 h20 " . (SimpleTimer.defaultRounds = 3 ? "Checked" : ""))
    this.pomodoroGui.Add("Text", "x+0 yp w20 h20 0x200", "3")
    
    this.rounds5Checkbox := this.pomodoroGui.Add("Checkbox", "x+10 yp w20 h20 " . (SimpleTimer.defaultRounds = 5 ? "Checked" : ""))
    this.pomodoroGui.Add("Text", "x+0 yp w20 h20 0x200", "5")
    
    ; Time Remaining Options - placed below the 50 On/10 Off checkbox
    this.pomodoroGui.Add("Text", "xm y+10", "Time Remaining Options:")
    
    this.pomodoroRemind5MinCheckbox := this.pomodoroGui.Add("Checkbox", "xm y+5 Checked w20 h20")
    this.pomodoroGui.Add("Text", "x+0 yp w120 h20 0x200", "5 minute reminder")
    
    this.pomodoroRemind2MinCheckbox := this.pomodoroGui.Add("Checkbox", "xm y+5 Checked w20 h20")
    this.pomodoroGui.Add("Text", "x+0 yp w120 h20 0x200", "2 minute reminder")
    
    ; Custom button - positioned at same Y as the 2 minute reminder
    this.pomodoroGui.Add("Button", "x150 yp-35 w120", "Custom").OnEvent("Click", ObjBindMethod(this, "SetCustomPomodoro"))
    
    ; Start button - positioned below Custom button with y+5 spacing
    this.pomodoroGui.Add("Button", "x150 y+5 w120 Default", "Start Pomodoro").OnEvent("Click", ObjBindMethod(this, "StartPomodoro"))
    
    ; Force exact same size as main GUI
    this.pomodoroGui.Move(,, 306, 282)
    
    ; Event handlers...
    this.pomodoro25Checkbox.OnEvent("Click", ObjBindMethod(this, "OnPomodoro25Click"))
    this.pomodoro50Checkbox.OnEvent("Click", ObjBindMethod(this, "OnPomodoro50Click"))
    this.rounds2Checkbox.OnEvent("Click", ObjBindMethod(this, "OnRounds2Click"))
    this.rounds3Checkbox.OnEvent("Click", ObjBindMethod(this, "OnRounds3Click"))
    this.rounds4Checkbox.OnEvent("Click", ObjBindMethod(this, "OnRounds4Click"))
    this.rounds5Checkbox.OnEvent("Click", ObjBindMethod(this, "OnRounds5Click"))
    
    this.pomodoroGui.OnEvent("Close", (*) => this.OnPomodoroGuiClose())
}



;///////////////////////////

OnPomodoro25Click(*) {
    if (this.pomodoro25Checkbox.Value) {
        this.pomodoro50Checkbox.Value := 0
    }
}

OnPomodoro50Click(*) {
    if (this.pomodoro50Checkbox.Value) {
        this.pomodoro25Checkbox.Value := 0
    }
}

; Round option event handlers
OnRounds2Click(*) {
    if (this.rounds2Checkbox.Value) {
        this.rounds3Checkbox.Value := 0
        this.rounds4Checkbox.Value := 0
        this.rounds5Checkbox.Value := 0
    }
}

OnRounds3Click(*) {
    if (this.rounds3Checkbox.Value) {
        this.rounds2Checkbox.Value := 0
        this.rounds4Checkbox.Value := 0
        this.rounds5Checkbox.Value := 0
    }
}

OnRounds4Click(*) {
    if (this.rounds4Checkbox.Value) {
        this.rounds2Checkbox.Value := 0
        this.rounds3Checkbox.Value := 0
        this.rounds5Checkbox.Value := 0
    }
}

OnRounds5Click(*) {
    if (this.rounds5Checkbox.Value) {
        this.rounds2Checkbox.Value := 0
        this.rounds3Checkbox.Value := 0
        this.rounds4Checkbox.Value := 0
    }
}

; Also fix the StartPomodoro method - remove rounds1Checkbox reference
StartPomodoro(*) {
    ; Determine selected pomodoro type
    if (this.pomodoro25Checkbox.Value) {
        this.workDuration := 25
        this.breakDuration := 5
        this.pomodoroType := "25/5"
    } else if (this.pomodoro50Checkbox.Value) {
        this.workDuration := 50
        this.breakDuration := 10
        this.pomodoroType := "50/10"
    } else {
        MsgBox("Please select a Pomodoro option (25/5 or 50/10)", "No Option Selected", "0x40000 16")
        return
    }
    
    ; Determine selected rounds
    if (this.rounds2Checkbox.Value) {
        this.pomodoroRounds := 2
    } else if (this.rounds3Checkbox.Value) {
        this.pomodoroRounds := 3
    } else if (this.rounds4Checkbox.Value) {
        this.pomodoroRounds := 4
    } else if (this.rounds5Checkbox.Value) {
        this.pomodoroRounds := 5
    } else {
        MsgBox("Please select number of rounds", "No Rounds Selected", "0x40000 16")
        return
    }
    
    ; Set up pomodoro session
    this.isPomodoroMode := true
    this.currentRound := 1
    this.isBreakTime := false
    this.pomodoroRemind5Min := this.pomodoroRemind5MinCheckbox.Value
    this.pomodoroRemind2Min := this.pomodoroRemind2MinCheckbox.Value
    
    ; Hide both GUIs
    this.pomodoroGui.Hide()
    if (this.mainGui) {
        this.mainGui.Hide()
    }
    
    this.StartPomodoroWork()
}

; Custom Pomodoro input
SetCustomPomodoro(*) {
    customInput := InputBox("Please input custom pomodoro option. Use Format `"On.Off.Rounds`". `n`nFor example, 20 minutes working, 5 minute break, for 3 rounds: `n`"20.5.3.`"", "Custom Pomodoro")
    if !customInput.Result {
        return
    }
    
    try {
        parts := StrSplit(customInput.Value, ".")
        if (parts.Length != 3) {
           return  ; Fail silently instead of throwing
        }
        
        workMin := Integer(parts[1])
        breakMin := Integer(parts[2])
        rounds := Integer(parts[3])
        
        if (workMin <= 0 || breakMin <= 0 || rounds <= 0) {
           return  ; Fail silently instead of throwing
        }
        
        ; Start custom pomodoro
        this.StartCustomPomodoro(workMin, breakMin, rounds)
        this.pomodoroGui.Hide()
        
    } catch {
       return  ; Fail silently on any error
    }
}

StartCustomPomodoro(workMin, breakMin, rounds) {
    this.isPomodoroMode := true
    this.workDuration := workMin
    this.breakDuration := breakMin
    this.pomodoroRounds := rounds
    this.currentRound := 1
    this.isBreakTime := false
    this.pomodoroRemind5Min := this.pomodoroRemind5MinCheckbox.Value
    this.pomodoroRemind2Min := this.pomodoroRemind2MinCheckbox.Value
    
    ; Hide both GUIs
    this.pomodoroGui.Hide()
    if (this.mainGui) {
        this.mainGui.Hide()
    }
    
    this.StartPomodoroWork()
}

; Start work session
StartPomodoroWork() {
    this.isBreakTime := false
    this.SetupTimer(
        this.workDuration,
        this.showHoursCheckbox.Value,
        this.showMinutesCheckbox.Value,
        this.showSecondsCheckbox.Value,
        this.pomodoroRemind5Min,
        this.pomodoroRemind2Min
    )
}

; Start break session
StartPomodoroBreak() {
    this.isBreakTime := true
    this.SetupTimer(
        this.breakDuration,
        this.showHoursCheckbox.Value,
        this.showMinutesCheckbox.Value,
        this.showSecondsCheckbox.Value,
        false,  ; No reminders during break
        false
    )
}

; Setup Pomodoro theme manager
SetupPomodoroThemeManager() {
    if (this.pomodoroGui) {
        ; Register theme change callback for pomodoro GUI
        this.themeManager.RegisterThemeChangeCallback(ObjBindMethod(this, "OnPomodoroThemeChange"))
    }
}

; Handle theme changes for Pomodoro GUI
OnPomodoroThemeChange(newTheme) {
    if (this.pomodoroGui && this.pomodoroGui.Visible) {
        this.ApplyThemeToGui(this.pomodoroGui)
    }
}
    
    ; Setup theme manager for this GUI
    SetupThemeManager() {
        ; Create a dummy preferences GUI for the theme manager (required by the interface)
        prefGui := Gui("+ToolWindow", "Preferences")
        prefGui.Hide()
        
        this.themeSwitchManager := ThemeSwitchManager(
            this.themeManager,
            this.guiTheme,
            this.mainGui,
            prefGui
        )
        
        ; Register theme change callback
        this.themeManager.RegisterThemeChangeCallback(ObjBindMethod(this, "OnThemeChange"))
    }
    
    ; Handle theme changes
    OnThemeChange(newTheme) {
        if (this.mainGui && this.mainGui.Visible) {
            this.ApplyThemeToGui(this.mainGui)
        }
        if (this.pomodoroGui && this.pomodoroGui.Visible) {
            this.ApplyThemeToGui(this.pomodoroGui)
        }
    }
    
    ; Handle common timer button clicks
    SetCommonTimer(btn, *) {
        duration := StrReplace(btn.Text, "m", "")
        duration := StrReplace(duration, "h", "")
        if (InStr(btn.Text, "h"))
            duration *= 60
        
        try {
            duration := Integer(duration)
            this.isPomodoroMode := false  ; Disable pomodoro mode
            this.SetupTimer(
                duration,
                this.showHoursCheckbox.Value,
                this.showMinutesCheckbox.Value,
                this.showSecondsCheckbox.Value,
                this.remind5MinCheckbox.Value,
                this.remind2MinCheckbox.Value
            )
            this.mainGui.Hide()
        } catch {
            ; Invalid duration, ignore
        }
    }
    
    SetCustomTimer(*) {
    customDuration := InputBox("Enter duration in minutes:", "Custom Timer")
    if !customDuration.Result {
        return  ; This exits the function if Cancel was clicked
    }
    
    try {
        duration := Integer(customDuration.Value)
        
        if (duration > 0) {
            this.isPomodoroMode := false  ; Disable pomodoro mode
            this.SetupTimer(
                duration,
                this.showHoursCheckbox.Value,
                this.showMinutesCheckbox.Value,
                this.showSecondsCheckbox.Value,
                this.remind5MinCheckbox.Value,
                this.remind2MinCheckbox.Value
            )
            this.mainGui.Hide()
        } else {
            ; Invalid duration, do nothing
        }
    } catch {
        ; Invalid input, do nothing
    }
    }
    
; Setup the timer with specified parameters
SetupTimer(duration, showHours, showMinutes, showSeconds, remind5MinValue, remind2MinValue) {
    ; Stop any existing timer
    SetTimer(ObjBindMethod(this, "UpdateToolTip"), 0)
    
    ; Reset state flags
    this.timerExpired := false
    this.reminder5MinShown := false
    this.reminder2MinShown := false
    
    ; Set timer parameters
    this.endTime := A_TickCount + duration * 60000
    this.remind5Min := remind5MinValue
    this.remind2Min := remind2MinValue
    
    ; Set display format
    this.showFormat := ""
    if (showHours)
        this.showFormat .= "h"
    if (showMinutes)
        this.showFormat .= "m"
    if (showSeconds)
        this.showFormat .= "s"
    if (this.showFormat == "")
        this.showFormat := "hms"
    
    ; Calculate tooltip position ONCE when timer starts
    this.UpdateTooltipPosition()
    SetTimer(ObjBindMethod(this, "UpdateToolTip"), 1000)
}

; Update the tooltip with remaining time
UpdateToolTip() {
    remainingTime := this.endTime - A_TickCount
    
    if (remainingTime <= 0) {
        if (!this.timerExpired) {
            this.timerExpired := true
            SetTimer(ObjBindMethod(this, "ShowTimeUpMessage"), -10)
        }
        return
    }

    ; Calculate remaining time
    hours := Floor(remainingTime / 3600000)
    minutes := Floor((remainingTime - hours * 3600000) / 60000)
    seconds := Floor((remainingTime - hours * 3600000 - minutes * 60000) / 1000)
    
    ; Prepare the tooltip text
    displayText := this.FormatTimeDisplay(hours, minutes, seconds)
    
    ; Use the already calculated position - DON'T recalculate
    ToolTip(displayText, this.tooltipX, this.tooltipY)

    ; Handle reminders - pass the actual minutes and seconds
    this.CheckReminders(minutes, seconds)
}
    
    ; Update tooltip position based on screen and taskbar
; Update tooltip position based on primary monitor only
; Update tooltip position to always use primary monitor (0,0)
UpdateTooltipPosition() {
    ; Get the primary monitor (the one that contains 0,0)
    ; This will always be monitor 1 in most setups
    MonitorGet(1, &monLeft, &monTop, &monRight, &monBottom)
    
    ; Force it to use coordinates relative to 0,0 (primary monitor)
    ; If your primary monitor doesn't start at 0,0, we'll adjust
    if (monLeft != 0 || monTop != 0) {
        ; Find the monitor that actually contains 0,0
        Loop MonitorGetCount() {
            MonitorGet(A_Index, &left, &top, &right, &bottom)
            if (left <= 0 && top <= 0 && right > 0 && bottom > 0) {
                monLeft := left
                monTop := top
                monRight := right
                monBottom := bottom
                break
            }
        }
    }
    
    ; Calculate taskbar height on primary monitor
    taskbarHeight := this.GetTaskbarHeight()
    
    ; Position tooltip in bottom-right of PRIMARY monitor
    this.tooltipX := monRight - 250
    this.tooltipY := monBottom - taskbarHeight - 50
    
    ; Ensure it's not off-screen (fallback)
    if (this.tooltipX < monLeft) {
        this.tooltipX := monLeft + 10
    }
    if (this.tooltipY < monTop) {
        this.tooltipY := monTop + 10
    }
}
    
    ; Get the height of the taskbar
    GetTaskbarHeight() {
        taskbar := WinExist("ahk_class Shell_TrayWnd")
        if (taskbar) {
            WinGetPos(&x, &y, &w, &h, "ahk_id " taskbar)
            return h
        }
        return 30  ; Default height if taskbar is not found
    }
    
    
    ; Format the time display based on user preferences
    FormatTimeDisplay(hours, minutes, seconds) {
        displayText := ""
        
        if (InStr(this.showFormat, "h") && hours > 0)
            displayText .= hours . "h "
        if (InStr(this.showFormat, "m"))
            displayText .= minutes . "m "
        if (InStr(this.showFormat, "s"))
            displayText .= seconds . "s"
            
        return displayText
    }
    
    ; Check and show reminders if needed
    CheckReminders(minutes, seconds) {
        ; Calculate total remaining minutes for accurate reminder triggering
        totalMinutes := Floor((this.endTime - A_TickCount) / 60000)
        
        if (this.remind5Min && totalMinutes == 5 && seconds == 0 && !this.reminder5MinShown) {
            this.reminder5MinShown := true
            SetTimer(ObjBindMethod(this, "ShowReminderMessage", "5 minutes remaining!"), -10)
        }
        if (this.remind2Min && totalMinutes == 2 && seconds == 0 && !this.reminder2MinShown) {
            this.reminder2MinShown := true
            SetTimer(ObjBindMethod(this, "ShowReminderMessage", "2 minutes remaining!"), -10)
        }
    }
    
    ; Show reminder message with themed dialog
    ShowReminderMessage(message) {     
SetTimer(() => MsgBox(message, "Timer Reminder", "0x40000 64"), -1)
    }
    
    ; Show time up message and clear tooltip
ShowTimeUpMessage() {
    ToolTip()
    SetTimer(ObjBindMethod(this, "UpdateToolTip"), 0)
    
    if (this.isPomodoroMode) {
        if (!this.isBreakTime) {
            ; Work session completed
            result := MsgBox("Round " . this.currentRound . " of " . this.pomodoroRounds . " completed.`n`nContinue with " . this.breakDuration . " minute break?", "Pomodoro", "0x40000 1")
            if (result = "OK") {
                this.StartPomodoroBreak()
                return
            } else {
                ; User cancelled, exit
                this.isPomodoroMode := false
                ExitApp()
            }
        } else {
            ; Break completed
            if (this.currentRound < this.pomodoroRounds) {
                ; More rounds to go
                this.currentRound++
                result := MsgBox("Break finished. Continue with round " . this.currentRound . "/" . this.pomodoroRounds . "?", "Pomodoro", "0x40000 1")
                if (result = "OK") {
                    this.StartPomodoroWork()
                    return
                } else {
                    ; User cancelled, exit
                    this.isPomodoroMode := false
                    ExitApp()
                }
            } else {
                ; All rounds completed
                MsgBox("All " . this.pomodoroRounds . " rounds completed! Great work!", "Pomodoro Complete", "0x40000 64")
                this.isPomodoroMode := false
                ExitApp()
            }
        }
    } else {
        ; Regular timer
        MsgBox("Time's up!", "Timer Finished", "0x40000 64")
        ExitApp()
    }
}
    
    ; Handle GUI close event
    OnGuiClose() {
        this.mainGui.Hide()
        this.mainGui := false
    }
    
    ; Handle Pomodoro GUI close event
    OnPomodoroGuiClose() {
        this.pomodoroGui.Hide()
    }
    ; Cleanup method
    Destroy() {
        ; Stop any active timers
        SetTimer(ObjBindMethod(this, "UpdateToolTip"), 0)
        
        ; Clear tooltip
        ToolTip()
        
        ; Destroy GUIs
        if (this.mainGui) {
            this.mainGui.Destroy()
            this.mainGui := ""
        }
        
        if (this.pomodoroGui) {
            this.pomodoroGui.Destroy()
            this.pomodoroGui := ""
        }
        
        ; Clean up theme manager references
        if (this.themeManager) {
            this.themeManager := ""
        }
        
        if (this.guiTheme) {
            this.guiTheme := ""
        }
        
        if (this.themeSwitchManager) {
            this.themeSwitchManager := ""
        }
    }
}
