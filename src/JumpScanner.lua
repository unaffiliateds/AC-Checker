local Players =
    game:GetService("Players")

local RunService =
    game:GetService("RunService")

local ReplicatedStorage =
    game:GetService("ReplicatedStorage")

local JumpScanner = {}
JumpScanner.__index = JumpScanner

function JumpScanner.new(config)

    config = config or {}

    local self =
        setmetatable({}, JumpScanner)

    --------------------------------------------------
    -- CONFIRMED GAME VALUES
    --------------------------------------------------

    -- Game's replicated custom jump value.
    self.ExpectedGameJumpPower =
        config.ExpectedGameJumpPower or 53.5

    -- Repeated legitimate measured peak.
    self.ExpectedJumpVelocity =
        config.ExpectedJumpVelocity or 51.865

    -- Anything above this measured physical
    -- velocity is suspicious.
    self.MaxUpwardVelocity =
        config.MaxUpwardVelocity or 52.1

    -- Retained as a secondary physical check.
    -- Exact legitimate max height still needs
    -- to be measured.
    self.MaxJumpHeight =
        config.MaxJumpHeight or 12

    --------------------------------------------------
    -- HUMANOID BASELINE
    --
    -- The live game currently has:
    -- UseJumpPower = false
    -- JumpPower = 0
    -- JumpHeight = 0
    --------------------------------------------------

    self.ExpectedUseJumpPower =
        false

    self.ExpectedHumanoidJumpPower =
        0

    self.ExpectedHumanoidJumpHeight =
        0

    --------------------------------------------------
    -- CALLBACK
    --------------------------------------------------

    self.OnDetection =
        config.OnDetection

    --------------------------------------------------
    -- STATE
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
-- RESET
--------------------------------------------------

function JumpScanner:ResetPlayer(
    player
)

    self.States[player] =
        nil
end

--------------------------------------------------
-- GET GAME JUMP POWER
--------------------------------------------------

function JumpScanner:GetGameJumpPower()

    local gameConstants =
        ReplicatedStorage:
        FindFirstChild(
            "GameConstants"
        )

    if gameConstants then

        local value =
            gameConstants:
            FindFirstChild(
                "JumpPower"
            )

        if value
            and value:IsA(
                "NumberValue"
            ) then

            return value.Value
        end
    end

    return nil
end

--------------------------------------------------
-- REPORT DETECTION
--------------------------------------------------

function JumpScanner:Detect(
    player,
    reason,
    data
)

    if not self.OnDetection then
        return
    end

    data =
        data or {}

    self.OnDetection({

        Type =
            "Jump",

        Player =
            player,

        Height =
            data.Height or 0,

        MaxHeight =
            self.MaxJumpHeight,

        PeakUpwardVelocity =
            data.PeakUpwardVelocity or 0,

        MaxUpwardVelocity =
            self.MaxUpwardVelocity,

        ExpectedJumpVelocity =
            self.ExpectedJumpVelocity,

        ExpectedGameJumpPower =
            self.ExpectedGameJumpPower,

        Reason =
            reason,

        Time =
            os.time(),
    })
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

    --------------------------------------------------
    -- DIRECT HUMANOID CHECK
    --
    -- Your game uses custom jump logic, so the normal
    -- Humanoid jump properties are expected to remain:
    --
    -- UseJumpPower = false
    -- JumpPower = 0
    -- JumpHeight = 0
    --
    -- A change to those properties is suspicious.
    --------------------------------------------------

    if humanoid.UseJumpPower ~=
        self.ExpectedUseJumpPower then

        self:Detect(
            player,
            "Humanoid.UseJumpPower"
        )

        return
    end

    if math.abs(
        humanoid.JumpPower -
        self.ExpectedHumanoidJumpPower
    ) > 0.01 then

        self:Detect(
            player,
            "Humanoid.JumpPower"
        )

        return
    end

    if math.abs(
        humanoid.JumpHeight -
        self.ExpectedHumanoidJumpHeight
    ) > 0.01 then

        self:Detect(
            player,
            "Humanoid.JumpHeight"
        )

        return
    end

    --------------------------------------------------
    -- DIRECT GAME-CONFIG CHECK
    --
    -- Expected custom game JumpPower = 53.5.
    --
    -- This catches a modified GameConstants value
    -- even when Humanoid.UseJumpPower is false.
    --------------------------------------------------

    local configuredJumpPower =
        self:GetGameJumpPower()

    if configuredJumpPower
        and math.abs(
            configuredJumpPower -
            self.ExpectedGameJumpPower
        ) > 0.01 then

        self:Detect(
            player,
            "GameConstants.JumpPower"
        )

        return
    end

    --------------------------------------------------
    -- STATE
    --------------------------------------------------

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
        }

        self.States[player] =
            state
    end

    --------------------------------------------------
    -- HUMANOID STATE
    --------------------------------------------------

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
            math.max(
                0,
                root.AssemblyLinearVelocity.Y
            )

        return
    end

    --------------------------------------------------
    -- TRACK PEAK
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
        -- PHYSICAL VELOCITY CHECK
        --------------------------------------------------

        if peakVelocity >
            self.MaxUpwardVelocity then

            self:Detect(

                player,

                "PeakUpwardVelocity",

                {
                    Height =
                        height,

                    PeakUpwardVelocity =
                        peakVelocity,
                }
            )

            state.PeakUpwardVelocity =
                0

            return
        end

        --------------------------------------------------
        -- PHYSICAL HEIGHT CHECK
        --------------------------------------------------

        if height >
            self.MaxJumpHeight then

            self:Detect(

                player,

                "JumpHeight",

                {
                    Height =
                        height,

                    PeakUpwardVelocity =
                        peakVelocity,
                }
            )

            state.PeakUpwardVelocity =
                0

            return
        end

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
