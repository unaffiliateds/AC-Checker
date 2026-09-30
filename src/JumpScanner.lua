--[[
    AC-Checker
    JumpScanner.lua

    Jump detection placeholder.

    This will eventually handle:

    - Jump height
    - Upward velocity
    - Abnormal repeated jumps
    - Legitimate jump modifiers
]]

local JumpScanner = {}
JumpScanner.__index = JumpScanner

function JumpScanner.new(config)

	local self =
		setmetatable(
			{},
			JumpScanner
		)

	self.Config =
		config or {}

	self.Running = false

	return self
end

function JumpScanner:Start()

	if self.Running then
		return
	end

	self.Running = true

	print(
		"[AC-Checker] JumpScanner started."
	)

end

function JumpScanner:Stop()

	if not self.Running then
		return
	end

	self.Running = false

	print(
		"[AC-Checker] JumpScanner stopped."
	)

end

return JumpScanner
