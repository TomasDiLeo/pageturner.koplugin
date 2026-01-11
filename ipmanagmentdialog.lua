local Button = require("ui/widget/button")
local CenterContainer = require("ui/widget/container/centercontainer")
local Device = require("device")
local FocusManager = require("ui/widget/focusmanager")
local Font = require("ui/font")
local FrameContainer = require("ui/widget/container/framecontainer")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan = require("ui/widget/horizontalspan")
local InputContainer = require("ui/widget/container/inputcontainer")
local LeftContainer = require("ui/widget/container/leftcontainer")
local RightContainer = require("ui/widget/container/rightcontainer")
local Size = require("ui/size")
local TextWidget = require("ui/widget/textwidget")
local UIManager = require("ui/uimanager")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local _ = require("gettext")
local Screen = Device.screen
local Blitbuffer = require("ffi/blitbuffer")
local logger = require("logger")

local ListItem = InputContainer:extend{
    text = "",
    index = 0,
    on_remove = nil,
}

function ListItem:init()
    self.text_widget = TextWidget:new{
        text = self.text,
        face = Font:getFace("cfont", 20),
    }
    
    self.close_button = Button:new{
        text = "✕",
        callback = function()
            if self.on_remove then
                self.on_remove(self.index)
            end
        end,
        bordersize = 0,
        padding = Size.padding.small,
        margin = 0,
    }
    
    self.horizontal_group = HorizontalGroup:new{
        align = "center",
        LeftContainer:new{
            dimen = { w = Screen:getWidth() * 0.7, h = self.text_widget:getSize().h },
            self.text_widget,
        },
        HorizontalSpan:new{ width = Size.padding.default },
        RightContainer:new{
            dimen = { w = Screen:getWidth() * 0.2, h = self.close_button:getSize().h },
            self.close_button,
        },
    }
    
    self[1] = FrameContainer:new{
        padding = Size.padding.small,
        margin = Size.margin.small,
        bordersize = 1,
        self.horizontal_group,
    }
    
    self.dimen = self[1]:getSize()
    
    self.ges_events = {
        TapSelect = {
            GestureRange:new{
                ges = "tap",
                range = self.dimen,
            },
        },
    }
end

-- Main dialog widget
local IPManagementDialog = InputContainer:extend{
    title = _("IP Management"),
    service = nil,
    items = {},
}

function IPManagementDialog:init()

    self:buildUI()
end

function IPManagementDialog:buildUI()
    -- Update items
    self.items = {}
    if self.service and self.service.confirmed_ips then
        for ip, _ in pairs(self.service.confirmed_ips) do
            table.insert(self.items, ip)
        end
    end

    -- Title
    self.title_widget = TextWidget:new{
        text = self.title,
        face = Font:getFace("tfont", 24),
        bold = true,
    }
    
    -- Close button (top right)
    self.close_button = Button:new{
        text = "✕",
        callback = function()
            UIManager:close(self)
        end,
        bordersize = 0,
        padding = Size.padding.default,
        margin = 0,
    }
    
    -- Header with title and close button
    self.header = HorizontalGroup:new{
        align = "center",
        LeftContainer:new{
            dimen = { w = Screen:getWidth() * 0.8, h = self.title_widget:getSize().h },
            self.title_widget,
        },
        RightContainer:new{
            dimen = { w = Screen:getWidth() * 0.1, h = self.close_button:getSize().h },
            self.close_button,
        },
    }
    
    -- List items container
    self.list_container = VerticalGroup:new{
        align = "center",
    }
    
    self:refreshList()
    
    -- Main container
    self.main_frame = FrameContainer:new{
        radius = Size.radius.window,
        padding = Size.padding.large,
        margin = Size.margin.default,
        background = Blitbuffer.COLOR_WHITE,
        VerticalGroup:new{
            align = "center",
            self.header,
            VerticalSpan:new{ width = Size.padding.large },
            self.list_container,
        }
    }
    
    -- Center the dialog
    self[1] = CenterContainer:new{
        dimen = Geom:new{ w = Screen:getWidth(), h = Screen:getHeight() },
        self.main_frame,
    }
    
    self.dimen = self[1]:getSize()
end

function IPManagementDialog:refreshList()
    self.list_container:clear()
    
    for i, item_text in ipairs(self.items) do
        local list_item = ListItem:new{
            text = item_text,
            index = i,
            on_remove = function(index)
                self:removeItem(index)
            end,
        }
        table.insert(self.list_container, list_item)
    end
    
    -- Trigger repaint
    UIManager:setDirty(self, function()
        return "ui", self.dimen
    end)
end

function IPManagementDialog:removeItem(index)
    if index >= 1 and index <= #self.items then
        local ip = self.items[index]
        self.service:deleteConfirmedIP(ip)
        table.remove(self.items, index)
        self:refreshList()
    end
end

function IPManagementDialog:onCloseWidget()
    UIManager:setDirty(nil, function()
        return "ui", self.dimen
    end)
end

return IPManagementDialog