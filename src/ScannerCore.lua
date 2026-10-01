--[[
    AC-Checker
    ScannerCore.lua

    Main controller + GUI.

    Tabs:
        LOOP DETECTION
        JUMP DETECTION
]]

local Players =
    game:GetService("Players")

local LocalPlayer =
    Players.LocalPlayer

local ScannerCore = {}
ScannerCore.__index = ScannerCore

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
    self.ActiveTab = "Loop"

    return self
end

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

function ScannerCore:HandleDetection(
    data
)

    self.Logs:Add(data)

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
        Instance.new(
            "TextLabel"
        )

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
        Instance.new(
            "TextButton"
        )

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

    button.Parent = parent

    return button
end

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
        Instance.new(
            "ScreenGui"
        )

    gui.Name =
        "ACCheckerGui"

    gui.ResetOnSpawn = false

    gui.Parent =
        playerGui

    self.Gui = gui

    local main =
        Instance.new("Frame")

    main.Name = "Main"

    main.Size =
        UDim2.fromOffset(
            720,
            430
        )

    main.Position =
        UDim2.new(
            0.5,
            -360,
            0.5,
            -215
        )

    main.BackgroundColor3 =
        Color3.fromRGB(
            17,
            17,
            17
        )

    main.BorderSizePixel = 0

    main.Parent = gui

    local title =
        self:CreateLabel(
            main,
            "AC-CHECKER",
            UDim2.new(
                1,
                -40,
                0,
                45
            ),
            UDim2.fromOffset(
                20,
                8
            ),
            22
        )

    title.Font =
        Enum.Font.GothamBold

    local status =
        self:CreateLabel(
            main,
            "● ONLINE",
            UDim2.fromOffset(
                120,
                30
            ),
            UDim2.new(
                1,
                -145,
                0,
                13
            ),
            13
        )

    status.TextXAlignment =
        Enum.TextXAlignment.Right

    status.TextColor3 =
        Color3.fromRGB(
            80,
            220,
            120
        )

    local sidebar =
        Instance.new("Frame")

    sidebar.Name =
        "Sidebar"

    sidebar.Size =
        UDim2.new(
            0,
            175,
            1,
            -65
        )

    sidebar.Position =
        UDim2.fromOffset(
            0,
            65
        )

    sidebar.BackgroundColor3 =
        Color3.fromRGB(
            22,
            22,
            22
        )

    sidebar.BorderSizePixel = 0

    sidebar.Parent = main

    self:CreateLabel(
        sidebar,
        "SCANNERS",
        UDim2.new(
            1,
            -30,
            0,
            30
        ),
        UDim2.fromOffset(
            15,
            15
        ),
        12
    ).TextColor3 =
        Color3.fromRGB(
            140,
            140,
            140
        )

    local loopButton =
        self:CreateButton(
            sidebar,
            "LOOP DETECTION",
            UDim2.new(
                1,
                -20,
                0,
                48
            ),
            UDim2.fromOffset(
                10,
                55
            )
        )

    local jumpButton =
        self:CreateButton(
            sidebar,
            "JUMP DETECTION",
            UDim2.new(
                1,
                -20,
                0,
                48
            ),
            UDim2.fromOffset(
                10,
                110
            )
        )

    loopButton.MouseButton1Click:Connect(
        function()

            self.ActiveTab =
                "Loop"

            self:RefreshGui()
        end
    )

    jumpButton.MouseButton1Click:Connect(
        function()

            self.ActiveTab =
                "Jump"

            self:RefreshGui()
        end
    )

    local content =
        Instance.new("Frame")

    content.Name =
        "Content"

    content.Size =
        UDim2.new(
            1,
            -195,
            1,
            -65
        )

    content.Position =
        UDim2.fromOffset(
            195,
            65
        )

    content.BackgroundTransparency = 1

    content.Parent = main

    self.Content =
        content

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
        Instance.new(
            "Frame"
        )

    row.Size =
        UDim2.new(
            1,
            -10,
            0,
            48
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

    local text

    if entry.Type == "Speed" then

        text =
            string.format(
                "%s\n%.2f studs/s  •  limit %.2f",

                entry.PlayerName,

                entry.Speed or 0,

                entry.Limit or 0
            )

    elseif entry.Type == "Jump" then

        text =
            string.format(
                "%s\n%.2f studs  •  max %.2f",

                entry.PlayerName,

                entry.Height or 0,

                entry.MaxHeight or 0
            )

    else

        text =
            entry.PlayerName

    end

    self:CreateLabel(
        row,
        text,
        UDim2.new(
            1,
            -20,
            1,
            0
        ),
        UDim2.fromOffset(
            10,
            0
        ),
        12
    )
end

--------------------------------------------------
-- REFRESH GUI
--------------------------------------------------

function ScannerCore:RefreshGui()

    local content =
        self.Content

    if not content then
        return
    end

    for _, child in ipairs(
        content:GetChildren()
    ) do

        child:Destroy()
    end

    local heading

    local subtitle

    local entries = {}

    for _, entry in ipairs(
        self.Logs:GetEntries()
    ) do

        if self.ActiveTab == "Loop"
            and entry.Type == "Speed" then

            table.insert(
                entries,
                entry
            )

        elseif self.ActiveTab == "Jump"
            and entry.Type == "Jump" then

            table.insert(
                entries,
                entry
            )
        end
    end

    if self.ActiveTab == "Loop" then

        heading =
            "LOOP DETECTION"

        subtitle =
            string.format(
                "Active scan  •  Normal %.1f studs/s  •  Sprint %.1f studs/s",

                self.Config.BaseSpeed,

                self.Config.SprintSpeed
            )

    else

        heading =
            "JUMP DETECTION"

        subtitle =
            "Active scan  •  Monitoring jump height and vertical movement"

    end

    self:CreateLabel(
        content,
        heading,
        UDim2.new(
            1,
            -30,
            0,
            35
        ),
        UDim2.fromOffset(
            15,
            15
        ),
        21
    ).Font =
        Enum.Font.GothamBold

    self:CreateLabel(
        content,
        subtitle,
        UDim2.new(
            1,
            -30,
            0,
            30
        ),
        UDim2.fromOffset(
            15,
            50
        ),
        12
    ).TextColor3 =
        Color3.fromRGB(
            145,
            145,
            145
        )

    local detectionsTitle =
        self:CreateLabel(
            content,
            "DETECTIONS",
            UDim2.new(
                1,
                -30,
                0,
                25
            ),
            UDim2.fromOffset(
                15,
                95
            ),
            12
        )

    detectionsTitle.TextColor3 =
        Color3.fromRGB(
            150,
            150,
            150
        )

    local list =
        Instance.new(
            "ScrollingFrame"
        )

    list.Name =
        "DetectionList"

    list.Size =
        UDim2.new(
            1,
            -30,
            1,
            -135
        )

    list.Position =
        UDim2.fromOffset(
            15,
            125
        )

    list.BackgroundColor3 =
        Color3.fromRGB(
            20,
            20,
            20
        )

    list.BorderSizePixel = 0

    list.ScrollBarThickness = 5

    list.CanvasSize =
        UDim2.new(
            0,
            0,
            0,
            #entries * 54
        )

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

    if #entries == 0 then

        local empty =
            self:CreateLabel(
                list,
                "No detections recorded.",
                UDim2.new(
                    1,
                    -20,
                    0,
                    40
                ),
                UDim2.fromOffset(
                    10,
                    10
                ),
                13
            )

        empty.TextColor3 =
            Color3.fromRGB(
                125,
                125,
                125
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
end

--------------------------------------------------
-- START / STOP
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

    Players.PlayerAdded:Connect(
        function(player)

            task.defer(
                function()

                    self:CreateGui(
                        player
                    )

                end
            )
        end
    )

    print(
        "[AC-Checker] Scanner started."
    )
end

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

    print(
        "[AC-Checker] Scanner stopped."
    )
end

return ScannerCore
