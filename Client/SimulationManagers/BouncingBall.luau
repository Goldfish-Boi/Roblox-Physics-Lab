--!strict
--!optimize 2

local module = {}

local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")

local simulationAssets = replicatedStorage.SimulationAssets

local gravity = 10

local ballFolder:Folder?
local surface:typeof(simulationAssets.BouncingBall.Surface)?
local gravityConnection:RBXScriptConnection?

local upperLimit:number?
local lowerLimit:number?
local dragActive:{typeof(simulationAssets.BouncingBall.Ball)} = {}
local velocityTable = {}

function terminateSimulation()
	if gravityConnection then
		gravityConnection:Disconnect()
		gravityConnection = nil
	end

	return
end

function checkBallBuffers(ball:typeof(simulationAssets.BouncingBall.Ball))
	if not surface then return end
	if not upperLimit then return end
	
	if ball.Position.Y + (ball.Border.Size.Y / 2) > upperLimit then
		ball.DragDetector.Enabled = false
		
		task.delay(0.25, function() ball.DragDetector.Enabled = true end)
	elseif ball.Position.Y - (ball.Border.Size.Y / 2) < surface.Position.Y + (surface.Size.Y / 2) then
		ball.DragDetector.Enabled = false

		task.delay(0.25, function() ball.DragDetector.Enabled = true end)
	end
end

function module.run()
	workspace.Camera.CameraType = Enum.CameraType.Scriptable
	workspace.Camera.CFrame = CFrame.new(0, 10, 0)
	
	surface = simulationAssets.BouncingBall.Surface:Clone()
	surface.Parent = workspace.Simulation
	
	ballFolder = Instance.new("Folder")
	ballFolder.IconTint = Color3.new(0, 1 ,1)
	ballFolder.Parent = workspace.Simulation
	
	local ball = simulationAssets.BouncingBall.Ball:Clone()
	ball.Name = "Ball" .. tostring(#ballFolder:GetChildren() + 1)
	ball.Parent = ballFolder
	
	velocityTable[ball.Name] = 0
	
	ball.DragDetector.DragStart:Connect(function()
		table.insert(dragActive, ball)
		velocityTable[ball.Name] = 0
	end)
	
	ball.DragDetector.DragEnd:Connect(function()
		table.remove(dragActive, table.find(dragActive, ball))
		velocityTable[ball.Name] = 0
	end)
	
	ball.DragDetector.DragContinue:Connect(function()
		checkBallBuffers(ball)
	end)
	
	upperLimit = workspace.Camera.CFrame.Position.Y + ((math.abs(workspace.Backdrop.Position.Z) - (workspace.Backdrop.Size.Z / 2)) * math.tan(math.rad(workspace.Camera.FieldOfView / 2)))
	lowerLimit = workspace.Camera.CFrame.Position.Y - ((math.abs(workspace.Backdrop.Position.Z) - (workspace.Backdrop.Size.Z / 2)) * math.tan(math.rad(workspace.Camera.FieldOfView / 2))) + 2.5
	
	surface:GetPropertyChangedSignal("Position"):Connect(function()
		if not upperLimit then return end
		if not lowerLimit then return end
		if not surface then return end
		
		if surface.Position.Y + (surface.Size.Y / 2) > upperLimit then
			surface.DragDetector.Enabled = false

			tweenService:Create(surface, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = Vector3.new(surface.Position.X, upperLimit - (surface.Size.Y / 2) - 2.5, surface.Position.Z)}):Play()

			task.delay(0.5, function()
				if not surface then return end
				
				surface.DragDetector.Enabled = true
			end)
		elseif surface.Position.Y + (surface.Size.Y / 2) < lowerLimit then
			surface.DragDetector.Enabled = false

			tweenService:Create(surface, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = Vector3.new(surface.Position.X, lowerLimit - (surface.Size.Y / 2) + 2.5, surface.Position.Z)}):Play()

			task.delay(0.5, function()
				if not surface then return end
				
				surface.DragDetector.Enabled = true
			end)
		end
		
		if not ballFolder then return end
		
		for i, ball in ipairs(ballFolder:GetChildren()::{typeof(simulationAssets.BouncingBall.Ball)}) do
			if ball.Position.Y - (ball.Border.Size.Y / 2) > surface.Position.Y + (surface.Size.Y / 2) then continue end
			
			ball.Position = Vector3.new(ball.Position.X, surface.Position.Y + (surface.Size.Y / 2) + (ball.Border.Size.Y / 2), ball.Position.Z)
			ball.Border.Position = ball.Position
		end
	end)
	0
	gravityConnection = runService.RenderStepped:Connect(function(dt)
		if not surface then terminateSimulation() return end
		if not ballFolder then terminateSimulation() return end
		
		for ballName, velocity in pairs(velocityTable) do
			if ball.Position.Y - (ball.Border.Size.Y / 2) <= surface.Position.Y + (surface.Size.Y / 2) then continue end
			
			velocityTable[ballName] -= dt * gravity / 10
		end
		
		for i, ball:typeof(simulationAssets.BouncingBall.Ball) in ipairs(ballFolder:GetChildren()::{typeof(simulationAssets.BouncingBall.Ball)}) do
			if table.find(dragActive, ball) then continue end
			
			if ball.Position.Y - (ball.Border.Size.Y / 2) <= surface.Position.Y + (surface.Size.Y / 2) and velocityTable[ball.Name] < 0 then
				velocityTable[ball.Name] *= -1 * ball:GetAttribute("Elasticity")
			else
				ball.Position += Vector3.new(0, velocityTable[ball.Name], 0)
				ball.Border.Position += Vector3.new(0, velocityTable[ball.Name], 0)
			end
		end
	end)
end

function module.cleanup()
	terminateSimulation()
end

return module
