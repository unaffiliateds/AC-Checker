--[[
    AC-Checker
    ScannerCore.lua

    Main controller + mobile-friendly GUI.

    Tabs:
        LOOP DETECTION
        JUMP DETECTION
        MISC
]]

local Players =
    game:GetService("Players")

local UserInputService =
    game:GetService("UserInputService")

local ScannerCore = {}
ScannerCore.__index = ScannerCore

--------------------------------------------------
-- CONSTRUCTOR
--------------------------------------------------

function ScannerCore.new(
    config,
    modules
)

    config = config or {}
    modules = modules or {}

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

        ShowGuiToAll =
            config.ShowGuiToAll ~= false,

        AdminUserIds =
            config.AdminUserIds or {},
    }

    self.Logs =
        modules.Logs.new(500)

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

    self.Started = false

    self.Gui = nil
    self.Main = nil
    self.Content = nil

    self.ActiveTab = "Loop"

    self.GuiSizeMode = "Medium"

    self.GuiScale = nil

    self.PlayerAddedConnection = nil
    self.PlayerRemovingConnection = nil
    self.ViewportConnection = nil

    return self
end

--------------------------------------------------
-- ADMIN / ACCESS
--------------------------------------------------

function ScannerCore:IsAdmin(
    player
)

    if self.Config.ShowGuiToAll then
        return true
    end

    for _, userId in ipairs(
        self.Config.AdminUserIds
    ) do

        if player.UserId == userId then
            return true
        end

    end

    return false
end

--------------------------------------------------
-- DETECTION
--------------------------------------------------

function ScannerCore:HandleDetection(
    data
)

    local entry =
        self.Logs:Add(data)

    if entry.Type == "Speed" then

        print(
            string.format(
                "[AC-Checker] SPEED DETECTION | %s | %.2f studs/s | limit %.2f",
                entry.PlayerName,
                entry.Speed or 0,
                entry.Limit or 0
            )
        )

    elseif entry.Type == "Jump" then

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
-- GUI HELPERS
--------------------------------------------------

function ScannerCore:CreateLabel(
    parent,
    text,
    size,
    position,
    textSize
)

    local label =
        Instance.new("TextLabel")

    label.Size = size
    label.Position = position

    label.BackgroundTransparency = 1

    label.Text = text

    label.TextColor3 =
        Color3.fromRGB(
            225,
            225,
            225
        )

    label.TextSize =
        textSize or 14

    label.Font =
        Enum.Font.Gotham

    label.TextXAlignment =
        Enum.TextXAlignment.Left

    label.TextYAlignment =
        Enum.TextYAlignment.Center

    label.Parent = parent

    return label
end

function ScannerCore:CreateButton(
    parent,
    text,
    size,
    position
)

    local button =
        Instance.new("TextButton")

    button.Size = size
    button.Position = position

    button.BackgroundColor3 =
        Color3.fromRGB(
            32,
            32,
            32
        )

    button.BorderSizePixel = 0

    button.Text = text

    button.TextColor3 =
        Color3.fromRGB(
            220,
            220,
            220
        )

    button.TextSize = 13

    button.Font =
        Enum.Font.GothamMedium

    button.AutoButtonColor = true

    button.Active = true

    button.Parent = parent

    return button
end

--------------------------------------------------
-- GUI SCALE
--------------------------------------------------

function ScannerCore:GetPreferredScale()

    if self.GuiSizeMode == "Small" then
        return 0.72
    end

    if self.GuiSizeMode == "Large" then
        return 1
    end

    return 0.86
end

function ScannerCore:UpdateGuiScale()

    if not self.Main
        or not self.GuiScale then

        return
    end

    local camera =
        workspace.CurrentCamera

    if not camera then
        return
    end

    local viewport =
        camera.ViewportSize

    local preferred =
        self:GetPreferredScale()

    -- Base GUI dimensions.
    local baseWidth = 700
    local baseHeight = 430

    -- Keep the interface inside the visible screen.
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

    -- Don't upscale beyond preference.
    -- This is especially useful on phones.
    local finalScale =
        math.min(
            preferred,
            fit
        )

    -- Give extremely small displays a minimum.
    finalScale =
        math.max(
            finalScale,
            0.48
        )

    self.GuiScale.Scale =
        finalScale

    self.Main.Position =
        UDim2.new(
            0.5,
            0,
            0.5,
            0
        )
end

--------------------------------------------------
-- DRAGGING
--------------------------------------------------

function ScannerCore:EnableDragging(
    frame,
    dragHandle
)

    local dragging = false
    local dragStart
    local startPosition

    local function update(
        input
    )

        if not dragging then
            return
        end

        local delta =
            input.Position -
            dragStart

        frame.Position =
            UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
    end

    dragHandle.InputBegan:Connect(
        function(input)

            if input.UserInputType ==
                Enum.UserInputType.MouseButton1
                or
                input.UserInputType ==
                Enum.UserInputType.Touch then

                dragging = true

                dragStart =
                    input.Position

                startPosition =
                    frame.Position

                input.Changed:Connect(
                    function()

                        if input.UserInputState ==
                            Enum.UserInputState.End then

                            dragging = false

                        end
                    end
                )
            end
        end
    )

    UserInputService.InputChanged:Connect(
        function(input)

            if input.UserInputType ==
                Enum.UserInputType.MouseMovement
                or
                input.UserInputType ==
                Enum.UserInputType.Touch then

                update(input)
            end
        end
    )
end

--------------------------------------------------
-- GUI CREATION
--------------------------------------------------

function ScannerCore:CreateGui(
    player
)

    if not self:IsAdmin(player) then
        return
    end

    local playerGui =
        player:FindFirstChildOfClass(
            "PlayerGui"
        )

    if not playerGui then
        return
    end

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

    gui.IgnoreGuiInset =
        false

    gui.Parent =
        playerGui

    self.Gui = gui

    --------------------------------------------------
    -- SCALE
    --------------------------------------------------

    local scale =
        Instance.new("UIScale")

    scale.Scale = 0.86

    scale.Parent = gui

    self.GuiScale =
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
            700,
            430
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
            17,
            17,
            17
        )

    main.BorderSizePixel = 0

    main.Parent = gui

    self.Main =
        main

    --------------------------------------------------
    -- TITLE BAR
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
        Color3.fromRGB(
            22,
            22,
            22
        )

    titleBar.BorderSizePixel = 0

    titleBar.Parent =
        main

    local title =
        self:CreateLabel(
            titleBar,
            "AC-CHECKER",
            UDim2.new(
                1,
                -150,
                1,
                0
            ),
            UDim2.fromOffset(
                18,
                0
            ),
            20
        )

    title.Font =
        Enum.Font.GothamBold

    local status =
        self:CreateLabel(
            titleBar,
            "● ONLINE",
            UDim2.fromOffset(
                110,
                30
            ),
            UDim2.new(
                1,
                -125,
                0.5,
                -15
            ),
            12
        )

    status.TextXAlignment =
        Enum.TextXAlignment.Right

    status.TextColor3 =
        Color3.fromRGB(
            80,
            220,
            120
        )

    --------------------------------------------------
    -- DRAGGING
    --------------------------------------------------

    self:EnableDragging(
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
        Color3.fromRGB(
            21,
            21,
            21
        )

    sidebar.BorderSizePixel = 0

    sidebar.Parent =
        main

    self:CreateLabel(
        sidebar,
        "SCANNERS",
        UDim2.new(
            1,
            -24,
            0,
            28
        ),
        UDim2.fromOffset(
            12,
            12
        ),
        11
    ).TextColor3 =
        Color3.fromRGB(
            140,
            140,
            140
        )

    local loopButton =
        self:CreateButton(
            sidebar,
            "LOOP",
            UDim2.new(
                1,
                -20,
                0,
                42
            ),
            UDim2.fromOffset(
                10,
                48
            )
        )

    local jumpButton =
        self:CreateButton(
            sidebar,
            "JUMP",
            UDim2.new(
                1,
                -20,
                0,
                42
            ),
            UDim2.fromOffset(
                10,
                96
            )
        )

    local miscButton =
        self:CreateButton(
            sidebar,
            "MISC",
            UDim2.new(
                1,
                -20,
                0,
                42
            ),
            UDim2.fromOffset(
                10,
                144
            )
        )

    loopButton.Activated:Connect(
        function()

            self.ActiveTab =
                "Loop"

            self:RefreshGui()
        end
    )

    jumpButton.Activated:Connect(
        function()

            self.ActiveTab =
                "Jump"

            self:RefreshGui()
        end
    )

    miscButton.Activated:Connect(
        function()

            self.ActiveTab =
                "Misc"

            self:RefreshGui()
        end
    )

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

    content.BackgroundTransparency =
        1

    content.Parent =
        main

    self.Content =
        content

    --------------------------------------------------
    -- VIEWPORT
    --------------------------------------------------

    local camera =
        workspace.CurrentCamera

    if camera then

        self.ViewportConnection =
            camera:GetPropertyChangedSignal(
                "ViewportSize"
            ):Connect(
                function()

                    self:UpdateGuiScale()

                end
            )
    end

    self:UpdateGuiScale()
    self:RefreshGui()
end

--------------------------------------------------
-- DETECTION ROW
--------------------------------------------------

function ScannerCore:AddDetectionRow(
    parent,
    entry,
    index
)

    local row =
        Instance.new("Frame")

    row.Size =
        UDim2.new(
            1,
            -10,
            0,
            52
        )

    row.BackgroundColor3 =
        Color3.fromRGB(
            28,
            28,
            28
        )

    row.BorderSizePixel = 0

    row.LayoutOrder =
        index

    row.Parent =
        parent

    local titleText

    local detailText

    if entry.Type ==
        "Speed" then

        titleText =
            entry.PlayerName

        detailText =
            string.format(
                "%.2f studs/s  •  limit %.2f",
                entry.Speed or 0,
                entry.Limit or 0
            )

    elseif entry.Type ==
        "Jump" then

        titleText =
            entry.PlayerName

        detailText =
            string.format(
                "%.2f studs  •  max %.2f",
                entry.Height or 0,
                entry.MaxHeight or 0
            )

    else

        titleText =
            entry.PlayerName

        detailText =
            "Unknown detection"
    end

    local title =
        self:CreateLabel(
            row,
            titleText,
            UDim2.new(
                1,
                -20,
                0,
                25
            ),
            UDim2.fromOffset(
                10,
                3
            ),
            13
        )

    title.Font =
        Enum.Font.GothamMedium

    self:CreateLabel(
        row,
        detailText,
        UDim2.new(
            1,
            -20,
            0,
            20
        ),
        UDim2.fromOffset(
            10,
            27
        ),
        11
    ).TextColor3 =
        Color3.fromRGB(
            150,
            150,
            150
        )
end

--------------------------------------------------
-- LOOP TAB
--------------------------------------------------

function ScannerCore:BuildLoopTab()

    local content =
        self.Content

    self:CreateLabel(
        content,
        "LOOP DETECTION",
        UDim2.new(
            1,
            -30,
            0,
            34
        ),
        UDim2.fromOffset(
            15,
            15
        ),
        19
    ).Font =
        Enum.Font.GothamBold

    self:CreateLabel(
        content,
        string.format(
            "● ACTIVE    Normal %.1f    Sprint %.1f",
            self.Config.BaseSpeed,
            self.Config.SprintSpeed
        ),
        UDim2.new(
            1,
            -30,
            0,
            28
        ),
        UDim2.fromOffset(
            15,
            48
        ),
        11
    ).TextColor3 =
        Color3.fromRGB(
            80,
            220,
            120
        )

    local detectionCount = 0

    for _, entry in ipairs(
        self.Logs:GetEntries()
    ) do

        if entry.Type == "Speed" then
            detectionCount += 1
        end
    end

    self:CreateLabel(
        content,
        "DETECTIONS  •  " ..
            tostring(
                detectionCount
            ),
        UDim2.new(
            1,
            -30,
            0,
            24
        ),
        UDim2.fromOffset(
            15,
            82
        ),
        11
    ).TextColor3 =
        Color3.fromRGB(
            150,
            150,
            150
        )

    local list =
        Instance.new("ScrollingFrame")

    list.Size =
        UDim2.new(
            1,
            -30,
            1,
            -125
        )

    list.Position =
        UDim2.fromOffset(
            15,
            115
        )

    list.BackgroundColor3 =
        Color3.fromRGB(
            20,
            20,
            20
        )

    list.BorderSizePixel = 0

    list.ScrollBarThickness = 5

    list.Parent =
        content

    local layout =
        Instance.new(
            "UIListLayout"
        )

    layout.Padding =
        UDim.new(
            0,
            6
        )

    layout.Parent =
        list

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

        self:CreateLabel(
            list,
            "No loop detections recorded.",
            UDim2.new(
                1,
                -20,
                0,
                45
            ),
            UDim2.fromOffset(
                10,
                10
            ),
            12
        ).TextColor3 =
            Color3.fromRGB(
                120,
                120,
                120
            )

    else

        for i = #entries, 1, -1 do

            self:AddDetectionRow(
                list,
                entries[i],
                #entries - i + 1
            )
        end
    end

    task.defer(
        function()

            list.CanvasSize =
                UDim2.fromOffset(
                    0,
                    layout.AbsoluteContentSize.Y + 10
                )

        end
    )
end

--------------------------------------------------
-- JUMP TAB
--------------------------------------------------

function ScannerCore:BuildJumpTab()

    local content =
        self.Content

    self:CreateLabel(
        content,
        "JUMP DETECTION",
        UDim2.new(
            1,
            -30,
            0,
            34
        ),
        UDim2.fromOffset(
            15,
            15
        ),
        19
    ).Font =
        Enum.Font.GothamBold

    self:CreateLabel(
        content,
        "● ACTIVE    Monitoring abnormal jump behavior",
        UDim2.new(
            1,
            -30,
            0,
            28
        ),
        UDim2.fromOffset(
            15,
            48
        ),
        11
    ).TextColor3 =
        Color3.fromRGB(
            80,
            220,
            120
        )

    local detectionCount = 0

    for _, entry in ipairs(
        self.Logs:GetEntries()
    ) do

        if entry.Type == "Jump" then
            detectionCount += 1
        end
    end

    self:CreateLabel(
        content,
        "DETECTIONS  •  " ..
            tostring(
                detectionCount
            ),
        UDim2.new(
            1,
            -30,
            0,
            24
        ),
        UDim2.fromOffset(
            15,
            82
        ),
        11
    ).TextColor3 =
        Color3.fromRGB(
            150,
            150,
            150
        )

    local list =
        Instance.new("ScrollingFrame")

    list.Size =
        UDim2.new(
            1,
            -30,
            1,
            -125
        )

    list.Position =
        UDim2.fromOffset(
            15,
            115
        )

    list.BackgroundColor3 =
        Color3.fromRGB(
            20,
            20,
            20
        )

    list.BorderSizePixel = 0

    list.ScrollBarThickness = 5

    list.Parent =
        content

    local layout =
        Instance.new(
            "UIListLayout"
        )

    layout.Padding =
        UDim.new(
            0,
            6
        )

    layout.Parent =
        list

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

        self:CreateLabel(
            list,
            "No jump detections recorded.",
            UDim2.new(
                1,
                -20,
                0,
                45
            ),
            UDim2.fromOffset(
                10,
                10
            ),
            12
        ).TextColor3 =
            Color3.fromRGB(
                120,
                120,
                120
            )

    else

        for i = #entries, 1, -1 do

            self:AddDetectionRow(
                list,
                entries[i],
                #entries - i + 1
            )
        end
    end

    task.defer(
        function()

            list.CanvasSize =
                UDim2.fromOffset(
                    0,
                    layout.AbsoluteContentSize.Y + 10
                )

        end
    )
end

--------------------------------------------------
-- MISC TAB
--------------------------------------------------

function ScannerCore:BuildMiscTab()

    local content =
        self.Content

    self:CreateLabel(
        content,
        "MISC",
        UDim2.new(
            1,
            -30,
            0,
            34
        ),
        UDim2.fromOffset(
            15,
            15
        ),
        19
    ).Font =
        Enum.Font.GothamBold

    self:CreateLabel(
        content,
        "GUI preferences",
        UDim2.new(
            1,
            -30,
            0,
            25
        ),
        UDim2.fromOffset(
            15,
            48
        ),
        11
    ).TextColor3 =
        Color3.fromRGB(
            145,
            145,
            145
        )

    --------------------------------------------------
    -- GUI SIZE
    --------------------------------------------------

    self:CreateLabel(
        content,
        "GUI SIZE",
        UDim2.new(
            1,
            -30,
            0,
            25
        ),
        UDim2.fromOffset(
            15,
            85
        ),
        12
    ).Font =
        Enum.Font.GothamMedium

    local small =
        self:CreateButton(
            content,
            "SMALL",
            UDim2.fromOffset(
                110,
                42
            ),
            UDim2.fromOffset(
                15,
                120
            )
        )

    local medium =
        self:CreateButton(
            content,
            "MEDIUM",
            UDim2.fromOffset(
                110,
                42
            ),
            UDim2.fromOffset(
                135,
                120
            )
        )

    local large =
        self:CreateButton(
            content,
            "LARGE",
            UDim2.fromOffset(
                110,
                42
            ),
            UDim2.fromOffset(
                255,
                120
            )
        )

    small.Activated:Connect(
        function()

            self.GuiSizeMode =
                "Small"

            self:UpdateGuiScale()
            self:RefreshGui()

        end
    )

    medium.Activated:Connect(
        function()

            self.GuiSizeMode =
                "Medium"

            self:UpdateGuiScale()
            self:RefreshGui()

        end
    )

    large.Activated:Connect(
        function()

            self.GuiSizeMode =
                "Large"

            self:UpdateGuiScale()
            self:RefreshGui()

        end
    )

    --------------------------------------------------
    -- CURRENT SIZE
    --------------------------------------------------

    self:CreateLabel(
        content,
        "CURRENT SIZE",
        UDim2.new(
            1,
            -30,
            0,
            25
        ),
        UDim2.fromOffset(
            15,
            185
        ),
        12
    ).Font =
        Enum.Font.GothamMedium

    local current =
        self:CreateLabel(
            content,
            self.GuiSizeMode,
            UDim2.new(
                1,
                -30,
                0,
                35
            ),
            UDim2.fromOffset(
                15,
                213
            ),
        13
    )

    current.TextColor3 =
        Color3.fromRGB(
            80,
            220,
            120
        )

    --------------------------------------------------
    -- MOBILE INFO
    --------------------------------------------------

    self:CreateLabel(
        content,
        "The interface automatically scales to fit your screen.",
        UDim2.new(
            1,
            -30,
            0,
            45
        ),
        UDim2.fromOffset(
            15,
            265
        ),
        11
    ).TextColor3 =
        Color3.fromRGB(
            130,
            130,
            130
        )

    self:CreateLabel(
        content,
        "You can drag the top bar to move the window.",
        UDim2.new(
            1,
            -30,
            0,
            45
        ),
        UDim2.fromOffset(
            15,
            310
        ),
        11
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

        self:BuildLoopTab()

    elseif self.ActiveTab == "Jump" then

        self:BuildJumpTab()

    elseif self.ActiveTab == "Misc" then

        self:BuildMiscTab()

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

    self.LoopScanner:Start()
    self.JumpScanner:Start()

    for _, player in ipairs(
        Players:GetPlayers()
    ) do

        if self:IsAdmin(player) then

            task.defer(
                function()

                    self:CreateGui(
                        player
                    )

                end
            )

        end
    end

    self.PlayerAddedConnection =
        Players.PlayerAdded:Connect(
            function(player)

                task.defer(
                    function()

                        if self:IsAdmin(
                            player
                        ) then

                            self:CreateGui(
                                player
                            )
                        end

                    end
                )

            end
        )

    self.PlayerRemovingConnection =
        Players.PlayerRemoving:Connect(
            function(player)

                self.Logs:ClearPlayer(
                    player.UserId
                )

                if self.LoopScanner
                    and self.LoopScanner.ResetPlayer then

                    self.LoopScanner:ResetPlayer(
                        player
                    )

                end

                if self.JumpScanner
                    and self.JumpScanner.ResetPlayer then

                    self.JumpScanner:ResetPlayer(
                        player
                    )

                end

                self:RefreshGui()
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

    self.Started = false

    self.LoopScanner:Stop()
    self.JumpScanner:Stop()

    if self.PlayerAddedConnection then

        self.PlayerAddedConnection:Disconnect()
        self.PlayerAddedConnection = nil

    end

    if self.PlayerRemovingConnection then

        self.PlayerRemovingConnection:Disconnect()
        self.PlayerRemovingConnection = nil

    end

    if self.ViewportConnection then

        self.ViewportConnection:Disconnect()
        self.ViewportConnection = nil

    end

    if self.Gui then

        self.Gui:Destroy()
        self.Gui = nil

    end

    self.Main = nil
    self.Content = nil
    self.GuiScale = nil

    print(
        "[AC-Checker] Scanner stopped."
    )
end

return ScannerCore
