local Players =
    game:GetService("Players")

local RunService =
    game:GetService("RunService")

local ReplicatedStorage =
    game:GetService("ReplicatedStorage")

local JumpScanner = {}
JumpScanner.__index = JumpScanner

--------------------------------------------------
-- CONFIRMED GAME PHYSICS
--
-- Measurements collected from the live game:
--
-- Normal gravity:
--     196.1999969482422
--
-- Normal peak velocity:
--     51.86499786376953
--     52.6824951171875
--
-- Normal maximum height:
--     6.746048927307129
--     6.963662147521973
--
-- JP55:
--     peak velocity = 53.36499786376953
--     height        = 7.145662307739258
--
-- Gravity 190:
--     peak velocity = 51.916664123535156
--     height        ≈ 6.984
--------------------------------------------------

local DEFAULT_REFERENCE_GRAVITY =
    196.1999969482422

local DEFAULT_NORMAL_MAX_HEIGHT =
    6.963662147521973

local DEFAULT_NORMAL_MAX_VELOCITY =
    52.6824951171875

--------------------------------------------------
-- CONSTRUCTOR
--------------------------------------------------

function JumpScanner.new(config)

    config =
        config or {}

    local self =
        setmetatable(
            {},
            JumpScanner
        )

    --------------------------------------------------
    -- ENVIRONMENT BASELINE
    --------------------------------------------------

    self.ReferenceGravity =
        config.ReferenceGravity
        or DEFAULT_REFERENCE_GRAVITY

    self.ReferenceMaxHeight =
        config.ReferenceMaxHeight
        or DEFAULT_NORMAL_MAX_HEIGHT

    self.ReferenceMaxVelocity =
        config.ReferenceMaxVelocity
        or DEFAULT_NORMAL_MAX_VELOCITY

    --------------------------------------------------
    -- PHYSICAL DETECTION LIMITS
    --
    -- These are deliberately above the highest
    -- legitimate measurements we observed.
    --------------------------------------------------

    self.MaxUpwardVelocity =
        config.MaxUpwardVelocity
        or 53.0

    self.MaxNormalizedHeight =
        config.MaxNormalizedHeight
        or 7.05

    --------------------------------------------------
    -- DIRECT HUMANOID BASELINE
    --
    -- Confirmed game behavior:
    --
    -- UseJumpPower = false
    -- JumpPower    = 0
    -- JumpHeight   = 0
    --------------------------------------------------

    self.ExpectedUseJumpPower =
        false

    self.ExpectedHumanoidJumpPower =
        0

    self.ExpectedHumanoidJumpHeight =
        0

    --------------------------------------------------
    -- DETECTION BEHAVIOR
    --------------------------------------------------

    -- One jump with BOTH velocity and height
    -- violations is strong enough to detect immediately.
    self.RequiredStrongViolations =
        config.RequiredStrongViolations
        or 1

    -- One-signal anomalies require repetition.
    self.RequiredWeakViolations =
        config.RequiredWeakViolations
        or 2

    self.ViolationWindow =
        config.ViolationWindow
        or 2

    --------------------------------------------------
    -- CALLBACK
    --------------------------------------------------

    self.OnDetection =
        config.OnDetection

    --------------------------------------------------
    -- PLAYER STATE
    --------------------------------------------------

    self.States =
        {}

    self.Running =
        false

    self.Connection =
        nil

    return self
end

--------------------------------------------------
-- RESET PLAYER
--------------------------------------------------

function JumpScanner:ResetPlayer(
    player
)

    self.States[player] =
        nil
end

--------------------------------------------------
-- GAME JUMP POWER
--
-- This is INFORMATIONAL.
--
-- We deliberately do NOT treat a global GameConstants
-- value as an individual cheat violation.
--------------------------------------------------

function JumpScanner:GetGameJumpPower()

    local gameConstants =
        ReplicatedStorage:
            FindFirstChild(
                "GameConstants"
            )

    if not gameConstants then
        return nil
    end

    local jumpPower =
        gameConstants:
            FindFirstChild(
                "JumpPower"
            )

    if jumpPower
        and jumpPower:IsA(
            "NumberValue"
        ) then

        return jumpPower.Value
    end

    return nil
end

--------------------------------------------------
-- CREATE STATE
--------------------------------------------------

function JumpScanner:CreateState(
    player,
    root
)

    local state = {

        --------------------------------------------------
        -- AIRBORNE STATE
        --------------------------------------------------

        InAir =
            false,

        --------------------------------------------------
        -- JUMP MEASUREMENT
        --------------------------------------------------

        StartY =
            root.Position.Y,

        PeakY =
            root.Position.Y,

        PeakUpwardVelocity =
            0,

        StartTime =
            0,

        --------------------------------------------------
        -- ENVIRONMENT SNAPSHOT
        --------------------------------------------------

        StartGravity =
            workspace.Gravity,

        EndGravity =
            workspace.Gravity,

        GravityChanged =
            false,

        --------------------------------------------------
        -- HUMANOID SNAPSHOT
        --------------------------------------------------

        StartUseJumpPower =
            false,

        StartHumanoidJumpPower =
            0,

        StartHumanoidJumpHeight =
            0,

        --------------------------------------------------
        -- VIOLATION STATE
        --------------------------------------------------

        WeakViolations =
            0,

        LastViolationTime =
            0,
    }

    self.States[player] =
        state

    return state
end

--------------------------------------------------
-- PLAYER-SPECIFIC PROPERTY CHECK
--------------------------------------------------

function JumpScanner:CheckHumanoidProperties(
    player,
    humanoid
)

    --------------------------------------------------
    -- USE JUMP POWER
    --------------------------------------------------

    if humanoid.UseJumpPower ~=
        self.ExpectedUseJumpPower then

        if self.OnDetection then

            self.OnDetection({

                Type =
                    "Jump",

                Player =
                    player,

                Height =
                    0,

                MaxHeight =
                    self.ReferenceMaxHeight,

                PeakUpwardVelocity =
                    0,

                MaxUpwardVelocity =
                    self.MaxUpwardVelocity,

                ExpectedJumpVelocity =
                    self.ReferenceMaxVelocity,

                ExpectedGameJumpPower =
                    self:GetGameJumpPower(),

                Reason =
                    "Humanoid.UseJumpPower",

                Time =
                    os.time(),
            })

        end

        return true
    end

    --------------------------------------------------
    -- HUMANOID JUMP POWER
    --------------------------------------------------

    if math.abs(
        humanoid.JumpPower -
        self.ExpectedHumanoidJumpPower
    ) > 0.01 then

        if self.OnDetection then

            self.OnDetection({

                Type =
                    "Jump",

                Player =
                    player,

                Height =
                    0,

                MaxHeight =
                    self.ReferenceMaxHeight,

                PeakUpwardVelocity =
                    0,

                MaxUpwardVelocity =
                    self.MaxUpwardVelocity,

                ExpectedJumpVelocity =
                    self.ReferenceMaxVelocity,

                ExpectedGameJumpPower =
                    self:GetGameJumpPower(),

                Reason =
                    "Humanoid.JumpPower",

                Time =
                    os.time(),
            })

        end

        return true
    end

    --------------------------------------------------
    -- HUMANOID JUMP HEIGHT
    --------------------------------------------------

    if math.abs(
        humanoid.JumpHeight -
        self.ExpectedHumanoidJumpHeight
    ) > 0.01 then

        if self.OnDetection then

            self.OnDetection({

                Type =
                    "Jump",

                Player =
                    player,

                Height =
                    0,

                MaxHeight =
                    self.ReferenceMaxHeight,

                PeakUpwardVelocity =
                    0,

                MaxUpwardVelocity =
                    self.MaxUpwardVelocity,

                ExpectedJumpVelocity =
                    self.ReferenceMaxVelocity,

                ExpectedGameJumpPower =
                    self:GetGameJumpPower(),

                Reason =
                    "Humanoid.JumpHeight",

                Time =
                    os.time(),
            })

        end

        return true
    end

    return false
end

--------------------------------------------------
-- START JUMP
--------------------------------------------------

function JumpScanner:StartJump(
    player,
    humanoid,
    root,
    state
)

    state.InAir =
        true

    state.StartY =
        root.Position.Y

    state.PeakY =
        root.Position.Y

    state.PeakUpwardVelocity =
        math.max(
            0,
            root.AssemblyLinearVelocity.Y
        )

    state.StartTime =
        os.clock()

    --------------------------------------------------
    -- CAPTURE GLOBAL PHYSICS AT JUMP START
    --------------------------------------------------

    state.StartGravity =
        workspace.Gravity

    state.EndGravity =
        state.StartGravity

    state.GravityChanged =
        false

    --------------------------------------------------
    -- CAPTURE HUMANOID STATE
    --------------------------------------------------

    state.StartUseJumpPower =
        humanoid.UseJumpPower

    state.StartHumanoidJumpPower =
        humanoid.JumpPower

    state.StartHumanoidJumpHeight =
        humanoid.JumpHeight
end

--------------------------------------------------
-- TRACK JUMP
--------------------------------------------------

function JumpScanner:TrackJump(
    state,
    root
)

    local currentY =
        root.Position.Y

    local velocityY =
        root.AssemblyLinearVelocity.Y

    --------------------------------------------------
    -- PEAK HEIGHT
    --------------------------------------------------

    if currentY >
        state.PeakY then

        state.PeakY =
            currentY
    end

    --------------------------------------------------
    -- PEAK UPWARD VELOCITY
    --------------------------------------------------

    if velocityY >
        state.PeakUpwardVelocity then

        state.PeakUpwardVelocity =
            velocityY
    end

    --------------------------------------------------
    -- WATCH GRAVITY
    --------------------------------------------------

    state.EndGravity =
        workspace.Gravity

    if math.abs(
        state.EndGravity -
        state.StartGravity
    ) > 0.001 then

        state.GravityChanged =
            true
    end
end

--------------------------------------------------
-- NORMALIZE HEIGHT FOR GRAVITY
--
-- If gravity changes globally:
--
--     normal jump height changes too.
--
-- Multiplying the observed height by:
--
--     CurrentGravity / ReferenceGravity
--
-- brings it back into the reference environment.
--
-- Example:
--
-- 190 gravity jump:
--     ~6.984 studs
--
-- normalized:
--     ~6.764 studs
--
-- which remains inside the normal range.
--------------------------------------------------

function JumpScanner:NormalizeHeight(
    height,
    gravity
)

    if gravity <= 0 then
        return height
    end

    return
        height *
        (
            gravity /
            self.ReferenceGravity
        )
end

--------------------------------------------------
-- FINISH JUMP
--------------------------------------------------

function JumpScanner:FinishJump(
    player,
    humanoid,
    root,
    state
)

    state.InAir =
        false

    --------------------------------------------------
    -- FINAL VALUES
    --------------------------------------------------

    local height =
        state.PeakY -
        state.StartY

    local airtime =
        math.max(
            0,
            os.clock() -
            state.StartTime
        )

    local peakVelocity =
        state.PeakUpwardVelocity

    local gravity =
        state.StartGravity

    local normalizedHeight =
        self:NormalizeHeight(
            height,
            gravity
        )

    --------------------------------------------------
    -- IGNORE A JUMP IF GLOBAL GRAVITY CHANGED
    -- DURING THAT SAME JUMP.
    --
    -- The next jump will use the new gravity.
    --------------------------------------------------

    if state.GravityChanged then

        state.PeakY =
            root.Position.Y

        state.PeakUpwardVelocity =
            0

        state.StartTime =
            0

        return
    end

    --------------------------------------------------
    -- PHYSICAL CHECKS
    --------------------------------------------------

    local velocityViolation =
        peakVelocity >
        self.MaxUpwardVelocity

    local heightViolation =
        normalizedHeight >
        self.MaxNormalizedHeight

    local strongViolation =
        velocityViolation
        and
        heightViolation

    --------------------------------------------------
    -- DIRECT HUMANOID CHECK AT JUMP END
    --------------------------------------------------

    local directPropertyViolation =
        (
            humanoid.UseJumpPower ~=
            self.ExpectedUseJumpPower
        )
        or
        (
            math.abs(
                humanoid.JumpPower -
                self.ExpectedHumanoidJumpPower
            ) > 0.01
        )
        or
        (
            math.abs(
                humanoid.JumpHeight -
                self.ExpectedHumanoidJumpHeight
            ) > 0.01
        )

    --------------------------------------------------
    -- STRONG PHYSICAL VIOLATION
    --
    -- Both height AND velocity exceed the
    -- legitimate envelope.
    --------------------------------------------------

    if strongViolation then

        state.WeakViolations =
            0

        state.LastViolationTime =
            os.clock()

        if self.OnDetection then

            self.OnDetection({

                Type =
                    "Jump",

                Player =
                    player,

                Height =
                    height,

                NormalizedHeight =
                    normalizedHeight,

                MaxHeight =
                    self.MaxNormalizedHeight,

                PeakUpwardVelocity =
                    peakVelocity,

                MaxUpwardVelocity =
                    self.MaxUpwardVelocity,

                ExpectedJumpVelocity =
                    self.ReferenceMaxVelocity,

                Gravity =
                    gravity,

                AirborneDuration =
                    airtime,

                ExpectedGameJumpPower =
                    self:GetGameJumpPower(),

                Reason =
                    "AbnormalJumpPhysics",

                Time =
                    os.time(),
            })

        end

        return
    end

    --------------------------------------------------
    -- DIRECT PROPERTY VIOLATION
    --------------------------------------------------

    if directPropertyViolation then

        state.WeakViolations =
            0

        state.LastViolationTime =
            os.clock()

        if self.OnDetection then

            self.OnDetection({

                Type =
                    "Jump",

                Player =
                    player,

                Height =
                    height,

                NormalizedHeight =
                    normalizedHeight,

                MaxHeight =
                    self.MaxNormalizedHeight,

                PeakUpwardVelocity =
                    peakVelocity,

                MaxUpwardVelocity =
                    self.MaxUpwardVelocity,

                ExpectedJumpVelocity =
                    self.ReferenceMaxVelocity,

                Gravity =
                    gravity,

                AirborneDuration =
                    airtime,

                ExpectedGameJumpPower =
                    self:GetGameJumpPower(),

                Reason =
                    "HumanoidJumpProperty",

                Time =
                    os.time(),
            })

        end

        return
    end

    --------------------------------------------------
    -- WEAK SINGLE-SIGNAL VIOLATION
    --
    -- Only one of:
    --
    --   velocity
    --   height
    --
    -- is above the threshold.
    --
    -- Require repetition to avoid false positives.
    --------------------------------------------------

    if velocityViolation
        or heightViolation then

        local now =
            os.clock()

        if now -
            state.LastViolationTime >
                self.ViolationWindow then

            state.WeakViolations =
                1

        else

            state.WeakViolations +=
                1

        end

        state.LastViolationTime =
            now

        if state.WeakViolations >= 2 then

            state.WeakViolations =
                0

            if self.OnDetection then

                self.OnDetection({

                    Type =
                        "Jump",

                    Player =
                        player,

                    Height =
                        height,

                    NormalizedHeight =
                        normalizedHeight,

                    MaxHeight =
                        self.MaxNormalizedHeight,

                    PeakUpwardVelocity =
                        peakVelocity,

                    MaxUpwardVelocity =
                        self.MaxUpwardVelocity,

                    ExpectedJumpVelocity =
                        self.ReferenceMaxVelocity,

                    Gravity =
                        gravity,

                    AirborneDuration =
                        airtime,

                    ExpectedGameJumpPower =
                        self:GetGameJumpPower(),

                    Reason =
                        "RepeatedAbnormalJumpPhysics",

                    Time =
                        os.time(),
                })

            end
        end

        return
    end

    --------------------------------------------------
    -- NORMAL JUMP
    --------------------------------------------------

    state.WeakViolations =
        0
end

--------------------------------------------------
-- CHECK PLAYER
--------------------------------------------------

function JumpScanner:CheckPlayer(
    player
)

    local character =
        player.Character

    if not character then

        self:ResetPlayer(
            player
        )

        return
    end

    local humanoid =
        character:
            FindFirstChildOfClass(
                "Humanoid"
            )

    local root =
        character:
            FindFirstChild(
                "HumanoidRootPart"
            )

    if not humanoid
        or not root then

        self:ResetPlayer(
            player
        )

        return
    end

    if humanoid.Health <= 0 then

        self:ResetPlayer(
            player
        )

        return
    end

    --------------------------------------------------
    -- STATE
    --------------------------------------------------

    local state =
        self.States[player]

    if not state then

        state =
            self:CreateState(
                player,
                root
            )

    end

    --------------------------------------------------
    -- DIRECT PROPERTY CHECK
    --
    -- Only do this while the player is grounded.
    -- During a jump, physics changes are evaluated
    -- together when the jump finishes.
    --------------------------------------------------

    local humanoidState =
        humanoid:GetState()

    local airborne =
        humanoidState ==
            Enum.HumanoidStateType.Jumping
        or
        humanoidState ==
            Enum.HumanoidStateType.Freefall

    if not airborne
        and not state.InAir then

        self:CheckHumanoidProperties(
            player,
            humanoid
        )

    end

    --------------------------------------------------
    -- START / TRACK / FINISH
    --------------------------------------------------

    if airborne
        and not state.InAir then

        self:StartJump(
            player,
            humanoid,
            root,
            state
        )

        return
    end

    if airborne
        and state.InAir then

        self:TrackJump(
            state,
            root
        )

        return
    end

    if not airborne
        and state.InAir then

        self:FinishJump(
            player,
            humanoid,
            root,
            state
        )

    end
end

--------------------------------------------------
-- START
--------------------------------------------------

function JumpScanner:Start()

    if self.Running then
        return
    end

    self.Running =
        true

    self.Connection =
        RunService.Heartbeat:
        Connect(
            function()

                if not self.Running then
                    return
                end

                for _, player in ipairs(
                    Players:GetPlayers()
                ) do

                    self:CheckPlayer(
                        player
                    )

                end
            end
        )

    print(
        "[AC-Checker] JumpScanner started."
    )
end

--------------------------------------------------
-- STOP
--------------------------------------------------

function JumpScanner:Stop()

    self.Running =
        false

    if self.Connection then

        self.Connection:Disconnect()

        self.Connection =
            nil
    end

    table.clear(
        self.States
    )
end

return JumpScanner
