--!strict
--!optimize 2

local tweenService = game:GetService("TweenService")

local gui = script.Parent
local background = gui.Background
local canvas = gui.UI
local scrollingFrame = canvas.ScrollingFrame

function setUpSimulation(button:TextButton)
	local moduleToRun:InstanceHandle = button:GetAttribute("Module") 
	
	require(moduleToRun:Get()::ModuleScript).run()
	
	tweenService:Create(background.Container, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {GroupTransparency = 1}):Play()
	tweenService:Create(canvas, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {GroupTransparency = 1}):Play()
	
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
			tweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromScale(1, 1)}):Play()
			tweenService:Create(uiStroke, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Thickness = 0.05}):Play()
			
			task.wait(0.5)
			
			setUpSimulation(button)
		end)
	end
end

init()