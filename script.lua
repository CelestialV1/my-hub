-- ============================================================
-- CELESTIAL v7.0 ULTIMATE
-- Premium UI + Full Features + Everything working
-- ============================================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local Debris           = game:GetService("Debris")
local Stats            = game:GetService("Stats")
local Lighting         = game:GetService("Lighting")
local VirtualUser      = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer      = Players.LocalPlayer

local CELESTIAL_ASSET = "rbxassetid://94872985442978"
local VERSION = "7.0 ULTIMATE"

-- ============================================================
-- CONFIG
-- ============================================================
local CONFIG = {
    -- THEME
    Accent   = Color3.fromRGB(160, 110, 255),
    Accent2  = Color3.fromRGB(255, 100, 200),
    Accent3  = Color3.fromRGB(100, 200, 255),
    Bg       = Color3.fromRGB(8, 8, 12),
    CardBg   = Color3.fromRGB(18, 18, 24),
    Text     = Color3.fromRGB(240, 240, 250),
    TextDark = Color3.fromRGB(140, 140, 160),
    GUIFont  = Enum.Font.Gotham,
    UIScale  = 1,

    -- COMBAT
    AimbotEnabled  = false,
    AimbotKey      = Enum.KeyCode.E,
    AimbotFOV      = 200,
    AimbotSmooth   = 0.35,
    AimbotPart     = "Head",
    AimbotPredict  = 0.15,
    AimbotSilent   = false,
    AimbotAutoFire = false,
    AimbotVisible  = false,
    KillAuraEnabled= false,
    KillAuraRange  = 25,
    KillAuraDelay  = 0.1,
    TriggerbotEnabled = false,

    -- ESP
    ESPEnabled    = true,
    ESPBox        = true,
    ESPHealth     = true,
    ESPName       = true,
    ESPDistance   = true,
    ESPSkeleton   = true,
    ESPWeapon     = true,
    ESPTracer     = true,
    ESPHeadDot    = true,
    ESPMaxDist    = 1500,
    ESPFont       = Drawing.Fonts.Plex,

    -- CHAMS
    ChamsEnemy    = false,
    ChamsSelf     = false,
    ChamsMaterial = "Highlight",
    ChamsRainbow  = false,
    ChamsColor    = Color3.fromRGB(160, 110, 255),

    -- COSMETICS
    WingsEnabled  = false,
    WingsColor    = Color3.fromRGB(160, 110, 255),
    CrownEnabled  = false,
    HaloEnabled   = false,
    AuraEnabled   = false,
    OrbitEnabled  = false,
    GroundCircle  = false,

    -- WORLD
    Fullbright    = false,
    NoFog         = false,

    -- MOVEMENT
    FlyEnabled    = false,
    FlySpeed      = 60,
    LegitFlyEnabled = false,
    NoclipEnabled = false,
    SpeedEnabled  = false,
    WalkSpeed     = 50,
    JumpPower     = 50,
    InfiniteJump  = false,
    AutoWallhop   = false,
    StandEnabled  = false,
    ClickTPEnabled= false,

    -- TROLL
    FlingEnabled  = false,
    FlingRange    = 25,
    InvisibleEnabled = false,
    FreezeEnabled = false,
    ChatSpamEnabled = false,
    ChatSpamText  = "CELESTIAL ON TOP",

    -- MUSIC
    MusicVolume   = 2,
}

-- ============================================================
-- KEYBINDS
-- ============================================================
local Keybinds = {
    ToggleMenu   = Enum.KeyCode.RightShift,
    Fly          = Enum.KeyCode.F,
    Noclip       = Enum.KeyCode.G,
    Fling        = Enum.KeyCode.V,
    Stand        = Enum.KeyCode.Z,
    Invisible    = Enum.KeyCode.I,
    ClickTP      = Enum.KeyCode.B,
    KillAura     = Enum.KeyCode.K,
    Triggerbot   = Enum.KeyCode.T,
    Unload       = Enum.KeyCode.Delete,
    Panic        = Enum.KeyCode.P,
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
    Notifications = {},
    Cosmetics = {},
    StandTarget = nil,
    menuFrame = nil,
    mainGui = nil,
    blur = nil,
    PlayingSong = false,
    WallhopCooldown = 0,
    KillAuraCooldown = 0,
    TriggerbotCooldown = 0,
    ChatSpamCooldown = 0,
    FlingAccum = {},
    OriginalLighting = {
        Brightness = Lighting.Brightness,
        FogEnd = Lighting.FogEnd,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        ClockTime = Lighting.ClockTime,
    },
    OriginalSizes = {},
    OriginalC0 = {},
}

local function Track(c) if State.Running and c then table.insert(State.Connections, c) end return c end
local function TrackD(d) if State.Running and d then table.insert(State.Drawings, d) end return d end
local function RegisterTheme(o) if State.Running then table.insert(State.ThemeObjects, o) end; return o end
local function RegisterFont(o) if State.Running then table.insert(State.FontObjects, o) end; return o end
local function RegisterSearch(w) if State.Running then table.insert(State.SearchWidgets, w) end end

-- ============================================================
-- DRAWINGS
-- ============================================================
local Draw = Drawing.new
local FOVCircle = TrackD(Draw("Circle"))
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 64
FOVCircle.Color = CONFIG.Accent
FOVCircle.Transparency = 0.9
FOVCircle.Radius = CONFIG.AimbotFOV
FOVCircle.Visible = false

-- ============================================================
-- UTILITY
-- ============================================================
local function Create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    if children then for _, c in ipairs(children) do c.Parent = inst end end
    return inst
end

local function Corner(r) return Create("UICorner", { CornerRadius = UDim.new(0, r) }) end
local function Stroke(color, thickness, transparency)
    return Create("UIStroke", { Color = color or CONFIG.Accent, Thickness = thickness or 1, Transparency = transparency or 0.5 })
end

local function applyStrokeGradient(stroke)
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new(CONFIG.Accent, CONFIG.Accent2)
    grad.Rotation = 45
    grad.Parent = stroke
    return grad
end

-- ============================================================
-- NOTIFICATION SYSTEM
-- ============================================================
local notifGui = Instance.new("ScreenGui")
notifGui.Name = "CelestialNotifs"
notifGui.ResetOnSpawn = false
notifGui.IgnoreGuiInset = true
notifGui.DisplayOrder = 1002
notifGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local notifFrame = Create("Frame", {
    Parent = notifGui,
    Size = UDim2.new(0, 340, 1, 0),
    Position = UDim2.new(1, -360, 0, 100),
    BackgroundTransparency = 1,
    ZIndex = 5,
})
Create("UIListLayout", { Parent = notifFrame, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })

local function Notify(text, duration)
    duration = duration or 3
    local card = Create("Frame", {
        Parent = notifFrame,
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = CONFIG.CardBg,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        ZIndex = 6,
    }, { Corner(8) })
    local str = Stroke(CONFIG.Accent, 1.5, 0.3)
    str.Parent = card
    applyStrokeGradient(str)

    local accentBar = Create("Frame", {
        Parent = card, Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = CONFIG.Accent, BorderSizePixel = 0, ZIndex = 7,
    }, { Corner(2) })

    Create("TextLabel", {
        Parent = card, Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = text, Font = Enum.Font.GothamMedium, TextSize = 12,
        TextColor3 = CONFIG.Text,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
    })

    card.Position = UDim2.new(1, 20, 0, 0)
    TweenService:Create(card, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0),
    }):Play()

    task.delay(duration, function()
        TweenService:Create(card, TweenInfo.new(0.3), {
            Position = UDim2.new(1, 20, 0, 0),
        }):Play()
        task.delay(0.3, function() card:Destroy() end)
    end)
end

-- ============================================================
-- COSMETICS
-- ============================================================
local function BuildCosmetics()
    local char = LocalPlayer.Character
    if not char then return end

    -- Halo
    if not State.Cosmetics.Halo then
        local halo = Instance.new("Model", Workspace); halo.Name = "Celestial_Halo"
        for i = 1, 20 do
            local ball = Instance.new("Part", halo)
            ball.Name = "HaloBall"
            ball.Shape = Enum.PartType.Ball
            ball.Size = Vector3.new(0.28, 0.28, 0.28)
            ball.Material = Enum.Material.Neon
            ball.Color = CONFIG.Accent
            ball.Transparency = 0.1
            ball.CanCollide = false
            ball.CanQuery = false
            ball.Anchored = true
        end
        State.Cosmetics.Halo = halo
    end

    -- Crown
    if not State.Cosmetics.Crown then
        local crown = Instance.new("Part", Workspace); crown.Name = "Celestial_Crown"
        crown.Size = Vector3.new(1.5, 1, 1.5)
        crown.Transparency = 1
        crown.CanCollide = false
        crown.CanQuery = false
        crown.Anchored = true
        local mesh = Instance.new("SpecialMesh", crown)
        mesh.MeshType = Enum.MeshType.FileMesh
        mesh.MeshId = "rbxassetid://176213013"
        mesh.Scale = Vector3.new(0.9, 0.9, 0.9)
        State.Cosmetics.Crown = crown
    end

    -- Wings
    if not State.Cosmetics.Wings then
        local wings = Instance.new("Model", Workspace); wings.Name = "Celestial_Wings"
        for _, side in ipairs({-1, 1}) do
            for i = 1, 8 do
                local beamPart = Instance.new("Part", wings)
                beamPart.Name = "WingBeam"
                beamPart.Anchored = true
                beamPart.CanCollide = false
                beamPart.CanQuery = false
                beamPart.Transparency = 1
                beamPart.Size = Vector3.new(0.1, 0.1, 0.1)
            end
        end
        State.Cosmetics.Wings = wings
    end

    -- Aura (Particle attachments)
    if not State.Cosmetics.Aura then
        local aura = Instance.new("Folder", Workspace); aura.Name = "Celestial_Aura"
        State.Cosmetics.Aura = aura
    end

    -- Orbit rings
    if not State.Cosmetics.Orbit then
        local orbit = Instance.new("Model", Workspace); orbit.Name = "Celestial_Orbit"
        for i = 1, 3 do
            local ring = Instance.new("Part", orbit)
            ring.Name = "OrbitRing"
            ring.Shape = Enum.PartType.Cylinder
            ring.Size = Vector3.new(0.1, 8, 8)
            ring.Material = Enum.Material.Neon
            ring.Color = CONFIG.Accent
            ring.Transparency = 0.4
            ring.CanCollide = false
            ring.CanQuery = false
            ring.Anchored = true
        end
        State.Cosmetics.Orbit = orbit
    end

    -- Ground Circle
    if not State.Cosmetics.GroundCircle then
        local gc = Instance.new("Part", Workspace); gc.Name = "Celestial_GroundCircle"
        gc.Shape = Enum.PartType.Cylinder
        gc.Size = Vector3.new(0.1, 10, 10)
        gc.Material = Enum.Material.Neon
        gc.Color = CONFIG.Accent
        gc.Transparency = 0.5
        gc.CanCollide = false
        gc.CanQuery = false
        gc.Anchored = true
        gc.Orientation = Vector3.new(0, 0, 90)
        State.Cosmetics.GroundCircle = gc
    end
end

local function UpdateCosmetics()
    local char = LocalPlayer.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local t = tick()

    -- Halo
    if State.Cosmetics.Halo and head then
        State.Cosmetics.Halo.Parent = CONFIG.HaloEnabled and Workspace or nil
        if CONFIG.HaloEnabled then
            for i, ball in ipairs(State.Cosmetics.Halo:GetChildren()) do
                if ball.Name == "HaloBall" then
                    local angle = (i / 20) * math.pi * 2 + t * 2
                    ball.CFrame = head.CFrame * CFrame.new(math.cos(angle) * 1.6, 1.3, math.sin(angle) * 1.6)
                    ball.Color = Color3.fromHSV((t * 0.2 + i / 20) % 1, 0.8, 1)
                end
            end
        end
    end

    -- Crown
    if State.Cosmetics.Crown and head then
        State.Cosmetics.Crown.Parent = CONFIG.CrownEnabled and Workspace or nil
        if CONFIG.CrownEnabled then
            State.Cosmetics.Crown.CFrame = head.CFrame * CFrame.new(0, 0.75, 0)
            State.Cosmetics.Crown.Color = CONFIG.Accent
        end
    end

    -- Wings
    if State.Cosmetics.Wings and hrp then
        State.Cosmetics.Wings.Parent = CONFIG.WingsEnabled and Workspace or nil
        if CONFIG.WingsEnabled then
            local parts = State.Cosmetics.Wings:GetChildren()
            local idx = 1
            for _, side in ipairs({-1, 1}) do
                for i = 1, 8 do
                    local p = parts[idx]
                    idx += 1
                    if p then
                        local spread = i / 8
                        local offset = hrp.CFrame * CFrame.new(
                            side * (0.5 + spread * 3.5),
                            1 + spread * 3,
                            -0.5 - spread * 1
                        )
                        p.CFrame = offset
                        p.Size = Vector3.new(0.25, 0.25, 0.25)
                        p.Color = Color3.fromHSV((t * 0.3 + i * 0.1) % 1, 0.8, 1)
                        local light = p:FindFirstChildOfClass("PointLight")
                        if not light then
                            light = Instance.new("PointLight", p)
                            light.Range = 4
                            light.Brightness = 2
                        end
                        light.Color = p.Color
                    end
                end
            end
        end
    end

    -- Aura
    if State.Cosmetics.Aura and hrp then
        State.Cosmetics.Aura.Parent = CONFIG.AuraEnabled and Workspace or nil
        if CONFIG.AuraEnabled then
            if #State.Cosmetics.Aura:GetChildren() == 0 then
                local att = Instance.new("Attachment", hrp)
                att.Name = "AuraAtt"
                local pe = Instance.new("ParticleEmitter", att)
                pe.Name = "AuraPE"
                pe.Rate = 30
                pe.Lifetime = NumberRange.new(0.8, 1.6)
                pe.Speed = NumberRange.new(2, 4)
                pe.SpreadAngle = Vector2.new(180, 180)
                pe.Size = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.6),
                    NumberSequenceKeypoint.new(1, 0),
                })
                pe.LightEmission = 1
                pe.LightInfluence = 0
                pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
            end
            for _, pe in ipairs(State.Cosmetics.Aura:GetDescendants()) do
                if pe:IsA("ParticleEmitter") then
                    pe.Color = ColorSequence.new(CONFIG.Accent)
                end
            end
        end
    end

    -- Orbit
    if State.Cosmetics.Orbit and hrp then
        State.Cosmetics.Orbit.Parent = CONFIG.OrbitEnabled and Workspace or nil
        if CONFIG.OrbitEnabled then
            for i, ring in ipairs(State.Cosmetics.Orbit:GetChildren()) do
                local angle = t * (1 + i * 0.3) + i * (math.pi * 2 / 3)
                local radius = 4 + math.sin(t * 2 + i) * 1
                ring.CFrame = hrp.CFrame * CFrame.new(
                    math.cos(angle) * radius,
                    math.sin(t * 1.5 + i) * 1.5,
                    math.sin(angle) * radius
                ) * CFrame.Angles(0, 0, math.rad(90))
                ring.Color = Color3.fromHSV((t * 0.2 + i * 0.3) % 1, 0.8, 1)
                ring.Transparency = 0.3 + math.sin(t * 3 + i) * 0.2
            end
        end
    end

    -- Ground Circle
    if State.Cosmetics.GroundCircle and hrp then
        State.Cosmetics.GroundCircle.Parent = CONFIG.GroundCircle and Workspace or nil
        if CONFIG.GroundCircle then
            State.Cosmetics.GroundCircle.CFrame = CFrame.new(hrp.Position - Vector3.new(0, hrp.Size.Y / 2 + 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
            State.Cosmetics.GroundCircle.Color = CONFIG.Accent
            State.Cosmetics.GroundCircle.Transparency = 0.5 + math.sin(t * 3) * 0.1
        end
    end
end

-- ============================================================
-- CHAMS
-- ============================================================
local function ApplyChams(character)
    if not character then return end
    if CONFIG.ChamsMaterial == "Highlight" or not CONFIG.ChamsMaterial then
        local hl = character:FindFirstChild("Celestial_Chams") or Instance.new("Highlight", character)
        hl.Name = "Celestial_Chams"
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.FillColor = CONFIG.ChamsRainbow and Color3.fromHSV(tick() % 1, 1, 1) or CONFIG.ChamsColor
        hl.OutlineColor = hl.FillColor
        State.ChamsCache[character] = hl
    end
end

local function RemoveChams(character)
    if character then
        local hl = character:FindFirstChild("Celestial_Chams")
        if hl then hl:Destroy() end
        State.ChamsCache[character] = nil
    end
end

-- ============================================================
-- MOVEMENT
-- ============================================================
local function StopFly()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hrp then
        for _, c in ipairs(hrp:GetChildren()) do
            if c.Name == "Celestial_FlyBV" or c.Name == "Celestial_FlyBG" then
                c:Destroy()
            end
        end
    end
    if hum then hum.PlatformStand = false end
end

local function ForceFling(targetChar)
    if not targetChar then return end
    local hrp = targetChar:FindFirstChild("HumanoidRootPart")
    local hum = targetChar:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    pcall(function()
        hrp:SetNetworkOwner(LocalPlayer)
        hum:ChangeState(Enum.HumanoidStateType.Physics)
        hrp.AssemblyLinearVelocity = Vector3.new(1e5, 1e5, 1e5)
        hrp.AssemblyAngularVelocity = Vector3.new(1e5, 1e5, 1e5)
    end)
end

local function ApplyGhost()
    local char = LocalPlayer.Character
    if not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") then v.Transparency = 1; v.CanCollide = false
        elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1 end
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
        if v:IsA("BasePart") then v.Transparency = 0; v.CanCollide = true
        elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 0 end
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
        hum.NameDisplayDistance = 100
        hum.HealthDisplayDistance = 100
    end
end

-- ============================================================
-- SONGS DATA
-- ============================================================
local SONGS = {
    ["Megalovania"] = {
        {n="E",d=0.1}, {n="D",d=0.1}, {n="C",d=0.1}, {n="D",d=0.1},
        {n="E",d=0.1}, {n="E",d=0.1}, {n="E",d=0.1}, {n="D",d=0.1},
        {n="D",d=0.1}, {n="D",d=0.1}, {n="E",d=0.1}, {n="G",d=0.1},
        {n="G",d=0.1}, {n="E",d=0.2}, {n="D",d=0.1}, {n="C",d=0.1},
        {n="D",d=0.1}, {n="E",d=0.1}, {n="E",d=0.1}, {n="E",d=0.1},
        {n="F",d=0.1}, {n="E",d=0.1}, {n="D",d=0.1}, {n="D",d=0.1},
        {n="E",d=0.1}, {n="D",d=0.1}, {n="C",d=0.2},
    },
    ["Coffin Dance"] = {
        {n="A",d=0.25}, {n="A",d=0.25}, {n="C",d=0.25}, {n="A",d=0.25},
        {n="D",d=0.25}, {n="A",d=0.25}, {n="C",d=0.25}, {n="A",d=0.5},
        {n="F",d=0.25}, {n="F",d=0.25}, {n="G",d=0.25}, {n="F",d=0.25},
        {n="D",d=0.25}, {n="C",d=0.25}, {n="A",d=0.25},
    },
    ["Rush E"] = {
        {n="E",d=0.05}, {n="E",d=0.05}, {n="E",d=0.05}, {n="E",d=0.05},
        {n="E",d=0.05}, {n="E",d=0.05}, {n="E",d=0.05}, {n="E",d=0.05},
        {n="D",d=0.08}, {n="E",d=0.08}, {n="B",d=0.08}, {n="D",d=0.08},
        {n="C",d=0.08}, {n="A",d=0.15}, {n="E",d=0.05}, {n="E",d=0.05},
        {n="E",d=0.05}, {n="E",d=0.05}, {n="G",d=0.1}, {n="A",d=0.1},
    },
    ["Yara Yara"] = {
        {n="E",d=0.22}, {n="G",d=0.22}, {n="A",d=0.22}, {n="C",d=0.35},
        {n="A",d=0.22}, {n="G",d=0.22}, {n="E",d=0.22}, {n="D",d=0.35},
        {n="E",d=0.22}, {n="G",d=0.22}, {n="A",d=0.22}, {n="C",d=0.35},
        {n="D",d=0.22}, {n="C",d=0.22}, {n="A",d=0.5},
    },
    ["Phonk Sigma"] = {
        {n="A",d=0.3}, {n="C",d=0.3}, {n="E",d=0.3}, {n="A",d=0.3},
        {n="G",d=0.3}, {n="E",d=0.3}, {n="C",d=0.3}, {n="A",d=0.5},
        {n="A",d=0.15}, {n="A",d=0.15}, {n="G",d=0.15}, {n="E",d=0.15},
    },
    ["Nokia"] = {
        {n="E",d=0.15}, {n="D",d=0.15}, {n="F",d=0.15}, {n="G",d=0.3},
        {n="E",d=0.15}, {n="D",d=0.15}, {n="F",d=0.15}, {n="G",d=0.3},
        {n="C",d=0.15}, {n="C",d=0.15}, {n="B",d=0.15}, {n="A",d=0.15},
        {n="G",d=0.15}, {n="A",d=0.15}, {n="F",d=0.15}, {n="G",d=0.3},
    },
    ["Among Us"] = {
        {n="C",d=0.2}, {n="D",d=0.15}, {n="E",d=0.15}, {n="F",d=0.3},
        {n="E",d=0.15}, {n="D",d=0.15}, {n="C",d=0.4},
    },
    ["Never Gonna"] = {
        {n="D",d=0.2}, {n="D",d=0.2}, {n="E",d=0.2}, {n="D",d=0.2},
        {n="G",d=0.2}, {n="F",d=0.4}, {n="D",d=0.2}, {n="D",d=0.2},
        {n="E",d=0.2}, {n="D",d=0.2}, {n="A",d=0.2}, {n="G",d=0.4},
    },
    ["Tetris"] = {
        {n="E",d=0.3}, {n="B",d=0.15}, {n="C",d=0.15}, {n="D",d=0.3},
        {n="C",d=0.15}, {n="B",d=0.15}, {n="A",d=0.3}, {n="A",d=0.15},
        {n="C",d=0.15}, {n="E",d=0.3}, {n="D",d=0.15}, {n="C",d=0.15},
        {n="B",d=0.6},
    },
}

local function PlaySong(songName)
    if State.PlayingSong then
        Notify("Already playing a song", 2)
        return
    end
    local notes = SONGS[songName]
    if not notes then return end
    State.PlayingSong = true
    Notify("Playing: " .. songName, 2)

    task.spawn(function()
        for _, note in ipairs(notes) do
            if not State.PlayingSong or not State.Running then break end
            local key = Enum.KeyCode[note.n]
            if key then
                pcall(function()
                    if typeof(keypress) == "function" then
                        keypress(key)
                        task.wait(0.02)
                        keyrelease(key)
                    else
                        VirtualInputManager:SendKeyEvent(true, key, false, game)
                        task.wait(0.02)
                        VirtualInputManager:SendKeyEvent(false, key, false, game)
                    end
                end)
            end
            task.wait(note.d)
        end
        State.PlayingSong = false
        Notify("Finished: " .. songName, 2)
    end)
end

-- ============================================================
-- PREMIUM UI
-- ============================================================
local function BuildUI()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")

    -- Blur
    State.blur = Instance.new("BlurEffect")
    State.blur.Size = 0
    State.blur.Parent = Lighting

    local mainGui = Instance.new("ScreenGui")
    mainGui.Name = "CelestialUI"
    mainGui.ResetOnSpawn = false
    mainGui.IgnoreGuiInset = true
    mainGui.DisplayOrder = 999
    mainGui.Parent = playerGui
    State.mainGui = mainGui

    local scaleUI = Instance.new("UIScale", mainGui)
    scaleUI.Scale = CONFIG.UIScale

    -- Main Frame
    local menu = Create("Frame", {
        Parent = mainGui,
        Size = UDim2.new(0, 640, 0, 460),
        Position = UDim2.new(0.5, -320, 1, 500),
        BackgroundColor3 = CONFIG.Bg,
        BackgroundTransparency = 0.02,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 2,
    }, { Corner(14) })
    State.menuFrame = menu

    local mainStroke = Create("UIStroke", {
        Parent = menu, Thickness = 1.8, Transparency = 0.2,
        Color = CONFIG.Accent,
    })
    applyStrokeGradient(mainStroke)

    -- Header
    local header = Create("Frame", {
        Parent = menu, Size = UDim2.new(1, 0, 0, 62),
        BackgroundTransparency = 1, ZIndex = 3,
    })

    local logo = Create("ImageLabel", {
        Parent = header, Size = UDim2.new(0, 36, 0, 36),
        Position = UDim2.new(0, 20, 0.5, -18),
        BackgroundColor3 = CONFIG.CardBg,
        Image = CELESTIAL_ASSET, ScaleType = Enum.ScaleType.Crop,
        ZIndex = 4,
    }, { Corner(18) })
    local logoStroke = Create("UIStroke", { Parent = logo, Thickness = 1.8, Color = CONFIG.Accent })
    applyStrokeGradient(logoStroke)

    local title = Create("TextLabel", {
        Parent = header, Size = UDim2.new(0, 200, 0, 22),
        Position = UDim2.new(0, 66, 0, 12),
        BackgroundTransparency = 1,
        Text = "Celestial",
        Font = Enum.Font.GothamBlack, TextSize = 18,
        TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4,
    })
    RegisterFont(title)

    local subtitle = Create("TextLabel", {
        Parent = header, Size = UDim2.new(0, 260, 0, 16),
        Position = UDim2.new(0, 66, 0, 34),
        BackgroundTransparency = 1,
        Text = "v" .. VERSION .. " | Premium",
        Font = Enum.Font.Gotham, TextSize = 11,
        TextColor3 = CONFIG.Accent, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4,
    })
    RegisterFont(subtitle)
    RegisterTheme(subtitle)

    local closeBtn = Create("TextButton", {
        Parent = header, Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(1, -46, 0.5, -16),
        BackgroundColor3 = Color3.fromRGB(35, 35, 45),
        Text = "×", Font = Enum.Font.GothamBold, TextSize = 22,
        TextColor3 = CONFIG.TextDark, BorderSizePixel = 0,
        AutoButtonColor = false, ZIndex = 4,
    }, { Corner(10) })
    closeBtn.MouseEnter:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(200, 60, 70),
            TextColor3 = Color3.new(1, 1, 1),
        }):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(35, 35, 45),
            TextColor3 = CONFIG.TextDark,
        }):Play()
    end)
    closeBtn.MouseButton1Click:Connect(function()
        TweenService:Create(menu, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, -320, 1, 500),
        }):Play()
        TweenService:Create(State.blur, TweenInfo.new(0.3), { Size = 0 }):Play()
        task.wait(0.3)
        menu.Visible = false
    end)

    -- Separator
    Create("Frame", {
        Parent = menu, Size = UDim2.new(1, -40, 0, 1),
        Position = UDim2.new(0, 20, 0, 62),
        BackgroundColor3 = Color3.fromRGB(35, 35, 45),
        BorderSizePixel = 0, ZIndex = 3,
    })

    -- Search
    local searchFrame = Create("Frame", {
        Parent = menu, Size = UDim2.new(1, -40, 0, 32),
        Position = UDim2.new(0, 20, 0, 72),
        BackgroundColor3 = CONFIG.CardBg, BackgroundTransparency = 0.3,
        BorderSizePixel = 0, ZIndex = 3,
    }, { Corner(8) })
    local searchStroke = Create("UIStroke", { Parent = searchFrame, Thickness = 1, Color = CONFIG.Accent, Transparency = 0.7 })

    Create("TextLabel", {
        Parent = searchFrame, Size = UDim2.new(0, 28, 1, 0),
        Position = UDim2.new(0, 6, 0, 0), BackgroundTransparency = 1,
        Text = "🔍", Font = Enum.Font.Gotham, TextSize = 14,
        TextColor3 = CONFIG.TextDark, ZIndex = 4,
    })
    local searchBox = Create("TextBox", {
        Parent = searchFrame, Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 32, 0, 0), BackgroundTransparency = 1,
        Text = "", PlaceholderText = "Search functions...",
        Font = Enum.Font.Gotham, TextSize = 12,
        TextColor3 = CONFIG.Text, PlaceholderColor3 = CONFIG.TextDark,
        ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4,
    })
    RegisterFont(searchBox)

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local query = searchBox.Text:lower()
        if query == "" then
            for _, w in ipairs(State.SearchWidgets) do
                if w.row and w.row.Parent then w.row.Visible = true end
            end
            return
        end
        for _, w in ipairs(State.SearchWidgets) do
            if w.row and w.row.Parent then
                w.row.Visible = w.text:find(query, 1, true) ~= nil
            end
        end
    end)

    -- Sidebar
    local sidebar = Create("Frame", {
        Parent = menu, Size = UDim2.new(0, 160, 1, -130),
        Position = UDim2.new(0, 20, 0, 116),
        BackgroundTransparency = 1, ZIndex = 3,
    })
    local sidebarPad = Create("UIPadding", { Parent = sidebar, PaddingTop = UDim.new(0, 4) })
    local sidebarLayout = Create("UIListLayout", {
        Parent = sidebar, Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    -- Content
    local content = Create("Frame", {
        Parent = menu, Size = UDim2.new(1, -200, 1, -130),
        Position = UDim2.new(0, 180, 0, 116),
        BackgroundTransparency = 1, ZIndex = 3,
    })

    local Pages = {}
    local Tabs = {}

    local function CreateTab(name, icon, order)
        local btn = Create("TextButton", {
            Parent = sidebar, Size = UDim2.new(1, 0, 0, 38),
            BackgroundColor3 = Color3.fromRGB(24, 24, 32),
            BackgroundTransparency = 0.4,
            Text = "  " .. icon .. "   " .. name,
            Font = Enum.Font.GothamMedium, TextSize = 12,
            TextColor3 = CONFIG.TextDark, TextXAlignment = Enum.TextXAlignment.Left,
            BorderSizePixel = 0, LayoutOrder = order,
            AutoButtonColor = false, ZIndex = 4,
        }, { Corner(8) })
        Create("UIPadding", { Parent = btn, PaddingLeft = UDim.new(0, 12) })
        RegisterFont(btn)

        local tabStroke = Create("UIStroke", {
            Parent = btn, Color = CONFIG.Accent, Thickness = 1.5, Transparency = 1,
        })

        local page = Create("ScrollingFrame", {
            Parent = content, Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1, Visible = false,
            ScrollBarThickness = 2, ScrollBarImageColor3 = CONFIG.Accent,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            BorderSizePixel = 0, ZIndex = 3,
        })
        local pagePad = Create("UIPadding", {
            Parent = page,
            PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
        })
        local pageLayout = Create("UIListLayout", {
            Parent = page, Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        Pages[name] = page
        Tabs[name] = { btn = btn, stroke = tabStroke }

        btn.MouseButton1Click:Connect(function()
            for n, p in pairs(Pages) do p.Visible = (n == name) end
            for _, b in ipairs(sidebar:GetChildren()) do
                if b:IsA("TextButton") then
                    TweenService:Create(b, TweenInfo.new(0.2), {
                        TextColor3 = CONFIG.TextDark, BackgroundTransparency = 0.4,
                    }):Play()
                    local s = b:FindFirstChildOfClass("UIStroke")
                    if s then TweenService:Create(s, TweenInfo.new(0.2), { Transparency = 1 }):Play() end
                end
            end
            TweenService:Create(btn, TweenInfo.new(0.2), {
                TextColor3 = CONFIG.Accent, BackgroundTransparency = 0.15,
            }):Play()
            TweenService:Create(tabStroke, TweenInfo.new(0.2), { Transparency = 0.4 }):Play()
        end)

        return page
    end

    -- Widgets
    local function CreateCard(parent, title)
        local card = Create("Frame", {
            Parent = parent, Size = UDim2.new(1, -8, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = CONFIG.CardBg,
            BackgroundTransparency = 0.15,
            BorderSizePixel = 0, ZIndex = 4,
        }, { Corner(10) })
        local cardStroke = Create("UIStroke", {
            Parent = card, Color = Color3.fromRGB(50, 50, 65),
            Thickness = 1, Transparency = 0.4,
        })
        local cardPad = Create("UIPadding", {
            Parent = card, PaddingTop = UDim.new(0, 12),
            PaddingBottom = UDim.new(0, 12),
            PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
        })
        local cardLayout = Create("UIListLayout", {
            Parent = card, Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        if title then
            local header = Create("TextLabel", {
                Parent = card, Size = UDim2.new(1, 0, 0, 16),
                BackgroundTransparency = 1,
                Text = title:upper(),
                Font = Enum.Font.GothamBold, TextSize = 10,
                TextColor3 = CONFIG.Accent, TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 5,
            })
            RegisterFont(header)
            RegisterTheme(header)
        end
        return card
    end

    local function CreateToggle(parent, text, default, cb, order)
        local row = Create("Frame", {
            Parent = parent, Size = UDim2.new(1, 0, 0, 30),
            BackgroundTransparency = 1, LayoutOrder = order or 1,
        })
        local lbl = Create("TextLabel", {
            Parent = row, Size = UDim2.new(1, -50, 1, 0),
            BackgroundTransparency = 1,
            Text = text, Font = Enum.Font.Gotham, TextSize = 13,
            TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 5,
        })
        RegisterFont(lbl)

        local sw = Create("Frame", {
            Parent = row, Size = UDim2.new(0, 36, 0, 18),
            Position = UDim2.new(1, -36, 0.5, -9),
            BackgroundColor3 = default and CONFIG.Accent or Color3.fromRGB(40, 40, 50),
            BorderSizePixel = 0, ZIndex = 5,
        }, { Corner(10) })
        local kn = Create("Frame", {
            Parent = sw, Size = UDim2.new(0, 14, 0, 14),
            Position = default and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0, ZIndex = 6,
        }, { Corner(7) })

        local state = default
        local click = Create("TextButton", {
            Parent = row, Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1, Text = "", ZIndex = 7,
        })
        click.MouseButton1Click:Connect(function()
            state = not state
            TweenService:Create(sw, TweenInfo.new(0.2), {
                BackgroundColor3 = state and CONFIG.Accent or Color3.fromRGB(40, 40, 50),
            }):Play()
            TweenService:Create(kn, TweenInfo.new(0.2), {
                Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
            }):Play()
            cb(state)
        end)

        RegisterSearch({ row = row, text = text:lower() })
    end

    local function CreateSlider(parent, text, min, max, default, suffix, cb, order)
        local row = Create("Frame", {
            Parent = parent, Size = UDim2.new(1, 0, 0, 46),
            BackgroundTransparency = 1, LayoutOrder = order or 1,
        })
        local lbl = Create("TextLabel", {
            Parent = row, Size = UDim2.new(1, -60, 0, 20),
            BackgroundTransparency = 1,
            Text = text, Font = Enum.Font.Gotham, TextSize = 13,
            TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 5,
        })
        RegisterFont(lbl)

        local val = Create("TextLabel", {
            Parent = row, Size = UDim2.new(0, 60, 0, 20),
            Position = UDim2.new(1, -60, 0, 0),
            BackgroundTransparency = 1,
            Text = tostring(default) .. (suffix or ""),
            Font = Enum.Font.GothamBold, TextSize = 13,
            TextColor3 = CONFIG.Accent, TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex = 5,
        })
        RegisterFont(val)

        local track = Create("Frame", {
            Parent = row, Size = UDim2.new(1, 0, 0, 4),
            Position = UDim2.new(0, 0, 1, -12),
            BackgroundColor3 = Color3.fromRGB(30, 30, 40),
            BorderSizePixel = 0, ZIndex = 5,
        }, { Corner(2) })
        local fill = Create("Frame", {
            Parent = track,
            Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
            BackgroundColor3 = CONFIG.Accent,
            BorderSizePixel = 0, ZIndex = 6,
        }, { Corner(2) })
        local grad = Instance.new("UIGradient", fill)
        grad.Color = ColorSequence.new(CONFIG.Accent, CONFIG.Accent2)
        RegisterTheme(fill)

        local knob = Create("Frame", {
            Parent = track, Size = UDim2.new(0, 12, 0, 12),
            Position = UDim2.new((default - min) / (max - min), -6, 0.5, -6),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0, ZIndex = 7,
        }, { Corner(6) })

        local hit = Create("TextButton", {
            Parent = row, Size = UDim2.new(1, 0, 0, 20),
            Position = UDim2.new(0, 0, 1, -18),
            BackgroundTransparency = 1, Text = "", ZIndex = 8,
        })

        local drag = false
        local function update(x)
            local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local v = math.floor(min + (max - min) * rel)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            knob.Position = UDim2.new(rel, -6, 0.5, -6)
            val.Text = tostring(v) .. (suffix or "")
            cb(v)
        end

        hit.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                drag = true
                update(input.Position.X)
            end
        end)
        Track(UserInputService.InputChanged:Connect(function(input)
            if drag and input.UserInputType == Enum.UserInputType.MouseMovement then
                update(input.Position.X)
            end
        end))
        Track(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
        end))

        RegisterSearch({ row = row, text = text:lower() })
    end

    local function CreateDropdown(parent, text, options, default, cb, order)
        local row = Create("Frame", {
            Parent = parent, Size = UDim2.new(1, 0, 0, 30),
            BackgroundTransparency = 1, LayoutOrder = order or 1,
        })
        local lbl = Create("TextLabel", {
            Parent = row, Size = UDim2.new(0.5, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = text, Font = Enum.Font.Gotham, TextSize = 13,
            TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 5,
        })
        RegisterFont(lbl)

        local btn = Create("TextButton", {
            Parent = row, Size = UDim2.new(0, 100, 0, 24),
            Position = UDim2.new(1, -100, 0.5, -12),
            BackgroundColor3 = Color3.fromRGB(30, 30, 40),
            Text = tostring(default),
            Font = Enum.Font.Gotham, TextSize = 11,
            TextColor3 = CONFIG.Accent,
            BorderSizePixel = 0, ZIndex = 5,
            AutoButtonColor = false,
        }, { Corner(6) })
        RegisterFont(btn)

        local idx = 1
        for i, v in ipairs(options) do
            if v == default or tostring(v) == tostring(default) then idx = i end
        end

        btn.MouseButton1Click:Connect(function()
            idx = idx % #options + 1
            btn.Text = tostring(options[idx])
            cb(options[idx])
        end)

        RegisterSearch({ row = row, text = text:lower() })
    end

    local function CreateButton(parent, text, callback, order)
        local btn = Create("TextButton", {
            Parent = parent, Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = Color3.fromRGB(30, 30, 40),
            Text = text, Font = Enum.Font.GothamBold, TextSize = 12,
            TextColor3 = CONFIG.Text, BorderSizePixel = 0,
            AutoButtonColor = false, LayoutOrder = order or 1, ZIndex = 5,
        }, { Corner(6) })
        RegisterFont(btn)

        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = CONFIG.Accent, TextColor3 = Color3.new(0, 0, 0),
            }):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = Color3.fromRGB(30, 30, 40), TextColor3 = CONFIG.Text,
            }):Play()
        end)
        btn.MouseButton1Click:Connect(callback)
        RegisterSearch({ row = btn, text = text:lower() })
    end

    -- ============================================================
    -- TABS
    -- ============================================================
    local HomeTab     = CreateTab("Home",     "🏠", 1)
    local CombatTab   = CreateTab("Combat",   "⚔️", 2)
    local VisualsTab  = CreateTab("Visuals",  "👁️", 3)
    local CosmeticsTab = CreateTab("Cosmetics", "✨", 4)
    local MovementTab = CreateTab("Movement", "🏃", 5)
    local TrollTab    = CreateTab("Troll",    "😈", 6)
    local MusicTab    = CreateTab("Music",    "🎵", 7)
    local SettingsTab = CreateTab("Settings", "⚙️", 8)

    -- ============================================================
    -- HOME
    -- ============================================================
    local profileCard = CreateCard(HomeTab, "Player Profile")
    Create("TextLabel", {
        Parent = profileCard, Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = "User: " .. LocalPlayer.Name,
        Font = Enum.Font.Gotham, TextSize = 13,
        TextColor3 = CONFIG.Text, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
    })
    Create("TextLabel", {
        Parent = profileCard, Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = "User ID: " .. LocalPlayer.UserId,
        Font = Enum.Font.Gotham, TextSize = 12,
        TextColor3 = CONFIG.TextDark, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
    })

    local aboutCard = CreateCard(HomeTab, "About")
    Create("TextLabel", {
        Parent = aboutCard, Size = UDim2.new(1, 0, 0, 80),
        BackgroundTransparency = 1,
        Text = "Celestial Ultimate — full-featured cheat hub.\nKeybind list on left, search on top.\nPress RShift to toggle menu.",
        Font = Enum.Font.Gotham, TextSize = 12,
        TextColor3 = CONFIG.TextDark, TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 5,
    })

    -- ============================================================
    -- COMBAT
    -- ============================================================
    local aimCard = CreateCard(CombatTab, "Aimbot")
    CreateToggle(aimCard, "Enable Aimbot (RMB / " .. Keybinds.AimbotKey.Name .. ")", CONFIG.AimbotEnabled, function(v) CONFIG.AimbotEnabled = v end, 1)
    CreateSlider(aimCard, "FOV Radius", 20, 600, CONFIG.AimbotFOV, "px", function(v) CONFIG.AimbotFOV = v; FOVCircle.Radius = v end, 2)
    CreateSlider(aimCard, "Smoothness", 5, 100, math.floor(CONFIG.AimbotSmooth * 100), "%", function(v) CONFIG.AimbotSmooth = v / 100 end, 3)
    CreateSlider(aimCard, "Prediction", 0, 50, math.floor(CONFIG.AimbotPredict * 100), "ms", function(v) CONFIG.AimbotPredict = v / 100 end, 4)
    CreateDropdown(aimCard, "Target Part", {"Head", "Torso", "HumanoidRootPart", "UpperTorso"}, CONFIG.AimbotPart, function(v) CONFIG.AimbotPart = v end, 5)
    CreateToggle(aimCard, "Silent Aim", CONFIG.AimbotSilent, function(v) CONFIG.AimbotSilent = v end, 6)
    CreateToggle(aimCard, "Auto Fire", CONFIG.AimbotAutoFire, function(v) CONFIG.AimbotAutoFire = v end, 7)
    CreateToggle(aimCard, "Visible Check", CONFIG.AimbotVisible, function(v) CONFIG.AimbotVisible = v end, 8)

    local kaCard = CreateCard(CombatTab, "Kill Aura")
    CreateToggle(kaCard, "Enable Kill Aura (" .. Keybinds.KillAura.Name .. ")", CONFIG.KillAuraEnabled, function(v) CONFIG.KillAuraEnabled = v end, 1)
    CreateSlider(kaCard, "Range", 5, 100, CONFIG.KillAuraRange, "s", function(v) CONFIG.KillAuraRange = v end, 2)
    CreateSlider(kaCard, "Delay", 1, 50, math.floor(CONFIG.KillAuraDelay * 100), "ms", function(v) CONFIG.KillAuraDelay = v / 100 end, 3)

    local tbCard = CreateCard(CombatTab, "Triggerbot")
    CreateToggle(tbCard, "Enable Triggerbot (" .. Keybinds.Triggerbot.Name .. ")", CONFIG.TriggerbotEnabled, function(v) CONFIG.TriggerbotEnabled = v end, 1)

    -- ============================================================
    -- VISUALS
    -- ============================================================
    local espCard = CreateCard(VisualsTab, "ESP Master")
    CreateToggle(espCard, "Enable ESP", CONFIG.ESPEnabled, function(v) CONFIG.ESPEnabled = v end, 1)
    CreateToggle(espCard, "Box", CONFIG.ESPBox, function(v) CONFIG.ESPBox = v end, 2)
    CreateToggle(espCard, "Health Bar", CONFIG.ESPHealth, function(v) CONFIG.ESPHealth = v end, 3)
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
    CreateToggle(chamsCard, "Rainbow Flow", CONFIG.ChamsRainbow, function(v) CONFIG.ChamsRainbow = v end, 3)
    CreateDropdown(chamsCard, "Material", {"Highlight", "Neon", "ForceField", "Glass"}, CONFIG.ChamsMaterial, function(v) CONFIG.ChamsMaterial = v end, 4)

    local worldCard = CreateCard(VisualsTab, "World")
    CreateToggle(worldCard, "Fullbright", CONFIG.Fullbright, function(v)
        CONFIG.Fullbright = v
        if v then
            Lighting.Brightness = 3
            Lighting.Ambient = Color3.fromRGB(180, 180, 180)
            Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
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

    -- ============================================================
    -- COSMETICS
    -- ============================================================
    local wingsCard = CreateCard(CosmeticsTab, "Wings")
    CreateToggle(wingsCard, "Enable Wings", CONFIG.WingsEnabled, function(v) CONFIG.WingsEnabled = v end, 1)

    local crownCard = CreateCard(CosmeticsTab, "Crown")
    CreateToggle(crownCard, "Enable Crown", CONFIG.CrownEnabled, function(v) CONFIG.CrownEnabled = v end, 1)

    local haloCard = CreateCard(CosmeticsTab, "Halo")
    CreateToggle(haloCard, "Enable Halo", CONFIG.HaloEnabled, function(v) CONFIG.HaloEnabled = v end, 1)

    local auraCard = CreateCard(CosmeticsTab, "Aura")
    CreateToggle(auraCard, "Enable Aura", CONFIG.AuraEnabled, function(v) CONFIG.AuraEnabled = v end, 1)

    local orbitCard = CreateCard(CosmeticsTab, "Orbit Rings")
    CreateToggle(orbitCard, "Enable Orbit", CONFIG.OrbitEnabled, function(v) CONFIG.OrbitEnabled = v end, 1)

    local gcCard = CreateCard(CosmeticsTab, "Ground Circle")
    CreateToggle(gcCard, "Enable Circle", CONFIG.GroundCircle, function(v) CONFIG.GroundCircle = v end, 1)

    -- ============================================================
    -- MOVEMENT
    -- ============================================================
    local flyCard = CreateCard(MovementTab, "Flight")
    CreateToggle(flyCard, "Fly (Fast)", CONFIG.FlyEnabled, function(v)
        CONFIG.FlyEnabled = v
        if not v then StopFly() end
    end, 1)
    CreateToggle(flyCard, "Legit Fly", CONFIG.LegitFlyEnabled, function(v) CONFIG.LegitFlyEnabled = v end, 2)
    CreateSlider(flyCard, "Fly Speed", 20, 300, CONFIG.FlySpeed, "", function(v) CONFIG.FlySpeed = v end, 3)

    local moveCard = CreateCard(MovementTab, "Movement")
    CreateToggle(moveCard, "Noclip (" .. Keybinds.Noclip.Name .. ")", CONFIG.NoclipEnabled, function(v) CONFIG.NoclipEnabled = v end, 1)
    CreateToggle(moveCard, "Speed Hack", CONFIG.SpeedEnabled, function(v) CONFIG.SpeedEnabled = v end, 2)
    CreateSlider(moveCard, "WalkSpeed", 16, 200, CONFIG.WalkSpeed, "", function(v) CONFIG.WalkSpeed = v end, 3)
    CreateSlider(moveCard, "JumpPower", 50, 300, CONFIG.JumpPower, "", function(v) CONFIG.JumpPower = v end, 4)
    CreateToggle(moveCard, "Infinite Jump", CONFIG.InfiniteJump, function(v) CONFIG.InfiniteJump = v end, 5)
    CreateToggle(moveCard, "Auto Wallhop", CONFIG.AutoWallhop, function(v) CONFIG.AutoWallhop = v end, 6)
    CreateToggle(moveCard, "Click TP (" .. Keybinds.ClickTP.Name .. ")", CONFIG.ClickTPEnabled, function(v) CONFIG.ClickTPEnabled = v end, 7)
    CreateToggle(moveCard, "Stand (Follow)", CONFIG.StandEnabled, function(v) CONFIG.StandEnabled = v end, 8)

    -- ============================================================
    -- TROLL
    -- ============================================================
    local flingCard = CreateCard(TrollTab, "Fling")
    CreateToggle(flingCard, "Auto Fling (" .. Keybinds.Fling.Name .. ")", CONFIG.FlingEnabled, function(v) CONFIG.FlingEnabled = v end, 1)
    CreateSlider(flingCard, "Fling Range", 5, 100, CONFIG.FlingRange, "s", function(v) CONFIG.FlingRange = v end, 2)
    CreateButton(flingCard, "Fling Everyone", function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                ForceFling(p.Character)
            end
        end
        Notify("Everyone flung!", 2)
    end, 3)

    local invisCard = CreateCard(TrollTab, "Invisible")
    CreateToggle(invisCard, "Ghost Invisible (" .. Keybinds.Invisible.Name .. ")", CONFIG.InvisibleEnabled, function(v)
        CONFIG.InvisibleEnabled = v
        if v then ApplyGhost() else RestoreVis() end
    end, 1)

    local emoteCard = CreateCard(TrollTab, "Troll Emotes")
    local function PlayEmoteNearest(animId, name)
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
        local closest, minD = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local d = (p.Character.HumanoidRootPart.Position - myRoot.Position).Magnitude
                if d < minD then minD = d; closest = p.Character end
            end
        end
        if closest and closest:FindFirstChildOfClass("Humanoid") then
            local hum = closest:FindFirstChildOfClass("Humanoid")
            local animator = hum:FindFirstChildOfClass("Animator") or hum
            pcall(function()
                local anim = Instance.new("Animation")
                anim.AnimationId = "rbxassetid://" .. animId
                animator:LoadAnimation(anim):Play()
            end)
            Notify("Played " .. name .. " on " .. closest.Name, 2)
        else
            Notify("No players found", 2)
        end
    end

    CreateButton(emoteCard, "Bang Nearest", function() PlayEmoteNearest("5269855227", "Bang") end, 1)
    CreateButton(emoteCard, "Dance Nearest", function() PlayEmoteNearest("507771019", "Dance") end, 2)
    CreateButton(emoteCard, "Laugh Nearest", function() PlayEmoteNearest("507770818", "Laugh") end, 3)
    CreateButton(emoteCard, "Point Nearest", function() PlayEmoteNearest("507770677", "Point") end, 4)

    local spamCard = CreateCard(TrollTab, "Chat Spam")
    CreateToggle(spamCard, "Spam Chat", CONFIG.ChatSpamEnabled, function(v) CONFIG.ChatSpamEnabled = v end, 1)
    local spamBox = Create("TextBox", {
        Parent = spamCard, Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Color3.fromRGB(30, 30, 40),
        Text = CONFIG.ChatSpamText, PlaceholderText = "Spam message...",
        Font = Enum.Font.Gotham, TextSize = 12,
        TextColor3 = CONFIG.Text, BorderSizePixel = 0,
        ClearTextOnFocus = false, ZIndex = 5,
    }, { Corner(6) })
    RegisterFont(spamBox)
    spamBox:GetPropertyChangedSignal("Text"):Connect(function()
        CONFIG.ChatSpamText = spamBox.Text
    end)

    -- ============================================================
    -- MUSIC
    -- ============================================================
    local songsCard = CreateCard(MusicTab, "Piano Songs (Auto)")
    local sortedSongs = {}
    for name in pairs(SONGS) do table.insert(sortedSongs, name) end
    table.sort(sortedSongs)
    for i, songName in ipairs(sortedSongs) do
        CreateButton(songsCard, "🎵 " .. songName, function()
            PlaySong(songName)
        end, i)
    end

    local stopCard = CreateCard(MusicTab, "Controls")
    CreateButton(stopCard, "⏹ Stop Playing", function()
        State.PlayingSong = false
        Notify("Stopped playing", 2)
    end, 1)

    local customCard = CreateCard(MusicTab, "Custom Sound (Local)")
    local soundBox = Create("TextBox", {
        Parent = customCard, Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Color3.fromRGB(30, 30, 40),
        Text = "", PlaceholderText = "rbxassetid://...",
        Font = Enum.Font.Gotham, TextSize = 12,
        TextColor3 = CONFIG.Text, BorderSizePixel = 0,
        ClearTextOnFocus = false, ZIndex = 5,
    }, { Corner(6) })
    RegisterFont(soundBox)
    CreateButton(customCard, "▶ Play Sound", function()
        local id = soundBox.Text
        if id ~= "" then
            local s = Instance.new("Sound", LocalPlayer.Character or Workspace)
            s.SoundId = id
            s.Volume = CONFIG.MusicVolume
            s:Play()
            Debris:AddItem(s, 30)
            Notify("Playing: " .. id, 2)
        end
    end, 1)

    CreateButton(customCard, "📦 Give Boombox", function()
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        if backpack then
            local tool = Instance.new("Tool")
            tool.Name = "Celestial Boombox"
            tool.RequiresHandle = true
            tool.CanBeDropped = false
            local handle = Instance.new("Part", tool)
            handle.Name = "Handle"
            handle.Size = Vector3.new(2, 1, 1)
            handle.Material = Enum.Material.Metal
            handle.Color = CONFIG.Accent
            local sound = Instance.new("Sound", handle)
            sound.Name = "Music"
            sound.SoundId = "rbxassetid://1837879082"
            sound.Looped = true
            sound.Volume = 2
            tool.Equipped:Connect(function() sound:Play() end)
            tool.Unequipped:Connect(function() sound:Stop() end)
            tool.Parent = backpack
            Notify("Boombox added to inventory", 2)
        end
    end, 2)

    -- ============================================================
    -- SETTINGS
    -- ============================================================
    local themeCard = CreateCard(SettingsTab, "Accent Colors")
    local paletteFrame = Create("Frame", {
        Parent = themeCard, Size = UDim2.new(1, 0, 0, 90),
        BackgroundTransparency = 1, ZIndex = 4,
    })
    local paletteLayout = Create("UIGridLayout", {
        Parent = paletteFrame,
        CellSize = UDim2.new(0, 32, 0, 32),
        CellPadding = UDim2.new(0, 8, 0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    local COLOR_LIST = {
        {Name = "Purple", Color = Color3.fromRGB(160, 110, 255)},
        {Name = "Pink", Color = Color3.fromRGB(255, 100, 200)},
        {Name = "Blue", Color = Color3.fromRGB(100, 150, 255)},
        {Name = "Cyan", Color = Color3.fromRGB(100, 220, 255)},
        {Name = "Green", Color = Color3.fromRGB(100, 255, 150)},
        {Name = "Lime", Color = Color3.fromRGB(180, 255, 100)},
        {Name = "Yellow", Color = Color3.fromRGB(255, 220, 100)},
        {Name = "Orange", Color = Color3.fromRGB(255, 160, 80)},
        {Name = "Red", Color = Color3.fromRGB(255, 100, 100)},
        {Name = "White", Color = Color3.fromRGB(240, 240, 240)},
        {Name = "Gray", Color = Color3.fromRGB(150, 150, 160)},
        {Name = "Ice", Color = Color3.fromRGB(200, 240, 255)},
        {Name = "Sunset", Color = Color3.fromRGB(255, 150, 100)},
        {Name = "Ocean", Color = Color3.fromRGB(80, 180, 255)},
        {Name = "Forest", Color = Color3.fromRGB(100, 200, 120)},
        {Name = "Rose", Color = Color3.fromRGB(255, 130, 180)},
    }

    for i, c in ipairs(COLOR_LIST) do
        local btn = Create("TextButton", {
            Parent = paletteFrame,
            BackgroundColor3 = c.Color,
            Text = "", BorderSizePixel = 0,
            LayoutOrder = i, ZIndex = 5,
        }, { Corner(16) })
        local s = Create("UIStroke", { Parent = btn, Color = Color3.new(1, 1, 1), Thickness = 1.5, Transparency = 0.4 })
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), { Size = UDim2.new(0, 36, 0, 36) }):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), { Size = UDim2.new(0, 32, 0, 32) }):Play()
        end)
        btn.MouseButton1Click:Connect(function()
            CONFIG.Accent = c.Color
            CONFIG.Accent2 = c.Color:Lerp(Color3.new(1, 1, 1), 0.3)
            CONFIG.Accent3 = c.Color:Lerp(Color3.new(0, 1, 1), 0.3)
            FOVCircle.Color = c.Color
            for _, obj in ipairs(State.ThemeObjects) do
                if obj and obj.Parent then
                    pcall(function()
                        TweenService:Create(obj, TweenInfo.new(0.25), { Color = c.Color }):Play()
                    end)
                    pcall(function()
                        TweenService:Create(obj, TweenInfo.new(0.25), { TextColor3 = c.Color }):Play()
                    end)
                end
            end
            Notify("Theme: " .. c.Name, 1.5)
        end)
    end

    local uiCard = CreateCard(SettingsTab, "Interface")
    CreateSlider(uiCard, "UI Scale", 50, 150, 100, "%", function(v)
        CONFIG.UIScale = v / 100
        if scaleUI then scaleUI.Scale = CONFIG.UIScale end
    end, 1)
    CreateDropdown(uiCard, "Font", {"Gotham", "GothamBold", "GothamBlack", "SourceSans", "Code", "Roboto"}, "Gotham", function(v)
        local font = Enum.Font[v] or Enum.Font.Gotham
        CONFIG.GUIFont = font
        for _, obj in ipairs(State.FontObjects) do
            if obj and obj.Parent then
                pcall(function() obj.Font = font end)
            end
        end
    end, 2)

    local keybindCard = CreateCard(SettingsTab, "Keybind List")
    local KB_LIST = {"ToggleMenu", "Fly", "Noclip", "Fling", "Stand", "Invisible", "ClickTP", "KillAura", "Triggerbot", "Unload"}
    for i, kb in ipairs(KB_LIST) do
        Create("TextLabel", {
            Parent = keybindCard, Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            Text = kb .. "  →  " .. Keybinds[kb].Name,
            Font = Enum.Font.Code, TextSize = 12,
            TextColor3 = CONFIG.TextDark, TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = i, ZIndex = 5,
        })
    end

    local dangerCard = CreateCard(SettingsTab, "Danger Zone")
    CreateButton(dangerCard, "🚨 PANIC (Unload All)", function()
        UNLOAD()
        Notify("PANIC — everything unloaded", 3)
    end, 1)
    CreateButton(dangerCard, "🔄 Reset Character", function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChildOfClass("Humanoid") then
            char:FindFirstChildOfClass("Humanoid").Health = 0
        end
    end, 2)

    -- ============================================================
    -- FLOATING HUD (Watermark + Keybind list)
    -- ============================================================
    local hudGui = Instance.new("ScreenGui")
    hudGui.Name = "CelestialHUD"
    hudGui.ResetOnSpawn = false
    hudGui.IgnoreGuiInset = true
    hudGui.DisplayOrder = 998
    hudGui.Parent = playerGui

    -- Watermark
    local watermark = Create("Frame", {
        Parent = hudGui, Size = UDim2.new(0, 560, 0, 32),
        Position = UDim2.new(0.5, -280, 0, 12),
        BackgroundColor3 = CONFIG.Bg, BackgroundTransparency = 0.2,
        BorderSizePixel = 0, ZIndex = 3,
    }, { Corner(8) })
    local wmStroke = Create("UIStroke", { Parent = watermark, Thickness = 1.2, Transparency = 0.4, Color = CONFIG.Accent })
    applyStrokeGradient(wmStroke)
    RegisterTheme(wmStroke)

    local wmText = Create("TextLabel", {
        Parent = watermark, Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = "Loading...",
        Font = Enum.Font.GothamBold, TextSize = 12,
        TextColor3 = CONFIG.Text, ZIndex = 4,
    })
    RegisterFont(wmText)

    -- Keybind Floating List
    local kbFloat = Create("Frame", {
        Parent = hudGui, Size = UDim2.new(0, 180, 0, 260),
        Position = UDim2.new(0, 20, 0, 100),
        BackgroundColor3 = CONFIG.CardBg, BackgroundTransparency = 0.2,
        BorderSizePixel = 0, ZIndex = 2,
    }, { Corner(8) })
    local kbStroke = Create("UIStroke", { Parent = kbFloat, Thickness = 1.2, Transparency = 0.5, Color = CONFIG.Accent2 })
    applyStrokeGradient(kbStroke)
    RegisterTheme(kbStroke)

    local kbTitle = Create("TextLabel", {
        Parent = kbFloat, Size = UDim2.new(1, 0, 0, 24),
        Position = UDim2.new(0, 12, 0, 8),
        BackgroundTransparency = 1,
        Text = "KEYBINDS",
        Font = Enum.Font.GothamBold, TextSize = 10,
        TextColor3 = CONFIG.Accent, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4,
    })
    RegisterFont(kbTitle)
    RegisterTheme(kbTitle)

    local kbListFrame = Create("Frame", {
        Parent = kbFloat, Size = UDim2.new(1, -16, 1, -40),
        Position = UDim2.new(0, 8, 0, 32),
        BackgroundTransparency = 1, ZIndex = 3,
    })
    Create("UIListLayout", { Parent = kbListFrame, Padding = UDim.new(0, 4) })

    local KB_DISPLAY = {"ToggleMenu", "Fly", "Noclip", "Fling", "KillAura", "Triggerbot", "Unload"}
    for _, kb in ipairs(KB_DISPLAY) do
        local row = Create("Frame", {
            Parent = kbListFrame, Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1, ZIndex = 3,
        })
        Create("TextLabel", {
            Parent = row, Size = UDim2.new(1, -40, 1, 0),
            BackgroundTransparency = 1,
            Text = kb, Font = Enum.Font.Gotham, TextSize = 11,
            TextColor3 = CONFIG.TextDark, TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 4,
        })
        local keyLabel = Create("TextLabel", {
            Parent = row, Size = UDim2.new(0, 36, 0, 16),
            Position = UDim2.new(1, -36, 0.5, -8),
            BackgroundColor3 = Color3.fromRGB(30, 30, 40),
            Text = Keybinds[kb].Name,
            Font = Enum.Font.Code, TextSize = 10,
            TextColor3 = CONFIG.Accent,
            BorderSizePixel = 0, ZIndex = 4,
        }, { Corner(4) })
    end

    -- ============================================================
    -- DRAGGING
    -- ============================================================
    local dragging, dragStart, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = menu.Position
        end
    end)
    Track(UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            menu.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end))
    Track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))

    -- ============================================================
    -- INITIAL SHOW ANIMATION
    -- ============================================================
    Pages["Home"].Visible = true
    TweenService:Create(TABs and Tabs["Home"].btn or Tabs["Home"].btn, TweenInfo.new(0.2), {
        TextColor3 = CONFIG.Accent, BackgroundTransparency = 0.15,
    }):Play()
    TweenService:Create(Tabs["Home"].stroke, TweenInfo.new(0.2), { Transparency = 0.4 }):Play()

    menu.Visible = true
    TweenService:Create(menu, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -320, 0.5, -230),
    }):Play()
    TweenService:Create(State.blur, TweenInfo.new(0.5), { Size = 18 }):Play()

    -- Watermark update loop
    local fpsCount, fpsAccum = 0, 0
    Track(RunService.Heartbeat:Connect(function(dt)
        if not State.Running then return end
        fpsCount += 1
        fpsAccum += dt
        if fpsAccum >= 1 then
            local ping = "N/A"
            pcall(function()
                ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
            end)
            local time = os.date("!%H:%M:%S", os.time() + (4 * 3600))
            wmText.Text = string.format(
                "✦ CELESTIAL v%s  |  %s  |  %d FPS  |  %s  |  %s (Samara)",
                VERSION, LocalPlayer.Name, fpsCount, ping, time
            )
            fpsCount = 0
            fpsAccum = 0
        end
    end))
end

-- ============================================================
-- COMBAT LOGIC
-- ============================================================
local function GetAimbotPart(char)
    if not char then return nil end
    if CONFIG.AimbotPart == "Head" then return char:FindFirstChild("Head") end
    if CONFIG.AimbotPart == "Torso" then return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") end
    if CONFIG.AimbotPart == "UpperTorso" then return char:FindFirstChild("UpperTorso") end
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
                local part = GetAimbotPart(p.Character)
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
                                    if ray and not ray.Instance:IsDescendantOf(p.Character) then
                                        continue
                                    end
                                end
                            end
                            bestD = d
                            best = part
                        end
                    end
                end
            end
        end
    end
    return best
end

-- ============================================================
-- SILENT AIM HOOK
-- ============================================================
if typeof(hookmetamethod) == "function" then
    local inSilent = false
    local oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        if not State.Running then return oldNamecall(self, ...) end
        local method = getnamecallmethod()
        if CONFIG.AimbotSilent and not inSilent and method == "Raycast" and self == Workspace then
            local origin, direction, params = ...
            if typeof(origin) == "Vector3" and typeof(direction) == "Vector3" then
                local myChar = LocalPlayer.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if myRoot and (origin - myRoot.Position).Magnitude < 25 then
                    local target = GetBestTarget()
                    if target then
                        inSilent = true
                        local newDir = (target.Position - origin).Unit * direction.Magnitude
                        local result = oldNamecall(self, origin, newDir, params)
                        inSilent = false
                        return result
                    end
                end
            end
        end
        return oldNamecall(self, ...)
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

    -- Speed / Jump
    if CONFIG.SpeedEnabled then hum.WalkSpeed = CONFIG.WalkSpeed else hum.WalkSpeed = 16 end
    hum.JumpPower = CONFIG.JumpPower
    hum.UseJumpPower = true

    -- Noclip
    if CONFIG.NoclipEnabled then
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end

    -- Invisible
    if CONFIG.InvisibleEnabled then ApplyGhost() end

    -- Infinite Jump
    if CONFIG.InfiniteJump and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end

    -- Auto Wallhop (FIXED)
    if CONFIG.AutoWallhop and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        if tick() - State.WallhopCooldown > 0.1 then
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

    -- Fly
    if CONFIG.FlyEnabled then
        local bv = hrp:FindFirstChild("Celestial_FlyBV")
        local bg = hrp:FindFirstChild("Celestial_FlyBG")
        local cam = Workspace.CurrentCamera
        if not bv or not bg then
            StopFly()
            local newBv = Instance.new("BodyVelocity", hrp)
            newBv.Name = "Celestial_FlyBV"
            newBv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            newBv.P = 2000
            local newBg = Instance.new("BodyGyro", hrp)
            newBg.Name = "Celestial_FlyBG"
            newBg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
            newBg.P = 3000
            hum.PlatformStand = true
        else
            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0, 1, 0) end
            local vel = move.Magnitude > 0 and move.Unit * CONFIG.FlySpeed or Vector3.zero
            bv.Velocity = bv.Velocity:Lerp(vel, math.min(dt * 10, 1))
            bg.CFrame = cam.CFrame
        end
    end

    -- Kill Aura
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

    -- Triggerbot
    if CONFIG.TriggerbotEnabled and tick() - State.TriggerbotCooldown > 0.1 then
        local target = GetBestTarget()
        if target then
            State.TriggerbotCooldown = tick()
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then pcall(function() tool:Activate() end) end
        end
    end

    -- Auto Fling
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

    -- Stand
    if CONFIG.StandEnabled and State.StandTarget and State.StandTarget.Parent then
        local tHrp = State.StandTarget:FindFirstChild("HumanoidRootPart")
        if tHrp then
            hrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, -3)
        end
    end

    -- Chat Spam
    if CONFIG.ChatSpamEnabled and tick() - State.ChatSpamCooldown > 2 then
        State.ChatSpamCooldown = tick()
        pcall(function()
            local chatEvent = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
            if chatEvent then
                local sayMessageRequest = chatEvent:FindFirstChild("SayMessageRequest")
                if sayMessageRequest then
                    sayMessageRequest:FireServer(CONFIG.ChatSpamText, "All")
                end
            end
        end)
    end
end))

-- Click TP
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

-- ============================================================
-- RENDER LOOP (Aimbot + Cosmetics + FOV)
-- ============================================================
local frameTick = 0
Track(RunService.RenderStepped:Connect(function()
    if not State.Running then return end
    frameTick += 1
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local m = UserInputService:GetMouseLocation()

    -- FOV Circle
    FOVCircle.Position = m
    FOVCircle.Radius = CONFIG.AimbotFOV
    FOVCircle.Visible = CONFIG.AimbotEnabled and (UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or UserInputService:IsKeyDown(CONFIG.AimbotKey))

    -- Aimbot
    if CONFIG.AimbotEnabled then
        local active = UserInputService:IsKeyDown(CONFIG.AimbotKey) or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        if active then
            local target = GetBestTarget()
            if target then
                local sp = cam:WorldToViewportPoint(target.Position)
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

    -- Cosmetics update every 3 frames
    if frameTick % 3 == 0 then
        UpdateCosmetics()
        if CONFIG.ChamsSelf then
            ApplyChams(LocalPlayer.Character)
        else
            RemoveChams(LocalPlayer.Character)
        end
    end
end))

-- ============================================================
-- ESP LOOP
-- ============================================================
local espTick = 0
Track(RunService.Heartbeat:Connect(function()
    if not State.Running then return end
    espTick += 1
    if espTick % 2 ~= 0 then return end

    if not CONFIG.ESPEnabled then
        for _, t in pairs(State.ESPCache) do
            for _, v in pairs(t) do
                if typeof(v) == "table" then
                    for _, l in pairs(v) do pcall(function() l.Visible = false end) end
                else
                    pcall(function() v.Visible = false end)
                end
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

            if hum and hum.Health > 0 and hrp and head and char.Parent == Workspace then
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
                        for i = 1, 6 do
                            t.skel[i] = TrackD(Draw("Line"))
                        end
                        State.ESPCache[p] = t
                    end

                    local hSp, hOn = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                    local rSp, rOn = cam:WorldToViewportPoint(hrp.Position)

                    if hOn and rOn then
                        local h = math.abs(rSp.Y - hSp.Y)
                        local w = h * 0.55
                        local bx = hSp.X - w / 2
                        local by = hSp.Y

                        -- Box
                        t.box.Visible = CONFIG.ESPBox
                        t.box.Position = Vector2.new(bx, by)
                        t.box.Size = Vector2.new(w, h)
                        t.box.Color = CONFIG.Accent
                        t.box.Thickness = 1
                        t.box.Filled = false

                        -- HP Bar
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

                        -- Name
                        if CONFIG.ESPName then
                            t.name.Visible = true
                            t.name.Text = p.Name
                            t.name.Position = Vector2.new(bx + w / 2, by - 16)
                            t.name.Size = 13
                            t.name.Color = CONFIG.Accent
                            t.name.Center = true
                            t.name.Outline = true
                            t.name.Font = CONFIG.ESPFont
                        else
                            t.name.Visible = false
                        end

                        -- Distance
                        if CONFIG.ESPDistance then
                            t.dist.Visible = true
                            t.dist.Text = math.floor(dist) .. "m"
                            t.dist.Position = Vector2.new(bx + w / 2, by + h + 2)
                            t.dist.Size = 11
                            t.dist.Color = Color3.fromRGB(200, 200, 210)
                            t.dist.Center = true
                            t.dist.Outline = true
                            t.dist.Font = CONFIG.ESPFont
                        else
                            t.dist.Visible = false
                        end

                        -- Tracer
                        if CONFIG.ESPTracer then
                            t.tracer.Visible = true
                            t.tracer.From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
                            t.tracer.To = Vector2.new(rSp.X, rSp.Y)
                            t.tracer.Color = CONFIG.Accent
                            t.tracer.Thickness = 1
                        else
                            t.tracer.Visible = false
                        end

                        -- Head Dot
                        if CONFIG.ESPHeadDot then
                            t.headDot.Visible = true
                            t.headDot.Position = Vector2.new(hSp.X, hSp.Y)
                            t.headDot.Radius = 3
                            t.headDot.Color = CONFIG.Accent2
                        else
                            t.headDot.Visible = false
                        end

                        -- Weapon
                        if CONFIG.ESPWeapon then
                            local tool = char:FindFirstChildOfClass("Tool")
                            if tool then
                                t.weapon.Visible = true
                                t.weapon.Text = tool.Name
                                t.weapon.Position = Vector2.new(bx + w / 2, by + h + 16)
                                t.weapon.Size = 10
                                t.weapon.Color = Color3.fromRGB(180, 180, 190)
                                t.weapon.Center = true
                                t.weapon.Outline = true
                                t.weapon.Font = CONFIG.ESPFont
                            else
                                t.weapon.Visible = false
                            end
                        else
                            t.weapon.Visible = false
                        end

                        -- Skeleton
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
                                        line.Color = Color3.fromRGB(255, 255, 255)
                                        line.Thickness = 1
                                    else
                                        line.Visible = false
                                    end
                                else
                                    line.Visible = false
                                end
                            end
                        else
                            for i = 1, 6 do t.skel[i].Visible = false end
                        end

                        -- Chams
                        if CONFIG.ChamsEnemy then ApplyChams(char) else RemoveChams(char) end

                    else
                        for _, v in pairs(t) do
                            if typeof(v) == "table" then
                                for _, l in pairs(v) do pcall(function() l.Visible = false end) end
                            else
                                pcall(function() v.Visible = false end)
                            end
                        end
                    end
                end
            end
        end
    end

    -- Cleanup dead
    for p, t in pairs(State.ESPCache) do
        if not active[p] then
            for _, v in pairs(t) do
                if typeof(v) == "table" then
                    for _, l in pairs(v) do pcall(function() l:Remove() end) end
                else
                    pcall(function() v:Remove() end)
                end
            end
            State.ESPCache[p] = nil
            if p.Character then RemoveChams(p.Character) end
        end
    end
end))

-- ============================================================
-- UNLOAD
-- ============================================================
function UNLOAD()
    if not State.Running then return end
    State.Running = false

    -- Cleanup
    if State.menuFrame then pcall(function() State.menuFrame:Destroy() end) end
    if State.mainGui then pcall(function() State.mainGui:Destroy() end) end
    if State.blur then pcall(function() State.blur:Destroy() end) end

    for _, c in ipairs(State.Connections) do pcall(function() c:Disconnect() end) end
    for _, d in ipairs(State.Drawings) do pcall(function() d:Remove() end) end

    StopFly()
    RestoreVis()

    -- Clean chams
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then RemoveChams(p.Character) end
    end
    for char in pairs(State.ChamsCache) do pcall(function() RemoveChams(char) end) end

    -- Clean cosmetics
    for _, v in pairs(State.Cosmetics) do
        if v and v.Parent then pcall(function() v:Destroy() end) end
    end
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name:find("Celestial") then pcall(function() obj:Destroy() end) end
    end

    -- Restore lighting
    Lighting.Brightness = State.OriginalLighting.Brightness
    Lighting.Ambient = State.OriginalLighting.Ambient
    Lighting.OutdoorAmbient = State.OriginalLighting.OutdoorAmbient
    Lighting.FogEnd = State.OriginalLighting.FogEnd
    Lighting.ClockTime = State.OriginalLighting.ClockTime

    print("[Celestial] Unloaded cleanly.")
    _G.CelestialUnload = nil
end
_G.CelestialUnload = UNLOAD

-- ============================================================
-- HOTKEYS
-- ============================================================
Track(UserInputService.InputBegan:Connect(function(input, gp)
    if gp or UserInputService:GetFocusedTextBox() then return end
    local k = input.KeyCode

    if k == Keybinds.ToggleMenu and State.menuFrame then
        local menu = State.menuFrame
        if menu.Visible then
            TweenService:Create(menu, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, -320, 1, 500),
            }):Play()
            TweenService:Create(State.blur, TweenInfo.new(0.3), { Size = 0 }):Play()
            task.wait(0.3)
            menu.Visible = false
        else
            menu.Visible = true
            TweenService:Create(menu, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = UDim2.new(0.5, -320, 0.5, -230),
            }):Play()
            TweenService:Create(State.blur, TweenInfo.new(0.3), { Size = 18 }):Play()
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
        Notify("Auto Fling: " .. (CONFIG.FlingEnabled and "ON" or "OFF"), 1.5)
    elseif k == Keybinds.Stand then
        CONFIG.StandEnabled = not CONFIG.StandEnabled
        Notify("Stand: " .. (CONFIG.StandEnabled and "ON" or "OFF"), 1.5)
    elseif k == Keybinds.Invisible then
        CONFIG.InvisibleEnabled = not CONFIG.InvisibleEnabled
        if CONFIG.InvisibleEnabled then ApplyGhost() else RestoreVis() end
        Notify("Ghost: " .. (CONFIG.InvisibleEnabled and "ON" or "OFF"), 1.5)
    elseif k == Keybinds.ClickTP then
        CONFIG.ClickTPEnabled = not CONFIG.ClickTPEnabled
        Notify("Click TP: " .. (CONFIG.ClickTPEnabled and "ON" or "OFF"), 1.5)
    elseif k == Keybinds.KillAura then
        CONFIG.KillAuraEnabled = not CONFIG.KillAuraEnabled
        Notify("Kill Aura: " .. (CONFIG.KillAuraEnabled and "ON" or "OFF"), 1.5)
    elseif k == Keybinds.Triggerbot then
        CONFIG.TriggerbotEnabled = not CONFIG.TriggerbotEnabled
        Notify("Triggerbot: " .. (CONFIG.TriggerbotEnabled and "ON" or "OFF"), 1.5)
    elseif k == Keybinds.Panic then
        Notify("PANIC", 2)
        UNLOAD()
    elseif k == Keybinds.Unload then
        UNLOAD()
    end
end))

-- ============================================================
-- CHARACTER RESPAWN HANDLER
-- ============================================================
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

-- ============================================================
-- INIT
-- ============================================================
task.spawn(function()
    pcall(BuildCosmetics)
    pcall(BuildUI)
    print("[Celestial] v" .. VERSION .. " loaded successfully.")
    task.wait(0.5)
    Notify("✦ Celestial v" .. VERSION .. " loaded", 3)
end)
