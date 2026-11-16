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
		if local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")::BasePart then
			humanoidRootPart.Position = Vector3.new(0, 110, 0)
		end
	end
end

function module.cleanup()
	if not players.LocalPlayer then return end

	if local character = players.LocalPlayer.Character then
		if local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")::BasePart then
			humanoidRootPart.Position = Vector3.new(0, -36, 0)
		end
	end
end

return module
