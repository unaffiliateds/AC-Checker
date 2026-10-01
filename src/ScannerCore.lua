local Players =
    game:GetService("Players")

local UserInputService =
    game:GetService("UserInputService")

local LocalPlayer =
    Players.LocalPlayer

local ScannerCore = {}
ScannerCore.__index = ScannerCore

--------------------------------------------------
-- COLORS
--------------------------------------------------

local Colors = {

    Background =
        Color3.fromRGB(
            10,
            12,
            16
        ),

    Main =
        Color3.fromRGB(
            15,
            18,
            23
        ),

    Header =
        Color3.fromRGB(
            20,
            24,
            30
        ),

    Sidebar =
        Color3.fromRGB(
            13,
            16,
            21
        ),

    Panel =
        Color3.fromRGB(
            19,
            23,
            29
        ),

    PanelLight =
        Color3.fromRGB(
            24,
            29,
            36
        ),

    Button =
        Color3.fromRGB(
            25,
            30,
            37
        ),

    ButtonHover =
        Color3.fromRGB(
            31,
            37,
            45
        ),

    Selected =
        Color3.fromRGB(
            30,
            48,
            41
        ),

    Accent =
        Color3.fromRGB(
            83,
            220,
            128
        ),

    AccentDark =
        Color3.fromRGB(
            45,
            120,
            72
        ),

    Text =
        Color3.fromRGB(
            240,
            243,
            247
        ),

    TextSecondary =
        Color3.fromRGB(
            165,
            173,
            184
        ),

    TextMuted =
        Color3.fromRGB(
            105,
            115,
            128
        ),

    Border =
        Color3.fromRGB(
            39,
            46,
            56
        ),

    Danger =
        Color3.fromRGB(
            235,
            92,
            92
        ),

    Warning =
        Color3.fromRGB(
            245,
            181,
            71
        ),
}

--------------------------------------------------
-- UI HELPERS
--------------------------------------------------

function ScannerCore:Corner(
    object,
    radius
)

    local corner =
        Instance.new("UICorner")

    corner.CornerRadius =
        UDim.new(
            0,
            radius or 8
        )

    corner.Parent =
        object

    return corner
end

function ScannerCore:Stroke(
    object,
    color,
    transparency,
    thickness
)

    local stroke =
        Instance.new("UIStroke")

    stroke.Color =
        color or Colors.Border

    stroke.Transparency =
        transparency or 0

    stroke.Thickness =
        thickness or 1

    stroke.ApplyStrokeMode =
        Enum.ApplyStrokeMode.Border

    stroke.Parent =
        object

    return stroke
end

function ScannerCore:Padding(
    object,
    amount
)

    local padding =
        Instance.new("UIPadding")

    padding.PaddingTop =
        UDim.new(0, amount)

    padding.PaddingBottom =
        UDim.new(0, amount)

    padding.PaddingLeft =
        UDim.new(0, amount)

    padding.PaddingRight =
        UDim.new(0, amount)

    padding.Parent =
        object

    return padding
end

function ScannerCore:Label(
    parent,
    text,
    size,
    pos,
    textSize
)

    local label =
        Instance.new("TextLabel")

    label.Size =
        size

    label.Position =
        pos

    label.BackgroundTransparency =
        1

    label.Text =
        text

    label.TextColor3 =
        Colors.Text

    label.TextSize =
        textSize or 14

    label.Font =
        Enum.Font.Gotham

    label.TextXAlignment =
        Enum.TextXAlignment.Left

    label.TextYAlignment =
        Enum.TextYAlignment.Center

    label.RichText =
        false

    label.Parent =
        parent

    return label
end

function ScannerCore:Button(
    parent,
    text,
    size,
    pos
)

    local button =
        Instance.new("TextButton")

    button.Size =
        size

    button.Position =
        pos

    button.BackgroundColor3 =
        Colors.Button

    button.BorderSizePixel =
        0

    button.Text =
        text

    button.TextColor3 =
        Colors.Text

    button.TextSize =
        12

    button.Font =
        Enum.Font.GothamMedium

    button.AutoButtonColor =
        false

    button.Active =
        true

    button.Selectable =
        true

    self:Corner(
        button,
        8
    )

    self:Stroke(
        button,
        Colors.Border,
        0.25,
        1
    )

    button.MouseEnter:Connect(
        function()

            button.BackgroundColor3 =
                Colors.ButtonHover

        end
    )

    button.MouseLeave:Connect(
        function()

            button.BackgroundColor3 =
                Colors.Button

        end
    )

    button.Parent =
        parent

    return button
end

function ScannerCore:CreateDivider(
    parent,
    position
)

    local divider =
        Instance.new("Frame")

    divider.Size =
        UDim2.new(
            1,
            0,
            0,
            1
        )

    divider.Position =
        position

    divider.BackgroundColor3 =
        Colors.Border

    divider.BorderSizePixel =
        0

    divider.Parent =
        parent

    return divider
end

--------------------------------------------------
-- CONSTRUCTOR
--------------------------------------------------

function ScannerCore.new(
    config,
    modules
)

    config =
        config or {}

    modules =
        modules or {}

    local self =
        setmetatable(
            {},
            ScannerCore
        )

    self.Config = {

        Enabled =
            config.Enabled ~= false,

        BaseSpeed =
            config.BaseSpeed or 18,

        SprintSpeed =
            config.SprintSpeed or 21,

        SpeedTolerance =
            config.SpeedTolerance or 1.25,

        SampleInterval =
            config.SampleInterval or 0.15,

        RequiredViolations =
            config.RequiredViolations or 3,

        ViolationWindow =
            config.ViolationWindow or 1,

        AdminUserIds =
            config.AdminUserIds or {},
    }

    self.Logs =
        modules.Logs.new(
            500
        )

    self.LoopScanner =
        modules.LoopScanner.new({

            BaseSpeed =
                self.Config.BaseSpeed,

            SprintSpeed =
                self.Config.SprintSpeed,

            Tolerance =
                self.Config.SpeedTolerance,

            SampleInterval =
                self.Config.SampleInterval,

            RequiredViolations =
                self.Config.RequiredViolations,

            ViolationWindow =
                self.Config.ViolationWindow,

            OnDetection =
                function(data)

                    self:HandleDetection(
                        data
                    )

                end,
        })

    self.JumpScanner =
        modules.JumpScanner.new({

            OnDetection =
                function(data)

                    self:HandleDetection(
                        data
                    )

                end,
        })

    self.Started =
        false

    self.Gui =
        nil

    self.Main =
        nil

    self.Content =
        nil

    self.Scale =
        nil

    self.ActiveTab =
        "Loop"

    self.GuiSizeMode =
        "Small"

    self.TabButtons =
        {}

    self.TabIndicator =
        nil

    return self
end

--------------------------------------------------
-- DETECTIONS
--------------------------------------------------

function ScannerCore:HandleDetection(
    data
)

    local entry =
        self.Logs:Add(
            data
        )

    if entry.Type ==
        "Speed" then

        print(
            string.format(
                "[AC-Checker] SPEED DETECTION | %s | %.2f studs/s | limit %.2f",
                entry.PlayerName,
                entry.Speed or 0,
                entry.Limit or 0
            )
        )

    elseif entry.Type ==
        "Jump" then

        print(
            string.format(
                "[AC-Checker] JUMP DETECTION | %s | %.2f studs | max %.2f",
                entry.PlayerName,
                entry.Height or 0,
                entry.MaxHeight or 0
            )
        )

    end

    self:RefreshGui()
end

--------------------------------------------------
-- SCALE
--------------------------------------------------

function ScannerCore:GetScale()

    if self.GuiSizeMode ==
        "Small" then

        return 0.68
    end

    if self.GuiSizeMode ==
        "Large" then

        return 0.96
    end

    return 0.82
end

function ScannerCore:UpdateScale()

    if not self.Scale then
        return
    end

    local camera =
        workspace.CurrentCamera

    if not camera then
        return
    end

    local viewport =
        camera.ViewportSize

    local baseWidth =
        640

    local baseHeight =
        400

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

function ScannerCore:MakeDraggable(
    frame,
    handle
)

    local dragging =
        false

    local startInput
    local startPosition

    handle.InputBegan:Connect(
        function(input)

            if
                input.UserInputType ==
                    Enum.UserInputType.MouseButton1
                or
                input.UserInputType ==
                    Enum.UserInputType.Touch
            then

                dragging =
                    true

                startInput =
                    input.Position

                startPosition =
                    frame.Position

                input.Changed:Connect(
                    function()

                        if
                            input.UserInputState ==
                                Enum.UserInputState.End
                        then

                            dragging =
                                false

                        end

                    end
                )

            end

        end
    )

    UserInputService.InputChanged:Connect(
        function(input)

            if not dragging then
                return
            end

            if
                input.UserInputType ~=
                    Enum.UserInputType.MouseMovement
                and
                input.UserInputType ~=
                    Enum.UserInputType.Touch
            then

                return
            end

            local delta =
                input.Position -
                startInput

            frame.Position =
                UDim2.new(

                    startPosition.X.Scale,

                    startPosition.X.Offset +
                        delta.X,

                    startPosition.Y.Scale,

                    startPosition.Y.Offset +
                        delta.Y
                )

        end
    )
end

--------------------------------------------------
-- TAB STYLE
--------------------------------------------------

function ScannerCore:UpdateTabs()

    for name, button in
        pairs(self.TabButtons) do

        if name ==
            self.ActiveTab then

            button.BackgroundColor3 =
                Colors.Selected

            button.TextColor3 =
                Colors.Text

        else

            button.BackgroundColor3 =
                Colors.Button

            button.TextColor3 =
                Colors.TextSecondary

        end
    end
end

--------------------------------------------------
-- STAT CARD
--------------------------------------------------

function ScannerCore:CreateStatCard(
    parent,
    title,
    value,
    x
)

    local card =
        Instance.new("Frame")

    card.Size =
        UDim2.new(
            0.31,
            0,
            0,
            62
        )

    card.Position =
        UDim2.new(
            x,
            0,
            0,
            0
        )

    card.BackgroundColor3 =
        Colors.Panel

    card.BorderSizePixel =
        0

    self:Corner(
        card,
        10
    )

    self:Stroke(
        card,
        Colors.Border,
        0.2,
        1
    )

    card.Parent =
        parent

    local titleLabel =
        self:Label(
            card,
            title,
            UDim2.new(
                1,
                -20,
                0,
                22
            ),
            UDim2.fromOffset(
                10,
                5
            ),
            9
        )

    titleLabel.TextColor3 =
        Colors.TextMuted

    local valueLabel =
        self:Label(
            card,
            value,
            UDim2.new(
                1,
                -20,
                0,
                28
            ),
            UDim2.fromOffset(
                10,
                27
            ),
            15
        )

    valueLabel.Font =
        Enum.Font.GothamBold

    return card
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

    gui.Name =
        "ACCheckerGui"

    gui.ResetOnSpawn =
        false

    gui.Enabled =
        true

    gui.DisplayOrder =
        9999

    gui.ZIndexBehavior =
        Enum.ZIndexBehavior.Global

    gui.IgnoreGuiInset =
        true

    gui.Parent =
        playerGui

    self.Gui =
        gui

    --------------------------------------------------
    -- SCALE
    --------------------------------------------------

    local scale =
        Instance.new("UIScale")

    scale.Scale =
        self:GetScale()

    scale.Parent =
        gui

    self.Scale =
        scale

    --------------------------------------------------
    -- MAIN
    --------------------------------------------------

    local main =
        Instance.new("Frame")

    main.Name =
        "Main"

    main.Size =
        UDim2.fromOffset(
            640,
            400
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
        Colors.Main

    main.BorderSizePixel =
        0

    main.ClipsDescendants =
        true

    self:Corner(
        main,
        16
    )

    self:Stroke(
        main,
        Colors.Border,
        0,
        1
    )

    main.Parent =
        gui

    self.Main =
        main

    --------------------------------------------------
    -- TOP HEADER
    --------------------------------------------------

    local titleBar =
        Instance.new("Frame")

    titleBar.Name =
        "TitleBar"

    titleBar.Size =
        UDim2.new(
            1,
            0,
            0,
            58
        )

    titleBar.BackgroundColor3 =
        Colors.Header

    titleBar.BorderSizePixel =
        0

    titleBar.Parent =
        main

    --------------------------------------------------
    -- HEADER ACCENT
    --------------------------------------------------

    local accent =
        Instance.new("Frame")

    accent.Size =
        UDim2.new(
            1,
            0,
            0,
            2
        )

    accent.Position =
        UDim2.new(
            0,
            0,
            1,
            -2
        )

    accent.BackgroundColor3 =
        Colors.Accent

    accent.BorderSizePixel =
        0

    accent.Parent =
        titleBar

    --------------------------------------------------
    -- TITLE
    --------------------------------------------------

    local title =
        self:Label(
            titleBar,
            "AC-CHECKER",
            UDim2.new(
                1,
                -220,
                0,
                30
            ),
            UDim2.fromOffset(
                18,
                9
            ),
            19
        )

    title.Font =
        Enum.Font.GothamBold

    --------------------------------------------------
    -- SUBTITLE
    --------------------------------------------------

    local subtitle =
        self:Label(
            titleBar,
            "Client-side monitoring interface",
            UDim2.new(
                1,
                -220,
                0,
                18
            ),
            UDim2.fromOffset(
                19,
                32
            ),
            9
        )

    subtitle.TextColor3 =
        Colors.TextMuted

    --------------------------------------------------
    -- ONLINE STATUS
    --------------------------------------------------

    local online =
        Instance.new("Frame")

    online.Size =
        UDim2.fromOffset(
            103,
            32
        )

    online.Position =
        UDim2.new(
            1,
            -118,
            0,
            13
        )

    online.BackgroundColor3 =
        Color3.fromRGB(
            23,
            42,
            31
        )

    online.BorderSizePixel =
        0

    self:Corner(
        online,
        8
    )

    self:Stroke(
        online,
        Colors.AccentDark,
        0.25,
        1
    )

    online.Parent =
        titleBar

    local statusDot =
        Instance.new("Frame")

    statusDot.Size =
        UDim2.fromOffset(
            7,
            7
        )

    statusDot.Position =
        UDim2.fromOffset(
            11,
            12
        )

    statusDot.BackgroundColor3 =
        Colors.Accent

    statusDot.BorderSizePixel =
        0

    self:Corner(
        statusDot,
        99
    )

    statusDot.Parent =
        online

    local statusText =
        self:Label(
            online,
            "ONLINE",
            UDim2.new(
                1,
                -28,
                1,
                0
            ),
            UDim2.fromOffset(
                25,
                0
            ),
            9
        )

    statusText.Font =
        Enum.Font.GothamBold

    statusText.TextColor3 =
        Colors.Accent

    self:MakeDraggable(
        main,
        titleBar
    )

    --------------------------------------------------
    -- SIDEBAR
    --------------------------------------------------

    local sidebar =
        Instance.new("Frame")

    sidebar.Name =
        "Sidebar"

    sidebar.Size =
        UDim2.new(
            0,
            145,
            1,
            -58
        )

    sidebar.Position =
        UDim2.fromOffset(
            0,
            58
        )

    sidebar.BackgroundColor3 =
        Colors.Sidebar

    sidebar.BorderSizePixel =
        0

    sidebar.Parent =
        main

    --------------------------------------------------
    -- SIDEBAR TITLE
    --------------------------------------------------

    local scannerTitle =
        self:Label(
            sidebar,
            "SCANNERS",
            UDim2.new(
                1,
                -28,
                0,
                24
            ),
            UDim2.fromOffset(
                14,
                16
            ),
            10
        )

    scannerTitle.Font =
        Enum.Font.GothamBold

    scannerTitle.TextColor3 =
        Colors.TextMuted

    --------------------------------------------------
    -- TAB BUTTONS
    --------------------------------------------------

    local loop =
        self:Button(
            sidebar,
            "LOOP",
            UDim2.new(
                1,
                -20,
                0,
                46
            ),
            UDim2.fromOffset(
                10,
                51
            )
        )

    local jump =
        self:Button(
            sidebar,
            "JUMP",
            UDim2.new(
                1,
                -20,
                0,
                46
            ),
            UDim2.fromOffset(
                10,
                105
            )
        )

    local misc =
        self:Button(
            sidebar,
            "MISC",
            UDim2.new(
                1,
                -20,
                0,
                46
            ),
            UDim2.fromOffset(
                10,
                159
            )
        )

    self.TabButtons = {

        Loop =
            loop,

        Jump =
            jump,

        Misc =
            misc,
    }

    loop.Activated:Connect(
        function()

            self.ActiveTab =
                "Loop"

            self:UpdateTabs()
            self:RefreshGui()

        end
    )

    jump.Activated:Connect(
        function()

            self.ActiveTab =
                "Jump"

            self:UpdateTabs()
            self:RefreshGui()

        end
    )

    misc.Activated:Connect(
        function()

            self.ActiveTab =
                "Misc"

            self:UpdateTabs()
            self:RefreshGui()

        end
    )

    --------------------------------------------------
    -- SIDEBAR FOOTER
    --------------------------------------------------

    local footer =
        Instance.new("Frame")

    footer.Size =
        UDim2.new(
            1,
            -28,
            0,
            66
        )

    footer.Position =
        UDim2.new(
            0,
            14,
            1,
            -80
        )

    footer.BackgroundColor3 =
        Colors.Panel

    footer.BorderSizePixel =
        0

    self:Corner(
        footer,
        9
    )

    self:Stroke(
        footer,
        Colors.Border,
        0.3,
        1
    )

    footer.Parent =
        sidebar

    local scanLabel =
        self:Label(
            footer,
            "SCANNER STATUS",
            UDim2.new(
                1,
                -16,
                0,
                18
            ),
            UDim2.fromOffset(
                8,
                7
            ),
            8
        )

    scanLabel.Font =
        Enum.Font.GothamBold

    scanLabel.TextColor3 =
        Colors.TextMuted

    local activeLabel =
        self:Label(
            footer,
            "ACTIVE",
            UDim2.new(
                1,
                -16,
                0,
                22
            ),
            UDim2.fromOffset(
                8,
                28
            ),
            11
        )

    activeLabel.Font =
        Enum.Font.GothamBold

    activeLabel.TextColor3 =
        Colors.Accent

    --------------------------------------------------
    -- CONTENT
    --------------------------------------------------

    local content =
        Instance.new("Frame")

    content.Name =
        "Content"

    content.Size =
        UDim2.new(
            1,
            -145,
            1,
            -58
        )

    content.Position =
        UDim2.fromOffset(
            145,
            58
        )

    content.BackgroundColor3 =
        Colors.Background

    content.BorderSizePixel =
        0

    content.Parent =
        main

    self.Content =
        content

    self:UpdateTabs()
    self:UpdateScale()
    self:RefreshGui()

    print(
        "[AC-Checker] GUI created successfully."
    )
end

--------------------------------------------------
-- DETECTION ROW
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
            -4,
            0,
            62
        )

    row.BackgroundColor3 =
        Colors.Panel

    row.BorderSizePixel =
        0

    self:Corner(
        row,
        9
    )

    self:Stroke(
        row,
        Colors.Border,
        0.3,
        1
    )

    row.Parent =
        list

    --------------------------------------------------
    -- STATUS STRIPE
    --------------------------------------------------

    local stripe =
        Instance.new("Frame")

    stripe.Size =
        UDim2.new(
            0,
            3,
            1,
            -18
        )

    stripe.Position =
        UDim2.fromOffset(
            8,
            9
        )

    stripe.BackgroundColor3 =
        Colors.Danger

    stripe.BorderSizePixel =
        0

    self:Corner(
        stripe,
        4
    )

    stripe.Parent =
        row

    --------------------------------------------------
    -- PLAYER
    --------------------------------------------------

    local name =
        entry.PlayerName or
        "Unknown"

    local nameLabel =
        self:Label(
            row,
            name,
            UDim2.new(
                1,
                -125,
                0,
                22
            ),
            UDim2.fromOffset(
                22,
                7
            ),
            12
        )

    nameLabel.Font =
        Enum.Font.GothamBold

    --------------------------------------------------
    -- TYPE
    --------------------------------------------------

    local typeText =
        entry.Type or
        "Detection"

    local typeLabel =
        self:Label(
            row,
            string.upper(
                typeText
            ),
            UDim2.fromOffset(
                78,
                20
            ),
            UDim2.new(
                1,
                -88,
                0,
                7
            ),
            8
        )

    typeLabel.TextXAlignment =
        Enum.TextXAlignment.Right

    typeLabel.Font =
        Enum.Font.GothamBold

    typeLabel.TextColor3 =
        Colors.Danger

    --------------------------------------------------
    -- DETAILS
    --------------------------------------------------

    local detail

    if entry.Type ==
        "Speed" then

        detail =
            string.format(
                "%.2f studs/s   •   limit %.2f",
                entry.Speed or 0,
                entry.Limit or 0
            )

        if entry.Sprinting then

            detail =
                detail ..
                "   •   SPRINT"

        end

    elseif entry.Type ==
        "Jump" then

        detail =
            string.format(
                "%.2f studs   •   max %.2f",
                entry.Height or 0,
                entry.MaxHeight or 0
            )

        if entry.PeakUpwardVelocity then

            detail =
                detail ..
                string.format(
                    "   •   peak %.2f",
                    entry.PeakUpwardVelocity
                )

        end

    else

        detail =
            "Detection"

    end

    local detailLabel =
        self:Label(
            row,
            detail,
            UDim2.new(
                1,
                -30,
                0,
                20
            ),
            UDim2.fromOffset(
                22,
                31
            ),
            9
        )

    detailLabel.TextColor3 =
        Colors.TextSecondary
end

--------------------------------------------------
-- STATISTICS
--------------------------------------------------

function ScannerCore:GetDetectionCount(
    detectionType
)

    local count =
        0

    for _, entry in ipairs(
        self.Logs:GetEntries()
    ) do

        if entry.Type ==
            detectionType then

            count += 1

        end
    end

    return count
end

--------------------------------------------------
-- TAB HEADER
--------------------------------------------------

function ScannerCore:BuildHeader(
    titleText,
    statusText
)

    local content =
        self.Content

    local title =
        self:Label(
            content,
            titleText,
            UDim2.new(
                1,
                -28,
                0,
                30
            ),
            UDim2.fromOffset(
                18,
                17
            ),
            18
        )

    title.Font =
        Enum.Font.GothamBold

    local status =
        self:Label(
            content,
            statusText,
            UDim2.new(
                1,
                -28,
                0,
                20
            ),
            UDim2.fromOffset(
                19,
                43
            ),
            9
        )

    status.TextColor3 =
        Colors.Accent

    return content
end

--------------------------------------------------
-- LOOP TAB
--------------------------------------------------

function ScannerCore:BuildLoop()

    local content =
        self.Content

    self:BuildHeader(
        "LOOP DETECTION",
        "● ACTIVE   Movement monitoring enabled"
    )

    --------------------------------------------------
    -- STAT CARDS
    --------------------------------------------------

    local stats =
        Instance.new("Frame")

    stats.Size =
        UDim2.new(
            1,
            -36,
            0,
            62
        )

    stats.Position =
        UDim2.fromOffset(
            18,
            78
        )

    stats.BackgroundTransparency =
        1

    stats.Parent =
        content

    self:CreateStatCard(
        stats,
        "NORMAL",
        string.format(
            "%.1f",
            self.Config.BaseSpeed
        ),
        0
    )

    self:CreateStatCard(
        stats,
        "SPRINT",
        string.format(
            "%.1f",
            self.Config.SprintSpeed
        ),
        0.345
    )

    self:CreateStatCard(
        stats,
        "DETECTIONS",
        tostring(
            self:GetDetectionCount(
                "Speed"
            )
        ),
        0.69
    )

    --------------------------------------------------
    -- LOG PANEL
    --------------------------------------------------

    local list =
        Instance.new(
            "ScrollingFrame"
        )

    list.Position =
        UDim2.fromOffset(
            18,
            154
        )

    list.Size =
        UDim2.new(
            1,
            -36,
            1,
            -172
        )

    list.BackgroundColor3 =
        Colors.Panel

    list.BorderSizePixel =
        0

    list.ScrollBarThickness =
        3

    list.ScrollBarImageColor3 =
        Colors.Accent

    list.AutomaticCanvasSize =
        Enum.AutomaticSize.Y

    list.CanvasSize =
        UDim2.fromScale(
            0,
            0
        )

    self:Corner(
        list,
        11
    )

    self:Stroke(
        list,
        Colors.Border,
        0.25,
        1
    )

    self:Padding(
        list,
        7
    )

    list.Parent =
        content

    local layout =
        Instance.new("UIListLayout")

    layout.Padding =
        UDim.new(
            0,
            6
        )

    layout.SortOrder =
        Enum.SortOrder.LayoutOrder

    layout.Parent =
        list

    local entries =
        {}

    for _, entry in ipairs(
        self.Logs:GetEntries()
    ) do

        if entry.Type ==
            "Speed" then

            table.insert(
                entries,
                entry
            )
        end
    end

    if #entries == 0 then

        local empty =
            self:Label(
                list,
                "No loop detections.",
                UDim2.new(
                    1,
                    0,
                    0,
                    40
                ),
                UDim2.fromOffset(
                    0,
                    0
                ),
                10
            )

        empty.TextColor3 =
            Colors.TextMuted

        empty.TextXAlignment =
            Enum.TextXAlignment.Center

    else

        for i =
            #entries,
            1,
            -1
        do

            self:AddDetection(
                list,
                entries[i]
            )

        end

    end
end

--------------------------------------------------
-- JUMP TAB
--------------------------------------------------

function ScannerCore:BuildJump()

    local content =
        self.Content

    self:BuildHeader(
        "JUMP DETECTION",
        "● ACTIVE   Jump behavior monitoring enabled"
    )

    --------------------------------------------------
    -- STAT CARDS
    --------------------------------------------------

    local stats =
        Instance.new("Frame")

    stats.Size =
        UDim2.new(
            1,
            -36,
            0,
            62
        )

    stats.Position =
        UDim2.fromOffset(
            18,
            78
        )

    stats.BackgroundTransparency =
        1

    stats.Parent =
        content

    self:CreateStatCard(
        stats,
        "JUMP POWER",
        "53.5",
        0
    )

    self:CreateStatCard(
        stats,
        "PEAK VELOCITY",
        "51.865",
        0.345
    )

    self:CreateStatCard(
        stats,
        "DETECTIONS",
        tostring(
            self:GetDetectionCount(
                "Jump"
            )
        ),
        0.69
    )

    --------------------------------------------------
    -- LOG PANEL
    --------------------------------------------------

    local list =
        Instance.new(
            "ScrollingFrame"
        )

    list.Position =
        UDim2.fromOffset(
            18,
            154
        )

    list.Size =
        UDim2.new(
            1,
            -36,
            1,
            -172
        )

    list.BackgroundColor3 =
        Colors.Panel

    list.BorderSizePixel =
        0

    list.ScrollBarThickness =
        3

    list.ScrollBarImageColor3 =
        Colors.Accent

    list.AutomaticCanvasSize =
        Enum.AutomaticSize.Y

    list.CanvasSize =
        UDim2.fromScale(
            0,
            0
        )

    self:Corner(
        list,
        11
    )

    self:Stroke(
        list,
        Colors.Border,
        0.25,
        1
    )

    self:Padding(
        list,
        7
    )

    list.Parent =
        content

    local layout =
        Instance.new("UIListLayout")

    layout.Padding =
        UDim.new(
            0,
            6
        )

    layout.SortOrder =
        Enum.SortOrder.LayoutOrder

    layout.Parent =
        list

    local entries =
        {}

    for _, entry in ipairs(
        self.Logs:GetEntries()
    ) do

        if entry.Type ==
            "Jump" then

            table.insert(
                entries,
                entry
            )
        end
    end

    if #entries == 0 then

        local empty =
            self:Label(
                list,
                "No jump detections.",
                UDim2.new(
                    1,
                    0,
                    0,
                    40
                ),
                UDim2.fromOffset(
                    0,
                    0
                ),
                10
            )

        empty.TextColor3 =
            Colors.TextMuted

        empty.TextXAlignment =
            Enum.TextXAlignment.Center

    else

        for i =
            #entries,
            1,
            -1
        do

            self:AddDetection(
                list,
                entries[i]
            )

        end
    end
end

--------------------------------------------------
-- MISC TAB
--------------------------------------------------

function ScannerCore:BuildMisc()

    local content =
        self.Content

    self:BuildHeader(
        "MISC",
        "● Interface and display settings"
    )

    --------------------------------------------------
    -- SIZE PANEL
    --------------------------------------------------

    local sizePanel =
        Instance.new("Frame")

    sizePanel.Size =
        UDim2.new(
            1,
            -36,
            0,
            144
        )

    sizePanel.Position =
        UDim2.fromOffset(
            18,
            78
        )

    sizePanel.BackgroundColor3 =
        Colors.Panel

    sizePanel.BorderSizePixel =
        0

    self:Corner(
        sizePanel,
        11
    )

    self:Stroke(
        sizePanel,
        Colors.Border,
        0.25,
        1
    )

    sizePanel.Parent =
        content

    local sizeTitle =
        self:Label(
            sizePanel,
            "GUI SIZE",
            UDim2.new(
                1,
                -24,
                0,
                24
            ),
            UDim2.fromOffset(
                12,
                10
            ),
            11
        )

    sizeTitle.Font =
        Enum.Font.GothamBold

    sizeTitle.TextColor3 =
        Colors.Text

    --------------------------------------------------
    -- SIZE BUTTONS
    --------------------------------------------------

    local small =
        self:Button(
            sizePanel,
            "SMALL",
            UDim2.new(
                0.29,
                0,
                0,
                42
            ),
            UDim2.new(
                0,
                12,
                0,
                49
            )
        )

    local medium =
        self:Button(
            sizePanel,
            "MEDIUM",
            UDim2.new(
                0.29,
                0,
                0,
                42
            ),
            UDim2.new(
                0.355,
                0,
                0,
                49
            )
        )

    local large =
        self:Button(
            sizePanel,
            "LARGE",
            UDim2.new(
                0.29,
                0,
                0,
                42
            ),
            UDim2.new(
                0.71,
                0,
                0,
                49
            )
        )

    small.Activated:Connect(
        function()

            self.GuiSizeMode =
                "Small"

            self:UpdateScale()

        end
    )

    medium.Activated:Connect(
        function()

            self.GuiSizeMode =
                "Medium"

            self:UpdateScale()

        end
    )

    large.Activated:Connect(
        function()

            self.GuiSizeMode =
                "Large"

            self:UpdateScale()

        end
    )

    --------------------------------------------------
    -- CURRENT SIZE
    --------------------------------------------------

    local current =
        self:Label(
            sizePanel,
            "Current size: " ..
                self.GuiSizeMode,
            UDim2.new(
                1,
                -24,
                0,
                20
            ),
            UDim2.fromOffset(
                12,
                101
            ),
            9
        )

    current.TextColor3 =
        Colors.Accent

    --------------------------------------------------
    -- INFORMATION
    --------------------------------------------------

    local infoPanel =
        Instance.new("Frame")

    infoPanel.Size =
        UDim2.new(
            1,
            -36,
            0,
            122
        )

    infoPanel.Position =
        UDim2.fromOffset(
            18,
            236
        )

    infoPanel.BackgroundColor3 =
        Colors.Panel

    infoPanel.BorderSizePixel =
        0

    self:Corner(
        infoPanel,
        11
    )

    self:Stroke(
        infoPanel,
        Colors.Border,
        0.25,
        1
    )

    infoPanel.Parent =
        content

    local infoTitle =
        self:Label(
            infoPanel,
            "INTERFACE",
            UDim2.new(
                1,
                -24,
                0,
                20
            ),
            UDim2.fromOffset(
                12,
                10
            ),
            10
        )

    infoTitle.Font =
        Enum.Font.GothamBold

    local info1 =
        self:Label(
            infoPanel,
            "The GUI automatically scales to fit your screen.",
            UDim2.new(
                1,
                -24,
                0,
                22
            ),
            UDim2.fromOffset(
                12,
                37
            ),
            9
        )

    info1.TextColor3 =
        Colors.TextSecondary

    local info2 =
        self:Label(
            infoPanel,
            "Drag the top bar to move it.",
            UDim2.new(
                1,
                -24,
                0,
                22
            ),
            UDim2.fromOffset(
                12,
                61
            ),
            9
        )

    info2.TextColor3 =
        Colors.TextSecondary

    local info3 =
        self:Label(
            infoPanel,
            "Scanner data is displayed locally to the client.",
            UDim2.new(
                1,
                -24,
                0,
                22
            ),
            UDim2.fromOffset(
                12,
                85
            ),
            9
        )

    info3.TextColor3 =
        Colors.TextMuted
end

--------------------------------------------------
-- REFRESH
--------------------------------------------------

function ScannerCore:RefreshGui()

    if not self.Content then
        return
    end

    for _, child in
        ipairs(
            self.Content:GetChildren()
        )
    do

        child:Destroy()

    end

    if self.ActiveTab ==
        "Loop" then

        self:BuildLoop()

    elseif self.ActiveTab ==
        "Jump" then

        self:BuildJump()

    elseif self.ActiveTab ==
        "Misc" then

        self:BuildMisc()

    end

    self:UpdateTabs()
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

    self.Started =
        true

    --------------------------------------------------
    -- SCANNERS
    --------------------------------------------------

    self.LoopScanner:Start()
    self.JumpScanner:Start()

    --------------------------------------------------
    -- LOCAL GUI
    --------------------------------------------------

    task.defer(
        function()

            self:CreateGui()

        end
    )

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

    self.Started =
        false

    self.LoopScanner:Stop()
    self.JumpScanner:Stop()

    if self.Gui then

        self.Gui:Destroy()

        self.Gui =
            nil

    end

    self.Main =
        nil

    self.Content =
        nil

    self.Scale =
        nil

    table.clear(
        self.TabButtons
    )

    print(
        "[AC-Checker] Scanner stopped."
    )
end

return ScannerCore
