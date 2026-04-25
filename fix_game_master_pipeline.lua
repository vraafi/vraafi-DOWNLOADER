-- MASTER GAME DOCTOR PIPELINE (V8: ARENA BREAKOUT FULL OVERHAUL)
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
if StarterGui then
    for _, gui in ipairs(StarterGui:GetChildren()) do
        if gui.ClassName == "ScreenGui" then pcall(function() gui.Enabled = false end) end
    end
end
local itemStorage = ServerStorage:FindFirstChild("ItemStorage") or Instance.new("Folder")
itemStorage.Name = "ItemStorage"; itemStorage.Parent = ServerStorage
for _, obj in ipairs(Workspace:GetChildren()) do
    if obj:IsA("Model") or obj:IsA("Tool") then
        local n = obj.Name:lower()
        if n:match("weapon") or n:match("armor") or n:match("monster") or n:match("template") then
            if obj:IsA("Tool") then obj.Parent = ReplicatedStorage else obj.Parent = itemStorage end
        else
            for _, c in ipairs(obj:GetDescendants()) do
                if c:IsA("BasePart") and c.Material == Enum.Material.Neon and c.Transparency < 1 then c.Transparency = 1 end
            end
        end
    end
    if obj.ClassName == "SpawnLocation" then obj:Destroy() end
end

print("==== TAHAP 2: INVENTORY SERVER, TIMER, & EXTRACTION ZONES ====")
-- Buat struktur untuk RemoteEvents komunikasi tas
local eventFolder = ReplicatedStorage:FindFirstChild("BreakoutEvents") or Instance.new("Folder")
eventFolder.Name = "BreakoutEvents"; eventFolder.Parent = ReplicatedStorage

local timerEvent = Instance.new("RemoteEvent"); timerEvent.Name = "MatchTimerUpdate"; timerEvent.Parent = eventFolder
local equipBagEvent = Instance.new("RemoteEvent"); equipBagEvent.Name = "EquipBag"; equipBagEvent.Parent = eventFolder
local syncInvEvent = Instance.new("RemoteEvent"); syncInvEvent.Name = "SyncInventory"; syncInvEvent.Parent = eventFolder

local serverLogic = Instance.new("Script")
serverLogic.Name = "ArenaBreakoutServer"
local sCode = [[
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local evFolder = ReplicatedStorage:WaitForChild("BreakoutEvents")
local timerEvent = evFolder:WaitForChild("MatchTimerUpdate")
local syncInvEvent = evFolder:WaitForChild("SyncInventory")

local LOBBY_Y = 10000
local SERVER_MATCH_TIME = 150 * 60
local currentMatchTime = SERVER_MATCH_TIME
local matchSeed = os.time()

-- Database Struktur Inventori (Sangat Disederhanakan)
-- Dalam sistem asli ini menggunakan DataStoreService.
local PlayerData = {}

local BagTypes = {
    ["None"] = {slots = 4, color = BrickColor.new("Dark stone grey"), size = Vector3.new(0,0,0)},
    ["SlingBag"] = {slots = 9, color = BrickColor.new("Sand"), size = Vector3.new(1.5, 1.5, 0.8)},
    ["AssaultBackpack"] = {slots = 16, color = BrickColor.new("Camo"), size = Vector3.new(1.8, 2.2, 1.2)},
    ["RushTactical"] = {slots = 25, color = BrickColor.new("Black"), size = Vector3.new(2, 2.5, 1.5)}
}

-- Bangun Spaceship Lobby
local spaceship = Instance.new("Part"); spaceship.Name="SpaceshipSpawnFloor"; spaceship.Size=Vector3.new(300,5,300); spaceship.Position=Vector3.new(0,LOBBY_Y,0); spaceship.Anchored=true; spaceship.Locked=true; spaceship.BrickColor=BrickColor.new("Dark stone grey"); spaceship.Parent=Workspace
local spawnLoc = Instance.new("SpawnLocation"); spawnLoc.Name="SpaceshipSpawn"; spawnLoc.Size=Vector3.new(12,1,12); spawnLoc.Position=Vector3.new(0,LOBBY_Y+3,0); spawnLoc.Anchored=true; spawnLoc.Parent=Workspace
local portal = Instance.new("Part"); portal.Name="DeployPortal"; portal.Size=Vector3.new(10,15,2); portal.Position=Vector3.new(0,LOBBY_Y+10,-50); portal.Anchored=true; portal.CanCollide=false; portal.BrickColor=BrickColor.new("Magenta"); portal.Material=Enum.Material.Neon; portal.Parent=Workspace

local function updateVisualBag(character, bagType)
    local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    if not torso then return end

    local oldBag = character:FindFirstChild("VisualBackpack")
    if oldBag then oldBag:Destroy() end

    if bagType == "None" then return end

    local bagData = BagTypes[bagType]
    local bag = Instance.new("Part"); bag.Name="VisualBackpack"; bag.Size=bagData.size; bag.BrickColor=bagData.color; bag.Material=Enum.Material.Fabric; bag.CanCollide=false; bag.Massless=true
    local weld = Instance.new("WeldConstraint"); weld.Part0=torso; weld.Part1=bag; bag.CFrame=torso.CFrame * CFrame.new(0,0,0.7)
    bag.Parent = character; weld.Parent = bag
end

-- Simulating Player Setup
Players.PlayerAdded:Connect(function(player)
    PlayerData[player.UserId] = {
        EquippedBag = "AssaultBackpack", -- Default untuk test
        MainBackpackItems = {}, -- Yang hilang saat mati
        LobbyStorage = {} -- Aman di pesawat
    }

    player.CharacterAdded:Connect(function(character)
        task.wait(0.5)
        character:PivotTo(CFrame.new(0, LOBBY_Y + 5, 0))
        -- Kasih visual tas di Lobby untuk manajemen (atau dilepas)
        updateVisualBag(character, PlayerData[player.UserId].EquippedBag)
        syncInvEvent:FireClient(player, PlayerData[player.UserId])
    end)
end)

local deb = {}
portal.Touched:Connect(function(hit)
    local char = hit.Parent
    local player = Players:GetPlayerFromCharacter(char)
    if player and char:FindFirstChild("Humanoid") then
        if deb[player.UserId] and tick() - deb[player.UserId] < 2 then return end
        deb[player.UserId] = tick()
        local rootPart = char:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.AssemblyLinearVelocity = Vector3.zero
            rootPart.AssemblyAngularVelocity = Vector3.zero
            char:PivotTo(CFrame.new(2000, 150, 2000))
            print(player.Name .. " MENERJUN (DEPLOY) DENGAN TAS: " .. PlayerData[player.UserId].EquippedBag)
        end
    end
end)

local function spawnExtractionZones(seed)
    for _, v in ipairs(Workspace:GetChildren()) do
        if v.Name == "ExtractionZone" then v:Destroy() end
    end
    local rng = Random.new(seed)
    for i=1, 3 do
        local ex = 2000 + rng:NextInteger(-1500, 1500)
        local ez = 2000 + rng:NextInteger(-1500, 1500)
        local zone = Instance.new("Part")
        zone.Name = "ExtractionZone"; zone.Size = Vector3.new(30, 20, 30); zone.Position = Vector3.new(ex, 10, ez)
        zone.Anchored = true; zone.CanCollide = false; zone.Transparency = 0.5; zone.BrickColor = BrickColor.new("Bright green"); zone.Material = Enum.Material.Neon; zone.Parent = Workspace

        -- Perbaikan Glitch Timer Ekstraksi (Pengecekan Bounding Box alih-alih TouchEnded)
        task.spawn(function()
            local extractTimers = {}
            while zone.Parent do
                task.wait(1)
                -- Gunakan Spatial Query agar lebih akurat mendeteksi pemain di dalam zona (Tidak reset karena lompat/animasi)
                local partsInZone = Workspace:GetPartBoundsInBox(zone.CFrame, zone.Size)
                local currentPlayersInZone = {}

                for _, part in ipairs(partsInZone) do
                    local char = part.Parent
                    local p = Players:GetPlayerFromCharacter(char)
                    if p then
                        currentPlayersInZone[p.UserId] = p
                    end
                end

                -- Update Timer
                for uid, p in pairs(currentPlayersInZone) do
                    if not extractTimers[uid] then
                        extractTimers[uid] = 0
                        print(p.Name .. " mulai ekstraksi...")
                    else
                        extractTimers[uid] = extractTimers[uid] + 1
                        if extractTimers[uid] >= 10 then
                            -- EKSTRAKSI SUKSES
                            print(p.Name .. " BERHASIL EKSTRAKSI!")
                            if p.Character then p.Character:PivotTo(CFrame.new(0, LOBBY_Y+5, 0)) end
                            extractTimers[uid] = nil

                            -- Pindahkan barang dari MainBackpack ke LobbyStorage
                            -- (Simulasi)
                            syncInvEvent:FireClient(p, PlayerData[p.UserId])
                        end
                    end
                end

                -- Hapus timer pemain yang keluar zona
                for uid, _ in pairs(extractTimers) do
                    if not currentPlayersInZone[uid] then
                        extractTimers[uid] = nil
                        local p = Players:GetPlayerByUserId(uid)
                        if p then print(p.Name .. " membatalkan ekstraksi.") end
                    end
                end
            end
        end)
    end
end

spawnExtractionZones(matchSeed)

task.spawn(function()
    while true do
        task.wait(1)
        currentMatchTime = currentMatchTime - 1
        timerEvent:FireAllClients(currentMatchTime, matchSeed)

        if currentMatchTime <= 0 then
            for _, player in ipairs(Players:GetPlayers()) do
                local char = player.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    if char.HumanoidRootPart.Position.Y < 5000 then
                        -- MATI WIPE: Kehilangan tas dan isinya
                        char.Humanoid.Health = 0
                        PlayerData[player.UserId].EquippedBag = "None"
                        PlayerData[player.UserId].MainBackpackItems = {}
                        syncInvEvent:FireClient(player, PlayerData[player.UserId])
                    end
                end
            end
            currentMatchTime = SERVER_MATCH_TIME
            matchSeed = os.time()
            spawnExtractionZones(matchSeed)
        end
    end
end)
]]
pcall(function() serverLogic.Source = sCode end)
serverLogic.Parent = ServerScriptService


print("==== TAHAP 3: CLIENT HUD TIMER & CHUNK LOADER ====")
local clientHUD = Instance.new("LocalScript")
clientHUD.Name = "ArenaBreakoutClientHUD"
local hudCode = [[
local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local evFolder = ReplicatedStorage:WaitForChild("BreakoutEvents")
local timerEvent = evFolder:WaitForChild("MatchTimerUpdate")

local sg = Instance.new("ScreenGui"); sg.Name="MatchTimerHUD"; sg.Parent=PlayerGui
local lbl = Instance.new("TextLabel"); lbl.Size=UDim2.new(0,200,0,50); lbl.Position=UDim2.new(0,20,0,20); lbl.BackgroundTransparency=0.5; lbl.BackgroundColor3=Color3.new(0,0,0); lbl.TextColor3=Color3.new(1,0,0); lbl.TextScaled=true; lbl.Font=Enum.Font.Oswald; lbl.Parent=sg

local currentSeed = 0

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CHUNK_SIZE, BLOCK_SIZE, RENDER_DISTANCE = 100, 20, 4
local activeChunks = {}
local terrainFolder = Workspace:FindFirstChild("ProceduralTerrain") or Instance.new("Folder"); terrainFolder.Name="ProceduralTerrain"; terrainFolder.Parent=Workspace

timerEvent.OnClientEvent:Connect(function(timeSeconds, seed)
    local mins = math.floor(timeSeconds / 60)
    local secs = timeSeconds % 60
    lbl.Text = string.format("EXTRACTION IN: %02d:%02d", mins, secs)

    if currentSeed ~= seed then
        currentSeed = seed
        -- Perbaikan Glitch: Bersihkan Cache lama saat dunia di wipe!
        for key, chunk in pairs(activeChunks) do
            chunk:Destroy()
        end
        activeChunks = {}
    end
end)

local leafColors = {BrickColor.new("Dark green"), BrickColor.new("Shamrock"), BrickColor.new("Earth green"), BrickColor.new("Rust")}

local function generateChunk(chunkX, chunkZ)
    if currentSeed == 0 then return end
    local chunkKey = chunkX .. "_" .. chunkZ
    if activeChunks[chunkKey] then return end

    local chunkModel = Instance.new("Model"); chunkModel.Name = "Chunk_" .. chunkKey
    local originX = chunkX * CHUNK_SIZE
    local originZ = chunkZ * CHUNK_SIZE
    local rng = Random.new(currentSeed + chunkX + chunkZ)

    for x = originX, originX + CHUNK_SIZE - BLOCK_SIZE, BLOCK_SIZE do
        for z = originZ, originZ + CHUNK_SIZE - BLOCK_SIZE, BLOCK_SIZE do
            local riverNoise = math.abs(math.noise(x * 0.001, z * 0.001, currentSeed))
            local elevation = math.noise(x * 0.003, z * 0.003, currentSeed + 100) * 80
            local y = math.floor(elevation / BLOCK_SIZE) * BLOCK_SIZE
            local mat = Enum.Material.Grass; local col = BrickColor.new("Earth green"); local isWater = false

            if riverNoise < 0.05 then y = -20; mat = Enum.Material.Ice; col = BrickColor.new("Cyan"); isWater = true
            elseif riverNoise < 0.1 then y = y - 20; mat = Enum.Material.Sand; col = BrickColor.new("Cool yellow") end

            local block = Instance.new("Part"); block.Size = Vector3.new(BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE); block.Position = Vector3.new(x, y, z); block.Anchored = true; block.Material = mat; block.BrickColor = col; block.Parent = chunkModel

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
                    local frWall = Instance.new("Part"); frWall.Size=Vector3.new(10,bh,2); frWall.Position=Vector3.new(x+9,py+(bh/2),z-(bd/2)+1); frWall.Anchored=true; flWall.Parent=h
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
    local char = Player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root or root.Position.Y > 5000 then return end

    local px = math.floor(root.Position.X / CHUNK_SIZE)
    local pz = math.floor(root.Position.Z / CHUNK_SIZE)
    local inRadius = {}
    for cx = px - RENDER_DISTANCE, px + RENDER_DISTANCE do
        for cz = pz - RENDER_DISTANCE, pz + RENDER_DISTANCE do
            generateChunk(cx, cz); inRadius[cx .. "_" .. cz] = true
        end
    end
    for key, chunk in pairs(activeChunks) do
        if not inRadius[key] then chunk:Destroy(); activeChunks[key] = nil end
    end
end)
]]
pcall(function() clientHUD.Source = hudCode end)
clientHUD.Parent = starterPlayerScripts

print("==== TAHAP 4: MASTER MENU BINDING & INVENTORY UI ====")
local menuManager = Instance.new("LocalScript")
menuManager.Name = "MasterMenuManager"
local menuCode = [[
local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local syncInvEvent = ReplicatedStorage:WaitForChild("BreakoutEvents"):WaitForChild("SyncInventory")

local masterMenu = Instance.new("ScreenGui"); masterMenu.Name = "GameDoctorMasterMenu"; masterMenu.Parent = PlayerGui
local menuBar = Instance.new("Frame"); menuBar.Size = UDim2.new(0, 300, 0, 50); menuBar.Position = UDim2.new(0.5, -150, 1, -60); menuBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30); menuBar.Parent = masterMenu
local listLayout = Instance.new("UIListLayout"); listLayout.FillDirection = Enum.FillDirection.Horizontal; listLayout.Parent = menuBar

local cats = {
    {name="Shop", icon="rbxassetid://6031280882", keywords={"shop","store"}},
    {name="Inventory", icon="rbxassetid://6031225815", keywords={"inventory","backpack"}},
    {name="Quest", icon="rbxassetid://6031280882", keywords={"quest","mission"}},
    {name="Social", icon="rbxassetid://6031262772", keywords={"inbox"}},
    {name="System", icon="rbxassetid://6031225815", keywords={"setting","system"}}
}
local categoryGuis = {Shop={}, Inventory={}, Quest={}, Social={}, System={}}

-- Dynamic Inventory Frame (Breakout Style)
local dynInv = Instance.new("Frame"); dynInv.Name = "DynamicInventoryUI"; dynInv.Size = UDim2.new(0, 400, 0, 400); dynInv.Position = UDim2.new(0.5, -200, 0.5, -200); dynInv.BackgroundColor3 = Color3.fromRGB(40,40,40); dynInv.Visible = false; dynInv.Parent = masterMenu
local title = Instance.new("TextLabel"); title.Size = UDim2.new(1, 0, 0, 30); title.Text = "Inventory (Bag: None)"; title.BackgroundColor3 = Color3.fromRGB(20,20,20); title.TextColor3 = Color3.new(1,1,1); title.Parent = dynInv
local scroll = Instance.new("ScrollingFrame"); scroll.Size = UDim2.new(1, -20, 1, -40); scroll.Position = UDim2.new(0, 10, 0, 35); scroll.BackgroundTransparency = 1; scroll.Parent = dynInv
local gl = Instance.new("UIGridLayout"); gl.CellSize = UDim2.new(0, 60, 0, 60); gl.Parent = scroll
table.insert(categoryGuis["Inventory"], dynInv)

local BagTypes = {
    ["None"] = 4, ["SlingBag"] = 9, ["AssaultBackpack"] = 16, ["RushTactical"] = 25
}

syncInvEvent.OnClientEvent:Connect(function(pData)
    title.Text = "Inventory (Bag: " .. pData.EquippedBag .. ")"
    for _, c in ipairs(scroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end

    local slots = BagTypes[pData.EquippedBag] or 4
    for i = 1, slots do
        local slot = Instance.new("Frame"); slot.BackgroundColor3 = Color3.fromRGB(60,60,60); slot.Parent = scroll
        local lbl = Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1; lbl.TextColor3=Color3.new(1,1,1); lbl.Text=tostring(i); lbl.Parent = slot
    end
end)

for _, gui in ipairs(PlayerGui:GetChildren()) do
    if gui:IsA("ScreenGui") and gui.Name ~= "GameDoctorMasterMenu" and gui.Name ~= "MatchTimerHUD" then
        gui.Enabled = false
        local catName = "System"
        for _, cat in ipairs(cats) do for _, kw in ipairs(cat.keywords) do if gui.Name:lower():match(kw) then catName = cat.name break end end end
        table.insert(categoryGuis[catName], gui)

        for _, child in ipairs(gui:GetDescendants()) do
            if child:IsA("Frame") and child.Visible then
                 local xBtn = Instance.new("TextButton"); xBtn.Size=UDim2.new(0,30,0,30); xBtn.Position=UDim2.new(1,-30,0,0); xBtn.Text="X"; xBtn.BackgroundColor3=Color3.new(1,0,0); xBtn.Parent=child
                 xBtn.MouseButton1Click:Connect(function() child.Visible = false end)
            end
        end
    end
end

local activeCat = nil
for _, cat in ipairs(cats) do
    local btn = Instance.new("ImageButton"); btn.Size = UDim2.new(0, 50, 0, 50); btn.Image = cat.icon; btn.Parent = menuBar
    btn.MouseButton1Click:Connect(function()
        if activeCat == cat.name then
            for _, g in ipairs(categoryGuis[cat.name]) do if g:IsA("ScreenGui") then g.Enabled=false else g.Visible=false end end; activeCat = nil
        else
            if activeCat then for _, g in ipairs(categoryGuis[activeCat]) do if g:IsA("ScreenGui") then g.Enabled=false else g.Visible=false end end end
            activeCat = cat.name; for _, g in ipairs(categoryGuis[cat.name]) do if g:IsA("ScreenGui") then g.Enabled=true else g.Visible=true end end
        end
    end)
end
]]
pcall(function() menuManager.Source = menuCode end)
menuManager.Parent = starterPlayerScripts

pcall(function() remodel.writePlaceFile("Fixed_Game_Final.rbxl", game) end)
print("\n[SUCCESS] Master Pipeline V8 (Tarkov/Arena Breakout Core) Complete.")
