local Players =
    game:GetService("Players")

local RunService =
    game:GetService("RunService")

local LoopScanner = {}
LoopScanner.__index = LoopScanner

function LoopScanner.new(config)

    config = config or {}

    local self =
        setmetatable({}, LoopScanner)

    self.BaseSpeed =
        config.BaseSpeed or 18

    self.SprintSpeed =
        config.SprintSpeed or 21

    -- Confirmed acceptable sprint spike range:
    -- 21.00 through 21.15.
    self.Tolerance =
        config.Tolerance or 0.15

    self.SampleInterval =
        config.SampleInterval or 0.15

    self.RequiredViolations =
        config.RequiredViolations or 3

    self.ViolationWindow =
        config.ViolationWindow or 1

    self.OnDetection =
        config.OnDetection

    self.LastPositions = {}
    self.LastTimes = {}

    self.ViolationCounts = {}
    self.LastViolationTimes = {}

    self.Running = false
    self.Connection = nil

    return self
end

--------------------------------------------------
-- SPRINT DETECTION
--------------------------------------------------

function LoopScanner:IsSprinting(
    player,
    humanoid
)

    if not humanoid then
        return false
    end

    local walkSpeed =
        humanoid.WalkSpeed

    -- Treat the confirmed sprint range as:
    -- 20.85 -> 21.15
    --
    -- This lets tiny legitimate WalkSpeed
    -- fluctuations around 21 count as sprint.
    local sprintMinimum =
        self.SprintSpeed -
        self.Tolerance

    local sprintMaximum =
        self.SprintSpeed +
        self.Tolerance

    if walkSpeed >= sprintMinimum
        and walkSpeed <= sprintMaximum then

        return true
    end

    return false
end

--------------------------------------------------
-- ALLOWED SPEED
--------------------------------------------------

function LoopScanner:GetAllowedSpeed(
    player,
    humanoid
)

    local sprinting =
        self:IsSprinting(
            player,
            humanoid
        )

    if sprinting then

        -- Exact requested rule:
        -- anything above 21.15 is suspicious.
        return self.SprintSpeed, true
    end

    return self.BaseSpeed, false
end

--------------------------------------------------
-- RESET
--------------------------------------------------

function LoopScanner:ResetPlayer(
    player
)

    self.LastPositions[player] = nil
    self.LastTimes[player] = nil

    self.ViolationCounts[player] = 0
    self.LastViolationTimes[player] = nil
end

--------------------------------------------------
-- CHECK PLAYER
--------------------------------------------------

function LoopScanner:CheckPlayer(
    player,
    currentTime
)

    local character =
        player.Character

    if not character then
        self:ResetPlayer(player)
        return
    end

    local humanoid =
        character:FindFirstChildOfClass(
            "Humanoid"
        )

    local root =
        character:FindFirstChild(
            "HumanoidRootPart"
        )

    if not humanoid or not root then
        self:ResetPlayer(player)
        return
    end

    if humanoid.Health <= 0 then
        self:ResetPlayer(player)
        return
    end

    local previousPosition =
        self.LastPositions[player]

    local previousTime =
        self.LastTimes[player]

    -- First sample.
    if not previousPosition
        or not previousTime then

        self.LastPositions[player] =
            root.Position

        self.LastTimes[player] =
            currentTime

        return
    end

    local deltaTime =
        currentTime -
        previousTime

    if deltaTime <
        self.SampleInterval then

        return
    end

    -- IMPORTANT:
    -- Only update the previous sample after
    -- the sample interval has elapsed.
    self.LastPositions[player] =
        root.Position

    self.LastTimes[player] =
        currentTime

    local displacement =
        root.Position -
        previousPosition

    -- Horizontal movement only.
    local horizontal =
        Vector3.new(
            displacement.X,
            0,
            displacement.Z
        )

    local distance =
        horizontal.Magnitude

    local speed =
        distance /
        deltaTime

    local limit, sprinting =
        self:GetAllowedSpeed(
            player,
            humanoid
        )

    local allowedSpeed =
        limit +
        self.Tolerance

    --------------------------------------------------
    -- NORMAL MOVEMENT
    --------------------------------------------------

    if speed <= allowedSpeed then

        self.ViolationCounts[player] =
            0

        self.LastViolationTimes[player] =
            nil

        return
    end

    --------------------------------------------------
    -- VIOLATION WINDOW
    --------------------------------------------------

    local lastViolation =
        self.LastViolationTimes[player]

    if not lastViolation
        or currentTime - lastViolation >
            self.ViolationWindow then

        self.ViolationCounts[player] =
            1

    else

        self.ViolationCounts[player] =
            (self.ViolationCounts[player] or 0) +
            1

    end

    self.LastViolationTimes[player] =
        currentTime

    --------------------------------------------------
    -- REQUIRED VIOLATIONS
    --------------------------------------------------

    if self.ViolationCounts[player] <
        self.RequiredViolations then

        return
    end

    self.ViolationCounts[player] =
        0

    --------------------------------------------------
    -- DETECTION
    --------------------------------------------------

    if self.OnDetection then

        self.OnDetection({

            Type =
                "Speed",

            Player =
                player,

            Speed =
                speed,

            Limit =
                limit,

            AllowedSpeed =
                allowedSpeed,

            Sprinting =
                sprinting,

            Time =
                os.time(),
        })

    end
end

--------------------------------------------------
-- START
--------------------------------------------------

function LoopScanner:Start()

    if self.Running then
        return
    end

    self.Running =
        true

    self.Connection =
        RunService.Heartbeat:Connect(
            function()

                if not self.Running then
                    return
                end

                local now =
                    os.clock()

                for _, player in ipairs(
                    Players:GetPlayers()
                ) do

                    self:CheckPlayer(
                        player,
                        now
                    )

                end
            end
        )

    print(
        "[AC-Checker] LoopScanner started."
    )
end

--------------------------------------------------
-- STOP
--------------------------------------------------

function LoopScanner:Stop()

    self.Running =
        false

    if self.Connection then

        self.Connection:Disconnect()

        self.Connection =
            nil
    end

    table.clear(
        self.LastPositions
    )

    table.clear(
        self.LastTimes
    )

    table.clear(
        self.ViolationCounts
    )

    table.clear(
        self.LastViolationTimes
    )
end

return LoopScanner
