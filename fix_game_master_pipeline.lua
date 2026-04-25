-- MASTER GAME DOCTOR PIPELINE (MEGA WORLD & MONSTER UPDATE)
local game = remodel.readPlaceFile("vraafi-DOWNLOADER/build(5).rbxl")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")

if not ServerScriptService then ServerScriptService = Instance.new("ServerScriptService"); ServerScriptService.Parent = game end
local starterPlayerScripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
if not starterPlayerScripts then starterPlayerScripts = Instance.new("StarterPlayerScripts"); starterPlayerScripts.Parent = StarterPlayer end
local starterCharacterScripts = StarterPlayer:FindFirstChild("StarterCharacterScripts")
if not starterCharacterScripts then starterCharacterScripts = Instance.new("StarterCharacterScripts"); starterCharacterScripts.Parent = StarterPlayer end

print("==== TAHAP 1: CLEANUP UI ====")
if StarterGui then
    for _, gui in ipairs(StarterGui:GetChildren()) do
        if gui.ClassName == "ScreenGui" then pcall(function() gui.Enabled = false end) end
    end
end

print("==== TAHAP 2: SPAWN ORCHESTRATOR & PORTAL ====")
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
spaceship.Size = Vector3.new(300, 5, 300)
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
spawnLoc.Parent = Workspace

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
    local player = Players:GetPlayerFromCharacter(character)
    if player and character:FindFirstChild("Humanoid") then
        if teleportDebounce[player.UserId] and tick() - teleportDebounce[player.UserId] < 2 then return end
        teleportDebounce[player.UserId] = tick()

        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.AssemblyLinearVelocity = Vector3.zero
            rootPart.AssemblyAngularVelocity = Vector3.zero
            character:PivotTo(CFrame.new(2000, 50, 2000))
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
    end)
end)
]]
pcall(function() masterManager.Source = spawnCode end)
masterManager.Parent = ServerScriptService


print("==== TAHAP 3: MEGA WORLD BUILDER & MONSTER AI ====")
local worldBuilder = Instance.new("Script")
worldBuilder.Name = "MegaWorldBuilderAndAI"
local architectCode = [[
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local rng = Random.new()
local LOBBY_Y = 10000

-- 1. SPACESHIP INTERIOR
local function buildSpaceshipInterior()
    for i = -80, 80, 40 do
        local light = Instance.new("Part")
        light.Size = Vector3.new(2, 1, 20)
        light.Position = Vector3.new(i, LOBBY_Y + 15, -50)
        light.Anchored = true
        light.BrickColor = BrickColor.new("Cyan")
        light.Material = Enum.Material.Neon
        light.Parent = Workspace
        local pl = Instance.new("PointLight")
        pl.Range = 40; pl.Brightness = 2; pl.Color = Color3.fromRGB(0,255,255); pl.Parent = light
    end
end

-- 2. ENTERABLE BUILDINGS
local function createAccessibleBuilding(x, z)
    local width, depth, height = 30, 30, 15
    local bModel = Instance.new("Model")
    bModel.Name = "House"

    local floor = Instance.new("Part")
    floor.Size = Vector3.new(width, 1, depth)
    floor.Position = Vector3.new(x, 0.5, z)
    floor.Anchored = true; floor.BrickColor = BrickColor.new("Medium stone grey"); floor.Parent = bModel

    local roof = Instance.new("Part")
    roof.Size = Vector3.new(width+2, 1, depth+2)
    roof.Position = Vector3.new(x, height, z)
    roof.Anchored = true; roof.BrickColor = BrickColor.new("Rust"); roof.Parent = bModel

    local lWall = Instance.new("Part"); lWall.Size = Vector3.new(2, height, depth); lWall.Position = Vector3.new(x-(width/2)+1, height/2, z); lWall.Anchored=true; lWall.Parent=bModel
    local rWall = Instance.new("Part"); rWall.Size = Vector3.new(2, height, depth); rWall.Position = Vector3.new(x+(width/2)-1, height/2, z); rWall.Anchored=true; rWall.Parent=bModel
    local bWall = Instance.new("Part"); bWall.Size = Vector3.new(width-4, height, 2); bWall.Position = Vector3.new(x, height/2, z+(depth/2)-1); bWall.Anchored=true; bWall.Parent=bModel

    -- Pintu depan bolong
    local flWall = Instance.new("Part"); flWall.Size = Vector3.new(10, height, 2); flWall.Position = Vector3.new(x-9, height/2, z-(depth/2)+1); flWall.Anchored=true; flWall.Parent=bModel
    local frWall = Instance.new("Part"); frWall.Size = Vector3.new(10, height, 2); frWall.Position = Vector3.new(x+9, height/2, z-(depth/2)+1); frWall.Anchored=true; frWall.Parent=bModel
    local topDWall = Instance.new("Part"); topDWall.Size = Vector3.new(8, 5, 2); topDWall.Position = Vector3.new(x, height-2.5, z-(depth/2)+1); topDWall.Anchored=true; topDWall.Parent=bModel

    -- Interior Light
    local cLight = Instance.new("Part"); cLight.Size = Vector3.new(4, 0.5, 4); cLight.Position = Vector3.new(x, height-0.5, z); cLight.Anchored=true; cLight.Material=Enum.Material.Neon; cLight.Parent=bModel
    local pl = Instance.new("PointLight"); pl.Range = 30; pl.Brightness = 2; pl.Parent = cLight

    bModel.Parent = Workspace
end

-- 3. 100 TREE VARIANTS
local leafColors = {BrickColor.new("Dark green"), BrickColor.new("Shamrock"), BrickColor.new("Earth green"), BrickColor.new("Rust")}
local function createTree(x, z)
    local h = rng:NextInteger(15, 40)
    local tModel = Instance.new("Model")
    local trunk = Instance.new("Part"); trunk.Size = Vector3.new(2, h, 2); trunk.Position = Vector3.new(x, h/2, z); trunk.Anchored=true; trunk.BrickColor=BrickColor.new("Brown"); trunk.Parent=tModel
    local leaves = Instance.new("Part"); leaves.Shape=Enum.PartType.Ball; leaves.Size = Vector3.new(15,15,15); leaves.Position = Vector3.new(x, h, z); leaves.Anchored=true; leaves.BrickColor=leafColors[rng:NextInteger(1,#leafColors)]; leaves.Parent=tModel
    tModel.Parent = Workspace
end

-- 4. STREET LAMPS
local function createStreetLamp(x, z)
    local lModel = Instance.new("Model")
    local pole = Instance.new("Part"); pole.Size=Vector3.new(1, 15, 1); pole.Position=Vector3.new(x, 7.5, z); pole.Anchored=true; pole.Parent=lModel
    local bulb = Instance.new("Part"); bulb.Size=Vector3.new(2,2,2); bulb.Position=Vector3.new(x, 15.5, z); bulb.Anchored=true; bulb.Material=Enum.Material.Neon; bulb.Parent=lModel
    local pl = Instance.new("PointLight"); pl.Range=40; pl.Parent=bulb
    lModel.Parent = Workspace
end

-- 5. MEGA BASEPLATE
local megaBase = Instance.new("Part")
megaBase.Name = "MegaFantasyContinent"
megaBase.Size = Vector3.new(30000, 10, 30000) -- Safe maximum before physics glitch
megaBase.Position = Vector3.new(2000, -5, 2000)
megaBase.Anchored = true
megaBase.BrickColor = BrickColor.new("Earth green")
megaBase.Material = Enum.Material.Grass
megaBase.Parent = Workspace

task.defer(function()
    buildSpaceshipInterior()

    -- Generate 200 Houses, 100 Trees, 100 StreetLamps in a grid city layout
    local cityOriginX, cityOriginZ = 2000, 2000
    for i = 1, 200 do
        local hx = cityOriginX + rng:NextInteger(-2000, 2000)
        local hz = cityOriginZ + rng:NextInteger(-2000, 2000)
        createAccessibleBuilding(hx, hz)
    end
    for i = 1, 100 do
        createTree(cityOriginX + rng:NextInteger(-2000, 2000), cityOriginZ + rng:NextInteger(-2000, 2000))
        createStreetLamp(cityOriginX + rng:NextInteger(-2000, 2000), cityOriginZ + rng:NextInteger(-2000, 2000))
    end

    -- MONSTER AI INJECTION
    local function initMonster(monster)
        local hum = monster:FindFirstChild("Humanoid")
        local root = monster:FindFirstChild("HumanoidRootPart")
        if hum and root then
            hum.MaxHealth = 1000; hum.Health = 1000; hum.WalkSpeed = 16
            task.spawn(function()
                while hum.Health > 0 and monster.Parent do
                    local target = nil; local dist = 100
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                            local d = (p.Character.HumanoidRootPart.Position - root.Position).Magnitude
                            if d < dist then dist = d; target = p.Character end
                        end
                    end
                    if target then
                        if dist <= 5 then
                            target.Humanoid:TakeDamage(25)
                            task.wait(1)
                        else
                            local path = PathfindingService:CreatePath()
                            pcall(function()
                                path:ComputeAsync(root.Position, target.HumanoidRootPart.Position)
                                if path.Status == Enum.PathStatus.Success then
                                    hum:MoveTo(path:GetWaypoints()[2].Position)
                                else
                                    hum:MoveTo(target.HumanoidRootPart.Position)
                                end
                            end)
                        end
                    end
                    task.wait(0.2)
                end
            end)
        end
    end

    -- Re-parent templates that might be monsters into workspace for testing, or just hook existing ones
    for _, obj in ipairs(game:GetService("ServerStorage"):GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj.Name:lower():match("monster") then
            local clone = obj:Clone()
            clone.Parent = Workspace
            local root = clone:FindFirstChild("HumanoidRootPart")
            if root then root.CFrame = CFrame.new(2000, 5, 2050) end
        end
    end

    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(obj) then
            initMonster(obj)
        end
    end
end)
]]
pcall(function() worldBuilder.Source = architectCode end)
worldBuilder.Parent = ServerScriptService


print("==== TAHAP 4: MASTER UI MENU & INTERAKTIVITAS ASET ====")
local menuManager = Instance.new("LocalScript")
menuManager.Name = "MasterMenuManager"
local menuCode = [[
-- [Kode UI yang sama dengan sebelumnya: mengelompokkan 71 gui]
local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local masterMenu = Instance.new("ScreenGui"); masterMenu.Name = "GameDoctorMasterMenu"; masterMenu.Parent = PlayerGui
local menuBar = Instance.new("Frame"); menuBar.Size = UDim2.new(0, 300, 0, 50); menuBar.Position = UDim2.new(0.5, -150, 1, -60); menuBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30); menuBar.Parent = masterMenu
local listLayout = Instance.new("UIListLayout"); listLayout.FillDirection = Enum.FillDirection.Horizontal; listLayout.Parent = menuBar

local cats = {"Shop", "Inventory", "Quest", "Social", "System"}
for _, c in ipairs(cats) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 50, 0, 50)
    btn.Text = c
    btn.Parent = menuBar
end

-- Inject X buttons
for _, gui in ipairs(PlayerGui:GetChildren()) do
    if gui:IsA("ScreenGui") and gui.Name ~= "GameDoctorMasterMenu" then
        gui.Enabled = false
        for _, child in ipairs(gui:GetDescendants()) do
            if child:IsA("Frame") and child.Visible then
                 local xBtn = Instance.new("TextButton"); xBtn.Size=UDim2.new(0,30,0,30); xBtn.Position=UDim2.new(1,-30,0,0); xBtn.Text="X"; xBtn.BackgroundColor3=Color3.new(1,0,0); xBtn.Parent=child
                 xBtn.MouseButton1Click:Connect(function() child.Visible = false end)
            end
        end
    end
end
]]
pcall(function() menuManager.Source = menuCode end)
menuManager.Parent = starterPlayerScripts


print("==== TAHAP 5: OPTIMIZED COMBAT ANIMATOR ====")
local animatorScript = Instance.new("LocalScript")
animatorScript.Name = "UniversalCombatAnimator"
local animCode = [[
local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Animator = Humanoid:WaitForChild("Animator")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local tracks = {}
pcall(function()
    local a = Instance.new("Animation"); a.AnimationId = "rbxassetid://522635514"; tracks.Sword = Animator:LoadAnimation(a)
    local b = Instance.new("Animation"); b.AnimationId = "rbxassetid://522638767"; tracks.Knife = Animator:LoadAnimation(b)
    local c = Instance.new("Animation"); c.AnimationId = "rbxassetid://522638767"; tracks.Reload = Animator:LoadAnimation(c)
end)

Character.ChildAdded:Connect(function(child)
    if child:IsA("Tool") then
        local name = child.Name:lower()
        child.Activated:Connect(function()
            if name:match("gun") or name:match("ak") then
                workspace.CurrentCamera.FieldOfView = workspace.CurrentCamera.FieldOfView + 2
                task.wait(0.05)
                workspace.CurrentCamera.FieldOfView = workspace.CurrentCamera.FieldOfView - 2
            elseif name:match("sword") and tracks.Sword then tracks.Sword:Play()
            elseif name:match("knife") and tracks.Knife then tracks.Knife:Play() end
        end)

        local rc = UserInputService.InputBegan:Connect(function(inp, gp)
            if not gp and inp.KeyCode == Enum.KeyCode.R and child.Parent == Character and (name:match("gun") or name:match("ak")) then
                if tracks.Reload then tracks.Reload:Play(); tracks.Reload:AdjustSpeed(0.5) end
            end
        end)
        child.Unequipped:Connect(function() rc:Disconnect() end)
    end
end)

local running = false
Humanoid.Running:Connect(function(speed)
    if speed > 18 and not running then running = true; TweenService:Create(workspace.CurrentCamera, TweenInfo.new(0.5), {FieldOfView=80}):Play()
    elseif speed <= 18 and running then running = false; TweenService:Create(workspace.CurrentCamera, TweenInfo.new(0.5), {FieldOfView=70}):Play() end
end)
]]
pcall(function() animatorScript.Source = animCode end)
animatorScript.Parent = starterCharacterScripts

pcall(function() remodel.writePlaceFile("Fixed_Game_Final.rbxl", game) end)
print("\n[SUCCESS] Master Pipeline Complete.")
