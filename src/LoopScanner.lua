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

    --------------------------------------------------
    -- CONFIRMED GAME VALUES
    --------------------------------------------------

    self.BaseSpeed =
        config.BaseSpeed or 18

    self.SprintSpeed =
        config.SprintSpeed or 21

    -- 21.00 -> 21.15 is allowed.
    -- Anything above 21.15 is suspicious.
    self.MaxAllowedSpeed =
        config.MaxAllowedSpeed or 21.15

    self.Tolerance =
        config.Tolerance or 0.15

    --------------------------------------------------
    -- MOVEMENT SAMPLING
    --------------------------------------------------

    self.SampleInterval =
        config.SampleInterval or 0.15

    self.RequiredViolations =
        config.RequiredViolations or 3

    self.ViolationWindow =
        config.ViolationWindow or 1

    --------------------------------------------------
    -- CALLBACK
    --------------------------------------------------

    self.OnDetection =
        config.OnDetection

    --------------------------------------------------
    -- STATE
    --------------------------------------------------

    self.LastPositions = {}
    self.LastTimes = {}

    self.ViolationCounts = {}
    self.LastViolationTimes = {}

    self.WalkSpeedViolations = {}

    self.Running = false
    self.Connection = nil

    return self
end

--------------------------------------------------
-- SPRINT CHECK
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

    return
        walkSpeed >=
            (self.SprintSpeed - self.Tolerance)
        and
        walkSpeed <=
            self.MaxAllowedSpeed
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

    self.WalkSpeedViolations[player] = 0
end

--------------------------------------------------
-- DETECTION
--------------------------------------------------

function LoopScanner:Detect(
    player,
    speed,
    limit,
    sprinting,
    reason
)

    if not self.OnDetection then
        return
    end

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
            self.MaxAllowedSpeed,

        Sprinting =
            sprinting,

        Reason =
            reason,

        Time =
            os.time(),
    })
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

    --------------------------------------------------
    -- DIRECT WALKSPEED CHECK
    --
    -- This is the important fix.
    -- We directly inspect the live Humanoid
    -- instead of relying only on displacement.
    --------------------------------------------------

    local walkSpeed =
        humanoid.WalkSpeed

    local sprinting =
        self:IsSprinting(
            player,
            humanoid
        )

    if walkSpeed >
        self.MaxAllowedSpeed then

        self.WalkSpeedViolations[player] =
            (self.WalkSpeedViolations[player] or 0) +
            1

        -- One direct property violation is enough
        -- because the property itself is explicit.
        if self.WalkSpeedViolations[player] >= 1 then

            self.WalkSpeedViolations[player] = 0

            self:Detect(

                player,

                walkSpeed,

                self.SprintSpeed,

                sprinting,

                "Humanoid.WalkSpeed"
            )

        end

    else

        self.WalkSpeedViolations[player] =
            0

    end

    --------------------------------------------------
    -- MOVEMENT-BASED CHECK
    --
    -- Keeps protection against movement that exceeds
    -- the allowed speed even when WalkSpeed itself
    -- has not been changed.
    --------------------------------------------------

    local previousPosition =
        self.LastPositions[player]

    local previousTime =
        self.LastTimes[player]

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

    self.LastPositions[player] =
        root.Position

    self.LastTimes[player] =
        currentTime

    local displacement =
        root.Position -
        previousPosition

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

    --------------------------------------------------
    -- MOVEMENT WITHIN LIMIT
    --------------------------------------------------

    if speed <=
        self.MaxAllowedSpeed then

        self.ViolationCounts[player] =
            0

        self.LastViolationTimes[player] =
            nil

        return
    end

    --------------------------------------------------
    -- MOVEMENT VIOLATION
    --------------------------------------------------

    local lastViolation =
        self.LastViolationTimes[player]

    if not lastViolation
        or
        currentTime -
            lastViolation >
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

    if self.ViolationCounts[player] <
        self.RequiredViolations then

        return
    end

    self.ViolationCounts[player] =
        0

    self:Detect(

        player,

        speed,

        self.SprintSpeed,

        sprinting,

        "Movement"
    )
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

    table.clear(
        self.WalkSpeedViolations
    )
end

return LoopScanner
