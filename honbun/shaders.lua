-- Honbun (本文) Visual Novel Engine
-- By: Radfordhound

-- Variables
local shaders = {}

-- Functions
function AddShader(pixelCode, vertexCode)
    local shader = nil
    if vertexCode == nil then
        shader = love.graphics.newShader(pixelCode)
    else
        shader = love.graphics.newShader(pixelCode, vertexCode)
    end
    
    shaders[#shaders + 1] = shader
    return shader
end

function GetShader(index)
	if index ~= nil then
		return shaders[index]
	else
		return shaders[#shaders]
	end
end