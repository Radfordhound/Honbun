-- Honbun (本文) Visual Novel Engine
-- By: Radfordhound

-- Variables
local c = nil
local jumpingToPoint, arrivedMusic, arrivedBG,
	arrivedScrollBG, arrivedSetShouldBGScale = nil, nil, nil, nil, nil

local skip, isJumping, couldProgress, waiting = false, false, true, false
local currentSFX = nil
CurrentChapter = nil
StoryPoint = 0
ChoiceIndex = 0

-- Functions
function IsJumping()
	return isJumping
end

function ChangeChapter(chapter, startPoint, doStart)
	require("scripts." .. chapter)
	local chapterFunction = _G[chapter]
	
	if chapterFunction == nil then
		error("Chapter \"" .. chapter .. "\" has no function!")
	else
		-- Reset everything
		ChangeLine(nil, nil)
		StoryPoint = 0
		ChoiceIndex = 0
		CanProgress = true
		OptionsHidden = false
		OptionsDisabled = false
		Answers = {}
		History = {}
		SetNextBG(nil)
		ClearTriggers()
		ClearChoices()
		ClearImages()
		ClearAudio()
		StopCurrentSFX()

		isJumping = false
		jumpingToPoint = nil
		waiting = false

		ChangeTextBoxVerticalOffset(0)
		SetTextBoxAlpha(1)
		CurrentChapter = chapter

		if c ~= nil then
			c = nil
		end

		c = coroutine.create(chapterFunction)

		if startPoint ~= nil and startPoint ~= 0 then
			isJumping = true
			jumpingToPoint = startPoint
		end

		if doStart == nil or doStart then
			coroutine.resume(c)
		end
	end
end

function NextCommand()
	if c ~= nil then
		if waiting then
			waiting = false
			CanProgress = couldProgress
		end

		coroutine.resume(c)
	end
end

function JumpToPoint(point)
	if c ~= nil then
		isJumping = true
		jumpingToPoint = point
		coroutine.resume(c)
	end
end

function Pause(keepCurrentSFX)
	StoryPoint = StoryPoint + 1

	if not keepCurrentSFX then
		StopCurrentSFX()
	end

	if isJumping then
		if jumpingToPoint > StoryPoint then
			return
		elseif jumpingToPoint < StoryPoint then
			error("This should never happen lol") -- TODO?
			StoryPoint = jumpingToPoint
			return
		else
			isJumping = false
			jumpingToPoint = nil

			-- Arrived BG
			if arrivedBG ~= nil then
				if arrivedBG[5] then
					BG(arrivedBG[1], arrivedBG[2],
						arrivedBG[3], arrivedBG[4])
				else
					FadeInBG(arrivedBG[1], arrivedBG[4],
						arrivedBG[2], arrivedBG[3])
				end
				arrivedBG = nil
			end

			-- Arrived Scroll BG
			if arrivedScrollBG ~= nil then
				ScrollBG(arrivedScrollBG[1], arrivedScrollBG[2],
					arrivedScrollBG[3], arrivedScrollBG[4],
					arrivedScrollBG[5])
				arrivedScrollBG = nil
			end

			-- Arrived Set Should BG Scale
			if arrivedSetShouldBGScale ~= nil then
				SetShouldBGScale(arrivedSetShouldBGScale)
				arrivedSetShouldBGScale = nil
			end

			-- Arrived Music
			if arrivedMusic ~= nil then
				ChangeMusic(arrivedMusic[1],
					arrivedMusic[2], arrivedMusic[3])
				arrivedMusic = nil
			end
		end
	end

	coroutine.yield()
end

function StartAnimations(keepTextBox)
	if isJumping and jumpingToPoint ~= StoryPoint then
		skip = false
		Pause()
		return
	end

	skip = IsSkipping
	IsSkipping = false
	CanProgress = false

	if not keepTextBox then
		OptionsHidden = true
		SetTextBoxAlpha(0)
		ChangeLine()
	end

	Pause()
end

function FinishAnimations()
	IsSkipping = skip
	CanProgress = true
	OptionsHidden = false
	NextCommand()
end

function Wait(time)
	if time == nil or isJumping then
		return
	end

	WaitTime = time
	couldProgress = CanProgress
	CanProgress = false
	waiting = true
	coroutine.yield()
end

function Say(name, str, dm)
	ChangeLine(name, str, dm)
	Pause()
end

function Speak(name, str, pth)
	-- TODO: Make this function better
	local dm = 1
	if not jumpingToPoint and str ~= nil then
		StopCurrentSFX()
		currentSFX = LoadAudio(pth, "static")
		currentSFX:play()
		dm = (str:len() / (currentSFX:getDuration("seconds") * 2.5))
	end

	ChangeLine(name, str, dm)
	Pause(true)
end

function StopCurrentSFX()
	if currentSFX ~= nil then
		currentSFX:stop()
		currentSFX:release()
		currentSFX = nil
	end
end

function Ask(question, choices, name)
	if choices == nil then
		choices = { "Yes", "No" }
	end

	ChoiceIndex = ChoiceIndex + 1
	if isJumping and jumpingToPoint > StoryPoint + 1 then
		Pause()
		return Answers[ChoiceIndex]
	end

	CanProgress = false
	if name == nil then
		ChangeLine(question)
	else
		ChangeLine(name, question)
	end

	AddChoices(choices)
	Pause()
	
	-- We only get here once the coroutine is resumed from choices.lua
	ClearChoices()
	CanProgress = true
	return SelectedChoice
end

function BG(img, x, y, a)
	if isJumping then
		arrivedBG = { img, x, y, a, true }
		return nil
	end

	if img == nil then
		SetBG(nil)
		return nil
	else
		if x == nil then
			x = 0
		end
	
		if y == nil then
			y = 0
		end

		local bg = GenImage(img, nil, nil, a, nil,
			x, y, nil, nil, 0, 0, nil, nil, nil, 1)

		bg.scaleType = 2
		SetBG(bg)
		return bg
	end
end

function FadeInBG(img, fs, x, y)
	if img == nil then
		return nil
	end

	if isJumping then
		arrivedBG = { img, x, y, fs }
		return nil
	end

	if x == nil then
		x = 0
	end

	if y == nil then
		y = 0
	end

	local bg = GenImage(img, nil, nil, 0, fs,
		x, y, nil, nil, 0, 0, nil, nil, nil, 1)

	bg.scaleType = 2
	bg.destAlpha = 1
	SetBG(bg)
	return bg
end

function FadeOutBG(fs)
	if isJumping then
		arrivedBG = nil
		arrivedScrollBG = nil
		arrivedSetShouldBGScale = nil
		return
	end

	local bg = GetBG()
	if bg ~= nil then
		bg.fadeAway = true
		bg.fadeSpeed = fs
		bg.destAlpha = 0
	end
end

function ChangeBG(img, fs)
	if img == nil then
		return nil
	end

	if isJumping then
		arrivedBG = { img, x, y, fs }
		return nil
	end

	local bg = GetBG()
	if bg ~= nil then
		bg.fadeAway = true
		bg.fadeSpeed = fs
		bg.destAlpha = 0
	end

	bg = GenImage(img, nil, nil, 0, fs,
		x, y, nil, nil, 0, 0, nil, nil, nil, 1)

	bg.scaleType = 2
	bg.destAlpha = 1
	SetNextBG(bg)
	return bg
end

function ScrollBG(x, y, xEndPos, yEndPos, spd)
	if isJumping then
		arrivedScrollBG = { x, y, xEndPos, yEndPos, spd }
		return
	end

	local bg = GetBG()
	bg.x = x
	bg.y = y
	bg.endX = xEndPos
	bg.endY = yEndPos
	bg.scrollSpeed = spd
end

function LoadImage(pth)
	return love.graphics.newImage(ImagesDirectory .. pth)
end

function Show(img, alpha, anchorX, anchorY)
	if img == nil then
		return
	end
	
	return AddImage(img, anchorX, anchorY, alpha, 0)
end

function FadeIn(img, anchorX, anchorY, fadeSpeed)
	if img == nil then
		return
	end

	local img = AddImage(img, anchorX, anchorY, 0, fadeSpeed)
	img.destAlpha = 1
	return img
end

function Hide(index)
	RemoveImage(index)
end

function FadeOut(index, fadeSpeed)
	if isJumping then
		RemoveImage(index)
		return
	end

	local img = GetImage(index)
	if img ~= nil then
		img.fadeAway = true
		img.fadeSpeed = fadeSpeed
		img.destAlpha = 0
	end
end

function ChangeMusic(pth, fadeSpeed, maxVolume)
	if isJumping then
		arrivedMusic = { pth, fadeSpeed, maxVolume }
		return
	end

	if not fadeSpeed then
		fadeSpeed = 0.01
	end

	FadeOutMusic(fadeSpeed)
	local bgm = LoadAudio(pth, "stream")
	SetBGM(bgm, fadeSpeed, maxVolume)

	bgm:setLooping(true)
    bgm:setVolume(0)
    bgm:play()
	
	return bgm
end

function StopMusic()
	ClearAudio()
	arrivedMusic = nil
end

function FadeOutMusic(fadeSpeed)
	if isJumping then
		arrivedMusic = nil
		return
	end

	if not fadeSpeed then
		fadeSpeed = 0.01
	end

	local bgm = GetBGM()
	if bgm == nil then
		return
	end

	bgm.fadeSpeed = fadeSpeed
	bgm.fadeState = 1
end

function PlaySFX(pth, maxVolume)
	if jumpingToPoint then
		return
	end

	if maxVolume == nil then
		maxVolume = 1
	end

	local sfx = LoadAudio(pth, "static")
	sfx:setVolume(maxVolume)
	sfx:play()
end

function Animate(img, animPth, speed, onAnimFinish)
	if isJumping and jumpingToPoint ~= StoryPoint - 1 then
		if onAnimFinish ~= nil then
			onAnimFinish()
		end
		return
	end

	if speed == nil then
		speed = 1
	end

	img.keyframes = bitser.loadLoveFile(animPth)
	img.onAnimFinish = onAnimFinish
	StartAnimating(img, speed)
end