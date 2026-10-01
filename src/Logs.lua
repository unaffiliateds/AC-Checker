local Logs = {}
Logs.__index = Logs

function Logs.new(maxEntries)

    local self =
        setmetatable({}, Logs)

    self.MaxEntries =
        maxEntries or 500

    self.Entries = {}
    self.NextId = 0

    return self
end

function Logs:Add(data)

    self.NextId += 1

    local player =
        data.Player

    local entry = {

        Id = self.NextId,

        Type =
            data.Type or "Unknown",

        PlayerName =
            player
            and player.Name
            or "Unknown",

        UserId =
            player
            and player.UserId
            or nil,

        Speed =
            data.Speed,

        Limit =
            data.Limit,

        Sprinting =
            data.Sprinting == true,

        Height =
            data.Height,

        MaxHeight =
            data.MaxHeight,

        Time =
            data.Time or os.time(),
    }

    table.insert(
        self.Entries,
        entry
    )

    while #self.Entries >
        self.MaxEntries do

        table.remove(
            self.Entries,
            1
        )
    end

    return entry
end

function Logs:GetEntries()

    local result =
        table.create(
            #self.Entries
        )

    for i, entry in ipairs(
        self.Entries
    ) do

        result[i] = entry
    end

    return result
end

function Logs:GetCount()
    return #self.Entries
end

function Logs:GetPlayerEntries(
    userId
)

    local result = {}

    for _, entry in ipairs(
        self.Entries
    ) do

        if entry.UserId == userId then

            table.insert(
                result,
                entry
            )
        end
    end

    return result
end

function Logs:Clear()

    table.clear(
        self.Entries
    )
end

function Logs:ClearPlayer(
    userId
)

    for i = #self.Entries, 1, -1 do

        if self.Entries[i].UserId ==
            userId then

            table.remove(
                self.Entries,
                i
            )
        end
    end
end

return Logs
