--!strict
--!optimize 2

local module = {}

local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")

local simulationAssets = replicatedStorage.SimulationAssets

function module.run()
	if not players.LocalPlayer then return end
	
	local obby = simulationAssets.Obby:Clone()
	obby.Parent = workspace.Simulation
	
	workspace.Camera.CameraType = Enum.CameraType.Custom
	
	if local character = players.LocalPlayer.Character then
		character:PivotTo(CFrame.new(0, 125, 0))
	end
end

function module.cleanup()
	if not players.LocalPlayer then return end

	if local character = players.LocalPlayer.Character then
		character:PivotTo(CFrame.new(0, -36, 0))
	end
end

return module
