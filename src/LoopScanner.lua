--[[
    AC-Checker
    LoopScanner.lua

    Server-side horizontal movement detector.

    Intended limits:

        Normal = 18 studs/sec
        Sprint = 21 studs/sec

    A tolerance is applied to reduce false positives caused
    by normal Roblox physics/network variance.

    A player must exceed the limit for several consecutive
    samples before a detection is generated.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LoopScanner = {}
LoopScanner.__index = LoopScanner

function LoopScanner.new(config)
	config = config or {}

	local self = setmetatable({}, LoopScanner)

	self.BaseSpeed = config.BaseSpeed or 18
	self.SprintSpeed = config.SprintSpeed or 21

	self.Tolerance = config.Tolerance or 1.25

	self.SampleInterval = config.SampleInterval or 0.15

	-- Number of consecutive over-limit samples required.
	self.RequiredViolations = config.RequiredViolations or 3

	-- Maximum amount of time between violations before
	-- the counter is reset.
	self.ViolationWindow = config.ViolationWindow or 1.0

	self.OnDetection = config.OnDetection

	self.LastPositions = {}
	self.LastSampleTimes = {}

	self.ViolationCounts = {}
	self.LastViolationTimes = {}

	self.Running = false
	self.Connection = nil

	return self
end

function LoopScanner:IsSprinting(player, humanoid)
	-- Preferred method:
	-- Your server-side sprint system should set:
	--
	-- player:SetAttribute("Sprinting", true)
	--
	-- and false when sprinting ends.

	if player:GetAttribute("Sprinting") == true then
		return true
	end

	-- Optional BoolValue support.

	local sprintValue = player:FindFirstChild("Sprinting")

	if sprintValue and sprintValue:IsA("BoolValue") then
		return sprintValue.Value
	end

	-- Basic testing fallback.
	--
	-- This is useful while we're building/testing, but later
	-- we'll connect this to the actual sprint system.

	if humanoid and humanoid.WalkSpeed > self.BaseSpeed then
		return true
	end

	return false
end

function LoopScanner:GetAllowedSpeed(player, humanoid)
	local sprinting = self:IsSprinting(player, humanoid)

	if sprinting then
		return self.SprintSpeed, true
	end

	return self.BaseSpeed, false
end

function LoopScanner:ResetPlayer(player)
	self.LastPositions[player] = nil
	self.LastSampleTimes[player] = nil

	self.ViolationCounts[player] = 0
	self.LastViolationTimes[player] = nil
end

function LoopScanner:ProcessPlayer(player, currentTime)
	local character = player.Character

	if not character then
		self:ResetPlayer(player)
		return
	end

	local humanoid =
		character:FindFirstChildOfClass("Humanoid")

	local root =
		character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not root then
		self:ResetPlayer(player)
		return
	end

	if humanoid.Health <= 0 then
		self:ResetPlayer(player)
		return
	end

	-- Store the previous position/time.

	local previousPosition =
		self.LastPositions[player]

	local previousSampleTime =
		self.LastSampleTimes[player]

	self.LastPositions[player] =
		root.Position

	self.LastSampleTimes[player] =
		currentTime

	-- Need an initial sample before calculating speed.

	if not previousPosition or not previousSampleTime then
		return
	end

	local deltaTime =
		currentTime - previousSampleTime

	if deltaTime <= 0 then
		return
	end

	if deltaTime < self.SampleInterval then
		return
	end

	-- Only horizontal movement counts.
	--
	-- Y is ignored so jumping/falling is handled separately
	-- by JumpScanner.

	local displacement =
		root.Position - previousPosition

	local horizontal =
		Vector3.new(
			displacement.X,
			0,
			displacement.Z
		)

	local distance =
		horizontal.Magnitude

	local speed =
		distance / deltaTime

	local limit, sprinting =
		self:GetAllowedSpeed(
			player,
			humanoid
		)

	local allowedSpeed =
		limit + self.Tolerance

	local overLimit =
		speed > allowedSpeed

	if not overLimit then
		self.ViolationCounts[player] = 0
		self.LastViolationTimes[player] = nil

		return
	end

	-- Track consecutive violations.

	local lastViolation =
		self.LastViolationTimes[player]

	if not lastViolation
		or currentTime - lastViolation > self.ViolationWindow then

		self.ViolationCounts[player] = 1
	else
		self.ViolationCounts[player] =
			(self.ViolationCounts[player] or 0) + 1
	end

	self.LastViolationTimes[player] =
		currentTime

	-- Not enough consecutive samples yet.

	if self.ViolationCounts[player] <
		self.RequiredViolations then

		return
	end

	-- Detection confirmed.

	self.ViolationCounts[player] = 0

	local detection = {
		Type = "Speed",

		Player = player,

		Speed = speed,

		Limit = limit,

		AllowedSpeed = allowedSpeed,

		Sprinting = sprinting,

		Time = os.time(),
	}

	if self.OnDetection then
		self.OnDetection(detection)
	end
end

function LoopScanner:Start()
	if self.Running then
		return
	end

	self.Running = true

	self.Connection =
		RunService.Heartbeat:Connect(function()
			if not self.Running then
				return
			end

			local currentTime = os.clock()

			for _, player in ipairs(
				Players:GetPlayers()
			) do
				self:ProcessPlayer(
					player,
					currentTime
				)
			end
		end)

	print("[AC-Checker] LoopScanner started.")
end

function LoopScanner:Stop()
	self.Running = false

	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end

	table.clear(self.LastPositions)
	table.clear(self.LastSampleTimes)
	table.clear(self.ViolationCounts)
	table.clear(self.LastViolationTimes)

	print("[AC-Checker] LoopScanner stopped.")
end

return LoopScanner
