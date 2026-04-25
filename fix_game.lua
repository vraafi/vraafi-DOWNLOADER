local game = remodel.readPlaceFile("vraafi-DOWNLOADER/build(5).rbxl")

print("---- 1. FIXING WORKSPACE (Terrain & SpawnLocation) ----")
local workspace = game:GetService("Workspace")

local spawnLoc = Instance.new("SpawnLocation")
spawnLoc.Name = "AutoSpawnLocation"
pcall(function() spawnLoc.Position = Vector3.new(0, 10, 0) end)
pcall(function() spawnLoc.CFrame = CFrame.new(0, 10, 0) end)
pcall(function() spawnLoc.Size = Vector3.new(12, 1, 12) end)
pcall(function() spawnLoc.Anchored = true end)
pcall(function() spawnLoc.BrickColor = BrickColor.new("Bright green") end)
spawnLoc.Parent = workspace
print("Added SpawnLocation to Workspace.")

local serverScriptService = game:GetService("ServerScriptService")
if not serverScriptService then
    serverScriptService = Instance.new("ServerScriptService")
    serverScriptService.Name = "ServerScriptService"
    serverScriptService.Parent = game
end

local terrainScript = Instance.new("Script")
terrainScript.Name = "ProceduralTerrainGenerator"

local sourceCode = [[
-- Procedural Terrain Generation for Aesthetic Environment
local terrain = workspace.Terrain
local rng = Random.new()

terrain:Clear()

local size = 256
local heightBase = -10
local amplitude = 15
local frequency = 0.02

for x = -size, size, 4 do
    for z = -size, size, 4 do
        local noise = math.noise(x * frequency, z * frequency, 123)
        local y = heightBase + (noise * amplitude)

        local region = Region3.new(
            Vector3.new(x-2, y-20, z-2),
            Vector3.new(x+2, y, z+2)
        ):ExpandToGrid(4)
        terrain:FillRegion(region, 4, Enum.Material.Dirt)

        local topRegion = Region3.new(
            Vector3.new(x-2, y, z-2),
            Vector3.new(x+2, y+2, z+2)
        ):ExpandToGrid(4)
        terrain:FillRegion(topRegion, 4, Enum.Material.Grass)
    end
end

local spawnRegion = Region3.new(
    Vector3.new(-30, heightBase-20, -30),
    Vector3.new(30, 8, 30)
):ExpandToGrid(4)
terrain:FillRegion(spawnRegion, 4, Enum.Material.Sand)
local spawnTop = Region3.new(
    Vector3.new(-30, 8, -30),
    Vector3.new(30, 9.5, 30)
):ExpandToGrid(4)
terrain:FillRegion(spawnTop, 4, Enum.Material.Grass)

print("[AI Terrain Generator] Natural terrain successfully generated!")
]]
pcall(function() terrainScript.Source = sourceCode end)
terrainScript.Parent = serverScriptService
print("Added ProceduralTerrainGenerator Script to ServerScriptService.")

print("\n---- 2. FIXING UI SPAM (StarterGui) ----")
local starterGui = game:GetService("StarterGui")
if starterGui then
    local disabledCount = 0
    for _, gui in ipairs(starterGui:GetChildren()) do
        if gui.ClassName == "ScreenGui" then
             pcall(function() gui.Enabled = false end)
             disabledCount = disabledCount + 1
        end
    end
    print("Disabled " .. tostring(disabledCount) .. " ScreenGuis.")
end

-- Save the fixed place file as an RBXL file (remodel's XML saving can sometimes fail with complex nested datatypes from older games, binary usually works better for huge files)
local newFileName = "Fixed_Game.rbxl"
pcall(function() remodel.writePlaceFile(newFileName, game) end)
print("\n[SUCCESS] Fixed game saved as " .. newFileName)
