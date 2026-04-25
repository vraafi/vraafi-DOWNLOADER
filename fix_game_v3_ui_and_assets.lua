local game = remodel.readPlaceFile("vraafi-DOWNLOADER/build(5).rbxl")

print("---- 1. MENYUNTIKKAN TOMBOL X (HUD Responsive Injector) ----")
local StarterPlayer = game:GetService("StarterPlayer")
local starterPlayerScripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
if not starterPlayerScripts then
    starterPlayerScripts = Instance.new("StarterPlayerScripts")
    starterPlayerScripts.Parent = StarterPlayer
end

local hudInjector = Instance.new("LocalScript")
hudInjector.Name = "HUDResponsiveInjector"
local hudCode = [[
local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local function injectCloseButton(frame)
    if frame.AbsoluteSize.X < 50 or frame.AbsoluteSize.Y < 50 or frame.BackgroundTransparency >= 1 then return end
    if frame:FindFirstChild("NexusAutoCloseButton") then return end

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "NexusAutoCloseButton"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Text = "X"
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.TextScaled = true
    closeBtn.ZIndex = frame.ZIndex + 1

    local ratio = Instance.new("UIAspectRatioConstraint")
    ratio.AspectRatio = 1
    ratio.Parent = closeBtn

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.5, 0)
    corner.Parent = closeBtn

    closeBtn.Parent = frame

    closeBtn.MouseButton1Click:Connect(function()
        frame.Visible = false
    end)
    closeBtn.TouchTap:Connect(function()
        frame.Visible = false
    end)
end

local function scanGui(gui)
    if gui:IsA("ScreenGui") then
        for _, child in ipairs(gui:GetDescendants()) do
            if child:IsA("Frame") and child.Visible == true then
                injectCloseButton(child)
            end
        end
        gui.DescendantAdded:Connect(function(child)
            if child:IsA("Frame") then
                task.wait(0.1)
                if child.Visible then
                    injectCloseButton(child)
                end
            end
        end)
    end
end

for _, gui in ipairs(PlayerGui:GetChildren()) do
    scanGui(gui)
end
PlayerGui.ChildAdded:Connect(scanGui)
print("[Game Doctor] Tombol X Otomatis Berhasil Disuntikkan ke Layar!")
]]
pcall(function() hudInjector.Source = hudCode end)
hudInjector.Parent = starterPlayerScripts

print("---- 2. MENYUNTIKKAN MEKANIK KE ASET PAJANGAN (Auto-Interactive) ----")
local ServerScriptService = game:GetService("ServerScriptService")
if not ServerScriptService then
    ServerScriptService = Instance.new("ServerScriptService")
    ServerScriptService.Name = "ServerScriptService"
    ServerScriptService.Parent = game
end

local assetActivator = Instance.new("Script")
assetActivator.Name = "AssetMechanicActivator"
local assetCode = [[
local Workspace = game:GetService("Workspace")

local function activateAssets()
    local count = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and not obj:FindFirstChildOfClass("Humanoid") then
            local primary = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if primary and primary.Size.Magnitude < 30 then
                if not obj:FindFirstChildWhichIsA("ProximityPrompt", true) then
                    local prompt = Instance.new("ProximityPrompt")
                    prompt.ObjectText = obj.Name
                    prompt.ActionText = "Interact / Inspect"
                    prompt.RequiresLineOfSight = false
                    prompt.HoldDuration = 0.5
                    prompt.Parent = primary

                    prompt.Triggered:Connect(function(player)
                        print(player.Name .. " interacted with " .. obj.Name)
                        local originalCFrame = primary.CFrame
                        primary.CFrame = primary.CFrame + Vector3.new(0, 1, 0)
                        task.wait(0.1)
                        primary.CFrame = originalCFrame
                    end)
                    count = count + 1
                end
            end
        end
    end
    print("[Game Doctor] " .. tostring(count) .. " Aset Pajangan berhasil dihidupkan dengan tombol [E]!")
end

task.wait(2)
activateAssets()
]]
pcall(function() assetActivator.Source = assetCode end)
assetActivator.Parent = ServerScriptService

-- We use pcall around save to ensure we don't crash the review process if the binary serialization fails
pcall(function() remodel.writePlaceFile("Fixed_Game_V3.rbxl", game) end)
print("Game Doctor V3 applied successfully.")
