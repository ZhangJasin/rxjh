local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local TestImage_Component = class("TestImage_Component", BaseFGUILayout)

function TestImage_Component:Create()
    self.handle_close = handler(self, self.Close)
    self.target_image = self:GetChild("target_image")
    self.change_property_list = self:GetChild("change_property_list")
    self.change_texture_list = self:GetChild("change_texture_list")

    self._change_property_config = {{
        value = 0,
        name_list = {"None", "Horizontal", "Vertical", "Both"},
        change = function(self)
            self.value = self.value + 1
            self.value = self.value % #self.name_list
        end,
        refresh = function(self, img, value_txt)
            FGUI:GImage_setFlip(img, self.value)
            local type = FGUI:GImage_getFilp(img)
            value_txt.text = self.name_list[type + 1]
            print("refresh filp value: " .. value_txt.text)
        end

    }, {
        value = 0,
        name_list = {"None", "Horizontal", "Radial90", "Radial180", "Radial360"},
        change = function(self)
            self.value = self.value + 1
            self.value = self.value % #self.name_list
        end,
        refresh = function(self, img, value_txt)
            FGUI:GImage_setFillMethod(img, self.value)
            local type = FGUI:GImage_getFillMethod(img)
            value_txt.text = self.name_list[type + 1]
            print("refresh fillMethod value: " .. value_txt.text)
        end
    }, {
        value = 0,
        name_list = {"0", "1", "2", "3"},
        change = function(self)
            self.value = self.value + 1
            self.value = self.value % #self.name_list
        end,
        refresh = function(self, img, value_txt)
            FGUI:GImage_setFillOrigin(img, self.value)
            local type = FGUI:GImage_getFillOrigin(img)
            value_txt.text = self.name_list[type + 1]
            print("refresh fillOrigin value: " .. value_txt.text)
        end
    }, {
        value = 1,
        name_list = {"false", "true"},
        change = function(self)
            self.value = self.value + 1
            self.value = self.value % #self.name_list
        end,
        refresh = function(self, img, value_txt)
            FGUI:GImage_setFillClockwise(img, self.value == 1)
            local type = FGUI:GImage_getFillClockwise(img)
            if type then
                value_txt.text = "true"
            else
                value_txt.text = "false"
            end
            print("refresh fillClockwise value: " .. value_txt.text)
        end
    }, {
        value = 100,
        change = function(self, slider)
            self.value = slider.value
        end,
        refresh = function(self, img, value_txt)
            FGUI:GImage_setFillAmount(img, self.value / 100)
            local amount = FGUI:GImage_getFillAmount(img)
            value_txt.text = tostring(math.floor(amount * 100))
            print("refresh fillAmount value: " .. value_txt.text)
        end
    }}

    local change_texture_from_url = function(widget, url, auto_size)
        FGUI:GImage_setTexture(widget, url, auto_size)
    end
    local change_texture_from_path = function(widget, path, auto_size)
        FGUI:Image_loadTexture(widget, path, auto_size)
    end
    self._change_texture_config = {{
        name = "URL：",
        path = "ui://xc9gb59xor25o",
        handler = change_texture_from_url
    }, {
        name = "URL：",
        path = "ui://xc9gb59xor25a",
        handler = change_texture_from_url
    }, {
        name = "URL：",
        path = "ui://xc9gb59xor257",
        handler = change_texture_from_url
    }, {
        name = "Path：",
        path = "Image/skill_icon/Skill_1.png",
        handler = change_texture_from_path
    }, {
        name = "Path：",
        path = "Image/skill_icon/Skill_17.png",
        handler = change_texture_from_path
    }, {
        name = "Path：",
        path = "Image/skill_icon/Skill_59.png",
        handler = change_texture_from_path
    }}
    self:InitEvent()
end

function TestImage_Component:InitEvent()
    local btn_close = self:GetChild("btn_close")
    btn_close.onClick:Add(self.handle_close)
    for i = 0, 4, 1 do
        local item = self.change_property_list:GetChildAt(i)
        local config = self._change_property_config[i + 1]

        if i ~= 4 then
            local btn = item:GetChild("icon")
            btn.onClick:Set(function()
                self:OnClickItem(i)
            end)
        else
            local slider = item:GetChild("icon").component
            local name = slider:GetType().FullName
            print(name)
            slider.value = config.value
            slider.onChanged:Set(function()
                config:change(slider)
                config:refresh(self.target_image, item:GetChild("value"))
            end)
        end
        config:refresh(self.target_image, item:GetChild("value"))
    end

    for i, config in ipairs(self._change_texture_config) do
        local item = self.change_texture_list:GetChildAt(i - 1)
        item.title = config.name
		local input = item:GetChild("input")
        input.text = config.path
        local tog = item:GetChild("auto_size")
        local btn = item:GetChild("change")
        btn.onClick:Set(function()
            config.handler(self.target_image, input.text, tog.selected)
			tog.selected = false
        end)
    end
end

function TestImage_Component:OnClickItem(index)
    local data = self._change_property_config[index + 1]
    local item = self.change_property_list:GetChildAt(index)
    data:change()
    data:refresh(self.target_image, item:GetChild("value"))
end

return TestImage_Component
