--!strict
--!optimize 2

local module = {}

local tweenService = game:GetService("TweenService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local simulationAssets = replicatedStorage.SimulationAssets

local beamModel:Model?
local mediumFolder:Folder?

--------------------------------------------- Helper Functions ---------------------------------------------

function clearRefractiveBeams()
	if not beamModel then return end
	
	for i, beam in beamModel:GetChildren() do
		if beam.Name == "BeamPart" or not beam:IsA("BasePart") then continue end
		
		beam:Destroy()
	end
end

function findClosestMediums(laserAngle:number) : (number|{number}?, number?, number?)
	if not mediumFolder then return nil, nil, nil end
	
	local medium = mediumFolder:FindFirstChild("Medium")::BasePart
	local laser = workspace.Simulation:FindFirstChild("Laser")::BasePart
	local blast = laser:FindFirstChild("Blast")::Attachment
	local direction = (90 - laserAngle) / math.abs(90 - laserAngle)
	
	if math.isinf(direction) then
		return nil, nil, nil
	end
	
	if direction == -1 then
		if medium.Position.Y + (medium.Size.Y / 2) >= blast.WorldPosition.Y then
			return nil, nil, nil
		else
			return medium.Position.Y + (medium.Size.Y / 2), direction, medium:GetAttribute("RefractiveIndex")
		end
	else
		if medium.Position.Y + (medium.Size.Y / 2) <= blast.WorldPosition.Y then
			return nil, nil, nil
		else
			return medium.Position.Y + (medium.Size.Y / 2), direction, medium:GetAttribute("RefractiveIndex")
		end
	end
end

function findNextMediumAbove(Y) : (BasePart?, number?, number?)
	if not mediumFolder then return nil, nil, nil end
	
	local nextMedium = nil
	
	for i, medium in mediumFolder:GetChildren()::{BasePart} do
		if medium.Position.Y + (medium.Size.Y / 2) <= Y then continue end
		
		if not nextMedium then
			nextMedium = medium
		else
			if medium.Position.Y + (medium.Size.Y / 2) < nextMedium.Position.Y + (nextMedium.Size.Y / 2) then
				nextMedium = medium
			end
		end
	end
	
	return if nextMedium then nextMedium else nil, if nextMedium then nextMedium.Position.Y + (nextMedium.Size.Y / 2) else nil, if nextMedium then nextMedium:GetAttribute("RefractiveIndex") else nil
end

function findNextMediumBelow(Y) : (BasePart?, number?, number?)
	if not mediumFolder then return nil, nil, nil end

	local nextMedium = nil

	for i, medium in mediumFolder:GetChildren()::{BasePart} do
		if medium.Position.Y + (medium.Size.Y / 2) >= Y then continue end

		if not nextMedium then
			nextMedium = medium
		else
			if medium.Position.Y + (medium.Size.Y / 2) > nextMedium.Position.Y + (nextMedium.Size.Y / 2) then
				nextMedium = medium
			end
		end
	end

	return if nextMedium then nextMedium else nil, if nextMedium then nextMedium.Position.Y + (nextMedium.Size.Y / 2) else nil, if nextMedium then nextMedium:GetAttribute("RefractiveIndex") else nil
end

--------------------------------------------- Primary Functions ---------------------------------------------

function createRefractionBeam(incidentAngle:number, direction:number, refractiveIndex:number, Y1:number, Y2:number)
	if not beamModel then return end
	
	local pointOfIncidenceX:number, pointOfIncidenceY:number = Y2 * math.tan(math.rad(incidentAngle)), Y1 - Y2
	
	local beam = beamModel:FindFirstChild("BeamPart2")::BasePart
	
	if not beam then
		beam = simulationAssets.MediumRefraction.BeamPart:Clone()
		beam.Name = "BeamPart2"
		beam.Parent = beamModel
	end
	
	local refractionAngle =  math.asin((1 * math.sin(math.rad(incidentAngle))) / refractiveIndex)
	
	beam.Size = Vector3.new(1000, 0.1, 0.1)
	beam.Position = Vector3.new(pointOfIncidenceX, pointOfIncidenceY, simulationAssets.MediumRefraction.BeamPart.Position.Z)
	beam.Orientation = Vector3.new(0, 0, -math.deg(refractionAngle) + 90)

	beam.CFrame *= CFrame.new((beam.Size.X / 2), 0, 0)
end

function createBeam()
	if not beamModel then return end
	if not mediumFolder then return end
	
	local medium = mediumFolder:FindFirstChild("Medium")::BasePart
	local laser = workspace.Simulation:FindFirstChild("Laser")::BasePart
	local blast = laser:FindFirstChild("Blast")::Attachment
	
	local beam = beamModel:FindFirstChild("BeamPart")::BasePart
	
	local incidentAngle = math.abs(math.abs(laser.Orientation.Z ) - 90)
	
	local mediumHeight, direction, n = findClosestMediums(incidentAngle)
	
	--[[if not mediumHeight or not direction or not n then
		beam.Size = Vector3.new(1000, 0.1, 0.1)
		
		clearRefractiveBeams()
	else
		local height = blast.WorldPosition.Y - (medium.Position.Y + (medium.Size.Y / 2))
		local hypotenuse = height / math.cos(math.rad(incidentAngle))
		
		createRefractionBeam(incidentAngle, direction, n, blast.WorldPosition.Y, height)
		
		beam.Size = Vector3.new(hypotenuse, 0.1, 0.1)
	end]]--
	
	print(incidentAngle)
	
	beam.Size = Vector3.new(1000, 0.1, 0.1)
	beam.CFrame = blast.WorldCFrame * CFrame.new((beam.Size.X / 2), 0, 0)
end

function module.run()
	workspace.Camera.CameraType = Enum.CameraType.Scriptable
	workspace.Camera.CFrame = CFrame.new(0, 10, 0)
	
	local laser = simulationAssets.MediumRefraction.Laser:Clone()
	laser.Parent = workspace.Simulation
	
	beamModel = Instance.new("Model")
	beamModel.Name = "Beam"
	beamModel.Parent = workspace.Simulation
	
	mediumFolder = Instance.new("Folder")
	mediumFolder.IconTint = Color3.new(0, 1, 1)
	mediumFolder.Name = "Medium"
	mediumFolder.Parent = workspace.Simulation
	
	local medium = simulationAssets.MediumRefraction.Medium:Clone()
	medium.Parent = mediumFolder
	
	local beamHighlight = simulationAssets.MediumRefraction.BeamHighlight:Clone()
	beamHighlight.Parent = beamModel
	beamHighlight.Adornee = beamModel
	
	local beam = simulationAssets.MediumRefraction.BeamPart:Clone()
	beam.Parent = beamModel
	
	local upperLimit = workspace.Camera.CFrame.Position.Y + ((math.abs(workspace.Backdrop.Position.Z) - (workspace.Backdrop.Size.Z / 2)) * math.tan(math.rad(workspace.Camera.FieldOfView / 2)))
	local lowerLimit = workspace.Camera.CFrame.Position.Y - ((math.abs(workspace.Backdrop.Position.Z) - (workspace.Backdrop.Size.Z / 2)) * math.tan(math.rad(workspace.Camera.FieldOfView / 2))) + 2.5
	
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
		
		createBeam()
	end)
	
	laser.Changed:Connect(function()
		createBeam()
	end)
	
	laser.Rotate.Changed:Connect(function()
		createBeam()
	end)
	
	createBeam()
end

return module
