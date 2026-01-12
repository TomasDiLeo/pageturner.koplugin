-- Simple Remote Service
-- UDP discovery + UDP command receiver with user confirmation
local socket = require("socket")
local logger = require("logger")
local UIManager = require("ui/uimanager")
local Event = require("ui/event")
local ConfirmBox = require("ui/widget/confirmbox")
local InfoMessage = require("ui/widget/infomessage")
local DataStorage = require("datastorage")
local LuaSettings = require("luasettings")
local _ = require("gettext")
local IPManagementDialog = require("ipmanagmentdialog")

local Service = {
    running = false,
    ui = nil,
    UDP_PORT = 8134,
    ipmanagementdialog = nil,
}

------------------------------------------------------------
-- Service initialization
------------------------------------------------------------
function Service:updateUI(ui)
    self.ui = ui
end

function Service:init()
    self.settings_file = DataStorage:getSettingsDir() .. "/pageturner_ips.lua"
    self.settings = LuaSettings:open(self.settings_file)

    self.confirmed_ips = self:loadConfirmedIPs()

    self.ipmanagementdialog = IPManagementDialog:new{
        service = self,
    }
    --IPManagementDialog:init()
end

function Service:start(ui)
    self:updateUI(ui)

    if self.running then return end
    self.running = true
    
    -- UDP socket
    self.udp = socket.udp4()
    self.udp:setoption("broadcast", true)
    self.udp:setsockname("0.0.0.0", self.UDP_PORT)
    self.udp:settimeout(0)
    
    logger.info("[PageTurner] UDP socket bound on port", self.UDP_PORT) --TODO REMOVE
    self:_scheduleTick()
end

function Service:saveConfirmedIPs()
    self.settings:saveSetting("confirmed_ips", self.confirmed_ips)
    self.settings:flush()
end

function Service:loadConfirmedIPs()
    local saved_data = self.settings:readSetting("confirmed_ips")
    local confirmed_ips = {}

    if saved_data and type(saved_data) == "table" then
        confirmed_ips = {}
        for ip, data in pairs(saved_data) do
            if type(ip) == "string" and type(data) == "table" then
                confirmed_ips[ip] = {
                    added_time = data.added_time or os.time(),
                    label = data.label or "Unknown"
                }
            end
        end
    else
        confirmed_ips = {}
    end
    
    return confirmed_ips
end

function Service:stop()
    if not self.running then return end
    self.running = false
    
    if self.udp then self.udp:close() end
    self.udp = nil
    
    logger.info("[PageTurner] Service stopped") --TODO REMOVE
end

------------------------------------------------------------
-- Internal loop (event-driven, non-blocking)
------------------------------------------------------------
function Service:_scheduleTick()
    UIManager:scheduleIn(0.1, function()
        if not self.running then return end
        self:_tick()
        self:_scheduleTick()
    end)
end

function Service:_tick()
    local data, ip, port = self.udp:receivefrom()

    if data then
        data = data:gsub("[\r\n]+$", "")
        logger.info("[PageTurner] Received from", ip, ":", data) --TODO REMOVE
        
        -- Handle REQUEST command
        if data == "REQUEST" then
            if self.confirmed_ips[ip] then
                logger.info("[PageTurner] Auto-accepted known IP", ip) --TODO REMOVE
                self.udp:sendto("ACCEPTED", ip, port)
                return
            end

            self.udp:sendto("REQUESTING", ip, port)
            
            UIManager:show(ConfirmBox:new{
                text = string.format(_("Allow remote control from %s?"), ip),
                ok_text = _("Accept"),
                cancel_text = _("Deny"),
                ok_callback = function()
                    self:_acceptConnection(ip, port)
                end,
                cancel_callback = function()
                    self:_denyConnection(ip, port)
                end,
            })
            return
        else
            if not self.confirmed_ips[ip] then
                logger.info("[PageTurner] Unauthorized command from", ip) --TODO REMOVE
                self.udp:sendto("ERR:NOT_AUTHORIZED", ip, port)
                return
            end
        end
        
        -- Process commands
        local reply = ""
        if self.ui and self.ui.document then
            reply = self:_processCommand(data)
        else
            logger.info("[PageTurner] No document open")
            reply = "ERR:NO_DOCUMENT"
        end
        
        self.udp:sendto(reply, ip, port)
    end
end

function Service:_processCommand(cmd)
    local commands = {
        ["NEXT"] = function() self.ui:handleEvent(Event:new("GotoViewRel", 1)) end,
        ["PREV"] = function() self.ui:handleEvent(Event:new("GotoViewRel", -1)) end,
    }

    if commands[cmd] then
        commands[cmd]()
        UIManager.event_hook:execute("InputEvent")
        return "OK"
    else
        return "ERR:UNKNOWN_COMMAND"
    end
end

function Service:_acceptConnection(ip, port)
    logger.info("[PageTurner] Connection accepted from", ip) --TODO REMOVE
    
    self.confirmed_ips[ip] = {
        added_time = os.time(),
    }
    self:saveConfirmedIPs()

    self.udp:sendto("ACCEPTED", ip, port)
    
    UIManager:show(InfoMessage:new{
        text = string.format(_("Remote control enabled for %s"), ip),
        timeout = 2,
    })
end

function Service:_denyConnection(ip, port)
    logger.info("[PageTurner] Connection denied from", ip) --TODO REMOVE
    
    self.udp:sendto("DENIED", ip, port)
    
    UIManager:show(InfoMessage:new{
        text = _("Remote control request denied"),
        timeout = 2,
    })
end

function Service:deleteConfirmedIP(ip)
    if ip and self.confirmed_ips[ip] then
        self.confirmed_ips[ip] = nil
        self:saveConfirmedIPs()
        logger.info("[PageTurner] Deleted confirmed IP", ip) --TODO REMOVE
    end
end

------------------------------------------------------------
-- Network info function (for debugging)
------------------------------------------------------------
function Service:getLocalIp()
    local ip_info = "Unknown"
    local test_sock = socket.udp4()
    local success = test_sock:setpeername("8.8.8.8", 53)
    if success then
        local sockname = test_sock:getsockname()
        if sockname then
            ip_info = sockname
        end
    end
    test_sock:close()
    return ip_info
end

function Service:showNetworkInfo()
    local ip_info = self:getLocalIp()
    local info_text = string.format(_(
        "Remote Service Status\n" ..
        "Running: %s\n" ..
        "Local IP: %s\n" ..
        "UDP Port: %d"
    ),
    tostring(self.running),
    ip_info,
    self.UDP_PORT)
    
    UIManager:show(InfoMessage:new{ text = info_text })
end

function Service:ipManagement()
    self.ipmanagementdialog:buildUI()
    UIManager:show(self.ipmanagementdialog)
end

return Service