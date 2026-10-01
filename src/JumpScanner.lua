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

    -- We have not yet measured the game's exact
    -- maximum jump height, so keep the existing
    -- conservative height threshold for now.
    self.MaxJumpHeight =
        config.MaxJumpHeight or 12

    -- Actual repeated live measurements:
    -- approximately 51.865 studs/sec upward.
    self.ExpectedJumpVelocity =
        config.ExpectedJumpVelocity or 51.865

    -- Small safety margin above the observed value.
    self.MaxUpwardVelocity =
        config.MaxUpwardVelocity or 53

    self.RequiredViolations =
        config.RequiredViolations or 2

    self.OnDetection =
        config.OnDetection

    self.States = {}

    self.Running = false
    self.Connection = nil

    return self
end

function JumpScanner:ResetPlayer(
    player
)

    self.States[player] = nil
end

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

            InAir = false,

            StartY =
                root.Position.Y,

            PeakUpwardVelocity = 0,

            Violations = 0,
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

    -- Detect the start of a jump.
    if airborne and not state.InAir then

        state.InAir = true

        state.StartY =
            root.Position.Y

        state.PeakUpwardVelocity = 0

        local velocity =
            root.AssemblyLinearVelocity.Y

        if velocity >
            state.PeakUpwardVelocity then

            state.PeakUpwardVelocity =
                velocity
        end

        return
    end

    -- While airborne, continuously track
    -- the highest upward velocity observed.
    if airborne and state.InAir then

        local velocity =
            root.AssemblyLinearVelocity.Y

        if velocity >
            state.PeakUpwardVelocity then

            state.PeakUpwardVelocity =
                velocity
        end

        return
    end

    -- The jump has ended.
    if not airborne and state.InAir then

        state.InAir = false

        local height =
            root.Position.Y -
            state.StartY

        local peakVelocity =
            state.PeakUpwardVelocity

        local velocityViolation =
            peakVelocity >
            self.MaxUpwardVelocity

        local heightViolation =
            height >
            self.MaxJumpHeight

        if velocityViolation
            or heightViolation then

            state.Violations += 1

            if state.Violations >=
                self.RequiredViolations then

                state.Violations = 0

                if self.OnDetection then

                    self.OnDetection({

                        Type = "Jump",

                        Player = player,

                        Height = height,

                        MaxHeight =
                            self.MaxJumpHeight,

                        PeakUpwardVelocity =
                            peakVelocity,

                        MaxUpwardVelocity =
                            self.MaxUpwardVelocity,

                        ExpectedJumpVelocity =
                            self.ExpectedJumpVelocity,

                        Time = os.time(),
                    })
                end
            end

        else

            state.Violations = 0
        end

        state.PeakUpwardVelocity = 0
    end
end

function JumpScanner:Start()

    if self.Running then
        return
    end

    self.Running = true

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

function JumpScanner:Stop()

    self.Running = false

    if self.Connection then

        self.Connection:Disconnect()
        self.Connection = nil

    end

    table.clear(
        self.States
    )
end

return JumpScanner
