class GUITheme { ; try 1
static DARK_MODE := {
    Background: 0x252526,
    Control: 0x252526,
    Text: 0xF0F0F0,
    ListViewText: 0xF0F0F0,
    ListViewBG: 0x252526,
    ListViewTextBG: 0x252526,
    TextBackgroundBrush: 0xF0F0F0,
    ListViewHeaderBG: 0x252526,
    ListViewHeaderText: 0xF0F0F0
}
    static LIGHT_MODE := {
        Background: "",
        Control: "",
        Text: "",
        ListViewText: "",
        ListViewBG: "",
        ListViewTextBG: "",
        TextBackgroundBrush: ""
    }
    
    subclassedControls := Map()
    
    ApplyTheme(guiObj, themeName) {
        theme := themeName = "Dark" ? GUITheme.DARK_MODE : GUITheme.LIGHT_MODE
        if guiObj.Hwnd {
            if themeName = "Dark" {
                DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", guiObj.Hwnd, "UInt", 20, "Int*", 1, "UInt", 4)
                DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", guiObj.Hwnd, "UInt", 35, "Int*", 0x252526, "UInt", 4)
                
                ; ADDED: Subclass the main GUI window to handle drawing for child controls (Text, GroupBox, StatusBar)
                if !this.subclassedControls.Has(guiObj.Hwnd) {
                    guiSubclassCallback := CallbackCreate(this._GuiSubclassProc.Bind(this), "F", 4)
                    DllCall("Comctl32.dll\SetWindowSubclass", "Ptr", guiObj.Hwnd, "Ptr", guiSubclassCallback, "Ptr", guiObj.Hwnd, "Ptr", 0)
                    this.subclassedControls[guiObj.Hwnd] := {callback: guiSubclassCallback, oldProc: 0} ; Store for removal
                }

            } else {
                DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", guiObj.Hwnd, "UInt", 20, "Int*", 0, "UInt", 4)
                
                ; ADDED: Remove the subclass when switching to light mode
                if this.subclassedControls.Has(guiObj.Hwnd) {
                    info := this.subclassedControls[guiObj.Hwnd]
                    DllCall("Comctl32.dll\RemoveWindowSubclass", "Ptr", guiObj.Hwnd, "Ptr", info.callback, "Ptr", guiObj.Hwnd)
                    CallbackFree(info.callback)
                    this.subclassedControls.Delete(guiObj.Hwnd)
                }
            }
            DllCall("RedrawWindow", "Ptr", guiObj.Hwnd, "Ptr", 0, "Ptr", 0, "UInt", 0x1 | 0x4)
        }
        try {
            guiObj.BackColor := theme.Background
            for ctrl in guiObj {
                this.ApplyControlTheme(ctrl, theme, guiObj, themeName)
            }
        } catch as e {
            ; Log error but continue
        }
    }

    ; ADDED: This new method handles WM_CTLCOLORSTATIC to theme Text, GroupBox, and StatusBar controls.
    _GuiSubclassProc(hWnd, uMsg, wParam, lParam) {
        static WM_CTLCOLORSTATIC := 0x0138
        static hBrush := 0
        if (uMsg == WM_CTLCOLORSTATIC) {
            hDC := wParam
            DllCall("gdi32\SetTextColor", "Ptr", hDC, "UInt", GUITheme.DARK_MODE.Text)
            DllCall("gdi32\SetBkColor", "Ptr", hDC, "UInt", GUITheme.DARK_MODE.Background)
            if !hBrush
                hBrush := DllCall("gdi32\CreateSolidBrush", "UInt", GUITheme.DARK_MODE.Background, "Ptr")
            return hBrush
        }
        return DllCall("Comctl32.dll\DefSubclassProc", "Ptr", hWnd, "UInt", uMsg, "Ptr", wParam, "Ptr", lParam)
    }

    ApplyControlTheme(ctrl, theme, guiObj, themeName) {
        try {
            ctrlType := ctrl.Type
            ; MODIFIED: Removed "Text" as it's now handled by _GuiSubclassProc
            validTypes := ["Edit", "Button", "DropDownList", "ComboBox"] 
            isValidType := false
            for type in validTypes {
                if (ctrlType = type) {
                    isValidType := true
                    break
                }
            }
            
            if (isValidType) {
                if (theme.HasProp("Control") && theme.Control) {
                    ctrl.Opt("+Background" . Format("{:06X}", theme.Control))
                }
                if (theme.HasProp("Text") && theme.Text) {
                    ctrl.Opt("+c" . Format("{:06X}", theme.Text))
                }
            }
            
            if (ctrlType = "ListView") {
                this.ApplyListViewTheme(ctrl, theme)
            }
            
            if (ctrlType = "TreeView") {
                this.ApplyTreeViewTheme(ctrl, theme)
            }
            
            if (ctrlType = "Edit" && themeName = "Dark") {
                this.ApplyCustomEditTheme(ctrl, guiObj, theme)
            }
            
            if (ctrlType = "CheckBox" && themeName = "Dark") {
                DllCall("uxtheme\SetWindowTheme", "Ptr", ctrl.Hwnd, "Str", "", "Ptr", 0)
                this.ApplyCustomCheckBoxTheme(ctrl, guiObj, theme)
            }

            if (ctrlType = "ComboBox" || "DropDownList" )  {
                if (themeName = "Dark") {
                    if (!this.subclassedControls.Has(ctrl.Hwnd)) {
                        DllCall("uxtheme\SetWindowTheme", "Ptr", ctrl.Hwnd, "Str", "DarkMode_CFD", "Ptr", 0)
                        OldWndProc := DllCall("GetWindowLongPtr", "Ptr", ctrl.Hwnd, "Int", -4, "Ptr")
                        NewWndProc := CallbackCreate(ObjBindMethod(this, "ComboWindowProc", ctrl, theme, OldWndProc), , 4)
                        DllCall("SetWindowLongPtr", "Ptr", ctrl.Hwnd, "Int", -4, "Ptr", NewWndProc)
                        this.subclassedControls[ctrl.Hwnd] := {callback: NewWndProc, oldProc: OldWndProc}
                    }
                } else {
                    if (this.subclassedControls.Has(ctrl.Hwnd)) {
                        info := this.subclassedControls[ctrl.Hwnd]
                        DllCall("SetWindowLongPtr", "Ptr", ctrl.Hwnd, "Int", -4, "Ptr", info.oldProc)
                        CallbackFree(info.callback)
                        this.subclassedControls.Delete(ctrl.Hwnd)
                    }
                    DllCall("uxtheme\SetWindowTheme", "Ptr", ctrl.Hwnd, "Str", "CFD", "Ptr", 0)
                }
            }

if (ctrlType = "StatusBar") {
    if (themeName = "Dark") {
        ; Apply dark mode theme
        DllCall("uxtheme\SetWindowTheme", "Ptr", ctrl.Hwnd, "Str", "DarkMode_Explorer", "Ptr", 0)
        ; Set -Theme and background color
        ctrl.Opt("-Theme Background" . Format("{:06X}", GUITheme.DARK_MODE.Background))
        ; Explicitly set background color via SB_SETBKCOLOR
        DllCall("SendMessage", "Ptr", ctrl.Hwnd, "UInt", 0x413, "Ptr", 0, "Ptr", GUITheme.DARK_MODE.Background)
        ; Optional: Windows 11 corner preference
        if (VerCompare(A_OSVersion, "10.0.22000") > 0) {
            DllCall("Dwmapi\DwmSetWindowAttribute", "Ptr", ctrl.Hwnd, "UInt", 33, "Ptr*", 3, "UInt", 4)
        }
    } else {
        ; Reset to light mode
        DllCall("uxtheme\SetWindowTheme", "Ptr", ctrl.Hwnd, "Str", "", "Ptr", 0)
        ; Reset background to default
        ctrl.Opt("+Theme BackgroundDefault")
        DllCall("SendMessage", "Ptr", ctrl.Hwnd, "UInt", 0x413, "Ptr", 0, "Ptr", -1) ; CLR_DEFAULT
    }
    ; Force redraw
    DllCall("InvalidateRect", "Ptr", ctrl.Hwnd, "Ptr", 0, "Int", 1)
    DllCall("UpdateWindow", "Ptr", ctrl.Hwnd)
}         
            if (ctrlType = "Edit" || ctrlType = "ListView" || ctrlType = "ListBox" || ctrlType = "TreeView" || ctrlType = "Tab" || ctrlType = "RichEdit") {
                if (themeName = "Dark") {
                    DllCall("uxtheme\SetWindowTheme", "Ptr", ctrl.Hwnd, "Str", "DarkMode_Explorer", "Ptr", 0)
                    DllCall("uxtheme\SetWindowTheme", "Ptr", guiObj.Hwnd, "Str", "DarkMode_Explorer", "Ptr", 0)
                } else {
                    DllCall("uxtheme\SetWindowTheme", "Ptr", ctrl.Hwnd, "Str", "", "Ptr", 0)
                    DllCall("uxtheme\SetWindowTheme", "Ptr", guiObj.Hwnd, "Str", "", "Ptr", 0)
                }
            }
            
            if (ctrlType = "Button") {
                if (themeName = "Dark") {
                    DllCall("uxtheme\SetWindowTheme", "Ptr", ctrl.Hwnd, "Str", "DarkMode_Explorer", "Ptr", 0)
                } else {
                    DllCall("uxtheme\SetWindowTheme", "Ptr", ctrl.Hwnd, "Str", "", "Ptr", 0)
                }
            }
        } catch Error as e {
            ; Continue with next control
        }
    }

    ComboWindowProc(comboCtrl, theme, OldWndProc, hWnd, uMsg, wParam, lParam) {
        static WM_CTLCOLORLISTBOX := 0x0134
        static WM_CTLCOLOREDIT := 0x0133
        static darkBrush := 0
        
        if (uMsg = WM_CTLCOLORLISTBOX || uMsg = WM_CTLCOLOREDIT) {
            hDC := wParam
            DllCall("gdi32\SetTextColor", "Ptr", hDC, "UInt", theme.Text)
            DllCall("gdi32\SetBkColor", "Ptr", hDC, "UInt", theme.Control)
            
            if (!darkBrush) {
                darkBrush := DllCall("gdi32\CreateSolidBrush", "UInt", theme.Control, "Ptr")
            }
            return darkBrush
        }
        return DllCall("CallWindowProc", "Ptr", OldWndProc, "Ptr", hWnd, "UInt", uMsg, "Ptr", wParam, "Ptr", lParam)
    }
    
    CleanupSubclassedControls() {
        for key, info in this.subclassedControls {
            try {
                if (InStr(key, "_header")) {
                    lvHwnd := StrReplace(key, "_header", "")
                    DllCall("Comctl32.dll\RemoveWindowSubclass", "Ptr", Integer(lvHwnd), "Ptr", info.callback, "Ptr", Integer(lvHwnd))
                } else if info.oldProc != 0 { ; It's a regular control subclass
                    DllCall("SetWindowLongPtr", "Ptr", Integer(key), "Int", -4, "Ptr", info.oldProc)
                } else { ; It's a GUI subclass
                    DllCall("Comctl32.dll\RemoveWindowSubclass", "Ptr", Integer(key), "Ptr", info.callback, "Ptr", Integer(key))
                }
                CallbackFree(info.callback)
            }
        }
        this.subclassedControls.Clear()
        if (this.HasProp("HeaderColors")) {
            this.HeaderColors.Clear()
        }
    }

    ApplyListViewTheme(lv, theme) {
        lv.Opt("+Background" . (theme.ListViewBG ? Format("{:06X}", theme.ListViewBG) : ""))
        DllCall("SendMessage", "Ptr", lv.Hwnd, "UInt", 0x1024, "Ptr", 0, "Ptr", theme.ListViewText ? theme.ListViewText : -1) 
        DllCall("SendMessage", "Ptr", lv.Hwnd, "UInt", 0x1026, "Ptr", 0, "Ptr", theme.ListViewTextBG ? theme.ListViewTextBG : -1)
        
        if (theme.HasProp("ListViewHeaderBG") && theme.ListViewHeaderBG) {
            this.ApplyListViewHeaderTheme(lv, theme)
        }
        
        lv.Redraw()
    }

    ApplyTreeViewTheme(tv, theme) {
        if (theme.ListViewBG) {
            DllCall("SendMessage", "Ptr", tv.Hwnd, "UInt", 0x111D, "Ptr", 0, "Ptr", theme.ListViewBG) ; TVM_SETBKCOLOR
            DllCall("SendMessage", "Ptr", tv.Hwnd, "UInt", 0x111E, "Ptr", 0, "Ptr", theme.ListViewText) ; TVM_SETTEXTCOLOR
        }
    }

    ApplyListViewHeaderTheme(lv, theme) {
        hHeader := DllCall("SendMessage", "Ptr", lv.Hwnd, "UInt", 0x101F, "Ptr", 0, "Ptr", 0, "UPtr")
        if (!hHeader) {
            return
        }
        
        if (!this.HasProp("HeaderColors")) {
            this.HeaderColors := Map()
        }
        
        this.HeaderColors[hHeader] := { Txt: theme.ListViewHeaderText, Bkg: theme.ListViewHeaderBG, TextBrush: theme.ListViewHeaderBG }
        
        headerKey := lv.Hwnd . "_header"
        if (!this.subclassedControls.Has(headerKey)) {
            headerCallback := CallbackCreate(ObjBindMethod(this, "HeaderCustomDraw"), , 6)
            if (DllCall("Comctl32.dll\SetWindowSubclass", "Ptr", lv.Hwnd, "Ptr", headerCallback, "Ptr", lv.Hwnd, "Ptr", 0)) {
                this.subclassedControls[headerKey] := {callback: headerCallback, oldProc: 0}
            }
        }
        
        DllCall("InvalidateRect", "Ptr", hHeader, "Ptr", 0, "Int", 1)
        DllCall("UpdateWindow", "Ptr", hHeader)
    }

    HeaderCustomDraw(H, M, W, L, IdSubclass, RefData) {
        static HDM_GETITEM := 0x120B, NM_CUSTOMDRAW := -12, CDRF_DODEFAULT := 0x00000000, CDRF_SKIPDEFAULT := 0x00000004
        static CDRF_NOTIFYITEMDRAW := 0x00000020, CDDS_PREPAINT := 0x00000001, CDDS_ITEMPREPAINT := 0x00010001, DC_Brush := DllCall("GetStockObject", "UInt", 18, "UPtr")
        static OHWND := 0, OMsg := 2 * A_PtrSize, ODrawStage := OMsg + A_PtrSize, OHDC := ODrawStage + A_PtrSize
        static ORect := OHDC + A_PtrSize, OItemSpec := OHDC + 16 + A_PtrSize, TM := 6
        
        if (M = 0x4E) {
            hWnd := NumGet(L, OHWND, "UPtr")
            if (this.HasProp("HeaderColors") && this.HeaderColors.Has(hWnd)) {
                HC := this.HeaderColors[hWnd], Code := NumGet(L, OMsg, "Int")
                if (Code = NM_CUSTOMDRAW) {
                    DrawStage := NumGet(L, ODrawStage, "UInt")
                    if (DrawStage = CDDS_PREPAINT) {
                        hdc := NumGet(L, OHDC, "Ptr"), headerRect := Buffer(16, 0)
                        DllCall("GetClientRect", "Ptr", hWnd, "Ptr", headerRect)
                        DllCall("SetDCBrushColor", "Ptr", hdc, "UInt", HC.Bkg)
                        DllCall("FillRect", "Ptr", hdc, "Ptr", headerRect, "Ptr", DC_Brush)
                        return CDRF_NOTIFYITEMDRAW
                    }
                    if (DrawStage = CDDS_ITEMPREPAINT) {
                        Item := NumGet(L, OItemSpec, "Ptr"), hdi := Buffer(48, 0), textBuf := Buffer(520, 0)
                        NumPut("UInt", 0x86, hdi, 0), NumPut("Ptr", textBuf.Ptr, hdi, 8), NumPut("Int", 260, hdi, 8 + 2 * A_PtrSize)
                        DllCall("SendMessage", "Ptr", hWnd, "UInt", HDM_GETITEM, "Ptr", Item, "Ptr", hdi)
                        Fmt := NumGet(hdi, 12 + 2 * A_PtrSize, "UInt") & 3, hdc := NumGet(L, OHDC, "Ptr")
                        rectPtr := L + ORect, right := NumGet(rectPtr + 8, "Int"), top := NumGet(rectPtr + 4, "Int"), bottom := NumGet(rectPtr + 12, "Int")
                        gridColor := 0x808080, hPen := DllCall("gdi32\CreatePen", "Int", 0, "Int", 1, "UInt", gridColor, "Ptr"), hOldPen := DllCall("gdi32\SelectObject", "Ptr", hdc, "Ptr", hPen, "Ptr")
                        DllCall("gdi32\MoveToEx", "Ptr", hdc, "Int", right-1, "Int", top, "Ptr", 0)
                        DllCall("gdi32\LineTo", "Ptr", hdc, "Int", right-1, "Int", bottom)
                        left := NumGet(rectPtr, "Int")
                        if (left = 0) {
                            DllCall("gdi32\MoveToEx", "Ptr", hdc, "Int", left, "Int", top, "Ptr", 0)
                            DllCall("gdi32\LineTo", "Ptr", hdc, "Int", left, "Int", bottom)
                        }
                        DllCall("gdi32\SelectObject", "Ptr", hdc, "Ptr", hOldPen, "Ptr"), DllCall("gdi32\DeleteObject", "Ptr", hPen)
                        DllCall("SetBkMode", "Ptr", hdc, "UInt", 1), DllCall("SetTextColor", "Ptr", hdc, "UInt", HC.Txt)
                        DllCall("InflateRect", "Ptr", L + ORect, "Int", -TM, "Int", 0)
                        DT_ALIGN := 0x0224 + ((Fmt & 1) ? 2 : (Fmt & 2) ? 1 : 0)
                        headerText := StrGet(textBuf)
                        DllCall("DrawTextW", "Ptr", hdc, "Str", headerText, "Int", -1, "Ptr", L + ORect, "UInt", DT_ALIGN)
                        return CDRF_SKIPDEFAULT
                    }
                    return CDRF_DODEFAULT
                }
            }
        }
        return DllCall("Comctl32.dll\DefSubclassProc", "Ptr", H, "UInt", M, "Ptr", W, "Ptr", L, "Ptr")
    }

    ApplyCustomEditTheme(editCtrl, guiObj, theme) {
        OldWndProc := DllCall("GetWindowLongPtr", "Ptr", editCtrl.Hwnd, "Int", -4, "Ptr")
        NewWndProc := CallbackCreate(ObjBindMethod(this, "EditWindowProc", editCtrl, theme, OldWndProc), , 4)
        DllCall("SetWindowLongPtr", "Ptr", editCtrl.Hwnd, "Int", -4, "Ptr", NewWndProc)
    }
    
    ApplyCustomCheckBoxTheme(checkBoxCtrl, guiObj, theme) {
        OldWndProc := DllCall("GetWindowLongPtr", "Ptr", checkBoxCtrl.Hwnd, "Int", -4, "Ptr")
        NewWndProc := CallbackCreate(ObjBindMethod(this, "CheckBoxWindowProc", checkBoxCtrl, theme, OldWndProc), , 4)
        DllCall("SetWindowLongPtr", "Ptr", checkBoxCtrl.Hwnd, "Int", -4, "Ptr", NewWndProc)
    }
    
    EditWindowProc(editCtrl, theme, OldWndProc, hWnd, uMsg, wParam, lParam) {
        static WM_CTLCOLOREDIT := 0x0133
        if (uMsg = WM_CTLCOLOREDIT) {
            hDC := wParam
            DllCall("SetTextColor", "Ptr", hDC, "UInt", theme.Text)
            DllCall("SetBkColor", "Ptr", hDC, "UInt", theme.TextBackgroundBrush)
            return DllCall("CreateSolidBrush", "UInt", theme.TextBackgroundBrush)
        }
        return DllCall("CallWindowProc", "Ptr", OldWndProc, "Ptr", hWnd, "UInt", uMsg, "Ptr", wParam, "Ptr", lParam)
    }
    
    CheckBoxWindowProc(checkBoxCtrl, theme, OldWndProc, hWnd, uMsg, wParam, lParam) {
        static WM_CTLCOLORSTATIC := 0x0138
        if (uMsg = WM_CTLCOLORSTATIC) {
            hDC := wParam
            DllCall("gdi32\SetTextColor", "Ptr", hDC, "UInt", 0xF0F0F0)
            DllCall("gdi32\SetBkMode", "Ptr", hDC, "Int", 1) ; TRANSPARENT
            DllCall("gdi32\SetBkColor", "Ptr", hDC, "UInt", theme.TextBackgroundBrush)
            return DllCall("gdi32\CreateSolidBrush", "UInt", theme.TextBackgroundBrush)
        }
        return DllCall("CallWindowProc", "Ptr", OldWndProc, "Ptr", hWnd, "UInt", uMsg, "Ptr", wParam, "Ptr", lParam)
    }
}
; =============================================================================
; THEME MANAGER CLASS (MODIFIED) to support globaldarkmodeoverride
; =============================================================================
class ThemeManager {
    ; Constants for theme management
    static REG_KEY := "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    static REG_VALUE := "AppsUseLightTheme"
    static WM_SETTINGCHANGE := 0x001A
    static DEFAULT_THEME := "Light"
    
    ; Instance properties
    currentTheme := ""
    themeChangeCallbacks := []
    hRegNotify := 0
    
    __New() {
        this.currentTheme := this.ReadThemeFromRegistry()
        this.RegisterMessageHandler()
        this.StartRegistryMonitoring()
    }
    
    ; Reads the current theme from the Windows registry
    ; MODIFIED to respect globaldarkmodeoverride
    ReadThemeFromRegistry() {
        global globaldarkmodeoverride ; Declare access to the global variable

        ; First, check for the global override from ContextColor.ahk
        if IsSet(globaldarkmodeoverride)
        {
            if (globaldarkmodeoverride = 1) ; 1 = Force Dark
                return "Dark"
            if (globaldarkmodeoverride = 2) ; 2 = Force Light
                return "Light"
            ; If the override is 0, we fall through to the default system-aware behavior.
        }

        ; Original logic for system-aware (context-aware) theme detection
        try {
            value := RegRead(ThemeManager.REG_KEY, ThemeManager.REG_VALUE)
            return value == 0 ? "Dark" : "Light"
        } catch {
            return ThemeManager.DEFAULT_THEME ; Fallback to Light if registry read fails
        }
    }
    
    ; Registers WM_SETTINGCHANGE message handler
    RegisterMessageHandler() {
        OnMessage(ThemeManager.WM_SETTINGCHANGE, ObjBindMethod(this, "OnThemeChangeListener"))
    }
    
    ; Handles theme change notifications via WM_SETTINGCHANGE
    OnThemeChangeListener(wParam, lParam, msg, hwnd) {
        ; Check if lParam is valid before calling StrGet
        if (lParam != 0 && StrGet(lParam) = "ImmersiveColorSet") {
            newTheme := this.ReadThemeFromRegistry()
            if newTheme != this.currentTheme {
                this.currentTheme := newTheme
                this.NotifyThemeChange()
            }
        }
        return 0
    }
    
    ; Starts monitoring registry for theme changes
    StartRegistryMonitoring() {
        try {
            hKey := DllCall("advapi32\RegOpenKeyExW", "Ptr", 0x80000001, "Str", ThemeManager.REG_KEY, "UInt", 0, "UInt", 0x20019 | 0x0010, "Ptr*", 0)
            if hKey {
                hEvent := DllCall("CreateEvent", "Ptr", 0, "Int", 1, "Int", 0, "Ptr", 0)
                if hEvent {
                    DllCall("advapi32\RegNotifyChangeKeyValue", "Ptr", hKey, "Int", 1, "UInt", 0x1 | 0x4, "Ptr", hEvent, "Int", 1)
                    this.hRegNotify := hEvent
                    SetTimer(ObjBindMethod(this, "CheckRegistryChange"), 1000)
                }
                DllCall("advapi32\RegCloseKey", "Ptr", hKey)
            }
        } catch {
            this.hRegNotify := 0
        }
    }
    
    ; Checks for registry changes
    CheckRegistryChange() {
        if this.hRegNotify {
            result := DllCall("WaitForSingleObject", "Ptr", this.hRegNotify, "UInt", 0)
            if result = 0 {
                newTheme := this.ReadThemeFromRegistry()
                if newTheme != this.currentTheme {
                    this.currentTheme := newTheme
                    this.NotifyThemeChange()
                }
                DllCall("ResetEvent", "Ptr", this.hRegNotify)
                try {
                    hKey := DllCall("advapi32\RegOpenKeyExW", "Ptr", 0x80000001, "Str", ThemeManager.REG_KEY, "UInt", 0, "UInt", 0x20019 | 0x0010, "Ptr*", 0)
                    if hKey {
                        DllCall("advapi32\RegNotifyChangeKeyValue", "Ptr", hKey, "Int", 1, "UInt", 0x1 | 0x4, "Ptr", this.hRegNotify, "Int", 1)
                        DllCall("advapi32\RegCloseKey", "Ptr", hKey)
                    }
                }
            }
        }
    }
    
    ; Registers a callback for theme changes
    RegisterThemeChangeCallback(callback) {
        this.themeChangeCallbacks.Push(callback)
    }
    
    ; Notifies registered callbacks
    NotifyThemeChange() {
        for callback in this.themeChangeCallbacks {
            try callback.Call(this.currentTheme)
        }
    }
    
    ; Gets the current theme
    GetCurrentTheme() {
        return this.currentTheme
    }
    
    ; Cleanup
    __Delete() {
        if this.hRegNotify {
            DllCall("CloseHandle", "Ptr", this.hRegNotify)
            this.hRegNotify := 0
        }
        try SetTimer(ObjBindMethod(this, "CheckRegistryChange"), 0)
    }
}

; =============================================================================
; THEME SWITCH MANAGER CLASS
; =============================================================================
class ThemeSwitchManager {
    ; Instance properties
    themeManager := ""
    guiTheme := ""
    mainGui := ""
    prefGui := ""
    
    __New(themeManager, guiTheme, mainGui, prefGui) {
        this.themeManager := themeManager
        this.guiTheme := guiTheme
        this.mainGui := mainGui
        this.prefGui := prefGui
        this.InitializeTheme()
        this.RegisterThemeCallback()
    }
    
    ; Initializes the theme based on system settings
    InitializeTheme() {
        currentTheme := this.themeManager.GetCurrentTheme()
        this.ApplyThemeToVisibleGui(currentTheme)
    }
    
    ; Registers for theme change notifications
    RegisterThemeCallback() {
        this.themeManager.RegisterThemeChangeCallback(ObjBindMethod(this, "OnThemeChange"))
    }
    
    ; Handles theme change events
    OnThemeChange(newTheme) {
        this.ApplyThemeToVisibleGui(newTheme)
    }
    
    ; Applies theme to the currently visible GUI
    ApplyThemeToVisibleGui(themeName) {
        try {
            if this.mainGui.Visible {
                this.guiTheme.ApplyTheme(this.mainGui, themeName)
            } else if this.prefGui.Visible {
                this.guiTheme.ApplyTheme(this.prefGui, themeName)
            }
        } catch {
            ; Log error but continue
        }
    }
}


