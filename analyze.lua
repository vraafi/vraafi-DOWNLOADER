local game = remodel.readPlaceFile("vraafi-DOWNLOADER/build(5).rbxl")

-- Fix for Source property
print("---- ANALYZING SCRIPTS ----")
local function scanForMalicious(instance)
    if instance.ClassName == "Script" or instance.ClassName == "LocalScript" then
        -- Remodel exposes Script.Source but sometimes fails on specific script types if they don't have it
        local success, source = pcall(function() return instance.Source end)
        if success and type(source) == "string" then
            if string.find(source:lower(), "kick") or string.find(source:lower(), "require") then
                print("[WARNING] Suspicious script found: " .. instance.Name)
            end
        end
    end
    for _, child in ipairs(instance:GetChildren()) do
        scanForMalicious(child)
    end
end
scanForMalicious(game)

-- Analisis StarterGui untuk mencari spam
print("\n---- ANALYZING STARTERGUI ----")
local starterGui = game:GetService("StarterGui")
if starterGui then
    local guiCount = #starterGui:GetChildren()
    print("Total ScreenGuis in StarterGui: " .. tostring(guiCount))
    for _, gui in ipairs(starterGui:GetChildren()) do
        if gui.ClassName == "ScreenGui" then
             print(" - Found UI: " .. gui.Name)
        end
    end
else
    print("No StarterGui found")
end

-- Analisis Workspace untuk Baseplate / Spawn Location
print("\n---- ANALYZING WORKSPACE FLOOR ----")
local workspace = game:GetService("Workspace")
if workspace then
    local hasFloor = false
    local spawnLoc = nil

    for _, child in ipairs(workspace:GetChildren()) do
        if child.ClassName == "SpawnLocation" then
            spawnLoc = child
        end
        if child.Name == "Baseplate" or child.ClassName == "Terrain" then
            hasFloor = true
        end
        if child.ClassName == "Part" and child.Name:lower() == "baseplate" then
            hasFloor = true
        end
    end

    if not hasFloor then
        print("[ERROR] No obvious Floor (Baseplate/Terrain) found. Players might fall into the void!")
    else
        print("Floor detected.")
    end

    if not spawnLoc then
        print("[WARNING] No SpawnLocation found.")
    else
        print("SpawnLocation detected.")
    end
else
    print("No Workspace found")
end
