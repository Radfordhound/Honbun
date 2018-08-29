-- Honbun (本文) Visual Novel Engine
-- By: Radfordhound

-- Variables
local triggers = {}

-- Functions
function AddTrigger(cond, act)
    local trigger =
    {
        condition = cond,
        action = act
	}

	if IsJumping() then
		trigger:action()
	else
		triggers[#triggers + 1] = trigger
	end
	
	return trigger
end

function RemoveTrigger(index)
    if index ~= nil then
		table.remove(triggers, index)
	else
		table.remove(triggers)
	end
end

function ClearTriggers()
	triggers = {}
end

function UpdateTriggers()
    if triggers ~= nil then
		local i, trigger = 1, nil
		while i <= #triggers do
            trigger = triggers[i]
			if trigger ~= nil and trigger:condition() then
                trigger:action()
				RemoveTrigger(i)
			else
				i = i + 1
			end
		end
	end
end