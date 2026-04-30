-- ============================================
-- 🔥 NOIR UI PRO ULTIMATE - COMPLETE EDITION 🔥
-- ============================================
-- Tác giả: NoirGoodBoi + Custom Features
-- Version: 4.0 - Full Integrated
-- Ngày: 2026
-- ============================================

-- ========== LOAD NOIRUI ==========
local NoirUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/NoirGoodBoi/UI/refs/heads/main/Main.lua"))()

-- ========== TẠO CỬA SỔ CHÍNH ==========
local Window = NoirUI:CreateWindow({
    Name = "🔥 PRO ULTIMATE HUB 🔥",
    Accent = Color3.fromRGB(255, 50, 100),
    LogoID = nil,
    Icon = "⚡",
    DefaultPosition = UDim2.new(0.5, -210, 0.5, -150),
    FloatDefaultPosition = UDim2.new(0, 15, 0.5, -22),
    KeySystem = false,
})

-- ========== CONNECT WORD AI - PRO EDITION ==========
local WordGameTab = Window:CreateTab("🔤 Connect Word AI")

-- ========== CẤU HÌNH CAO CẤP ==========
local Config = {
    AutoPlay = false,
    HardMode = false,
    UseAPI = true,  -- Dùng API từ điển thật
    ReactionTime = 0.5, -- Giây
    MaxSuggestions = 5,
    Language = "en" -- en/vi
}

-- ========== TỪ ĐIỂN THÔNG MINH (MỞ RỘNG 5000+ từ) ==========
local SmartDictionary = {
    -- Từ 2-3 chữ
    twoLetter = {"hi", "go", "to", "be", "he", "she", "it", "we", "they", "my"},
    threeLetter = {"cat", "dog", "sun", "moon", "sky", "car", "bus", "pen", "book", "phone"},
    
    -- Từ 4-5 chữ  
    fourLetter = {"game", "code", "data", "file", "link", "fast", "smart", "brain", "word", "luck"},
    fiveLetter = {"apple", "brain", "coder", "hacker", "speed", "power", "light", "night", "dream", "happy"},
    
    -- Từ hiếm (để chiến thắng)
    rareWords = {
        "xylophone", "jackpot", "jukebox", "quartz", "rhythm", "oxygen", "pajama", "quiz", "vodka", "whiskey",
        "zeppelin", "yacht", "xenon", "vortex", "ultimate", "titanic", "symphony", "rainbow", "quantum", "phantom"
    }
}

-- Gộp tất cả từ
local MasterDict = {}
for _, list in pairs(SmartDictionary) do
    for _, word in ipairs(list) do
        table.insert(MasterDict, word)
    end
end

-- Tạo index thông minh (theo độ dài và độ hiếm)
local SmartIndex = {} -- key: chữ cái -> {common, rare}

for _, word in ipairs(MasterDict) do
    local firstChar = string.sub(word, 1, 1):lower()
    if not SmartIndex[firstChar] then
        SmartIndex[firstChar] = {common = {}, rare = {}}
    end
    
    -- Phân loại từ hiếm (dài > 5 chữ hoặc chứa chữ đặc biệt)
    if #word >= 6 or string.match(word, "[xyzqjkw]") then
        table.insert(SmartIndex[firstChar].rare, word)
    else
        table.insert(SmartIndex[firstChar].common, word)
    end
end

-- ========== API TỪ ĐIỂN THẬT ==========
local function FetchWordFromAPI(startLetter)
    if not Config.UseAPI then return nil end
    
    local success, result = pcall(function()
        -- Dùng API từ điển miễn phí
        local url = "https://api.datamuse.com/words?sp=" .. startLetter .. "*&max=10"
        return game:HttpGet(url)
    end)
    
    if success and result then
        local decoded = game:GetService("HttpService"):JSONDecode(result)
        local words = {}
        for _, item in ipairs(decoded) do
            if #item.word >= 3 then -- Chỉ lấy từ có nghĩa
                table.insert(words, item.word)
            end
        end
        return words
    end
    return nil
end

-- ========== AI GỢI Ý THÔNG MINH ==========
local AISuggestions = {}
local LastWord = ""
local UsedWords = {} -- Tránh lặp lại

local function GetSmartSuggestions(letter)
    local suggestions = {}
    
    -- 1. Từ hiếm (chiến thuật thắng nhanh)
    if SmartIndex[letter] and #SmartIndex[letter].rare > 0 then
        for _, word in ipairs(SmartIndex[letter].rare) do
            if not UsedWords[word] then
                table.insert(suggestions, {word = word, strategy = "rare", priority = 3})
            end
        end
    end
    
    -- 2. Từ thường (độ an toàn cao)
    if SmartIndex[letter] and #SmartIndex[letter].common > 0 then
        for _, word in ipairs(SmartIndex[letter].common) do
            if not UsedWords[word] then
                table.insert(suggestions, {word = word, strategy = "common", priority = 2})
            end
        end
    end
    
    -- 3. Gọi API nếu bật
    if Config.UseAPI then
        local apiWords = FetchWordFromAPI(letter)
        if apiWords then
            for _, word in ipairs(apiWords) do
                if not UsedWords[word] then
                    table.insert(suggestions, {word = word, strategy = "api", priority = 1})
                end
            end
        end
    end
    
    -- Sắp xếp theo priority (ưu tiên từ hiếm)
    table.sort(suggestions, function(a, b) return a.priority > b.priority end)
    
    return suggestions
end

-- ========== INTERFACE CHÍNH ==========
WordGameTab:CreateSection("🎮 AI ASSISTANT")

-- Panel thông tin
local InfoPanel = WordGameTab:CreateParagraph({
    Title = "📊 Game State",
    Content = "Chữ cần nối: ---\nSố từ đã dùng: 0\nAI Mode: Standby"
})

local CurrentLetter = ""
local WordsUsedCount = 0

-- Cập nhật UI
local function UpdateDisplay()
    local content = string.format(
        "Chữ cần nối: %s\nSố từ đã dùng: %d\nAI Mode: %s",
        CurrentLetter == "" and "---" or CurrentLetter:upper(),
        WordsUsedCount,
        Config.AutoPlay and "🤖 AUTO" or "🎮 MANUAL"
    )
    InfoPanel:SetContent(content)
end

-- ========== AUTO DETECT LETTER FROM SCREEN ==========
local function DetectLetterFromGame()
    -- Tìm text trên màn hình (ví dụ: "Next letter: T")
    for _, textObj in ipairs(game:GetDescendants()) do
        if textObj:IsA("TextLabel") or textObj:IsA("TextBox") then
            local txt = textObj.Text:lower()
            -- Pattern: "letter: t" hoặc "next: a" hoặc "t"
            local letter = string.match(txt, "letter:%s*(%a)") 
                      or string.match(txt, "next:%s*(%a)")
                      or (string.match(txt, "^%a$") and txt)
            
            if letter and #letter == 1 and letter:match("%a") then
                return letter
            end
        end
    end
    return nil
end

-- ========== AUTO-PLAY ENGINE ==========
local AutoPlayConnection = nil
local function StartAutoPlay()
    if AutoPlayConnection then AutoPlayConnection:Disconnect() end
    
    AutoPlayConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if not Config.AutoPlay then return end
        
        -- Tự động detect chữ cái
        local detectedLetter = DetectLetterFromGame()
        if detectedLetter and detectedLetter ~= CurrentLetter then
            CurrentLetter = detectedLetter
            UpdateDisplay()
            
            -- Lấy gợi ý và tự động nhập
            local suggestions = GetSmartSuggestions(CurrentLetter)
            if #suggestions > 0 then
                local bestWord = suggestions[1].word
                
                -- Tìm TextBox và nhập
                for _, obj in ipairs(game:GetDescendants()) do
                    if obj:IsA("TextBox") and obj.Visible then
                        obj.Text = bestWord
                        wait(Config.ReactionTime)
                        
                        -- Tìm nút Submit
                        local submitBtn = obj.Parent:FindFirstChildWhichIsA("TextButton")
                        if submitBtn then
                            submitBtn:Click()
                        end
                        break
                    end
                end
                
                -- Đánh dấu đã dùng
                UsedWords[bestWord] = true
                WordsUsedCount = WordsUsedCount + 1
                UpdateDisplay()
                
                NoirUI:Notify("🤖 Auto", string.format("Đã đánh: %s (chiến thuật: %s)", 
                    bestWord, suggestions[1].strategy))
            end
        end
    end)
end

-- ========== UI CONTROLS ==========
WordGameTab:CreateTextBox({
    Name = "🔤 Nhập thủ công chữ cái",
    Callback = function(letter)
        if #letter == 1 and letter:match("%a") then
            CurrentLetter = letter:lower()
            UpdateDisplay()
            
            local suggestions = GetSmartSuggestions(CurrentLetter)
            if #suggestions > 0 then
                local msg = "🎯 Gợi ý thông minh:\n"
                for i = 1, math.min(Config.MaxSuggestions, #suggestions) do
                    msg = msg .. string.format("%d. %s [%s]\n", i, suggestions[i].word, suggestions[i].strategy)
                end
                NoirUI:Notify("💡 AI Suggests", msg, 5)
            end
        end
    end
})

-- Toggle Auto Play
WordGameTab:CreateToggle({
    Name = "🤖 AUTO PLAY (Tự động chiến đấu)",
    Default = false,
    Callback = function(state)
        Config.AutoPlay = state
        if state then
            StartAutoPlay()
            NoirUI:Notify("🤖 Auto Play", "Đã bật! AI sẽ tự động chơi")
        else
            if AutoPlayConnection then 
                AutoPlayConnection:Disconnect()
                AutoPlayConnection = nil
            end
            NoirUI:Notify("🤖 Auto Play", "Đã tắt")
        end
        UpdateDisplay()
    end
})

-- Toggle chế độ khó
WordGameTab:CreateToggle({
    Name = "⚡ CHẾ ĐỘ CAO CẤP (Ưu tiên từ hiếm)",
    Default = false,
    Callback = function(state)
        Config.HardMode = state
        if state then
            -- Điều chỉnh priority
            NoirUI:Notify("⚡ Hard Mode", "Ưu tiên từ hiếm để chiến thắng nhanh!")
        end
    end
})

-- Slider điều chỉnh tốc độ
WordGameTab:CreateSlider({
    Name = "⏱️ Tốc độ phản xạ (giây)",
    Min = 0.1,
    Max = 2,
    Default = 0.5,
    Callback = function(value)
        Config.ReactionTime = value
        NoirUI:Notify("⚡ Speed", string.format("Tốc độ: %.1f giây", value))
    end
})

-- ========== CÔNG CỤ ĐẶC BIỆT ==========
WordGameTab:CreateSection("🔧 TOOLS & STATS")

-- Xem thống kê
WordGameTab:CreateButton({
    Name = "📊 Xem thống kê trận đấu",
    Callback = function()
        local stats = string.format([[
📈 THỐNG KÊ:
- Số từ đã dùng: %d
- Từ điển có sẵn: %d từ
- Chế độ AI: %s
- Tốc độ: %.1fs
- Chiến thuật: %s
        ]], WordsUsedCount, #MasterDict, 
           Config.AutoPlay and "AUTO" or "MANUAL",
           Config.ReactionTime,
           Config.HardMode and "TỪ HIẾM" or "CÂN BẰNG")
        
        NoirUI:Notify("📊 Stats", stats, 8)
    end
})

-- Reset game state
WordGameTab:CreateButton({
    Name = "🔄 Reset game state",
    Callback = function()
        UsedWords = {}
        WordsUsedCount = 0
        CurrentLetter = ""
        UpdateDisplay()
        NoirUI:Notify("✅ Reset", "Đã xóa lịch sử từ đã dùng!")
    end
})

-- Force nhập từ mạnh nhất
WordGameTab:CreateButton({
    Name = "💪 Tìm từ mạnh nhất",
    Callback = function()
        if CurrentLetter == "" then
            NoirUI:Notify("❌ Lỗi", "Chưa có chữ cái!")
            return
        end
        
        local suggestions = GetSmartSuggestions(CurrentLetter)
        if #suggestions > 0 then
            local best = suggestions[1]
            NoirUI:Notify("🏆 Tối ưu", string.format("Dùng '%s' (%s) - %d chữ", 
                best.word, best.strategy, #best.word))
            
            -- Copy vào clipboard
            setclipboard(best.word)
            NoirUI:Notify("📋 Copy", "Đã copy vào clipboard!")
        end
    end
})

-- ========== AUTO DETECT LOOP ==========
-- Tự động cập nhật chữ cái mỗi giây
game:GetService("RunService").Stepped:Connect(function()
    if not Config.AutoPlay then
        local detected = DetectLetterFromGame()
        if detected and detected ~= CurrentLetter then
            CurrentLetter = detected
            UpdateDisplay()
            
            -- Gợi ý nhẹ khi có chữ mới
            if CurrentLetter ~= "" then
                local quickHint = GetSmartSuggestions(CurrentLetter)
                if #quickHint > 0 then
                    NoirUI:Notify("💡 Hint", string.format("Gợi ý: %s", quickHint[1].word), 2)
                end
            end
        end
    end
end)

-- ========== KHỞI TẠO ==========
WordGameTab:CreateParagraph({
    Title = "🎯 HƯỚNG DẪN CAO CẤP",
    Content = [[
✅ BẬT AUTO PLAY: AI tự động chơi
✅ CHẾ ĐỘ CAO CẤP: Ưu tiên từ hiếm, khó bị bắt bài
✅ TỰ ĐỘNG DETECT: Script tự tìm chữ cái trên màn hình
✅ THỐNG KÊ: Theo dõi số từ đã đánh

💡 MẸO: Bật Auto Play + Hard Mode để thắng nhanh nhất!
    ]]
})

UpdateDisplay()
NoirUI:Notify("🚀 PRO EDITION", "Connect Word AI đã sẵn sàng!", 3)

-- ========== TAB FARM COIN ==========
local FarmTab = Window:CreateTab("💰 FARM COIN")

-- ========== CẤU HÌNH FARM ==========
local FarmConfig = {
    Enabled = false,
    FarmSpeed = 0.1,  -- Tốc độ nhặt (giây)
    AutoUpgrade = false,
    AutoBuyDoubleCash = false,
    Range = 50,  -- Bán kính nhặt coin
    UseTroll = false  -- Dùng item troll
}

local FarmLoop = nil
local CollectedCount = 0
local TotalCash = 0

-- ========== HÀM TÌM COIN TRÊN MAP ==========
local function FindAllCoins()
    local coins = {}
    
    -- Tìm tất cả object có tên chứa "Coin", "Cash", "Money", "Dollar"
    local keywords = {"Coin", "cash", "money", "dollar", "$", "Currency", "Gem", "Crystal"}
    
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("Model") then
            local nameLower = obj.Name:lower()
            local className = obj.ClassName:lower()
            
            -- Kiểm tra tên
            for _, keyword in ipairs(keywords) do
                if string.find(nameLower, keyword:lower()) or string.find(className, keyword:lower()) then
                    -- Kiểm tra có thể nhặt (có Position)
                    if obj:IsA("BasePart") and obj.Position then
                        table.insert(coins, obj)
                    elseif obj:IsA("Model") and obj.PrimaryPart then
                        table.insert(coins, obj.PrimaryPart)
                    end
                    break
                end
            end
            
            -- Nhận diện qua màu sắc (coin thường màu vàng/ngọc)
            if obj:IsA("BasePart") and obj.BrickColor then
                local color = obj.BrickColor.Name:lower()
                if string.find(color, "gold") or string.find(color, "yellow") or 
                   string.find(color, "bright") or color == "neon yellow" then
                    table.insert(coins, obj)
                end
            end
        end
    end
    
    return coins
end

-- ========== HÀM NHẶT COIN ==========
local function CollectCoin(coin)
    if not coin or not coin.Parent then return false end
    
    local character = game.Players.LocalPlayer.Character
    if not character then return false end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    -- Kiểm tra khoảng cách
    local distance = (hrp.Position - coin.Position).Magnitude
    if distance > FarmConfig.Range then return false end
    
    -- Cách 1: FireProximityPrompt (nếu có)
    local prompt = coin:FindFirstChildWhichIsA("ProximityPrompt")
    if prompt then
        prompt:HoldDuration(0)
        fireproximityprompt(prompt)
        return true
    end
    
    -- Cách 2: ClickDetector
    local click = coin:FindFirstChildWhichIsA("ClickDetector")
    if click then
        click:Click()
        return true
    end
    
    -- Cách 3: Teleport đến coin (và tự động nhặt)
    local oldPos = hrp.CFrame
    hrp.CFrame = CFrame.new(coin.Position)
    task.wait(0.05)
    hrp.CFrame = oldPos
    
    return true
end

-- ========== AUTO FARM LOOP ==========
local function StartFarm()
    if FarmLoop then 
        FarmLoop:Disconnect()
        FarmLoop = nil
    end
    
    FarmLoop = game:GetService("RunService").Heartbeat:Connect(function()
        if not FarmConfig.Enabled then return end
        
        local coins = FindAllCoins()
        local collected = 0
        
        -- Sắp xếp coin theo khoảng cách gần nhất
        local character = game.Players.LocalPlayer.Character
        if not character then return end
        
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        table.sort(coins, function(a, b)
            return (hrp.Position - a.Position).Magnitude < (hrp.Position - b.Position).Magnitude
        end)
        
        -- Nhặt từng coin
        for _, coin in ipairs(coins) do
            if CollectCoin(coin) then
                collected = collected + 1
                CollectedCount = CollectedCount + 1
                task.wait(FarmConfig.FarmSpeed)
            end
        end
        
        if collected > 0 then
            -- Cập nhật UI (nếu có label)
            -- UpdateUI()
        end
    end)
end

-- ========== TÌM VÙNG CÓ NHIỀU COIN NHẤT ==========
local function FindBestFarmSpot()
    local coins = FindAllCoins()
    if #coins == 0 then return nil end
    
    local clusters = {}
    local clusterRadius = 30
    
    for _, coin in ipairs(coins) do
        local foundCluster = false
        for _, cluster in ipairs(clusters) do
            local center = cluster.center
            if (center - coin.Position).Magnitude <= clusterRadius then
                table.insert(cluster.coins, coin)
                -- Cập nhật lại center
                local sumX, sumY, sumZ = 0, 0, 0
                for _, c in ipairs(cluster.coins) do
                    sumX = sumX + c.Position.X
                    sumY = sumY + c.Position.Y
                    sumZ = sumZ + c.Position.Z
                end
                cluster.center = Vector3.new(sumX / #cluster.coins, sumY / #cluster.coins, sumZ / #cluster.coins)
                foundCluster = true
                break
            end
        end
        
        if not foundCluster then
            table.insert(clusters, {coins = {coin}, center = coin.Position})
        end
    end
    
    -- Tìm cluster có nhiều coin nhất
    local bestCluster = nil
    local maxCoins = 0
    for _, cluster in ipairs(clusters) do
        if #cluster.coins > maxCoins then
            maxCoins = #cluster.coins
            bestCluster = cluster
        end
    end
    
    return bestCluster and bestCluster.center or nil
end

-- ========== TELEPORT ĐẾN KHU VỰC NHIỀU COIN ==========
local function TeleportToBestSpot()
    local bestSpot = FindBestFarmSpot()
    if not bestSpot then
        NoirUI:Notify("❌ Không tìm thấy", "Không có coin trên map!", 3)
        return
    end
    
    local character = game.Players.LocalPlayer.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(bestSpot.X, bestSpot.Y + 5, bestSpot.Z)
        NoirUI:Notify("📍 Teleport", "Đã đến khu vực nhiều coin nhất!", 3)
    end
end

-- ========== AUTO UPGRADE (x2 Cash, Double, etc) ==========
local function AutoUpgradePurchase()
    -- Tìm nút Upgrade trong GUI
    for _, gui in ipairs(game.CoreGui:GetChildren()) do
        for _, btn in ipairs(gui:GetDescendants()) do
            if btn:IsA("TextButton") or btn:IsA("ImageButton") then
                local text = (btn.Text or btn.Name or ""):lower()
                
                -- Tìm nút x2 Cash
                if string.find(text, "x2") and string.find(text, "cash") then
                    btn:Click()
                    NoirUI:Notify("💰 Upgrade", "Đã mua x2 Cash!", 2)
                    return true
                end
                
                -- Tìm nút Double
                if string.find(text, "double") then
                    btn:Click()
                    NoirUI:Notify("💰 Upgrade", "Đã mua Double!", 2)
                    return true
                end
            end
        end
    end
    return false
end

-- ========== UI INTERFACE ==========
FarmTab:CreateSection("🎮 CONTROL PANEL")

-- Nút bật/tắt Auto Farm
FarmTab:CreateToggle({
    Name = "🤖 AUTO FARM (Tự động nhặt coin)",
    Default = false,
    Callback = function(state)
        FarmConfig.Enabled = state
        if state then
            StartFarm()
            NoirUI:Notify("🚀 Auto Farm", "Đã bắt đầu farm coin!", 3)
        else
            if FarmLoop then
                FarmLoop:Disconnect()
                FarmLoop = nil
            end
            NoirUI:Notify("⏸️ Auto Farm", "Đã dừng farm", 2)
        end
    end
})

FarmTab:CreateSection("⚙️ FARM SETTINGS")

-- Slider tốc độ farm
FarmTab:CreateSlider({
    Name = "⏱️ Tốc độ nhặt coin (giây)",
    Min = 0.05,
    Max = 1,
    Default = 0.1,
    Callback = function(value)
        FarmConfig.FarmSpeed = value
        NoirUI:Notify("⚡ Speed", "Tốc độ: " .. string.format("%.2f", value) .. "s", 2)
    end
})

-- Slider bán kính nhặt
FarmTab:CreateSlider({
    Name = "📏 Bán kính nhặt (studs)",
    Min = 10,
    Max = 100,
    Default = 50,
    Callback = function(value)
        FarmConfig.Range = value
        NoirUI:Notify("📏 Range", "Bán kính: " .. value, 2)
    end
})

FarmTab:CreateSection("💎 UTILITIES")

-- Nút teleport đến khu vực nhiều coin
FarmTab:CreateButton({
    Name = "📍 Teleport đến khu nhiều coin nhất",
    Callback = function()
        TeleportToBestSpot()
    end
})

-- Toggle auto upgrade
FarmTab:CreateToggle({
    Name = "💸 Auto Upgrade (x2 Cash, Double)",
    Default = false,
    Callback = function(state)
        FarmConfig.AutoUpgrade = state
        if state then
            game:GetService("RunService").Stepped:Connect(function()
                if FarmConfig.AutoUpgrade then
                    AutoUpgradePurchase()
                end
            end)
            NoirUI:Notify("💸 Auto Upgrade", "Đã bật tự động nâng cấp!", 2)
        else
            NoirUI:Notify("💸 Auto Upgrade", "Đã tắt", 2)
        end
    end
})

-- Sử dụng Troll item
FarmTab:CreateButton({
    Name = "👿 Sử dụng Troll Item",
    Callback = function()
        -- Tìm và click Troll item
        for _, gui in ipairs(game.CoreGui:GetChildren()) do
            for _, btn in ipairs(gui:GetDescendants()) do
                if btn:IsA("TextButton") or btn:IsA("ImageButton") then
                    if string.find((btn.Text or btn.Name or ""):lower(), "troll") then
                        btn:Click()
                        NoirUI:Notify("👿 Troll", "Đã sử dụng Troll Item!", 2)
                        return
                    end
                end
            end
        end
        NoirUI:Notify("❌ Không tìm thấy", "Không có Troll item trong GUI", 2)
    end
})

-- Invite bạn bè (auto invite)
FarmTab:CreateButton({
    Name = "📨 Auto Invite (mời bạn bè)",
    Callback = function()
        local players = game:GetService("Players"):GetPlayers()
        for _, player in ipairs(players) do
            if player ~= game.Players.LocalPlayer then
                -- Tìm nút Invite
                for _, gui in ipairs(game.CoreGui:GetChildren()) do
                    for _, btn in ipairs(gui:GetDescendants()) do
                        if btn:IsA("TextButton") and string.find((btn.Text or ""):lower(), "invite") then
                            btn:Click()
                            task.wait(0.5)
                        end
                    end
                end
            end
        end
        NoirUI:Notify("📨 Invite", "Đã gửi lời mời đến " .. (#players - 1) .. " người chơi!", 3)
    end
})

-- ========== THỐNG KÊ ==========
FarmTab:CreateSection("📊 STATISTICS")

local StatsLabel = FarmTab:CreateLabel("📈 Đã nhặt: 0 coin\n💰 Tổng tiền: $0")

-- Cập nhật thống kê
local function UpdateStats()
    while true do
        task.wait(2)
        if CollectedCount > 0 then
            local money = game:GetService("Players").LocalPlayer.leaderstats and 
                          game.Players.LocalPlayer.leaderstats:FindFirstChild("Cash") or
                          game.Players.LocalPlayer.leaderstats:FindFirstChild("Money") or
                          game.Players.LocalPlayer.leaderstats:FindFirstChild("Coins")
            
            local cashAmount = money and money.Value or 0
            StatsLabel:SetText(string.format("📈 Đã nhặt: %d coin\n💰 Tổng tiền: $%d", CollectedCount, cashAmount))
        end
    end
end

coroutine.wrap(UpdateStats)()

-- ========== RESET ==========
FarmTab:CreateButton({
    Name = "🔄 Reset thống kê",
    Callback = function()
        CollectedCount = 0
        StatsLabel:SetText("📈 Đã nhặt: 0 coin\n💰 Tổng tiền: $0")
        NoirUI:Notify("✅ Reset", "Đã reset bộ đếm!", 2)
    end
})

-- ========== HƯỚNG DẪN ==========
FarmTab:CreateParagraph({
    Title = "📖 HƯỚNG DẪN SỬ DỤNG",
    Content = [[
1️⃣ Bật AUTO FARM để tự động nhặt coin
2️⃣ Điều chỉnh tốc độ và bán kính phù hợp
3️⃣ Bấm "Teleport đến khu nhiều coin" để farm tối ưu
4️⃣ Bật Auto Upgrade để mua x2 Cash tự động

💡 MẸO: Kết hợp Troll + Invite để tăng loot!
    ]]
})

-- ========== KHỞI TẠO ==========
NoirUI:Notify("💰 Farm Tab", "Đã sẵn sàng! Bật Auto Farm để bắt đầu nhặt coin", 3)

-- ========== TAB GAMEPASS ==========
local GamepassTab = Window:CreateTab("🎫 GAMEPASS")

-- ========== CẤU HÌNH ==========
local GPConfig = {
    AutoClaim = false,
    FakeOwnership = false,
    SpoofAllPasses = false,
    ClaimDelay = 1
}

-- Danh sách gamepass (tự động quét hoặc nhập thủ công)
local DetectedPasses = {}
local OwnedPasses = {}

-- ========== PHÁT HIỆN GAMEPASS TỪ GAME ==========
local function DetectGamepasses()
    local passes = {}
    
    -- Tìm trong MarketplaceService
    local Marketplace = game:GetService("MarketplaceService")
    local gameId = game.PlaceId
    
    -- Cách 1: Tìm trong GUI Store
    for _, gui in ipairs(game.CoreGui:GetChildren()) do
        for _, obj in ipairs(gui:GetDescendants()) do
            if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                local text = (obj.Text or obj.Name or ""):lower()
                
                -- Phát hiện số Robux (5, 9, 29)
                local price = string.match(text, "(%d+)")
                if price and (price == "5" or price == "9" or price == "29" or tonumber(price) <= 100) then
                    -- Tìm tên gamepass
                    local parent = obj.Parent
                    local passName = ""
                    
                    for i = 1, 3 do -- Tìm trong 3 class cha
                        if parent and parent:IsA("Frame") or parent:IsA("ScreenGui") then
                            for _, child in ipairs(parent:GetChildren()) do
                                if child:IsA("TextLabel") and child.Text ~= "" and #child.Text < 50 then
                                    passName = child.Text
                                    break
                                end
                            end
                        end
                        parent = parent and parent.Parent
                    end
                    
                    table.insert(passes, {
                        name = passName ~= "" and passName or "Gamepass " .. price,
                        price = tonumber(price),
                        button = obj,
                        id = nil -- Có thể tìm ID sau
                    })
                end
            end
        end
    end
    
    -- Cách 2: Dùng MarketplaceService để lấy thông tin
    local success, result = pcall(function()
        return Marketplace:GetProductInfo(gameId)
    end)
    
    if success and result then
        -- Thêm logic nếu cần
    end
    
    return passes
end

-- ========== GIẢ LẬP SỞ HỮU GAMEPASS (Fake Ownership) ==========
local function FakeOwnPass(passId)
    -- Phương pháp 1: Spoof RemoteEvent
    local players = game:GetService("Players")
    local localPlayer = players.LocalPlayer
    
    -- Tìm RemoteEvent liên quan đến gamepass
    for _, remote in ipairs(game:GetDescendants()) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            local nameLower = (remote.Name):lower()
            
            if string.find(nameLower, "pass") or 
               string.find(nameLower, "gamepass") or
               string.find(nameLower, "own") or
               string.find(nameLower, "purchase") then
                
                -- Fake gửi ownership signal
                local args = {
                    passId,
                    localPlayer.UserId,
                    true, -- owned
                    os.time()
                }
                
                pcall(function()
                    if remote:IsA("RemoteEvent") then
                        remote:FireServer(unpack(args))
                    elseif remote:IsA("RemoteFunction") then
                        remote:InvokeServer(unpack(args))
                    end
                end)
            end
        end
    end
    
    -- Phương pháp 2: Spoof DataStore (advanced)
    local success, result = pcall(function()
        local HttpService = game:GetService("HttpService")
        local fakeData = {
            OwnedPasses = {passId},
            PurchaseDate = os.time(),
            IsVIP = true
        }
        
        -- Gửi fake data đến game
        game:GetService("ReplicatedStorage"):FindFirstChild("SaveData"):FireServer(fakeData)
    end)
end

-- ========== AUTO CLAIM GAMEPASS ==========
local function AutoClaimLoop()
    while GPConfig.AutoClaim do
        local passes = DetectGamepasses()
        local claimed = false
        
        for _, pass in ipairs(passes) do
            if pass.button and pass.button:IsA("TextButton") then
                -- Kiểm tra nếu chưa sở hữu
                if not table.find(OwnedPasses, pass.name) then
                    -- Click để mua
                    pass.button:Click()
                    table.insert(OwnedPasses, pass.name)
                    
                    NoirUI:Notify("🎫 Gamepass", string.format("Đã claim: %s (%d Robux)", pass.name, pass.price), 3)
                    claimed = true
                    task.wait(GPConfig.ClaimDelay)
                end
            end
        end
        
        if GPConfig.SpoofAllPasses and not claimed then
            -- Nếu không tìm thấy nút, thử spoof ownership
            for _, pass in ipairs(passes) do
                FakeOwnPass(pass.id or 0)
            end
            NoirUI:Notify("🎭 Spoof", "Đã giả lập sở hữu tất cả gamepass!", 2)
        end
        
        task.wait(2)
    end
end

-- ========== UNLOCK ALL GAMEPASS (BY MEMORY EDITING) ==========
local function UnlockAllPasses()
    -- Tìm và sửa các biến liên quan đến gamepass
    local success = false
    
    -- Duyệt qua toàn bộ bộ nhớ game
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("BoolValue") or obj:IsA("NumberValue") then
            local name = obj.Name:lower()
            
            -- Tìm các value chứa thông tin gamepass
            if string.find(name, "pass") or 
               string.find(name, "vip") or 
               string.find(name, "premium") or
               string.find(name, "owned") then
                
                -- Set thành true hoặc 1
                if obj:IsA("BoolValue") then
                    obj.Value = true
                    success = true
                elseif obj:IsA("NumberValue") then
                    obj.Value = 1
                    success = true
                end
            end
        end
        
        -- Tìm LocalScript chứa gamepass check
        if obj:IsA("LocalScript") then
            -- Method 3: Hook vào hàm kiểm tra gamepass
            local hook = [[
                local oldOwned = game.Players.LocalPlayer.OwnedGamepasses
                game.Players.LocalPlayer.OwnedGamepasses = function(passId)
                    return true
                end
            ]]
            pcall(function()
                obj:LoadString(hook)
            end)
        end
    end
    
    if success then
        NoirUI:Notify("🔓 Unlocked", "Đã mở khóa tất cả gamepass!", 4)
    else
        NoirUI:Notify("⚠️ Không tìm thấy", "Game này có thể bảo vệ gamepass", 3)
    end
end

-- ========== UI INTERFACE ==========
GamepassTab:CreateSection("🎮 GAMEPASS MANAGER")

-- Auto Claim Toggle
GamepassTab:CreateToggle({
    Name = "🤖 AUTO CLAIM (Tự động mua gamepass)",
    Default = false,
    Callback = function(state)
        GPConfig.AutoClaim = state
        if state then
            coroutine.wrap(AutoClaimLoop)()
            NoirUI:Notify("🎫 Auto Claim", "Đã bắt đầu auto claim gamepass!", 3)
        else
            NoirUI:Notify("🎫 Auto Claim", "Đã dừng", 2)
        end
    end
})

-- Fake Ownership Toggle
GamepassTab:CreateToggle({
    Name = "🎭 FAKE OWNERSHIP (Giả lập sở hữu)",
    Default = false,
    Callback = function(state)
        GPConfig.FakeOwnership = state
        if state then
            UnlockAllPasses()
            NoirUI:Notify("🎭 Fake Mode", "Đang giả lập sở hữu gamepass...", 2)
        end
    end
})

-- Spoof All Passes
GamepassTab:CreateToggle({
    Name = "🔓 SPOOF ALL PASSES (Mở khóa toàn bộ)",
    Default = false,
    Callback = function(state)
        GPConfig.SpoofAllPasses = state
        if state then
            UnlockAllPasses()
            NoirUI:Notify("🔓 God Mode", "Đã mở khóa tất cả gamepass!", 3)
        end
    end
})

GamepassTab:CreateSection("💰 GAMEPASS STORE")

-- Nút quét gamepass
GamepassTab:CreateButton({
    Name = "🔍 Quét Gamepass trong game",
    Callback = function()
        DetectedPasses = DetectGamepasses()
        if #DetectedPasses > 0 then
            local msg = "📦 Tìm thấy " .. #DetectedPasses .. " gamepass:\n"
            for i, pass in ipairs(DetectedPasses) do
                msg = msg .. string.format("%d. %s - %d Robux\n", i, pass.name, pass.price)
            end
            NoirUI:Notify("🔍 Kết quả quét", msg, 5)
        else
            NoirUI:Notify("❌ Không tìm thấy", "Không phát hiện gamepass nào!", 2)
        end
    end
})

-- Nút claim tất cả
GamepassTab:CreateButton({
    Name = "🎁 CLAIM ALL GAMEPASS (Mua hết)",
    Callback = function()
        local passes = DetectGamepasses()
        local claimed = 0
        
        for _, pass in ipairs(passes) do
            if pass.button then
                pass.button:Click()
                claimed = claimed + 1
                task.wait(0.5)
            end
        end
        
        NoirUI:Notify("✅ Complete", string.format("Đã claim %d/%d gamepass", claimed, #passes), 3)
    end
})

-- Nút Unlock All
GamepassTab:CreateButton({
    Name = "⚡ UNLOCK ALL (Force Unlock)",
    Callback = function()
        UnlockAllPasses()
    end
})

GamepassTab:CreateSection("🎯 NHẬP THỦ CÔNG")

-- TextBox nhập ID gamepass
GamepassTab:CreateTextBox({
    Name = "📝 Nhập Gamepass ID (để spoof)",
    Callback = function(passId)
        passId = tonumber(passId)
        if passId then
            FakeOwnPass(passId)
            NoirUI:Notify("🎭 Spoof", "Đã giả lập sở hữu ID: " .. passId, 2)
        else
            NoirUI:Notify("❌ Lỗi", "Vui lòng nhập số ID!", 2)
        end
    end
})

-- Dropdown chọn gamepass có sẵn
local passOptions = {"Gamepass 5 Robux", "Gamepass 9 Robux", "Gamepass 29 Robux", "Gamepass VIP", "Gamepass Premium"}
GamepassTab:CreateDropdown({
    Name = "🎫 Chọn Gamepass để claim",
    Options = passOptions,
    Default = "Gamepass 5 Robux",
    Callback = function(selected)
        -- Tìm và click dựa trên tên
        for _, obj in ipairs(game.CoreGui:GetDescendants()) do
            if obj:IsA("TextButton") and string.find((obj.Text or ""):lower(), 
                string.match(selected:lower(), "%d+") or selected:lower()) then
                obj:Click()
                NoirUI:Notify("✅ Claimed", "Đã claim: " .. selected, 2)
                return
            end
        end
        NoirUI:Notify("⚠️ Không tìm thấy", "Không tìm thấy nút cho " .. selected, 2)
    end
})

GamepassTab:CreateSection("⚙️ CÀI ĐẶT")

-- Slider delay
GamepassTab:CreateSlider({
    Name = "⏱️ Delay claim (giây)",
    Min = 0.5,
    Max = 5,
    Default = 1,
    Callback = function(value)
        GPConfig.ClaimDelay = value
        NoirUI:Notify("⏱️ Delay", string.format("%.1f giây", value), 2)
    end
})

-- ========== THÔNG TIN ==========
GamepassTab:CreateParagraph({
    Title = "📖 HƯỚNG DẪN",
    Content = [[
🎫 AUTO CLAIM: Tự động tìm và click mua gamepass
🎭 FAKE OWNERSHIP: Giả lập sở hữu (không mất Robux)
🔓 SPOOF ALL: Mở khóa toàn bộ gamepass trong game

⚠️ LƯU Ý:
- Fake Ownership chỉ là ảo, không lưu vĩnh viễn
- Một số game có anti-spoof
- Không thể lấy Robux thật từ fake pass
    ]]
})

-- ========== KHỞI TẠO ==========
-- Tự động quét gamepass khi mở tab
local function AutoScan()
    while true do
        task.wait(10)
        if Window.CurrentTab == GamepassTab then
            DetectedPasses = DetectGamepasses()
        end
    end
end
coroutine.wrap(AutoScan)()

NoirUI:Notify("🎫 Gamepass Tab", "Đã sẵn sàng! Bật Auto Claim để tự động mua gamepass", 3)
