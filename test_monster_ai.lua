local monsterAICode = [[
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Master Script untuk semua Monster (di ServerScriptService)
local function injectMonsterAI(monsterModel)
    local humanoid = monsterModel:FindFirstChild("Humanoid")
    local rootPart = monsterModel:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return end

    -- Standarisasi Statistik (Level 100 Boss / Basic stats)
    humanoid.MaxHealth = 1000
    humanoid.Health = 1000
    humanoid.WalkSpeed = 14

    local damage = 25
    local aggroRange = 100
    local attackRange = 5

    local currentTarget = nil

    local function findNearestPlayer()
        local nearest = nil
        local shortestDistance = aggroRange

        for _, player in ipairs(Players:GetPlayers()) do
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 and char:FindFirstChild("HumanoidRootPart") then
                local dist = (char.HumanoidRootPart.Position - rootPart.Position).Magnitude
                if dist < shortestDistance then
                    shortestDistance = dist
                    nearest = char
                end
            end
        end
        return nearest
    end

    -- Pathfinding Loop
    task.spawn(function()
        while humanoid.Health > 0 and monsterModel.Parent do
            currentTarget = findNearestPlayer()

            if currentTarget then
                local targetRoot = currentTarget:FindFirstChild("HumanoidRootPart")
                local dist = (targetRoot.Position - rootPart.Position).Magnitude

                if dist <= attackRange then
                    -- Attack
                    currentTarget.Humanoid:TakeDamage(damage)
                    -- Simple attack animation via Tween
                    local origCF = rootPart.CFrame
                    rootPart.CFrame = rootPart.CFrame * CFrame.new(0, 0, -2)
                    task.wait(0.1)
                    rootPart.CFrame = origCF
                    task.wait(1) -- Cooldown
                else
                    -- Chase using Pathfinding
                    local path = PathfindingService:CreatePath({
                        AgentRadius = 2,
                        AgentHeight = 5,
                        AgentCanJump = true
                    })

                    pcall(function()
                        path:ComputeAsync(rootPart.Position, targetRoot.Position)
                        local waypoints = path:GetWaypoints()
                        if path.Status == Enum.PathStatus.Success and #waypoints > 1 then
                            humanoid:MoveTo(waypoints[2].Position)
                        else
                            -- Fallback direct walk
                            humanoid:MoveTo(targetRoot.Position)
                        end
                    end)
                end
            end
            task.wait(0.2)
        end
    end)
end

-- Inject into all existing monsters in Workspace
for _, obj in ipairs(workspace:GetDescendants()) do
    if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(obj) then
        -- This is an NPC/Monster
        injectMonsterAI(obj)
    end
end
]]
print("Monster AI Logic compiled")
