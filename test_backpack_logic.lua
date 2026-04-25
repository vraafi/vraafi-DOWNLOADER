local backpackLogic = [[
local function attachBackpack(character)
    if character:FindFirstChild("VisualBackpack") then return end

    local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    if not torso then return end

    local bag = Instance.new("Part")
    bag.Name = "VisualBackpack"
    bag.Size = Vector3.new(1.5, 2, 1)
    bag.BrickColor = BrickColor.new("Camo")
    bag.Material = Enum.Material.Fabric
    bag.CanCollide = false
    bag.Massless = true

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = torso
    weld.Part1 = bag

    bag.CFrame = torso.CFrame * CFrame.new(0, 0, 0.7) -- Pasang di punggung
    bag.Parent = character
    weld.Parent = bag
end
]]
