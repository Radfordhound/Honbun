-- Honbun (本文) Visual Novel Engine
-- By: Radfordhound

-- Variables
local choices = {}
local font = "DefaultSmall"
local ys = {}
local w, h, s, txtOffset = 10, 30, 7, 1 -- TODO: Remove s if you decide not to use it

Answers = {}
SelectedChoice = nil
ChoicesEnabled = true

-- Functions
function ClearChoices()
	choices = {}
	RefreshChoices()
end

function AddChoice(choice)
	table.insert(choices, choice)
	RefreshChoices()
end

function AddChoices(c)
	choices = c
	RefreshChoices()
end

function ChangeChoicesFont(f)
	font = f
	RefreshChoices()
end

function GetChoicesCount()
	if choices == nil then
		return 0
	else
		return #choices
	end
end

function RefreshChoices()
	local wm, hm, hs = 2.5, 5, 40
	if RunningOnMobile then
		wm = 1.8
		hm = 10
		hs = 70
		s = 1
	else
		s = 1
	end

	w = ScreenWidth / wm
	h = hs * ScaleY
	txtOffset = (h / 2) - (GetFontHeight(font) / 2)

	local hp = h + hm
	local y = ((ScreenHeight - (h * (#choices - 1))) / 2) -
		(((hp * #choices) - hm) / 2)
	
	-- Compute positions for choices
	ys = {}

	for i, choice in ipairs(choices) do
		table.insert(ys, y)
		y = y + hp
	end
end

function DrawChoices()
	if ChoicesEnabled and choices ~= nil and #choices > 0 then
		local x = (ScreenWidth - w) / 2
		ChangeFont(font)

		for i, choice in ipairs(choices) do
			-- Choice Box
			love.graphics.setColor(0.2274, 0.5333, 0.9882, 0.8235)
			love.graphics.rectangle("fill", x, ys[i], w, h, 4, 4)
			
			-- Choice Text
			love.graphics.setColor(1, 1, 1)
			love.graphics.printf(choice, x, ys[i] + (txtOffset / (ScaleY * s)),
				w / (ScaleX * s), "center", 0, ScaleX * s, ScaleY * s)
		end
	end
end

function MousePressedChoices(x, y, button)
	if not ChoicesEnabled then
		return
	end

	local xPos = ((ScreenWidth - w) / 2)
	for i, choice in ipairs(ys) do
		local yPos = ys[i]
		if x >= xPos and x <= xPos + w and y >= yPos and y <= yPos + h then
			SelectedChoice = choices[i]
			Answers[#Answers + 1] = SelectedChoice
			NextCommand()
			return
		end
	end
end

function TouchPressedChoices(id, x, y)
	if not ChoicesEnabled then
		return
	end

	local xPos = ((ScreenWidth - w) / 2)
	for i, choice in ipairs(ys) do
		local yPos = ys[i]
		if x >= xPos and x <= xPos + w and y >= yPos and y <= yPos + h then
			SelectedChoice = choices[i]
			Answers[#Answers + 1] = SelectedChoice
			NextCommand()
			-- TODO: Highlight now, only activate on release
			return
		end
	end
end