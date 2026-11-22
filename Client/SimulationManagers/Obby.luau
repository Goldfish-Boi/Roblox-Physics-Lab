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
	
	local character = players.LocalPlayer.Character
	if character then
		character:PivotTo(CFrame.new(0, 125, 0))
	end
	
	for i, part in ipairs(obby:GetDescendants()) do
		if part.Name ~= "Win" then continue end
		if not part:IsA("BasePart") then continue end
		
		part.Touched:Connect(function()
			if not players.LocalPlayer then return end
			
			script.Win:Play()
			
			local character = players.LocalPlayer.Character
			if character then
				character:PivotTo(CFrame.new(0, 125, 0))
			end
		end)
	end
end

function module.cleanup()
	if not players.LocalPlayer then return end
	
	local character = players.LocalPlayer.Character
	if character then
		character:PivotTo(CFrame.new(0, -36, 0))
	end
end

return module
