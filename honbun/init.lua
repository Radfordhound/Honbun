-- Honbun (本文) Visual Novel Engine
-- By: Radfordhound

-- The name of the directory which contains this file
local dir = (...):gsub('%init$', '')
local path = dir .. "."
utf8 = require("utf8")
require(path .. "helpers")
require(path .. "settings")
require(path .. "shaders")
require(path .. "fonts")
require(path .. "images")
require(path .. "states")
require(path .. "options")
require(path .. "textbox")
require(path .. "choices")
require(path .. "audio")
bitser = require(path .. "bitser")
require(path .. "animationEditor")
require(path .. "commands")
require(path .. "characters")
require(path .. "triggers")
require(path .. "userData")
require(path .. "splash")
path = nil

-- Variables
TargetWidth, TargetHeight = 1280, 720
ScreenWidth, ScreenHeight, ScaleX, ScaleY,
	CenterX, CenterY = 0, 0, 1, 1, 0, 0
WaitTime = 0
DebugEnabled, DebugUIVisible = false, false

local debugChapters = {}
local version = 1.0
local currentState = nil
local fading, fadeSpeed, destAlpha, fadeAlpha = false, 0.01, 1, 0
local debugChapterIndex = 1
local debugMenu = false

RunningOnMobile = false
CanProgress = true
InFullscreen = false

-- Functions
function EnableDebug()
	DebugEnabled = true
end

function ChangeCurrentState(state, ...)
	currentState = state
	InitState(state, {...})
	StartState(state)
end

function FinishCurrentState()
	local state = currentState
	currentState = nil

	FinishState(state)
end

local function FadeScreen(speed)
	fading = true
	if speed == nil then
		fadeSpeed = 0.01
	else
		fadeSpeed = speed
	end
end

local function ResizeScreen(w, h)
	ScreenWidth = w
	ScreenHeight = h
	ScaleX = ScreenWidth / TargetWidth
	ScaleY = ScreenHeight / TargetHeight
	CenterX = ScreenWidth / 2
	CenterY = ScreenHeight / 2
	print("screen resized: " .. tostring(w) .. " x " .. tostring(h))
end

function FadeScreenIn(speed)
	destAlpha = 0
	fadeAlpha = 1
	FadeScreen(speed)
end

function FadeScreenOut(speed)
	destAlpha = 1
	fadeAlpha = 0
	FadeScreen(speed)
end

local function DebugDraw()
	if not DebugUIVisible then
		return
	end

	-- Setup Debug Drawing
	local mode = nil
	if debugMenu then
		mode = "Debug Menu"
	elseif AnimEditor then
		mode = "Animation Editor"
	else
		mode = "MISSINGNO" -- (sorry)
	end

	ChangeFont("DebugFont")
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("Honbun (本文) v" .. tostring(version) ..
		" (" .. mode .. ")", 4, 4)

	local bgmText = nil
	if Settings.MusicVolume <= 0 then
		bgmText = " (MUTED)"
	else
		bgmText = " (VOLUME: " .. tostring(Settings.MusicVolume) .. ")"
	end

	love.graphics.print(
		"F2: Debug Menu, F3: Animation Editor, F5: BGM Toggle" ..
		bgmText, 4, 25)

	-- Debug Menu
	if debugMenu then
		local y = 70
		love.graphics.print("StoryPoint: " .. StoryPoint .. ", FPS: " ..
			tostring(love.timer.getFPS()), 4, 50)
		
		for i, chapter in ipairs(debugChapters) do
			if i == debugChapterIndex then
				local fnt = love.graphics.getFont()
				love.graphics.setColor(0, 0.5804, 1, 0.9412)
				love.graphics.rectangle("fill", 20, y - 5,
					fnt:getWidth(chapter) + 10, fnt:getHeight(chapter) + 10)
				
				love.graphics.setColor(1, 1, 1)
			end

			love.graphics.print(chapter, 25, y)
			y = y + 20
		end

	-- Animation Editor
	elseif AnimEditor then
		DrawAnimationEditor()
	end
end

-- LÖVE Events
function love.load()
	ResizeScreen(love.graphics.getWidth(),
		love.graphics.getHeight())
	InitTextBox(dir)
	dir = nil

	local os = love.system.getOS()
	RunningOnMobile = (os == "Android" or os == "iOS")
	InFullscreen = love.window.getFullscreen()
	
	if RunningOnMobile then
		ChangeChoicesFont("Default")
	end
	
	if OnGameLoad ~= nil then
		OnGameLoad()
	end
end

function love.resize(w, h)
	ResizeScreen(w, h)
	ResizeTextBox()
	RefreshChoices()

	-- States
	if currentState ~= nil then
		if currentState.Resize ~= nil then
			currentState:Resize()
		end
		return
	end
end

function love.keypressed(key, scanCode, isRepeat)
	-- Fullscreen Toggle
	if key == "f11" then
		InFullscreen = not InFullscreen
		love.window.setFullscreen(InFullscreen, "desktop")
	end

	-- Debug
	if DebugEnabled then
		if key == "escape" then
			if DebugUIVisible then
				DebugUIVisible = false
			else
				love.event.quit()
			end
		elseif key == "f2" then
			if AnimEditor then
				DebugUIVisible = true
			else
				DebugUIVisible = not DebugUIVisible
			end

			debugMenu = DebugUIVisible
			AnimEditor = false

			if DebugUIVisible then
				debugMenu = true
				debugChapters = {}
				debugChapterIndex = 1
	
				local chapters = love.filesystem.getDirectoryItems("scripts")
				for i, chapter in ipairs(chapters) do
					debugChapters[#debugChapters + 1] = chapter
				end
			end
		elseif key == "f3" then
			if debugMenu then
				DebugUIVisible = true
			else
				DebugUIVisible = not DebugUIVisible
			end

			debugMenu = false
			AnimEditor = DebugUIVisible
		end
	end

	-- Debug UI
	if DebugUIVisible then
		-- BGM Toggle
		if key == "f5" then
			if Settings.MusicVolume == 0 then
				Settings.MusicVolume = 0.5
			else
				Settings.MusicVolume = 0
			end
		end

		-- Debug Menu
		if debugMenu then
			-- Chapter Switch
			if key == "up" and debugChapterIndex > 1 then
				debugChapterIndex = debugChapterIndex - 1
			elseif key == "down" and debugChapterIndex < #debugChapters then
				debugChapterIndex = debugChapterIndex + 1
			end

			if key == "return" then
				if currentState ~= nil then
					FinishCurrentState()
				end

				love.graphics.setBackgroundColor(0, 0, 0)
				ChangeChapter(string.sub(debugChapters[debugChapterIndex], 1, -5))
				DebugUIVisible = false
				return
			end
		end

		-- Animation Editor
		if AnimEditor then
			KeyPressedAnimationEditor(key)
		end
	end

	-- States
	if fading then
		return
	end

	if currentState ~= nil then
		if currentState.KeyPressed ~= nil then
			currentState:KeyPressed(key, scanCode, isRepeat)
		end
		return
	end

	-- Text Box
	if not IsSkipping and CanProgress then
		if key == "space" or key == "return" then
			NextCommand()
		end
	end
end

function love.mousepressed(x, y, button, isTouch)
	-- Animation Editor
	if DebugUIVisible and AnimEditor then
		MousePressedImages(x, y, button)
	end

	-- States
	if fading then
		return
	end

	if currentState ~= nil then
		if currentState.MousePressed ~= nil then
			currentState:MousePressed(x, y, button, isTouch)
		end
		return
	end

	if not MousePressedOptions(x, y, button, isTouch) and
	   not isTouch and not IsSkipping and CanProgress and not DebugUIVisible then
		NextCommand()
	end

	if not isTouch then
		MousePressedChoices(x, y, button)
	end
end

-- TODO: Make touch stuff work better on touch screen laptops

function love.touchpressed(id, x, y, dx, dy, pressure)
	-- States
	if fading then
		return
	end

	if currentState ~= nil then
		if currentState.TouchPressed ~= nil then
			currentState:TouchPressed(id, x, y, dx, dy, pressure)
		end
		return
	end

	if not TouchPressedOptions(id, x, y) and not IsSkipping
	   and CanProgress then
		NextCommand()
	end

	TouchPressedChoices(id, x, y)
end

function love.touchreleased(id, x, y, dx, dy, pressure)
	TouchReleasedOptions(id)
end

function love.textinput(text)
	if AnimEditor then
		TypingAnimationEditor(text)
	end
end

function love.wheelmoved(x, y)
	if AnimEditor then
		MouseWheelAnimationEditor(x, y)
	end
end

function love.update(dt)
	-- Images
	UpdateImages(dt)

	-- Text Box
	UpdateTextBox(dt)

	-- Audio
	UpdateAudio()

	-- States
	if fading then
		if destAlpha == 1 then
			fadeAlpha = fadeAlpha + fadeSpeed
			if fadeAlpha >= 1 then
				fadeAlpha = 1
				fading = false
			end
		else
			fadeAlpha = fadeAlpha - fadeSpeed
			if fadeAlpha <= 0 then
				fadeAlpha = 0
				fading = false
			end
		end
		return
	end

	if currentState ~= nil then
		if currentState.Update ~= nil then
			currentState:Update(dt)
		end
		return
	end

	-- Triggers
	UpdateTriggers()

	if WaitTime > 0 then
		WaitTime = WaitTime - dt
		if WaitTime <= 0 then
			NextCommand()
		end
	end

	-- Debug
	if AnimEditor then
		UpdateAnimationEditor()
	end
end

function love.draw()
	-- States
	if currentState ~= nil then
		if currentState.Draw ~= nil then
			currentState:Draw()
		end

		if not fading then
			DebugDraw()
			return
		end
	end

	-- Images
	DrawImages()

	-- Text Box
	DrawTextBox()
	
	-- Choices
	DrawChoices()

	-- Fading
	if fading then
		love.graphics.setColor(0, 0, 0, fadeAlpha)
		love.graphics.rectangle("fill", 0, 0, ScreenWidth, ScreenHeight)
	end

	-- Debug
	DebugDraw()
end