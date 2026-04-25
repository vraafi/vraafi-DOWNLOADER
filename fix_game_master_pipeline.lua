-- MASTER GAME DOCTOR PIPELINE (V6.1: FULL CONSOLIDATION)
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

print("==== TAHAP 1: CLEANUP UI & ASET ====")
-- Sembunyikan UI
if StarterGui then
    for _, gui in ipairs(StarterGui:GetChildren()) do
        if gui.ClassName == "ScreenGui" then pcall(function() gui.Enabled = false end) end
    end
end

-- Bersihkan hitbox dan pindahkan template ke storage
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


print("==== TAHAP 2: SPAWN ORCHESTRATOR ====")
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
            -- Teleport to procedural world height
            character:PivotTo(CFrame.new(0, 150, 0))
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


print("==== TAHAP 3: KALIMANTAN PROCEDURAL CHUNK BUILDER ====")
local worldBuilder = Instance.new("LocalScript")
worldBuilder.Name = "EndlessWorldChunkLoader"
local chunkCode = [[
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local SEED = 8888
local CHUNK_SIZE = 100
local RENDER_DISTANCE = 4
local BLOCK_SIZE = 20

local activeChunks = {}
local terrainFolder = Workspace:FindFirstChild("ProceduralTerrain") or Instance.new("Folder")
terrainFolder.Name = "ProceduralTerrain"
terrainFolder.Parent = Workspace

local leafColors = {BrickColor.new("Dark green"), BrickColor.new("Shamrock"), BrickColor.new("Earth green"), BrickColor.new("Rust")}

local function generateChunk(chunkX, chunkZ)
    local chunkKey = chunkX .. "_" .. chunkZ
    if activeChunks[chunkKey] then return end

    local chunkModel = Instance.new("Model")
    chunkModel.Name = "Chunk_" .. chunkKey
    local originX = chunkX * CHUNK_SIZE
    local originZ = chunkZ * CHUNK_SIZE
    local rng = Random.new(SEED + chunkX + chunkZ)

    for x = originX, originX + CHUNK_SIZE - BLOCK_SIZE, BLOCK_SIZE do
        for z = originZ, originZ + CHUNK_SIZE - BLOCK_SIZE, BLOCK_SIZE do
            local riverNoise = math.abs(math.noise(x * 0.001, z * 0.001, SEED))
            local elevation = math.noise(x * 0.003, z * 0.003, SEED + 100) * 80

            local y = math.floor(elevation / BLOCK_SIZE) * BLOCK_SIZE
            local mat = Enum.Material.Grass
            local col = BrickColor.new("Earth green")
            local isWater = false

            if riverNoise < 0.05 then
                y = -20; mat = Enum.Material.Ice; col = BrickColor.new("Cyan"); isWater = true
            elseif riverNoise < 0.1 then
                y = y - 20; mat = Enum.Material.Sand; col = BrickColor.new("Cool yellow")
            end

            local block = Instance.new("Part")
            block.Size = Vector3.new(BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE)
            block.Position = Vector3.new(x, y, z)
            block.Anchored = true; block.Material = mat; block.BrickColor = col; block.Parent = chunkModel

            if not isWater then
                local spawnChance = rng:NextNumber()
                if spawnChance > 0.95 then
                    local th = rng:NextInteger(20, 50)
                    local tree = Instance.new("Model")
                    local trunk = Instance.new("Part"); trunk.Size=Vector3.new(4,th,4); trunk.Position=Vector3.new(x, y+(BLOCK_SIZE/2)+(th/2), z); trunk.Anchored=true; trunk.BrickColor=BrickColor.new("Brown"); trunk.Parent=tree
                    local leaves = Instance.new("Part"); leaves.Shape=Enum.PartType.Ball; leaves.Size=Vector3.new(20,20,20); leaves.Position=Vector3.new(x, y+(BLOCK_SIZE/2)+th, z); leaves.Anchored=true; leaves.BrickColor=leafColors[rng:NextInteger(1,#leafColors)]; leaves.Parent=tree
                    tree.Parent = chunkModel
                elseif spawnChance < 0.02 and (y > 0) then
                    local h = Instance.new("Model")
                    local bw, bd, bh = 30, 30, 20
                    local py = y + (BLOCK_SIZE/2)
                    local floor = Instance.new("Part"); floor.Size=Vector3.new(bw,1,bd); floor.Position=Vector3.new(x,py,z); floor.Anchored=true; floor.Parent=h
                    local roof = Instance.new("Part"); roof.Size=Vector3.new(bw+2,1,bd+2); roof.Position=Vector3.new(x,py+bh,z); roof.Anchored=true; roof.Parent=h
                    local lWall = Instance.new("Part"); lWall.Size=Vector3.new(2,bh,bd); lWall.Position=Vector3.new(x-(bw/2)+1,py+(bh/2),z); lWall.Anchored=true; lWall.Parent=h
                    local rWall = Instance.new("Part"); rWall.Size=Vector3.new(2,bh,bd); rWall.Position=Vector3.new(x+(bw/2)-1,py+(bh/2),z); rWall.Anchored=true; rWall.Parent=h
                    local bWall = Instance.new("Part"); bWall.Size=Vector3.new(bw-4,bh,2); bWall.Position=Vector3.new(x,py+(bh/2),z+(bd/2)-1); bWall.Anchored=true; bWall.Parent=h
                    local flWall = Instance.new("Part"); flWall.Size=Vector3.new(10,bh,2); flWall.Position=Vector3.new(x-9,py+(bh/2),z-(bd/2)+1); flWall.Anchored=true; flWall.Parent=h
                    local frWall = Instance.new("Part"); frWall.Size=Vector3.new(10,bh,2); frWall.Position=Vector3.new(x+9,py+(bh/2),z-(bd/2)+1); frWall.Anchored=true; frWall.Parent=h
                    local light = Instance.new("PointLight"); light.Range=30; light.Brightness=2; light.Parent=roof
                    h.Parent = chunkModel
                elseif spawnChance > 0.90 and spawnChance <= 0.95 and (y > 0) then
                    local lp = Instance.new("Model")
                    local py = y + (BLOCK_SIZE/2)
                    local pole = Instance.new("Part"); pole.Size=Vector3.new(1, 15, 1); pole.Position=Vector3.new(x, py+7.5, z); pole.Anchored=true; pole.Parent=lp
                    local bulb = Instance.new("Part"); bulb.Size=Vector3.new(2,2,2); bulb.Position=Vector3.new(x, py+15, z); bulb.Anchored=true; bulb.Material=Enum.Material.Neon; bulb.Parent=lp
                    local pl = Instance.new("PointLight"); pl.Range=40; pl.Parent=bulb
                    lp.Parent = chunkModel
                end
            end
        end
    end
    chunkModel.Parent = terrainFolder
    activeChunks[chunkKey] = chunkModel
end

RunService.Heartbeat:Connect(function()
    local char = Players.LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root or root.Position.Y > 5000 then return end

    local px = math.floor(root.Position.X / CHUNK_SIZE)
    local pz = math.floor(root.Position.Z / CHUNK_SIZE)
    local inRadius = {}
    for cx = px - RENDER_DISTANCE, px + RENDER_DISTANCE do
        for cz = pz - RENDER_DISTANCE, pz + RENDER_DISTANCE do
            generateChunk(cx, cz)
            inRadius[cx .. "_" .. cz] = true
        end
    end
    for key, chunk in pairs(activeChunks) do
        if not inRadius[key] then chunk:Destroy(); activeChunks[key] = nil end
    end
end)
]]
pcall(function() worldBuilder.Source = chunkCode end)
worldBuilder.Parent = starterPlayerScripts


print("==== TAHAP 4: MASTER UI MENU & INTERAKTIVITAS ====")
local menuManager = Instance.new("LocalScript")
menuManager.Name = "MasterMenuManager"
local menuCode = [[
local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local masterMenu = Instance.new("ScreenGui"); masterMenu.Name = "GameDoctorMasterMenu"; masterMenu.Parent = PlayerGui
local menuBar = Instance.new("Frame"); menuBar.Size = UDim2.new(0, 300, 0, 50); menuBar.Position = UDim2.new(0.5, -150, 1, -60); menuBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30); menuBar.Parent = masterMenu
local listLayout = Instance.new("UIListLayout"); listLayout.FillDirection = Enum.FillDirection.Horizontal; listLayout.Parent = menuBar

local cats = {
    {name="Shop", icon="rbxassetid://6031280882", keywords={"shop","store","buy","sell","market"}},
    {name="Inventory", icon="rbxassetid://6031225815", keywords={"inventory","backpack","item","equipment"}},
    {name="Quest", icon="rbxassetid://6031280882", keywords={"quest","mission"}},
    {name="Social", icon="rbxassetid://6031262772", keywords={"inbox","mail","message"}},
    {name="System", icon="rbxassetid://6031225815", keywords={"setting","system","hud"}}
}
local categoryGuis = {Shop={}, Inventory={}, Quest={}, Social={}, System={}}

local function categorizeUI(guiName)
    local ln = guiName:lower()
    for _, cat in ipairs(cats) do
        for _, kw in ipairs(cat.keywords) do
            if ln:match(kw) then return cat.name end
        end
    end
    return "System"
end

-- Inject X buttons and categorize
for _, gui in ipairs(PlayerGui:GetChildren()) do
    if gui:IsA("ScreenGui") and gui.Name ~= "GameDoctorMasterMenu" then
        gui.Enabled = false
        for _, child in ipairs(gui:GetDescendants()) do
            if child:IsA("GuiButton") then
                child.Active = true
                if child:IsA("ImageButton") and child.Image == "" then child.Image = "rbxassetid://6031225815" end
            end
            if child:IsA("ImageLabel") and child.Image == "" then child.Image = "rbxassetid://6031225815" end

            if child:IsA("Frame") and child.Visible then
                 local xBtn = Instance.new("TextButton"); xBtn.Name = "NexusAutoCloseButton"
                 xBtn.Size=UDim2.new(0,30,0,30); xBtn.Position=UDim2.new(1,-30,0,0); xBtn.Text="X"; xBtn.BackgroundColor3=Color3.new(1,0,0); xBtn.Parent=child
                 xBtn.MouseButton1Click:Connect(function() child.Visible = false end)
            end
        end
        table.insert(categoryGuis[categorizeUI(gui.Name)], gui)
    end
end

-- Hook up menu buttons to categories
local activeCat = nil
for _, cat in ipairs(cats) do
    local btn = Instance.new("ImageButton")
    btn.Size = UDim2.new(0, 50, 0, 50)
    btn.Image = cat.icon
    btn.Parent = menuBar
    btn.MouseButton1Click:Connect(function()
        if activeCat == cat.name then
            for _, g in ipairs(categoryGuis[cat.name]) do g.Enabled = false end
            activeCat = nil
        else
            if activeCat then for _, g in ipairs(categoryGuis[activeCat]) do g.Enabled = false end end
            activeCat = cat.name
            for _, g in ipairs(categoryGuis[cat.name]) do g.Enabled = true end
        end
    end)
end
]]
pcall(function() menuManager.Source = menuCode end)
menuManager.Parent = starterPlayerScripts

-- Inject Auto-Interactive Prompts to Workspace Assets
local assetActivator = Instance.new("Script")
assetActivator.Name = "AssetMechanicActivator"
local assetCode = [[
local Workspace = game:GetService("Workspace")
task.defer(function()
    task.wait(5)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and not obj:FindFirstChildOfClass("Humanoid") then
            local primary = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if primary and primary.Size.Magnitude < 30 and not obj:FindFirstChildWhichIsA("ProximityPrompt", true) then
                local prompt = Instance.new("ProximityPrompt")
                prompt.ObjectText = obj.Name; prompt.ActionText = "Inspect"; prompt.Parent = primary
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


print("==== TAHAP 5: OPTIMIZED COMBAT ANIMATOR & MONSTER AI ====")
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

-- MONSTER AI
local monsterManager = Instance.new("Script")
monsterManager.Name = "GlobalMonsterManager"
local aiCode = [[
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")

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

-- Bind AI to all current and future monsters in workspace
for _, obj in ipairs(Workspace:GetChildren()) do
    if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(obj) then
        initMonster(obj)
    end
end

Workspace.ChildAdded:Connect(function(obj)
    task.wait(1) -- Wait for character to fully load
    if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(obj) then
        initMonster(obj)
    end
end)
]]
pcall(function() monsterManager.Source = aiCode end)
monsterManager.Parent = ServerScriptService

pcall(function() remodel.writePlaceFile("Fixed_Game_Final.rbxl", game) end)
print("\n[SUCCESS] Master Pipeline V6 Complete. (Includes AI, Interactive Assets, and working UI Menu)")
