-- Honbun (本文) Visual Novel Engine
-- By: Radfordhound
local fonts = {}
FontsDirectory = "fonts/"

-- Functions
function AddFont(pth, size, name)
	if name == nil then
		name = pth
	end
	
	local font = love.graphics.newFont(FontsDirectory .. pth, size)
	fonts[name] = font
	return font
end

function AddBitmapFont(pth, name)
	if name == nil then
		name = pth
	end
	
	local font = love.graphics.newFont(FontsDirectory .. pth)
	fonts[name] = font
	return font
end

function ChangeFont(name)
	if fonts[name] == nil then
		error("Cannot change font to \"" .. name .. "\"; that font doesn't exist!")
	end
	
	love.graphics.setFont(fonts[name])
	return fonts[name]
end

function GetFont(name)
	return fonts[name]
end

function GetFontWidth(name, text)
	return fonts[name]:getWidth(text)
end

function GetFontHeight(name)
	return fonts[name]:getHeight()
end

function GetFontWrap(name, text, wrapLimit)
	return fonts[name]:getWrap(text, wrapLimit)
end