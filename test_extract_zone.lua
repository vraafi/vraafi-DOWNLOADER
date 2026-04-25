local testZone = [[
local Workspace = game:GetService("Workspace")

local LOBBY_Y = 10000

local function createExtractionZone(x, z)
    local zone = Instance.new("Part")
    zone.Name = "ExtractionZone"
    zone.Size = Vector3.new(20, 10, 20)
    zone.Position = Vector3.new(x, 5, z)
    zone.Anchored = true
    zone.CanCollide = false
    zone.Transparency = 0.5
    zone.BrickColor = BrickColor.new("Bright green")
    zone.Material = Enum.Material.Neon
    zone.Parent = Workspace

    -- Efek partikel asap hijau ala Arena Breakout
    local pe = Instance.new("ParticleEmitter")
    pe.Color = ColorSequence.new(Color3.new(0, 1, 0))
    pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 5)})
    pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1)})
    pe.Lifetime = NumberRange.new(2, 4)
    pe.Rate = 20
    pe.Speed = NumberRange.new(5, 10)
    pe.Parent = zone

    -- Logika 10 Detik
    local playersInZone = {} -- [UserId] = waktu masuk

    zone.Touched:Connect(function(hit)
        local char = hit.Parent
        local player = game.Players:GetPlayerFromCharacter(char)
        if player and not playersInZone[player.UserId] then
            playersInZone[player.UserId] = tick()
            print(player.Name .. " memasuki zona ekstraksi. Tahan 10 detik!")

            -- Bisa kirim RemoteEvent ke client untuk nampilin UI bar 10 detik
        end
    end)

    zone.TouchEnded:Connect(function(hit)
        local char = hit.Parent
        local player = game.Players:GetPlayerFromCharacter(char)
        if player and playersInZone[player.UserId] then
            playersInZone[player.UserId] = nil
            print(player.Name .. " keluar dari zona. Ekstraksi batal.")
        end
    end)

    -- Loop pengecekan
    task.spawn(function()
        while task.wait(0.5) do
            for userId, enterTime in pairs(playersInZone) do
                local elapsed = tick() - enterTime
                if elapsed >= 10 then
                    local player = game.Players:GetPlayerByUserId(userId)
                    if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        print(player.Name .. " BERHASIL EKSTRAKSI!")
                        player.Character:PivotTo(CFrame.new(0, LOBBY_Y + 5, 0))
                        playersInZone[userId] = nil

                        -- Simpan MainBackpack ke LobbyStorage
                        -- PlayerData[userId].LobbyStorage = merge(LobbyStorage, MainBackpack)
                        -- PlayerData[userId].MainBackpack = {}
                    end
                end
            end
        end
    end)
end
]]
