local game = remodel.readPlaceFile("vraafi-DOWNLOADER/build(5).rbxl")

print("---- MENGANALISIS INTERAKTIVITAS ASET (Workspace) ----")
local workspace = game:GetService("Workspace")
local interactiveCount = 0
local function scanInteractivity(instance)
    if instance.ClassName == "ProximityPrompt" or instance.ClassName == "ClickDetector" then
        interactiveCount = interactiveCount + 1
        print("  [✓] Mekanik ditemukan: " .. instance.Name .. " pada " .. instance.Parent.Name)
    end
    for _, child in ipairs(instance:GetChildren()) do
        scanInteractivity(child)
    end
end
scanInteractivity(workspace)
if interactiveCount == 0 then
    print("  [!] PERINGATAN: Tidak ada ProximityPrompt/ClickDetector. Aset di Workspace mungkin hanya PAJANGAN (tidak bisa diinteraksi).")
else
    print("  Total " .. interactiveCount .. " titik interaksi aset ditemukan. Aset BEKERJA!")
end

print("\n---- MENGANALISIS FUNGSI UI (StarterGui) ----")
local starterGui = game:GetService("StarterGui")
local uiScriptsCount = 0
local emptyGuiCount = 0

local function scanUI(instance, isRootScreenGui)
    local hasLogic = false

    -- Check for scripts inside this UI tree
    local function findScripts(node)
        if node.ClassName == "LocalScript" then
            hasLogic = true
            uiScriptsCount = uiScriptsCount + 1
        end
        for _, child in ipairs(node:GetChildren()) do
            findScripts(child)
        end
    end
    findScripts(instance)

    if isRootScreenGui and not hasLogic then
        emptyGuiCount = emptyGuiCount + 1
        -- print("  [X] UI Pajangan/Kosong: " .. instance.Name)
    end
end

if starterGui then
    for _, gui in ipairs(starterGui:GetChildren()) do
        if gui.ClassName == "ScreenGui" then
             scanUI(gui, true)
        end
    end
    print("  Total LocalScript UI (Logika) ditemukan: " .. uiScriptsCount)
    print("  Total UI Pajangan (Tanpa Script): " .. emptyGuiCount)
    if uiScriptsCount == 0 then
        print("  [!] PERINGATAN: Semua UI adalah PAJANGAN karena tidak ada LocalScript penggerak.")
    end
end
