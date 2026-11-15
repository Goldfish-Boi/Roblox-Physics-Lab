--!strict
--!optimize 2

local tweenService = game:GetService("TweenService")
local collectionService = game:GetService("CollectionService")

local gui = script.Parent
local background = gui.Background
local canvas = gui.UI
local exit = gui.ExitSimulation
local scrollingFrame = canvas.ScrollingFrame

local debounce = false

function setUpSimulation(button:TextButton)
	local moduleToRun:InstanceHandle = button:GetAttribute("Module") 
	
	require(moduleToRun:Get()::ModuleScript).run()
	
	tweenService:Create(background.Container, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {GroupTransparency = 1}):Play()
	tweenService:Create(canvas, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {GroupTransparency = 1}):Play()
	tweenService:Create(exit, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.85, 0.025)}):Play()
	
	task.wait(0.5)
	
	canvas.Position = UDim2.fromScale(5, 5)
	background.Container.Position = UDim2.fromScale(5, 5)
end

function init()
	pcall(function()
		game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	end)
	
	tweenService:Create(background.Container.Scroll, TweenInfo.new(15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Position = UDim2.fromScale(0, -1)}):Play()

	task.spawn(function()
		while task.wait(15) do
			background.Container.Scroll.Position = UDim2.fromScale(0, 0)
		end
	end)
	
	exit.MouseEnter:Connect(function()
		tweenService:Create(exit.UICorner, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {CornerRadius = UDim.new(0, 0)}):Play()
	end)
	
	exit.MouseLeave:Connect(function()
		tweenService:Create(exit.UICorner, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {CornerRadius = UDim.new(0.25, 0)}):Play()
	end)
	
	exit.Activated:Connect(function()
		if debounce == true then return end
		
		debounce = true

		tweenService:Create(background.Container, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {GroupTransparency = 0}):Play()
		tweenService:Create(canvas, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {GroupTransparency = 0}):Play()
		tweenService:Create(exit, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = UDim2.fromScale(1.1, 0.025)}):Play()
		
		canvas.Position = UDim2.fromScale(0, 0)
		background.Container.Position = UDim2.fromScale(0, 0)

		task.wait(0.5)
		
		workspace.Simulation:ClearAllChildren()
		
		debounce = false
	end)
	
	for i, button in ipairs(scrollingFrame:GetChildren()) do
		if not button:IsA("TextButton") then continue end
		
		local frame = button:FindFirstChild("Frame")::Frame
		local uiStroke = frame:FindFirstChild("UIStroke")::UIStroke
		local imageLabel = frame:FindFirstChild("ImageLabel")::ImageLabel
		local textLabel = frame:FindFirstChild("TextLabel")::TextLabel
		
		button.MouseEnter:Connect(function()
			tweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.85, 0.85)}):Play()
			tweenService:Create(uiStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Thickness = 0.025}):Play()
		end)
		
		button.MouseLeave:Connect(function()
			tweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0.8, 0.8)}):Play()
			tweenService:Create(uiStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Thickness = 0.01}):Play()
		end)
		
		button.Activated:Connect(function()
			if debounce == true then return end

			debounce = true
			task.delay(1, function() debounce = false end)
			
			tweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, true, 0.5), {Size = UDim2.fromScale(1, 1)}):Play()
			tweenService:Create(uiStroke, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, true, 0.5), {Thickness = 0.05}):Play()
			
			task.wait(0.5)
			
			setUpSimulation(button)
		end)
	end
end

for i, child in ipairs(collectionService:GetTagged("Invisible")::{BasePart}) do
	child.Transparency = 1
end

init()