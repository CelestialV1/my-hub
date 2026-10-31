print("CELESTIAL v8.0 — BINDS & CONFIG UPDATE")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local CELESTIAL_ASSET = "rbxassetid://94872985442978"
local VERSION = "8.0"

-- ============================================================
-- CONFIG & BINDS
-- ============================================================
local CONFIG = {
    Accent = Color3.fromRGB(160, 110, 255),
    Accent2 = Color3.fromRGB(255, 100, 200),
    Bg = Color3.fromRGB(8, 8, 12),
    CardBg = Color3.fromRGB(18, 18, 24),
    Text = Color3.fromRGB(240, 240, 250),
    TextDark = Color3.fromRGB(140, 140, 160),
    
    AimbotEnabled = false, AimbotKey = Enum.KeyCode.E,
    AimbotFOV = 200, AimbotSmooth = 0.35, AimbotPart = "Head",
    AimbotAutoFire = false, AimbotVisible = false,
    KillAuraEnabled = false, KillAuraRange = 25, KillAuraDelay = 0.1,
    
    ESPEnabled = true, ESPBox = true, ESPHealth = true,
    ESPName = true, ESPDistance = true, ESPSkeleton = true,
    ESPWeapon = true, ESPTracer = true, ESPHeadDot = true,
    ESPMaxDist = 1500,

    WingsEnabled = false, CrownEnabled = false, HaloEnabled = false,
    AuraEnabled = false, OrbitEnabled = false, GroundCircle = false,

    Fullbright = false, NoFog = false,

    FlyEnabled = false, FlySpeed = 60, NoclipEnabled = false,
    SpeedEnabled = false, WalkSpeed = 50, JumpPower = 50,
    InfiniteJump = false,
}

-- Здесь хранятся бинды для функций (можно менять)
local BINDS = {
    Fly = Enum.KeyCode.Unknown,
    Noclip = Enum.KeyCode.Unknown,
    Speed = Enum.KeyCode.Unknown,
    ESP = Enum.KeyCode.Unknown,
    Aimbot = Enum.KeyCode.Unknown,
    KillAura = Enum.KeyCode.Unknown,
    Fling = Enum.KeyCode.Unknown,
    Invisible = Enum.KeyCode.Unknown,
    Menu = Enum.KeyCode.H
}

local State = {
    Running = true,
    Connections = {},
    Drawings = {},
    ESPCache = {},
    ChamsCache = {},
    ThemeObjects = {},
    Cosmetics = {},
    menuFrame = nil,
    mainGui = nil,
    WaitingForBind = nil, -- Для окна привязки
}

local function Track(c) if State.Running and c then table.insert(State.Connections, c) end return c end
local function TrackD(d) if State.Running and d then table.insert(State.Drawings, d) end return d end
local function RegisterTheme(o) if State.Running then table.insert(State.ThemeObjects, o) end return o end

local Draw = Drawing.new
local FOVCircle = TrackD(Draw("Circle"))
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 64
FOVCircle.Color = CONFIG.Accent
FOVCircle.Transparency = 0.9
FOVCircle.Radius = CONFIG.AimbotFOV
FOVCircle.Visible = false

local function Create(c, p, ch)
    local i = Instance.new(c)
    for k, v in pairs(p) do i[k] = v end
    if ch then for _, c2 in ipairs(ch) do c2.Parent = i end end
    return i
end
local function Corner(r) return Create("UICorner", { CornerRadius = UDim.new(0, r) }) end
local function ApplyGradient(stroke)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(CONFIG.Accent, CONFIG.Accent2)
    g.Rotation = 45
    g.Parent = stroke
end

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
local notifGui = Create("ScreenGui", { Name = "CelestialNotifs", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 1002, Parent = LocalPlayer:WaitForChild("PlayerGui") })
local notifFrame = Create("Frame", { Parent = notifGui, Size = UDim2.new(0, 320, 1, 0), Position = UDim2.new(1, -340, 0, 100), BackgroundTransparency = 1, ZIndex = 5 })
Create("UIListLayout", { Parent = notifFrame, Padding = UDim.new(0, 6) })

local function Notify(text, duration)
    duration = duration or 2.5
    local card = Create("Frame", { Parent = notifFrame, Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = CONFIG.CardBg, BackgroundTransparency = 0.1, BorderSizePixel = 0, ZIndex = 6 }, { Corner(8) })
    local s = Create("UIStroke", { Parent = card, Color = CONFIG.Accent, Thickness = 1, Transparency = 0.3 })
    ApplyGradient(s)
    Create("Frame", { Parent = card, Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = CONFIG.Accent, BorderSizePixel = 0, ZIndex = 7 }, { Corner(2) })
    Create("TextLabel", { Parent = card, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = text, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7 })
    card.Position = UDim2.new(1, 20, 0, 0)
    TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(0, 0, 0, 0) }):Play()
    task.delay(duration, function()
        TweenService:Create(card, TweenInfo.new(0.25), { Position = UDim2.new(1, 20, 0, 0) }):Play()
        task.delay(0.25, function() card:Destroy() end)
    end)
end

-- ============================================================
-- COSMETICS (Fixed Wings & Crown)
-- ============================================================
local function BuildCosmetics()
    if not State.Cosmetics.Halo then
        local m = Instance.new("Model", Workspace); m.Name = "Celestial_Halo"
        for i = 1, 20 do
            local b = Instance.new("Part", m)
            b.Name = "HaloBall"; b.Shape = Enum.PartType.Ball
            b.Size = Vector3.new(0.28,0.28,0.28); b.Material = Enum.Material.Neon
            b.Color = CONFIG.Accent; b.Transparency = 0.1
            b.CanCollide = false; b.CanQuery = false; b.Anchored = true
        end
        State.Cosmetics.Halo = m
    end
    if not State.Cosmetics.Crown then
        local c = Instance.new("Part", Workspace); c.Name = "Celestial_Crown"
        c.Size = Vector3.new(1.5,1,1.5); c.Transparency = 1
        c.CanCollide = false; c.CanQuery = false; c.Anchored = true
        local mesh = Instance.new("SpecialMesh", c)
        mesh.MeshType = Enum.MeshType.FileMesh
        mesh.MeshId = "rbxassetid://176213013" -- Классическая корона
        mesh.Scale = Vector3.new(0.9,0.9,0.9)
        State.Cosmetics.Crown = c
    end
    if not State.Cosmetics.Wings then
        local m = Instance.new("Model", Workspace); m.Name = "Celestial_Wings"
        for _ = 1, 16 do
            local p = Instance.new("Part", m)
            p.Name = "WingBeam"; p.Anchored = true
            p.CanCollide = false; p.CanQuery = false
            p.Transparency = 1; p.Size = Vector3.new(0.2,0.2,0.2)
            p.Material = Enum.Material.Neon
        end
        State.Cosmetics.Wings = m
    end
    if not State.Cosmetics.GroundCircle then
        local gc = Instance.new("Part", Workspace); gc.Name = "Celestial_GroundCircle"
        gc.Shape = Enum.PartType.Cylinder; gc.Size = Vector3.new(0.1, 10, 10)
        gc.Material = Enum.Material.Neon; gc.Color = CONFIG.Accent
        gc.Transparency = 0.5; gc.CanCollide = false; gc.CanQuery = false
        gc.Anchored = true
        State.Cosmetics.GroundCircle = gc
    end
end

local function UpdateCosmetics()
    local char = LocalPlayer.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local t = tick()

    if State.Cosmetics.Halo and head then
        State.Cosmetics.Halo.Parent = CONFIG.HaloEnabled and Workspace or nil
        if CONFIG.HaloEnabled then
            for i, b in ipairs(State.Cosmetics.Halo:GetChildren()) do
                if b.Name == "HaloBall" then
                    local a = (i/20) * math.pi * 2 + t*2
                    b.CFrame = head.CFrame * CFrame.new(math.cos(a)*1.6, 1.3, math.sin(a)*1.6)
                    b.Color = Color3.fromHSV((t*0.2 + i/20) % 1, 0.8, 1)
                end
            end
        end
    end
    if State.Cosmetics.Crown and head then
        State.Cosmetics.Crown.Parent = CONFIG.CrownEnabled and Workspace or nil
        if CONFIG.CrownEnabled then
            State.Cosmetics.Crown.CFrame = head.CFrame * CFrame.new(0,0.75,0)
            State.Cosmetics.Crown.Color = CONFIG.Accent
        end
    end
    if State.Cosmetics.Wings and hrp then
        State.Cosmetics.Wings.Parent = CONFIG.WingsEnabled and Workspace or nil
        if CONFIG.WingsEnabled then
            local parts = State.Cosmetics.Wings:GetChildren()
            local idx = 1
            for _, side in ipairs({-1,1}) do
                for i = 1, 8 do
                    local p = parts[idx]; idx += 1
                    if p then
                        local s = i/8
                        p.CFrame = hrp.CFrame * CFrame.new(side*(0.5+s*3.5), 1+s*3, -0.5-s*1)
                        p.Size = Vector3.new(0.2,0.2,0.2)
                        p.Color = Color3.fromHSV((t*0.3 + i*0.1) % 1, 0.8, 1)
                        p.Transparency = 0
                    end
                end
            end
        end
    end
    if State.Cosmetics.GroundCircle and hrp then
        State.Cosmetics.GroundCircle.Parent = CONFIG.GroundCircle and Workspace or nil
        if CONFIG.GroundCircle then
            State.Cosmetics.GroundCircle.CFrame = CFrame.new(hrp.Position - Vector3.new(0, hrp.Size.Y/2 + 0.1, 0)) * CFrame.Angles(math.rad(90), 0, 0)
            State.Cosmetics.GroundCircle.Color = CONFIG.Accent
            State.Cosmetics.GroundCircle.Transparency = 0.5 + math.sin(t*3)*0.1
        end
    end
end

-- ============================================================
-- CHAMS & ESP
-- ============================================================
local function ApplyChams(char)
    if not char then return end
    local hl = char:FindFirstChild("Celestial_Chams")
    if not hl then
        hl = Instance.new("Highlight", char)
        hl.Name = "Celestial_Chams"
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
    end
    hl.FillColor = CONFIG.ChamsRainbow and Color3.fromHSV(tick() % 1, 1, 1) or CONFIG.Accent
    hl.OutlineColor = hl.FillColor
end

local function RemoveChams(char)
    if char then
        local hl = char:FindFirstChild("Celestial_Chams")
        if hl then hl:Destroy() end
    end
end

-- ============================================================
-- MOVEMENT / TROLL FIX (Убрал сломанную физику)
-- ============================================================
local function StopFly()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        for _, c in ipairs(hrp:GetChildren()) do
            if c.Name == "Celestial_FlyBV" or c.Name == "Celestial_FlyBG" then c:Destroy() end
        end
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
end

local function ForceFling(char)
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    pcall(function()
        -- Убрал смену состояния, чтобы не ломать звуки
        local bv = Instance.new("BodyVelocity", hrp)
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = Vector3.new(1e5, 1e5, 1e5)
        Debris:AddItem(bv, 0.4)
    end)
end

local function ApplyGhost()
    local char = LocalPlayer.Character
    if not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Transparency = 1
            v.LocalTransparencyModifier = 1
            if v.Name ~= "HumanoidRootPart" then v.CanCollide = false end
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        end
    end
end

local function RestoreVis()
    local char = LocalPlayer.Character
    if not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Transparency = 0
            v.LocalTransparencyModifier = 0
            if v.Name ~= "HumanoidRootPart" then v.CanCollide = true end
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 0
        end
    end
end

-- ============================================================
-- UI BUILD
-- ============================================================
local function BuildUI()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local gui = Create("ScreenGui", { Name = "CelestialUI", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 999, Parent = playerGui })
    State.mainGui = gui

    local menu = Create("Frame", {
        Parent = gui, Size = UDim2.new(0, 640, 0, 460),
        Position = UDim2.new(0.5, -320, 1, 500),
        BackgroundColor3 = CONFIG.Bg, BackgroundTransparency = 0.02,
        BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 2,
    }, { Corner(14) })
    State.menuFrame = menu

    local ms = Create("UIStroke", { Parent = menu, Thickness = 1.5, Transparency = 0.2, Color = CONFIG.Accent })
    ApplyGradient(ms)

    local header = Create("Frame", { Parent = menu, Size = UDim2.new(1,0,0,62), BackgroundTransparency = 1, ZIndex = 3 })
    
    -- Title and Close
    Create("TextLabel", { Parent = header, Size = UDim2.new(0,200,0,22), Position = UDim2.new(0,20,0,12), BackgroundTransparency = 1, Text = "Celestial v"..VERSION, Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 })
    local closeBtn = Create("TextButton", { Parent = header, Size = UDim2.new(0,32,0,32), Position = UDim2.new(1,-46,0.5,-16), BackgroundColor3 = Color3.fromRGB(35,35,45), Text = "×", Font = Enum.Font.GothamBold, TextSize = 22, TextColor3 = CONFIG.TextDark, BorderSizePixel = 0, AutoButtonColor = false, ZIndex = 4 }, { Corner(10) })
    closeBtn.MouseButton1Click:Connect(function()
        TweenService:Create(menu, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Position = UDim2.new(0.5, -320, 1, 500) }):Play()
        task.wait(0.3); menu.Visible = false
    end)

    -- Sidebar
    local sidebar = Create("Frame", { Parent = menu, Size = UDim2.new(0,160,1,-80), Position = UDim2.new(0,20,0,72), BackgroundTransparency = 1, ZIndex = 3 })
    Create("UIListLayout", { Parent = sidebar, Padding = UDim.new(0,6) })
    local content = Create("Frame", { Parent = menu, Size = UDim2.new(1,-200,1,-80), Position = UDim2.new(0,180,0,72), BackgroundTransparency = 1, ZIndex = 3 })

    local Pages = {}
    local function CreateTab(name, icon)
        local btn = Create("TextButton", { Parent = sidebar, Size = UDim2.new(1,0,0,36), BackgroundColor3 = Color3.fromRGB(24,24,32), BackgroundTransparency = 0.4, Text = "  "..icon.."   "..name, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = CONFIG.TextDark, TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, AutoButtonColor = false, ZIndex = 4 }, { Corner(8) })
        local page = Create("ScrollingFrame", { Parent = content, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Visible = false, ScrollBarThickness = 2, ScrollBarImageColor3 = CONFIG.Accent, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0,0,0,0), BorderSizePixel = 0, ZIndex = 3 })
        Create("UIListLayout", { Parent = page, Padding = UDim.new(0,10) })
        Pages[name] = { btn = btn, page = page }
        btn.MouseButton1Click:Connect(function()
            for n, p in pairs(Pages) do p.page.Visible = (n == name); TweenService:Create(p.btn, TweenInfo.new(0.2), { TextColor3 = (n == name) and CONFIG.Accent or CONFIG.TextDark }):Play() end
        end)
        return page
    end

    local function CreateCard(parent, title)
        local card = Create("Frame", { Parent = parent, Size = UDim2.new(1,-8,0,0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = CONFIG.CardBg, BackgroundTransparency = 0.15, BorderSizePixel = 0, ZIndex = 4 }, { Corner(10) })
        Create("UIStroke", { Parent = card, Color = Color3.fromRGB(50,50,65), Thickness = 1, Transparency = 0.4 })
        Create("UIPadding", { Parent = card, PaddingTop = UDim.new(0,14), PaddingBottom = UDim.new(0,14), PaddingLeft = UDim.new(0,14), PaddingRight = UDim.new(0,14) })
        Create("UIListLayout", { Parent = card, Padding = UDim.new(0,10) })
        if title then Create("TextLabel", { Parent = card, Size = UDim2.new(1,0,0,14), BackgroundTransparency = 1, Text = title:upper(), Font = Enum.Font.GothamMedium, TextSize = 10, TextColor3 = CONFIG.Accent, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 }) end
        return card
    end

    -- Функция создания тумблера с привязкой
    local function CreateToggle(parent, text, key, default, cb)
        local row = Create("Frame", { Parent = parent, Size = UDim2.new(1,0,0,28), BackgroundTransparency = 1 })
        
        -- Кнопка бинда
        local bindBtn = Create("TextButton", { Parent = row, Size = UDim2.new(0,50,0,20), Position = UDim2.new(1,-70,0.5,-10), BackgroundColor3 = Color3.fromRGB(35,35,45), Text = BINDS[key] and BINDS[key].Name or "None", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = CONFIG.TextDark, BorderSizePixel = 0, ZIndex = 6 }, { Corner(4) })
        bindBtn.MouseButton1Click:Connect(function()
            if State.WaitingForBind then return end
            bindBtn.Text = "..."
            State.WaitingForBind = function(kc)
                BINDS[key] = kc
                bindBtn.Text = kc.Name
                State.WaitingForBind = nil
                Notify("Binded "..text.." to "..kc.Name, 1.5)
            end
        end)

        local sw = Create("Frame", { Parent = row, Size = UDim2.new(0,28,0,14), Position = UDim2.new(1,-28,0.5,-7), BackgroundColor3 = default and CONFIG.Accent or Color3.fromRGB(40,40,50), BorderSizePixel = 0, ZIndex = 5 }, { Corner(7) })
        local kn = Create("Frame", { Parent = sw, Size = UDim2.new(0,10,0,10), Position = default and UDim2.new(1,-12,0.5,-5) or UDim2.new(0,2,0.5,-5), BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, ZIndex = 6 }, { Corner(5) })
        local label = Create("TextLabel", { Parent = row, Size = UDim2.new(1,-120,1,0), BackgroundTransparency = 1, Text = text, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 })
        
        local state = default
        local click = Create("TextButton", { Parent = row, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "", ZIndex = 7 })
        click.MouseButton1Click:Connect(function()
            state = not state
            TweenService:Create(sw, TweenInfo.new(0.2), { BackgroundColor3 = state and CONFIG.Accent or Color3.fromRGB(40,40,50) }):Play()
            TweenService:Create(kn, TweenInfo.new(0.2), { Position = state and UDim2.new(1,-12,0.5,-5) or UDim2.new(0,2,0.5,-5) }):Play()
            cb(state)
        end)
    end

    -- Вкладки
    local MainTab = CreateTab("Main", "🏠")
    local CombatTab = CreateTab("Combat", "⚔️")
    local VisualTab = CreateTab("Visuals", "👁️")
    local CosmeticsTab = CreateTab("Cosmetics", "✨")
    local SettingsTab = CreateTab("Configs", "⚙️")

    -- Main / Movement
    local moveCard = CreateCard(MainTab, "Movement")
    CreateToggle(moveCard, "Fly", "Fly", CONFIG.FlyEnabled, function(v) CONFIG.FlyEnabled = v; if not v then StopFly() end end)
    CreateToggle(moveCard, "Noclip", "Noclip", CONFIG.NoclipEnabled, function(v) CONFIG.NoclipEnabled = v end)
    CreateToggle(moveCard, "Speed", "Speed", CONFIG.SpeedEnabled, function(v) CONFIG.SpeedEnabled = v end)
    CreateToggle(moveCard, "Infinite Jump", "InfiniteJump", CONFIG.InfiniteJump, function(v) CONFIG.InfiniteJump = v end)

    -- Combat
    local combatCard = CreateCard(CombatTab, "Combat")
    CreateToggle(combatCard, "Aimbot", "Aimbot", CONFIG.AimbotEnabled, function(v) CONFIG.AimbotEnabled = v end)
    CreateToggle(combatCard, "Kill Aura", "KillAura", CONFIG.KillAuraEnabled, function(v) CONFIG.KillAuraEnabled = v end)
    CreateToggle(combatCard, "Fling", "Fling", false, function(v) CONFIG.FlingEnabled = v end)

    -- Visuals
    local visCard = CreateCard(VisualTab, "ESP")
    CreateToggle(visCard, "Enable ESP", "ESP", CONFIG.ESPEnabled, function(v) CONFIG.ESPEnabled = v end)
    CreateToggle(visCard, "Box", "ESPBox", CONFIG.ESPBox, function(v) CONFIG.ESPBox = v end)
    CreateToggle(visCard, "Name", "ESPName", CONFIG.ESPName, function(v) CONFIG.ESPName = v end)
    CreateToggle(visCard, "Health", "ESPHealth", CONFIG.ESPHealth, function(v) CONFIG.ESPHealth = v end)

    -- Cosmetics
    local cosCard = CreateCard(CosmeticsTab, "Auras & Cosmetics")
    CreateToggle(cosCard, "Halo", "Halo", CONFIG.HaloEnabled, function(v) CONFIG.HaloEnabled = v end)
    CreateToggle(cosCard, "Wings", "Wings", CONFIG.WingsEnabled, function(v) CONFIG.WingsEnabled = v end)
    CreateToggle(cosCard, "Crown", "Crown", CONFIG.CrownEnabled, function(v) CONFIG.CrownEnabled = v end)
    CreateToggle(cosCard, "Ground Circle", "Circle", CONFIG.GroundCircle, function(v) CONFIG.GroundCircle = v end)

    -- Configs
    local confCard = CreateCard(SettingsTab, "Config System")
    local saveBtn = Create("TextButton", { Parent = confCard, Size = UDim2.new(1,0,0,30), BackgroundColor3 = Color3.fromRGB(30,30,40), Text = "Save Config", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = CONFIG.Text, BorderSizePixel = 0 }, { Corner(6) })
    saveBtn.MouseButton1Click:Connect(function()
        local data = HttpService:JSONEncode(CONFIG)
        if writefile then
            writefile("CelestialConfig.json", data)
            Notify("Config Saved!", 2)
        else
            Notify("Executor does not support writefile", 2)
        end
    end)
    
    local loadBtn = Create("TextButton", { Parent = confCard, Size = UDim2.new(1,0,0,30), BackgroundColor3 = Color3.fromRGB(30,30,40), Text = "Load Config", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = CONFIG.Text, BorderSizePixel = 0 }, { Corner(6) })
    loadBtn.MouseButton1Click:Connect(function()
        if readfile and isfile and isfile("CelestialConfig.json") then
            local data = readfile("CelestialConfig.json")
            local loaded = HttpService:JSONDecode(data)
            for k, v in pairs(loaded) do
                if CONFIG[k] ~= nil then CONFIG[k] = v end
            end
            Notify("Config Loaded! Please rejoin or reset.", 3)
        else
            Notify("Config file not found.", 2)
        end
    end)

    -- Открытие меню на H
    Pages["Main"].page.Visible = true
    Pages["Main"].btn.TextColor3 = CONFIG.Accent
    menu.Visible = true
    TweenService:Create(menu, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, -320, 0.5, -230) }):Play()
end

-- ============================================================
-- LOOPS & HOTKEYS
-- ============================================================
Track(UserInputService.InputBegan:Connect(function(input, gp)
    -- Обработка привязки клавиши
    if State.WaitingForBind then
        State.WaitingForBind(input.KeyCode)
        return
    end

    if gp or UserInputService:GetFocusedTextBox() then return end
    local k = input.KeyCode

    -- Открытие меню на H
    if k == BINDS.Menu and State.menuFrame then
        local m = State.menuFrame
        if m.Visible then
            TweenService:Create(m, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Position = UDim2.new(0.5, -320, 1, 500) }):Play()
            task.wait(0.3); m.Visible = false
        else
            m.Visible = true
            TweenService:Create(m, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, -320, 0.5, -230) }):Play()
        end
        return
    end

    -- Проверка остальных биндов
    if k == BINDS.Fly then CONFIG.FlyEnabled = not CONFIG.FlyEnabled; if not CONFIG.FlyEnabled then StopFly() end; Notify("Fly: "..tostring(CONFIG.FlyEnabled), 1) end
    if k == BINDS.Noclip then CONFIG.NoclipEnabled = not CONFIG.NoclipEnabled; Notify("Noclip: "..tostring(CONFIG.NoclipEnabled), 1) end
    if k == BINDS.Speed then CONFIG.SpeedEnabled = not CONFIG.SpeedEnabled; Notify("Speed: "..tostring(CONFIG.SpeedEnabled), 1) end
    if k == BINDS.ESP then CONFIG.ESPEnabled = not CONFIG.ESPEnabled; Notify("ESP: "..tostring(CONFIG.ESPEnabled), 1) end
    if k == BINDS.Aimbot then CONFIG.AimbotEnabled = not CONFIG.AimbotEnabled; Notify("Aimbot: "..tostring(CONFIG.AimbotEnabled), 1) end
    if k == BINDS.KillAura then CONFIG.KillAuraEnabled = not CONFIG.KillAuraEnabled; Notify("KillAura: "..tostring(CONFIG.KillAuraEnabled), 1) end
    if k == BINDS.Fling then CONFIG.FlingEnabled = not CONFIG.FlingEnabled; Notify("Fling: "..tostring(CONFIG.FlingEnabled), 1) end
end))

Track(RunService.Stepped:Connect(function(_, dt)
    if not State.Running then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    hum.WalkSpeed = CONFIG.SpeedEnabled and CONFIG.WalkSpeed or 16
    hum.JumpPower = CONFIG.JumpPower

    if CONFIG.NoclipEnabled then
        for _, v in ipairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
    end

    if CONFIG.InfiniteJump and UserInputService:IsKeyDown(Enum.KeyCode.Space) then hum:ChangeState(Enum.HumanoidStateType.Jumping) end

    if CONFIG.FlyEnabled then
        local cam = Workspace.CurrentCamera
        local bv = hrp:FindFirstChild("Celestial_FlyBV")
        local bg = hrp:FindFirstChild("Celestial_FlyBG")
        if not bv or not bg then
            StopFly()
            local n = Instance.new("BodyVelocity", hrp); n.Name = "Celestial_FlyBV"; n.MaxForce = Vector3.new(1e5,1e5,1e5); n.P = 2000
            local g = Instance.new("BodyGyro", hrp); g.Name = "Celestial_FlyBG"; g.MaxTorque = Vector3.new(1e5,1e5,1e5); g.P = 3000
            hum.PlatformStand = true
        else
            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0,1,0) end
            bv.Velocity = move.Magnitude > 0 and move.Unit * CONFIG.FlySpeed or Vector3.zero
            bg.CFrame = cam.CFrame
        end
    end
    
    if CONFIG.FlingEnabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local tHrp = p.Character:FindFirstChild("HumanoidRootPart")
                if tHrp and (tHrp.Position - hrp.Position).Magnitude < 25 then ForceFling(p.Character) end
            end
        end
    end
end))

Track(RunService.Heartbeat:Connect(function()
    if not State.Running then return end
    UpdateCosmetics()
    -- Упрощенный ESP рендер
    if not CONFIG.ESPEnabled then return end
    local cam = Workspace.CurrentCamera
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local char = p.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
            if hum and hum.Health > 0 and hrp then
                local sp, on = cam:WorldToViewportPoint(hrp.Position)
                if on and not State.ESPCache[p] then
                    State.ESPCache[p] = {
                        box = TrackD(Draw("Square")),
                        name = TrackD(Draw("Text"))
                    }
                end
                local t = State.ESPCache[p]
                if t and on then
                    t.box.Visible = CONFIG.ESPBox
                    t.box.Size = Vector2.new(50, 70)
                    t.box.Position = Vector2.new(sp.X - 25, sp.Y - 35)
                    t.box.Color = CONFIG.Accent
                    t.name.Visible = CONFIG.ESPName
                    t.name.Text = p.Name
                    t.name.Position = Vector2.new(sp.X, sp.Y - 50)
                    t.name.Color = CONFIG.Accent
                    t.name.Center = true
                    t.name.Outline = true
                elseif t then
                    t.box.Visible = false; t.name.Visible = false
                end
            end
        end
    end
end))

task.spawn(function()
    pcall(BuildCosmetics)
    pcall(BuildUI)
    print("[Celestial] v8.0 Loaded.")
end)
