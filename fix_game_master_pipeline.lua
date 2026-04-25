-- MASTER GAME DOCTOR PIPELINE
-- Skrip ini menggabungkan semua perbaikan (V1 - V5) secara sekuensial pada satu file memory sebelum menyimpannya.

local game = remodel.readPlaceFile("vraafi-DOWNLOADER/build(5).rbxl")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")

-- Ensure core directories exist
if not ServerScriptService then ServerScriptService = Instance.new("ServerScriptService"); ServerScriptService.Parent = game end
local starterPlayerScripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
if not starterPlayerScripts then starterPlayerScripts = Instance.new("StarterPlayerScripts"); starterPlayerScripts.Parent = StarterPlayer end
local starterCharacterScripts = StarterPlayer:FindFirstChild("StarterCharacterScripts")
if not starterCharacterScripts then starterCharacterScripts = Instance.new("StarterCharacterScripts"); starterCharacterScripts.Parent = StarterPlayer end


print("==== TAHAP 1: CLEANUP SPAM UI & ASET ====")
-- Hapus UI lama yang mengganggu
if StarterGui then
    for _, gui in ipairs(StarterGui:GetChildren()) do
        if gui.ClassName == "ScreenGui" then
             pcall(function() gui.Enabled = false end)
        end
    end
end

-- Bersihkan hitbox dan aset
local itemStorage = ServerStorage:FindFirstChild("ItemStorage") or Instance.new("Folder")
itemStorage.Name = "ItemStorage"
itemStorage.Parent = ServerStorage

for _, obj in ipairs(Workspace:GetChildren()) do
    if obj:IsA("Model") or obj:IsA("Tool") then
        local nameLower = obj.Name:lower()
        if nameLower:match("ak47") or nameLower:match("weapon") or nameLower:match("armor") or nameLower:match("monster") or nameLower:match("template") then
            if obj:IsA("Tool") then obj.Parent = ReplicatedStorage else obj.Parent = itemStorage end
        else
            for _, child in ipairs(obj:GetDescendants()) do
                if child:IsA("BasePart") and child.Material == Enum.Material.Neon and child.Transparency < 1 then
                    child.Transparency = 1
                end
            end
        end
    end
end


print("\n==== TAHAP 2: SPAWN ORCHESTRATOR & PORTAL ====")
for _, child in ipairs(Workspace:GetChildren()) do
    if child.ClassName == "SpawnLocation" then child:Destroy() end
end

local masterManager = Instance.new("Script")
masterManager.Name = "MasterSpawnAndPortalManager"
local spawnCode = [[
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LOBBY_Y = 10000

local spaceship = Instance.new("Part")
spaceship.Name = "SpaceshipSpawnFloor"
spaceship.Size = Vector3.new(200, 5, 200)
spaceship.Position = Vector3.new(0, LOBBY_Y, 0)
spaceship.Anchored = true
spaceship.Locked = true
spaceship.BrickColor = BrickColor.new("Dark stone grey")
spaceship.Material = Enum.Material.Metal
spaceship.Parent = Workspace

local spawnLoc = Instance.new("SpawnLocation")
spawnLoc.Name = "SpaceshipSpawn"
spawnLoc.Size = Vector3.new(12, 1, 12)
spawnLoc.Position = Vector3.new(0, LOBBY_Y + 3, 0)
spawnLoc.Anchored = true
spawnLoc.BrickColor = BrickColor.new("Bright blue")
spawnLoc.Material = Enum.Material.Neon
spawnLoc.Parent = Workspace

local fantasyBase = Workspace:FindFirstChild("Baseplate") or Workspace:FindFirstChild("Terrain")
if not fantasyBase then
    local newBase = Instance.new("Part")
    newBase.Name = "FantasyGround"
    newBase.Size = Vector3.new(1024, 10, 1024)
    newBase.Position = Vector3.new(2000, 0, 2000)
    newBase.Anchored = true
    newBase.BrickColor = BrickColor.new("Earth green")
    newBase.Material = Enum.Material.Grass
    newBase.Parent = Workspace
    fantasyBase = newBase
end

local portal = Instance.new("Part")
portal.Name = "FantasyPortal"
portal.Size = Vector3.new(10, 15, 2)
portal.Position = Vector3.new(0, LOBBY_Y + 10, -50)
portal.Anchored = true
portal.CanCollide = false
portal.BrickColor = BrickColor.new("Magenta")
portal.Material = Enum.Material.Neon
portal.Parent = Workspace

local teleportDebounce = {}
portal.Touched:Connect(function(hit)
    local character = hit.Parent
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local player = Players:GetPlayerFromCharacter(character)

    if humanoid and player and humanoid.Health > 0 then
        if teleportDebounce[player.UserId] and tick() - teleportDebounce[player.UserId] < 2 then return end
        teleportDebounce[player.UserId] = tick()

        local origin = Vector3.new(2000, 1000, 2000)
        local direction = Vector3.new(0, -2000, 0)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {character, spaceship, spawnLoc, portal}
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude

        local result = Workspace:Raycast(origin, direction, raycastParams)

        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.AssemblyLinearVelocity = Vector3.zero
            rootPart.AssemblyAngularVelocity = Vector3.zero
            if result then
                character:PivotTo(CFrame.new(result.Position + Vector3.new(0, 5, 0)))
            else
                character:PivotTo(CFrame.new(2000, 50, 2000))
            end
        end
    end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        task.wait(0.5)
        local rootPart = character:WaitForChild("HumanoidRootPart", 5)
        if rootPart then
            rootPart.AssemblyLinearVelocity = Vector3.zero
            rootPart.AssemblyAngularVelocity = Vector3.zero
            character:PivotTo(CFrame.new(0, LOBBY_Y + 5, 0))
        end
        local ff = Instance.new("ForceField")
        ff.Visible = true
        ff.Parent = character
        game.Debris:AddItem(ff, 5)
    end)
end)
]]
pcall(function() masterManager.Source = spawnCode end)
masterManager.Parent = ServerScriptService


print("\n==== TAHAP 3: WORLD ARCHITECT (DEKORASI) ====")
local worldBuilder = Instance.new("Script")
worldBuilder.Name = "WorldArchitectBuilder"
local architectCode = [[
local Workspace = game:GetService("Workspace")

local LOBBY_Y = 10000

local function buildSpaceshipInterior()
    -- Create structural elements safely
    for i = -80, 80, 40 do
        local light = Instance.new("Part")
        light.Name = "CabinLight"
        light.Size = Vector3.new(2, 1, 20)
        light.Position = Vector3.new(i, LOBBY_Y + 15, -50)
        light.Anchored = true
        light.BrickColor = BrickColor.new("Cyan")
        light.Material = Enum.Material.Neon
        light.Parent = Workspace

        local pointLight = Instance.new("PointLight")
        pointLight.Color = Color3.fromRGB(0, 255, 255)
        pointLight.Range = 40
        pointLight.Brightness = 2
        pointLight.Parent = light
    end

    local console = Instance.new("Part")
    console.Name = "ControlConsole"
    console.Size = Vector3.new(20, 4, 5)
    console.Position = Vector3.new(0, LOBBY_Y + 2, -80)
    console.Anchored = true
    console.BrickColor = BrickColor.new("Dark stone grey")
    console.Material = Enum.Material.Metal
    console.Parent = Workspace

    local screen = Instance.new("Part")
    screen.Name = "Screen"
    screen.Size = Vector3.new(18, 3, 1)
    screen.Position = Vector3.new(0, LOBBY_Y + 4, -78)
    screen.Anchored = true
    screen.BrickColor = BrickColor.new("Lime green")
    screen.Material = Enum.Material.Neon
    screen.Parent = Workspace
end

local function buildFantasyWorld()
    local originX, originZ = 2000, 2000

    local function createTree(x, z)
        local trunk = Instance.new("Part")
        trunk.Size = Vector3.new(2, 10, 2)
        trunk.Position = Vector3.new(x, 5, z)
        trunk.Anchored = true
        trunk.BrickColor = BrickColor.new("Brown")
        trunk.Parent = Workspace

        local leaves = Instance.new("Part")
        leaves.Shape = Enum.PartType.Ball
        leaves.Size = Vector3.new(12, 12, 12)
        leaves.Position = Vector3.new(x, 12, z)
        leaves.Anchored = true
        leaves.BrickColor = BrickColor.new("Dark green")
        leaves.Parent = Workspace
    end

    local function createHouse(x, z)
        local house = Instance.new("Part")
        house.Size = Vector3.new(20, 15, 20)
        house.Position = Vector3.new(x, 7.5, z)
        house.Anchored = true
        house.BrickColor = BrickColor.new("Cobblestone")
        house.Parent = Workspace

        local roof = Instance.new("Part")
        roof.Shape = Enum.PartType.Cylinder
        roof.Size = Vector3.new(22, 22, 22)
        roof.Position = Vector3.new(x, 15, z)
        roof.Rotation = Vector3.new(0, 0, 90)
        roof.Anchored = true
        roof.BrickColor = BrickColor.new("Bright red")
        roof.Parent = Workspace

        local torch = Instance.new("Part")
        torch.Size = Vector3.new(1, 3, 1)
        torch.Position = Vector3.new(x + 11, 8, z)
        torch.Anchored = true
        torch.BrickColor = BrickColor.new("New Yeller")
        torch.Parent = Workspace

        local fire = Instance.new("PointLight")
        fire.Color = Color3.fromRGB(255, 150, 0)
        fire.Range = 30
        fire.Brightness = 3
        fire.Parent = torch
    end

    local rng = Random.new()
    for i = 1, 10 do
        createTree(originX + rng:NextInteger(-100, 100), originZ + rng:NextInteger(-100, 100))
    end

    createHouse(originX + 50, originZ + 50)
    createHouse(originX - 50, originZ + 60)
    createHouse(originX + 20, originZ - 70)
end

-- Using task.defer instead of task.wait so we don't block server script init
task.defer(function()
    buildSpaceshipInterior()
    buildFantasyWorld()
end)
]]
pcall(function() worldBuilder.Source = architectCode end)
worldBuilder.Parent = ServerScriptService


print("\n==== TAHAP 4: MASTER UI MENU & INTERAKTIVITAS ASET ====")
local menuManager = Instance.new("LocalScript")
menuManager.Name = "MasterMenuManager"
local menuCode = [[
local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local masterMenu = Instance.new("ScreenGui")
masterMenu.Name = "GameDoctorMasterMenu"
masterMenu.ResetOnSpawn = false
masterMenu.Parent = PlayerGui

local menuBar = Instance.new("Frame")
menuBar.Name = "MenuBar"
menuBar.Size = UDim2.new(0, 300, 0, 50)
menuBar.Position = UDim2.new(0.5, -150, 1, -60)
menuBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
menuBar.Parent = masterMenu

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Horizontal
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.Padding = UDim.new(0, 10)
listLayout.Parent = menuBar

local categories = {
    {name = "Shop", icon = "rbxassetid://6031280882", keywords = {"shop", "store", "buy", "sell", "market"}},
    {name = "Inventory", icon = "rbxassetid://6031225815", keywords = {"inventory", "backpack", "item", "equipment"}},
    {name = "Quest", icon = "rbxassetid://6031280882", keywords = {"quest", "mission"}},
    {name = "Social", icon = "rbxassetid://6031262772", keywords = {"inbox", "mail", "message"}},
    {name = "System", icon = "rbxassetid://6031225815", keywords = {"setting", "system", "hud"}}
}

local categoryButtons = {}
local categoryGuis = {Shop={}, Inventory={}, Quest={}, Social={}, System={}}

local function categorizeUI(guiName)
    local lowerName = guiName:lower()
    for _, cat in ipairs(categories) do
        for _, kw in ipairs(cat.keywords) do
            if lowerName:match(kw) then return cat.name end
        end
    end
    return "System"
end

for _, gui in ipairs(PlayerGui:GetChildren()) do
    if gui:IsA("ScreenGui") and gui.Name ~= "GameDoctorMasterMenu" then
        for _, descendant in ipairs(gui:GetDescendants()) do
            if descendant:IsA("GuiButton") then
                descendant.Active = true
                if descendant:IsA("ImageButton") and descendant.Image == "" then
                    descendant.Image = "rbxassetid://6031225815"
                end
            end
            if descendant:IsA("ImageLabel") and descendant.Image == "" then
                descendant.Image = "rbxassetid://6031225815"
            end
        end
        gui.Enabled = false
        table.insert(categoryGuis[categorizeUI(gui.Name)], gui)
    end
end

local activeCategory = nil
for _, cat in ipairs(categories) do
    local btn = Instance.new("ImageButton")
    btn.Size = UDim2.new(0, 40, 0, 40)
    btn.Image = cat.icon
    btn.Parent = menuBar

    btn.MouseButton1Click:Connect(function()
        if activeCategory == cat.name then
            for _, gui in ipairs(categoryGuis[cat.name]) do gui.Enabled = false end
            activeCategory = nil
        else
            if activeCategory then
                for _, gui in ipairs(categoryGuis[activeCategory]) do gui.Enabled = false end
            end
            activeCategory = cat.name
            for _, gui in ipairs(categoryGuis[cat.name]) do gui.Enabled = true end
        end
    end)
end

-- Inject X Close Button capability
local function injectCloseButton(frame)
    if frame.AbsoluteSize.X < 50 or frame.BackgroundTransparency >= 1 then return end
    if frame:FindFirstChild("NexusAutoCloseButton") then return end

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "NexusAutoCloseButton"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.Text = "X"
    closeBtn.ZIndex = frame.ZIndex + 1
    closeBtn.Parent = frame

    closeBtn.MouseButton1Click:Connect(function() frame.Visible = false end)
end

for _, gui in ipairs(PlayerGui:GetChildren()) do
    if gui:IsA("ScreenGui") then
        for _, child in ipairs(gui:GetDescendants()) do
            if child:IsA("Frame") and child.Visible then injectCloseButton(child) end
        end
        gui.DescendantAdded:Connect(function(child)
            if child:IsA("Frame") then
                task.wait(0.1)
                if child.Visible then injectCloseButton(child) end
            end
        end)
    end
end
]]
pcall(function() menuManager.Source = menuCode end)
menuManager.Parent = starterPlayerScripts


local assetActivator = Instance.new("Script")
assetActivator.Name = "AssetMechanicActivator"
local assetCode = [[
local Workspace = game:GetService("Workspace")

task.defer(function()
    task.wait(5) -- allow dynamic building
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and not obj:FindFirstChildOfClass("Humanoid") then
            local primary = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if primary and primary.Size.Magnitude < 30 and not obj:FindFirstChildWhichIsA("ProximityPrompt", true) then
                local prompt = Instance.new("ProximityPrompt")
                prompt.ObjectText = obj.Name
                prompt.ActionText = "Inspect"
                prompt.Parent = primary
                prompt.Triggered:Connect(function()
                    local orig = primary.CFrame
                    primary.CFrame = orig + Vector3.new(0, 1, 0)
                    task.wait(0.1)
                    primary.CFrame = orig
                end)
            end
        end
    end
end)
]]
pcall(function() assetActivator.Source = assetCode end)
assetActivator.Parent = ServerScriptService

print("\n==== TAHAP 5: OPTIMIZED COMBAT ANIMATOR ====")
local animatorScript = Instance.new("LocalScript")
animatorScript.Name = "UniversalCombatAnimator"
local animCode = [[
local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Animator = Humanoid:WaitForChild("Animator")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Cache animasi untuk performa dan menghindari memory leak
local animations = {
    Sword = Instance.new("Animation"),
    Knife = Instance.new("Animation"),
    Reload = Instance.new("Animation")
}
animations.Sword.AnimationId = "rbxassetid://522635514"
animations.Knife.AnimationId = "rbxassetid://522638767"
animations.Reload.AnimationId = "rbxassetid://522638767"

-- Kami memuat Track hanya sekali
local loadedTracks = {}
pcall(function() loadedTracks.Sword = Animator:LoadAnimation(animations.Sword) end)
pcall(function() loadedTracks.Knife = Animator:LoadAnimation(animations.Knife) end)
pcall(function() loadedTracks.Reload = Animator:LoadAnimation(animations.Reload) end)

Character.ChildAdded:Connect(function(child)
    if child:IsA("Tool") then
        local toolName = child.Name:lower()

        local isGun = toolName:match("gun") or toolName:match("ak") or toolName:match("rifle") or toolName:match("pistol")
        local isSword = toolName:match("sword") or toolName:match("blade") or toolName:match("katana") or toolName:match("axe")
        local isKnife = toolName:match("knife") or toolName:match("dagger")

        child.Activated:Connect(function()
            if isGun then
                local cam = workspace.CurrentCamera
                cam.FieldOfView = cam.FieldOfView + 2
                task.wait(0.05)
                cam.FieldOfView = cam.FieldOfView - 2

            elseif isSword and loadedTracks.Sword then
                loadedTracks.Sword:Play()

            elseif isKnife and loadedTracks.Knife then
                loadedTracks.Knife:Play()
                loadedTracks.Knife:AdjustSpeed(1.5)
            end
        end)

        if isGun then
            local reloadConnection
            reloadConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if not gameProcessed and input.KeyCode == Enum.KeyCode.R and child.Parent == Character then
                    if loadedTracks.Reload then
                        loadedTracks.Reload:Play()
                        loadedTracks.Reload:AdjustSpeed(0.5)
                    end
                end
            end)

            child.Unequipped:Connect(function()
                if reloadConnection then reloadConnection:Disconnect() end
            end)
        end
    end
end)

local isRunning = false
Humanoid.Running:Connect(function(speed)
    if speed > 18 and not isRunning then
        isRunning = true
        TweenService:Create(workspace.CurrentCamera, TweenInfo.new(0.5), {FieldOfView = 80}):Play()
    elseif speed <= 18 and isRunning then
        isRunning = false
        TweenService:Create(workspace.CurrentCamera, TweenInfo.new(0.5), {FieldOfView = 70}):Play()
    end
end)
]]
pcall(function() animatorScript.Source = animCode end)
animatorScript.Parent = starterCharacterScripts

pcall(function() remodel.writePlaceFile("Fixed_Game_Final.rbxl", game) end)
print("\n[SUCCESS] Seluruh modul perbaikan telah dikompilasi ke dalam Fixed_Game_Final.rbxl")
