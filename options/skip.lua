-- Honbun (本文) Visual Novel Engine
-- By: Radfordhound

-- State
local skip = CreateState()
function skip:Start()
    IsSkipping = not IsSkipping
    StopCurrentSFX()
end

return skip