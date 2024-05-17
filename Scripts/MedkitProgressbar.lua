MedkitProgressbar = class()

function MedkitProgressbar:init(frames)
    self.maxFrameCount = frames
    self.gui = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/Layouts/MedkitProgressbar.layout", false,
        {
            isHud = true,
            isInteractive = false,
            needsCursor = false,
            hidesHotbar = false,
            isOverlapped = false,
            backgroundAlpha = 0
        }
    )
    self.gui:setColor("overlay", sm.color.new("#00ff00"))
    self:setHudFrame(0)

    return self
end

function MedkitProgressbar:update(progress)
    self:setHudFrame(round(self.maxFrameCount*progress))
end

function MedkitProgressbar:setHudFrame(frame)
    self.gui:setImage("overlay", ("$CONTENT_DATA/Gui/MedkitProgressbarImages/%s.png"):format(frame%self.maxFrameCount))
end



function MedkitProgressbar:open()
    self.gui:open()
end

function MedkitProgressbar:close()
    self.gui:close()
end

function MedkitProgressbar:destroy()
    self.gui:destroy()
end

function MedkitProgressbar:isActive()
    return self.gui:isActive()
end