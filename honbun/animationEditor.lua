-- Honbun (本文) Visual Novel Engine
-- By: Radfordhound

-- Variables
local lockX, lockY, scaling = false, false, false
local isTyping = false
local txt = ""
local smx, smy = nil, nil

SelectedImage = nil
AutoAddKeyframe = false
AnimEditor = false

-- Functions
function GenKeyframe(img)
    return {
        x = img.x,
        y = img.y,
        r = img.r,
        sx = img.sx,
        sy = img.sy
    }
end

function GenKeyframeInfo()
    return {
        frameIndex = 1,
        animTime = 0
    }
end

function GenKeyframeInfos(img)
    img.XInfo = GenKeyframeInfo()
    img.YInfo = GenKeyframeInfo()
    img.RInfo = GenKeyframeInfo()
    img.SXInfo = GenKeyframeInfo()
    img.SYInfo = GenKeyframeInfo()
end

function TypingAnimationEditor(text)
    if not isTyping then
        return
    end

    txt = txt .. text
end

local function SetTyping(v)
    isTyping = v
    love.keyboard.setKeyRepeat(v)
    love.keyboard.setTextInput(v)
end

function UpdateImagePos(img)
    if img == nil then
        img = SelectedImage
    end

    local frame = img.keyframes[img.currentFrame]
    img.x = frame.x
    img.y = frame.y
    img.r = frame.r
    img.sx = frame.sx
    img.sy = frame.sy
end

function StartAnimating(img, speed)
    img.animating = true
    img.currentFrame = 1

    if speed == nil then
        img.animSpeed = 1
    else
        img.animSpeed = speed
    end

    GenKeyframeInfos(img)
    UpdateImagePos(img)
    img.currentFrame = #img.keyframes
end

function KeyPressedAnimationEditor(key)
    if isTyping then
        if key == "backspace" then
            local byteOffset = utf8.offset(txt, -1)
            if byteOffset then
                txt = string.sub(txt, 1, byteOffset - 1)
            end
        elseif key == "return" then
            SetTyping(false)
            local pth = txt .. ".anim"
            print("Saving animation at: " .. pth)
            bitser.dumpLoveFile(pth, SelectedImage.keyframes)
            txt = ""
        end

        return
    end

    if SelectedImage == nil or SelectedImage.animating then
        return
    end

    if key == "f1" then
        SelectedImage.animating = not SelectedImage.animating
        if SelectedImage.animating then
            StartAnimating(SelectedImage, 1)
        end
    elseif key == "f8" then
        SetTyping(true)
    elseif key == "f4" then
        scaling = not scaling
    elseif key == "delete" then
        if SelectedImage.currentFrame > 1 then
            table.remove(SelectedImage.keyframes, SelectedImage.currentFrame)
            SelectedImage.currentFrame = SelectedImage.currentFrame - 1
            UpdateImagePos()
        end
    elseif key == "lshift" or key == "rshift" then
        lockX = not lockX
    elseif key == "lctrl" or key == "rctrl" then
        lockY = not lockY
    elseif key == "left" then
        if SelectedImage.currentFrame > 1 then
            SelectedImage.currentFrame = SelectedImage.currentFrame - 1
            UpdateImagePos()
        end
    elseif key == "right" then
        if SelectedImage.currentFrame < #SelectedImage.keyframes then
            SelectedImage.currentFrame = SelectedImage.currentFrame + 1
        else
            SelectedImage.keyframes[#SelectedImage.keyframes + 1] =
                GenKeyframe(SelectedImage)

			SelectedImage.currentFrame = SelectedImage.currentFrame + 1
        end

        UpdateImagePos()
    end
end

function MouseWheelAnimationEditor(x, y)
    if SelectedImage == nil then
        return
    end

    local frame = SelectedImage.keyframes[SelectedImage.currentFrame]
    if scaling then
        frame.sx = frame.sx + (y * 0.1)
        frame.sy = frame.sy + (y * 0.1)
        SelectedImage.sx = frame.sx
        SelectedImage.sy = frame.sy
    else
        frame.r = frame.r + (y * 0.0174533)
        SelectedImage.r = frame.r
    end
end

function UpdateAnimationEditor()
    if SelectedImage == nil then
        return
    end

    local mx, my = love.mouse.getPosition()
	local mDown = love.mouse.isDown(1)

    -- Mouse Drag
    if mDown and not SelectedImage.animating then
        if smx == nil then
            smx = (SelectedImage.x - mx)
        end

        if smy == nil then
            smy = (SelectedImage.y - my)
        end

        if not lockX then
            SelectedImage.x = mx + smx
            SelectedImage.keyframes[SelectedImage.currentFrame].x = SelectedImage.x
        end

        if not lockY then
            SelectedImage.y = my + smy
            SelectedImage.keyframes[SelectedImage.currentFrame].y = SelectedImage.y
        end
    else
        smx = nil
        smy = nil
    end

    -- WASD Movement
    if not SelectedImage.animating then
        if love.keyboard.isDown("a") then
            SelectedImage.x = SelectedImage.x - 1
            SelectedImage.keyframes[SelectedImage.currentFrame].x = SelectedImage.x
        elseif love.keyboard.isDown("d") then
            SelectedImage.x = SelectedImage.x + 1
            SelectedImage.keyframes[SelectedImage.currentFrame].x = SelectedImage.x
        end

        if love.keyboard.isDown("w") then
            SelectedImage.y = SelectedImage.y - 1
            SelectedImage.keyframes[SelectedImage.currentFrame].y = SelectedImage.y
        elseif love.keyboard.isDown("s") then
            SelectedImage.y = SelectedImage.y + 1
            SelectedImage.keyframes[SelectedImage.currentFrame].y = SelectedImage.y
        end
    end
end

function DrawAnimationEditor()
    if isTyping then
        love.graphics.print("Type a filename and hit enter to save.", 4, 70)
        love.graphics.print("Folder: " .. love.filesystem.getSaveDirectory(), 25, 90)
        love.graphics.print("FileName: " .. txt .. ".anim", 25, 110)
    elseif SelectedImage ~= nil then
        love.graphics.print("Keyframe " .. tostring(SelectedImage.currentFrame) ..
            "/" .. tostring(#SelectedImage.keyframes), 25, 130)

        love.graphics.print("X: " .. tostring(SelectedImage.x) ..
            ", Y: " .. tostring(SelectedImage.y) .. ", R: " ..
            tostring(SelectedImage.r) .. ", SX: " .. tostring(SelectedImage.sx) ..
            ", SY: " .. tostring(SelectedImage.sy), 25, 150)

        if SelectedImage.animating then
            love.graphics.print("Playing Animation", 4, 70)
            love.graphics.print("XINFO Frame Index: " .. SelectedImage.XInfo.frameIndex, 4, 90)
        else
            love.graphics.print(
                "F1: Play, F8: Save, F4: Toggle Scale/Rotation Mode, Shift: Toggle X Lock, Ctrl: Toggle Y Lock",
                4, 70)

            love.graphics.print(
                "Left: Previous Keyframe, Right: Next Keyframe, Delete: Delete Keyframe",
                4, 90)

            -- X Lock
            if lockX then
                love.graphics.setColor(0, 1, 0)
                love.graphics.line(SelectedImage.x, 0,
                    SelectedImage.x, ScreenHeight)
            end

            -- Y Lock
            if lockY then
                love.graphics.setColor(1, 0, 0)
                love.graphics.line(0, SelectedImage.y,
                    ScreenWidth, SelectedImage.y)
            end
        end
    else
        love.graphics.print("Click an image to start animating it.", 4, 70)
    end
end