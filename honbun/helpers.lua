-- Honbun (本文) Visual Novel Engine
-- By: Radfordhound

-- Functions
function SetArg(arg, type, default)
    if arg ~= nil and type(arg) == type then
        return arg
    else
        return default
    end
end

function GetImageArg(arg)
    if type(arg) == "string" then
        return LoadImage(arg)
    else
        return arg
    end
end