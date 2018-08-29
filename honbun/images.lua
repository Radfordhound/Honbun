-- Honbun (本文) Visual Novel Engine
-- By: Radfordhound

-- Variables
local sx, sy = 0.9, 0.9
local nextBG = nil
local images =
{
	-- Background
	{
		image = nil
	}
}

ImagesDirectory = "images/"

-- Functions
function AddImage(img, anchorX, anchorY, a, fs,
	xPos, yPos, w, h, ox, oy, xEndPos, yEndPos, ss)

	local image = GenImage(img, anchorX, anchorY, a, fs,
		xPos, yPos, w, h, ox, oy, xEndPos, yEndPos, ss)

	images[image.index] = image
	return image
end

function GenImage(img, anchorX, anchorY, a, fs,
	xPos, yPos, w, h, ox, oy, xEndPos, yEndPos, ss, i)

	if img == nil then
		return nil
	else
		img = GetImageArg(img)
	end

	if a == nil then
		a = 1
	end

	if xPos == nil then
		xPos = 0
	end

	if yPos == nil then
		yPos = 0
	end

	if w == nil then
		w = img:getWidth()
	end
	
	if h == nil then
		h = img:getHeight()
	end

	if ox == nil then
		ox = w / 2
	end
	
	if oy == nil then
		oy = h / 2
	end

	if i == nil then
		i = #images + 1
	end
	
	return {
		image = img,
		anchorX = anchorX,
		anchorY = anchorY,
		alpha = a,
		fadeSpeed = fs,
		x = xPos,
		y = yPos,
		width = w,
		height = h,
		ox = ox,
		oy = oy,
		endX = xEndPos,
		endY = yEndPos,
		scrollSpeed = ss,
		index = i,
		r = 0,
		sx = 1,
		sy = 1,
	}
end

function SetBG(img)
	if img == nil then
		images[1] = { image = nil }
	else
		images[1] = img
	end
end

function SetNextBG(img)
	if img == nil then
		nextBG = { image = nil }
	else
		nextBG = img
	end
end

function GetBG(img)
	return images[1]
end

function RemoveImage(index)
	if #images < 1 then
		return
	end

	if #images == 1 then
		index = 1
	elseif index == nil then
		index = #images
	end

	local img = images[index]
	if img ~= nil and (img.release == nil or img.release) then
		img.image:release()
	end

	if index == 1 then
		images[1] = { image = nil }
		return
	end

	if SelectedImage == img then
		SelectedImage = nil
	end
	
	img = nil
	table.remove(images, index)

	-- Update Image Indices
	for i, image in ipairs(images) do
		image.index = i
	end
end

function ClearImages(keepBackground)
	if keepBackground then
		local back = images[1]
		images = { back }
	else
		images =
		{
			-- Background
			{
				image = nil
			}
		}
	end
end

function GetImage(index)
	if index ~= nil then
		return images[index]
	else
		return images[#images]
	end
end

function GetImageCount()
	return #images
end

function Lerp(s, d, t)
	return (1 - t) * s + t * d;
end

function LerpCapped(s, d, t)
	local v = Lerp(s, d, t)
	if (d > s and v >= d) or (s > d and v <= d) then
		v = d
	end

	return v
end

local function AnimateFrame(v, v2, info, image, dt)
	info.animTime = info.animTime + dt
	if info.animTime * image.animSpeed >= 1 then
		info.animTime = 0
		info.frameIndex = info.frameIndex + 1
		return v2
	else
		v = Lerp(v, v2, info.animTime * image.animSpeed)
	end
	return v
end

local function GetFrm(info, image)
	return info, image.keyframes[info.frameIndex],
		image.keyframes[info.frameIndex + 1]
end

function UpdateImages(dt)
	-- While loop instead of for loop so we can change table size
	local i, img = 1, nil
	while i <= #images do
		img = images[i]
		if img ~= nil and img.image ~= nil then
			if (img.endX ~= nil and img.x ~= img.endX) or
			   (img.endY ~= nil and img.y ~= img.endY) then
				if img.scrollTimer == nil then
					img.scrollTimer = 0
				end

				if img.startX == nil then
					img.startX = img.x
				end

				if img.startY == nil then
					img.startY = img.y
				end

				local scrollSpeed = img.scrollSpeed
				if scrollSpeed == nil then
					scrollSpeed = 2
				end

				img.scrollTimer = img.scrollTimer + dt
				if img.endX then
					img.x = LerpCapped(img.startX, img.endX,
						img.scrollTimer * scrollSpeed)
				end

				if img.endY then
					img.y = LerpCapped(img.startY, img.endY,
						img.scrollTimer * scrollSpeed)
				end

				--[[if img.timer >= scrollDelay then
					if img.x < img.endX then
						img.x = img.x + scrollSpeed
					elseif img.x > img.endX then
						img.x = img.x - scrollSpeed
					end

					if img.y < img.endY then
						img.y = img.y + scrollSpeed
					elseif img.y > img.endY then
						img.y = img.y - scrollSpeed
					end

					img.timer = 0
				end--]]
			elseif i > 1 then
				if img.animating and img.animSpeed ~= nil then
					-- Lerp Position
					local v = 0
					if img.XInfo.frameIndex < #img.keyframes then
						local info, frm, nFrm = GetFrm(img.XInfo, img)
						img.x = AnimateFrame(frm.x, nFrm.x, info, img, dt) * ScaleX
					else
						v = v + 1
					end

					if img.YInfo.frameIndex < #img.keyframes then
						local info, frm, nFrm = GetFrm(img.YInfo, img)
						img.y = AnimateFrame(frm.y, nFrm.y, info, img, dt) * ScaleY
					else
						v = v + 1
					end

					-- Lerp Rotation
					if img.RInfo.frameIndex < #img.keyframes then
						local info, frm, nFrm = GetFrm(img.RInfo, img)
						img.r = AnimateFrame(frm.r, nFrm.r, info, img, dt)
					else
						v = v + 1
					end

					-- Lerp ScaleX/Y
					if img.SXInfo.frameIndex < #img.keyframes then
						local info, frm, nFrm = GetFrm(img.SXInfo, img)
						img.sx = AnimateFrame(frm.sx, nFrm.sx, info, img, dt)
					else
						v = v + 1
					end

					if img.SYInfo.frameIndex < #img.keyframes then
						local info, frm, nFrm = GetFrm(img.SYInfo, img)
						img.sy = AnimateFrame(frm.sy, nFrm.sy, info, img, dt)
					else
						v = v + 1
					end

					-- Go to Next Frame
					if v >= 5 then
						if AnimEditor then
							UpdateImagePos(img)
						end

						img.animating = false
						if img.onAnimFinish ~= nil then
							img.onAnimFinish()
						end
					end
				end
			end

			-- Fade Image
			if img.destAlpha ~= nil and img.alpha ~= img.destAlpha then
				-- Get Fade Speed
				local fs = img.fadeSpeed
				if fs == nil then
					if i == i then
						fs = 2
					else
						fs = 4
					end
				end

				-- Lerp Alpha
				if img.fadeTimer == nil then
					img.fadeTimer = 0
				end

				if img.sourceAlpha == nil then
					img.sourceAlpha = img.alpha
					img.fadeTimer = 0
				end

				img.fadeTimer = img.fadeTimer + dt
				img.alpha = LerpCapped(img.sourceAlpha, img.destAlpha,
					img.fadeTimer * fs)

				if img.alpha == img.destAlpha then
					img.fadeTimer = 0
					img.sourceAlpha = nil
				end

				if img.fadeAway and img.alpha <= 0 then
					if i == 1 and nextBG ~= nil then
						images[1] = nextBG

						-- We loop over nextBG once rather than skipping
						-- it until next frame by not increasing i here.
					else
						-- Let's say i == 2 here. We're removing that element from
						-- the images table, which re-arranges the table elements.
						-- So images[3] becomes images[2], for example.
						RemoveImage(i)

						-- Because of that, we don't actually want to increase i here.

						-- The only exceptions are cases where RemoveImage doesn't remove
						-- an element from the images table. This only happens if we tell
						-- it to remove element #1, where it just re-generates images[1]
						-- instead, as that's the background; we don't want it gone completely!
						if i == 1 then
							i = i + 1 
						end
					end
				else
					i = i + 1
				end
			else
				i = i + 1
			end
		else
			i = i + 1
		end
	end
end

local function GetImageScaling(img)
	-- No Screen-Scaling
	if img.scaleType == 1 then
		return img.sx, img.sy

	-- Stretch to Screen Resolution
	elseif img.scaleType == 2 then
		return (ScreenWidth / img.width),
			(ScreenHeight / img.height)
	end

	-- Default (screen scaling * image scaling)
	return (sx * img.sx), (sy * img.sy)
end

local function GetImageTransform(img)
	local x, y = img.x, img.y
	local xs, ys = GetImageScaling(img)

	-- Default (screen scaling * image scaling)
	if not img.scaleType or img.scaleType == 0 then
		x = (x * sx)
		y = (y * sy)

	-- Stretch to Screen Resolution
	elseif img.scaleType == 2 then
		return x, y, xs, ys
	end

	-- X Anchors
	if img.anchorX == "center" then
		x = x + (ScreenWidth / 2)
	elseif img.anchorX == "left" then
		x = x + (img.ox * xs)
	elseif img.anchorX == "right" then
		x = x + ScreenWidth - (img.ox * xs)
	end

	-- Y Anchors
	if img.anchorY == "center" then
		y = y + (ScreenHeight / 2)
	elseif img.anchorY == "top" then
		y = y + (img.oy * ys)
	elseif img.anchorY == "bottom" then
		y = y + ScreenHeight - (img.oy * ys)
	end

	return x, y, xs, ys
end

local function DrawImage(img)
	if img == nil or img.image == nil then
		return
	end

	local x, y, xs, ys = GetImageTransform(img)
	love.graphics.setColor(1, 1, 1, img.alpha)
	love.graphics.draw(img.image, x, y, img.r,
		xs, ys, img.ox, img.oy)

	-- Animation Editor Selected Box
	if AnimEditor and SelectedImage == img then
		love.graphics.setColor(1, 1, 1)
		love.graphics.rectangle("line",
			x - (img.ox * xs),
			y - (img.oy * ys),
			img.width  * xs,
			img.height * ys)
	end
end

function DrawImages()
	if images ~= nil then
		sx = (ScreenWidth * 0.9) / TargetWidth
		sy = (ScreenHeight * 0.9) / TargetHeight

		for i = 1, #images do
			DrawImage(images[i])

			-- Debug
			if DebugUIVisible then
				if i == 1 then
					ChangeFont("Default")
					love.graphics.setColor(1, 1, 1, 1)
					love.graphics.print("Images:", ScreenWidth - 80,
						0, 0, 0.5, 0.5)
				end
			
				local a = images[i].alpha
				if not a then
					a = 0.25
					love.graphics.setColor(0, 1, 0, a)
				else
					if a < 0.25 then
						a = 0.25
					end
					love.graphics.setColor(0, 0.58, 1, a)
				end
				
				love.graphics.print(tostring(i), ScreenWidth - 20,
					i * 20, 0, 0.5, 0.5)
			end
		end
	end
end

function MousePressedImages(x, y, button)
	SelectedImage = nil
	for i, img in pairs(images) do
		if i > 1 and img.image ~= nil then
			if MouseIsOverImage(x, y, img) then
				if img.animating == nil or not img.animating then
					if img.keyframes == nil then
						img.keyframes = { GenKeyframe(img) }
						img.currentFrame = 1
						GenKeyframeInfos(img)
					end

					img.animating = false
					SelectedImage = img
					UpdateImagePos()
				end
			end
		end
	end
end

function MouseIsOverImage(x, y, img)
	local xp, yp, xs, ys = GetImageTransform(img)
	return x >= xp - (img.ox * xs) and x <= xp + (img.ox * xs) and
		y >= yp - (img.oy * ys) and y <= yp + (img.oy * ys)
end