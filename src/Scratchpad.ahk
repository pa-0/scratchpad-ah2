#Requires AutoHotkey v2.0
#SingleInstance Force

; Note dependency on dq.ahk lib: https://github.com/DesiQuintans/dq.ahk
#Include "C:/Dropbox/Projects/Autohotkey 2 - dq.ahk/dq.ahk"

DetectHiddenWindows True



; ---- Create/restore program settings -------------------------------------------------------------


; ---- Define default settings ----

VisibilityHotkey   := "#s"  ; Windows + S is the default show/hide hotkey

SaveOnHide         := 1
SaveOnFocusLoss    := 1
StartMinimised     := 0
LastActiveFile     := ""

TabSpaces          := 4
FontName           := "Consolas"
FontSizePt         := 10
ListItem           := "- "
ToDoItem           := "- [ ] "
DoneItem           := "- [x] "

EditorCols         := 90
EditorRows         := 45



; ---- Load user settings from .ini file -----------------------------------------------------------

; If a .ini doesn't exist, this function call will lead to one being created.
sp_LoadSettings()



; ---- Hard-coded settings -------------------------------------------------------------------------

DefaultWindowTitle := " - Scratchpad (Ctrl+H for Help)"
LastModifiedAt     := ""

GuiMargin          := 5



; ---- Create GUI ----------------------------------------------------------------------------------

; Find how wide my Edit should be in order to fit desired number of chars in a line.
WidthFromCols := dq_EditWidthFromCols(EditorCols, FontName, FontSizePt)

SPGui := Gui("+AlwaysOnTop +Resize -MaximizeBox", DefaultWindowTitle)
this_hwnd := "ahk_id " . SPGui.Hwnd
SPGui.Opt("+OwnDialogs")  ; Has to be set in all new threads too.

SPGui.MarginX := GuiMargin
SPGui.MarginY := GuiMargin
SPGui.SetFont("s" . FontSizePt, FontName)

SPGui.BackColor := "fcffa4"

SPEditor := SPGui.Add("Edit",
                    Format("section Multi +WantTab +Wrap Backgroundfffff4 w{1} R{2}", 
                           WidthFromCols,
                           EditorRows),
                    "Placeholder text")




; ---- Set and show the GUI's elements -------------------------------------------------------------


if LastActiveFile == "" {
    sp_NewFromTemplate(0)  ; Suppresses the confirmation dialog
} else {
    LoadResult := sp_OpenFile(LastActiveFile)

    if LoadResult.err == 1 {
        sp_NewFromTemplate(0)
    }
}

if (StartMinimised == 1) {
    SPGui.Show("Hide")
} else {
    SPGui.Show()
    SendInput("^{Home}")  ; The editor starts with everything selected, for some reason.
}



; ---- Define GUI events ---------------------------------------------------------------------------

SPGui.OnEvent("Size", ev_Size)
SPGui.OnEvent("Close", ev_Close)
SPGui.OnEvent("Escape", ev_Escape)

SPEditor.OnEvent("Change", ev_Change)
SPEditor.OnEvent("LoseFocus", ev_LoseFocus)
SPEditor.OnEvent("Focus", ev_Focus)


ev_Size(SPGui, MinMax, Width, Height) {
    ; GUI was resized/minimised/restored
    SPGui.Opt("+OwnDialogs")

    if MinMax == -1 {
        ; It was minimised
        hk_vis_hide()
    }

    sp_ResizeEditor()
}

ev_Close(*) {
    ; GUI was closed
    SPGui.Opt("+OwnDialogs")

    hk_vis_hide()
}

ev_Escape(*) {
    ; User pressed ESC while GUI has focus
    SPGui.Opt("+OwnDialogs")
    
    hk_vis_hide()
}

ev_Change(*) {
    ; Editor contents were changed
    SPGui.Opt("+OwnDialogs")
    
    dq_FlagTitle(SPGui)
    global LastModifiedAt := A_Now
}

ev_LoseFocus(*) {
    ; Editor lost keyboard focus
    SPGui.Opt("+OwnDialogs")
    
    if SaveOnFocusLoss == 1 {
        if sp_SafeToAutoSave() == 1 {
            sp_SaveFile(LastActiveFile)
            dq_UnflagTitle(SPGui)
        }
    }
}

ev_Focus(*) {
    ; Editor regained focus
    SPGui.Opt("+OwnDialogs")
    
    sp_RefreshFile()
}

OnExit(sp_Exit)


; ---- Define hotkeys ------------------------------------------------------------------------------

#HotIf WinActive(this_hwnd)
    Hotkey("#s", hk_vis_toggle)

    ^n::hk_new()
    ^+n::hk_rollover()
    ^s::hk_save()
    ^+s::hk_saveas()
    ^o::hk_open()
    ^h::hk_help()

    Escape::hk_vis_hide()
    
    ; Standard editor functionality

    ^Del::SendInput("^+{Right}{Delete}")         ; Forward-delete
    ^BackSpace::SendInput("^+{Left}{Delete}")    ; Back-delete
    Tab::SendInput("{Space " . TabSpaces . "}")  ; Insert spaces instead of a tab

    ; Custom editor functionality

    !Enter::SendInput("{End}{Enter}{Raw}" . ListItem)       ; Insert list item 
    !+Enter::SendInput("{End}{Enter}{Raw}" . ToDoItem)      ; Insert todo list item 
    ^Enter::hk_cycle_todo()                                 ; Cycle between done and todo
    
    ; Alt+Arrow line movement
    !Up::hk_line_up()
    !Down::hk_line_down()
    !Left::hk_outdent()
    !Right::hk_indent()

    !F4::ExitApp

#HotIf ; Undoes the context-sensitivity from above.


hk_new(*) {
    SPGui.Opt("+OwnDialogs")
    
    sp_NewFromTemplate()
}

hk_rollover(*) {
    SPGui.Opt("+OwnDialogs")
    
    sp_NewFromRollover()
}

hk_save(*) {
    SPGui.Opt("+OwnDialogs")
    
    sp_SaveFile(LastActiveFile)
}

hk_saveas(*) {
    SPGui.Opt("+OwnDialogs")
    
    sp_SaveFile("")
}

hk_open(*) {
    SPGui.Opt("+OwnDialogs")
    
    sp_OpenFile()
}

hk_help(*) {
    SPGui.Opt("+OwnDialogs")
    
    sp_HelpMsg()
}

hk_vis_toggle(*) {
    SPGui.Opt("+OwnDialogs")
    
    sp_ToggleVisibility()
}

hk_vis_hide(*) {
    SPGui.Opt("+OwnDialogs")
    
    sp_HideScratchpad()
}

hk_cycle_todo(*) {
    SPGui.Opt("+OwnDialogs")
    
    sp_ToggleToDo()
}

hk_line_up(*) {
    SPGui.Opt("+OwnDialogs")

    sp_MoveLine("up")
}

hk_line_down(*) {
    SPGui.Opt("+OwnDialogs")
    
    sp_MoveLine("down")
}

hk_outdent(*) {
    SPGui.Opt("+OwnDialogs")
    
    sp_Dent("out")
}

hk_indent(*) {
    SPGui.Opt("+OwnDialogs")
 
    sp_Dent("in")
}



; ---- Functions -----------------------------------------------------------------------------------


sp_NewFromTemplate(ConfirmDialog := 1) {
    global

    if (ConfirmDialog == 1) {
        ; WinSetAlwaysOnTop(0, this_hwnd)

        confirm := MsgBox("Are you sure you want to create a new file?`nAll unsaved changes will be lost.",
                      "Lose unsaved changes? - Scratchpad", "YesNo Icon!")

        ; WinSetAlwaysOnTop(1, this_hwnd)

        if confirm == "No" {
            return
        }
    }

    if FileExist("template.txt") {
        filecontents := FileRead("template.txt")
    } else {
        filecontents := ""
    }

    SPGui.Title := "Unsaved" . DefaultWindowTitle
    dq_FlagTitle(SPGui)

    LastActiveFile := ""
    LastModifiedAt := A_Now

    SPEditor.Value := filecontents
    SPEditor.Focus()
}


sp_NewFromRollover(ConfirmDialog := 1) {
    global

    if (ConfirmDialog == 1) {
        ; WinSetAlwaysOnTop(0, this_hwnd)

        confirm := MsgBox("Are you sure you want to create a new file?`nAll unsaved changes will be lost.",
                      "Lose unsaved changes? - Scratchpad", "YesNo Icon!")

        ; WinSetAlwaysOnTop(1, this_hwnd)

        if confirm == "No" {
            return
        }
    }

    ; WinSetAlwaysOnTop(0, this_hwnd)
    attempt := dq_LoadFile(, "Load a file - Scratchpad")
    ; WinSetAlwaysOnTop(1, this_hwnd)

    ; HACK This is done in such a weird way because AHK's RegexMatch() is so weird and obtuse. I got
    ; it working for detecting headings, but could not get it working to detect ToDoItems even 
    ; though the regex I was using was perfectly valid, and then I had trouble getting the matched
    ; lines back out of it. Instead, I'm skipping regex altogether and going line-by-line.

    if attempt.err == 0 {
        ; 1. Split the input into lines
        split := StrSplit(attempt.contents, "`n", "`r")  ; Not just "`r`n", which can fail to split

        ; 2. Make a variable that receives my matched lines.
        rollover := ""

        ; 3. Test each line to see if it has my needle. If so, append it to the output.
        For index, value in split {
            if InStr(SubStr(value, 1, 1), "#") != 0 {
                ; Header # found at start of line.
                rollover .= value . "`r`n"
                Continue
            }

            if InStr(value, ToDoItem) != 0 {
                ; ToDoItem found anywhere in the line.
                rollover .= value . "`r`n"
                Continue
            }

            if value = "" {
            	; A blank line
                rollover .= "`r`n"
                Continue
            }
        }

        ; 4. Remove duplicate newlines
        rollover := RegExReplace(rollover, "\R{2,}", "`r`n`r`n")

        ; 5. Put this into the editor
        SPGui.Title := "Unsaved " . DefaultWindowTitle
        dq_FlagTitle(SPGui)

        LastActiveFile := ""
        LastModifiedAt := A_Now

        SPEditor.Value := rollover
    }
}


sp_SaveFile(fname?) {
    global

    attempt := dq_SaveFile(SPEditor.Value, fname, , "Save As - Scratchpad")

    if attempt.err == 0 {
        SPGui.Title := dq_Basename(attempt.path) . DefaultWindowTitle
        dq_UnflagTitle(SPGui)

        LastActiveFile := attempt.path
        LastModifiedAt := A_Now
    }
}


sp_OpenFile(fname := "") {
    global

    ; WinSetAlwaysOnTop(0, this_hwnd)
    attempt := dq_LoadFile(fname, "Load a file - Scratchpad")
    ; WinSetAlwaysOnTop(1, this_hwnd)

    if attempt.err == 0 {
        SPGui.Title    := dq_Basename(attempt.path) . DefaultWindowTitle
        dq_UnflagTitle(SPGui)

        LastActiveFile := attempt.path
        LastModifiedAt := A_Now
        
        SPEditor.Value := attempt.contents

        return({err: 0})
    } else {
        return({err: 1})
    }
}


sp_RefreshFile() {
    global

    if LastActiveFile == "" {
        ; This is a new and unsaved file, so there's nothing to refresh from. 
        return
    }

    myfile := dq_FileNewerThan(LastActiveFile, LastModifiedAt)

    if myfile.newer == 1 {
        sp_OpenFile(LastActiveFile)
        LastModifiedAt := myfile.mtime  ; Manually set this to the file's own time.
    }
}


sp_HelpMsg() {
    global

    ; Displays the Help dialog, which shows keybinds. Important since I removed all buttons and stuff
    ; from Scratchpad to maximise text space.

    MsgBox(Format("
    (
    {2}{1}{1}Show/hide Scratchpad
    Escape{1}{1}Hide Scratchpad (if it's active)

    Ctrl+N {1}{1} New file from template
    {1}{1} (/template.txt)
    Ctrl+Shift+N {1} New file from past file's To Do items

    Alt+Enter {1} Insert list item
    Alt+Shift+Enter {1} Insert To Do item
    Ctrl+Enter {1} Toggle To Do/Done
    Alt+Up/Down {1} Move a line up or down
    Alt+Right/Left {1} Indent or outdent a line

    Ctrl+S {1}{1} Save
    Ctrl+Shift+S {1} Save As
    Ctrl+O {1}{1} Open

    Ctrl+H {1}{1} Help (this window)

    You are using Scratchpad v9, released 2023-03-22.

    desiquintans.com/scratchpad

    Thanks to Freepik for the notepad icon!
    https://www.flaticon.com/free-icon/pencil_3075908
    )",
    A_Tab,
    dq_ReadableHotkey(VisibilityHotkey)
    ), "Help - Scratchpad", 32) ; 0 + 32 + 262144 + 4096)
}


sp_ToggleVisibility(*) {
    If DllCall("IsWindowVisible", "Ptr", WinExist(this_hwnd))
    {
        sp_HideScratchpad()
    }
    else
    {
        sp_ShowScratchpad()
    }
}

sp_HideScratchpad(*) {
    if SaveOnHide == 1 {
        if sp_SafeToAutoSave() == 1 {
            sp_SaveFile(LastActiveFile)
            dq_UnflagTitle(SPGui)
        }
    }

    ; Always save the .ini file when hiding the GUI
    sp_SaveSettings()

    SPGui.Hide()
}


sp_ShowScratchpad(*) {
    sp_RefreshFile()

    SPGui.Show()
}


sp_ResizeEditor(*) {
    global

    SPGui.GetClientPos(,, &GuiWidth, &GuiHeight)

    ; Set editor dimensions
    PadWidth  := Round(GuiWidth  - (GuiMargin * 2), 0) 
    PadHeight := Round(GuiHeight - (GuiMargin * 2), 0)

    SPEditor.Move(GuiMargin, GuiMargin, PadWidth, PadHeight)

    ; I don't save the settings to the .ini in this function because this event is 
    ; actually called every time the GUI is resized even by 1 pixel.
}


sp_SaveSettings() {
    ; Saves user-editable settings to the .ini.
    ; Overwrites all existing key-value pairs.

    global

    IniWrite(VisibilityHotkey, "ScratchpadSettings.ini", "Keybind",   "VisibilityHotkey")

    IniWrite(SaveOnHide,       "ScratchpadSettings.ini", "Behaviour", "SaveOnHide")
    IniWrite(SaveOnFocusLoss,  "ScratchpadSettings.ini", "Behaviour", "SaveOnFocusLoss")
    IniWrite(StartMinimised,   "ScratchpadSettings.ini", "Behaviour", "StartMinimised")
    IniWrite(LastActiveFile,   "ScratchpadSettings.ini", "Behaviour", "LastActiveFile")

    IniWrite(TabSpaces,        "ScratchpadSettings.ini", "Editing",   "TabSpaces")
    IniWrite("`"" . FontName . "`"", "ScratchpadSettings.ini", "Editing",   "FontName")
    IniWrite(FontSizePt,       "ScratchpadSettings.ini", "Editing",   "FontSizePt")
    IniWrite("`"" . ListItem . "`"", "ScratchpadSettings.ini", "Editing",   "ListItem")
    IniWrite("`"" . ToDoItem . "`"", "ScratchpadSettings.ini", "Editing",   "ToDoItem")
    IniWrite("`"" . DoneItem . "`"", "ScratchpadSettings.ini", "Editing",   "DoneItem")

    IniWrite(EditorCols,       "ScratchpadSettings.ini", "Sizing",   "EditorCols")
    IniWrite(EditorRows,       "ScratchpadSettings.ini", "Sizing",   "EditorRows")

    
    
}


sp_LoadSettings() {
    ; Loads user-editable settings from the .ini.
    ; Default settings are hard-coded at the start of this script. If the .ini doesn't
    ; exist, it will create the .ini and save those defaults to it.

    global

    if not FileExist("ScratchpadSettings.ini") {
        sp_SaveSettings()
        return  ; No need to read the .ini; we just set it with already-existing values.
    }

    VisibilityHotkey := IniRead("ScratchpadSettings.ini", "Keybind",   "VisibilityHotkey")

    SaveOnHide       := IniRead("ScratchpadSettings.ini", "Behaviour", "SaveOnHide")
    SaveOnFocusLoss  := IniRead("ScratchpadSettings.ini", "Behaviour", "SaveOnFocusLoss")
    StartMinimised   := IniRead("ScratchpadSettings.ini", "Behaviour", "StartMinimised")
    LastActiveFile   := IniRead("ScratchpadSettings.ini", "Behaviour", "LastActiveFile")

    TabSpaces        := IniRead("ScratchpadSettings.ini", "Editing",   "TabSpaces")
    FontName         := IniRead("ScratchpadSettings.ini", "Editing",   "FontName")
    FontSizePt       := IniRead("ScratchpadSettings.ini", "Editing",   "FontSizePt")
    ListItem         := IniRead("ScratchpadSettings.ini", "Editing",   "ListItem")
    ToDoItem         := IniRead("ScratchpadSettings.ini", "Editing",   "ToDoItem")
    DoneItem         := IniRead("ScratchpadSettings.ini", "Editing",   "DoneItem")

    EditorCols       := IniRead("ScratchpadSettings.ini", "Sizing",    "EditorCols")
    EditorRows       := IniRead("ScratchpadSettings.ini", "Sizing",    "EditorRows")
}


sp_SafeToAutoSave() {
    global
    
    ; If the LastActiveFile is blank, don't autosave (user always does first save of a new file)
    if LastActiveFile == "" {
        return(0)
    }

    ; If LastActiveFile doesn't exist, don't autosave.
    if not FileExist(LastActiveFile) {
        return(0)
    }

    myfile := dq_FileNewerThan(LastActiveFile, LastModifiedAt)

    if myfile.newer == 1 {
        return(0)
    }

    return(1)
}


sp_ToggleToDo() {
    CurrLine := EditGetCurrentLine(SPEditor)
    ThisLine := EditGetLine(CurrLine, SPEditor)

    if not InStr(ThisLine, ToDoItem) and not InStr(ThisLine, DoneItem) {
        return
    }

    if InStr(ThisLine, ToDoItem) {
        NewLine := StrReplace(ThisLine, ToDoItem, DoneItem)
    } else {
        NewLine := StrReplace(ThisLine, DoneItem, ToDoItem)
    }

    Send("{End}+{Home}{Backspace}")
    EditPaste(NewLine, SPEditor)
    Send("{Down}")
}


sp_Exit(*) {
    SPGui.Opt("+OwnDialogs")

    sp_SaveSettings()

    myfile := dq_FileNewerThan(LastActiveFile, LastModifiedAt)

    if myfile.newer == 0 {
    	SaveBeforeExit := MsgBox("Do you want to save before exiting?", 
                             "Save before exiting? - Scratchpad", 4 + 48)

    	if SaveBeforeExit == "Yes" {
	        if sp_SafeToAutoSave() == 1 {
	            sp_SaveFile(LastActiveFile)
	        } else {
	            sp_SaveFile("")
	        }
    	}
    }
}


sp_MoveLine(Dir) {
    /*
     * This is an imperfect solution; EditGetLine() only returns visual lines, not the actual line
     * in the file; if a long line wraps, then only the current soft-wrapped line under the cursor
     * will be moved. 
     * 
     * I found that splitting the control's value into an array
     *      StrSplit(SPEditor.Value, ["`r`n", "`n"])
     * worked to return the whole line, and I had hoped that I would be able to .InsertAt() to move 
     * the entire line around the document. However, there were a few major obstacles in what AHK
     * lets me do:
     * 
     * 1. How do I convert the cursor position in soft-wrapped lines into a position within 
     *    unwrapped lines? I *could* RegExMatch() it, but then there is the possibility that a 
     *    partial line will match multiple places in the document.
     * 2. How do I return the user's cursor to a sensible place in the document? There is no 
     *    such thing as an EditPutCursor() function.
     * 3. How do I handle a selection of multiple lines? I can get the text of the selection with
     *    EditGetSelectedText(), but then there is no way to ensure that the entirety of those 
     *    lines is selected, especially when they're soft-wrapped.
     * 
     * I therefore decided that even though moving a single visual line up or down is an imperfect
     * solution, it's the only solution that works predictably all the time.
    */

    CurrLine := EditGetCurrentLine(SPEditor)
    ThisLine := EditGetLine(CurrLine, SPEditor)

    if (Dir == "up") {
        SendInput("{Home}+{End}{Backspace 2}{Home}{Enter}{Up}")
    } else {
        SendInput("{Home}+{End}{Backspace 2}{Down 2}{Home}{Enter}{Up}")
    }
    
    EditPaste(ThisLine, SPEditor)
}


sp_Dent(Dir) {
    /*
     * This is likewise an imperfect solution, but not as bad. I decided to type the indenting 
     * spaces so that the visual lines would reflow properly. In an ideal world, in/outdenting 
     * a visual line would in/outdent the entire physical line, but AHK's Edit control is too 
     * barebones to achieve that.
    */

    CurrLine := EditGetCurrentLine(SPEditor)
    ThisLine := EditGetLine(CurrLine, SPEditor)

    if (Dir == "in") {
        SendInput(Format("{Home}^{Right}^{Left}{Space {1}}{End}", TabSpaces))
    } else {
        ; If the first [TabSpaces] characters of the line match the indent spaces, then remove them.
        ; If not, then return the line unchanged because it is already outdented at max. 

        if (SubStr(ThisLine, 1, TabSpaces) == dq_Rep(A_Space, TabSpaces)) {
            SendInput(Format("{Home}^{Right}^{Left}{Backspace {1}}{End}", TabSpaces))
        }
    }
}
