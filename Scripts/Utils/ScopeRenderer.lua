function ScopeRenderer_RenderScopeImage(gui, imagePath, imageWidth, imageHeight)
	local viewWidth, viewHeight = sm.jsonGui.getViewSize()
	local finalImageWidth = math.floor(viewHeight * (imageWidth / imageHeight))
	local finalImageHeight = viewHeight
	local finalImageOffset = (viewWidth - finalImageWidth) * 0.5

	local rootWidget = {
		Anchor = "Top Left",
		Childs = {
			{
				Anchor = "Top Left",
				Childs = {},
				Name = "ScopeImage",
				NeedKey = false,
				NeedMouse = false,
				ImageTexture = imagePath,
				Skin = "ImageBox",
				Type = "ImageBox",
				x = finalImageOffset,
				y = 0,
				width = finalImageWidth,
				height = finalImageHeight
			}
		},
		Name = "BackPanel",
		NeedKey = false,
		NeedMouse = false,
		Skin = "PanelEmpty",
		Type = "Widget",
		width = viewWidth,
		height = viewHeight,
		x = 0,
		y = 0
	}

	if finalImageOffset > 0 then
		table.insert(rootWidget.Childs, {
			Anchor = "Top Left",
			Childs = {},
			Name = "ScopeImageLeftBar",
			NeedKey = false,
			NeedMouse = false,
			Skin = "WhiteSkin",
			Type = "Widget",
			Colour = "0 0 0 1",
			x = 0,
			y = 0,
			width = finalImageOffset,
			height = viewHeight
		})

		table.insert(rootWidget.Childs, {
			Anchor = "Top Left",
			Childs = {},
			Name = "ScopeImageRightBar",
			NeedKey = false,
			NeedMouse = false,
			Skin = "WhiteSkin",
			Type = "Widget",
			Colour = "0 0 0 1",
			x = finalImageOffset + finalImageWidth,
			y = 0,
			width = finalImageOffset,
			height = viewHeight
		})
	end

	gui:render(rootWidget)
end