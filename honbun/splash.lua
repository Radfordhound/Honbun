-- Honbun (本文) Visual Novel Engine
-- By: Radfordhound
local splashImgs, sx, sy, a, state, time,
    splashIndex, fs, waitTime = nil, nil, nil, 0, 0, 0, 0, 0.01, 4

SplashScreen = CreateState()
function SplashScreen:Init(args)
    if #args < 1 or not args[1] then
        error("No images were passed to SplashScreen; you can't have a splash screen without a splash!")
    end

    -- Load all of the splash screen images
    splashImgs = {}
    for i, img in ipairs(args[1]) do
        splashImgs[#splashImgs + 1] = GetImageArg(img)
    end

    -- Set arguments
    fs = SetArg(args[2], "number", 0.01)
    waitTime = SetArg(args[3], "number", 4)

    -- Go to the first splash
    splashIndex = 0
    self:NextSplash()
end

function SplashScreen:Start()
    love.graphics.setBackgroundColor(1, 1, 1)
end

function SplashScreen:NextSplash()
    -- Finish the splash screen if we've reached the last splash in the table
    local i = splashIndex + 1
    if i > #splashImgs then
        FinishCurrentState()
        return
    end

    -- Otherwise, setup the next splash
    splashIndex = i
    a = 0
    state = 0
    time = 0
    self:Resize()
end

function SplashScreen:Resize()
    sx = (ScreenWidth / splashImgs[splashIndex]:getWidth())
    sy = (ScreenHeight / splashImgs[splashIndex]:getHeight())
end

function SplashScreen:KeyPressed(key, scanCode, isRepeat)
    if time >= 1 then
        if key == "return" or key == "space" then
            state = 2
        end
    end
end

function SplashScreen:MousePressed(x, y, button, isTouch)
    if time >= 1 then
        state = 2
    end
end

function SplashScreen:Update(dt)
    time = time + dt
    
    -- Fading In
    if state == 0 then
        if a < 1 then
            a = a + 0.01
        else
            state = 1
        end
    end

    -- Showing Splash
    if state == 1 and time >= 4 then
        state = 2
    end

    -- Fading Out
    if state == 2 then
        if a > 0 then
            a = a - 0.01
        else
            self:NextSplash()
        end
    end
end

function SplashScreen:Draw()
    love.graphics.setColor(1, 1, 1, a)
    love.graphics.draw(splashImgs[splashIndex], 0, 0, 0, sx, sy)
end