-- ============================================================
-- CELESTIAL v8.5 — FULL UI + BINDS + CONFIGS + FIXES
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local VIM = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

local CELESTIAL_ASSET = "rbxassetid://94872985442978"
local VERSION = "8.5"

-- ============================================================
-- CONFIG & BINDS
-- ============================================================
local CONFIG = {
    Accent   = Color3.fromRGB(160, 110, 255),
    Accent2  = Color3.fromRGB(255, 100, 200),
    Bg       = Color3.fromRGB(8, 8, 12),
    CardBg   = Color3.fromRGB(18, 18, 24),
    Text     = Color3.fromRGB(240, 240, 250),
    TextDark = Color3.fromRGB(140, 140, 160),
    GUIFont  = Enum.Font.Gotham,

    AimbotEnabled = false, AimbotFOV = 200, AimbotSmooth = 0.35, AimbotPart = "Head",
    AimbotPredict = 0.15, AimbotAutoFire = false, AimbotVisible = false,
    KillAuraEnabled = false, KillAuraRange = 25, KillAuraDelay = 0.1,
    TriggerbotEnabled = false,

    ESPEnabled = true, ESPBox = true, ESPHealth = true,
    ESPName = true, ESPDistance = true, ESPSkeleton = true,
    ESPWeapon = true, ESPTracer = true, ESPHeadDot = true,
    ESPMaxDist = 1500, ESPFont = Drawing.Fonts.Plex,

    ChamsEnemy = false, ChamsSelf = false, ChamsRainbow = false,
    ChamsColor = Color3.fromRGB(160, 110, 255),

    WingsEnabled = false, CrownEnabled = false, HaloEnabled = false,
    AuraEnabled = false, OrbitEnabled = false, GroundCircle = false,

    Fullbright = false, NoFog = false,

    FlyEnabled = false, FlySpeed = 60, NoclipEnabled = false,
    SpeedEnabled = false, WalkSpeed = 50, JumpPower = 50,
    InfiniteJump = false, AutoWallhop = false,
    StandEnabled = false, ClickTPEnabled = false,

    FlingEnabled = false, FlingRange = 25,
    InvisibleEnabled = false,
}

-- По умолчанию все бинды пустые, кроме меню
local BINDS = {
    ToggleMenu = Enum.KeyCode.H,
    Fly = Enum.KeyCode.Unknown,
    Noclip = Enum.KeyCode.Unknown,
    Speed = Enum.KeyCode.Unknown,
    Aimbot = Enum.KeyCode.Unknown,
    KillAura = Enum.KeyCode.Unknown,
    Fling = Enum.KeyCode.Unknown,
    Stand = Enum.KeyCode.Unknown,
    Invisible = Enum.KeyCode.Unknown,
    ClickTP = Enum.KeyCode.Unknown,
    Triggerbot = Enum.KeyCode.Unknown,
    Unload = Enum.KeyCode.Unknown,
}

local State = {
    Running = true,
    Connections = {},
    Drawings = {},
    ESPCache = {},
    ChamsCache = {},
    ThemeObjects = {},
    SearchWidgets = {},
    Cosmetics = {},
    StandTarget = nil,
    menuFrame = nil,
    mainGui = nil,
    PlayingSong = false,
    WallhopCooldown = 0,
    KillAuraCooldown = 0,
    TriggerbotCooldown = 0,
    WaitingForBind = nil,
    OriginalLighting = {
        Brightness = Lighting.Brightness,
        FogEnd = Lighting.FogEnd,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
    },
}

local function Track(c) if State.Running and c then table.insert(State.Connections, c) end return c end
local function TrackD(d) if State.Running and d then table.insert(State.Drawings, d) end return d end
local function RegisterTheme(o) if State.Running then table.insert(State.ThemeObjects, o) end return o end
local function RegisterSearch(w) if State.Running then table.insert(State.SearchWidgets, w) end end

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
-- COSMETICS (Fixed Crown, Wings, Circle)
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
        mesh.MeshId = "rbxassetid://176213013"
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
    if not State.Cosmetics.Orbit then
        local m = Instance.new("Model", Workspace); m.Name = "Celestial_Orbit"
        for _ = 1, 3 do
            local r = Instance.new("Part", m)
            r.Name = "OrbitRing"; r.Shape = Enum.PartType.Cylinder
            r.Size = Vector3.new(0.1,8,8); r.Material = Enum.Material.Neon
            r.Color = CONFIG.Accent; r.Transparency = 0.4
            r.CanCollide = false; r.CanQuery = false; r.Anchored = true
        end
        State.Cosmetics.Orbit = m
    end
    if not State.Cosmetics.GroundCircle then
        local gc = Instance.new("Part", Workspace); gc.Name = "Celestial_GroundCircle"
        gc.Shape = Enum.PartType.Cylinder; gc.Size = Vector3.new(0.1,10,10)
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
                        -- Фикс позиции крыльев
                        p.CFrame = hrp.CFrame * CFrame.new(side*(0.5+s*2), 1+s*1.5, -1) * CFrame.Angles(0, math.rad(side*45), 0)
                        p.Color = Color3.fromHSV((t*0.3 + i*0.1) % 1, 0.8, 1)
                        p.Transparency = 0
                    end
                end
            end
        end
    end
    if State.Cosmetics.Orbit and hrp then
        State.Cosmetics.Orbit.Parent = CONFIG.OrbitEnabled and Workspace or nil
        if CONFIG.OrbitEnabled then
            for i, r in ipairs(State.Cosmetics.Orbit:GetChildren()) do
                local a = t*(1+i*0.3) + i*(math.pi*2/3)
                local rad = 4 + math.sin(t*2+i)*1
                -- Фикс орбиты (крутится вокруг)
                r.CFrame = CFrame.new(hrp.Position + Vector3.new(math.cos(a)*rad, math.sin(t*1.5+i)*1.5, math.sin(a)*rad)) * CFrame.Angles(0, 0, math.rad(90))
                r.Color = Color3.fromHSV((t*0.2 + i*0.3) % 1, 0.8, 1)
                r.Transparency = 0.3 + math.sin(t*3+i)*0.2
            end
        end
    end
    if State.Cosmetics.GroundCircle and hrp then
        State.Cosmetics.GroundCircle.Parent = CONFIG.GroundCircle and Workspace or nil
        if CONFIG.GroundCircle then
            -- Фикс круга на земле
            State.Cosmetics.GroundCircle.CFrame = CFrame.new(hrp.Position - Vector3.new(0, 3, 0)) * CFrame.Angles(0, 0, math.rad(90))
            State.Cosmetics.GroundCircle.Color = CONFIG.Accent
            State.Cosmetics.GroundCircle.Transparency = 0.5 + math.sin(t*3)*0.1
        end
    end
end

-- ============================================================
-- CHAMS & MOVEMENT FIXES
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
    hl.FillColor = CONFIG.ChamsRainbow and Color3.fromHSV(tick() % 1, 1, 1) or CONFIG.ChamsColor
    hl.OutlineColor = hl.FillColor
    State.ChamsCache[char] = hl
end

local function RemoveChams(char)
    if char then
        local hl = char:FindFirstChild("Celestial_Chams")
        if hl then hl:Destroy() end
        State.ChamsCache[char] = nil
    end
end

local function StopFly()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        for _, c in ipairs(hrp:GetChildren()) do
            if c.Name == "Celestial_FlyBV" or c.Name == "Celestial_FlyBG" then c:Destroy() end
        end
    end
end

local function ForceFling(char)
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    pcall(function()
        -- Безопасный флинг без Physics состояния
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
    
    Create("TextLabel", { Parent = header, Size = UDim2.new(0,200,0,22), Position = UDim2.new(0,66,0,12), BackgroundTransparency = 1, Text = "Celestial", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 })
    Create("TextLabel", { Parent = header, Size = UDim2.new(0,260,0,16), Position = UDim2.new(0,66,0,34), BackgroundTransparency = 1, Text = "v" .. VERSION .. " | Premium", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = CONFIG.Accent, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 })

    local closeBtn = Create("TextButton", { Parent = header, Size = UDim2.new(0,32,0,32), Position = UDim2.new(1,-46,0.5,-16), BackgroundColor3 = Color3.fromRGB(35,35,45), Text = "×", Font = Enum.Font.GothamBold, TextSize = 22, TextColor3 = CONFIG.TextDark, BorderSizePixel = 0, AutoButtonColor = false, ZIndex = 4 }, { Corner(10) })
    closeBtn.MouseButton1Click:Connect(function()
        TweenService:Create(menu, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Position = UDim2.new(0.5, -320, 1, 500) }):Play()
        task.wait(0.3); menu.Visible = false
    end)

    local searchFrame = Create("Frame", { Parent = menu, Size = UDim2.new(1,-40,0,32), Position = UDim2.new(0,20,0,72), BackgroundColor3 = CONFIG.CardBg, BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 3 }, { Corner(8) })
    local searchBox = Create("TextBox", { Parent = searchFrame, Size = UDim2.new(1,-40,1,0), Position = UDim2.new(0,32,0,0), BackgroundTransparency = 1, Text = "", PlaceholderText = "Search functions...", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = CONFIG.Text, PlaceholderColor3 = CONFIG.TextDark, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 })
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local q = searchBox.Text:lower()
        for _, w in ipairs(State.SearchWidgets) do
            if w.row and w.row.Parent then w.row.Visible = (q == "" or w.text:find(q, 1, true) ~= nil) end
        end
    end)

    local sidebar = Create("Frame", { Parent = menu, Size = UDim2.new(0,160,1,-130), Position = UDim2.new(0,20,0,116), BackgroundTransparency = 1, ZIndex = 3 })
    Create("UIListLayout", { Parent = sidebar, Padding = UDim.new(0,6) })
    local content = Create("Frame", { Parent = menu, Size = UDim2.new(1,-200,1,-130), Position = UDim2.new(0,180,0,116), BackgroundTransparency = 1, ZIndex = 3 })

    local Pages = {}
    local Tabs = {}

    local function CreateTab(name, icon, order)
        local btn = Create("TextButton", { Parent = sidebar, Size = UDim2.new(1,0,0,36), BackgroundColor3 = Color3.fromRGB(24,24,32), BackgroundTransparency = 0.4, Text = "  " .. icon .. "   " .. name, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = CONFIG.TextDark, TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, LayoutOrder = order, AutoButtonColor = false, ZIndex = 4 }, { Corner(8) })
        local stroke = Create("UIStroke", { Parent = btn, Color = CONFIG.Accent, Thickness = 1, Transparency = 1 })
        local page = Create("ScrollingFrame", { Parent = content, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Visible = false, ScrollBarThickness = 2, ScrollBarImageColor3 = CONFIG.Accent, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0,0,0,0), BorderSizePixel = 0, ZIndex = 3 })
        Create("UIListLayout", { Parent = page, Padding = UDim.new(0,10) })

        Pages[name] = page
        Tabs[name] = { btn = btn, stroke = stroke }

        btn.MouseButton1Click:Connect(function()
            for n, p in pairs(Pages) do p.Visible = (n == name) end
            for n, t2 in pairs(Tabs) do
                TweenService:Create(t2.btn, TweenInfo.new(0.2), { TextColor3 = (n == name) and CONFIG.Accent or CONFIG.TextDark, BackgroundTransparency = (n == name) and 0.15 or 0.4 }):Play()
                TweenService:Create(t2.stroke, TweenInfo.new(0.2), { Transparency = (n == name) and 0.4 or 1 }):Play()
            end
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

    -- Модифицированные функции с биндами (Клик колесиком)
    local function CreateToggle(parent, text, bindKey, default, cb, order)
        local row = Create("Frame", { Parent = parent, Size = UDim2.new(1,0,0,28), BackgroundTransparency = 1, LayoutOrder = order or 1 })
        
        local bindBtn = Create("TextButton", { Parent = row, Size = UDim2.new(0,50,0,20), Position = UDim2.new(1,-70,0.5,-10), BackgroundColor3 = Color3.fromRGB(35,35,45), Text = BINDS[bindKey] and BINDS[bindKey].Name or "None", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = CONFIG.TextDark, BorderSizePixel = 0, ZIndex = 6 }, { Corner(4) })
        bindBtn.MouseButton1Click:Connect(function() end) -- Поглотитель
        bindBtn.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton3 then
                if State.WaitingForBind then return end
                bindBtn.Text = "..."
                State.WaitingForBind = function(kc)
                    BINDS[bindKey] = kc
                    bindBtn.Text = kc.Name
                    State.WaitingForBind = nil
                    Notify("Binded "..text.." to "..kc.Name, 1.5)
                end
            end
        end)

        local label = Create("TextLabel", { Parent = row, Size = UDim2.new(1,-120,1,0), BackgroundTransparency = 1, Text = text, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 })
        local sw = Create("Frame", { Parent = row, Size = UDim2.new(0,28,0,14), Position = UDim2.new(1,-28,0.5,-7), BackgroundColor3 = default and CONFIG.Accent or Color3.fromRGB(40,40,50), BorderSizePixel = 0, ZIndex = 5 }, { Corner(7) })
        local kn = Create("Frame", { Parent = sw, Size = UDim2.new(0,10,0,10), Position = default and UDim2.new(1,-12,0.5,-5) or UDim2.new(0,2,0.5,-5), BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, ZIndex = 6 }, { Corner(5) })

        local state = default
        local click = Create("TextButton", { Parent = row, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "", ZIndex = 7 })
        click.MouseButton1Click:Connect(function()
            state = not state
            TweenService:Create(sw, TweenInfo.new(0.2), { BackgroundColor3 = state and CONFIG.Accent or Color3.fromRGB(40,40,50) }):Play()
            TweenService:Create(kn, TweenInfo.new(0.2), { Position = state and UDim2.new(1,-12,0.5,-5) or UDim2.new(0,2,0.5,-5) }):Play()
            cb(state)
        end)
        RegisterSearch({ row = row, text = text:lower() })
    end

    local function CreateSlider(parent, text, min, max, default, suffix, cb, order)
        local row = Create("Frame", { Parent = parent, Size = UDim2.new(1,0,0,44), BackgroundTransparency = 1, LayoutOrder = order or 1 })
        Create("TextLabel", { Parent = row, Size = UDim2.new(1,-60,0,18), BackgroundTransparency = 1, Text = text, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 })
        local val = Create("TextLabel", { Parent = row, Size = UDim2.new(0,60,0,18), Position = UDim2.new(1,-60,0,0), BackgroundTransparency = 1, Text = tostring(default) .. (suffix or ""), Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = CONFIG.Accent, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 5 })

        local track = Create("Frame", { Parent = row, Size = UDim2.new(1,0,0,3), Position = UDim2.new(0,0,1,-10), BackgroundColor3 = Color3.fromRGB(30,30,40), BorderSizePixel = 0, ZIndex = 5 }, { Corner(2) })
        local fill = Create("Frame", { Parent = track, Size = UDim2.new((default-min)/(max-min),0,1,0), BackgroundColor3 = CONFIG.Accent, BorderSizePixel = 0, ZIndex = 6 }, { Corner(2) })
        local knob = Create("Frame", { Parent = track, Size = UDim2.new(0,10,0,10), Position = UDim2.new((default-min)/(max-min),-5,0.5,-5), BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, ZIndex = 7 }, { Corner(5) })

        local hit = Create("TextButton", { Parent = row, Size = UDim2.new(1,0,0,18), Position = UDim2.new(0,0,1,-16), BackgroundTransparency = 1, Text = "", ZIndex = 8 })
        local drag = false
        local function update(x)
            local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local v = math.floor(min + (max - min) * rel)
            fill.Size = UDim2.new(rel,0,1,0); knob.Position = UDim2.new(rel,-5,0.5,-5)
            val.Text = tostring(v) .. (suffix or ""); cb(v)
        end
        hit.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true; update(i.Position.X) end end)
        Track(UserInputService.InputChanged:Connect(function(i) if drag and i.UserInputType == Enum.UserInputType.MouseMovement then update(i.Position.X) end end))
        Track(UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end))
        RegisterSearch({ row = row, text = text:lower() })
    end

    -- Вкладки
    local HomeTab = CreateTab("Home", "🏠", 1)
    local CombatTab = CreateTab("Combat", "⚔️", 2)
    local VisualsTab = CreateTab("Visuals", "👁️", 3)
    local CosmeticsTab = CreateTab("Cosmetics", "✨", 4)
    local MovementTab = CreateTab("Movement", "🏃", 5)
    local TrollTab = CreateTab("Troll", "😈", 6)
    local SettingsTab = CreateTab("Configs", "⚙️", 7)

    -- Combat
    local aimCard = CreateCard(CombatTab, "Aimbot")
    CreateToggle(aimCard, "Enable Aimbot", "Aimbot", CONFIG.AimbotEnabled, function(v) CONFIG.AimbotEnabled = v end, 1)
    CreateSlider(aimCard, "FOV Radius", 20, 600, CONFIG.AimbotFOV, "px", function(v) CONFIG.AimbotFOV = v; FOVCircle.Radius = v end, 2)
    CreateSlider(aimCard, "Smoothness", 5, 100, math.floor(CONFIG.AimbotSmooth * 100), "%", function(v) CONFIG.AimbotSmooth = v/100 end, 3)
    
    local kaCard = CreateCard(CombatTab, "Kill Aura")
    CreateToggle(kaCard, "Enable Kill Aura", "KillAura", CONFIG.KillAuraEnabled, function(v) CONFIG.KillAuraEnabled = v end, 1)
    CreateSlider(kaCard, "Range", 5, 100, CONFIG.KillAuraRange, "s", function(v) CONFIG.KillAuraRange = v end, 2)

    -- Visuals
    local espCard = CreateCard(VisualsTab, "ESP")
    CreateToggle(espCard, "Enable ESP", "ESP", CONFIG.ESPEnabled, function(v) CONFIG.ESPEnabled = v end, 1)
    CreateToggle(espCard, "Box", "ESPBox", CONFIG.ESPBox, function(v) CONFIG.ESPBox = v end, 2)
    CreateToggle(espCard, "Name", "ESPName", CONFIG.ESPName, function(v) CONFIG.ESPName = v end, 3)
    CreateToggle(espCard, "Health", "ESPHealth", CONFIG.ESPHealth, function(v) CONFIG.ESPHealth = v end, 4)

    -- Cosmetics
    local cosCard = CreateCard(CosmeticsTab, "Cosmetics")
    CreateToggle(cosCard, "Halo", "Halo", CONFIG.HaloEnabled, function(v) CONFIG.HaloEnabled = v end, 1)
    CreateToggle(cosCard, "Wings", "Wings", CONFIG.WingsEnabled, function(v) CONFIG.WingsEnabled = v end, 2)
    CreateToggle(cosCard, "Crown", "Crown", CONFIG.CrownEnabled, function(v) CONFIG.CrownEnabled = v end, 3)
    CreateToggle(cosCard, "Ground Circle", "Circle", CONFIG.GroundCircle, function(v) CONFIG.GroundCircle = v end, 4)
    CreateToggle(cosCard, "Orbit", "Orbit", CONFIG.OrbitEnabled, function(v) CONFIG.OrbitEnabled = v end, 5)

    -- Movement
    local flyCard = CreateCard(MovementTab, "Flight")
    CreateToggle(flyCard, "Fly", "Fly", CONFIG.FlyEnabled, function(v) CONFIG.FlyEnabled = v; if not v then StopFly() end end, 1)
    CreateSlider(flyCard, "Fly Speed", 20, 300, CONFIG.FlySpeed, "", function(v) CONFIG.FlySpeed = v end, 2)
    CreateToggle(flyCard, "Noclip", "Noclip", CONFIG.NoclipEnabled, function(v) CONFIG.NoclipEnabled = v end, 3)
    CreateToggle(flyCard, "Speed", "Speed", CONFIG.SpeedEnabled, function(v) CONFIG.SpeedEnabled = v end, 4)

    -- Troll
    local trollCard = CreateCard(TrollTab, "Troll")
    CreateToggle(trollCard, "Auto Fling", "Fling", CONFIG.FlingEnabled, function(v) CONFIG.FlingEnabled = v end, 1)
    CreateToggle(trollCard, "Invisible", "Invisible", CONFIG.InvisibleEnabled, function(v) CONFIG.InvisibleEnabled = v; if v then ApplyGhost() else RestoreVis() end end, 2)

    -- Configs
    local confCard = CreateCard(SettingsTab, "Config System")
    local nameBox = Create("TextBox", { Parent = confCard, Size = UDim2.new(1,0,0,30), BackgroundColor3 = Color3.fromRGB(30,30,40), Text = "my_config", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = CONFIG.Text, BorderSizePixel = 0, PlaceholderText = "Config Name..." }, { Corner(6) })
    
    local saveBtn = Create("TextButton", { Parent = confCard, Size = UDim2.new(1,0,0,30), BackgroundColor3 = Color3.fromRGB(30,30,40), Text = "Save Config", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = CONFIG.Text, BorderSizePixel = 0 }, { Corner(6) })
    saveBtn.MouseButton1Click:Connect(function()
        if writefile then
            local data = HttpService:JSONEncode({CONFIG = CONFIG, BINDS = BINDS})
            writefile(nameBox.Text .. ".json", data)
            Notify("Config Saved: " .. nameBox.Text, 2)
        else
            Notify("writefile not supported", 2)
        end
    end)
    
    local loadBtn = Create("TextButton", { Parent = confCard, Size = UDim2.new(1,0,0,30), BackgroundColor3 = Color3.fromRGB(30,30,40), Text = "Load Config", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = CONFIG.Text, BorderSizePixel = 0 }, { Corner(6) })
    loadBtn.MouseButton1Click:Connect(function()
        if readfile and isfile and isfile(nameBox.Text .. ".json") then
            local data = HttpService:JSONDecode(readfile(nameBox.Text .. ".json"))
            if data.CONFIG then for k, v in pairs(data.CONFIG) do if CONFIG[k] ~= nil then CONFIG[k] = v end end end
            if data.BINDS then for k, v in pairs(data.BINDS) do if BINDS[k] ~= nil then BINDS[k] = v end end end
            Notify("Config Loaded! Rejoin to apply fully.", 3)
        else
            Notify("Config not found", 2)
        end
    end)

    -- Открытие меню
    Pages["Home"].Visible = true
    Tabs["Home"].btn.TextColor3 = CONFIG.Accent
    Tabs["Home"].btn.BackgroundTransparency = 0.15
    Tabs["Home"].stroke.Transparency = 0.4

    menu.Visible = true
    TweenService:Create(menu, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, -320, 0.5, -230) }):Play()

    -- Перетаскивание
    local drag, dragStart, startPos
    header.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true; dragStart = i.Position; startPos = menu.Position end end)
    Track(UserInputService.InputChanged:Connect(function(i) if drag and i.UserInputType == Enum.UserInputType.MouseMovement then local d = i.Position - dragStart; menu.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y) end end))
    Track(UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end))
end

-- ============================================================
-- LOOPS & HOTKEYS
-- ============================================================
Track(UserInputService.InputBegan:Connect(function(input, gp)
    -- Логика привязки колесиком
    if State.WaitingForBind then
        State.WaitingForBind(input.KeyCode)
        return
    end

    if gp or UserInputService:GetFocusedTextBox() then return end
    local k = input.KeyCode
    
    -- Только если нажата реальная клавиша, а не Unknown
    if k == Enum.KeyCode.Unknown then return end

    if k == BINDS.ToggleMenu and State.menuFrame then
        local m = State.menuFrame
        if m.Visible then
            TweenService:Create(m, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Position = UDim2.new(0.5, -320, 1, 500) }):Play()
            task.wait(0.3); m.Visible = false
        else
            m.Visible = true
            TweenService:Create(m, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, -320, 0.5, -230) }):Play()
        end
    elseif k == BINDS.Fly then CONFIG.FlyEnabled = not CONFIG.FlyEnabled; if not CONFIG.FlyEnabled then StopFly() end; Notify("Fly: " .. (CONFIG.FlyEnabled and "ON" or "OFF"), 1.5)
    elseif k == BINDS.Noclip then CONFIG.NoclipEnabled = not CONFIG.NoclipEnabled; Notify("Noclip: " .. (CONFIG.NoclipEnabled and "ON" or "OFF"), 1.5)
    elseif k == BINDS.Speed then CONFIG.SpeedEnabled = not CONFIG.SpeedEnabled; Notify("Speed: " .. (CONFIG.SpeedEnabled and "ON" or "OFF"), 1.5)
    elseif k == BINDS.Aimbot then CONFIG.AimbotEnabled = not CONFIG.AimbotEnabled; Notify("Aimbot: " .. (CONFIG.AimbotEnabled and "ON" or "OFF"), 1.5)
    elseif k == BINDS.KillAura then CONFIG.KillAuraEnabled = not CONFIG.KillAuraEnabled; Notify("KillAura: " .. (CONFIG.KillAuraEnabled and "ON" or "OFF"), 1.5)
    elseif k == BINDS.Fling then CONFIG.FlingEnabled = not CONFIG.FlingEnabled; Notify("Fling: " .. (CONFIG.FlingEnabled and "ON" or "OFF"), 1.5)
    elseif k == BINDS.Invisible then CONFIG.InvisibleEnabled = not CONFIG.InvisibleEnabled; if CONFIG.InvisibleEnabled then ApplyGhost() else RestoreVis() end; Notify("Invisible: " .. (CONFIG.InvisibleEnabled and "ON" or "OFF"), 1.5)
    end
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
                if tHrp and (tHrp.Position - hrp.Position).Magnitude < CONFIG.FlingRange then ForceFling(p.Character) end
            end
        end
    end
end))

Track(RunService.Heartbeat:Connect(function()
    if not State.Running then return end
    UpdateCosmetics()
    
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
                    State.ESPCache[p] = { box = TrackD(Draw("Square")), name = TrackD(Draw("Text")) }
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
    print("[Celestial] v8.5 Loaded.")
end)
