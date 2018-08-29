-- Honbun (本文) Visual Novel Engine
-- By: Radfordhound

-- Variables
local songs = {}
AudioDirectory = "audio/"

-- Functions
function LoadAudio(pth, type)
    local audio = love.audio.newSource(AudioDirectory .. pth, type)
    if type == "static" then
        audio:setVolume(Settings.SFXVolume)
    end

    return audio
end

function GetBGM()
    if #songs == 0 then
        return nil
    end

    return songs[#songs]
end

function SetBGM(audio, fs, maxVolume)
    if maxVolume == nil then
        maxVolume = 1
    end
    
    bgm =
    {
        stream = audio,
        fadeState = 0,
        fadeSpeed = fs,
        volumeMax = maxVolume
    }

    songs[#songs + 1] = bgm
end

local function RemoveAudio(index)
    local bgm = songs[index]
    bgm.stream:stop()
    bgm.stream:release()
    table.remove(songs, index)
end

function ClearAudio()
    local i = 1
    local a = nil
    while i <= #songs do
        a = songs[i]
        a.stream:stop()
        a.stream:release()
        a = nil
        table.remove(songs, i)
    end

    songs = {}
end

function UpdateAudio()
    love.audio.setVolume(Settings.MasterVolume)

    if songs ~= nil then
        local i = 1
        while i <= #songs do
            local bgm = songs[i]
            if bgm ~= nil and bgm.fadeState ~= nil then
                local volume = bgm.stream:getVolume()

                -- Fade In
                if bgm.fadeState == 0 then
                    local max = (bgm.volumeMax * Settings.MusicVolume)
                    i = i + 1

                    if volume < max then
                        bgm.stream:setVolume(volume + bgm.fadeSpeed)
                    else
                        bgm.stream:setVolume(max)
                    end
                
                -- Fade Out
                elseif bgm.fadeState == 1 then
                    if volume > 0.1 then
                        i = i + 1
                        bgm.stream:setVolume(volume - bgm.fadeSpeed)
                    else
                        RemoveAudio(i)
                    end
                end
            else
                i = i + 1
            end
        end
    end
end