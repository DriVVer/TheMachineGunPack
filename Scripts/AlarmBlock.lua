AlarmBlock = class(nil)
AlarmBlock.connectionInput =  sm.interactable.connectionType.none
AlarmBlock.connectionOutput = sm.interactable.connectionType.none

AlarmBlock.MessageTable = {
    ["561b2e83-4e9b-462f-ae97-645dc596b2c4"] = "Component Destroyed!",
    ["b40dbc55-65f3-40ae-be5e-4d8976c7d970"] = "Lost control! Press E to parachute!",
    ["27839ef0-bc1e-4fed-a715-7adb9c9701b1"] = "Target Destroyed!"
}

function AlarmBlock:client_onCreate()
    self.alarming = false
    self.text = self.MessageTable[tostring(self.shape.uuid)]
end

function AlarmBlock:client_onInteract(character, state)
    if state then
        self.alarming = not self.alarming
        local _text = (self.alarming and "Alarming when destroyed!" or "Not alarming when destroyed!")
        local _UvIndex = (self.alarming and 6 or 0)
        self.interactable:setUvFrameIndex(_UvIndex)
        sm.gui.displayAlertText(_text, 5)
    end
end

function AlarmBlock:server_onProjectile()
    self.shape:destroyShape(0)
end

function AlarmBlock:server_onSledgehammer()
    self.shape:destroyShape(0)
end

function AlarmBlock:client_onDestroy()
    if self.alarming then
        sm.gui.displayAlertText("#ff0000"..self.text)
    end
end