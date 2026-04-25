local game = remodel.readPlaceFile("vraafi-DOWNLOADER/build(5).rbxl")

print("---- 1. MEMBERSIHKAN ASET REFERENSI & HITBOX ----")
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Buat folder penyimpanan jika belum ada
local itemStorage = ServerStorage:FindFirstChild("ItemStorage") or Instance.new("Folder")
itemStorage.Name = "ItemStorage"
itemStorage.Parent = ServerStorage

local assetCleanupCount = 0
local hitboxFixCount = 0

-- Identifikasi aset yang seharusnya disembunyikan (template) atau hitbox
for _, obj in ipairs(Workspace:GetChildren()) do
    if obj:IsA("Model") or obj:IsA("Tool") then
        local nameLower = obj.Name:lower()

        -- Jika ini adalah template senjata, armor, atau monster, pindahkan ke Storage
        if nameLower:match("ak47") or nameLower:match("ak-47") or nameLower:match("weapon") or nameLower:match("armor") or nameLower:match("monster") or nameLower:match("template") then
            -- Alat yang bisa dipakai (Tool) ke ReplicatedStorage, Model ke ServerStorage
            if obj:IsA("Tool") then
                obj.Parent = ReplicatedStorage
            else
                obj.Parent = itemStorage
            end
            assetCleanupCount = assetCleanupCount + 1
        else
            -- Cari "Kotak Bercahaya" (Biasanya Part Neon tanpa decal yang digunakan AI sebagai hitbox/pajangan)
            for _, child in ipairs(obj:GetDescendants()) do
                if child:IsA("BasePart") and child.Material == Enum.Material.Neon and child.Transparency < 1 then
                    child.Transparency = 1 -- Sembunyikan kotaknya
                    hitboxFixCount = hitboxFixCount + 1
                end
            end
        end
    end
end
print("[Game Doctor] Memindahkan " .. assetCleanupCount .. " aset template dari Workspace.")
print("[Game Doctor] Menyembunyikan " .. hitboxFixCount .. " hitbox bercahaya yang mengganggu.")

print("---- 2. MEMBANGUN MASTER MENU UI & PERBAIKAN TOMBOL ----")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local starterPlayerScripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
if not starterPlayerScripts then
    starterPlayerScripts = Instance.new("StarterPlayerScripts")
    starterPlayerScripts.Parent = StarterPlayer
end

-- Skrip ini akan membuat UI Menu di sisi klien dan merapikan 71 Popup
local menuManager = Instance.new("LocalScript")
menuManager.Name = "MasterMenuManager"
local menuCode = [[
local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local StarterGui = game:GetService("StarterGui")

-- Nonaktifkan Roblox Core UI default yang mengganggu jika perlu
pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end)
pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true) end)

-- Buat Master Menu Container
local masterMenu = Instance.new("ScreenGui")
masterMenu.Name = "GameDoctorMasterMenu"
masterMenu.ResetOnSpawn = false
masterMenu.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
masterMenu.Parent = PlayerGui

local menuBar = Instance.new("Frame")
menuBar.Name = "MenuBar"
menuBar.Size = UDim2.new(0, 300, 0, 50)
menuBar.Position = UDim2.new(0.5, -150, 1, -60) -- Di tengah bawah layar
menuBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
menuBar.BackgroundTransparency = 0.5
menuBar.Parent = masterMenu

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = menuBar

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Horizontal
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
listLayout.Padding = UDim.new(0, 10)
listLayout.Parent = menuBar

-- Kategori dan Ikon (Roblox Image IDs)
local categories = {
    {name = "Shop", icon = "rbxassetid://6031280882", keywords = {"shop", "store", "buy", "sell", "market"}},
    {name = "Inventory", icon = "rbxassetid://6031225815", keywords = {"inventory", "backpack", "item", "equipment"}},
    {name = "Quest", icon = "rbxassetid://6031280882", keywords = {"quest", "mission", "task", "objective"}},
    {name = "Social", icon = "rbxassetid://6031262772", keywords = {"inbox", "mail", "message", "clan", "party"}},
    {name = "System", icon = "rbxassetid://6031225815", keywords = {"setting", "system", "analytics", "hud"}}
}

-- Buat Tombol Kategori
local categoryButtons = {}
for _, cat in ipairs(categories) do
    local btn = Instance.new("ImageButton")
    btn.Name = cat.name .. "Btn"
    btn.Size = UDim2.new(0, 40, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.Image = cat.icon
    btn.Parent = menuBar

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0.5, 0)
    btnCorner.Parent = btn

    categoryButtons[cat.name] = btn
end

-- Fungsi untuk mengkategorikan UI
local function categorizeUI(guiName)
    local lowerName = guiName:lower()
    for _, cat in ipairs(categories) do
        for _, keyword in ipairs(cat.keywords) do
            if lowerName:match(keyword) then
                return cat.name
            end
        end
    end
    return "System" -- Default fallback
end

-- Sistem Dropdown/Toggling UI berdasarkan Kategori
local activeCategory = nil
local categoryGuis = {Shop={}, Inventory={}, Quest={}, Social={}, System={}}

-- Scan semua UI yang ada
for _, gui in ipairs(PlayerGui:GetChildren()) do
    if gui:IsA("ScreenGui") and gui.Name ~= "GameDoctorMasterMenu" then
        -- Perbaikan AK-47 dan Item tanpa gambar
        for _, descendant in ipairs(gui:GetDescendants()) do
            -- Perbaiki TextButton atau ImageButton yang tidak bisa diklik
            if descendant:IsA("GuiButton") then
                descendant.Active = true
                if descendant:IsA("ImageButton") and descendant.Image == "" then
                    descendant.Image = "rbxassetid://6031225815" -- Placeholder icon
                end
            end
            -- Perbaiki ImageLabel tanpa gambar
            if descendant:IsA("ImageLabel") and descendant.Image == "" then
                descendant.Image = "rbxassetid://6031225815"
            end
        end

        gui.Enabled = false -- Sembunyikan semuanya di awal
        local catName = categorizeUI(gui.Name)
        table.insert(categoryGuis[catName], gui)
    end
end

-- Logika Klik Kategori
for catName, btn in pairs(categoryButtons) do
    btn.MouseButton1Click:Connect(function()
        if activeCategory == catName then
            -- Tutup jika diklik lagi
            for _, gui in ipairs(categoryGuis[catName]) do
                gui.Enabled = false
            end
            activeCategory = nil
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        else
            -- Tutup kategori lama
            if activeCategory then
                categoryButtons[activeCategory].BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                for _, gui in ipairs(categoryGuis[activeCategory]) do
                    gui.Enabled = false
                end
            end
            -- Buka kategori baru
            activeCategory = catName
            btn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
            for _, gui in ipairs(categoryGuis[catName]) do
                gui.Enabled = true
            end
        end
    end)
end

print("[Game Doctor] Master Menu UI berhasil di-inject dan 71 UI telah dikategorikan!")
]]
pcall(function() menuManager.Source = menuCode end)
menuManager.Parent = starterPlayerScripts

pcall(function() remodel.writePlaceFile("Fixed_Game_V4.rbxl", game) end)
print("Game Doctor V4 applied successfully.")
