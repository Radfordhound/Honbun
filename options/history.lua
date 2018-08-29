-- Honbun (本文) Visual Novel Engine
-- By: Radfordhound

-- Variables
local isHistoryOpen, wasBoxHidden, couldProgress,
	historyScroll, maxScroll = false, false, true, nil, 0
local historyBG, font, fh, hs = nil, nil, nil, 0
local x1, x2, y, ym, endY, w, sx, sy = 0, 195, 0, 90, 400, 400, 1, 1
local sbx, sby, sbw, sbh, sty, sbl, scrolling = 0, 0, 15, 80, nil, 0, false

-- State
local history = CreateState()
function history:Init(args)
    if args ~= nil and #args >= 1 then
		if #args >= 1 then
			historyBG = GetImageArg(args[1])
		end

		if #args >= 2 then
			font = args[2]
		else
			font = "Default"
		end
    end
end

function history:Resize()
	local startOption = GetOption(1)
	if startOption ~= nil then
		x1 = startOption.x
		x2 = startOption.x + 195 * ScaleX
		endY = startOption.y
	end

	if historyBG ~= nil then
		w = (historyBG:getWidth() * ScaleX) - x2 - x1
	end

	if ScreenWidth < TargetWidth or ScreenHeight < TargetHeight then
		sx = ScaleX
		sy = ScaleY
	else
		sx = 1
		sy = 1
	end

	-- Compute Scrollbar Position/Size
	ym = 90 * sy
	sbh = 80 * sy
	
	if RunningOnMobile then
		sbw = 5 * sx
		sbx = (x2 + w)
	else
		sbw = 15 * sx
		sbx = (x2 + w)
	end

	sbl = (endY - sbh - ym)
	y = ym

	local _, wrappedText, lh = nil, nil, nil
	for i, line in ipairs(History) do
		if line[2] ~= nil and line[2] ~= "" then
			_, wrappedText = GetFontWrap(font, line[2], w / sx)
			lh = y + ((fh * #wrappedText) + hs) * sy

			y = lh
		end
	end

	if y > endY then
		if historyScroll ~= nil then
			historyScroll = (historyScroll / maxScroll) * (y - endY)
		end

		maxScroll = (y - endY)

		if historyScroll == nil then
			historyScroll = maxScroll
		end

		sby = ((historyScroll / maxScroll) * sbl) + ym
	else
		historyScroll = 0
		sby = nil
	end
end

function history:Start()
    isHistoryOpen = not isHistoryOpen
	if isHistoryOpen then
		-- Initialize History Box
		couldProgress = CanProgress
		CanProgress = false
		IsSkipping = false
		ChoicesEnabled = false
		historyScroll = nil
		scrolling = false
		
		wasBoxHidden = TextBoxHidden
		TextBoxHidden = true
		
		fh = GetFontHeight(font)
		hs = (70 - fh)
		
		self:Resize()
	else
		-- Close History Box
		CanProgress = couldProgress
		ChoicesEnabled = true
		TextBoxHidden = wasBoxHidden
        FinishState(self)
    end
end

-- TODO: Scrollwheel support and better touchscreen support.
function history:Update(dt)
	local mx, my = love.mouse.getPosition()
	if not scrolling then
		scrolling = (sby ~= nil and
		   love.mouse.isDown(1) and RunningOnMobile or
		   (mx >= sbx and mx <= sbx + sbw and
		   my >= sby and my <= sby + sbh))
	else
		scrolling = love.mouse.isDown(1)
	end

	if scrolling then
		if sty == nil then
			if RunningOnMobile then
				sty = my
			else
				sty = (sby - my)
			end
		end

		if RunningOnMobile then
			sby = sby + (sty - my)
			sty = my
			historyScroll = (((sby - ym) / sbl) * maxScroll)
		else
			historyScroll = (((my + sty - ym) / sbl) * maxScroll)
		end

		if historyScroll > maxScroll then
			historyScroll = maxScroll
		elseif historyScroll < 0 then
			historyScroll = 0
		end
	else
		sty = nil
	end
end

function history:Draw()
    if isHistoryOpen and historyBG ~= nil then
		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(historyBG, 0, 0, 0, ScaleX, ScaleY)
        
		y = (ym - historyScroll)
		ChangeFont(font)

		-- Draw ScrollBar
		if sby ~= nil then
			sby = ((historyScroll / maxScroll) * sbl) + ym
			love.graphics.rectangle("fill", sbx, sby, sbw, sbh)
		end

		-- Print Text
		local _, wrappedText, lh = nil, nil, nil
		for i, line in ipairs(History) do
			if line[2] ~= nil and line[2] ~= "" then
				if line[1] == nil then
					line[1] = "Narrator"
				end

				_, wrappedText = GetFontWrap(font, line[2], w / sx)
				lh = y + ((fh * #wrappedText) + hs) * sy

				-- If entire paragraph goes off-screen, print only on-screen lines
				if lh >= endY then
					lh = y
					for i2, l in ipairs(wrappedText) do
						lh = lh + (fh * sy)
						if lh < endY then
							-- Print Name
							if i2 == 1 then
								love.graphics.print(line[1], x1, y, 0, sx, sy)
							end

							-- Print Line
							love.graphics.printf(wrappedText[i2], x2,
								y, w / sx, "left", 0, sx, sy)
							y = lh
						else
							break
						end
					end
					break

				-- Only draw lines which are on-screen
				elseif lh >= 0 then
					-- Print Name
					love.graphics.print(line[1], x1, y, 0, sx, sy)

					-- Print Line
					love.graphics.printf(line[2], x2,
						y, w / sx, "left", 0, sx, sy)
				end

				y = lh
			end
		end
    end
end

return history