local game = remodel.readPlaceFile("vraafi-DOWNLOADER/build(5).rbxl")
local ServerScriptService = game:GetService("ServerScriptService")
if not ServerScriptService then
    ServerScriptService = Instance.new("ServerScriptService")
    ServerScriptService.Name = "ServerScriptService"
    ServerScriptService.Parent = game
end

local masterManager = Instance.new("Script")
masterManager.Name = "MasterSpawnAndPortalManager"
local sourceCode = [[
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
        if teleportDebounce[player.UserId] and tick() - teleportDebounce[player.UserId] < 2 then
            return
        end
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
pcall(function() masterManager.Source = sourceCode end)
masterManager.Parent = ServerScriptService

pcall(function() remodel.writePlaceFile("Fixed_Game_V2.rbxl", game) end)
print("Game Doctor V2 applied successfully.")
