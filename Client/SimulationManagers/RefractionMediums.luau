--!strict
--!optimize 2

local module = {}

local tweenService = game:GetService("TweenService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local simulationAssets = replicatedStorage.SimulationAssets

function module.run()
	workspace.Camera.CameraType = Enum.CameraType.Scriptable
	workspace.Camera.CFrame = CFrame.new(0, 10, 0)
	
	local medium = simulationAssets.MediumRefraction.Medium:Clone()
	medium.Parent = workspace.Simulation
	
	local upperLimit = workspace.Camera.CFrame.Position.Y + ((math.abs(workspace.Backdrop.Position.Z) - (workspace.Backdrop.Size.Z / 2)) * math.tan(math.rad(workspace.Camera.FieldOfView / 2)))
	local lowerLimit = workspace.Camera.CFrame.Position.Y - ((math.abs(workspace.Backdrop.Position.Z) - (workspace.Backdrop.Size.Z / 2)) * math.tan(math.rad(workspace.Camera.FieldOfView / 2))) + 1
	
	print(upperLimit, lowerLimit)
	
	medium:GetPropertyChangedSignal("Position"):Connect(function()
		--print(medium.Position.Y + (medium.Size.Y / 2))
		
		if medium.Position.Y + (medium.Size.Y / 2) > upperLimit then
			medium.DragDetector.Enabled = false
			
			tweenService:Create(medium, TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Position = Vector3.new(medium.Position.X, upperLimit - (medium.Size.Y / 2) - 2.5, medium.Position.Z)}):Play()
			
			task.delay(0.5, function()
				medium.DragDetector.Enabled = true
			end)
		elseif medium.Position.Y + (medium.Size.Y / 2) < lowerLimit then
			medium.DragDetector.Enabled = false
			
			tweenService:Create(medium, TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Position = Vector3.new(medium.Position.X, lowerLimit - (medium.Size.Y / 2) + 2.5, medium.Position.Z)}):Play()
			
			task.delay(0.5, function()
				medium.DragDetector.Enabled = true
			end)
		end
	end)
end

return module
