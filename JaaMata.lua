-- =========================================================
--[[
    Fish It Script (Cleaned & Refactored Version)
    By Rafscape, Refactored with Gemini
]]
-- =========================================================

-- =========================================================
-- 1. SETUP & SERVICES
-- =========================================================
-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

-- Player
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end

-- Load Rayfield Library
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua"))()

-- Networking & Game Modules
local success, modules = pcall(function()
    local netLibrary = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")
    return {
        Net = netLibrary,
        ItemUtility = require(ReplicatedStorage.Shared.ItemUtility),
        Replion = require(ReplicatedStorage.Packages.Replion).Client,
        Modifiers = require(ReplicatedStorage.Shared.FishingRodModifiers),
        Baits = require(ReplicatedStorage.Baits)
    }
end)

if not success then
    warn("Gagal memuat modul penting. Script tidak dapat berjalan.", modules)
    return
end

local playerData = modules.Replion:WaitReplion("Data")
if not playerData then
    warn("Gagal memuat data pemain (Replion).")
    return
end

-- =========================================================
-- 2. UI SETUP (WINDOW & TABS)
-- =========================================================
local Window = Rayfield:CreateWindow({
    Name = "Fish It Script",
    LoadingTitle = "Fish It",
    LoadingSubtitle = "by Rafscape",
    Theme = "Amethyst",
    ConfigurationSaving = { Enabled = true, FolderName = "Rafscape", FileName = "FishIt" }
})

-- [[ TAB BARU DITAMBAHKAN ]] --
local Tabs = {
    Developer = Window:CreateTab("Developer", "airplay"),
    AutoFish = Window:CreateTab("Auto Fish", "fish"),
    AutoFarm = Window:CreateTab("Auto Farm", "fish"),
    AutoTrade = Window:CreateTab("Auto Trade", "repeat-2"), -- TAB BARU
    Player = Window:CreateTab("Player", "users-round"),
    Islands = Window:CreateTab("Islands", "map"),
    Settings = Window:CreateTab("Settings", "cog"),
    NPC = Window:CreateTab("NPC", "user"),
    Event = Window:CreateTab("Event", "cog"),
    SpawnBoat = Window:CreateTab("Spawn Boat", "cog"),
    BuyRod = Window:CreateTab("Buy Rod", "cog"),
    BuyWeather = Window:CreateTab("Buy Weather", "cog"),
    BuyBait = Window:CreateTab("Buy Bait", "cog")
}
local mainTabToggles = {}
-- =========================================================
-- 3. HELPER FUNCTIONS
-- =========================================================
local function Notify(title, message, isError)
    Rayfield:Notify({
        Title = title,
        Content = message,
        Duration = 5,
        Image = isError and "ban" or "circle-check"
    })
end

local webhookSettings = {
    enabled = false,
    url = "https://discord.com/api/webhooks/1421277150333505587/LFgGVdOx68w1RzWRacdnB-4PTW1yBhjpPYZox04CGCwmyaDfVbJmR1CN6zgkelj_REHM",
    minTier = 6
}
-- [[ FUNGSI WEBHOOK DITAMBAHKAN DI SINI ]]
local function SendToDiscord(itemInfo)
    if not webhookSettings.enabled or webhookSettings.url:len() < 20 then return end

    local data = itemInfo.Data
    
    if data.Tier < webhookSettings.minTier then return end

    local fishName = data.Name or "Ikan Tidak Dikenal"
    local fishIconId = data.Icon and data.Icon:match("%d+") or ""
    local imageUrl = "https://i.imgur.com/K3v8aG3.png" -- URL default jika gagal

    -- [[ LANGKAH 1: MINTA URL GAMBAR DARI API THUMBNAIL ROBLOX ]]
    local requestFunction = (syn and syn.request) or request or http_request
    if requestFunction and fishIconId ~= "" then
        local success, response = pcall(function()
            return requestFunction({
                Url = "https://thumbnails.roblox.com/v1/assets?assetIds=" .. fishIconId .. "&size=150x150&format=Png&isCircular=false",
                Method = "GET"
            })
        end)

        if success and response and response.Body then
            local decodedResponse = HttpService:JSONDecode(response.Body)
            if decodedResponse and decodedResponse.data and #decodedResponse.data > 0 and decodedResponse.data[1].imageUrl then
                imageUrl = decodedResponse.data[1].imageUrl -- Ambil URL gambar yang valid
            end
        end
    end

    -- [[ LANGKAH 2: KIRIM PAYLOAD KE DISCORD DENGAN URL GAMBAR YANG DIDAPAT ]]
    local fields = {}
    for key, value in pairs(data) do
        if value and tostring(value) ~= "" then
            table.insert(fields, { name = tostring(key), value = "```" .. tostring(value) .. "```", inline = true })
        end
    end

    local payload = {
        username = "Fish It Bot",
        avatar_url = "https://i.imgur.com/K3v8aG3.png",
        embeds = {{
            title = "🎣 Ikan Langka Tertangkap!",
            description = "**" .. LocalPlayer.Name .. "** berhasil menangkap **" .. fishName .. "**!",
            color = 15105570,
            fields = fields,
            thumbnail = { url = imageUrl }, -- Gunakan URL yang sudah didapat dari API
            footer = { text = "Fish It Script by Rafscape & Gemini" },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z")
        }}
    }

    pcall(function()
        if requestFunction then
            requestFunction({
                Url = webhookSettings.url,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode(payload)
            })
        else
            warn("Executor tidak mendukung fungsi request HTTP.")
        end
    end)
end
-- Fungsi Teleport yang sudah bisa mengatur arah pandang
local function Teleport(position, objectName, lookAtPosition)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local targetPos = position + Vector3.new(0, 5, 0)
        
        if lookAtPosition then
            -- Jika ada target untuk dilihat, CFrame akan diatur menghadap ke sana
            hrp.CFrame = CFrame.new(targetPos, lookAtPosition)
        else
            -- Jika tidak ada, perilaku tetap seperti semula (hanya pindah posisi)
            hrp.CFrame = CFrame.new(targetPos)
        end
        
        Notify("Teleport Berhasil", "Berpindah ke: " .. objectName)
    else
        Notify("Teleport Gagal", "Karakter tidak ditemukan.", true)
    end
end

local function GetInventoryFishList()
    local inventory = playerData:Get("Inventory")
    if not inventory or not inventory.Items then return {} end

    local fishCountMap = {}
    for _, item in ipairs(inventory.Items) do
        if item.Id then
            local success, itemData = pcall(modules.ItemUtility.GetItemData, modules.ItemUtility, tonumber(item.Id))
            if success and itemData and itemData.Data and itemData.Data.Type == "Fishes" then
                local fishName = itemData.Data.Name or "Unknown Fish"
                fishCountMap[fishName] = (fishCountMap[fishName] or 0) + 1
            end
        end
    end

    local fishList = {}
    for name, count in pairs(fishCountMap) do
        table.insert(fishList, name .. " (" .. count .. ")")
    end

    table.sort(fishList)
    return fishList
end

local function GetInventoryEnchantStoneList()
    local inventory = playerData:Get("Inventory")
    if not inventory or not inventory.Items then return {} end

    local stoneCountMap = {}
    for _, item in ipairs(inventory.Items) do
        if item.Id then
            local success, itemData = pcall(modules.ItemUtility.GetItemData, modules.ItemUtility, tonumber(item.Id))
            if success and itemData and itemData.Data and itemData.Data.Type == "EnchantStones" then
                local stoneName = itemData.Data.Name or "Unknown Stone"
                stoneCountMap[stoneName] = (stoneCountMap[stoneName] or 0) + 1
            end
        end
    end

    local stoneList = {}
    for name, count in pairs(stoneCountMap) do
        table.insert(stoneList, name .. " (" .. count .. ")")
    end

    table.sort(stoneList)
    return stoneList
end
-- Fungsi untuk mendapatkan UUID item dari namanya
-- [[ FUNGSI HELPER BARU ]] --
-- Fungsi untuk mendapatkan beberapa UUID item berdasarkan nama dan jumlah yang diminta
local function GetItemUUIDsFromName(itemName, quantity)
    local inventory = playerData:Get("Inventory")
    if not inventory or not inventory.Items then return {} end

    local pureItemName = itemName:match("^(.*)%s%(%d+%)$") or itemName
    local uuids = {}

    for _, item in ipairs(inventory.Items) do
        if #uuids >= quantity then break end -- Berhenti jika sudah cukup

        if item.Id then
            local success, itemData = pcall(modules.ItemUtility.GetItemData, modules.ItemUtility, tonumber(item.Id))
            if success and itemData and itemData.Data and itemData.Data.Name == pureItemName then
                table.insert(uuids, {UUID = item.UUID, Type = itemData.Data.Type})
            end
        end
    end
    return uuids
end

-- [[ FUNGSI HELPER BARU ]] --
-- Fungsi ini bisa dipakai ulang untuk membuat dropdown teleportasi autofarm
local function CreateLocationDropdown(parentTab, dropdownName, locations)
    -- Pastikan ada data lokasi sebelum membuat dropdown
    if not locations or next(locations) == nil then return end

    -- 1. Ekstrak semua nama lokasi dari tabel data
    local spotNames = {}
    for name in pairs(locations) do
        table.insert(spotNames, name)
    end
    table.sort(spotNames)

    -- 2. Buat dropdown menggunakan data yang sudah disiapkan
    parentTab:CreateDropdown({
        Name = dropdownName,
        Options = spotNames,
        Default = spotNames[1],
        Callback = function(selectedInfo)
            local spotName = selectedInfo[1]
            local spotData = locations[spotName]
            if not spotData then return end

            -- 3. Panggil fungsi Teleport dengan posisi dan arah pandang
            Teleport(spotData.Pos, spotName, spotData.LookAt)
            
            -- (Opsional) Jika Anda ingin auto-fish aktif setelah teleport
            task.wait(1)
            for _, toggle in ipairs(mainTabToggles) do toggle:Set(true) end
            Notify("Auto Farm Dimulai", "Auto fishing diaktifkan di " .. spotName)
        end
    })
end
-- =========================================================
-- 4. FEATURES
-- =========================================================

-- 4.1 Fitur: Developer Tab
local function SetupDeveloperTab()
    Tabs.Developer:CreateParagraph({
        Title = "Fish It Script Edited By Rafscape",
        Content = "YNWA"
    })
    -- Pengaturan Webhook
    Tabs.Developer:CreateSection("Webhook Settings")
    Tabs.Developer:CreateToggle({
        Name = "📢 Aktifkan Webhook Ikan Langka",
        CurrentValue = webhookSettings.enabled,
        Callback = function(value)
            webhookSettings.enabled = value
            Notify("Webhook", "Notifikasi Discord " .. (value and "diaktifkan." or "dimatikan."))
        end
    })
    Tabs.Developer:CreateParagraph({
        Title = "Discord Webhook",
        Content= "Masukkan URL webhook Discord Anda..."
    })
    -- Tabs.Developer:CreateInput({
    --    Name = "Webhook URL",
    --   PlaceholderText = "discord webhook url",
    --    Text = webhookSettings.url,
    --  Callback = function(value)
    --       webhookSettings.url = value
    --   end
    -- })
    Tabs.Developer:CreateSlider({
        Name = "Minimal Tier",
        Range = {1, 7},
        Increment = 1,
        CurrentValue = webhookSettings.minTier,
        Suffix = "Tier",
        Callback = function(value)
            webhookSettings.minTier = value
            Notify("Webhook", "Minimal tier diatur ke " .. value)
        end
    })
end

-- 4.2 Fitur: Auto Fish
local function SetupAutoFishTab()
    local autofish, perfectCast, autoSellVersion = false, false, false
    local autoRecastDelay, autoSellDelay = 0.5, 1

    Tabs.AutoFish:CreateParagraph({ Title = "🎣 Auto Fish Settings", Content = "Gunakan toggle & slider di bawah untuk mengatur auto fishing." })

    local autoFishToggle = Tabs.AutoFish:CreateToggle({
        Name = "🎣 Enable Auto Fishing",
        CurrentValue = autofish,
        Callback = function(val)
            autofish = val
            if not val then return end
            task.spawn(function()
                local remotes = {
                    unequip = modules.Net:WaitForChild("RE/UnequipToolFromHotbar"),
                    equip = modules.Net:WaitForChild("RE/EquipToolFromHotbar"),
                    charge = modules.Net:WaitForChild("RF/ChargeFishingRod"),
                    minigame = modules.Net:WaitForChild("RF/RequestFishingMinigameStarted"),
                    finish = modules.Net:WaitForChild("RE/FishingCompleted")
                }
                while autofish do
                    pcall(function()
                        remotes.unequip:FireServer()
                        task.wait(0.1)
                        remotes.equip:FireServer(1)
                        task.wait(0.1)
                        remotes.charge:InvokeServer(perfectCast and 9e9 or tick())
                        task.wait(0.1)
                        remotes.minigame:InvokeServer(perfectCast and -1.238 or math.random(), perfectCast and 0.969 or math.random())
                        task.wait(1.3)
                        for i = 1, 10 do remotes.finish:FireServer() task.wait(0.2) end
                    end)
                    task.wait(autoRecastDelay)
                end
            end)
        end
    })

    local perfectCastToggle = Tabs.AutoFish:CreateToggle({ Name = "✨ Use Perfect Cast", CurrentValue = perfectCast, Callback = function(val) perfectCast = val end })
    table.insert(mainTabToggles, autoFishToggle)
    table.insert(mainTabToggles, perfectCastToggle)
    
    Tabs.AutoFish:CreateButton({ Name = "Unstuck Fishing", Callback = function() pcall(function() modules.Net:WaitForChild("RE/FishingCompleted"):FireServer() end) end })
    Tabs.AutoFish:CreateSlider({ Name = "⏱️ Recast Delay (s)", Range = {0.5, 5}, Increment = 0.1, CurrentValue = autoRecastDelay, Callback = function(val) autoRecastDelay = val end })
    Tabs.AutoFish:CreateToggle({ Name = "Auto Sell", CurrentValue = autoSellVersion, Callback = function(val)
        autoSellVersion = val
        if not val then return end
        task.spawn(function()
            local sellRemote = modules.Net:WaitForChild("RF/SellAllItems")
            while autoSellVersion do
                pcall(function() sellRemote:InvokeServer() end)
                task.wait(autoSellDelay)
            end
        end)
    end})
    Tabs.AutoFish:CreateSlider({ Name = "⏱️ Auto Sell Delay (min)", Range = {1, 100}, Increment = 10, CurrentValue = 1, Callback = function(val) autoSellDelay = val * 60 end })
end

-- 4.3 Fitur: Auto Farm
local function SetupAutoFarmTab()
    -- Data Set 1: Lokasi Paus & Batu
    local whaleAndRockSpots = {
        ["Bawah Air Terjun"] = {Pos = Vector3.new(-2083, 6, 3658), LookAt = Vector3.new(-2098,-2,3672)},
        ["Dalam Goa"] = {Pos = Vector3.new(-2166, 2, 3640), LookAt = Vector3.new(-2150,-2,3650)},
        ["Atas Air Terjun"] = {Pos = Vector3.new(-2145, 53, 3621), LookAt = Vector3.new(-2144,44,3650)},
        ["Tebing Laut"] = {Pos = Vector3.new(-2184,25,3591), LookAt = Vector3.new(-2182,-2,3559)}
    }

    -- Data Set 2: Lokasi Ikan Langka (Contoh)
    local craterFishSpots = {
        ["Tengah"] = {Pos = Vector3.new(1009,18,5063), LookAt = Vector3.new(1016,-2,5036)},
        ["Tepi"] = {Pos = Vector3.new(1069,2,5046), LookAt = Vector3.new(1045,-2,5057)},
    }
    
    local krakenFishSpots = {
        ["Depan Board"] = {Pos = Vector3.new(-3738,-135,-1010), LookAt = Vector3.new(-3732,-140,-986)},
        ["Belakang Patung"] = {Pos = Vector3.new(-3694,-135,-888), LookAt = Vector3.new(-3732,-140,-986)},
    }
    
    local orcaFishSpots = {
        ["Bawah Jembatan"] = {Pos = Vector3.new(-64,3,2781), LookAt = Vector3.new(-79,-2,2784)},
        ["Atas Jembatan"] = {Pos = Vector3.new(-86,18,2814), LookAt = Vector3.new(-79,-2,2784)},
        ["Pulau Kecil"] = {Pos = Vector3.new(-211,2,2946), LookAt = Vector3.new(-225,2,2946)},
   }

    -- Membuat dropdown pertama menggunakan fungsi reusable
    CreateLocationDropdown(Tabs.AutoFarm, "Farm Spot Paus & Batu", whaleAndRockSpots)

    -- Membuat dropdown kedua menggunakan fungsi reusable yang sama
    CreateLocationDropdown(Tabs.AutoFarm, "Farm Frosborn Crater", craterFishSpots)

    CreateLocationDropdown(Tabs.AutoFarm, "Farm Kraken", krakenFishSpots)
    CreateLocationDropdown(Tabs.AutoFarm, "Farm Orca", orcaFishSpots)

end

-- [[ BARU ]] Fitur: Auto Trade
-- =========================================================
-- 4.4 Fitur: Auto Trade [[ DITINGKATKAN DENGAN MONITOR STATUS ]]
-- =========================================================
local function SetupAutoTradeTab()
    local selectedTargetPlayer = nil
    local selectedItemName = nil
    local tradeQuantity = 1

    -- Variabel untuk menyimpan objek label status
    local statusProgressLabel, statusSuksesLabel, statusGagalLabel, statusInfoLabel

    Tabs.AutoTrade:CreateParagraph({ Title = "🎯 Player Target", Content = "Pilih pemain yang ingin Anda kirimi item." })
    
    -- Bagian memilih player
    local playerNames = {}
    local playerDropdown = Tabs.AutoTrade:CreateDropdown({
        Name = "Pilih Player Tujuan",
        Options = playerNames,
        Callback = function(s)
            selectedTargetPlayer = Players:FindFirstChild(s[1])
            if selectedTargetPlayer then Notify("Player Dipilih", "Target trade: " .. s[1])
            else selectedTargetPlayer = nil; Notify("Error", "Player tidak ditemukan!", true) end
        end
    })
    local function refreshPlayerList()
        playerNames = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then table.insert(playerNames, player.Name) end
        end
        if #playerNames == 0 then playerDropdown:Set({"Tidak ada pemain lain"})
        else playerDropdown:Set(playerNames); playerDropdown:Refresh(playerNames) end
    end
    Tabs.AutoTrade:CreateButton({ Name = "🔄 Refresh Daftar Player", Callback = function()
        refreshPlayerList()
        Notify("Update", "Daftar pemain diperbarui.")
    end})
    refreshPlayerList()
    Tabs.AutoTrade:CreateButton({ Name = "🚀 Teleport ke Player Terpilih", Callback = function()
        if selectedTargetPlayer and selectedTargetPlayer.Character and selectedTargetPlayer.Character:FindFirstChild("HumanoidRootPart")
        and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local targetPos = selectedTargetPlayer.Character.HumanoidRootPart.CFrame
            LocalPlayer.Character.HumanoidRootPart.CFrame = targetPos + Vector3.new(0, 5, 0)
        else
            Notify("Teleport Failed", "Player tidak valid atau karakter tidak siap.", true)
        end
    end})

    Tabs.AutoTrade:CreateParagraph({ Title = "📦 Item & Jumlah", Content = "Pilih item dan tentukan jumlah yang akan dikirim." })
    
    -- Dropdown Item
    task.spawn(function()
        task.wait(0.5)
        local stoneList = GetInventoryEnchantStoneList()
        if #stoneList == 0 then stoneList = {"Tidak ada enchant stone"} end
        Tabs.AutoTrade:CreateDropdown({ Name = "Pilih Enchant Stone", Options = stoneList, Callback = function(selection)
            selectedItemName = selection[1]
            Notify("Item Dipilih", "Kamu memilih: " .. selectedItemName)
        end})
    end)
    task.spawn(function()
        task.wait(1)
        local fishList = GetInventoryFishList()
        if #fishList == 0 then fishList = {"Tidak ada ikan di inventory"} end
        Tabs.AutoTrade:CreateDropdown({ Name = "Pilih Ikan", Options = fishList, Callback = function(selection)
            selectedItemName = selection[1]
            Notify("Item Dipilih", "Kamu memilih: " .. selectedItemName)
        end})
    end)

    Tabs.AutoTrade:CreateInput({ Name = "Jumlah Item", PlaceholderText = "1", Numbers = true, Callback = function(val)
        tradeQuantity = tonumber(val) or 1
    end})

    Tabs.AutoTrade:CreateParagraph({ Title = "⚙️ Aksi & Status", Content = "Setelah memilih, kirim trade dan pantau statusnya di bawah." })
    
    -- [[ BARU ]] Label untuk memantau status trade
    task.spawn(function()
        task.wait(1.2)
        statusProgressLabel = Tabs.AutoTrade:CreateLabel("Progress: -/-")
        statusSuksesLabel = Tabs.AutoTrade:CreateLabel("Berhasil: 0")
        statusGagalLabel = Tabs.AutoTrade:CreateLabel("Gagal: 0")
        statusInfoLabel = Tabs.AutoTrade:CreateLabel("Status: Menunggu perintah...")
    end)
 
    -- [[ BARU ]] Logika tombol "Kirim Trade" yang diperbarui untuk update status
    local function SendAutoTrade()
        if not selectedTargetPlayer then return Notify("Gagal", "Pilih pemain tujuan!", true) end
        if not selectedItemName then return Notify("Gagal", "Pilih item yang ingin dikirim!", true) end
        
        local quantityToTrade = tradeQuantity
        if quantityToTrade <= 0 then return Notify("Gagal", "Jumlah harus lebih dari 0.", true) end

        local itemInfos = GetItemUUIDsFromName(selectedItemName, quantityToTrade)
        if #itemInfos < quantityToTrade then
            return Notify("Gagal Stok", string.format("Stok item tidak cukup. Diminta: %d, Tersedia: %d", quantityToTrade, #itemInfos), true)
        end

        -- Reset label status untuk sesi trade baru
        local suksesCount, gagalCount = 0, 0
        statusProgressLabel:Set(string.format("Progress: 0/%d", quantityToTrade))
        statusSuksesLabel:Set("Berhasil: 0")
        statusGagalLabel:Set("Gagal: 0")
        statusInfoLabel:Set("Status: Memulai...")
        
        task.spawn(function()
            for i = 1, quantityToTrade do
                statusProgressLabel:Set(string.format("Progress: %d/%d", i, quantityToTrade))
                statusInfoLabel:Set(string.format("Mengirim item ke-%d...", i))
                
                local currentItem = itemInfos[i]
                modules.Net:WaitForChild("RE/EquipItem"):FireServer(currentItem.UUID, currentItem.Type)
                task.wait(1.5)

                local success, result = pcall(function()
                    return modules.Net:WaitForChild("RF/InitiateTrade"):InvokeServer(selectedTargetPlayer.UserId, currentItem.UUID)
                end)
                
                if success and result then
                    suksesCount = suksesCount + 1
                    statusSuksesLabel:Set("Berhasil: " .. suksesCount)
                    statusInfoLabel:Set(string.format("Item ke-%d berhasil terkirim.", i))
                else
                    gagalCount = gagalCount + 1
                    statusGagalLabel:Set("Gagal: " .. gagalCount)
                    statusInfoLabel:Set(string.format("Gagal di item ke-%d. Proses Gagal.", i))
                    warn(string.format("Trade item ke-%d gagal. Alasan dari server: %s", i, tostring(result)))
                end
                
                if i < quantityToTrade then task.wait(5) end
            end
            
            if gagalCount == 0 then
                statusInfoLabel:Set("Status: Semua item berhasil dikirim!")
            end
        end)
    end

     task.spawn(function()
        task.wait(1.1)
        Tabs.AutoTrade:CreateButton({ Name = "📤 Kirim Trade", Callback = SendAutoTrade })
    end)
end

-- 4.4 Fitur: Player (Sudah Disederhanakan)
local function SetupPlayerTab()
    local infiniteJumpEnabled = false
    
    Tabs.Player:CreateParagraph({ Title = "🔧 Player Mods", Content = "Fitur untuk memodifikasi kemampuan karakter Anda."})

    -- Toggle Infinite Jump
    Tabs.Player:CreateToggle({
        Name = "Infinity Jump",
        CurrentValue = infiniteJumpEnabled,
        Callback = function(val)
            infiniteJumpEnabled = val
        end
    })

    -- Slider Walk Speed
    Tabs.Player:CreateSlider({
        Name = "WalkSpeed",
        Range = {16, 150},
        Increment = 1,
        CurrentValue = 16,
        Callback = function(val)
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = val end
        end
    })

    -- Slider Jump Power
    Tabs.Player:CreateSlider({
        Name = "Jump Power",
        Range = {50, 500},
        Increment = 10,
        CurrentValue = 50,
        Callback = function(val)
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.JumpPower = val
            end
        end
    })

    local blockUpdateOxygen = false
    -- Toggle Unlimited Oxygen
    Tabs.Player:CreateToggle({
        Name = "Unlimited Oxygen",
        CurrentValue = false,
        Flag = "BlockUpdateOxygen",
        Callback = function(value) 
            -- Logika untuk unlimited oxygen bisa ditambahkan di sini jika ada
            blockUpdateOxygen = value
            Rayfield:Notify({
                Title = "Update Oxygen Block",
                Content = value and "Remote blocked!" or "Remote allowed!",
                Duration = 3,
            })
        end
    })

    -- Hook FireServer
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
    
        if method == "FireServer" and tostring(self) == "URE/UpdateOxygen" and blockUpdateOxygen then
            warn("Tahan Napas Bang")
            return nil -- prevent call
        end
    
        return oldNamecall(self, unpack(args))
    end))

    UserInputService.JumpRequest:Connect(function()
        if infiniteJumpEnabled and LocalPlayer.Character and LocalPlayer.Character.Humanoid then
            LocalPlayer.Character.Humanoid:ChangeState("Jumping")
        end
    end)
end

-- 4.5 Fitur: Islands
local function SetupIslandsTab()
    local islandCoords = {
        { name = "Weather Machine", pos = Vector3.new(-1471, -3, 1929) }, { name = "Esoteric Depths", pos = Vector3.new(3157, -1303, 1439) },
        { name = "Tropical Grove", pos = Vector3.new(-2038, 3, 3650) }, { name = "Stingray Shores", pos = Vector3.new(-32, 4, 2773) },
        { name = "Kohana Volcano", pos = Vector3.new(-519, 24, 189) }, { name = "Coral Reefs", pos = Vector3.new(-3095, 1, 2177) },
        { name = "Lost Isle [Treasure Room]", pos = Vector3.new(-3601,-282,-1630)}, { name = "Lost Isle [Treasure Hall]", pos = Vector3.new(-3757,-135,-1005)},
        { name = "Lost Isle [Sisyphus]", pos = Vector3.new(-3738,-136,-1010)}, { name = "Lost Isle [Lost Shore]", pos = Vector3.new(-3697, 97, -932)},
        { name = "Isoteric Island", pos = Vector3.new(1987, 4, 1400) }, { name = "Crater Island", pos = Vector3.new(1025,20,5075) },
    }
    for _, data in ipairs(islandCoords) do
        Tabs.Islands:CreateButton({ Name = data.name, Callback = function() Teleport(data.pos, data.name) end })
    end
end

-- 4.6 Fitur: Settings (Sudah Disederhanakan)
local function SetupSettingsTab()
    Tabs.Settings:CreateButton({ Name = "Rejoin Server", Callback = function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end })
    Tabs.Settings:CreateButton({ Name = "Server Hop", Callback = function() Notify("Server Hop", "Fungsi ini belum diimplementasikan.", true) end })
    Tabs.Settings:CreateButton({ Name = "Unload Script", Callback = function() Window:Destroy() end })
    
    local enchantAltarPosition = Vector3.new(3174, -1303, 1425)
    
    Tabs.Settings:CreateParagraph({ Title = "Auto Enchant Settings", Content = "Pilih pancingan dari inventory, lalu tekan tombol." })

    local selectedRodUUID = nil
    task.spawn(function()
        task.wait(3)
        local inventory = playerData:Get("Inventory")
        local rodsInventory = inventory and inventory["Fishing Rods"]
        if not rodsInventory then return end
        
        local rodNamesForDropdown = {}
        local rodNameToUUIDMap = {}
        for _, rodData in ipairs(rodsInventory) do
            if rodData and rodData.Id then
                local blueprint = modules.ItemUtility:GetItemData(tonumber(rodData.Id))
                if blueprint and blueprint.Data and blueprint.Data.Type == "Fishing Rods" then
                    local rodName = blueprint.Data.Name
                    if not rodNameToUUIDMap[rodName] then
                        table.insert(rodNamesForDropdown, rodName)
                        rodNameToUUIDMap[rodName] = rodData.UUID
                    end
                end
            end
        end
        Tabs.Settings:CreateDropdown({
            Name = "Pilih Pancingan",
            Options = #rodNamesForDropdown > 0 and rodNamesForDropdown or {"Tidak ada pancingan"},
            Callback = function(s)
                selectedRodUUID = rodNameToUUIDMap[s[1]]
                if selectedRodUUID then Notify("Pancingan Dipilih", "Siap enchant " .. s[1]) end
            end
        })
    end)

    Tabs.Settings:CreateButton({ Name = "🔮 Mulai Auto Enchant", Callback = function()
        if not selectedRodUUID then return Notify("Gagal", "Pilih pancingan terlebih dahulu!", true) end

        task.spawn(function()
            Notify("Auto Enchant", "Memulai proses...")
            modules.Net:WaitForChild("RE/EquipItem"):FireServer(selectedRodUUID, "Fishing Rods")
            task.wait(2)

            local items = playerData:Get("Inventory").Items
            local foundStone = false
            
            for _, item in ipairs(items) do
                if item.Id then
                    local success, itemData = pcall(modules.ItemUtility.GetItemData, modules.ItemUtility, item.Id)
                    if success and itemData and itemData.Data.Name == "Enchant Stone" then
                        modules.Net:WaitForChild("RE/EquipItem"):FireServer(item.UUID, "EnchantStones")
                        modules.Net:WaitForChild("RE/EquipToolFromHotbar"):FireServer(2)
                        task.wait(2)
                        Teleport(enchantAltarPosition, "Altar Enchant")
                        task.wait(1)
                        modules.Net:WaitForChild("RE/ActivateEnchantingAltar"):FireServer()
                        Notify("Berhasil!", "Proses enchant diaktifkan.")
                        foundStone = true
                        break 
                    end
                end
            end
            if not foundStone then Notify("Gagal", "'Enchant Stone' tidak ditemukan di inventory.", true) end
        end)
    end})
end

-- 4.7 Fitur: NPC Tab
local function SetupNPCTab()
    local npcFolder = ReplicatedStorage:WaitForChild("NPC", 10)
    if not npcFolder then return end
    for _, npc in ipairs(npcFolder:GetChildren()) do
        Tabs.NPC:CreateButton({ Name = "TP to " .. npc.Name, Callback = function()
            local npcModel = Workspace:FindFirstChild(npc.Name, true)
            if npcModel and npcModel:FindFirstChild("HumanoidRootPart") then
                Teleport(npcModel.HumanoidRootPart.Position, npc.Name)
            else
                Notify("Gagal", "NPC " .. npc.Name .. " tidak ditemukan.", true)
            end
        end})
    end
end

-- 4.8 Fitur: Spawn Boat Tab
local function SetupSpawnBoatTab()
    local remotes = {
        despawn = modules.Net:WaitForChild("RF/DespawnBoat"),
        spawn = modules.Net:WaitForChild("RF/SpawnBoat")
    }
    local function spawnBoat(id, name)
        pcall(function()
            remotes.despawn:InvokeServer()
            task.wait(1)
            remotes.spawn:InvokeServer(id)
            Notify("Boat Spawning", "Memunculkan " .. name)
        end)
    end
    
    Tabs.SpawnBoat:CreateParagraph({ Title = "🚤 Standard Boats", Content = "" })
    local standard_boats = {
        { Name = "Small Boat", ID = 1 }, { Name = "Kayak", ID = 2 }, { Name = "Jetski", ID = 3 },
        { Name = "Highfield Boat", ID = 4 }, { Name = "Speed Boat", ID = 5 }, { Name = "Fishing Boat", ID = 6 },
        { Name = "Mini Yacht", ID = 14 }, { Name = "Hyper Boat", ID = 7 }, { Name = "Frozen Boat", ID = 11 },
        { Name = "Cruiser Boat", ID = 13 }
    }
    for _, boat in ipairs(standard_boats) do
        Tabs.SpawnBoat:CreateButton({ Name = boat.Name, Callback = function() spawnBoat(boat.ID, boat.Name) end })
    end
    
    Tabs.SpawnBoat:CreateParagraph({ Title = "🦆 Other Boats", Content = "" })
    local other_boats = {
        { Name = "Alpha Floaty", ID = 8 }, { Name = "DEV Evil Duck 9000", ID = 9 },
        { Name = "Festive Duck", ID = 10 }, { Name = "Santa Sleigh", ID = 12 }
    }
    for _, boat in ipairs(other_boats) do
        Tabs.SpawnBoat:CreateButton({ Name = boat.Name, Callback = function() spawnBoat(boat.ID, boat.Name) end })
    end
end

-- 4.9 Fitur: Buy Rod Tab
local function SetupBuyRodTab()
    Tabs.BuyRod:CreateParagraph({ Title = "🎣 Purchase Rods", Content = "Select a rod to buy using coins." })
    local rods = {
        { Name = "Luck Rod", Price = "350 Coins", ID = 79 }, { Name = "Carbon Rod", Price = "900 Coins", ID = 76 },
        { Name = "Grass Rod", Price = "1.50k Coins", ID = 85 }, { Name = "Demascus Rod", Price = "3k Coins", ID = 77 },
        { Name = "Ice Rod", Price = "5k Coins", ID = 78 }, { Name = "Lucky Rod", Price = "15k Coins", ID = 4 },
        { Name = "Midnight Rod", Price = "50k Coins", ID = 80 }, { Name = "Steampunk Rod", Price = "215k Coins", ID = 6 },
        { Name = "Chrome Rod", Price = "437k Coins", ID = 7 }, { Name = "Astral Rod", Price = "1M Coins", ID = 5 }
    }
    for _, rod in ipairs(rods) do
        Tabs.BuyRod:CreateButton({ Name = rod.Name .. " (" .. rod.Price .. ")", Callback = function()
            pcall(function()
                modules.Net:WaitForChild("RF/PurchaseFishingRod"):InvokeServer(rod.ID)
                Notify("Pembelian", "Membeli " .. rod.Name)
            end)
        end})
    end
end

-- 4.10 Fitur: Buy Weather Tab
local function SetupBuyWeatherTab()
    Tabs.BuyWeather:CreateParagraph({ Title = "🌤️ Purchase Weather Events", Content = "Pilih cuaca mana saja yang ingin dibeli secara otomatis setiap 20 menit." })
    
    local autoBuyWeather = false
    local weathers = {
        { Name = "Wind", Price = "10k Coins" }, { Name = "Snow", Price = "15k Coins" },
        { Name = "Cloudy", Price = "20k Coins" }, { Name = "Storm", Price = "35k Coins" },
        { Name = "Shark Hunt", Price = "300k Coins" }
    }
    
    local weatherStates = {}
    for _, w in ipairs(weathers) do
        weatherStates[w.Name] = false
    end

    Tabs.BuyWeather:CreateToggle({ 
        Name = "🌀 Aktifkan Auto Buy (Siklus 20 Menit)", 
        CurrentValue = autoBuyWeather, 
        Callback = function(val)
            autoBuyWeather = val
            if not val then return Notify("Auto Weather", "Siklus 20 menit dihentikan.") end
            
            Notify("Auto Weather", "Siklus 20 menit dimulai.")
            task.spawn(function()
                local currentIndex = 1
                
                while autoBuyWeather do
                    local activeWeathers = {}
                    for _, w in ipairs(weathers) do
                        if weatherStates[w.Name] == true then
                            table.insert(activeWeathers, w)
                        end
                    end

                    if #activeWeathers > 0 then
                        if currentIndex > #activeWeathers then
                            currentIndex = 1
                        end
                        
                        local weatherToBuy = activeWeathers[currentIndex]
                        
                        Notify("Auto Weather", "Membeli cuaca: " .. weatherToBuy.Name)
                        pcall(function() 
                            modules.Net:WaitForChild("RF/PurchaseWeatherEvent"):InvokeServer(weatherToBuy.Name) 
                        end)
                        
                        currentIndex = currentIndex + 1
                        
                        Notify("Auto Weather", "Menunggu 20 menit untuk siklus berikutnya...")
                        task.wait(20 * 60)
                    else
                        Notify("Auto Weather", "Tidak ada cuaca yang dipilih. Menunggu 1 menit sebelum cek lagi.", true)
                        task.wait(60)
                    end
                end
            end)
        end
    })

    Tabs.BuyWeather:CreateParagraph({ Title = "Pilih Cuaca untuk Auto Buy", Content = "" })

    for _, weather in ipairs(weathers) do
        Tabs.BuyWeather:CreateToggle({
            Name = weather.Name .. " (" .. weather.Price .. ")",
            CurrentValue = weatherStates[weather.Name],
            Callback = function(value)
                weatherStates[weather.Name] = value
                Notify("Update Pilihan", weather.Name .. " auto-buy " .. (value and "ON" or "OFF"))
            end
        })
    end
end

-- 4.11 Fitur: Buy Bait Tab
local function SetupBuyBaitTab()
    Tabs.BuyBait:CreateParagraph({ Title = "🪱 Purchase Baits", Content = "Buy bait to enhance fishing luck or effects." })
    local baits = {
        { Name = "Topwater Bait", Price = "100 Coins", ID = 10 }, { Name = "Luck Bait", Price = "1k Coins", ID = 2 },
        { Name = "Midnight Bait", Price = "3k Coins", ID = 3 }, { Name = "Chroma Bait", Price = "290k Coins", ID = 6 },
        { Name = "Dark Mater Bait", Price = "630k Coins", ID = 8 }, { Name = "Corrupt Bait", Price = "1.15M Coins", ID = 15 }
    }
    for _, bait in ipairs(baits) do
        Tabs.BuyBait:CreateButton({ Name = bait.Name .. " (" .. bait.Price .. ")", Callback = function()
            pcall(function()
                modules.Net:WaitForChild("RF/PurchaseBait"):InvokeServer(bait.ID)
                Notify("Pembelian", "Membeli " .. bait.Name)
            end)
        end})
    end
end

-- 4.12 Fitur: Event Tab
local function SetupEventTab()
    local eventButtons = {}
    local function createEventButtons()
        for _, v in ipairs(eventButtons) do v:Destroy() end; table.clear(eventButtons)
        
        local props = Workspace:FindFirstChild("Props")
        if not props then return Notify("Event Info", "Folder 'Props' tidak ditemukan untuk event.", true) end
        
        for _, child in ipairs(props:GetChildren()) do
            if child:IsA("Model") or child:IsA("BasePart") then
                local button = Tabs.Event:CreateButton({
                    Name = "TP to: " .. child.Name,
                    Callback = function()
                        local pos = child:IsA("Model") and child.PrimaryPart and child.PrimaryPart.Position or child.Position
                        if pos then Teleport(pos, child.Name) else Notify("Gagal", "Tidak ada posisi valid.", true) end
                    end
                })
                table.insert(eventButtons, button)
            end
        end
    end
    
    Tabs.Event:CreateButton({ Name = "🔄 Refresh Event List", Callback = createEventButtons })
    createEventButtons()
end

-- 4.13 Fitur: Walk on Water
local function SetupWalkOnWater()
    local walkOnWaterEnabled = false
    local waterPlatform = nil

    Tabs.Player:CreateToggle({
        Name = "💧 Walk on Water",
        CurrentValue = false,
        Callback = function(val)
            walkOnWaterEnabled = val
            if not val and waterPlatform then
                waterPlatform:Destroy()
                waterPlatform = nil
            end
        end
    })

    game:GetService("RunService").Heartbeat:Connect(function()
        if not walkOnWaterEnabled then return end
        
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local rayOrigin = hrp.Position
        local rayDirection = Vector3.new(0, -10, 0)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {char}
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

        local raycastResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)

        if raycastResult and raycastResult.Instance:IsA("Terrain") and raycastResult.Material == Enum.Material.Water then
            if not waterPlatform then
                waterPlatform = Instance.new("Part")
                waterPlatform.Name = "WaterPlatform"
                waterPlatform.Size = Vector3.new(10, 1, 10)
                waterPlatform.Anchored = true
                waterPlatform.CanCollide = true
                waterPlatform.Transparency = 1
                waterPlatform.Parent = Workspace
            end
            waterPlatform.Position = Vector3.new(hrp.Position.X, raycastResult.Position.Y, hrp.Position.Z)
        else
            if waterPlatform then
                waterPlatform:Destroy()
                waterPlatform = nil
            end
        end
    end)
end

-- 4.14 Fitur: Modifier Hacks
local function ApplyHacks()
    pcall(function()
        for key in pairs(modules.Modifiers) do modules.Modifiers[key] = 9e9 end
        modules.Baits["Luck Bait"].Luck = 9e9
        print("Modifier hacks applied.")
    end)
end

-- =========================================================
-- 5. INITIALIZATION
-- =========================================================
SetupDeveloperTab()
SetupAutoFishTab()
SetupAutoFarmTab()
SetupAutoTradeTab()
SetupPlayerTab()
SetupIslandsTab()
SetupNPCTab()
SetupSpawnBoatTab()
SetupBuyRodTab()
SetupBuyWeatherTab()
SetupBuyBaitTab()
SetupEventTab()
SetupSettingsTab()
SetupWalkOnWater()
ApplyHacks()

local function StartFishMonitor()
    if not playerData then return end

    playerData:OnChange("Inventory.Items", function(newItems, oldItems)
        if #newItems > #oldItems then
            local newItemData = newItems[#newItems]
            if newItemData and newItemData.Id then
                local success, itemInfo = pcall(modules.ItemUtility.GetItemData, modules.ItemUtility, newItemData.Id)
                if success and itemInfo and itemInfo.Data.Type == "Fishes" then
                    task.spawn(SendToDiscord, itemInfo) 
                end
            end
        end
    end)
    
    print("Webhook fish monitor has been initialized.")
end

StartFishMonitor()

Notify("Script Loaded", "Fish It by Rafscape berhasil dimuat!")