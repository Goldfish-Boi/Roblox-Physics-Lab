--!strict
--!optimize 2

local module = {}

local tweenService = game:GetService("TweenService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local simulationAssets = replicatedStorage.SimulationAssets

local nAir = 1

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
	local bufferMedium = nil
	
	for i, medium in mediumFolder:GetChildren()::{BasePart} do
		if medium.Position.Y + (medium.Size.Y / 2) <= Y then continue end
		
		if not bufferMedium then
			bufferMedium = medium
		else
			if medium.Position.Y + (medium.Size.Y / 2) < bufferMedium.Position.Y + (bufferMedium.Size.Y / 2) then
				bufferMedium = medium
			end
		end
	end
	
	if not bufferMedium then
		return nil, nil, nAir
	end
	
	for i, medium in mediumFolder:GetChildren()::{BasePart} do
		if medium.Position.Y + (medium.Size.Y / 2) <= bufferMedium.Position.Y + (bufferMedium.Size.Y / 2) + 1e-5 then continue end

		if not nextMedium then
			nextMedium = medium
		else
			if medium.Position.Y + (medium.Size.Y / 2) < nextMedium.Position.Y + (nextMedium.Size.Y / 2) then
				nextMedium = medium
			end
		end
	end
	
	return if bufferMedium then bufferMedium else nil, if bufferMedium then bufferMedium.Position.Y + (bufferMedium.Size.Y / 2) else nil, if nextMedium then nextMedium:GetAttribute("RefractiveIndex") else nAir
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

function findCurrentMedium(Y) : number
	if not mediumFolder then return nAir end

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

	return if nextMedium then nextMedium:GetAttribute("RefractiveIndex") else nAir
end

--------------------------------------------- Primary Functions ---------------------------------------------

--[[function createRefractionBeam(incidentAngle:number, direction:number, refractiveIndex:number, Y1:number, Y2:number)
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
end]]--

function createRefraction(n1:number, n2:number, directionY:number, incidentAngle:number, X:number, Y:number)
	if not beamModel then return end
	
	print(n1, n2)
	
	local laser = workspace.Simulation:FindFirstChild("Laser")::BasePart
	local blast = laser:FindFirstChild("Blast")::Attachment
	
	local directionX = if math.abs(laser.Orientation.Z) < 90 then 1 elseif math.abs(laser.Orientation.Z) > 90 then -1 else 0
	local angleOfRefraction = math.deg(math.asin((n1 * math.sin(math.rad(incidentAngle))) / n2))
	
	local beam = beamModel:FindFirstChild("BeamPart2")::BasePart

	if not beam then
		beam = simulationAssets.MediumRefraction.BeamPart:Clone()
		beam.Name = "BeamPart2"
		beam.Parent = beamModel
	end
	
	beam.Size = Vector3.new(1000, 0.1, 0.1)
	beam.CFrame = CFrame.new(blast.WorldPosition.X + (-1 * directionY * directionX * ((blast.WorldPosition.Y - Y) * math.tan(math.rad(incidentAngle)))), Y, -21.4) * CFrame.Angles(0, 0, math.rad(directionY * (90 - directionX * angleOfRefraction))) * CFrame.new((beam.Size.X / 2), 0, 0)
end

function createBeam()
	if not beamModel then return end
	if not mediumFolder then return end
	
	local medium = mediumFolder:FindFirstChild("Medium")::BasePart
	local laser = workspace.Simulation:FindFirstChild("Laser")::BasePart
	local blast = laser:FindFirstChild("Blast")::Attachment
	
	local beam = beamModel:FindFirstChild("BeamPart")::BasePart
	
	local incidentAngle, direction = math.abs(math.abs(laser.Orientation.Z) - 90), laser.Orientation.Z / math.abs(laser.Orientation.Z)
	
	if math.isinf(direction) then
		beam.Size = Vector3.new(1000, 0.1, 0.1)
		
		clearRefractiveBeams()
	else
		if direction == 1 then
			local medium, Y, n = findNextMediumAbove(blast.WorldPosition.Y)
			
			if not medium or not Y or not n then
				beam.Size = Vector3.new(1000, 0.1, 0.1)

				clearRefractiveBeams()
			else
				local height = Y - blast.WorldPosition.Y
				local hypotenuse = height / math.cos(math.rad(incidentAngle))
				
				beam.Size = Vector3.new(hypotenuse, 0.1, 0.1)
				
				createRefraction(findCurrentMedium(blast.WorldPosition.Y), n, direction, incidentAngle, blast.WorldPosition.X + ((blast.WorldPosition.Y - Y) * math.tan(math.rad(incidentAngle))), Y)
			end
		else
			local medium, Y, n = findNextMediumBelow(blast.WorldPosition.Y)
			
			if not medium or not Y or not n then
				beam.Size = Vector3.new(1000, 0.1, 0.1)

				clearRefractiveBeams()
			else
				local height = blast.WorldPosition.Y - Y
				local hypotenuse = height / math.cos(math.rad(incidentAngle))

				beam.Size = Vector3.new(hypotenuse, 0.1, 0.1)
				
				createRefraction(findCurrentMedium(blast.WorldPosition.Y), n, direction, incidentAngle, blast.WorldPosition.X + (height * math.tan(math.rad(incidentAngle))), Y)
			end
		end
		
		--print(findNextMediumBelow(blast.WorldPosition.Y), findCurrentMedium(blast.WorldPosition.Y), findNextMediumAbove(blast.WorldPosition.Y))
		
		--print(findNextMediumAbove(blast.WorldPosition.Y))
	end
	
	--[[local mediumHeight, direction, n = findClosestMediums(incidentAngle)
	
	if not mediumHeight or not direction or not n then
		beam.Size = Vector3.new(1000, 0.1, 0.1)
		
		clearRefractiveBeams()
	else
		local height = blast.WorldPosition.Y - (medium.Position.Y + (medium.Size.Y / 2))
		local hypotenuse = height / math.cos(math.rad(incidentAngle))
		
		createRefractionBeam(incidentAngle, direction, n, blast.WorldPosition.Y, height)
		
		beam.Size = Vector3.new(hypotenuse, 0.1, 0.1)
	end]]--
	
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
