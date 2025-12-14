; ===============================
; Full F3 -> Left Mouse Button
; ===============================

#Requires AutoHotkey v2.0

; --- Single Click / Hold / Drag ---
F3::
{
    SendInput("{LButton down}")
    KeyWait("F3")
    SendInput("{LButton up}")
}

; AHK v2 - Remap Middle Mouse Button to Back
MButton::Send("!{Left}")