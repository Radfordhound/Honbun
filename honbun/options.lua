-- Honbun (本文) Visual Novel Engine
-- By: Radfordhound

-- Variables
local options = {}
local optionsTex, highlightedTex = nil, nil
local optionsSB, optionsHighlightSB = nil, nil
local optionsY, s = 0, 1
local touchID = nil
OptionsHidden, OptionsDisabled = false, false
OptionsDirectory = "options/"

-- Functions
-- SetupOptions(tex, highlightTex, [width], [height], [options])
function SetupOptions(tex, highlightTex, ...)
	-- Normal Texture
	optionsTex = GetImageArg(tex)
	if optionsTex == nil then
		error("Cannot Setup Options; a valid texture must be given.")
	end

	-- Highlighted Texture
	if highlightTex == nil then
		highlightedTex = optionsTex
	else
		highlightedTex = GetImageArg(highlightTex)
	end

	-- Options
	if ... == nil then
		return
	end

	local args = {...}
	local sw, sh = optionsTex:getWidth(), optionsTex:getHeight()
	local x, y, width, height, w, h = 0, 0, 0, sh, 0, 0
	local index, option = 1, nil

	-- Get Width/Height
	if type(args[1]) == "number" then
		width = args[1]
		if type(args[2]) == "number" then
			height = args[2]
			index = 3
		else
			index = 2
		end
	else
		width = (sw / #args)
	end

	-- Generate Options
	for i = index, #args do
		option = args[i]
		w = width
		h = height

		-- Path to .lua file
		if type(option) == "string" then
			option = GenOption(x, y, w, h, sw, sh, option)
		
		-- Table
		elseif type(option) == "table" then
			-- If table contains a state, assume it was made by GenOption.
			-- Otherwise, we expect a table with this layout ([] means optional):
			-- { luaPath, [width], [height], [args] }
			if option.state == nil then
				if #option >= 1 and type(option[1]) == "string" then
					if #option >= 2 and type(option[2]) == "number" then
						w = option[2]
					end

					if #option >= 3 and type(option[3]) == "number" then
						h = option[3]
					end

					if #option > 1 and type(option[#option]) ~= "number" then
						option = GenOption(x, y, w, h, sw, sh,
							option[1], unpack(option[#option]))
					else
						option = GenOption(x, y, w, h, sw, sh, option[1])
					end
				else
					error("Option #" .. tostring(i - (index - 1)) .. " is invalid!")
				end
			end

		-- Invalid Option
		else
			error("Option #" .. tostring(i - (index - 1)) .. " is invalid!")
		end

		x = x + w
		if x >= sw then
			x = 0
			y = y + h
		end

		options[#options + 1] = option
	end
end

function GenOption(x, y, width, height, sw, sh, state, ...)
	if not state then
		error("Cannot generate option; invalid state!")
	elseif type(state) == "string" then
		print(state)
		state = require(OptionsDirectory .. state)
	end

	InitState(state, {...})

	print(height)

	return {
		rect = love.graphics.newQuad(x, y, width, height, sw, sh),
		x = ScreenWidth,
		initialWidth = width,
		initialHeight = height,
		width = width,
		height = height,
		isHighlighted = false,
		state = state
	}
end

function AddOption(x, y, width, height, sw, sh, state, ...)
	local option = GenOption(x, y, width, height, sw, sh, state, ...)
	options[#options + 1] = option
	return option
end

function GetOption(i)
    if i <= #options then
        return options[i]
    end
    return nil
end

function InitOptions(x, y)
	optionsSB = love.graphics.newSpriteBatch(optionsTex, #options)
	optionsSBH = love.graphics.newSpriteBatch(highlightedTex, #options)

	PlaceOptions(x, y)
	optionsSB:flush()
end

function ClearOptions()
	optionsSB:clear()
	optionsSBH:clear()
end

function PlaceOptions(x, y)
	if optionsSB == nil then
		return
	end

	local sc = 0.5
	optionsY = y
	ClearOptions()

	if RunningOnMobile then
		sc = 0.65
	end

	s = (ScreenWidth * sc) / TargetWidth

	local m = nil
	if RunningOnMobile then
		m = (50 * s)
	else
		m = (25 * s)
	end

	for i, option in pairs(options) do
		option.x = x
		option.y = optionsY

		option.width = option.initialWidth * s
		option.height = option.initialHeight * s

		optionsSB:add(option.rect, x, optionsY, 0, s, s)
		x = x + option.width + m
	end
end

function ResizeOptions()
    for i, option in pairs(options) do
        if option.state.active and option.state.Resize ~= nil then
            option.state:Resize()
        end
    end
end

local function UpdateHighlighted(x, y)
	-- Compute whether each option is being hovered over
	local doUpdateSBs = false
	local vertHover = (y >= optionsY)
	
	for i, option in pairs(options) do
		if vertHover and y <= optionsY + option.height and
		   x >= option.x and x <= option.x + option.width then
			if not option.isHighlighted then
				doUpdateSBs = true
			end

			option.isHighlighted = true
		else
			if option.isHighlighted then
				doUpdateSBs = true
			end

			option.isHighlighted = false
		end
	end

	return doUpdateSBs
end

local function UpdateOptionsSB()
	ClearOptions()

	for i, option in pairs(options) do
		if option.isHighlighted then
			optionsSBH:add(option.rect, option.x, optionsY, 0, s, s)
		else
			optionsSB:add(option.rect, option.x, optionsY, 0, s, s)
		end
	end
end

function UpdateOptions(dt)
	if OptionsHidden then
		return
	end

	-- Update Options
    for i, option in pairs(options) do
        if option.state.active and option.state.Update ~= nil then
            option.state:Update(dt)
        end
	end
	
	if OptionsDisabled or RunningOnMobile then
		return
	end

	-- Update the Options SpriteBatch if necessary
	local x, y = love.mouse.getPosition()
	if UpdateHighlighted(x, y) then
		UpdateOptionsSB()
	end
end

function DrawOptions(txtBxW, txtBxOffset)
	if OptionsHidden then
		return
	end

    -- Draw Options
    for i, option in pairs(options) do
        if option.state.active and option.state.Draw ~= nil then
            option.state:Draw()
        end
    end

	love.graphics.draw(optionsSB)
	love.graphics.draw(optionsSBH)
end

function MousePressedOptions(x, y, button, isTouch)
	if OptionsHidden then
		return false
	end

	for i, option in pairs(options) do
        if option.state.active and option.state.MousePressed ~= nil then
            option.state:MousePressed(x, y, button, isTouch)
        end
	end
	
	if OptionsDisabled or RunningOnMobile or
	   button ~= 1 or y < optionsY then
		return false
	end

	for i, option in pairs(options) do
		if y <= optionsY + option.height and x >= option.x and
		   x <= option.x + option.width then
			StartState(option.state)
			return true
		end
	end

	return false
end

function TouchPressedOptions(id, x, y)
	if OptionsHidden or OptionsDisabled then
		return false
	end

	local my = 20 * ScaleY
	if y < optionsY - my then
		return false
	end

	local mx, didTouch = (20 * ScaleX), false
	touchID = id

	for i, option in pairs(options) do
		option.isHighlighted = (y <= optionsY + option.height + my and
			x >= option.x - mx and x <= option.x + option.width + mx)

		if option.isHighlighted then
			didTouch = true
		end
	end

	UpdateOptionsSB()
	return didTouch
end

function TouchReleasedOptions(id)
	if OptionsHidden or OptionsDisabled then
		return
	end

	for i, option in pairs(options) do
		if option.isHighlighted and id == touchID then
			StartState(option.state)
		end

		option.isHighlighted = false
	end

	UpdateOptionsSB()
end