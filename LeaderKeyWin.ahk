#Requires AutoHotkey v2.0
A_MenuMaskKey := "vkE8"

global leaderTimeout := 0
global leaderHoldTimeout := 0
global leaderKey := "b"
global lkeyWithPre
global currentSeq := ""
global defaultShellPrefix := "pwsh -NoExit -Command"
global box
global ih
global isLeader

; TODO 写得太丑陋了，需要重构
; TODO 最后改为解析一次配置文件，然后生成对应的函数，不要每次解析
global keyMap := Map(
    "av", ["Exec nvim"],
    "ap", ["Exec wt -p PowerShell"],
    ; "wr", ["Run wm-enalbe-binding-mode --name resize"],
    "b", ["Just Do It!!!!!"]
)

SetupLeaderKey() {
    global lkeyWithPre
    global useCapsPlus

    Hotkey(lkeyWithPre, (*) => SendInput("{Blind}{vkE8}"), "On")
    Hotkey(lkeyWithPre " Up", LeaderUpHandler, "On")
}

IsModifierKey(key) {
    modifierKeys := ["LWin", "RWin", "Ctrl", "LCtrl", "RCtrl", "Alt", "LAlt", "RAlt", "Shift", "LShift", "RShift"]
    for _, modKey in modifierKeys
        if key == modKey
            return true

    return false
}


LeaderUpHandler(thisHotkey) {
    global isLeader
    if (isLeader)
        return

    if (A_PriorKey != leaderKey || (A_TimeSincePriorHotkey > leaderHoldTimeout && leaderHoldTimeout > 0)) {
        return  ; 有其他鍵介入 → 直接忽略，不啟動 leader
    }

    isLeader := true
    Hotkey("~" lkeyWithPre, (*) => SendInput("{Blind}{vkE8}"), "Off")
    Hotkey("~" lkeyWithPre " Up", LeaderUpHandler, "Off")

    global currentSeq
    currentSeq := ""
    global box := Gui("-SysMenu +ToolWindow +AlwaysOnTop -Caption -DPIScale +E0x20 +E0x08000000")
    box.AddText(, "<Leader>")
    box.Show("NoActivate")


    global ih := InputHook("T" leaderTimeout / 1000)
    ih.KeyOpt("{All}", "N")
    ih.NotifyNoncharacter := false
    ih.OnKeyUp := OnKeyDownHandler
    ih.Start()
    ih.Wait()
}

OnKeyDownHandler(ih, vk, sc) {
    global box
    global currentSeq

    key := GetKeyName(Format("vk{:X}sc{:X}", vk, sc))
    currentSeq := currentSeq . key

    box.Destroy()
    box := Gui("-SysMenu +ToolWindow +AlwaysOnTop -Caption -DPIScale +E0x20 +E0x08000000")
    box.AddText(, "<Leader>" . currentSeq)
    box.Show("NoActivate")

    ; 完全匹配 → 执行函数
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
        SendInput(action)
    }

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

    lkeyWithPre := leaderKey

    ; 如果是修饰键的话，要保留原来的长按功能，需要加上 ~
    ; 如果是普通键，加了会导致当作leaderkey的时候还输入文本
    ; 不过老实说我为什么要专门写这个功能呢，真的会有人拿文本键当leaderkey吗？
    ; 啊想了一下不止文本键，如果是什么capslock insert pageup nunlock之类的也可以用来当leaderkey，这就需要抑制原本的功能了
    ; 但是我自己用了Capslock+会导致Capslock的长按按键出问题
    if IsModifierKey(leaderKey)
        lkeyWithPre := "~" . lkeyWithPre

    SetupLeaderKey()
}

ClearStatus()