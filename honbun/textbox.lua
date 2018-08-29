-- Honbun (本文) Visual Novel Engine
-- By: Radfordhound

-- Variables
local currentLine, currentTypedLine, currentShownLine,
	currentName = nil, nil, nil, nil
local timer, fadeTimer, skipTimer, currentCharIndex,
	currentPos = 0, 0, 0, 0, 0
local x, y, ts, nameBoxW, o, w, h, a, sa, da, fs, ta,
	offset = 0, 0, 0.8, 0, 30, 0, 0, 1, 1, 1, 1, 1, 0

local font, nameFont = "Default", "Default"
local unpauseWhenDone, wereOptionsDisabled, couldProgress = false, false, true
local textBoxImg, nameBox = nil, nil
local shakeShader, shake, shakeMag, shakeMode, shakeMin,
	shakeMax, perChar, historyLimit, delayMulti = nil, false, 2, 0, 0, 2, false, 400, 1

TextBoxHidden = false
IsSkipping = false
History = {}

-- Functions
function AddTextTrigger(pos, action)
	if action == nil then
		return
	end

	local condition = function(self)
		return (self.storyPoint ~= nil and StoryPoint > self.storyPoint or
			(currentPos >= pos and StoryPoint == self.storyPoint))
	end

	local trig = AddTrigger(condition, action)
	trig.storyPoint = StoryPoint + 1
end

function ChangeLine(name, str, dm)
	-- Reset Variables
	currentTypedLine = ""
	currentShownLine = ""
	timer = 0
	skipTimer = 0
	currentCharIndex = 0
	currentPos = 0

	if dm ~= nil then
		delayMulti = dm
	else
		delayMulti = 1
	end

	-- Log to history
	if currentLine ~= nil and historyLimit > 0 then
		if #History >= historyLimit then
			table.remove(History, 1)
		end

		History[#History + 1] = { currentName, currentLine, font }
	end
	
	-- Set Current Name/Line
	if str == nil then
		currentName = nil
		if name == nil then
			currentLine = ""
		else
			currentLine = name
		end
	else
		currentName = name
		currentLine = str
	end
end

function SetHistoryLimit(limit)
	if limit <= 0 then
		historyLimit = 0
		History = {}
		return
	end

	historyLimit = limit
	while #History > limit do
		table.remove(History, 1)
	end
end

function GetHistoryLimit()
	return historyLimit
end

function ChangeTextBoxFont(f)
	font = f
end

function ChangeNameFont(f)
	nameFont = f
end

function ChangeTextBoxImage(img)
	textBoxImg = GetImageArg(img)
	if textBoxImg ~= nil then
		w = textBoxImg:getWidth()
		h = textBoxImg:getHeight()
	end
end

function ChangeNameBoxImage(img)
	nameBox = GetImageArg(img)
	if nameBox ~= nil then
		nameBoxW = nameBox:getWidth()
	end
end

function InitTextBox(honbunPath)
	UpdateTextBoxSize()
	InitOptions(x + (25 * ScaleX), y + (h - o * 1.4) * ScaleY)
	shakeShader = love.graphics.newShader(honbunPath .. "/shake.glsl")
end

function FadeTextBoxTo(destAlpha, fadeSpeed)
	if IsJumping() then
		SetTextBoxAlpha(destAlpha)
		return
	end

	if fadeSpeed == nil then
		fadeSpeed = 1
	end

	fadeTimer = 0
	sa = a
	da = destAlpha
	fs = fadeSpeed

	couldProgress = CanProgress
	wereOptionsDisabled = OptionsDisabled
	OptionsDisabled = true
	CanProgress = false

	if coroutine.running() ~= nil then
		unpauseWhenDone = true
		coroutine.yield()
	end
end

function GetTextBoxAlpha()
	return a
end

function SetTextBoxAlpha(alpha)
	a = alpha
	da = alpha
end

function GetTextAlpha()
	return ta
end

function SetTextAlpha(alpha)
	ta = alpha
end

function StartTextShaking()
	shake = true
end

function StopTextShaking()
	shake = false
end

function SetTextShakeMagnitude(mag, min, max)
	shakeMag = mag
	if shakeMode == 1 and min ~= nil and max ~= nil then
		shakeMin = min
		shakeMax = max
	else
		shakeMin = 0
		shakeMax = mag
	end
end

function SetTextShakeMode(mode, shakeEachChar)
	shakeMode = mode
	perChar = shakeEachChar
end

function UpdateTextBoxSize()
	x = CenterX - (w / 2) * ScaleX
	y = (ScreenHeight - h * ScaleY) - (o - offset) * ScaleY
end

function ResizeTextBox()
	UpdateTextBoxSize()
	PlaceOptions(x + (25 * ScaleX), y + (h - o * 1.4) * ScaleY)
	ResizeOptions()
end

function ChangeTextBoxVerticalOffset(verticalOffset)
	offset = verticalOffset
	ResizeTextBox()
end

function UpdateTextBox(dt)
	if currentLine ~= nil and currentTypedLine ~= nil then
		timer = timer + dt
		skipTimer = skipTimer + dt

		if a ~= da then
			fadeTimer = fadeTimer + dt
			a = Lerp(sa, da, fadeTimer * fs)

			if (da > sa and a >= da) or (sa > da and a <= da) then
				a = da
			end
		elseif unpauseWhenDone then
			unpauseWhenDone = false
			CanProgress = couldProgress
			OptionsDisabled = wereOptionsDisabled
			NextCommand()
		end

		if CanProgress and IsSkipping and skipTimer >= Settings.TextSkipDelay and
			GetChoicesCount() < 1 then
			NextCommand()
		end

		local d = (Settings.TextTypeDelay * delayMulti)
		if timer >= d and currentCharIndex < utf8.len(currentLine) then
			timer = 0
			currentCharIndex = currentCharIndex + 1
			
			local c = utf8.offset(currentLine, currentCharIndex)
			local c2 = utf8.offset(currentLine, currentCharIndex+1)
			currentPos = currentPos + (c2-c)
			currentTypedLine = currentTypedLine .. string.sub(currentLine, 
				c, currentPos)
			currentShownLine = currentTypedLine .. "    "
		end

		-- Shake
		if shakeMode == 1 then
			shakeMag = math.random(shakeMin, shakeMax)
		end
	end

	-- Options
	UpdateOptions()
end

function DrawTextBox()
	if textBoxImg == nil then
		return
	end

	if not TextBoxHidden and currentLine ~= nil and currentShownLine ~= nil then
		love.graphics.setColor(1, 1, 1, a)
		love.graphics.draw(textBoxImg, x, y, 0, ScaleX, ScaleY)
		
		-- Name
		local m, txtO = 25, 10
		ChangeFont(nameFont)

		if currentName ~= nil then
			txtO = 20
			DrawName(x, y, o, 15, 25)
		end

		-- Text
		txtO = txtO * (ScaleY * ts)
		ChangeFont(font)

		if shake and not perChar then
			love.graphics.setShader(shakeShader)
			shakeShader:send("offsetX", math.random(-shakeMag, shakeMag))
			shakeShader:send("offsetY", math.random(-shakeMag, shakeMag))
		end

		if not shake or not perChar then
			love.graphics.setColor(1, 1, 1, ta)
			love.graphics.printf(currentShownLine, x + (m * ScaleX),
				y + (m * ScaleY) + txtO, (w - m * 2) / ts, "left", 0,
				ScaleX * ts, ScaleY * ts)
		end

		if shake and perChar then
			love.graphics.setShader(shakeShader)
			shakeShader:send("offsetX", math.random(-shakeMag, shakeMag))
			shakeShader:send("offsetY", math.random(-shakeMag, shakeMag))

			local l = currentShownLine:len()
			love.graphics.setColor(1, 1, 1, ta)
			
			for i = 1, l do
				love.graphics.printf(currentShownLine:sub(i, i), x + (m * ScaleX),
					y + (m * ScaleY) + txtO, (w - m * 2) / ts, "left", 0,
					ScaleX * ts, ScaleY * ts)
			end
		end

		if shake then
			love.graphics.setShader()
		end
	end
	
	-- Options
	love.graphics.setColor(1, 1, 1, a)
	DrawOptions(w, o)
end

function DrawName(w, h, txtBxOffset, mx, my)
	if nameBox ~= nil then
		love.graphics.draw(nameBox, x + mx * ScaleX,
			y - my * ScaleY, 0, ScaleX, ScaleY)
	end

	love.graphics.printf(currentName, x + mx * ScaleX,
		y - (my * ScaleY) + (10 * (ts * ScaleY)), nameBoxW / ts,
		"center", 0, ts * ScaleX, ts * ScaleY)
end