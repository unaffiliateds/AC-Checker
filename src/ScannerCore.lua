--[[
    AC-Checker
    ScannerCore.lua

    Scans all replicated players.
    GUI is displayed only to the local player.

    Tabs:
        LOOP
        JUMP
        MISC
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local ScannerCore = {}
ScannerCore.__index = ScannerCore

--------------------------------------------------
-- CONSTRUCTOR
--------------------------------------------------

function ScannerCore.new(config, modules)

    config = config or {}
    modules = modules or {}

    local self = setmetatable({}, ScannerCore)

    self.Config = {
        Enabled = config.Enabled ~= false,

        BaseSpeed = config.BaseSpeed or 18,
        SprintSpeed = config.SprintSpeed or 21,
        SpeedTolerance = config.SpeedTolerance or 1.25,

        SampleInterval = config.SampleInterval or 0.15,
        RequiredViolations = config.RequiredViolations or 3,
        ViolationWindow = config.ViolationWindow or 1,

        AdminUserIds = config.AdminUserIds or {},
    }

    self.Logs = modules.Logs.new(500)

    self.LoopScanner = modules.LoopScanner.new({
        BaseSpeed = self.Config.BaseSpeed,
        SprintSpeed = self.Config.SprintSpeed,
        Tolerance = self.Config.SpeedTolerance,
        SampleInterval = self.Config.SampleInterval,
        RequiredViolations = self.Config.RequiredViolations,
        ViolationWindow = self.Config.ViolationWindow,

        OnDetection = function(data)
            self:HandleDetection(data)
        end,
    })

    self.JumpScanner = modules.JumpScanner.new({
        OnDetection = function(data)
            self:HandleDetection(data)
        end,
    })

    self.Started = false

    self.Gui = nil
    self.Main = nil
    self.Content = nil
    self.Scale = nil

    self.ActiveTab = "Loop"
    self.GuiSizeMode = "Small"

    return self
end

--------------------------------------------------
-- DETECTIONS
--------------------------------------------------

function ScannerCore:HandleDetection(data)

    local entry = self.Logs:Add(data)

    if entry.Type == "Speed" then
        print(string.format(
            "[AC-Checker] SPEED DETECTION | %s | %.2f studs/s | limit %.2f",
            entry.PlayerName,
            entry.Speed or 0,
            entry.Limit or 0
        ))
    elseif entry.Type == "Jump" then
        print(string.format(
            "[AC-Checker] JUMP DETECTION | %s | %.2f studs | max %.2f",
            entry.PlayerName,
            entry.Height or 0,
            entry.MaxHeight or 0
        ))
    end

    self:RefreshGui()
end

--------------------------------------------------
-- GUI HELPERS
--------------------------------------------------

function ScannerCore:Label(parent, text, size, pos, textSize)

    local label = Instance.new("TextLabel")

    label.Size = size
    label.Position = pos

    label.BackgroundTransparency = 1

    label.Text = text
    label.TextColor3 = Color3.fromRGB(230, 230, 230)

    label.TextSize = textSize or 14
    label.Font = Enum.Font.Gotham

    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center

    label.Parent = parent

    return label
end

function ScannerCore:Button(parent, text, size, pos)

    local button = Instance.new("TextButton")

    button.Size = size
    button.Position = pos

    button.BackgroundColor3 =
        Color3.fromRGB(35, 35, 35)

    button.BorderSizePixel = 0

    button.Text = text
    button.TextColor3 =
        Color3.fromRGB(230, 230, 230)

    button.TextSize = 13
    button.Font = Enum.Font.GothamMedium

    button.AutoButtonColor = true
    button.Active = true

    button.Parent = parent

    return button
end

--------------------------------------------------
-- SIZE
--------------------------------------------------

function ScannerCore:GetScale()

    if self.GuiSizeMode == "Small" then
        return 0.65
    end

    if self.GuiSizeMode == "Large" then
        return 0.95
    end

    return 0.8
end

function ScannerCore:UpdateScale()

    if not self.Scale then
        return
    end

    local camera = workspace.CurrentCamera

    if not camera then
        return
    end

    local viewport = camera.ViewportSize

    local baseWidth = 600
    local baseHeight = 360

    local fitX =
        (viewport.X - 20) /
        baseWidth

    local fitY =
        (viewport.Y - 20) /
        baseHeight

    local fit =
        math.min(
            fitX,
            fitY
        )

    self.Scale.Scale =
        math.min(
            self:GetScale(),
            fit
        )

    self.Scale.Scale =
        math.max(
            self.Scale.Scale,
            0.45
        )
end

--------------------------------------------------
-- DRAGGING
--------------------------------------------------

function ScannerCore:MakeDraggable(frame, handle)

    local dragging = false
    local startInput
    local startPosition

    handle.InputBegan:Connect(function(input)

        if input.UserInputType ==
            Enum.UserInputType.MouseButton1
            or
            input.UserInputType ==
            Enum.UserInputType.Touch then

            dragging = true

            startInput = input.Position
            startPosition = frame.Position

            input.Changed:Connect(function()

                if input.UserInputState ==
                    Enum.UserInputState.End then

                    dragging = false

                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)

        if not dragging then
            return
        end

        if input.UserInputType ~=
            Enum.UserInputType.MouseMovement
            and
            input.UserInputType ~=
            Enum.UserInputType.Touch then

            return
        end

        local delta =
            input.Position -
            startInput

        frame.Position =
            UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,

                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
    end)
end

--------------------------------------------------
-- GUI
--------------------------------------------------

function ScannerCore:CreateGui()

    local playerGui =
        LocalPlayer:WaitForChild(
            "PlayerGui"
        )

    local old =
        playerGui:FindFirstChild(
            "ACCheckerGui"
        )

    if old then
        old:Destroy()
    end

    local gui =
        Instance.new("ScreenGui")

    gui.Name = "ACCheckerGui"

    gui.ResetOnSpawn = false
    gui.Enabled = true

    -- Keep it above normal Roblox interfaces.
    gui.DisplayOrder = 9999

    gui.ZIndexBehavior =
        Enum.ZIndexBehavior.Global

    gui.Parent = playerGui

    self.Gui = gui

    --------------------------------------------------
    -- SCALE
    --------------------------------------------------

    local scale =
        Instance.new("UIScale")

    scale.Scale =
        self:GetScale()

    scale.Parent = gui

    self.Scale = scale

    --------------------------------------------------
    -- MAIN
    --------------------------------------------------

    local main =
        Instance.new("Frame")

    main.Name = "Main"

    main.Size =
        UDim2.fromOffset(
            600,
            360
        )

    main.AnchorPoint =
        Vector2.new(
            0.5,
            0.5
        )

    main.Position =
        UDim2.new(
            0.5,
            0,
            0.5,
            0
        )

    main.BackgroundColor3 =
        Color3.fromRGB(
            16,
            16,
            16
        )

    main.BorderSizePixel = 0

    main.Parent = gui

    self.Main = main

    --------------------------------------------------
    -- TITLE
    --------------------------------------------------

    local titleBar =
        Instance.new("Frame")

    titleBar.Size =
        UDim2.new(
            1,
            0,
            0,
            50
        )

    titleBar.BackgroundColor3 =
        Color3.fromRGB(
            24,
            24,
            24
        )

    titleBar.BorderSizePixel = 0

    titleBar.Parent = main

    local title =
        self:Label(
            titleBar,
            "AC-CHECKER",
            UDim2.new(
                1,
                -120,
                1,
                0
            ),
            UDim2.fromOffset(
                15,
                0
            ),
            18
        )

    title.Font =
        Enum.Font.GothamBold

    local online =
        self:Label(
            titleBar,
            "● ONLINE",
            UDim2.fromOffset(
                100,
                30
            ),
            UDim2.new(
                1,
                -110,
                0.5,
                -15
            ),
            11
        )

    online.TextXAlignment =
        Enum.TextXAlignment.Right

    online.TextColor3 =
        Color3.fromRGB(
            80,
            220,
            120
        )

    self:MakeDraggable(
        main,
        titleBar
    )

    --------------------------------------------------
    -- SIDEBAR
    --------------------------------------------------

    local sidebar =
        Instance.new("Frame")

    sidebar.Size =
        UDim2.new(
            0,
            115,
            1,
            -50
        )

    sidebar.Position =
        UDim2.fromOffset(
            0,
            50
        )

    sidebar.BackgroundColor3 =
        Color3.fromRGB(
            21,
            21,
            21
        )

    sidebar.BorderSizePixel = 0

    sidebar.Parent = main

    self:Label(
        sidebar,
        "SCANNERS",
        UDim2.new(
            1,
            -20,
            0,
            30
        ),
        UDim2.fromOffset(
            10,
            10
        ),
        10
    ).TextColor3 =
        Color3.fromRGB(
            130,
            130,
            130
        )

    local loop =
        self:Button(
            sidebar,
            "LOOP",
            UDim2.new(
                1,
                -16,
                0,
                42
            ),
            UDim2.fromOffset(
                8,
                48
            )
        )

    local jump =
        self:Button(
            sidebar,
            "JUMP",
            UDim2.new(
                1,
                -16,
                0,
                42
            ),
            UDim2.fromOffset(
                8,
                96
            )
        )

    local misc =
        self:Button(
            sidebar,
            "MISC",
            UDim2.new(
                1,
                -16,
                0,
                42
            ),
            UDim2.fromOffset(
                8,
                144
            )
        )

    loop.Activated:Connect(function()

        self.ActiveTab = "Loop"
        self:RefreshGui()

    end)

    jump.Activated:Connect(function()

        self.ActiveTab = "Jump"
        self:RefreshGui()

    end)

    misc.Activated:Connect(function()

        self.ActiveTab = "Misc"
        self:RefreshGui()

    end)

    --------------------------------------------------
    -- CONTENT
    --------------------------------------------------

    local content =
        Instance.new("Frame")

    content.Size =
        UDim2.new(
            1,
            -115,
            1,
            -50
        )

    content.Position =
        UDim2.fromOffset(
            115,
            50
        )

    content.BackgroundTransparency = 1

    content.Parent = main

    self.Content = content

    self:UpdateScale()
    self:RefreshGui()

    print(
        "[AC-Checker] GUI created successfully."
    )
end

--------------------------------------------------
-- DETECTION LIST
--------------------------------------------------

function ScannerCore:AddDetection(
    list,
    entry
)

    local row =
        Instance.new("Frame")

    row.Size =
        UDim2.new(
            1,
            -10,
            0,
            50
        )

    row.BackgroundColor3 =
        Color3.fromRGB(
            28,
            28,
            28
        )

    row.BorderSizePixel = 0

    row.Parent = list

    local name =
        entry.PlayerName or
        "Unknown"

    local detail

    if entry.Type == "Speed" then

        detail =
            string.format(
                "%.2f studs/s | limit %.2f",
                entry.Speed or 0,
                entry.Limit or 0
            )

    elseif entry.Type == "Jump" then

        detail =
            string.format(
                "%.2f studs | max %.2f",
                entry.Height or 0,
                entry.MaxHeight or 0
            )

    else

        detail =
            "Detection"
    end

    local nameLabel =
        self:Label(
            row,
            name,
            UDim2.new(
                1,
                -16,
                0,
                23
            ),
            UDim2.fromOffset(
                8,
                2
            ),
            12
        )

    nameLabel.Font =
        Enum.Font.GothamMedium

    self:Label(
        row,
        detail,
        UDim2.new(
            1,
            -16,
            0,
            20
        ),
        UDim2.fromOffset(
            8,
            26
        ),
        10
    ).TextColor3 =
        Color3.fromRGB(
            145,
            145,
            145
        )
end

--------------------------------------------------
-- LOOP TAB
--------------------------------------------------

function ScannerCore:BuildLoop()

    local content =
        self.Content

    self:Label(
        content,
        "LOOP DETECTION",
        UDim2.new(
            1,
            -20,
            0,
            30
        ),
        UDim2.fromOffset(
            12,
            12
        ),
        17
    ).Font =
        Enum.Font.GothamBold

    self:Label(
        content,
        string.format(
            "● ACTIVE   Normal %.1f   Sprint %.1f",
            self.Config.BaseSpeed,
            self.Config.SprintSpeed
        ),
        UDim2.new(
            1,
            -20,
            0,
            25
        ),
        UDim2.fromOffset(
            12,
            43
        ),
        10
    ).TextColor3 =
        Color3.fromRGB(
            80,
            220,
            120
        )

    local list =
        Instance.new("ScrollingFrame")

    list.Position =
        UDim2.fromOffset(
            12,
            78
        )

    list.Size =
        UDim2.new(
            1,
            -24,
            1,
            -90
        )

    list.BackgroundColor3 =
        Color3.fromRGB(
            20,
            20,
            20
        )

    list.BorderSizePixel = 0

    list.ScrollBarThickness = 4

    list.Parent = content

    local layout =
        Instance.new("UIListLayout")

    layout.Padding =
        UDim.new(
            0,
            5
        )

    layout.Parent = list

    local entries = {}

    for _, entry in ipairs(
        self.Logs:GetEntries()
    ) do

        if entry.Type == "Speed" then

            table.insert(
                entries,
                entry
            )

        end
    end

    if #entries == 0 then

        self:Label(
            list,
            "No loop detections.",
            UDim2.new(
                1,
                -10,
                0,
                35
            ),
            UDim2.fromOffset(
                5,
                5
            ),
            11
        ).TextColor3 =
            Color3.fromRGB(
                125,
                125,
                125
            )

    else

        for i = #entries, 1, -1 do

            self:AddDetection(
                list,
                entries[i]
            )

        end
    end

    task.defer(function()

        list.CanvasSize =
            UDim2.fromOffset(
                0,
                layout.AbsoluteContentSize.Y + 10
            )

    end)
end

--------------------------------------------------
-- JUMP TAB
--------------------------------------------------

function ScannerCore:BuildJump()

    local content =
        self.Content

    self:Label(
        content,
        "JUMP DETECTION",
        UDim2.new(
            1,
            -20,
            0,
            30
        ),
        UDim2.fromOffset(
            12,
            12
        ),
        17
    ).Font =
        Enum.Font.GothamBold

    self:Label(
        content,
        "● ACTIVE   Monitoring jump behavior",
        UDim2.new(
            1,
            -20,
            0,
            25
        ),
        UDim2.fromOffset(
            12,
            43
        ),
        10
    ).TextColor3 =
        Color3.fromRGB(
            80,
            220,
            120
        )

    local list =
        Instance.new("ScrollingFrame")

    list.Position =
        UDim2.fromOffset(
            12,
            78
        )

    list.Size =
        UDim2.new(
            1,
            -24,
            1,
            -90
        )

    list.BackgroundColor3 =
        Color3.fromRGB(
            20,
            20,
            20
        )

    list.BorderSizePixel = 0

    list.ScrollBarThickness = 4

    list.Parent = content

    local layout =
        Instance.new("UIListLayout")

    layout.Padding =
        UDim.new(
            0,
            5
        )

    layout.Parent = list

    local entries = {}

    for _, entry in ipairs(
        self.Logs:GetEntries()
    ) do

        if entry.Type == "Jump" then

            table.insert(
                entries,
                entry
            )

        end
    end

    if #entries == 0 then

        self:Label(
            list,
            "No jump detections.",
            UDim2.new(
                1,
                -10,
                0,
                35
            ),
            UDim2.fromOffset(
                5,
                5
            ),
            11
        ).TextColor3 =
            Color3.fromRGB(
                125,
                125,
                125
            )

    else

        for i = #entries, 1, -1 do

            self:AddDetection(
                list,
                entries[i]
            )

        end
    end

    task.defer(function()

        list.CanvasSize =
            UDim2.fromOffset(
                0,
                layout.AbsoluteContentSize.Y + 10
            )

    end)
end

--------------------------------------------------
-- MISC TAB
--------------------------------------------------

function ScannerCore:BuildMisc()

    local content =
        self.Content

    self:Label(
        content,
        "MISC",
        UDim2.new(
            1,
            -20,
            0,
            30
        ),
        UDim2.fromOffset(
            12,
            12
        ),
        17
    ).Font =
        Enum.Font.GothamBold

    self:Label(
        content,
        "GUI SIZE",
        UDim2.new(
            1,
            -20,
            0,
            25
        ),
        UDim2.fromOffset(
            12,
            50
        ),
        11
    ).Font =
        Enum.Font.GothamMedium

    local small =
        self:Button(
            content,
            "SMALL",
            UDim2.fromOffset(
                95,
                40
            ),
            UDim2.fromOffset(
                12,
                82
            )
        )

    local medium =
        self:Button(
            content,
            "MEDIUM",
            UDim2.fromOffset(
                95,
                40
            ),
            UDim2.fromOffset(
                115,
                82
            )
        )

    local large =
        self:Button(
            content,
            "LARGE",
            UDim2.fromOffset(
                95,
                40
            ),
            UDim2.fromOffset(
                218,
                82
            )
        )

    small.Activated:Connect(function()

        self.GuiSizeMode = "Small"

        self:UpdateScale()

    end)

    medium.Activated:Connect(function()

        self.GuiSizeMode = "Medium"

        self:UpdateScale()

    end)

    large.Activated:Connect(function()

        self.GuiSizeMode = "Large"

        self:UpdateScale()

    end)

    self:Label(
        content,
        "Current size: " ..
            self.GuiSizeMode,
        UDim2.new(
            1,
            -20,
            0,
            30
        ),
        UDim2.fromOffset(
            12,
            140
        ),
        11
    ).TextColor3 =
        Color3.fromRGB(
            80,
            220,
            120
        )

    self:Label(
        content,
        "The GUI automatically scales to fit your phone.",
        UDim2.new(
            1,
            -20,
            0,
            40
        ),
        UDim2.fromOffset(
            12,
            190
        ),
        10
    ).TextColor3 =
        Color3.fromRGB(
            130,
            130,
            130
        )

    self:Label(
        content,
        "Drag the top bar to move it.",
        UDim2.new(
            1,
            -20,
            0,
            40
        ),
        UDim2.fromOffset(
            12,
            225
        ),
        10
    ).TextColor3 =
        Color3.fromRGB(
            130,
            130,
            130
        )
end

--------------------------------------------------
-- REFRESH
--------------------------------------------------

function ScannerCore:RefreshGui()

    if not self.Content then
        return
    end

    for _, child in ipairs(
        self.Content:GetChildren()
    ) do

        child:Destroy()

    end

    if self.ActiveTab == "Loop" then

        self:BuildLoop()

    elseif self.ActiveTab == "Jump" then

        self:BuildJump()

    elseif self.ActiveTab == "Misc" then

        self:BuildMisc()

    end
end

--------------------------------------------------
-- START
--------------------------------------------------

function ScannerCore:Start()

    if self.Started then
        return
    end

    if not self.Config.Enabled then

        warn(
            "[AC-Checker] Scanner disabled."
        )

        return
    end

    self.Started = true

    -- These scan EVERY replicated player.
    self.LoopScanner:Start()
    self.JumpScanner:Start()

    -- GUI belongs ONLY to the local player.
    task.defer(function()

        self:CreateGui()

    end)

    print(
        "[AC-Checker] Scanner started."
    )
end

--------------------------------------------------
-- STOP
--------------------------------------------------

function ScannerCore:Stop()

    if not self.Started then
        return
    end

    self.Started = false

    self.LoopScanner:Stop()
    self.JumpScanner:Stop()

    if self.Gui then

        self.Gui:Destroy()
        self.Gui = nil

    end

    self.Main = nil
    self.Content = nil
    self.Scale = nil

    print(
        "[AC-Checker] Scanner stopped."
    )
end

return ScannerCore
