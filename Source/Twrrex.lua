--[[
    OblivionUI - UI Library estilo anos 2000
    Temas: Cinza Escuro, Windows XP, Black
    Config com AutoSave em tempo real (OblivionUI/Config_OB.json)
    Tecla para abrir/fechar: Left Control
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local CoreGui = game:GetService("CoreGui")
local Debris = game:GetService("Debris")

local OblivionUI = {}

------------------------------------------------------------------
-- IDs DE SOM
------------------------------------------------------------------
local Sounds = {
    NotificationSoundID = 195868961,
    NotificationErrorID = 8426701399,
    SuccessSoundID = 17692186009,
}

------------------------------------------------------------------
-- TEMAS
------------------------------------------------------------------
local Themes = {
    ["Cinza Escuro"] = {
        Window = Color3.fromRGB(58, 58, 58),
        Panel = Color3.fromRGB(44, 44, 44),
        Button = Color3.fromRGB(92, 92, 92),
        Title = Color3.fromRGB(28, 28, 28),
        TitleText = Color3.fromRGB(235, 235, 235),
        Text = Color3.fromRGB(235, 235, 235),
        Border = Color3.fromRGB(16, 16, 16),
        Accent = Color3.fromRGB(170, 170, 170),
    },
    ["Windows XP"] = {
        Window = Color3.fromRGB(236, 233, 216),
        Panel = Color3.fromRGB(255, 255, 255),
        Button = Color3.fromRGB(225, 222, 205),
        Title = Color3.fromRGB(0, 84, 227),
        TitleText = Color3.fromRGB(255, 255, 255),
        Text = Color3.fromRGB(0, 0, 0),
        Border = Color3.fromRGB(0, 60, 116),
        Accent = Color3.fromRGB(49, 106, 197),
    },
    ["Black"] = {
        Window = Color3.fromRGB(18, 18, 18),
        Panel = Color3.fromRGB(10, 10, 10),
        Button = Color3.fromRGB(38, 38, 38),
        Title = Color3.fromRGB(0, 0, 0),
        TitleText = Color3.fromRGB(255, 255, 255),
        Text = Color3.fromRGB(240, 240, 240),
        Border = Color3.fromRGB(70, 70, 70),
        Accent = Color3.fromRGB(210, 210, 210),
    },
}
local ThemeOrder = { "Cinza Escuro", "Windows XP", "Black" }

------------------------------------------------------------------
-- CONFIG (AutoSave em tempo real)
------------------------------------------------------------------
local FOLDER = "OblivionUI"
local FILE = FOLDER .. "/Config_OB.json"

local canFS = (writefile and readfile and isfile and makefolder and isfolder) and true or false

local function defaultConfig()
    return {
        JobID = game.JobId,
        Theme = "Cinza Escuro",
        SoundEnabled = true,
        Flags = {},
    }
end

local Config = defaultConfig()

local function loadConfig()
    if not canFS then return end
    local ok, data = pcall(function()
        if isfile(FILE) then
            return HttpService:JSONDecode(readfile(FILE))
        end
    end)
    if ok and type(data) == "table" then
        Config.Theme = Themes[data.Theme] and data.Theme or Config.Theme
        if type(data.SoundEnabled) == "boolean" then
            Config.SoundEnabled = data.SoundEnabled
        end
        if type(data.Flags) == "table" then
            Config.Flags = data.Flags
        end
    end
end

local saveQueued = false
local function saveConfigNow()
    if not canFS then return end
    pcall(function()
        if not isfolder(FOLDER) then makefolder(FOLDER) end
        Config.JobID = game.JobId
        writefile(FILE, HttpService:JSONEncode(Config))
    end)
end

-- AutoSave: chamado a cada mudança
local function autoSave()
    if saveQueued then return end
    saveQueued = true
    task.delay(0.25, function()
        saveQueued = false
        saveConfigNow()
    end)
end

local function deleteConfig()
    if canFS and isfile(FILE) and delfile then
        pcall(delfile, FILE)
    end
    Config = defaultConfig()
end

------------------------------------------------------------------
-- HELPERS
------------------------------------------------------------------
local Registry = {} -- {obj, prop, key}

local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function theme(obj, prop, key)
    table.insert(Registry, { obj, prop, key })
    local t = Themes[Config.Theme]
    obj[prop] = t[key]
end

local function applyTheme(name)
    if not Themes[name] then return end
    Config.Theme = name
    local t = Themes[name]
    for i = #Registry, 1, -1 do
        local r = Registry[i]
        if r[1] and r[1].Parent then
            r[1][r[2]] = t[r[3]]
        else
            table.remove(Registry, i)
        end
    end
    autoSave()
end

local function playSound(id)
    if not Config.SoundEnabled then return end
    local s = new("Sound", {
        SoundId = "rbxassetid://" .. tostring(id),
        Volume = 1,
    }, SoundService)
    s:Play()
    Debris:AddItem(s, 6)
end

local function getGuiParent()
    local ok, hui = pcall(function() return gethui and gethui() end)
    if ok and hui then return hui end
    local ok2 = pcall(function() return CoreGui.Name end)
    if ok2 then return CoreGui end
    return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local FONT = Enum.Font.Code

local function stroke(obj, thickness)
    local s = new("UIStroke", {
        Thickness = thickness or 2,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, obj)
    theme(s, "Color", "Border")
    return s
end

local function label(parent, text, size)
    local l = new("TextLabel", {
        BackgroundTransparency = 1,
        Text = text,
        Font = FONT,
        TextSize = size or 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, parent)
    theme(l, "TextColor3", "Text")
    return l
end

------------------------------------------------------------------
-- WINDOW
------------------------------------------------------------------
function OblivionUI:CreateWindow(opts)
    opts = opts or {}
    local title = opts.Title or "OblivionUI"

    loadConfig()

    local gui = new("ScreenGui", {
        Name = "OblivionUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
    })
    gui.Parent = getGuiParent()

    local Window = {}
    Window.Gui = gui

    --------------------------------------------------------------
    -- NOTIFICAÇÕES
    --------------------------------------------------------------
    local notifHolder = new("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -14, 1, -14),
        Size = UDim2.fromOffset(260, 400),
        ZIndex = 50,
    }, gui)
    new("UIListLayout", {
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, notifHolder)

    function Window:Notify(ntitle, text, kind, duration)
        kind = kind or "info"
        duration = duration or 4
        playSound(kind == "error" and Sounds.NotificationErrorID or Sounds.NotificationSoundID)

        local box = new("Frame", {
            Size = UDim2.fromOffset(250, 62),
            BorderSizePixel = 0,
            ZIndex = 50,
        }, notifHolder)
        theme(box, "BackgroundColor3", "Window")
        stroke(box, 2)

        local bar = new("Frame", {
            Size = UDim2.new(1, 0, 0, 18),
            BorderSizePixel = 0,
            ZIndex = 51,
        }, box)
        if kind == "error" then
            bar.BackgroundColor3 = Color3.fromRGB(170, 30, 30)
        else
            theme(bar, "BackgroundColor3", "Title")
        end
        local bt = new("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(6, 0),
            Size = UDim2.new(1, -12, 1, 0),
            Text = ntitle or "Aviso",
            Font = FONT,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = Color3.new(1, 1, 1),
            ZIndex = 52,
        }, bar)

        local body = new("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(6, 22),
            Size = UDim2.new(1, -12, 1, -26),
            Text = text or "",
            Font = FONT,
            TextSize = 13,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = 52,
        }, box)
        theme(body, "TextColor3", "Text")

        task.delay(duration, function()
            if box and box.Parent then
                box:Destroy()
            end
        end)
    end

    --------------------------------------------------------------
    -- TELA DE LOADING (estilo Windows)
    --------------------------------------------------------------
    do
        local loading = new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(340, 120),
            BorderSizePixel = 0,
            ZIndex = 100,
        }, gui)
        theme(loading, "BackgroundColor3", "Window")
        stroke(loading, 2)

        local lt = new("Frame", {
            Size = UDim2.new(1, 0, 0, 22),
            BorderSizePixel = 0,
            ZIndex = 101,
        }, loading)
        theme(lt, "BackgroundColor3", "Title")
        local ltt = new("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(8, 0),
            Size = UDim2.new(1, -16, 1, 0),
            Text = title .. " - Loading",
            Font = FONT,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 102,
        }, lt)
        theme(ltt, "TextColor3", "TitleText")

        local status = new("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(14, 36),
            Size = UDim2.new(1, -28, 0, 20),
            Text = "Iniciando...",
            Font = FONT,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 102,
        }, loading)
        theme(status, "TextColor3", "Text")

        local track = new("Frame", {
            Position = UDim2.fromOffset(14, 66),
            Size = UDim2.new(1, -28, 0, 22),
            BorderSizePixel = 0,
            ZIndex = 102,
        }, loading)
        theme(track, "BackgroundColor3", "Panel")
        stroke(track, 2)

        local fill = new("Frame", {
            Position = UDim2.fromOffset(2, 2),
            Size = UDim2.new(0, 0, 1, -4),
            BorderSizePixel = 0,
            ZIndex = 103,
        }, track)
        theme(fill, "BackgroundColor3", "Accent")

        local steps = {
            { "Carregando config...", 0.25 },
            { "Aplicando tema: " .. Config.Theme, 0.5 },
            { "Montando interface...", 0.8 },
            { "Finalizando...", 1 },
        }
        for _, s in ipairs(steps) do
            status.Text = s[1]
            TweenService:Create(fill, TweenInfo.new(0.35, Enum.EasingStyle.Linear),
                { Size = UDim2.new(s[2], -4, 1, -4) }):Play()
            task.wait(0.45)
        end
        status.Text = "Success!"
        playSound(Sounds.SuccessSoundID)
        task.wait(0.6)
        loading:Destroy()
    end

    --------------------------------------------------------------
    -- JANELA PRINCIPAL
    --------------------------------------------------------------
    local main = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(540, 360),
        BorderSizePixel = 0,
        Visible = true,
    }, gui)
    theme(main, "BackgroundColor3", "Window")
    stroke(main, 2)
    Window.Main = main

    local titleBar = new("Frame", {
        Size = UDim2.new(1, 0, 0, 26),
        BorderSizePixel = 0,
    }, main)
    theme(titleBar, "BackgroundColor3", "Title")

    local tt = new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(8, 0),
        Size = UDim2.new(1, -40, 1, 0),
        Text = title,
        Font = FONT,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, titleBar)
    theme(tt, "TextColor3", "TitleText")

    local closeBtn = new("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -4, 0.5, 0),
        Size = UDim2.fromOffset(20, 18),
        Text = "X",
        Font = FONT,
        TextSize = 13,
        AutoButtonColor = false,
        BorderSizePixel = 0,
    }, titleBar)
    theme(closeBtn, "BackgroundColor3", "Button")
    theme(closeBtn, "TextColor3", "Text")
    stroke(closeBtn, 1)
    closeBtn.MouseButton1Click:Connect(function()
        main.Visible = false
    end)

    -- arrastar
    do
        local dragging, startPos, startMouse
        titleBar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                startMouse = i.Position
                startPos = main.Position
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
                or i.UserInputType == Enum.UserInputType.Touch) then
                local d = i.Position - startMouse
                main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                    startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
    end

    -- barra de tabs (esquerda)
    local tabBar = new("ScrollingFrame", {
        Position = UDim2.fromOffset(6, 32),
        Size = UDim2.new(0, 120, 1, -60),
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, main)
    theme(tabBar, "BackgroundColor3", "Panel")
    stroke(tabBar, 2)
    new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, tabBar)
    new("UIPadding", {
        PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4),
    }, tabBar)

    local pages = new("Frame", {
        Position = UDim2.fromOffset(132, 32),
        Size = UDim2.new(1, -138, 1, -60),
        BorderSizePixel = 0,
    }, main)
    theme(pages, "BackgroundColor3", "Panel")
    stroke(pages, 2)

    -- status bar
    local statusBar = new("TextLabel", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 6, 1, -4),
        Size = UDim2.new(1, -12, 0, 18),
        BackgroundTransparency = 1,
        Text = "[LeftCtrl] Abrir/Fechar  |  AutoSave: ON",
        Font = FONT,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, main)
    theme(statusBar, "TextColor3", "Text")

    -- Left Control abre/fecha
    UIS.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.LeftControl then
            main.Visible = not main.Visible
        end
    end)

    --------------------------------------------------------------
    -- TABS
    --------------------------------------------------------------
    local tabs = {}
    local function selectTab(t)
        for _, o in ipairs(tabs) do
            o.Page.Visible = (o == t)
            o.Button.TextTransparency = (o == t) and 0 or 0.45
        end
    end

    function Window:CreateTab(name, order)
        local Tab = {}

        local btn = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 24),
            Text = name,
            Font = FONT,
            TextSize = 14,
            AutoButtonColor = false,
            BorderSizePixel = 0,
            LayoutOrder = order or (#tabs + 1),
        }, tabBar)
        theme(btn, "BackgroundColor3", "Button")
        theme(btn, "TextColor3", "Text")
        stroke(btn, 1)

        local page = new("ScrollingFrame", {
            Size = UDim2.new(1, -8, 1, -8),
            Position = UDim2.fromOffset(4, 4),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 5,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
        }, pages)
        new("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, page)
        new("UIPadding", { PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 2) }, page)

        Tab.Page = page
        Tab.Button = btn
        table.insert(tabs, Tab)
        btn.MouseButton1Click:Connect(function() selectTab(Tab) end)
        if #tabs == 1 then selectTab(Tab) end

        local function row(h)
            local f = new("Frame", {
                Size = UDim2.new(1, 0, 0, h or 28),
                BorderSizePixel = 0,
            }, page)
            theme(f, "BackgroundColor3", "Window")
            stroke(f, 1)
            return f
        end

        local function saved(flag, default)
            local v = Config.Flags[flag]
            if v == nil then return default end
            return v
        end

        function Tab:Label(text)
            local f = row(24)
            local l = label(f, text)
            l.Position = UDim2.fromOffset(8, 0)
            l.Size = UDim2.new(1, -16, 1, 0)
            return l
        end

        function Tab:Button(text, callback)
            local b = new("TextButton", {
                Size = UDim2.new(1, 0, 0, 28),
                Text = text,
                Font = FONT,
                TextSize = 14,
                AutoButtonColor = false,
                BorderSizePixel = 0,
            }, page)
            theme(b, "BackgroundColor3", "Button")
            theme(b, "TextColor3", "Text")
            stroke(b, 2)
            b.MouseButton1Click:Connect(function()
                if callback then task.spawn(callback) end
            end)
            return b
        end

        function Tab:Toggle(text, default, callback, flag)
            flag = flag or text
            local state = saved(flag, default or false)
            local f = row(28)
            local l = label(f, text)
            l.Position = UDim2.fromOffset(8, 0)
            l.Size = UDim2.new(1, -44, 1, 0)

            local box = new("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -6, 0.5, 0),
                Size = UDim2.fromOffset(20, 20),
                Text = "",
                Font = FONT,
                TextSize = 16,
                AutoButtonColor = false,
                BorderSizePixel = 0,
            }, f)
            theme(box, "BackgroundColor3", "Panel")
            theme(box, "TextColor3", "Text")
            stroke(box, 2)

            local obj = {}
            local function set(v, silent)
                state = v
                box.Text = v and "X" or ""
                Config.Flags[flag] = v
                if not silent then autoSave() end
                if callback then task.spawn(callback, v) end
            end
            box.MouseButton1Click:Connect(function() set(not state) end)
            set(state, true)
            function obj:Set(v) set(v) end
            function obj:Get() return state end
            return obj
        end

        function Tab:Slider(text, min, max, default, callback, flag)
            flag = flag or text
            local value = math.clamp(saved(flag, default or min), min, max)
            local f = row(44)
            local l = label(f, text)
            l.Position = UDim2.fromOffset(8, 2)
            l.Size = UDim2.new(1, -60, 0, 18)
            local vl = new("TextLabel", {
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -8, 0, 2),
                Size = UDim2.fromOffset(50, 18),
                Font = FONT,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Right,
            }, f)
            theme(vl, "TextColor3", "Text")

            local track = new("Frame", {
                Position = UDim2.fromOffset(8, 26),
                Size = UDim2.new(1, -16, 0, 10),
                BorderSizePixel = 0,
            }, f)
            theme(track, "BackgroundColor3", "Panel")
            stroke(track, 1)
            local fill = new("Frame", { Size = UDim2.new(0, 0, 1, 0), BorderSizePixel = 0 }, track)
            theme(fill, "BackgroundColor3", "Accent")

            local function set(v, silent)
                value = math.clamp(math.floor(v + 0.5), min, max)
                fill.Size = UDim2.new((value - min) / math.max(max - min, 1), 0, 1, 0)
                vl.Text = tostring(value)
                Config.Flags[flag] = value
                if not silent then autoSave() end
                if callback then task.spawn(callback, value) end
            end
            local dragging = false
            local function fromInput(x)
                local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                set(min + (max - min) * rel)
            end
            track.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                    or i.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    fromInput(i.Position.X)
                end
            end)
            UIS.InputChanged:Connect(function(i)
                if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
                    or i.UserInputType == Enum.UserInputType.Touch) then
                    fromInput(i.Position.X)
                end
            end)
            UIS.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                    or i.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            set(value, true)
            local obj = {}
            function obj:Set(v) set(v) end
            function obj:Get() return value end
            return obj
        end

        function Tab:TextBox(text, default, callback, flag)
            flag = flag or text
            local f = row(28)
            local l = label(f, text)
            l.Position = UDim2.fromOffset(8, 0)
            l.Size = UDim2.new(0.4, 0, 1, 0)
            local tb = new("TextBox", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -6, 0.5, 0),
                Size = UDim2.new(0.55, 0, 0, 20),
                Text = tostring(saved(flag, default or "")),
                PlaceholderText = "...",
                ClearTextOnFocus = false,
                Font = FONT,
                TextSize = 13,
                BorderSizePixel = 0,
            }, f)
            theme(tb, "BackgroundColor3", "Panel")
            theme(tb, "TextColor3", "Text")
            stroke(tb, 1)
            tb.FocusLost:Connect(function()
                Config.Flags[flag] = tb.Text
                autoSave()
                if callback then task.spawn(callback, tb.Text) end
            end)
            Config.Flags[flag] = tb.Text
            if callback then task.spawn(callback, tb.Text) end
            return tb
        end

        -- Selector: fileira de botões (usado pra escolher tema)
        function Tab:Selector(text, options, default, callback, flag)
            flag = flag or text
            local current = saved(flag, default or options[1])
            local f = row(54)
            local l = label(f, text)
            l.Position = UDim2.fromOffset(8, 2)
            l.Size = UDim2.new(1, -16, 0, 18)

            local holder = new("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(6, 24),
                Size = UDim2.new(1, -12, 0, 24),
            }, f)
            new("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 4),
            }, holder)

            local btns = {}
            local function refresh()
                for opt, b in pairs(btns) do
                    b.TextTransparency = (opt == current) and 0 or 0.5
                    b.Text = (opt == current) and ("[" .. opt .. "]") or opt
                end
            end
            for _, opt in ipairs(options) do
                local b = new("TextButton", {
                    Size = UDim2.new(1 / #options, -3, 1, 0),
                    Text = opt,
                    Font = FONT,
                    TextSize = 12,
                    AutoButtonColor = false,
                    BorderSizePixel = 0,
                }, holder)
                theme(b, "BackgroundColor3", "Button")
                theme(b, "TextColor3", "Text")
                stroke(b, 2)
                btns[opt] = b
                b.MouseButton1Click:Connect(function()
                    current = opt
                    Config.Flags[flag] = opt
                    refresh()
                    autoSave()
                    if callback then task.spawn(callback, opt) end
                end)
            end
            refresh()
            if callback then task.spawn(callback, current) end
            return { Get = function() return current end }
        end

        return Tab
    end

    --------------------------------------------------------------
    -- ABA SETTINGS (config)
    --------------------------------------------------------------
    local settings = Window:CreateTab("Settings", 999)

    settings:Label("== Interface ==")
    settings:Selector("Tema da UI", ThemeOrder, Config.Theme, function(name)
        if name ~= Config.Theme then
            applyTheme(name)
        end
    end, "__ThemeSelector")

    settings:Label("== Som ==")
    settings:Toggle("Enable Sound", Config.SoundEnabled, function(v)
        Config.SoundEnabled = v
        autoSave()
    end, "__EnableSound")

    settings:Button("Testar notificacao", function()
        Window:Notify("Notificacao", "Som de notificacao funcionando!", "info")
    end)
    settings:Button("Testar erro", function()
        Window:Notify("Erro", "Som de erro funcionando!", "error")
    end)

    settings:Label("== Config ==")
    settings:Label("JobID: " .. tostring(game.JobId ~= "" and game.JobId or "(Studio)"))
    settings:Label("Arquivo: " .. FILE)

    settings:Button("Save Config", function()
        saveConfigNow()
        Window:Notify("Config", "Config salva em " .. FILE, "info")
    end)

    settings:Button("Excluir Config", function()
        deleteConfig()
        Window:Notify("Config", "Config excluida. Reexecute para recomecar.", "error")
    end)

    settings:Button("Fechar / Destruir UI", function()
        gui:Destroy()
    end)

    -- Se a config foi carregada com outro tema, aplica
    applyTheme(Config.Theme)
    saveConfigNow()

    Window:Notify("OblivionUI", "Carregada! Aperte Left Control para abrir/fechar.", "info")

    function Window:Toggle()
        main.Visible = not main.Visible
    end
    function Window:Destroy()
        gui:Destroy()
    end

    return Window
end

return OblivionUI
