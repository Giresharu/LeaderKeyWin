#Requires AutoHotkey v2.0
A_MenuMaskKey := "vkE8"

global leaderTimeout := 0
global leaderHoldTimeout := 0
global leaderKey := "LWin"
global lkeyWithPre := ""
global currentSeq := ""
global defaultShellPrefix := "pwsh -NoExit -Command"
global box
global ih
global isLeader

; TODO 写得太丑陋了，需要重构
; TODO 最后改为解析一次配置文件，然后生成对应的函数，不要每次解析
; TODO 解析的时候应该按照 modifierKeyStatus 里面的顺序来修改用户写的修饰符顺序
global keyMap := Map(
    ; "<LWin>", ["{Blind}{LWin Down}{LWin Up}"],
    "tt", ["Exec wt"],
    "top", ["Exec wt -p PowerShell"],
    "toc", ["Exec wt -p CMD"],
    "ton", ["Exec wt -p NAS"],
    "tow", ["Exec wt -p HiWifi_4_Pro"],
    "ap", ['Exec "C:\Program Files\Bitwarden\Bitwarden.exe"'],
    "ee", ["Exec yazi ~"],
    "eop", ["Exec yazi D:\Project"],
    "eon", ["Exec yazi \\NAS\gsr"],
    "ff", ["#f"],
    "fl", ["^+!f"],
    "fe", ['Exec "C:\Program Files\Everything\Everything.exe"'],
    "we", ['Run glazewm command wm-enable-binding-mode --name WINDOW-EDIT-MODE'],
    "wf", ['Run glazewm command wm-enable-binding-mode --name FOCUS-MODE'],
    "w{LShift}h", ['Run glazewm command move --direction left'],
    "w{LShift}j", ['Run glazewm command move --direction down'],
    "w{LShift}k", ['Run glazewm command move --direction up'],
    "w{LShift}l", ['Run glazewm command move --direction right'],
    "w{LShift}w", ['Run glazewm command move --recent-workspace'],
    "w{LShift}p", ['Run glazewm command move --prev-workspace'],
    "w{LShift}n", ['Run glazewm command move --next-workspace'],
    "w{LShift}1", ['Run glazewm command move --workspace 1'],
    "w{LShift}2", ['Run glazewm command move --workspace 2'],
    "w{LShift}3", ['Run glazewm command move --workspace 3'],
    "w{LShift}4", ['Run glazewm command move --workspace 4'],
    "w{LShift}4", ['Run glazewm command move --workspace 4'],
    "w{LShift}5", ['Run glazewm command move --workspace 11'],
    "w{LShift}6", ['Run glazewm command move --workspace 22'],
    "w{LShift}7", ['Run glazewm command move --workspace 33'],
    "w{LShift}8", ['Run glazewm command move --workspace 44'],
    "wh", ['Run glazewm command focus --direction left'],
    "wj", ['Run glazewm command focus --direction down'],
    "wk", ['Run glazewm command focus --direction up'],
    "wl", ['Run glazewm command focus --direction right'],
    "ww", ['Run glazewm command focus --recent-workspace'],
    "wp", ['Run glazewm command focus --prev-workspace'],
    "wn", ['Run glazewm command focus --next-workspace'],
    "w1", ['Run glazewm command focus --workspace 1'],
    "w2", ['Run glazewm command focus --workspace 2'],
    "w3", ['Run glazewm command focus --workspace 3'],
    "w4", ['Run glazewm command focus --workspace 4'],
    "w4", ['Run glazewm command focus --workspace 4'],
    "w5", ['Run glazewm command focus --workspace 11'],
    "w6", ['Run glazewm command focus --workspace 22'],
    "w7", ['Run glazewm command focus --workspace 33'],
    "w8", ['Run glazewm command focus --workspace 44'],
    "v", ['^+!v'],
)


global modifierKeyStatus := Map(
    "LCtrl", "",
    "RCtrl", "",
    "LAlt", "",
    "RAlt", "",
    "LShift", "",
    "RShift", "",
)

SetupLeaderKey() {
    global lkeyWithPre

    Hotkey(lkeyWithPre, (*) => SendInput("{Blind}{vkE8}"), "On")
    Hotkey(lkeyWithPre " Up", LeaderUpHandler, "On")
}

IsModifierKey(key) {
    for k, _ in modifierKeyStatus
        if key == k
            return true

    return false
}

Control2Ctrl(control) {
    if control == "LControl" || control == "RControl"
        control := StrReplace(control, "ontrol", "trl")
    return control
}


LeaderUpHandler(thisHotkey) {
    global isLeader
    if (isLeader) {
        ih.Stop()
        ClearStatus()
        return
    }

    priorKey := Control2Ctrl(A_PriorKey)
    if (priorKey != leaderKey || (A_TimeSincePriorHotkey > leaderHoldTimeout && leaderHoldTimeout > 0)) {
        return  ; 有其他鍵介入 → 直接忽略，不啟動 leader
    }

    isLeader := true
    Hotkey(lkeyWithPre, (*) => SendInput("{Blind}{vkE8}"), "Off")
    Hotkey(lkeyWithPre " Up", LeaderUpHandler, "Off")

    global currentSeq
    currentSeq := ""
    global box := Gui("-SysMenu +ToolWindow +AlwaysOnTop -Caption -DPIScale +E0x20 +E0x08000000")
    box.AddText(, "<Leader>")
    box.Show("NoActivate")


    global ih := InputHook("M T" leaderTimeout / 1000)
    ih.KeyOpt('{All}', "N")
    ih.NotifyNoncharacter := true
    ih.OnKeyUp := OnKeyUpHandler
    ih.OnKeyDown := OnKeyDownandler
    ih.Start()
    ih.Wait()
}

OnKeyDownandler(ih, vk, sc) {
    ; 如果是修饰键按下，就记住修饰键已按下，等到释放的时候过滤到修饰键
    key := Control2Ctrl(GetKeyName(Format("vk{:X}sc{:X}", vk, sc)))
    global modifierKeyStatus

    for k in modifierKeyStatus
        if key == k
            modifierKeyStatus[k] := "waitting"
}

OnKeyUpHandler(ih, vk, sc) {
    global box
    global currentSeq

    key := Control2Ctrl(GetKeyName(Format("vk{:X}sc{:X}", vk, sc)))

    if IsModifierKey(key) {
        ; 如果是修饰键释放，清楚状态并过滤信号
        modifierKeyStatus[key] := ""
        return
    }

    for k in modifierKeyStatus {
        if modifierKeyStatus[k] == "waitting" {
            ; 如果有等待记录的修饰键，则记录并修改状态
            key := "{" k "}" . key
            modifierKeyStatus[k] := "done"
        }
    }

    currentSeq := currentSeq . key

    box.Destroy()
    box := Gui("-SysMenu +ToolWindow +AlwaysOnTop -Caption -DPIScale +E0x20 +E0x08000000")
    box.AddText(, "<Leader>" . currentSeq)
    box.Show("NoActivate")

    ; 完全匹配 → 执行函数
    ;TODO 匹配修饰符不到的时候尝试匹配没有LR的版本
    if keyMap.Has(currentSeq) {
        ih.Stop()
        for action in keyMap[currentSeq] {
            if action != "Just Do It!!!!!"
                DoAction(action)
            else
                SendInput(key)
        }
        ClearStatus()
        return
    }

    ; 检查是否还有任何 key 以 currentSeq 开头
    hasPrefix := false
    for k in keyMap {
        if InStr(k, currentSeq, 1, true) = 1 {
            hasPrefix := true
            return
        }
    }
    ih.Stop()
    ClearStatus()
}

DoAction(action) {
    result := ParseCMD(action)
    if result {
        ; 索引从1开始太逆天了我只能说，见一次我就要说一次
        prefix := result[1]
        cmd := result[2]
        if prefix = "RunAwait" {
            RunWait(cmd, , "Hide")
            return
        }
        if prefix = "Run" {
            Run(cmd, , "Hide")
            return
        }
        if prefix = "ExecAwait" {
            RunWait(cmd)
            return
        }
        if prefix = "Exec" {
            Run(cmd)
            return
        }
        if prefix = "$" {
            Run(defaultShellPrefix . " " . cmd)
        }
    }
    SendInput(action)
}

ParseCMD(action) {
    keywords := ["ExecAwait", "Exec", "RunAwait", "Run", "$"]
    prefix := ""

    for _, v in keywords
        if InStr(action, v, 1, true) = 1 {
            prefix := v
            keywordLength := StrLen(v)
            break
        }

    if prefix = ""
        return 0

    cmd := Trim(SubStr(action, keywordLength + 1), " ")
    return [prefix, cmd]
}

ClearStatus() {
    global currentSeq
    global isLeader
    global box
    global lkeyWithPre

    isLeader := false
    if IsSet(box) && box
        box.Destroy()
    currentSeq := ""


    ; 如果是修饰键的话，要保留原来的长按功能，需要加上 ~
    ; 如果是普通键，加了会导致当作leaderkey的时候还输入文本
    ; 不过老实说我为什么要专门写这个功能呢，真的会有人拿文本键当leaderkey吗？
    ; 啊想了一下不止文本键，如果是什么capslock insert pageup nunlock之类的也可以用来当leaderkey，这就需要抑制原本的功能了
    ; 但是我自己用了Capslock+会导致Capslock的长按按键出问题
    if !lkeyWithPre {
        if IsModifierKey(leaderKey)
            lkeyWithPre := "~" . leaderKey
        else
            lkeyWithPre := leaderKey
    }

    SetupLeaderKey()
}

ClearStatus()