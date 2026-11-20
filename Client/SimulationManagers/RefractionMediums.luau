--!strict
--!optimize 2

local module = {}

local tweenService = game:GetService("TweenService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")

local simulationAssets = replicatedStorage.SimulationAssets

local nAir = 1
local laserDebounce:{typeof(simulationAssets.MediumRefraction.Laser)} = {}

local upperLimit:number?
local lowerLimit:number?
local rightHandLimit:number?
local leftHandLimit:number?

local mediumFolder:Folder?
local laserFolder:Folder?
local beamFolder:Folder?
local gui:typeof(simulationAssets.MediumRefraction.RefractionMediumsUI)?
local indexBillboard:typeof(simulationAssets.MediumRefraction.IndexBillboard)?

--------------------------------------------- Helper Functions ---------------------------------------------

function clearRefractiveBeams(laser:typeof(simulationAssets.MediumRefraction.Laser))
	if not beamFolder then return end
	
	for i, beamModel in beamFolder:GetDescendants() do
		if beamModel.Name ~= "BeamModel" .. laser.Name:sub(6) then continue end
		
		for j, beam in beamModel:GetChildren() do
			if beam.Name == "BeamPart" or not beam:IsA("BasePart") then continue end

			beam:Destroy()
		end
	end
end

function findClosestMediums(laser:typeof(simulationAssets.MediumRefraction.Laser), laserAngle:number) : (number|{number}?, number?, number?)
	if not mediumFolder then return nil, nil, nil end
	if not laserFolder then return nil, nil, nil end
	
	local medium = mediumFolder:FindFirstChild("Medium")::BasePart
	local direction = (90 - laserAngle) / math.abs(90 - laserAngle)
	
	if math.isinf(direction) then
		return nil, nil, nil
	end
	
	if direction == -1 then
		if medium.Position.Y + (medium.Size.Y / 2) >= laser.Blast.WorldPosition.Y then
			return nil, nil, nil
		else
			return medium.Position.Y + (medium.Size.Y / 2), direction, medium:GetAttribute("RefractiveIndex")
		end
	else
		if medium.Position.Y + (medium.Size.Y / 2) <= laser.Blast.WorldPosition.Y then
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

function createRefraction(laser:typeof(simulationAssets.MediumRefraction.Laser), n1:number, n2:number, directionY:number, incidentAngle:number, X:number, Y:number)
	if not beamFolder then return end
	if not laserFolder then return end
	
	local beamModel = beamFolder:FindFirstChild("BeamModel" .. laser.Name:sub(6), true)
	if not beamModel then return end
	
	local directionX = if math.abs(laser.Orientation.Z) < 90 then 1 elseif math.abs(laser.Orientation.Z) > 90 then -1 else 0
	local angleOfRefraction
	
	if n1 > n2 and incidentAngle > math.deg(math.asin(n2 / n1)) then
		directionY *= -1
		
		angleOfRefraction = incidentAngle
	else
		angleOfRefraction = math.deg(math.asin((n1 * math.sin(math.rad(incidentAngle))) / n2))
	end
	
	local beam = beamModel:FindFirstChild("BeamPart2")::BasePart

	if not beam then
		beam = simulationAssets.MediumRefraction.BeamPart:Clone()
		beam.Name = "BeamPart2"
		beam.Parent = beamModel
	end
	
	beam.Size = Vector3.new(1000, 0.1, 0.1)
	beam.CFrame = CFrame.new(laser.Blast.WorldPosition.X + (-1 * directionY * directionX * ((laser.Blast.WorldPosition.Y - Y) * math.tan(math.rad(incidentAngle)))) * if n1 > n2 and incidentAngle >= math.deg(math.asin(n2 / n1)) then -1 else 1, Y, -21.4) * CFrame.Angles(0, 0, math.rad(directionY * (90 - directionX * angleOfRefraction))) * CFrame.new((beam.Size.X / 2), 0, 0)
end

function createBeam(laser:typeof(simulationAssets.MediumRefraction.Laser))
	if not beamFolder then return end
	if not mediumFolder then return end
	if not laserFolder then return end
	if #workspace.Simulation:GetChildren() == 0 then return end
	
	local beamModel = beamFolder:FindFirstChild("BeamModel" .. laser.Name:sub(6), true)
	if not beamModel then return end
	
	local medium = mediumFolder:FindFirstChild("Medium")::BasePart
	local beam = beamModel:FindFirstChild("BeamPart")::BasePart
	
	local incidentAngle, direction = math.abs(math.abs(laser.Orientation.Z) - 90), laser.Orientation.Z / math.abs(laser.Orientation.Z)
	
	if math.isinf(direction) then
		beam.Size = Vector3.new(1000, 0.1, 0.1)
		
		clearRefractiveBeams(laser)
	else
		if direction == 1 then
			local medium, Y, n = findNextMediumAbove(laser.Blast.WorldPosition.Y)
			
			if not medium or not Y or not n then
				beam.Size = Vector3.new(1000, 0.1, 0.1)

				clearRefractiveBeams(laser)
			else
				local height = Y - laser.Blast.WorldPosition.Y
				local hypotenuse = height / math.cos(math.rad(incidentAngle))
				
				beam.Size = Vector3.new(hypotenuse, 0.1, 0.1)
				
				createRefraction(laser, findCurrentMedium(laser.Blast.WorldPosition.Y), n, direction, incidentAngle, laser.Blast.WorldPosition.X + ((laser.Blast.WorldPosition.Y - Y) * math.tan(math.rad(incidentAngle))), Y)
			end
		else
			local medium, Y, n = findNextMediumBelow(laser.Blast.WorldPosition.Y)
			
			if not medium or not Y or not n then
				beam.Size = Vector3.new(1000, 0.1, 0.1)

				clearRefractiveBeams(laser)
			else
				local height = laser.Blast.WorldPosition.Y - Y
				local hypotenuse = height / math.cos(math.rad(incidentAngle))

				beam.Size = Vector3.new(hypotenuse, 0.1, 0.1)
				
				createRefraction(laser, findCurrentMedium(laser.Blast.WorldPosition.Y), n, direction, incidentAngle, laser.Blast.WorldPosition.X + (height * math.tan(math.rad(incidentAngle))), Y)
			end
		end
	end
	
	beam.CFrame = laser.Blast.WorldCFrame * CFrame.new((beam.Size.X / 2), 0, 0)
end

function checkLaserSpaceBuffers(laser:typeof(simulationAssets.MediumRefraction.Laser))
	if not upperLimit then return end
	if not lowerLimit then return end
	if not laserFolder then return end
	
	if laser.Position.Y > upperLimit - 2.5 then
		laser.DragDetector.Enabled = false
		laser.Rotate.DragDetector.Enabled = false

		task.delay(0.75, function()
			laser.DragDetector.Enabled = true
			laser.Rotate.DragDetector.Enabled = true
		end)
		
		tweenService:Create(laser, TweenInfo.new(0.75, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = laser.Position - Vector3.new(0, 2.5, 0)}):Play()
		tweenService:Create(laser.Rotate, TweenInfo.new(0.75, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = laser.Rotate.Position - Vector3.new(0, 2.5, 0)}):Play()
	elseif laser.Position.Y < lowerLimit then
		laser.DragDetector.Enabled = false
		laser.Rotate.DragDetector.Enabled = false
		
		task.delay(0.75, function()
			laser.DragDetector.Enabled = true
			laser.Rotate.DragDetector.Enabled = true
		end)

		tweenService:Create(laser, TweenInfo.new(0.75, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = laser.Position + Vector3.new(0, 2.5, 0)}):Play()
		tweenService:Create(laser.Rotate, TweenInfo.new(0.75, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = laser.Rotate.Position + Vector3.new(0, 2.5, 0)}):Play()
	end
	
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.FilterDescendantsInstances = laserFolder:GetChildren()
	
	for i, laser in laserFolder:GetChildren()::{typeof(simulationAssets.MediumRefraction.Laser)} do
		if table.find(laserDebounce, laser) then continue end
		
		local overlappingParts = workspace:GetPartBoundsInRadius(laser.Position, 0.25, overlapParams)
		
		for i, otherLaser in ipairs(overlappingParts::{typeof(simulationAssets.MediumRefraction.Laser)}) do
			if not otherLaser:HasTag("LaserBase") or otherLaser == laser or table.find(laserDebounce, otherLaser) then continue end
			
			table.insert(laserDebounce, laser)
			table.insert(laserDebounce, otherLaser)
			
			laser.DragDetector.Enabled = false
			laser.Rotate.DragDetector.Enabled = false
			otherLaser.DragDetector.Enabled = false
			otherLaser.Rotate.DragDetector.Enabled = false

			task.delay(0.75, function()
				laser.DragDetector.Enabled = true
				laser.Rotate.DragDetector.Enabled = true
				otherLaser.DragDetector.Enabled = true
				otherLaser.Rotate.DragDetector.Enabled = true
				
				local a = table.find(laserDebounce, laser)
				if a then table.remove(laserDebounce, a) end
				local b = table.find(laserDebounce, otherLaser)
				if b then table.remove(laserDebounce, b) end
			end)
			
			local direction = if Vector3.new((laser.Position - otherLaser.Position).Unit.X, (laser.Position - otherLaser.Position).Unit.Y, 0).Magnitude > 1e-3 then Vector3.new((laser.Position - otherLaser.Position).Unit.X, (laser.Position - otherLaser.Position).Unit.Y, 0).Unit else Vector3.yAxis
			
			tweenService:Create(laser, TweenInfo.new(0.75, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {CFrame = laser.CFrame + direction * 0.5}):Play()
			tweenService:Create(laser.Rotate, TweenInfo.new(0.75, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {CFrame = laser.Rotate.CFrame + direction * 0.5}):Play()
			tweenService:Create(otherLaser, TweenInfo.new(0.75, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {CFrame = otherLaser.CFrame - direction * 0.5}):Play()
			tweenService:Create(otherLaser.Rotate, TweenInfo.new(0.75, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {CFrame = otherLaser.Rotate.CFrame - direction * 0.5}):Play()
		end
	end
end

function module.run()
	if not players.LocalPlayer then return end
	
	workspace.Camera.CameraType = Enum.CameraType.Scriptable
	workspace.Camera.CFrame = CFrame.new(0, 10, 0)
	
	laserFolder = Instance.new("Folder")
	laserFolder.Name = "Laser"
	laserFolder.IconTint = Color3.new(1, 0, 1)
	laserFolder.Parent = workspace.Simulation
	
	local laser = simulationAssets.MediumRefraction.Laser:Clone()
	laser.Name = "Laser" .. tostring(#laserFolder:GetChildren() + 1)
	laser.Parent = laserFolder
	
	beamFolder = Instance.new("Folder")
	beamFolder.Name = "Beam"
	beamFolder.IconTint = Color3.new(1, 0, 0)
	beamFolder.Parent = workspace.Simulation
	
	local highlightModel = Instance.new("Model")
	highlightModel.Name = "Hightlight"
	highlightModel.Parent = beamFolder
	
	local beamHighlight = simulationAssets.MediumRefraction.BeamHighlight:Clone()
	beamHighlight.Parent = highlightModel
	beamHighlight.Adornee = highlightModel
	
	local beamModel = Instance.new("Model")
	beamModel.Name = "BeamModel" .. tostring(#highlightModel:GetChildren())
	beamModel.Parent = highlightModel
	
	mediumFolder = Instance.new("Folder")
	mediumFolder.IconTint = Color3.new(0, 1, 1)
	mediumFolder.Name = "Medium"
	mediumFolder.Parent = workspace.Simulation
	
	local medium = simulationAssets.MediumRefraction.Medium:Clone()
	medium.Parent = mediumFolder
	
	local beam = simulationAssets.MediumRefraction.BeamPart:Clone()
	beam.Parent = beamModel
	
	gui = simulationAssets.MediumRefraction.RefractionMediumsUI:Clone()
	gui.Parent = players.LocalPlayer.PlayerGui
	
	upperLimit = workspace.Camera.CFrame.Position.Y + ((math.abs(workspace.Backdrop.Position.Z) - (workspace.Backdrop.Size.Z / 2)) * math.tan(math.rad(workspace.Camera.FieldOfView / 2)))
	lowerLimit = workspace.Camera.CFrame.Position.Y - ((math.abs(workspace.Backdrop.Position.Z) - (workspace.Backdrop.Size.Z / 2)) * math.tan(math.rad(workspace.Camera.FieldOfView / 2))) + 2.5
	
	indexBillboard = simulationAssets.MediumRefraction.IndexBillboard:Clone()
	indexBillboard.Adornee = workspace.WorldOrigin
	indexBillboard.ExtentsOffsetWorldSpace = Vector3.new(0, ((medium.Position.Y + (medium.Size.Y / 2)) + lowerLimit) / 2, medium.Position.Z * 2)
	indexBillboard.Parent = players.LocalPlayer.PlayerGui
	
	print(upperLimit, lowerLimit)
	
	indexBillboard.TextBox.FocusLost:Connect(function()
		if not indexBillboard then return end
		if not laserFolder then return end
		
		local newN = tonumber(indexBillboard.TextBox.Text)
		
		if not newN then
			medium:SetAttribute("RefractiveIndex", 1.5)
			
			for i, laser in ipairs(laserFolder:GetChildren()::{typeof(laser)}) do
				createBeam(laser)
			end
			
			return
		end
		
		medium:SetAttribute("RefractiveIndex", newN)
		
		for i, laser in ipairs(laserFolder:GetChildren()::{typeof(laser)}) do
			createBeam(laser)
		end
	end)
	
	medium:GetPropertyChangedSignal("Position"):Connect(function()
		if not upperLimit then return end
		if not lowerLimit then return end
		if not indexBillboard then return end
		
		indexBillboard.ExtentsOffsetWorldSpace = Vector3.new(0, ((medium.Position.Y + (medium.Size.Y / 2)) + lowerLimit) / 2, medium.Position.Z * 2)
		
		if medium.Position.Y + (medium.Size.Y / 2) > upperLimit then
			medium.DragDetector.Enabled = false
			
			tweenService:Create(medium, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = Vector3.new(medium.Position.X, upperLimit - (medium.Size.Y / 2) - 2.5, medium.Position.Z)}):Play()
			
			task.delay(0.5, function()
				medium.DragDetector.Enabled = true
			end)
		elseif medium.Position.Y + (medium.Size.Y / 2) < lowerLimit then
			medium.DragDetector.Enabled = false
			
			tweenService:Create(medium, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = Vector3.new(medium.Position.X, lowerLimit - (medium.Size.Y / 2) + 2.5, medium.Position.Z)}):Play()
			
			task.delay(0.5, function()
				medium.DragDetector.Enabled = true
			end)
		end
		
		if not laserFolder then return end
		
		for i, laser in ipairs(laserFolder:GetChildren()::{typeof(laser)}) do
			createBeam(laser)
		end
	end)
	
	laser.Changed:Connect(function()
		checkLaserSpaceBuffers(laser)
		createBeam(laser)
	end)
	
	laser.Rotate.Changed:Connect(function()
		checkLaserSpaceBuffers(laser)
		createBeam(laser)
	end)
	
	gui.TextButton.Activated:Connect(function()
		if not laserFolder then return end
		if not beamFolder then return end
		if not highlightModel then return end
		
		local newLaser = simulationAssets.MediumRefraction.Laser:Clone()
		newLaser.Name = "Laser" .. tostring(#laserFolder:GetChildren() + 1)
		newLaser.Parent = laserFolder
		
		local newBeamModel = Instance.new("Model")
		newBeamModel.Name = "BeamModel" .. tostring(#highlightModel:GetChildren())
		newBeamModel.Parent = highlightModel
		
		local newBeam = simulationAssets.MediumRefraction.BeamPart:Clone()
		newBeam.Parent = newBeamModel
		
		newLaser.Changed:Connect(function()
			checkLaserSpaceBuffers(newLaser)
			createBeam(newLaser)
		end)

		newLaser.Rotate.Changed:Connect(function()
			checkLaserSpaceBuffers(newLaser)
			createBeam(newLaser)
		end)
		
		checkLaserSpaceBuffers(newLaser)
		createBeam(newLaser)
	end)
	
	createBeam(laser)
end

function module.cleanup()
	if gui then
		gui:Destroy()
	end
end

return module
