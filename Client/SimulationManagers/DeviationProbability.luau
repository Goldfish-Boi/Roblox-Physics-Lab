--!strict
--!optimize 2

local module = {}

local tweenService = game:GetService("TweenService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")

local simulationAssets = replicatedStorage.SimulationAssets

local ui:typeof(simulationAssets.DeviationProbability.DeviationProbabilityUI)?

function module.run()
	if not players.LocalPlayer then return end
	
	workspace.Camera.CameraType = Enum.CameraType.Scriptable
	workspace.Camera.CFrame = CFrame.new(0, 10, 0)
	
	local board = simulationAssets.DeviationProbability.Board:Clone()
	board.Parent = workspace.Simulation
	
	local wells = simulationAssets.DeviationProbability.Wells:Clone()
	wells.Parent = workspace.Simulation
	
	local maxCount = 0
	
	for i, well in ipairs(wells:GetChildren()::{typeof(wells.ExampleWell)}) do
		well.SurfaceGui.BackGround.Progress.Size = UDim2.fromScale(1, 0)
		
		well.Touched:Connect(function(otherPart)
			if otherPart.Name ~= "Ball" then return end
			
			otherPart.CanTouch = false
			otherPart:Destroy()
			
			well:SetAttribute("BallCount", well:GetAttribute("BallCount") + 1)
			
			if well:GetAttribute("BallCount") > maxCount then
				maxCount = well:GetAttribute("BallCount")
				
				for i, otherWell in ipairs(wells:GetChildren()::{typeof(wells.ExampleWell)}) do
					tweenService:Create(otherWell.SurfaceGui.BackGround.Progress, TweenInfo.new(0.75, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.fromScale(1, otherWell:GetAttribute("BallCount") / maxCount)}):Play()
				end
			end
			
			tweenService:Create(well.SurfaceGui.BackGround.Progress, TweenInfo.new(0.75, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.fromScale(1, well:GetAttribute("BallCount") / maxCount)}):Play()
		end)
	end
	
	ui = simulationAssets.DeviationProbability.DeviationProbabilityUI:Clone()
	ui.Parent = players.LocalPlayer.PlayerGui
	
	ui.TextButton.Activated:Connect(function()
		local ball = simulationAssets.DeviationProbability.Ball:Clone()
		ball.Position = Vector3.new(board.Origin.Position.X + ((math.random(1, 100) / 1000) * ((math.random(0, 1) * 2) - 1)), board.Origin.Position.Y, board.Origin.Position.Z)
		ball.Parent = workspace.Simulation
	end)
end

function module.cleanup()
	if ui then
		ui:Destroy()
	end
end

return module
