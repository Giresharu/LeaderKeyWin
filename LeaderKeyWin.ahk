#Requires AutoHotkey v2.0
#Include lib\ahk2_lib\YAML.ahk

A_MenuMaskKey := "vkE8"

global version := "0.0.1 alpha"

; global keyMap := Map(
;     ; "<LWin>", ["{Blind}{LWin Down}{LWin Up}"],
;     "tt", ["Exec wt"],
;     "top", ["Exec wt -p PowerShell"],
;     "toc", ["Exec wt -p CMD"],
;     "ton", ["Exec wt -p NAS"],
;     "tow", ["Exec wt -p HiWifi_4_Pro"],
;     "ap", ['Exec "C:\Program Files\Bitwarden\Bitwarden.exe"'],
;     "ee", ["Exec explorer"],
;     "eop", ["Exec yazi D:\Project"],
;     "eon", ["Exec yazi \\NAS\gsr"],
;     "ff", ["#f"],
;     "fl", ["^+!f"],
;     "fe", ['Exec "C:\Program Files\Everything\Everything.exe"'],
;     "we", ['Run glazewm command wm-enable-binding-mode --name WINDOW-EDIT-MODE'],
;     "wf", ['Run glazewm command wm-enable-binding-mode --name FOCUS-MODE', 'Run chord_g7.vbs'],
;     "w{LShift}h", ['Run glazewm command move --direction left'],
;     "w{LShift}j", ['Run glazewm command move --direction down'],
;     "w{LShift}k", ['Run glazewm command move --direction up'],
;     "w{LShift}l", ['Run glazewm command move --direction right'],
;     "w{LShift}w", ['Run glazewm command move --recent-workspace'],
;     "w{LShift}p", ['Run glazewm command move --prev-workspace'],
;     "w{LShift}n", ['Run glazewm command move --next-workspace'],
;     "w{LShift}1", ['Run glazewm command move --workspace 1'],
;     "w{LShift}2", ['Run glazewm command move --workspace 2'],
;     "w{LShift}3", ['Run glazewm command move --workspace 3'],
;     "w{LShift}4", ['Run glazewm command move --workspace 4'],
;     "w{LShift}4", ['Run glazewm command move --workspace 4'],
;     "w{LShift}5", ['Run glazewm command move --workspace 11'],
;     "w{LShift}6", ['Run glazewm command move --workspace 22'],
;     "w{LShift}7", ['Run glazewm command move --workspace 33'],
;     "w{LShift}8", ['Run glazewm command move --workspace 44'],
;     "wh", ['Run glazewm command focus --direction left'],
;     "wj", ['Run glazewm command focus --direction down'],
;     "wk", ['Run glazewm command focus --direction up'],
;     "wl", ['Run glazewm command focus --direction right'],
;     "ww", ['Run glazewm command focus --recent-workspace'],
;     "wp", ['Run glazewm command focus --prev-workspace'],
;     "wn", ['Run glazewm command focus --next-workspace'],
;     "w1", ['Run glazewm command focus --workspace 1'],
;     "w2", ['Run glazewm command focus --workspace 2'],
;     "w3", ['Run glazewm command focus --workspace 3'],
;     "w4", ['Run glazewm command focus --workspace 4'],
;     "w4", ['Run glazewm command focus --workspace 4'],
;     "w5", ['Run glazewm command focus --workspace 11'],
;     "w6", ['Run glazewm command focus --workspace 22'],
;     "w7", ['Run glazewm command focus --workspace 33'],
;     "w8", ['Run glazewm command focus --workspace 44'],
;     "v", ['^+!v'],
; )

class Config {
    static leaderTimeout := 0
    static leaderHoldTimeout := 0
    static leaderKey := "LWin"
    static leaderKeyWithPre := ""
    static defaultShellPrefix := "pwsh -NoExit -Command"
    static dataPath := EnvGet("LOCALAPPDATA") . "\LeaderKeyWin"
    static modifierKeyStatus := Map(
        "LCtrl", "",
        "RCtrl", "",
        "LAlt", "",
        "RAlt", "",
        "LShift", "",
        "RShift", "",
    )
    static keyMap := ""
}

class Status {
    static leaderState := 0
}

class Log {
    static file := Config.dataPath "\_.log"

    static Log(message := "", title := "", level := "INFO", autoIndent := true) {

        if title
            title := '[' title '] '

        timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
        levelStr := "[" level "]"      ; INFO, WARN, ERROR 等
        prefix := timestamp " " levelStr " "
        indent := ""

        if autoIndent
            loop (StrLen(prefix)) {
                indent .= " "
            }

        message := StrReplace(message, '`n', '`n' . indent)

        line := prefix . title . message "`n"

        try
            FileAppend(line, Log.file, "UTF-8")
        catch Error as e {
            if e.Number == 3 {
                DirCreate(Config.dataPath)
                FileAppend(line, Log.file, "UTF-8")
            } else throw
        }
    }

    static LogWarn(message := "", title := "", autoIndent := true) {
        Log.Log(message, title, "WARN")
    }

    static LogError(message := "", title := "", autoIndent := true) {
        Log.Log(message, title, "ERROR")
    }

    static LogFatal(message := "", title := "", autoIndent := true) {
        Log.Log(message, title, "FATAL")
    }
}

Init() {
    try {

        Log.Log("----------------------------------------------------------------------------------------------`n"
            " _        ___   ____  ___      ___  ____       __  _    ___  __ __      __    __  ____  ____  `n" .
            "| |      /  _] /    ||   \    /  _]|    \     |  |/ ]  /  _]|  |  |    |  |__|  ||    ||    \ `n" .
            "| |     /  [_ |  o  ||    \  /  [_ |  D  )    |  ' /  /  [_ |  |  |    |  |  |  | |  | |  _  |`n" .
            "| |___ |    _]|     ||  D  ||    _]|    /     |    \ |    _]|  ~  |    |  |  |  | |  | |  |  |`n" .
            "|     ||   [_ |  _  ||     ||   [_ |    \     |     ||   [_ |___, |    |  ``  '  | |  | |  |  |`n" .
            "|     ||     ||  |  ||     ||     ||  .  \    |  .  ||     ||     |     \      /  |  | |  |  |`n" .
            "|_____||_____||__|__||_____||_____||__|\_|    |__|\_||_____||____/       \_/\_/  |____||__|__|`n`n" .
            "----------------------------------------------------------------------------------------------`n"
        )
        try
            Log.Log(FileRead(A_ScriptDir "\LICENSE.txt"))

        Log.Log("Initialization started.")
        InitConfig()
        InitLeaderKey()
        Log.Log("Initialization completed.")
        Log.Log("Leader Key Win started. Enjoy!")
    }
    catch Error as e {
        err := "`n[" e.What "] "
        err := err . e.Message "`n"
        err := err . e.Stack
        Log.LogFatal(err, 'Unexpected termination', "FATAL")
        throw
    }
}

InitConfig() {
    Log.Log("Loading config...")
    configPath := Config.dataPath . "\config.yaml"
    if !FileExist(configPath) {
        if !DirExist(Config.dataPath)
            DirCreate(Config.dataPath)
        Log.Log('Config file: "' configPath '" does NOT EXIST. Attempting to create it...')
        FileCopy(A_ScriptDir . "\default_config.yaml", configPath)
        Log.Log('Successfully created "' configPath '".')
    }

    configStr := FileRead(configPath, "UTF-8")
    configMap := YAML.parse(configStr)

    Log.Log("Generating Keymap...")
    Config.keymap := GenerateKeyMap(configMap["keymap"])
    Log.Log("Keymap Generated.")
}

InitLeaderKey() {
    ; 如果是修饰键的话，要保留原来的长按功能，需要加上 ~
    ; 如果是普通键，加了会导致当作leaderkey的时候还输入文本
    ; 为了阻止开始菜单乱跳，Win键不能添加 ~ ，无法保持优先度不高的原有组合键功能，如 Win+V Win+E以及其他 ahk 脚本实现的 Win 组合键等，但 Win+L 是可以的。这可能和钩子优先级有关
    if Config.leaderKeyWithPre == "" {
        if IsModifierKey(Config.leaderKey)
            Config.leaderKeyWithPre := "~" . Config.leaderKey
        else
            Config.leaderKeyWithPre := Config.leaderKey
    }
    SetupLeaderKey()
    Log.Log("Leader Key generated.")
}


GenerateKeyMap(keymapConfigArr, locate := []) {
    keymap := Map()
    for _, keymapConfigItem in keymapConfigArr {
        if Type(keymapConfigItem) == "String" {
            Log.LogWarn("A keymapItem located at:`n" FormatKeymapLocate(keymapConfigItem, locate) "`nshould be objects with fields, not direct values.", 'Invalid Format')
            continue
        }

        ;读取key作为索引
        if !keymapConfigItem.Has("key") {
            Log.LogWarn("A keymapItem located at:`n" FormatKeymapLocate(keymapConfigItem, locate) "`nis missing the required 'key' field.", 'Invalid Format')
            continue
        }

        key := SortModifierKey(keymapConfigItem["key"])
        if !key {
            Log.LogWarn("A keymapItem located at:`n" FormatKeymapLocate(keymapConfigItem, locate) "`nhas an 'key' field with no valid value", 'Invalid Format')
            continue
        }

        keymapConfigItem.Delete("key")
        here := locate.Clone()
        here.Push(key)
        keymapItem := Map()

        if keymapConfigItem.Has("subKeymap") {
            keymapItem["subKeymap"] := GenerateKeyMap(keymapConfigItem["subKeymap"], here)
            keymapConfigItem.Delete("subKeymap")
        } else if keymapConfigItem.Has("commands") {
            commandConfigs := keymapConfigItem["commands"]
            if Type(commandConfigs) != "Array" {
                commandConfigs := [commandConfigs]
            }
            commands := commandConfigs
            for i, c in commandConfigs {
                commands[i] := GenerateCommandCallback(c)
            }
            keymapConfigItem.Delete("commands")
            keymapItem["commands"] := commands

        } else {
            Log.LogWarn("A keymapItem located at:`n" FormatKeymapLocate(keymapConfigItem, locate) "`nhas neither 'subKeymap' field nor 'commands' field.", 'Invalid Format')
            continue
        }

        ; 读取其他字段
        for k, v in keymapConfigItem {
            keymapItem[k] := v
        }

        keymap[key] := keymapItem
    }
    return keymap
}

FormatKeymapLocate(configItem, locate) {
    str := "keymap:`n"
    indent := ""
    for l in locate {
        indent .= "  "
        str .= indent . '- key: "' l '"`n'
        str .= indent . '  subKeymap:`n'
        indent := indent . "  "
    }
    indent .= "  "

    if Type(configItem) != "String" && configItem.Has("key") {
        return str . indent . '- key: "' configItem["key"] '"'
    }
    return str . indent . '- *'
}

SortModifierKey(key) {
    matchLen := RegExMatchAll(key, '(?:\{[^}]+\})*(?:[^{}]+)?', &combos)
    if !matchLen {
        return ""
    }
    if matchLen == 1 {
        ;从1开始，哈哈
        return combos[1]
    }

    key := ""
    for c in combos {
        RegExMatchAll(c, '\{[^}]+\}|[^{}]+', &keys)
        str := ""
        for modifier, _ in Config.modifierKeyStatus {
            for i, v in keys {
                if !v
                    continue
                if modifier == Trim(v, ' {}') {
                    str .= v
                    keys[i] := ""
                }
            }
        }
        for v in keys {
            str .= v
        }
        key .= str
    }
    return key
}

RegExMatchAll(str, pattern, &arr := "") {
    arr := []
    pos := 1
    len := StrLen(str)
    while RegExMatch(str, pattern, &match, pos) {
        arr.Push(match[0])
        pos := match.Pos + match.Len
        if !match.Len
            pos += 1

        if (pos > len) {
            break
        }
    }
    return arr.Length
}

SetupLeaderKey() {
    Hotkey(Config.leaderKeyWithPre, (*) => SendInput("{Blind}{vkE8}"), "On")
    Hotkey(Config.leaderKeyWithPre " Up", LeaderUpHandler, "On")
}

IsModifierKey(key) {
    for modifier, _ in Config.modifierKeyStatus
        if key == modifier
            return true

    return false
}

Control2Ctrl(control) {
    if control == "LControl" || control == "RControl"
        control := StrReplace(control, "ontrol", "trl")
    return control
}

LeaderUpHandler(_) {
    if (Status.leaderState) {
        return
    }

    priorKey := Control2Ctrl(A_PriorKey)
    if (priorKey != Config.leaderKey || (A_TimeSincePriorHotkey > Config.leaderHoldTimeout && Config.leaderHoldTimeout > 0)) {
        return
    }

    Status.leaderState := true
    Hotkey(Config.leaderKeyWithPre, (*) => SendInput("{Blind}{vkE8}"), "Off")
    Hotkey(Config.leaderKeyWithPre " Up", LeaderUpHandler, "Off")

    ; 待修改GUI

    ih := InputHook("M T" Config.leaderTimeout / 1000)
    ih.KeyOpt('{All}', "N")
    ih.NotifyNoncharacter := true
    ih.OnKeyUp := OnKeyUpHandler
    ih.OnKeyDown := OnKeyDownandler
    ih.Start()
}

OnKeyDownandler(ih, vk, sc) {
    ; 如果是修饰键按下，就记住修饰键已按下，等到释放的时候过滤修饰键
    key := Control2Ctrl(GetKeyName(Format("vk{:X}sc{:X}", vk, sc)))
    if IsModifierKey(key)
        Config.modifierKeyStatus[key] := "waitting"
}

OnKeyUpHandler(ih, vk, sc) {
    static s_sequence := ""
    static s_keymap := ""

    key := Control2Ctrl(GetKeyName(Format("vk{:X}sc{:X}", vk, sc)))
    if IsModifierKey(key) {
        ; 如果是修饰键释放，清除状态并过滤信号
        Config.modifierKeyStatus[key] := ""
        return
    }

    modifierSequence := ""
    for modifier in Config.modifierKeyStatus {
        if Config.modifierKeyStatus[modifier] == "waitting" {
            ; 如果有等待记录的修饰键，则记录并修改状态
            modifierSequence .= "{" modifier "}"
            Config.modifierKeyStatus[modifier] := "done"
        }
    }

    key := modifierSequence . key
    s_sequence := s_sequence . key

    ;TODO 匹配修饰符不到的时候尝试匹配没有LR的版本

    if s_keymap == ""
        s_keymap := Config.keyMap

    if s_keymap.Has(s_sequence) {
        s_keymap := s_keymap[s_sequence]
        if s_keymap.Has("subKeymap") {
            ; 如果包含 subKeymap 还需要继续等待下一个 s_sequence
            s_keymap := s_keymap["subKeymap"]
            s_sequence := ""
            return
        }

        ; 提早结束 InputHook 防止用户配置的 SendInput 被脚本捕获
        ih.Stop()
        for c in s_keymap["commands"] {
            c()
        }
    } else {
        ; 没有匹配到但是 s_sequence 被包含在某个 key 内，那就需要继续等待下一个按键来完善 s_sequence
        for k in s_keymap {
            if InStr(k, s_sequence, 1, true) == 1
                return
        }
    }

    s_sequence := ""
    s_keymap := ""
    ih.Stop()
    ClearStatus()
}

GenerateCommandCallback(command) {
    result := ParseCommand(command)
    if result {
        ; 索引从1开始太逆天了我只能说，见一次我就要说一次
        pre := result[1]
        cmd := result[2]
        if pre == "RunWait" {
            return () => RunWait(cmd, , "Hide")
        }
        if pre == "Run" {
            return () => Run(cmd, , "Hide")

        }
        if pre == "ExecWait" {
            return () => RunWait(cmd)

        }
        if pre == "Exec" {
            return () => Run(cmd)

        }
        if pre == "$" {
            return () => Run(Config.defaultShellPrefix . " " . cmd)
        }
    }
    return () => SendInput(command)
}

ParseCommand(command) {
    keywords := ["ExecAwait", "Exec", "RunAwait", "Run", "$"]
    pre := ""

    for _, v in keywords
        if InStr(command, v, 1, true) = 1 {
            pre := v
            keywordLength := StrLen(v)
            break
        }

    if pre = ""
        return 0

    cmd := Trim(SubStr(command, keywordLength + 1), " ")
    return [pre, cmd]
}

ClearStatus() {
    Status.leaderState := 0
    SetupLeaderKey()
}

Init()