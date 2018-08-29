-- Honbun (本文) Visual Novel Engine
-- By: Radfordhound

-- State
local save = CreateState()
function save:Start()
    SaveGame()
end

return save