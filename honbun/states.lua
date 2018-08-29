-- Honbun (本文) Visual Novel Engine
-- By: Radfordhound

-- Functions
function CreateState()
    return
    {
        active = false
    }
end

function InitState(state, args)
    if state.Init ~= nil then
        state:Init(args)
    end
end

function StartState(state)
    state.active = true
    if state.Start ~= nil then
        state:Start()
    end
end

function FinishState(state)
    state.active = false
	if state.Finish ~= nil then
		state:Finish()
    end
end