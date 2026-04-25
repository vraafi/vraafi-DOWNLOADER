-- Menguji struktur data untuk Grid Inventory dan tipe Tas ala Arena Breakout
local backpackData = {
    ["Pockets"] = {
        name = "Pockets",
        slots = 4, -- 2x2 grid dasar
        visualMesh = nil
    },
    ["SlingBag"] = {
        name = "Sling Bag",
        slots = 9, -- 3x3
        visualMesh = "rbxassetid://12345678", -- Placeholder
        color = BrickColor.new("Sand")
    },
    ["AssaultBackpack"] = {
        name = "Assault Backpack",
        slots = 16, -- 4x4
        visualMesh = "rbxassetid://87654321",
        color = BrickColor.new("Camo")
    },
    ["RushTactical"] = {
        name = "Rush Tactical Bag",
        slots = 25, -- 5x5
        visualMesh = "rbxassetid://11223344",
        color = BrickColor.new("Black")
    }
}

-- Di dalam Server, setiap pemain memiliki profil inventory
-- PlayerData = { EquippedBag = "AssaultBackpack", GridItems = {}, LobbyStash = {} }
print("Backpack System Logic OK")
