-- Honbun (本文) Visual Novel Engine
-- By: Radfordhound

-- Variables
local characters = {}

-- Functions
function AddCharacter(shortName, longName)
	if shortName == nil then
		return
	end
	
	-- Setup Character
	ch =
	{
		costumes = {},
		currentCostume = nil,
		currentImage = nil,
		anchorX = nil,
		anchorY = nil,
		id = #characters + 1
	}

	-- Set Name
	if longName ~= nil then
		ch.name = longName
	else
		ch.name = shortName
	end
	
	-- Setup Functions
	function ch:GetCostume(name)
		self.costumes[name] = GetImageArg(self.costumes[name])
		return self.costumes[name]
	end

	function ch:AddCostume(name, pth, loadNow)
		if loadNow == nil or not loadNow then
			self.costumes[name] = pth
		else
			self.costumes[name] = LoadImage(pth)
		end
	end

	function ch:RemoveCostume(name)
		if self.currentImage ~= nil and self.currentImage.image == self.costumes[name] then
			RemoveImage(self.currentImage.index)
			self.currentImage = nil
		end

		self.costumes[name] = nil
	end
	
	function ch:ChangeCostume(name)
		self:Hide()
		self:Show(name, self.anchorX, self.anchorY)
	end

	function ch:Show(costume, anchorX, anchorY, alpha)
		if costume == nil then
			costume = self.currentCostume
		else
			self.currentCostume = costume
		end

		self.anchorX = anchorX
		self.anchorY = anchorY

		local costumeImage = self:GetCostume(costume)
		self.currentImage = AddImage(costumeImage,
			anchorX, anchorY, alpha, 0)
		
		return self.currentImage
	end

	function ch:Hide()
		if self.currentImage == nil then
			return
		end

		self.currentImage.release = false
		RemoveImage(self.currentImage.index)
		self.currentImage = nil
	end

	function ch:FadeIn(costume, anchorX, anchorY, fadeSpeed)
		if costume == nil then
			costume = self.currentCostume
		else
			self.currentCostume = costume
		end

		self.anchorX = anchorX
		self.anchorY = anchorY
	
		local costumeImage = self:GetCostume(costume)
		self.currentImage = AddImage(costumeImage,
			anchorX, anchorY, 0, fadeSpeed)

		if self.currentImage then
			self.currentImage.destAlpha = 1
		end
		
		return self.currentImage
	end
	
	function ch:FadeOut(fadeSpeed)
		if self.currentImage == nil then
			return
		end
	
		self.currentImage.release = false

		if IsJumping() then
			RemoveImage(self.currentImage.index)
		else
			self.currentImage.fadeAway = true
			self.currentImage.fadeSpeed = fadeSpeed
			self.currentImage.destAlpha = 0
		end

		self.currentImage = nil
	end

	function ch:Say(str, dm)
		ChangeLine(self.name, str, dm)
		Pause()
	end

	function ch:SayFast(str)
		ChangeLine(self.name, str, 0.5)
		Pause()
	end

	function ch:Remove()
		self:Hide()
		characters[self.id] = nil
		self = nil
	end

	characters[ch.id] = ch
	return ch
end