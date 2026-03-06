local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local TestLabel_Component = class("TestLabel_Component", BaseFGUILayout)

function TestLabel_Component:Create()
    self.curLabel = nil
    self.handle_close = handler(self, self.Close)
    self.label_list = self:GetChild("label_list")
    self.switch_list = self:GetChild("switch_list")
    local nums = FGUI:GList_getNumItems(self.label_list)
    FGUI:GList_setNumItems(self.switch_list, nums)

    self.property_config = {{
        title = "Title:",
        init = function(config,widget)
            config.widget = widget
            config.value = widget:GetChild("value")
            widget.title = config.title
        end,
        get = function(config, label)
            config.value.text = FGUI:GLabel_getTitle(label)
        end,
        set = function(config, label)
            FGUI:GLabel_setTitle(label, config.value.text)
        end
    },{
        title = "Icon:",
        init = function(config,widget)
            config.widget = widget
            config.value = widget:GetChild("value")
            widget.title = config.title
        end,
        get = function(config, label)
            config.value.text = FGUI:GLabel_getIcon(label)
        end,
        set = function(config, label)
            FGUI:GLabel_setIcon(label, config.value.text)
        end
    },{
        title = "Editable:",
        init = function(config,widget)
            config.widget = widget
            config.value = widget:GetChild("value")
            widget.title = config.title
        end,
        get = function(config, label)
            config.value.text = tostring(FGUI:GLabel_getEditable(label))
        end,
        set = function(config, label)
            local editable = string.lower(config.value.text) == tostring(true) or config.value.text == "1"
            FGUI:GLabel_setEditable(label, editable)
        end
    },{
        title = "TitleColor:",
        init = function(config,widget)
            config.widget = widget
            config.value = widget:GetChild("value")
            widget.title = config.title
        end,
        get = function(config, label)
            config.value.text = "only set"
        end,
        set = function(config, label)
            if not string.startsWith(config.value.text,"#") then
                return
            end
            FGUI:GLabel_setTitleColor(label, config.value.text)
        end
    },{
        title = "TitleFontSize:",
        init = function(config,widget)
            config.widget = widget
            config.value = widget:GetChild("value")
            widget.title = config.title
        end,
        get = function(config, label)
            config.value.text = FGUI:GLabel_getTitleFontSize(label)
        end,
        set = function(config, label)
            local fontSize = tonumber(config.value.text)
            FGUI:GLabel_setTitleFontSize(label, fontSize)
        end
    },{
        title = "TitleType:",
        init = function(config,widget)
            config.widget = widget
            config.value = widget:GetChild("value")
            widget.title = config.title
        end,
        get = function(config, label)
            local textField = FGUI:GLabel_getTextField(label)
            if textField then
                config.value.text = textField:GetType().FullName
            else
                config.value.text = tostring(textField)
            end
        end,
        set = function(config, label)
        end
    }}

    self.property_list = self:GetChild("property_list")
    FGUI:GList_setNumItems(self.property_list, #self.property_config)
    for i = 1, #self.property_config, 1 do
        local idx = i - 1
        local item = self.property_list:GetChildAt(idx)
        local config = self.property_config[i]
        config.init(config, item)
        local icon = item:GetChild("icon")
        FGUI:GLoader_setUrl(icon, "ui://b7c7kv70vuky10")
        icon.component.onClick:EventListener_Set(function()
            self:OnClickSet(idx)
        end)
    end

    self:InitEvent()
    FGUI:GList_setSelectedIndex(self.switch_list, 0)
end

function TestLabel_Component:InitEvent()
    local btn_close = self:GetChild("closeButton")
    btn_close.onClick:Add(self.handle_close)

    local nums = FGUI:GList_getNumItems(self.switch_list)

    local controller = self.component:GetController("pageController")
    for i = 1, nums, 1 do
        controller:AddPage(tostring(i - 1))
    end
    controller.onChanged:Add(function()
        self:OnPageChange(controller.selectedIndex)
    end)
end

function TestLabel_Component:OnPageChange(index)
    local childIdx = FGUI:GList_itemIndexToChildIndex(self.label_list, index)
    self.curLabel = self.label_list:GetChildAt(childIdx)
    self:RefreshPropertyList()
end

function TestLabel_Component:RefreshPropertyList()
    for i, config in ipairs(self.property_config) do
        config.get(config, self.curLabel)
    end
end

function TestLabel_Component:OnClickSet(idx)
    local config = self.property_config[idx + 1]
    config.set(config, self.curLabel)
end

return TestLabel_Component
