local testScript = [[
-- Simulasi logika inventory & arena breakout wipe timer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local SERVER_MATCH_TIME = 150 * 60 -- 150 menit dalam detik
local currentMatchTime = SERVER_MATCH_TIME

-- Buat remote events untuk HUD Timer
local timerEvent = Instance.new("RemoteEvent")
timerEvent.Name = "MatchTimerUpdate"
timerEvent.Parent = ReplicatedStorage

-- Core Data (Simulasi)
local PlayerData = {}
-- PlayerData[UserId] = { MainBackpack = {}, SafeContainer = {}, LobbyStorage = {} }

-- LOOP TIMER SERVER UTAMA
task.spawn(function()
    while true do
        task.wait(1)
        currentMatchTime = currentMatchTime - 1
        timerEvent:FireAllClients(currentMatchTime)

        if currentMatchTime <= 0 then
            -- MATCH END / WIPE SERVER
            print("[SERVER] MATCH OVER! Membunuh semua pemain yang tidak terekstraksi!")
            for _, player in ipairs(Players:GetPlayers()) do
                local char = player.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    -- Cek apakah player di dunia fantasy (Y < 5000)
                    if char.HumanoidRootPart.Position.Y < 5000 then
                        -- Player gagal extract. Mati dan hilang isi tas utama.
                        char.Humanoid.Health = 0
                        print(player.Name .. " gagal terekstraksi. Tas hilang.")
                        -- PlayerData[player.UserId].MainBackpack = {}
                    end
                end
            end

            -- RESET DUNIA FANTASY (Ganti seed)
            -- Simulasi: Kita biarkan chunk loader bekerja dengan seed baru nanti
            currentMatchTime = SERVER_MATCH_TIME
            print("[SERVER] Dunia fantasy di-reset dengan seed baru!")
        end
    end
end)
print("Logic Timer Extraction Compiled")
]]
