-- ============================================================
-- CELESTIAL v7.5 — FIXED BY WORM SHADOW
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local VIM = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- Безопасное получение PlayerModule
local PlayerModule = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
local Controls = PlayerModule:GetControls()

local CELESTIAL_ASSET = "rbxassetid://94872985442978"
local VERSION = "7.5"

-- ============================================================
-- CONFIG
-- ============================================================
local CONFIG = {
    Accent   = Color3.fromRGB(160, 110, 255),
    Accent2  = Color3.fromRGB(255, 100, 200),
    Bg       = Color3.fromRGB(8, 8, 12),
    CardBg   = Color3.fromRGB(18, 18, 24),
    Text     = Color3.fromRGB(240, 240, 250),
    TextDark = Color3.fromRGB(140, 140, 160),
    GUIFont  = Enum.Font.Gotham,

    AimbotEnabled = false, AimbotKey = Enum.KeyCode.E,
    AimbotFOV = 200, AimbotSmooth = 0.35, AimbotPart = "Head",
    AimbotPredict = 0.15, AimbotSilent = false,
    AimbotAutoFire = false, AimbotVisible = false,
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

local Keybinds = {
    ToggleMenu = Enum.KeyCode.RightShift,
    Fly = Enum.KeyCode.F, Noclip = Enum.KeyCode.G,
    Fling = Enum.KeyCode.V, Stand = Enum.KeyCode.Z,
    Invisible = Enum.KeyCode.I, ClickTP = Enum.KeyCode.B,
    KillAura = Enum.KeyCode.K, Triggerbot = Enum.KeyCode.T,
    Unload = Enum.KeyCode.Delete, Panic = Enum.KeyCode.P,
}

-- ============================================================
-- STATE
-- ============================================================
local State = {
    Running = true,
    Connections = {},
    Drawings = {},
    ESPCache = {},
    ChamsCache = {},
    ThemeObjects = {},
    FontObjects = {},
    SearchWidgets = {},
    Cosmetics = {},
    StandTarget = nil,
    menuFrame = nil,
    mainGui = nil,
    PlayingSong = false,
    WallhopCooldown = 0,
    KillAuraCooldown = 0,
    TriggerbotCooldown = 0,
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
local function RegisterFont(o) if State.Running then table.insert(State.FontObjects, o) end return o end
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
local notifGui = Instance.new("ScreenGui")
notifGui.Name = "CelestialNotifs"
notifGui.ResetOnSpawn = false
notifGui.IgnoreGuiInset = true
notifGui.DisplayOrder = 1002
notifGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local notifFrame = Create("Frame", {
    Parent = notifGui, Size = UDim2.new(0, 320, 1, 0),
    Position = UDim2.new(1, -340, 0, 100),
    BackgroundTransparency = 1, ZIndex = 5,
})
Create("UIListLayout", { Parent = notifFrame, Padding = UDim.new(0, 6) })

local function Notify(text, duration)
    duration = duration or 2.5
    local card = Create("Frame", {
        Parent = notifFrame, Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = CONFIG.CardBg, BackgroundTransparency = 0.1,
        BorderSizePixel = 0, ZIndex = 6,
    }, { Corner(8) })
    local s = Create("UIStroke", { Parent = card, Color = CONFIG.Accent, Thickness = 1, Transparency = 0.3 })
    ApplyGradient(s)
    Create("Frame", { Parent = card, Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = CONFIG.Accent, BorderSizePixel = 0, ZIndex = 7 }, { Corner(2) })
    Create("TextLabel", {
        Parent = card, Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1,
        Text = text, Font = Enum.Font.Gotham, TextSize = 12,
        TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
    })
    card.Position = UDim2.new(1, 20, 0, 0)
    TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()
    task.delay(duration, function()
        TweenService:Create(card, TweenInfo.new(0.25), { Position = UDim2.new(1, 20, 0, 0) }):Play()
        task.delay(0.25, function() card:Destroy() end)
    end)
end

-- ============================================================
-- COSMETICS
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
            p.Transparency = 1; p.Size = Vector3.new(0.1,0.1,0.1)
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
        gc.Anchored = true; gc.Orientation = Vector3.new(0,0,90)
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
                        p.Size = Vector3.new(0.25,0.25,0.25)
                        p.Color = Color3.fromHSV((t*0.3 + i*0.1) % 1, 0.8, 1)
                        local l = p:FindFirstChildOfClass("PointLight")
                        if not l then l = Instance.new("PointLight", p); l.Range = 4; l.Brightness = 2 end
                        l.Color = p.Color
                    end
                end
            end
        end
    end

    if hrp then
        if CONFIG.AuraEnabled then
            local att = hrp:FindFirstChild("Celestial_AuraAtt")
            if not att then
                att = Instance.new("Attachment", hrp)
                att.Name = "Celestial_AuraAtt"
                local pe = Instance.new("ParticleEmitter", att)
                pe.Name = "AuraPE"; pe.Rate = 30
                pe.Lifetime = NumberRange.new(0.8,1.6)
                pe.Speed = NumberRange.new(2,4)
                pe.SpreadAngle = Vector2.new(180,180)
                pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.6), NumberSequenceKeypoint.new(1,0)})
                pe.LightEmission = 1; pe.LightInfluence = 0
                pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
            end
            for _, pe in ipairs(att:GetChildren()) do
                if pe:IsA("ParticleEmitter") then pe.Color = ColorSequence.new(CONFIG.Accent) end
            end
        else
            local old = hrp:FindFirstChild("Celestial_AuraAtt")
            if old then old:Destroy() end
        end
    end

    if State.Cosmetics.Orbit and hrp then
        State.Cosmetics.Orbit.Parent = CONFIG.OrbitEnabled and Workspace or nil
        if CONFIG.OrbitEnabled then
            for i, r in ipairs(State.Cosmetics.Orbit:GetChildren()) do
                local a = t*(1+i*0.3) + i*(math.pi*2/3)
                local rad = 4 + math.sin(t*2+i)*1
                r.CFrame = hrp.CFrame * CFrame.new(math.cos(a)*rad, math.sin(t*1.5+i)*1.5, math.sin(a)*rad) * CFrame.Angles(0,0,math.rad(90))
                r.Color = Color3.fromHSV((t*0.2 + i*0.3) % 1, 0.8, 1)
                r.Transparency = 0.3 + math.sin(t*3+i)*0.2
            end
        end
    end
    if State.Cosmetics.GroundCircle and hrp then
        State.Cosmetics.GroundCircle.Parent = CONFIG.GroundCircle and Workspace or nil
        if CONFIG.GroundCircle then
            State.Cosmetics.GroundCircle.CFrame = CFrame.new(hrp.Position - Vector3.new(0, hrp.Size.Y/2 + 0.1, 0)) * CFrame.Angles(0,0,math.rad(90))
            State.Cosmetics.GroundCircle.Color = CONFIG.Accent
            State.Cosmetics.GroundCircle.Transparency = 0.5 + math.sin(t*3)*0.1
        end
    end
end

-- ============================================================
-- CHAMS
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

-- ============================================================
-- MOVEMENT / TROLL HELPERS
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
    Controls:Enable() -- Fix: safe enable
end

-- Fling — Fixed physics breakage
local function ForceFling(char)
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    
    pcall(function()
        hum:ChangeState(Enum.HumanoidStateType.Physics)
        local bv = Instance.new("BodyVelocity", hrp)
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = Vector3.new(1e5, 1e5, 1e5)
        Debris:AddItem(bv, 0.4)
        local bav = Instance.new("BodyAngularVelocity", hrp)
        bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bav.AngularVelocity = Vector3.new(1e5, 1e5, 1e5)
        Debris:AddItem(bav, 0.4)
    end)
end

-- Invisible — Fixed ghost visual
local function ApplyGhost()
    local char = LocalPlayer.Character
    if not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Transparency = 1
            v.LocalTransparencyModifier = 1
            v.CanCollide = false
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        end
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        hum.NameDisplayDistance = 0
        hum.HealthDisplayDistance = 0
    end
end

local function RestoreVis()
    local char = LocalPlayer.Character
    if not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Transparency = 0
            v.LocalTransparencyModifier = 0
            v.CanCollide = true
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 0
        end
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer -- Fix: typo fixed
        hum.NameDisplayDistance = 100
        hum.HealthDisplayDistance = 100
    end
end

-- ============================================================
-- SONGS
-- ============================================================
local SONGS = {
    ["Megalovania"] = {{"E",0.1},{"D",0.1},{"C",0.1},{"D",0.1},{"E",0.1},{"E",0.1},{"E",0.1},{"D",0.1},{"D",0.1},{"D",0.1},{"E",0.1},{"G",0.1},{"G",0.1},{"E",0.2},{"D",0.1},{"C",0.1},{"D",0.1},{"E",0.1},{"E",0.1},{"E",0.1},{"F",0.1},{"E",0.1},{"D",0.1},{"D",0.1},{"E",0.1},{"D",0.1},{"C",0.2}},
    ["Coffin Dance"] = {{"A",0.25},{"A",0.25},{"C",0.25},{"A",0.25},{"D",0.25},{"A",0.25},{"C",0.25},{"A",0.5},{"F",0.25},{"F",0.25},{"G",0.25},{"F",0.25},{"D",0.25},{"C",0.25},{"A",0.25}},
    ["Rush E"] = {{"E",0.05},{"E",0.05},{"E",0.05},{"E",0.05},{"E",0.05},{"E",0.05},{"E",0.05},{"E",0.05},{"D",0.08},{"E",0.08},{"B",0.08},{"D",0.08},{"C",0.08},{"A",0.15},{"E",0.05},{"E",0.05},{"E",0.05},{"E",0.05},{"G",0.1},{"A",0.1}},
    ["Yara Yara"] = {{"E",0.22},{"G",0.22},{"A",0.22},{"C",0.35},{"A",0.22},{"G",0.22},{"E",0.22},{"D",0.35},{"E",0.22},{"G",0.22},{"A",0.22},{"C",0.35},{"D",0.22},{"C",0.22},{"A",0.5}},
    ["Phonk Sigma"] = {{"A",0.3},{"C",0.3},{"E",0.3},{"A",0.3},{"G",0.3},{"E",0.3},{"C",0.3},{"A",0.5}},
    ["Nokia"] = {{"E",0.15},{"D",0.15},{"F",0.15},{"G",0.3},{"E",0.15},{"D",0.15},{"F",0.15},{"G",0.3},{"C",0.15},{"C",0.15},{"B",0.15},{"A",0.15},{"G",0.15},{"A",0.15},{"F",0.15},{"G",0.3}},
    ["Among Us"] = {{"C",0.2},{"D",0.15},{"E",0.15},{"F",0.3},{"E",0.15},{"D",0.15},{"C",0.4}},
    ["Tetris"] = {{"E",0.3},{"B",0.15},{"C",0.15},{"D",0.3},{"C",0.15},{"B",0.15},{"A",0.3},{"A",0.15},{"C",0.15},{"E",0.3},{"D",0.15},{"C",0.15},{"B",0.6}},
}

local function PlayNote(key)
    local kc = Enum.KeyCode[key]
    if not kc then return end
    pcall(function()
        if typeof(keypress) == "function" then
            keypress(kc)
            task.wait(0.02)
            keyrelease(kc)
            return
        end
        VIM:SendKeyEvent(true, kc, false, game)
        task.wait(0.02)
        VIM:SendKeyEvent(false, kc, false, game)
    end)
end

local function PlaySong(name)
    if State.PlayingSong then Notify("Already playing", 1.5); return end
    local song = SONGS[name]
    if not song then return end
    State.PlayingSong = true
    Notify("Playing: " .. name, 2)
    task.spawn(function()
        for _, n in ipairs(song) do
            if not State.PlayingSong or not State.Running then break end
            PlayNote(n[1])
            task.wait(n[2])
        end
        State.PlayingSong = false
        Notify("Finished: " .. name, 2)
    end)
end

-- ============================================================
-- UI
-- ============================================================
local function BuildUI()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")

    local gui = Instance.new("ScreenGui")
    gui.Name = "CelestialUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999
    gui.Parent = playerGui
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

    local logo = Create("ImageLabel", {
        Parent = header, Size = UDim2.new(0,36,0,36),
        Position = UDim2.new(0,20,0.5,-18),
        BackgroundColor3 = CONFIG.CardBg, Image = CELESTIAL_ASSET,
        ScaleType = Enum.ScaleType.Crop, ZIndex = 4,
    }, { Corner(18) })
    local ls = Create("UIStroke", { Parent = logo, Thickness = 1.5, Color = CONFIG.Accent })
    ApplyGradient(ls)

    RegisterFont(Create("TextLabel", {
        Parent = header, Size = UDim2.new(0,200,0,22),
        Position = UDim2.new(0,66,0,12),
        BackgroundTransparency = 1, Text = "Celestial",
        Font = Enum.Font.GothamBold, TextSize = 18,
        TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4,
    }))
    RegisterFont(RegisterTheme(Create("TextLabel", {
        Parent = header, Size = UDim2.new(0,260,0,16),
        Position = UDim2.new(0,66,0,34),
        BackgroundTransparency = 1, Text = "v" .. VERSION .. " | Premium",
        Font = Enum.Font.Gotham, TextSize = 11,
        TextColor3 = CONFIG.Accent, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4,
    })))

    local closeBtn = Create("TextButton", {
        Parent = header, Size = UDim2.new(0,32,0,32),
        Position = UDim2.new(1,-46,0.5,-16),
        BackgroundColor3 = Color3.fromRGB(35,35,45),
        Text = "×", Font = Enum.Font.GothamBold, TextSize = 22,
        TextColor3 = CONFIG.TextDark, BorderSizePixel = 0,
        AutoButtonColor = false, ZIndex = 4,
    }, { Corner(10) })
    closeBtn.MouseButton1Click:Connect(function()
        TweenService:Create(menu, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, -320, 1, 500)
        }):Play()
        task.wait(0.3)
        menu.Visible = false
    end)

    Create("Frame", { Parent = menu, Size = UDim2.new(1,-40,0,1),
        Position = UDim2.new(0,20,0,62), BackgroundColor3 = Color3.fromRGB(35,35,45),
        BorderSizePixel = 0, ZIndex = 3 })

    local searchFrame = Create("Frame", {
        Parent = menu, Size = UDim2.new(1,-40,0,32),
        Position = UDim2.new(0,20,0,72),
        BackgroundColor3 = CONFIG.CardBg, BackgroundTransparency = 0.3,
        BorderSizePixel = 0, ZIndex = 3,
    }, { Corner(8) })
    Create("UIStroke", { Parent = searchFrame, Thickness = 1, Color = CONFIG.Accent, Transparency = 0.7 })
    Create("TextLabel", { Parent = searchFrame, Size = UDim2.new(0,28,1,0),
        Position = UDim2.new(0,6,0,0), BackgroundTransparency = 1,
        Text = "🔍", Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = CONFIG.TextDark, ZIndex = 4 })
    local searchBox = Create("TextBox", {
        Parent = searchFrame, Size = UDim2.new(1,-40,1,0),
        Position = UDim2.new(0,32,0,0), BackgroundTransparency = 1,
        Text = "", PlaceholderText = "Search functions...",
        Font = Enum.Font.Gotham, TextSize = 12,
        TextColor3 = CONFIG.Text, PlaceholderColor3 = CONFIG.TextDark,
        ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4,
    })
    RegisterFont(searchBox)
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local q = searchBox.Text:lower()
        for _, w in ipairs(State.SearchWidgets) do
            if w.row and w.row.Parent then
                w.row.Visible = (q == "" or w.text:find(q, 1, true) ~= nil)
            end
        end
    end)

    local sidebar = Create("Frame", {
        Parent = menu, Size = UDim2.new(0,160,1,-130),
        Position = UDim2.new(0,20,0,116), BackgroundTransparency = 1, ZIndex = 3,
    })
    Create("UIListLayout", { Parent = sidebar, Padding = UDim.new(0,6) })

    local content = Create("Frame", {
        Parent = menu, Size = UDim2.new(1,-200,1,-130),
        Position = UDim2.new(0,180,0,116), BackgroundTransparency = 1, ZIndex = 3,
    })

    local Pages = {}
    local Tabs = {}

    local function CreateTab(name, icon, order)
        local btn = Create("TextButton", {
            Parent = sidebar, Size = UDim2.new(1,0,0,36),
            BackgroundColor3 = Color3.fromRGB(24,24,32),
            BackgroundTransparency = 0.4,
            Text = "  " .. icon .. "   " .. name,
            Font = Enum.Font.GothamMedium, TextSize = 12,
            TextColor3 = CONFIG.TextDark, TextXAlignment = Enum.TextXAlignment.Left,
            BorderSizePixel = 0, LayoutOrder = order,
            AutoButtonColor = false, ZIndex = 4,
        }, { Corner(8) })
        Create("UIPadding", { Parent = btn, PaddingLeft = UDim.new(0,12) })
        RegisterFont(btn)

        local stroke = Create("UIStroke", { Parent = btn, Color = CONFIG.Accent, Thickness = 1, Transparency = 1 })

        local page = Create("ScrollingFrame", {
            Parent = content, Size = UDim2.new(1,0,1,0),
            BackgroundTransparency = 1, Visible = false,
            ScrollBarThickness = 2, ScrollBarImageColor3 = CONFIG.Accent,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(0,0,0,0), BorderSizePixel = 0, ZIndex = 3,
        })
        Create("UIPadding", { Parent = page, PaddingTop = UDim.new(0,4), PaddingBottom = UDim.new(0,4) })
        Create("UIListLayout", { Parent = page, Padding = UDim.new(0,10) })

        Pages[name] = page
        Tabs[name] = { btn = btn, stroke = stroke }

        btn.MouseButton1Click:Connect(function()
            for n, p in pairs(Pages) do p.Visible = (n == name) end
            for n, t2 in pairs(Tabs) do
                TweenService:Create(t2.btn, TweenInfo.new(0.2), {
                    TextColor3 = (n == name) and CONFIG.Accent or CONFIG.TextDark,
                    BackgroundTransparency = (n == name) and 0.15 or 0.4,
                }):Play()
                TweenService:Create(t2.stroke, TweenInfo.new(0.2), {
                    Transparency = (n == name) and 0.4 or 1,
                }):Play()
            end
        end)
        return page
    end

    local function CreateCard(parent, title)
        local card = Create("Frame", {
            Parent = parent, Size = UDim2.new(1,-8,0,0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = CONFIG.CardBg, BackgroundTransparency = 0.15,
            BorderSizePixel = 0, ZIndex = 4,
        }, { Corner(10) })
        Create("UIStroke", { Parent = card, Color = Color3.fromRGB(50,50,65), Thickness = 1, Transparency = 0.4 })
        Create("UIPadding", {
            Parent = card, PaddingTop = UDim.new(0,14),
            PaddingBottom = UDim.new(0,14),
            PaddingLeft = UDim.new(0,14), PaddingRight = UDim.new(0,14),
        })
        Create("UIListLayout", { Parent = card, Padding = UDim.new(0,10) })
        if title then
            RegisterFont(RegisterTheme(Create("TextLabel", {
                Parent = card, Size = UDim2.new(1,0,0,14),
                BackgroundTransparency = 1, Text = title:upper(),
                Font = Enum.Font.GothamMedium, TextSize = 10,
                TextColor3 = CONFIG.Accent, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5,
            })))
        end
        return card
    end

    local function CreateToggle(parent, text, default, cb, order)
        local row = Create("Frame", {
            Parent = parent, Size = UDim2.new(1,0,0,28),
            BackgroundTransparency = 1, LayoutOrder = order or 1,
        })
        RegisterFont(Create("TextLabel", {
            Parent = row, Size = UDim2.new(1,-50,1,0),
            BackgroundTransparency = 1, Text = text,
            Font = Enum.Font.Gotham, TextSize = 13,
            TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5,
        }))

        local sw = Create("Frame", {
            Parent = row, Size = UDim2.new(0,28,0,14),
            Position = UDim2.new(1,-28,0.5,-7),
            BackgroundColor3 = default and CONFIG.Accent or Color3.fromRGB(40,40,50),
            BorderSizePixel = 0, ZIndex = 5,
        }, { Corner(7) })
        local kn = Create("Frame", {
            Parent = sw, Size = UDim2.new(0,10,0,10),
            Position = default and UDim2.new(1,-12,0.5,-5) or UDim2.new(0,2,0.5,-5),
            BackgroundColor3 = Color3.new(1,1,1),
            BorderSizePixel = 0, ZIndex = 6,
        }, { Corner(5) })

        local state = default
        local click = Create("TextButton", {
            Parent = row, Size = UDim2.new(1,0,1,0),
            BackgroundTransparency = 1, Text = "", ZIndex = 7,
        })
        click.MouseButton1Click:Connect(function()
            state = not state
            TweenService:Create(sw, TweenInfo.new(0.2), {
                BackgroundColor3 = state and CONFIG.Accent or Color3.fromRGB(40,40,50),
            }):Play()
            TweenService:Create(kn, TweenInfo.new(0.2), {
                Position = state and UDim2.new(1,-12,0.5,-5) or UDim2.new(0,2,0.5,-5),
            }):Play()
            cb(state)
        end)
        RegisterSearch({ row = row, text = text:lower() })
    end

    local function CreateSlider(parent, text, min, max, default, suffix, cb, order)
        local row = Create("Frame", {
            Parent = parent, Size = UDim2.new(1,0,0,44),
            BackgroundTransparency = 1, LayoutOrder = order or 1,
        })
        RegisterFont(Create("TextLabel", {
            Parent = row, Size = UDim2.new(1,-60,0,18),
            BackgroundTransparency = 1, Text = text,
            Font = Enum.Font.Gotham, TextSize = 13,
            TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5,
        }))
        local val = RegisterFont(Create("TextLabel", {
            Parent = row, Size = UDim2.new(0,60,0,18),
            Position = UDim2.new(1,-60,0,0),
            BackgroundTransparency = 1,
            Text = tostring(default) .. (suffix or ""),
            Font = Enum.Font.GothamMedium, TextSize = 13,
            TextColor3 = CONFIG.Accent, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 5,
        }))

        local track = Create("Frame", {
            Parent = row, Size = UDim2.new(1,0,0,3),
            Position = UDim2.new(0,0,1,-10),
            BackgroundColor3 = Color3.fromRGB(30,30,40),
            BorderSizePixel = 0, ZIndex = 5,
        }, { Corner(2) })
        local fill = Create("Frame", {
            Parent = track, Size = UDim2.new((default-min)/(max-min),0,1,0),
            BackgroundColor3 = CONFIG.Accent, BorderSizePixel = 0, ZIndex = 6,
        }, { Corner(2) })
        local g = Instance.new("UIGradient", fill)
        g.Color = ColorSequence.new(CONFIG.Accent, CONFIG.Accent2)
        RegisterTheme(fill)

        local knob = Create("Frame", {
            Parent = track, Size = UDim2.new(0,10,0,10),
            Position = UDim2.new((default-min)/(max-min),-5,0.5,-5),
            BackgroundColor3 = Color3.new(1,1,1),
            BorderSizePixel = 0, ZIndex = 7,
        }, { Corner(5) })

        local hit = Create("TextButton", {
            Parent = row, Size = UDim2.new(1,0,0,18),
            Position = UDim2.new(0,0,1,-16),
            BackgroundTransparency = 1, Text = "", ZIndex = 8,
        })
        local drag = false
        local function update(x)
            local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local v = math.floor(min + (max - min) * rel)
            fill.Size = UDim2.new(rel,0,1,0)
            knob.Position = UDim2.new(rel,-5,0.5,-5)
            val.Text = tostring(v) .. (suffix or "")
            cb(v)
        end
        hit.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true; update(i.Position.X) end
        end)
        Track(UserInputService.InputChanged:Connect(function(i)
            if drag and i.UserInputType == Enum.UserInputType.MouseMovement then update(i.Position.X) end
        end))
        Track(UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
        end))
        RegisterSearch({ row = row, text = text:lower() })
    end

    local function CreateDropdown(parent, text, options, default, cb, order)
        local row = Create("Frame", {
            Parent = parent, Size = UDim2.new(1,0,0,28),
            BackgroundTransparency = 1, LayoutOrder = order or 1,
        })
        RegisterFont(Create("TextLabel", {
            Parent = row, Size = UDim2.new(0.5,0,1,0),
            BackgroundTransparency = 1, Text = text,
            Font = Enum.Font.Gotham, TextSize = 13,
            TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5,
        }))
        local btn = RegisterFont(Create("TextButton", {
            Parent = row, Size = UDim2.new(0,100,0,24),
            Position = UDim2.new(1,-100,0.5,-12),
            BackgroundColor3 = Color3.fromRGB(30,30,40),
            Text = tostring(default),
            Font = Enum.Font.Gotham, TextSize = 11,
            TextColor3 = CONFIG.Accent,
            BorderSizePixel = 0, ZIndex = 5, AutoButtonColor = false,
        }, { Corner(6) }))
        local idx = 1
        for i, v in ipairs(options) do if v == default then idx = i end end
        btn.MouseButton1Click:Connect(function()
            idx = idx % #options + 1
            btn.Text = tostring(options[idx])
            cb(options[idx])
        end)
        RegisterSearch({ row = row, text = text:lower() })
    end

    local function CreateButton(parent, text, callback, order)
        local btn = RegisterFont(Create("TextButton", {
            Parent = parent, Size = UDim2.new(1,0,0,32),
            BackgroundColor3 = Color3.fromRGB(30,30,40),
            Text = text, Font = Enum.Font.GothamMedium, TextSize = 12,
            TextColor3 = CONFIG.Text, BorderSizePixel = 0,
            AutoButtonColor = false, LayoutOrder = order or 1, ZIndex = 5,
        }, { Corner(6) }))
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = CONFIG.Accent, TextColor3 = Color3.new(0,0,0),
            }):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = Color3.fromRGB(30,30,40), TextColor3 = CONFIG.Text,
            }):Play()
        end)
        btn.MouseButton1Click:Connect(callback)
        RegisterSearch({ row = btn, text = text:lower() })
    end

    local HomeTab = CreateTab("Home", "🏠", 1)
    local CombatTab = CreateTab("Combat", "⚔️", 2)
    local VisualsTab = CreateTab("Visuals", "👁️", 3)
    local CosmeticsTab = CreateTab("Cosmetics", "✨", 4)
    local MovementTab = CreateTab("Movement", "🏃", 5)
    local TrollTab = CreateTab("Troll", "😈", 6)
    local MusicTab = CreateTab("Music", "🎵", 7)
    local SettingsTab = CreateTab("Settings", "⚙️", 8)

    local pCard = CreateCard(HomeTab, "Player")
    Create("TextLabel", { Parent = pCard, Size = UDim2.new(1,0,0,20),
        BackgroundTransparency = 1, Text = "User: " .. LocalPlayer.Name,
        Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = CONFIG.Text,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 })
    Create("TextLabel", { Parent = pCard, Size = UDim2.new(1,0,0,20),
        BackgroundTransparency = 1, Text = "ID: " .. LocalPlayer.UserId,
        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = CONFIG.TextDark,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 })

    local aimCard = CreateCard(CombatTab, "Aimbot")
    CreateToggle(aimCard, "Enable Aimbot (RMB)", CONFIG.AimbotEnabled, function(v) CONFIG.AimbotEnabled = v end, 1)
    CreateSlider(aimCard, "FOV Radius", 20, 600, CONFIG.AimbotFOV, "px", function(v) CONFIG.AimbotFOV = v; FOVCircle.Radius = v end, 2)
    CreateSlider(aimCard, "Smoothness", 5, 100, math.floor(CONFIG.AimbotSmooth * 100), "%", function(v) CONFIG.AimbotSmooth = v/100 end, 3)
    CreateSlider(aimCard, "Prediction", 0, 50, math.floor(CONFIG.AimbotPredict * 100), "ms", function(v) CONFIG.AimbotPredict = v/100 end, 4)
    CreateDropdown(aimCard, "Part", {"Head","Torso","HumanoidRootPart"}, CONFIG.AimbotPart, function(v) CONFIG.AimbotPart = v end, 5)
    CreateToggle(aimCard, "Silent Aim", CONFIG.AimbotSilent, function(v) CONFIG.AimbotSilent = v end, 6)
    CreateToggle(aimCard, "Auto Fire", CONFIG.AimbotAutoFire, function(v) CONFIG.AimbotAutoFire = v end, 7)
    CreateToggle(aimCard, "Visible Check", CONFIG.AimbotVisible, function(v) CONFIG.AimbotVisible = v end, 8)

    local kaCard = CreateCard(CombatTab, "Kill Aura")
    CreateToggle(kaCard, "Enable Kill Aura (" .. Keybinds.KillAura.Name .. ")", CONFIG.KillAuraEnabled, function(v) CONFIG.KillAuraEnabled = v end, 1)
    CreateSlider(kaCard, "Range", 5, 100, CONFIG.KillAuraRange, "s", function(v) CONFIG.KillAuraRange = v end, 2)
    CreateSlider(kaCard, "Delay", 1, 50, math.floor(CONFIG.KillAuraDelay*100), "ms", function(v) CONFIG.KillAuraDelay = v/100 end, 3)

    local tbCard = CreateCard(CombatTab, "Triggerbot")
    CreateToggle(tbCard, "Enable (" .. Keybinds.Triggerbot.Name .. ")", CONFIG.TriggerbotEnabled, function(v) CONFIG.TriggerbotEnabled = v end, 1)

    local espCard = CreateCard(VisualsTab, "ESP")
    CreateToggle(espCard, "Enable ESP", CONFIG.ESPEnabled, function(v) CONFIG.ESPEnabled = v end, 1)
    CreateToggle(espCard, "Box", CONFIG.ESPBox, function(v) CONFIG.ESPBox = v end, 2)
    CreateToggle(espCard, "Health", CONFIG.ESPHealth, function(v) CONFIG.ESPHealth = v end, 3)
    CreateToggle(espCard, "Name", CONFIG.ESPName, function(v) CONFIG.ESPName = v end, 4)
    CreateToggle(espCard, "Distance", CONFIG.ESPDistance, function(v) CONFIG.ESPDistance = v end, 5)
    CreateToggle(espCard, "Skeleton", CONFIG.ESPSkeleton, function(v) CONFIG.ESPSkeleton = v end, 6)
    CreateToggle(espCard, "Weapon", CONFIG.ESPWeapon, function(v) CONFIG.ESPWeapon = v end, 7)
    CreateToggle(espCard, "Tracer", CONFIG.ESPTracer, function(v) CONFIG.ESPTracer = v end, 8)
    CreateToggle(espCard, "Head Dot", CONFIG.ESPHeadDot, function(v) CONFIG.ESPHeadDot = v end, 9)
    CreateSlider(espCard, "Max Distance", 100, 3000, CONFIG.ESPMaxDist, "m", function(v) CONFIG.ESPMaxDist = v end, 10)

    local chamsCard = CreateCard(VisualsTab, "Chams")
    CreateToggle(chamsCard, "Enemy Chams", CONFIG.ChamsEnemy, function(v) CONFIG.ChamsEnemy = v end, 1)
    CreateToggle(chamsCard, "Self Chams", CONFIG.ChamsSelf, function(v) CONFIG.ChamsSelf = v end, 2)
    CreateToggle(chamsCard, "Rainbow", CONFIG.ChamsRainbow, function(v) CONFIG.ChamsRainbow = v end, 3)

    local worldCard = CreateCard(VisualsTab, "World")
    CreateToggle(worldCard, "Fullbright", CONFIG.Fullbright, function(v)
        CONFIG.Fullbright = v
        if v then
            Lighting.Brightness = 3
            Lighting.Ambient = Color3.fromRGB(180,180,180)
            Lighting.OutdoorAmbient = Color3.fromRGB(180,180,180)
        else
            Lighting.Brightness = State.OriginalLighting.Brightness
            Lighting.Ambient = State.OriginalLighting.Ambient
            Lighting.OutdoorAmbient = State.OriginalLighting.OutdoorAmbient
        end
    end, 1)
    CreateToggle(worldCard, "No Fog", CONFIG.NoFog, function(v)
        CONFIG.NoFog = v
        Lighting.FogEnd = v and 100000 or State.OriginalLighting.FogEnd
    end, 2)

    local wingsCard = CreateCard(CosmeticsTab, "Wings")
    CreateToggle(wingsCard, "Enable Wings", CONFIG.WingsEnabled, function(v) CONFIG.WingsEnabled = v end, 1)
    local crownCard = CreateCard(CosmeticsTab, "Crown")
    CreateToggle(crownCard, "Enable Crown", CONFIG.CrownEnabled, function(v) CONFIG.CrownEnabled = v end, 1)
    local haloCard = CreateCard(CosmeticsTab, "Halo")
    CreateToggle(haloCard, "Enable Halo", CONFIG.HaloEnabled, function(v) CONFIG.HaloEnabled = v end, 1)
    local auraCard = CreateCard(CosmeticsTab, "Aura")
    CreateToggle(auraCard, "Enable Aura", CONFIG.AuraEnabled, function(v) CONFIG.AuraEnabled = v end, 1)
    local orbitCard = CreateCard(CosmeticsTab, "Orbit")
    CreateToggle(orbitCard, "Enable Orbit", CONFIG.OrbitEnabled, function(v) CONFIG.OrbitEnabled = v end, 1)
    local gcCard = CreateCard(CosmeticsTab, "Ground Circle")
    CreateToggle(gcCard, "Enable Circle", CONFIG.GroundCircle, function(v) CONFIG.GroundCircle = v end, 1)

    local flyCard = CreateCard(MovementTab, "Flight")
    CreateToggle(flyCard, "Fly (Fast)", CONFIG.FlyEnabled, function(v) CONFIG.FlyEnabled = v; if not v then StopFly() end end, 1)
    CreateSlider(flyCard, "Fly Speed", 20, 300, CONFIG.FlySpeed, "", function(v) CONFIG.FlySpeed = v end, 2)

    local moveCard = CreateCard(MovementTab, "Movement")
    CreateToggle(moveCard, "Noclip (" .. Keybinds.Noclip.Name .. ")", CONFIG.NoclipEnabled, function(v) CONFIG.NoclipEnabled = v end, 1)
    CreateToggle(moveCard, "Speed", CONFIG.SpeedEnabled, function(v) CONFIG.SpeedEnabled = v end, 2)
    CreateSlider(moveCard, "WalkSpeed", 16, 200, CONFIG.WalkSpeed, "", function(v) CONFIG.WalkSpeed = v end, 3)
    CreateSlider(moveCard, "JumpPower", 50, 300, CONFIG.JumpPower, "", function(v) CONFIG.JumpPower = v end, 4)
    CreateToggle(moveCard, "Infinite Jump", CONFIG.InfiniteJump, function(v) CONFIG.InfiniteJump = v end, 5)
    CreateToggle(moveCard, "Auto Wallhop", CONFIG.AutoWallhop, function(v) CONFIG.AutoWallhop = v end, 6)
    CreateToggle(moveCard, "Click TP (" .. Keybinds.ClickTP.Name .. ")", CONFIG.ClickTPEnabled, function(v) CONFIG.ClickTPEnabled = v end, 7)
    CreateToggle(moveCard, "Stand (Follow)", CONFIG.StandEnabled, function(v) CONFIG.StandEnabled = v end, 8)

    local flingCard = CreateCard(TrollTab, "Fling")
    CreateToggle(flingCard, "Auto Fling (" .. Keybinds.Fling.Name .. ")", CONFIG.FlingEnabled, function(v) CONFIG.FlingEnabled = v end, 1)
    CreateSlider(flingCard, "Fling Range", 5, 100, CONFIG.FlingRange, "s", function(v) CONFIG.FlingRange = v end, 2)
    CreateButton(flingCard, "Fling Everyone", function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then ForceFling(p.Character) end
        end
        Notify("Everyone flung!", 2)
    end, 3)

    local invisCard = CreateCard(TrollTab, "Invisible")
    CreateToggle(invisCard, "Ghost Invisible (" .. Keybinds.Invisible.Name .. ")", CONFIG.InvisibleEnabled, function(v)
        CONFIG.InvisibleEnabled = v
        if v then ApplyGhost() else RestoreVis() end
    end, 1)

    local emoteCard = CreateCard(TrollTab, "Emotes")
    local function PlayEmoteNearest(animId, name)
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
        local closest, minD = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local d = (hrp.Position - myRoot.Position).Magnitude
                    if d < minD then minD = d; closest = p.Character end
                end
            end
        end
        if closest then
            local hum = closest:FindFirstChildOfClass("Humanoid")
            if hum then
                local animator = hum:FindFirstChildOfClass("Animator") or hum
                pcall(function()
                    local a = Instance.new("Animation")
                    a.AnimationId = "rbxassetid://" .. animId
                    animator:LoadAnimation(a):Play()
                end)
                Notify(name .. " on " .. closest.Name, 2)
            end
        end
    end
    CreateButton(emoteCard, "Bang Nearest", function() PlayEmoteNearest("5269855227", "Bang") end, 1)
    CreateButton(emoteCard, "Dance Nearest", function() PlayEmoteNearest("507771019", "Dance") end, 2)
    CreateButton(emoteCard, "Laugh Nearest", function() PlayEmoteNearest("507770818", "Laugh") end, 3)

    local songsCard = CreateCard(MusicTab, "Songs")
    local sortedSongs = {}
    for k in pairs(SONGS) do table.insert(sortedSongs, k) end
    table.sort(sortedSongs)
    for i, name in ipairs(sortedSongs) do
        CreateButton(songsCard, "🎵 " .. name, function() PlaySong(name) end, i)
    end
    CreateButton(CreateCard(MusicTab, "Controls"), "⏹ Stop", function()
        State.PlayingSong = false
        Notify("Stopped", 1.5)
    end, 1)

    local themeCard = CreateCard(SettingsTab, "Theme Color")
    local palFrame = Create("Frame", {
        Parent = themeCard, Size = UDim2.new(1,0,0,90),
        BackgroundTransparency = 1, ZIndex = 4,
    })
    Create("UIGridLayout", {
        Parent = palFrame, CellSize = UDim2.new(0,32,0,32),
        CellPadding = UDim2.new(0,8,0,8),
    })
    local COLORS = {
        Color3.fromRGB(160,110,255), Color3.fromRGB(255,100,200),
        Color3.fromRGB(100,150,255), Color3.fromRGB(100,220,255),
        Color3.fromRGB(100,255,150), Color3.fromRGB(180,255,100),
        Color3.fromRGB(255,220,100), Color3.fromRGB(255,160,80),
        Color3.fromRGB(255,100,100), Color3.fromRGB(240,240,240),
        Color3.fromRGB(150,150,160), Color3.fromRGB(200,240,255),
    }
    for i, c in ipairs(COLORS) do
        local b = Create("TextButton", {
            Parent = palFrame, BackgroundColor3 = c,
            Text = "", BorderSizePixel = 0, LayoutOrder = i, ZIndex = 5,
        }, { Corner(16) })
        Create("UIStroke", { Parent = b, Color = Color3.new(1,1,1), Thickness = 1.5, Transparency = 0.4 })
        b.MouseButton1Click:Connect(function()
            CONFIG.Accent = c
            CONFIG.Accent2 = c:Lerp(Color3.new(1,1,1), 0.3)
            FOVCircle.Color = c
            for _, obj in ipairs(State.ThemeObjects) do
                if obj and obj.Parent then
                    pcall(function() TweenService:Create(obj, TweenInfo.new(0.25), { Color = c }):Play() end)
                    pcall(function() TweenService:Create(obj, TweenInfo.new(0.25), { TextColor3 = c }):Play() end)
                end
            end
            Notify("Theme updated", 1.5)
        end)
    end

    local dangerCard = CreateCard(SettingsTab, "Danger")
    CreateButton(dangerCard, "🚨 PANIC (Unload)", function() UNLOAD() end, 1)
    CreateButton(dangerCard, "🔄 Reset Character", function()
        local c = LocalPlayer.Character
        if c and c:FindFirstChildOfClass("Humanoid") then
            c:FindFirstChildOfClass("Humanoid").Health = 0
        end
    end, 2)

    local drag, dragStart, startPos
    header.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true; dragStart = i.Position; startPos = menu.Position
        end
    end)
    Track(UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dragStart
            menu.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
        end
    end))
    Track(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
    end))

    Pages["Home"].Visible = true
    Tabs["Home"].btn.TextColor3 = CONFIG.Accent
    Tabs["Home"].btn.BackgroundTransparency = 0.15
    Tabs["Home"].stroke.Transparency = 0.4

    menu.Visible = true
    TweenService:Create(menu, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -320, 0.5, -230)
    }):Play()

    local wmGui = Instance.new("ScreenGui")
    wmGui.Name = "CelestialWM"
    wmGui.ResetOnSpawn = false
    wmGui.IgnoreGuiInset = true
    wmGui.DisplayOrder = 998
    wmGui.Parent = playerGui

    local wm = Create("Frame", {
        Parent = wmGui, Size = UDim2.new(0,560,0,30),
        Position = UDim2.new(0.5,-280,0,12),
        BackgroundColor3 = CONFIG.Bg, BackgroundTransparency = 0.2,
        BorderSizePixel = 0, ZIndex = 3,
    }, { Corner(8) })
    local wms = Create("UIStroke", { Parent = wm, Color = CONFIG.Accent, Thickness = 1, Transparency = 0.4 })
    ApplyGradient(wms)
    RegisterTheme(wms)
    local wmText = RegisterFont(Create("TextLabel", {
        Parent = wm, Size = UDim2.new(1,-20,1,0),
        Position = UDim2.new(0,10,0,0), BackgroundTransparency = 1,
        Text = "Loading...", Font = Enum.Font.GothamMedium, TextSize = 11,
        TextColor3 = CONFIG.Text, ZIndex = 4,
    }))

    local fps, acc = 0, 0
    Track(RunService.Heartbeat:Connect(function(dt)
        if not State.Running then return end
        fps += 1; acc += dt
        if acc >= 1 then
            local ping = "N/A"
            pcall(function() ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValueString() end)
            local time = os.date("!%H:%M:%S", os.time() + (4*3600))
            wmText.Text = string.format("✦ CELESTIAL v%s  |  %s  |  %d FPS  |  %s  |  %s (Samara)",
                VERSION, LocalPlayer.Name, fps, ping, time)
            fps = 0; acc = 0
        end
    end))
end

-- ============================================================
-- COMBAT
-- ============================================================
local function GetPart(char)
    if not char then return nil end
    if CONFIG.AimbotPart == "Head" then return char:FindFirstChild("Head") end
    if CONFIG.AimbotPart == "Torso" then return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") end
    return char:FindFirstChild("HumanoidRootPart")
end

local function GetBestTarget()
    local cam = Workspace.CurrentCamera
    if not cam then return nil end
    local mouse = UserInputService:GetMouseLocation()
    local best, bestD = nil, CONFIG.AimbotFOV
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local part = GetPart(p.Character)
                if part then
                    local sp, on = cam:WorldToViewportPoint(part.Position)
                    if on then
                        local d = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
                        if d < bestD then
                            if CONFIG.AimbotVisible then
                                local myChar = LocalPlayer.Character
                                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                                if myRoot then
                                    local params = RaycastParams.new()
                                    params.FilterType = Enum.RaycastFilterType.Exclude
                                    params.FilterDescendantsInstances = {myChar}
                                    local ray = Workspace:Raycast(myRoot.Position, part.Position - myRoot.Position, params)
                                    if ray and not ray.Instance:IsDescendantOf(p.Character) then continue end
                                end
                            end
                            bestD = d; best = part
                        end
                    end
                end
            end
        end
    end
    return best
end

-- Silent aim hook (Fixed safe check)
if typeof(hookmetamethod) == "function" and typeof(getnamecallmethod) == "function" then
    local inSilent = false
    local oldNC = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        if not State.Running then return oldNC(self, ...) end
        local m = getnamecallmethod()
        if CONFIG.AimbotSilent and not inSilent and m == "Raycast" and self == Workspace then
            local origin, dir, params = ...
            if typeof(origin) == "Vector3" and typeof(dir) == "Vector3" then
                local myChar = LocalPlayer.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if myRoot and (origin - myRoot.Position).Magnitude < 25 then
                    local t = GetBestTarget()
                    if t then
                        inSilent = true
                        local newDir = (t.Position - origin).Unit * dir.Magnitude
                        local r = oldNC(self, origin, newDir, params)
                        inSilent = false
                        return r
                    end
                end
            end
        end
        return oldNC(self, ...)
    end))
end

-- ============================================================
-- MAIN LOOPS
-- ============================================================
Track(RunService.Stepped:Connect(function(_, dt)
    if not State.Running then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    hum.WalkSpeed = CONFIG.SpeedEnabled and CONFIG.WalkSpeed or 16
    hum.JumpPower = CONFIG.JumpPower
    hum.UseJumpPower = true

    if CONFIG.NoclipEnabled then
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end

    if CONFIG.InvisibleEnabled then ApplyGhost() end

    if CONFIG.InfiniteJump and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end

    if CONFIG.AutoWallhop and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        if tick() - State.WallhopCooldown > 0.15 then
            local state = hum:GetState()
            if state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.FallingDown then
                local params = RaycastParams.new()
                params.FilterDescendantsInstances = {char}
                params.FilterType = Enum.RaycastFilterType.Exclude
                local ray = Workspace:Raycast(hrp.Position, hrp.CFrame.LookVector * 3.5, params)
                if ray then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    hrp.AssemblyLinearVelocity = Vector3.new(
                        hrp.AssemblyLinearVelocity.X,
                        55,
                        hrp.AssemblyLinearVelocity.Z
                    )
                    State.WallhopCooldown = tick()
                end
            end
        end
    end

    if CONFIG.FlyEnabled then
        local cam = Workspace.CurrentCamera
        local bv = hrp:FindFirstChild("Celestial_FlyBV")
        local bg = hrp:FindFirstChild("Celestial_FlyBG")
        if not bv or not bg then
            StopFly()
            local n = Instance.new("BodyVelocity", hrp)
            n.Name = "Celestial_FlyBV"
            n.MaxForce = Vector3.new(1e5,1e5,1e5); n.P = 2000
            local g = Instance.new("BodyGyro", hrp)
            g.Name = "Celestial_FlyBG"
            g.MaxTorque = Vector3.new(1e5,1e5,1e5); g.P = 3000
            Controls:Disable() -- Fix: safe disable
        else
            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0,1,0) end
            local vel = move.Magnitude > 0 and move.Unit * CONFIG.FlySpeed or Vector3.zero
            bv.Velocity = bv.Velocity:Lerp(vel, math.min(dt * 10, 1))
            bg.CFrame = cam.CFrame
        end
    end

    if CONFIG.KillAuraEnabled and tick() - State.KillAuraCooldown > CONFIG.KillAuraDelay then
        State.KillAuraCooldown = tick()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local tHrp = p.Character:FindFirstChild("HumanoidRootPart")
                if tHrp and (tHrp.Position - hrp.Position).Magnitude < CONFIG.KillAuraRange then
                    local tool = char:FindFirstChildOfClass("Tool")
                    if tool then pcall(function() tool:Activate() end) end
                    local tHum = p.Character:FindFirstChildOfClass("Humanoid")
                    if tHum then pcall(function() tHum.Health = 0 end) end
                end
            end
        end
    end

    if CONFIG.TriggerbotEnabled and tick() - State.TriggerbotCooldown > 0.1 then
        local t = GetBestTarget()
        if t then
            State.TriggerbotCooldown = tick()
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then pcall(function() tool:Activate() end) end
        end
    end

    if CONFIG.FlingEnabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local tHrp = p.Character:FindFirstChild("HumanoidRootPart")
                if tHrp and (tHrp.Position - hrp.Position).Magnitude < CONFIG.FlingRange then
                    ForceFling(p.Character)
                end
            end
        end
    end

    if CONFIG.StandEnabled and State.StandTarget and State.StandTarget.Parent then
        local tHrp = State.StandTarget:FindFirstChild("HumanoidRootPart")
        if tHrp then hrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, -3) end
    end
end))

local mouse = LocalPlayer:GetMouse()
Track(UserInputService.InputBegan:Connect(function(input, gp)
    if CONFIG.ClickTPEnabled and input.UserInputType == Enum.UserInputType.MouseButton1 and not gp then
        if UserInputService:GetFocusedTextBox() then return end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and mouse.Hit then
            hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
        end
    end
end))

local frameTick = 0
Track(RunService.RenderStepped:Connect(function()
    if not State.Running then return end
    frameTick += 1
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local m = UserInputService:GetMouseLocation()

    FOVCircle.Position = m
    FOVCircle.Radius = CONFIG.AimbotFOV
    FOVCircle.Visible = CONFIG.AimbotEnabled and (UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or UserInputService:IsKeyDown(CONFIG.AimbotKey))

    if CONFIG.InvisibleEnabled then ApplyGhost() end

    if CONFIG.AimbotEnabled then
        local active = UserInputService:IsKeyDown(CONFIG.AimbotKey) or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        if active then
            local t = GetBestTarget()
            if t then
                local sp = cam:WorldToViewportPoint(t.Position)
                if typeof(mousemoverel) == "function" then
                    mousemoverel((sp.X - m.X) * CONFIG.AimbotSmooth, (sp.Y - m.Y) * CONFIG.AimbotSmooth)
                end
                if CONFIG.AimbotAutoFire then
                    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                    if tool then pcall(function() tool:Activate() end) end
                end
            end
        end
    end

    if frameTick % 3 == 0 then
        UpdateCosmetics()
        if CONFIG.ChamsSelf then ApplyChams(LocalPlayer.Character) else RemoveChams(LocalPlayer.Character) end
    end
end))

local espTick = 0
Track(RunService.Heartbeat:Connect(function()
    if not State.Running then return end
    espTick += 1
    if espTick % 2 ~= 0 then return end

    if not CONFIG.ESPEnabled then
        for _, t in pairs(State.ESPCache) do
            for _, v in pairs(t) do
                if typeof(v) == "table" then for _, l in pairs(v) do pcall(function() l.Visible = false end) end
                else pcall(function() v.Visible = false end) end
            end
        end
        return
    end

    local cam = Workspace.CurrentCamera
    if not cam then return end
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local active = {}

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character.Parent then
            local char = p.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
            local head = char:FindFirstChild("Head")
            if hum and hum.Health > 0 and hrp and head then
                local dist = myRoot and (hrp.Position - myRoot.Position).Magnitude or 0
                if dist <= CONFIG.ESPMaxDist then
                    active[p] = true
                    local t = State.ESPCache[p]
                    if not t then
                        t = {
                            box = TrackD(Draw("Square")),
                            name = TrackD(Draw("Text")),
                            dist = TrackD(Draw("Text")),
                            hpBg = TrackD(Draw("Square")),
                            hpBar = TrackD(Draw("Square")),
                            tracer = TrackD(Draw("Line")),
                            headDot = TrackD(Draw("Circle")),
                            weapon = TrackD(Draw("Text")),
                            skel = {},
                        }
                        for i = 1, 6 do t.skel[i] = TrackD(Draw("Line")) end
                        State.ESPCache[p] = t
                    end

                    local hSp, hOn = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                    local rSp, rOn = cam:WorldToViewportPoint(hrp.Position)

                    if hOn and rOn then
                        local h = math.abs(rSp.Y - hSp.Y)
                        local w = h * 0.55
                        local bx = hSp.X - w/2
                        local by = hSp.Y

                        t.box.Visible = CONFIG.ESPBox
                        t.box.Position = Vector2.new(bx, by)
                        t.box.Size = Vector2.new(w, h)
                        t.box.Color = CONFIG.Accent
                        t.box.Thickness = 1
                        t.box.Filled = false

                        if CONFIG.ESPHealth then
                            local r = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                            t.hpBg.Visible = true
                            t.hpBg.Position = Vector2.new(bx - 6, by)
                            t.hpBg.Size = Vector2.new(3, h)
                            t.hpBg.Color = Color3.fromRGB(25, 25, 30)
                            t.hpBg.Filled = true
                            t.hpBar.Visible = true
                            t.hpBar.Position = Vector2.new(bx - 6, by + h * (1 - r))
                            t.hpBar.Size = Vector2.new(3, h * r)
                            t.hpBar.Color = Color3.fromRGB(255 * (1 - r), 255 * r, 80)
                            t.hpBar.Filled = true
                        else
                            t.hpBg.Visible = false
                            t.hpBar.Visible = false
                        end

                        if CONFIG.ESPName then
                            t.name.Visible = true
                            t.name.Text = p.Name
                            t.name.Position = Vector2.new(bx + w/2, by - 16)
                            t.name.Size = 13
                            t.name.Color = CONFIG.Accent
                            t.name.Center = true
                            t.name.Outline = true
                            t.name.Font = CONFIG.ESPFont
                        else t.name.Visible = false end

                        if CONFIG.ESPDistance then
                            t.dist.Visible = true
                            t.dist.Text = math.floor(dist) .. "m"
                            t.dist.Position = Vector2.new(bx + w/2, by + h + 2)
                            t.dist.Size = 11
                            t.dist.Color = Color3.fromRGB(200,200,210)
                            t.dist.Center = true
                            t.dist.Outline = true
                            t.dist.Font = CONFIG.ESPFont
                        else t.dist.Visible = false end

                        if CONFIG.ESPTracer then
                            t.tracer.Visible = true
                            t.tracer.From = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y)
                            t.tracer.To = Vector2.new(rSp.X, rSp.Y)
                            t.tracer.Color = CONFIG.Accent
                            t.tracer.Thickness = 1
                        else t.tracer.Visible = false end

                        if CONFIG.ESPHeadDot then
                            t.headDot.Visible = true
                            t.headDot.Position = Vector2.new(hSp.X, hSp.Y)
                            t.headDot.Radius = 3
                            t.headDot.Color = CONFIG.Accent2
                        else t.headDot.Visible = false end

                        if CONFIG.ESPWeapon then
                            local tool = char:FindFirstChildOfClass("Tool")
                            if tool then
                                t.weapon.Visible = true
                                t.weapon.Text = tool.Name
                                t.weapon.Position = Vector2.new(bx + w/2, by + h + 16)
                                t.weapon.Size = 10
                                t.weapon.Color = Color3.fromRGB(180,180,190)
                                t.weapon.Center = true
                                t.weapon.Outline = true
                                t.weapon.Font = CONFIG.ESPFont
                            else t.weapon.Visible = false end
                        else t.weapon.Visible = false end

                        if CONFIG.ESPSkeleton then
                            local bones = {
                                {head, char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")},
                                {char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"), char:FindFirstChild("LowerTorso") or char:FindFirstChild("Torso")},
                                {char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"), char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")},
                                {char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"), char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")},
                                {char:FindFirstChild("LowerTorso") or char:FindFirstChild("Torso"), char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg")},
                                {char:FindFirstChild("LowerTorso") or char:FindFirstChild("Torso"), char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg")},
                            }
                            for i, pair in ipairs(bones) do
                                local line = t.skel[i]
                                local a, b = pair[1], pair[2]
                                if a and b and a.Parent and b.Parent then
                                    local sa, oa = cam:WorldToViewportPoint(a.Position)
                                    local sb, ob = cam:WorldToViewportPoint(b.Position)
                                    if oa and ob then
                                        line.Visible = true
                                        line.From = Vector2.new(sa.X, sa.Y)
                                        line.To = Vector2.new(sb.X, sb.Y)
                                        line.Color = Color3.fromRGB(255,255,255)
                                        line.Thickness = 1
                                    else line.Visible = false end
                                else line.Visible = false end
                            end
                        else for i = 1, 6 do t.skel[i].Visible = false end end

                        if CONFIG.ChamsEnemy then ApplyChams(char) else RemoveChams(char) end
                    else
                        for _, v in pairs(t) do
                            if typeof(v) == "table" then for _, l in pairs(v) do pcall(function() l.Visible = false end) end
                            else pcall(function() v.Visible = false end) end
                        end
                    end
                end
            end
        end
    end

    for p, t in pairs(State.ESPCache) do
        if not active[p] then
            for _, v in pairs(t) do
                if typeof(v) == "table" then for _, l in pairs(v) do pcall(function() l:Remove() end) end
                else pcall(function() v:Remove() end) end
            end
            State.ESPCache[p] = nil
            if p.Character then RemoveChams(p.Character) end
        end
    end
end))

function UNLOAD()
    if not State.Running then return end
    State.Running = false

    if State.menuFrame then pcall(function() State.menuFrame:Destroy() end) end
    if State.mainGui then pcall(function() State.mainGui:Destroy() end) end

    for _, c in ipairs(State.Connections) do pcall(function() c:Disconnect() end) end
    for _, d in ipairs(State.Drawings) do pcall(function() d:Remove() end) end

    StopFly()
    RestoreVis()

    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then RemoveChams(p.Character) end
    end
    for char in pairs(State.ChamsCache) do pcall(function() RemoveChams(char) end) end

    for _, v in pairs(State.Cosmetics) do
        if v and v.Parent then pcall(function() v:Destroy() end) end
    end
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name:find("Celestial") then pcall(function() obj:Destroy() end) end
    end

    Lighting.Brightness = State.OriginalLighting.Brightness
    Lighting.Ambient = State.OriginalLighting.Ambient
    Lighting.OutdoorAmbient = State.OriginalLighting.OutdoorAmbient
    Lighting.FogEnd = State.OriginalLighting.FogEnd

    print("[Celestial] Unloaded.")
    _G.CelestialUnload = nil
end
_G.CelestialUnload = UNLOAD

Track(UserInputService.InputBegan:Connect(function(input, gp)
    if gp or UserInputService:GetFocusedTextBox() then return end
    local k = input.KeyCode

    if k == Keybinds.ToggleMenu and State.menuFrame then
        local m = State.menuFrame
        if m.Visible then
            TweenService:Create(m, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, -320, 1, 500)
            }):Play()
            task.wait(0.3)
            m.Visible = false
        else
            m.Visible = true
            TweenService:Create(m, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = UDim2.new(0.5, -320, 0.5, -230)
            }):Play()
        end
    elseif k == Keybinds.Fly then
        CONFIG.FlyEnabled = not CONFIG.FlyEnabled
        if not CONFIG.FlyEnabled then StopFly() end
        Notify("Fly: " .. (CONFIG.FlyEnabled and "ON" or "OFF"), 1.5)
    elseif k == Keybinds.Noclip then
        CONFIG.NoclipEnabled = not CONFIG.NoclipEnabled
        if not CONFIG.NoclipEnabled and LocalPlayer.Character then
            for _, v in ipairs(LocalPlayer.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = true end
            end
        end
        Notify("Noclip: " .. (CONFIG.NoclipEnabled and "ON" or "OFF"), 1.5)
    elseif k == Keybinds.Fling then
        CONFIG.FlingEnabled = not CONFIG.FlingEnabled
        Notify("Fling: " .. (CONFIG.FlingEnabled and "ON" or "OFF"), 1.5)
    elseif k == Keybinds.Stand then
        CONFIG.StandEnabled = not CONFIG.StandEnabled
        Notify("Stand: " .. (CONFIG.StandEnabled and "ON" or "OFF"), 1.5)
    elseif k == Keybinds.Invisible then
        CONFIG.InvisibleEnabled = not CONFIG.InvisibleEnabled
        if CONFIG.InvisibleEnabled then ApplyGhost() else RestoreVis() end
        Notify("Invisible: " .. (CONFIG.InvisibleEnabled and "ON" or "OFF"), 1.5)
    elseif k == Keybinds.ClickTP then
        CONFIG.ClickTPEnabled = not CONFIG.ClickTPEnabled
        Notify("Click TP: " .. (CONFIG.ClickTPEnabled and "ON" or "OFF"), 1.5)
    elseif k == Keybinds.KillAura then
        CONFIG.KillAuraEnabled = not CONFIG.KillAuraEnabled
        Notify("Kill Aura: " .. (CONFIG.KillAuraEnabled and "ON" or "OFF"), 1.5)
    elseif k == Keybinds.Triggerbot then
        CONFIG.TriggerbotEnabled = not CONFIG.TriggerbotEnabled
        Notify("Triggerbot: " .. (CONFIG.TriggerbotEnabled and "ON" or "OFF"), 1.5)
    elseif k == Keybinds.Panic or k == Keybinds.Unload then
        UNLOAD()
    end
end))

Track(LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if not State.Running then return end
    pcall(BuildCosmetics)
    if CONFIG.InvisibleEnabled then ApplyGhost() end
    if CONFIG.NoclipEnabled then
        local char = LocalPlayer.Character
        if char then
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end
    end
end))

task.spawn(function()
    pcall(BuildCosmetics)
    pcall(BuildUI)
    print("[Celestial] v7.5 loaded successfully.")
    task.wait(0.5)
    Notify("✦ Celestial v" .. VERSION .. " loaded", 3)
end)
