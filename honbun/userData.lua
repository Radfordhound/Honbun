-- Honbun (本文) Visual Novel Engine
-- By: Radfordhound

-- Variables
UserData = {}

-- Functions
local function ReadSaveData()
    local file = bitser.loadLoveFile("saveFile.bin")
    local chap = file["CurrentChapter"]
    local sp = file["StoryPoint"]
    ChoiceIndex = file["ChoiceIndex"]
    local answers = file["Answers"]
    UserData = file["UserData"]

    if sp ~= StoryPoint then
        ChangeChapter(chap, nil, false)
        Answers = answers
        JumpToPoint(sp)
    end
end

local function WriteSaveData()
    local file = {}
    file["CurrentChapter"] = CurrentChapter
    file["StoryPoint"] = StoryPoint
    file["ChoiceIndex"] = ChoiceIndex
    file["Answers"] = Answers
    file["UserData"] = UserData

    bitser.dumpLoveFile("saveFile.bin", file)
end

function LoadGame()
    if love.filesystem.getInfo("saveFile.bin") == nil then
        return false
    end
    
    return pcall(ReadSaveData)
end

function SaveGame()
    return pcall(WriteSaveData)
end