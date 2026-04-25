-- Kita tes logika arsitek kompleks sebelum dimasukkan ke master pipeline
local worldBuilder = [[
local Workspace = game:GetService("Workspace")
local rng = Random.new()

-- Fungsi untuk membuat bangunan yang bisa dimasuki (Hollow Box)
local function createAccessibleBuilding(x, z, width, depth, height)
    local wallThickness = 2
    local doorWidth = 6
    local doorHeight = 8

    local buildingModel = Instance.new("Model")
    buildingModel.Name = "AccessibleBuilding"

    -- Lantai
    local floor = Instance.new("Part")
    floor.Size = Vector3.new(width, 1, depth)
    floor.Position = Vector3.new(x, 0.5, z)
    floor.Anchored = true
    floor.BrickColor = BrickColor.new("Medium stone grey")
    floor.Material = Enum.Material.WoodPlanks
    floor.Parent = buildingModel

    -- Atap
    local roof = Instance.new("Part")
    roof.Size = Vector3.new(width + 2, 1, depth + 2)
    roof.Position = Vector3.new(x, height + 0.5, z)
    roof.Anchored = true
    roof.BrickColor = BrickColor.new("Rust")
    roof.Material = Enum.Material.Slate
    roof.Parent = buildingModel

    -- Dinding Kiri (Z axis)
    local leftWall = Instance.new("Part")
    leftWall.Size = Vector3.new(wallThickness, height, depth)
    leftWall.Position = Vector3.new(x - (width/2) + (wallThickness/2), height/2, z)
    leftWall.Anchored = true
    leftWall.BrickColor = BrickColor.new("Brick yellow")
    leftWall.Parent = buildingModel

    -- Dinding Kanan
    local rightWall = Instance.new("Part")
    rightWall.Size = Vector3.new(wallThickness, height, depth)
    rightWall.Position = Vector3.new(x + (width/2) - (wallThickness/2), height/2, z)
    rightWall.Anchored = true
    rightWall.BrickColor = BrickColor.new("Brick yellow")
    rightWall.Parent = buildingModel

    -- Dinding Belakang (X axis)
    local backWall = Instance.new("Part")
    backWall.Size = Vector3.new(width - (wallThickness*2), height, wallThickness)
    backWall.Position = Vector3.new(x, height/2, z + (depth/2) - (wallThickness/2))
    backWall.Anchored = true
    backWall.BrickColor = BrickColor.new("Brick yellow")
    backWall.Parent = buildingModel

    -- Dinding Depan (dengan pintu di tengah)
    local frontLeftWall = Instance.new("Part")
    local frontWallWidth = (width - doorWidth - (wallThickness*2)) / 2
    frontLeftWall.Size = Vector3.new(frontWallWidth, height, wallThickness)
    frontLeftWall.Position = Vector3.new(x - (width/2) + (wallThickness/2) + (frontWallWidth/2), height/2, z - (depth/2) + (wallThickness/2))
    frontLeftWall.Anchored = true
    frontLeftWall.BrickColor = BrickColor.new("Brick yellow")
    frontLeftWall.Parent = buildingModel

    local frontRightWall = Instance.new("Part")
    frontRightWall.Size = Vector3.new(frontWallWidth, height, wallThickness)
    frontRightWall.Position = Vector3.new(x + (width/2) - (wallThickness/2) - (frontWallWidth/2), height/2, z - (depth/2) + (wallThickness/2))
    frontRightWall.Anchored = true
    frontRightWall.BrickColor = BrickColor.new("Brick yellow")
    frontRightWall.Parent = buildingModel

    -- Bagian atas pintu
    local topDoorWall = Instance.new("Part")
    topDoorWall.Size = Vector3.new(doorWidth, height - doorHeight, wallThickness)
    topDoorWall.Position = Vector3.new(x, height - ((height - doorHeight)/2), z - (depth/2) + (wallThickness/2))
    topDoorWall.Anchored = true
    topDoorWall.BrickColor = BrickColor.new("Brick yellow")
    topDoorWall.Parent = buildingModel

    -- Lampu Plafon Interior
    local ceilingLight = Instance.new("Part")
    ceilingLight.Size = Vector3.new(4, 0.5, 4)
    ceilingLight.Position = Vector3.new(x, height - 0.2, z)
    ceilingLight.Anchored = true
    ceilingLight.BrickColor = BrickColor.new("Institutional white")
    ceilingLight.Material = Enum.Material.Neon
    ceilingLight.Parent = buildingModel

    local plight = Instance.new("PointLight")
    plight.Color = Color3.fromRGB(255, 255, 220)
    plight.Range = 25
    plight.Brightness = 1.5
    plight.Parent = ceilingLight

    buildingModel.Parent = Workspace
    return buildingModel
end

-- Generator Pohon Varian Acak (100+ jenis ilusi)
local leafColors = {
    BrickColor.new("Dark green"), BrickColor.new("Shamrock"),
    BrickColor.new("Camo"), BrickColor.new("Earth green"),
    BrickColor.new("Rust"), BrickColor.new("Bright yellow")
}

local function createRandomTree(x, z)
    local height = rng:NextInteger(15, 40)
    local trunkThick = rng:NextNumber(2, 4)
    local leafSize = rng:NextInteger(15, 30)
    local lColor = leafColors[rng:NextInteger(1, #leafColors)]

    local tree = Instance.new("Model")
    tree.Name = "RandomTree"

    local trunk = Instance.new("Part")
    trunk.Size = Vector3.new(trunkThick, height, trunkThick)
    trunk.Position = Vector3.new(x, height/2, z)
    trunk.Anchored = true
    trunk.BrickColor = BrickColor.new("Brown")
    trunk.Material = Enum.Material.Wood
    trunk.Parent = tree

    local leaves = Instance.new("Part")
    leaves.Shape = Enum.PartType.Ball
    leaves.Size = Vector3.new(leafSize, leafSize, leafSize)
    leaves.Position = Vector3.new(x, height, z)
    leaves.Anchored = true
    leaves.BrickColor = lColor
    leaves.Material = Enum.Material.Grass
    leaves.Parent = tree

    tree.Parent = Workspace
end

-- Generator Tiang Lampu Jalan
local function createStreetLamp(x, z)
    local lamp = Instance.new("Model")
    lamp.Name = "StreetLamp"

    local pole = Instance.new("Part")
    pole.Size = Vector3.new(1, 15, 1)
    pole.Position = Vector3.new(x, 7.5, z)
    pole.Anchored = true
    pole.BrickColor = BrickColor.new("Dark stone grey")
    pole.Material = Enum.Material.Metal
    pole.Parent = lamp

    local bulb = Instance.new("Part")
    bulb.Shape = Enum.PartType.Ball
    bulb.Size = Vector3.new(2, 2, 2)
    bulb.Position = Vector3.new(x, 15.5, z)
    bulb.Anchored = true
    bulb.BrickColor = BrickColor.new("New Yeller")
    bulb.Material = Enum.Material.Neon
    bulb.Parent = lamp

    local pointLight = Instance.new("PointLight")
    pointLight.Color = Color3.fromRGB(255, 255, 200)
    pointLight.Range = 40
    pointLight.Brightness = 2
    pointLight.Parent = bulb

    lamp.Parent = Workspace
end

print("Test Architect logic compiled")
]]
