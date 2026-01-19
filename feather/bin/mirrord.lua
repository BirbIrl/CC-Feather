local storage = bundle "feather.storage" ---@type feather.storage
local pp = require "cc.pretty".pretty_print

peripheral.find("modem", rednet.open)
local protocol = "feather.mirrord"
rednet.host(protocol, os.getComputerLabel() or ("Unnamed Computer nr." .. os.getComputerID()))

---@class feather.mirrord.message
---@field request_type string
---@field contents table


---@class feather.mirrord.message.bundle.get: feather.mirrord.message
---@field requst_type "bundle_get"
---@field contents {}

local struct = storage.encode(".feather/lib/feather/hello")


storage.decode(struct, "newhello")


-- while true do
-- 	local sender, message = rednet.receive(protocol)
-- end
