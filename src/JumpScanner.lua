local Players =
    game:GetService("Players")

local RunService =
    game:GetService("RunService")

local JumpScanner = {}
JumpScanner.__index = JumpScanner

function JumpScanner.new(config)

    config = config or {}

    local self =
        setmetatable({}, JumpScanner)

    -- Still retained as a secondary check.
    -- We have not yet measured exact legitimate
    -- maximum jump height.
    self.MaxJumpHeight =
        config.MaxJumpHeight or 12

    -- Repeated legitimate measurements:
    -- 51.86499786376953
    --
    -- Rounded reference:
    -- 51.865
    self.ExpectedJumpVelocity =
        config.ExpectedJumpVelocity or 51.865

    -- Detection threshold.
    --
    -- Legitimate measured peak:
    -- 51.865
    --
    -- Allowed margin:
    -- ~0.235
    --
    -- Anything above this is suspicious.
    self.MaxUpwardVelocity =
        config.MaxUpwardVelocity or 52.1

    -- One abnormal jump is enough.
    self.RequiredViolations =
        config.RequiredViolations or 1

    self.OnDetection =
        config.OnDetection

    self.States =
        {}

    self.Running =
        false

    self.Connection =
        nil

    return self
end

--------------------------------------------------
-- RESET
--------------------------------------------------

function JumpScanner:ResetPlayer(
    player
)

    self.States[player] =
        nil
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

    local state =
        self.States[player]

    if not state then

        state = {

            InAir =
                false,

            StartY =
                root.Position.Y,

            PeakUpwardVelocity =
                0,

            Violations =
                0,
        }

        self.States[player] =
            state
    end

    local humanoidState =
        humanoid:GetState()

    local airborne =
        humanoidState ==
            Enum.HumanoidStateType.Jumping
        or
        humanoidState ==
            Enum.HumanoidStateType.Freefall

    --------------------------------------------------
    -- JUMP START
    --------------------------------------------------

    if airborne
        and not state.InAir then

        state.InAir =
            true

        state.StartY =
            root.Position.Y

        state.PeakUpwardVelocity =
            0

        local velocity =
            root.AssemblyLinearVelocity.Y

        if velocity >
            state.PeakUpwardVelocity then

            state.PeakUpwardVelocity =
                velocity

        end

        return
    end

    --------------------------------------------------
    -- TRACK PEAK WHILE AIRBORNE
    --------------------------------------------------

    if airborne
        and state.InAir then

        local velocity =
            root.AssemblyLinearVelocity.Y

        if velocity >
            state.PeakUpwardVelocity then

            state.PeakUpwardVelocity =
                velocity

        end

        return
    end

    --------------------------------------------------
    -- LANDING
    --------------------------------------------------

    if not airborne
        and state.InAir then

        state.InAir =
            false

        local height =
            root.Position.Y -
            state.StartY

        local peakVelocity =
            state.PeakUpwardVelocity

        --------------------------------------------------
        -- VELOCITY CHECK
        --------------------------------------------------

        local velocityViolation =
            peakVelocity >
            self.MaxUpwardVelocity

        --------------------------------------------------
        -- HEIGHT CHECK
        --------------------------------------------------

        local heightViolation =
            height >
            self.MaxJumpHeight

        --------------------------------------------------
        -- FINAL RESULT
        --------------------------------------------------

        if velocityViolation
            or heightViolation then

            state.Violations +=
                1

        else

            state.Violations =
                0

        end

        --------------------------------------------------
        -- DETECTION
        --------------------------------------------------

        if state.Violations >=
            self.RequiredViolations then

            state.Violations =
                0

            if self.OnDetection then

                self.OnDetection({

                    Type =
                        "Jump",

                    Player =
                        player,

                    Height =
                        height,

                    MaxHeight =
                        self.MaxJumpHeight,

                    PeakUpwardVelocity =
                        peakVelocity,

                    MaxUpwardVelocity =
                        self.MaxUpwardVelocity,

                    ExpectedJumpVelocity =
                        self.ExpectedJumpVelocity,

                    Time =
                        os.time(),
                })

            end
        end

        --------------------------------------------------
        -- RESET PEAK
        --------------------------------------------------

        state.PeakUpwardVelocity =
            0
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
        RunService.Heartbeat:Connect(
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
