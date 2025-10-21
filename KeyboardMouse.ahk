#Requires AutoHotkey v1

#SingleInstance Force

#include <HeckerFunc>

;-------------------------------------------------------

CoordMode, ToolTip, Screen

;-------------------------------------------------------

toolTipTimeout := 1500
iniFile := regexreplace(A_ScriptFullPath, "\.[^.]+$", ".ini")

; Possible directions (object keys are used in ini direction naming as well)
directions := {}
directions["Left"] := {axises: {x:-1, y:0}}
directions["Right"] := {axises: {x:1, y:0}}
directions["Up"] := {axises: {x:0, y:-1}}
directions["Down"] := {axises: {x:0, y:1}}

cursorMoving := false
continuousMouseControlOn := false

;-----------------------

scriptSectionName := "hotkeys"
scriptOptionSectionName := "options"

IniRead, cursorSpeedOptions, %iniFile% , %scriptOptionSectionName%, cursorSpeedOptions, %A_Space%
IniRead, cursorSpeedIndex, %iniFile% , %scriptOptionSectionName%, initialSpeedOptionIndex, %A_Space%

; cursorSpeedIndex - Describes which speed option is set at the moment from cursorSpeedOptions
; By default 0, if the options are default as well, then 2.
cursorSpeedIndex := cursorSpeedIndex == "" ? (cursorSpeedOptions == "" ? 2 : 0) : cursorSpeedIndex
; cursorSpeedOptions - The possible cursor speed options to switch from
cursorSpeedOptions := cursorSpeedOptions == "" ? [50, 100, 250, 500, 1000, 2500, 5000, 10000] : StrSplit(cursorSpeedOptions, ",", " ")

;-------------------------------------------------------

prepareContinousMouseControll()
mapConfigHotkeyToFunction(iniFile, scriptSectionName, "setContinuousMouseControl")

; 1 pixel movement
for direction, directionData in directions {
	mapConfigHotkeyToFunction(iniFile, scriptSectionName, ["moveCursor" . direction, "moveCursor"], [directionData.axises.x, directionData.axises.y])
}

;-------------------------------------------------------
;-------------------------------------------------------

moveCursor(x, y) {
	MouseMove, x, y, 0, R
}

;-------------------------------------------------------

#If continuousMouseControlOn
#If

prepareContinousMouseControll() {
	global iniFile
	global scriptSectionName
	global continuousMouseControlOn ;Set in setContinuousMouseControl
	global cursorMoving ;Set in moveCursorContinuously based on cursor is being moved or not
	global directions ;Set at top of the script

	Hotkey If, continuousMouseControlOn

	; Set cursor mover hotkeys
	for direction, directionData in directions {
		; Save moving keys to later check their state
		iniKey := "moveCursorContinously" . direction
		IniRead, directionHotkey, %iniFile% , %scriptSectionName%, %iniKey%, %A_Space%
		if (directionHotkey != "")
			directionData["hotkey"] := directionHotkey

		; Set cursor mover hotkey
		mapConfigHotkeyToFunction(iniFile, scriptSectionName, [iniKey, "moveCursorContinously"])
	}

	mapConfigHotkeyToFunction(iniFile, scriptSectionName, ["changeCursorSpeedUp", "changeCursorSpeed"], [1])
	mapConfigHotkeyToFunction(iniFile, scriptSectionName, ["changeCursorSpeedDown", "changeCursorSpeed"], [-1])

	mapConfigHotkeyToFunction(iniFile, scriptSectionName, ["leftClick", "mouseAction"], ["LButton"])
	mapConfigHotkeyToFunction(iniFile, scriptSectionName, ["rightClick", "mouseAction"], ["RButton"])
	mapConfigHotkeyToFunction(iniFile, scriptSectionName, ["middleClick", "mouseAction"], ["MButton"])
	mapConfigHotkeyToFunction(iniFile, scriptSectionName, ["macro1", "mouseAction"], ["XButton1"])
	mapConfigHotkeyToFunction(iniFile, scriptSectionName, ["macro2", "mouseAction"], ["XButton2"])

	mapConfigHotkeyToFunction(iniFile, scriptSectionName, ["scrollUp", "mouseScroll"], ["WheelUp"])
	mapConfigHotkeyToFunction(iniFile, scriptSectionName, ["scrollDown", "mouseScroll"], ["WheelDown"])

	mapConfigHotkeyToFunction(iniFile, scriptSectionName, "doubleClick")
	mapConfigHotkeyToFunction(iniFile, scriptSectionName, "tripleClick")

	Hotkey If
}

setContinuousMouseControl() {
	global continuousMouseControlOn ;Global value to set here
	global toolTipTimeout ;Set at top of the script
	continuousMouseControlOn := !continuousMouseControlOn

	tmpToolTip("Continous mouse controll: " . (continuousMouseControlOn ? "On" : "Off"), toolTipTimeout)
}

moveCursorContinously() {
	global cursorMoving
	global directions

	if (cursorMoving) {
		return
	} else
		cursorMoving := true

	lastTime := A_TickCount
	stillMoving := true
	remainder := 0
	while (stillMoving) {
		stillMoving := false
		directionSum := {x:0, y:0}

		for direction, directionData in directions {
			if (GetKeyState(directionData["hotkey"], "P")) {
				stillMoving := true

				directionSum.x += directionData.axises.x
				directionSum.y += directionData.axises.y
			}
		}

		elapsedMilisecs := A_TickCount - lastTime
		lastTime := A_TickCount

		pixelsToMove := (elapsedMilisecs / 1000 * getCursorSpeed()) + remainder
		remainder := mathMod(pixelsToMove, 1)
		pixelsToMove := Floor(pixelsToMove)
		moveCursor(pixelsToMove * directionSum.x, pixelsToMove * directionSum.y)
	}

	cursorMoving := false
}

changeCursorSpeed(step) {
	global cursorSpeedIndex ;Set at top of the script
	global cursorSpeedOptions ;Set at top of the script
	global toolTipTimeout ;Set at top of the script
	cursorSpeedIndex := mathMod(cursorSpeedIndex + step, cursorSpeedOptions.MaxIndex())

	tmpToolTip("Cursor speed: " . getCursorSpeed() . "px / sec", toolTipTimeout)
}

getCursorSpeed() {
	global cursorSpeedIndex ;Set in changeCursorSpeed
	global cursorSpeedOptions ;Set at top of the script
	return cursorSpeedOptions[cursorSpeedIndex + 1]
}

mouseAction(keyToSend, triggerKey) {
	SendInput, {%keyToSend% down}
	while (GetKeyState(triggerKey, "P")) {
		Sleep, 50
	}
	SendInput, {%keyToSend% up}
}

mouseScroll(keyToSend, triggerKey) {
	while GetKeyState(triggerKey, "P"){
		SendInput, {%keyToSend%}
		Sleep, 100
	}
}

doubleClick() {
	SendInput, {LButton}
	Sleep, 100
	SendInput, {LButton}
}

tripleClick() {
	SendInput, {LButton}
	Sleep, 100
	SendInput, {LButton}
	Sleep, 100
	SendInput, {LButton}
}
