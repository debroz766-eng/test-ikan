local Fluent = loadstring(game:HttpGet("https://github.com/zcuss/fluent-lib-reedit/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Barudak Fishit v 1.0",
    SubTitle = "by Zcus",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true, -- The blur may be detectable, setting this to false disables blur entirely
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl, -- Used when theres no MinimizeKeybind

    Icons = {
		AssetId = 131835214940124,
		Size = UDim2.fromOffset(50, 50),
		Position = UDim2.new(0, 20, 0, 20),
		Parent = GUI,
	}
})

local Tabs = {
    Fish = Window:AddTab({ Title = "Fish", Icon = "" }),
    Wtp = Window:AddTab({ Title = "World TP", Icon = "" }),
    Weather = Window:AddTab({ Title = "Weather Machine", Icon = "" }),
    Boats = Window:AddTab({ Title = "Spawn Boat", icon = "" }),
    Utilities = Window:AddTab({ Title = "Utilities", Icon = "⚙️" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}
local AutoFishSection = Tabs.Fish:AddSection("Auto Fish")
local AutoSellSection = Tabs.Fish:AddSection("Auto Sell")


local Options = Fluent.Options

-- ======================================
-- Fishing Script
-- ======================================
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

-- Tambahkan services yang diperlukan
local TeleportService = game:GetService("TeleportService")
local PlaceId = game.PlaceId
local JobId = game.JobId


-- Config
local Config = {
    ReelIdleTime = 3,
    AutoSellDelay = 10,
    Direction = -0.75,
    Power = 0.9923193947
}

local AutoFishing = false -- toggle state

-- Helper stop semua animasi
local function stopAll()
    for _, t in pairs(animator:GetPlayingAnimationTracks()) do
        t:Stop()
    end
end

-- Helper play animasi
-- local function playAnimation(animId)
--     stopAll()
--     local animation = Instance.new("Animation")
--     animation.AnimationId = animId
--     local track = animator:LoadAnimation(animation)
--     track:Play()
--     return track
-- end

-- Fishing Function (sekali eksekusi)
local function doFishingOnce()
    -- STEP 1: ChargeFishingRod
    local args1 = {tick()}
    game:GetService("ReplicatedStorage"):WaitForChild("Packages")
        :WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0")
        :WaitForChild("net"):WaitForChild("RF/ChargeFishingRod")
        :InvokeServer(unpack(args1))

    -- Reel Idle
    -- local reelTrack = playAnimation("rbxassetid://134965425664034")

    -- STEP 2: RequestFishingMinigameStarted
    local args2 = {Config.Direction, Config.Power}
    game:GetService("ReplicatedStorage"):WaitForChild("Packages")
        :WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0")
        :WaitForChild("net"):WaitForChild("RF/RequestFishingMinigameStarted")
        :InvokeServer(unpack(args2))

    task.wait(Config.ReelIdleTime)

    -- Stop Reel Idle
    -- if reelTrack then
    --     reelTrack:Stop()
    -- end

    -- STEP 3: FishingCompleted
    game:GetService("ReplicatedStorage"):WaitForChild("Packages")
        :WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0")
        :WaitForChild("net"):WaitForChild("RE/FishingCompleted")
        :FireServer()

    -- STEP 4: Idle Animasi
    -- playAnimation("rbxassetid://96586569072385")
end

-- AutoFishing Loop
task.spawn(function()
    while true do
        if AutoFishing then
            doFishingOnce()
            task.wait(1) -- delay antar mancing (bisa diatur)
        else
            task.wait(0.2)
        end
    end
end)

-- ======================================
-- UI Controls
-- ======================================

-- Input Delay Config
local InputDelay = AutoFishSection:AddInput("ReelIdleTime", {
    Title = "Auto Fish Delay [Sec]",
    Default = tostring(Config.ReelIdleTime),
    Placeholder = "Dont Change it",
    Numeric = true,
    Callback = function(Value)
        Config.ReelIdleTime = tonumber(Value) or Config.ReelIdleTime
    end
})

-- Toggle Auto Fishing
local ToggleAuto = AutoFishSection:AddToggle("AutoFishingToggle", {
    Title = "Auto Fishing",
    Default = false,
    Callback = function(Value)
        AutoFishing = Value
        if Value then
            Fluent:Notify({ Title = "Fishing", Content = "Auto Fishing ON", Duration = 4 })
        else
            Fluent:Notify({ Title = "Fishing", Content = "Auto Fishing OFF", Duration = 4 })
        end
    end
})

-- section auto Sell
-- Input Auto Sell Delay (dalam menit)
local InputDelay = AutoSellSection:AddInput("AutoSellDelay", {
    Title = "Auto Sell Delay [Min]",
    Default = tostring(Config.AutoSellDelay),
    Placeholder = "Dont Change it",
    Numeric = true,
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num > 0 then
            Config.AutoSellDelay = num
            Fluent:Notify({
                Title = "AutoSell",
                Content = "Delay set to "..Config.AutoSellDelay.." minute(s)",
                Duration = 4
            })
        else
            Fluent:Notify({
                Title = "AutoSell",
                Content = "Invalid input!",
                Duration = 4
            })
        end
    end
})

-- Toggle Auto Sell
local AutoSell = false
local ToggleAutoSell = AutoSellSection:AddToggle("AutoSellToggle", {
    Title = "Auto Sell",
    Default = false,
    Callback = function(Value)
        AutoSell = Value
        if Value then
            Fluent:Notify({
                Title = "AutoSell",
                Content = "Auto Sell ON (Delay: "..Config.AutoSellDelay.." min)",
                Duration = 4
            })

            -- jalankan loop AutoSell
            task.spawn(function()
                while AutoSell do
                    local success, err = pcall(function()
                        game:GetService("ReplicatedStorage")
                            :WaitForChild("Packages")
                            :WaitForChild("_Index")
                            :WaitForChild("sleitnick_net@0.2.0")
                            :WaitForChild("net")
                            :WaitForChild("RF/SellAllItems")
                            :InvokeServer()
                    end)
                    if success then
                        Fluent:Notify({
                            Title = "AutoSell",
                            Content = "Auto Sell Active",
                            Duration = 2
                        })
                    else
                        warn("AutoSell Error: " .. tostring(err))
                    end
                    task.wait(Config.AutoSellDelay * 60) -- konversi menit ke detik
                end
            end)
        else
            Fluent:Notify({
                Title = "AutoSell",
                Content = "Auto Sell OFF",
                Duration = 4
            })
        end
    end
})





local Players = game:GetService("Players")
local player = Players.LocalPlayer
local root = player.Character or player.CharacterAdded:Wait()
root = root:WaitForChild("HumanoidRootPart")

-- === DAFTAR LOKASI ===
-- =======================
-- Daftar teleport CFrame (urut sesuai list)
-- =======================
local teleportList = {
    ["Stingray Shores"] = CFrame.new(-13.2640066, 4.29577065, 2821.48682, 0.99168092, 0, -0.12872076, 0, 1.00000012, 0, 0.12872076, 0, 0.99168092),
    ["Tropical Grove"] = CFrame.new(-2164.48804, 6.37770081, 3626.59277, -0.656722546, 0, -0.75413233, 0, 1, 0, 0.75413233, 0, -0.656722546),
    ["Winter Fest"] = CFrame.new(),
    ["Kohana"] = CFrame.new(-683.985474, 3.0354929, 799.907593, -0.999713778, 0, 0.0239262339, 0, 1.00000012, 0, -0.0239262339, 0, -0.999713778),
    ["Kohana Volcano"] = CFrame.new(-601.147522, 59.0000572, 108.313446, -0.900374651, 0, 0.435115576, 0, 1, 0, -0.435115576, 0, -0.900374651),
    ["Esoteric Island"] = CFrame.new(),
    ["Esoteric Depths"] = CFrame.new(3207.48438, -1302.85486, 1409.95032, 0.935428143, 0, 0.353516877, 0, 1, 0, -0.353516877, 0, 0.935428143),
    ["Crystal Island"] = CFrame.new(),
    ["Coral Reefs"] = CFrame.new(-3153.79346, 2.40465546, 2127.73804, 0.978023469, 0, -0.208495244, 0, 1.00000012, 0, 0.208495274, 0, 0.97802335),
    ["Sisyphus Statue"] = CFrame.new(-3744.00195, -135.074417, -1010.22461, -0.983183146, 0, -0.182622537, 0, 1.00000012, 0, 0.182622537, 0, -0.983183146),
    ["Crater Island"] = CFrame.new(995.165283, 2.99178267, 5009.90039, -0.999866247, 0, -0.0163552333, 0, 1, 0, 0.0163552333, 0, -0.999866247),
    ["Treasure Room"] = CFrame.new(-3555.62085, -279.074219, -1673.78723, -0.697831035, 0, 0.71626246, 0, 1, 0, -0.71626246, 0, -0.697831035),
    ["Ocean"] = CFrame.new(-1499.17981, 3.49999976, 1912.60535, -0.850566864, 0, 0.525867045, 0, 1, 0, -0.525867105, 0, -0.850566745),
}

-- =======================
-- Buat list urut untuk dropdown
-- =======================
local locationNames = {
    "Stingray Shores",
    "Tropical Grove",
    "Winter Fest",
    "Kohana",
    "Kohana Volcano",
    "Esoteric Island",
    "Esoteric Depths",
    "Crystal Island",
    "Coral Reefs",
    "Sisyphus Statue",
    "Crater Island",
    "Treasure Room",
    "Ocean"
}

-- =======================
-- Dropdown Fluent
-- =======================
local Dropdown = Tabs.Wtp:AddDropdown("Dropdown", {
    Title = "Teleport Location",
    Values = locationNames,
    Multi = false,
    Default = 1
})

Dropdown:OnChanged(function(Value)
    selectedLocation = Value
    print("Selected:", Value)
end)

Tabs.Wtp:AddButton({
    Title = "Teleport",
    Description = "Teleport ke lokasi terpilih",
    Callback = function()
        if selectedLocation and teleportList[selectedLocation] then
            root.CFrame = teleportList[selectedLocation] + Vector3.new(0,3,0) -- sedikit naik biar ga nyangkut
            print("Teleported to:", selectedLocation)
        else
            warn("Lokasi tidak ditemukan!")
        end
    end
})

local boatNames = {
    3
}

local DropdownBoats = Tabs.Boats:AddDropdown("Dropdown", {
    Title = "Select Boat",
    Values = boatNames,
    Multi = false,
    Default = 1
})

DropdownBoats:OnChanged(function(Value)
    selectedBoats = Value
    print("Selected:", Value)
end)

local function summonBoat()
    local args1 = {selectedBoats}
    game:GetService("ReplicatedStorage"):WaitForChild("Packages")
        :WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0")
        :WaitForChild("net"):WaitForChild("RF/SpawnBoat")
        :InvokeServer(unpack(args1))
end

Tabs.Boats:AddButton({
    Title = "Spawn",
    Description = "Spawn boat terpilih",
    Callback = function()
        if selectedBoats then
            summonBoat()
        else
            warn("Boats tidak ditemukan!")
        end
    end
})

local function despawnBoat()
    local args1 = {selectedBoats}
    game:GetService("ReplicatedStorage"):WaitForChild("Packages")
        :WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0")
        :WaitForChild("net"):WaitForChild("RF/DespawnBoat")
        :InvokeServer(unpack(args1))
end

Tabs.Boats:AddButton({
    Title = "Despawn",
    Description = "Despawn boat terpilih",
    Callback = function()
        if selectedBoats then
            despawnBoat()
        else
            warn("Boats tidak ditemukan!")
        end
    end
})

-- ======================================
-- UTILITIES TAB - Tambahkan di sini
-- ======================================
local UtilitiesSection = Tabs.Utilities:AddSection("Server Utilities")

-- Fungsi Rejoin
local function rejoinServer()
    UtilitiesSection:AddButton({
        Title = "Rejoin Server",
        Description = "Rejoin current server atau game",
        Callback = function()
            if #Players:GetPlayers() <= 1 then
                Fluent:Notify({
                    Title = "Rejoin",
                    Content = "Rejoining game...",
                    Duration = 3
                })
                Players.LocalPlayer:Kick("\nRejoining...")
                wait(0.5)
                TeleportService:Teleport(PlaceId, Players.LocalPlayer)
            else
                Fluent:Notify({
                    Title = "Rejoin", 
                    Content = "Rejoining server instance...",
                    Duration = 3
                })
                TeleportService:TeleportToPlaceInstance(PlaceId, JobId, Players.LocalPlayer)
            end
        end
    })
end

-- Fungsi Server Hop (optional)
local function serverHop()
    UtilitiesSection:AddButton({
        Title = "Server Hop",
        Description = "Join random server",
        Callback = function()
            Fluent:Notify({
                Title = "Server Hop",
                Content = "Finding new server...",
                Duration = 4
            })
            
            -- Simple server hop implementation
            local servers = TeleportService:GetGameInstances(PlaceId)
            if #servers > 0 then
                local randomServer = servers[math.random(1, #servers)]
                TeleportService:TeleportToPlaceInstance(PlaceId, randomServer.JobId, Players.LocalPlayer)
            else
                Fluent:Notify({
                    Title = "Server Hop",
                    Content = "No servers found! Rejoining...",
                    Duration = 4
                })
                rejoinServer()
            end
        end
    })
end

-- Fungsi Reset Character
local function resetCharacter()
    UtilitiesSection:AddButton({
        Title = "Reset Character",
        Description = "Reset your character",
        Callback = function()
            local character = Players.LocalPlayer.Character
            if character then
                character:BreakJoints()
                Fluent:Notify({
                    Title = "Reset",
                    Content = "Character reset!",
                    Duration = 3
                })
            end
        end
    })
end

-- Panggil fungsi untuk membuat buttons
rejoinServer()
serverHop() -- Optional
resetCharacter()

-- ======================================
-- COMMAND SYSTEM (Optional) - Jika ingin sistem command seperti yang Anda minta
-- ======================================
local CommandsSection = Tabs.Utilities:AddSection("Chat Commands")

-- Sistem command handler
local commandHandlers = {}

function addcmd(command, aliases, callback)
    table.insert(commandHandlers, {
        command = command,
        aliases = aliases or {},
        callback = callback
    })
end

-- Setup chat listener untuk commands
local function setupChatCommands()
    local function onChatMessage(message, speaker)
        if string.sub(message, 1, 1) == ";" then -- Prefix command
            local args = {}
            for word in string.gmatch(message, "%S+") do
                table.insert(args, word)
            end
            
            local cmd = string.lower(string.sub(args[1], 2)) -- Remove prefix
            local commandArgs = {}
            for i = 2, #args do
                table.insert(commandArgs, args[i])
            end
            
            for _, handler in ipairs(commandHandlers) do
                if cmd == string.lower(handler.command) then
                    pcall(handler.callback, commandArgs, speaker)
                    return
                end
                for _, alias in ipairs(handler.aliases) do
                    if cmd == string.lower(alias) then
                        pcall(handler.callback, commandArgs, speaker)
                        return
                    end
                end
            end
        end
    end

    -- Listen to chat (basic implementation)
    Players.LocalPlayer.Chatted:Connect(function(message)
        onChatMessage(message, Players.LocalPlayer)
    end)
end

-- Register rejoin command
addcmd("rejoin", {"rj"}, function(args, speaker)
    Fluent:Notify({
        Title = "Rejoin Command",
        Content = "Rejoining server...",
        Duration = 3
    })
    
    if #Players:GetPlayers() <= 1 then
        Players.LocalPlayer:Kick("\nRejoining...")
        wait(0.5)
        TeleportService:Teleport(PlaceId, Players.LocalPlayer)
    else
        TeleportService:TeleportToPlaceInstance(PlaceId, JobId, Players.LocalPlayer)
    end
end)

-- Setup chat commands (optional)
setupChatCommands()

CommandsSection:AddButton({
    Title = "Enable Chat Commands",
    Description = "Use ;rejoin or ;rj in chat",
    Callback = function()
        Fluent:Notify({
            Title = "Chat Commands",
            Content = "Commands enabled! Use ;rejoin or ;rj",
            Duration = 5
        })
    end
})



-- SaveManager & Interface
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("FishingHub")
SaveManager:SetFolder("FishingHub/specific-game")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
    Title = "Fishing Hub",
    Content = "Script loaded!",
    Duration = 6
})