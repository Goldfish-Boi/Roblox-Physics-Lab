--!strict
--!optimize 2

local tweenService = game:GetService("TweenService")

local gui = script.Parent
local background = gui.Background

tweenService:Create(background.Container.Scroll, TweenInfo.new(15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Position = UDim2.fromScale(0, -1)}):Play()

task.spawn(function()
	while task.wait(15) do
		background.Container.Scroll.Position = UDim2.fromScale(0, 0)
	end
end)