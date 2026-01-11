local WidgetContainer = require("ui/widget/container/widgetcontainer")
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
local logger = require("logger")

local _ = require("gettext")

local Service = require("service")

local PageTurner = WidgetContainer:extend{
    name = "page_turner",
    is_doc_only = false,
}

function PageTurner:init()
    Service:init()
    self.ui.menu:registerToMainMenu(self)
end

function PageTurner:onReaderReady()
    Service:updateUI(self.ui)
end

function PageTurner:addToMainMenu(menu_items)
    menu_items.page_turner = {
        text = _("Page Turner"),
        sorting_hint = "tools",
        sub_item_table = {
            {
                text_func = function()
                    return Service.running and _("Stop service") or _("Start service")
                end,
                callback = function()
                    if Service.running then
                        Service:stop()
                        UIManager:show(InfoMessage:new{ 
                            text = _("Page Turner Service stopped"),
                            icon = "close",
                            timeout = 5,
                        })
                    else
                        Service:start(self.ui)
                        local ip_info = Service:getLocalIp()

                        local info_text = string.format(_(
                            "Page Turner Service started\n" ..
                            "Local IP: %s\n" ..
                            "UDP Discovery Port: %d"
                        ),
                        ip_info or "Unknown",
                        Service.UDP_PORT)
                        UIManager:show(InfoMessage:new{ 
                            text = info_text,
                            icon = "wifi",
                            timeout = 10,
                        })
                    end
                end,
                separator = true,
            },
            {
                text = _("Show network info"),
                callback = function()
                    Service:showNetworkInfo()
                end,
            },
            {
                text = _("IP Management"),
                callback = function()
                    Service:ipManagement()
                end,
            },
        },
    }
end

function PageTurner:onClose()
    Service:stop()
end

return PageTurner