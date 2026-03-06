local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local S_CommonDialog = class("S_CommonDialog", BaseFGUILayout)

function S_CommonDialog:Create()
    self._ui = FGUI:ui_delegate(self.component)
end

function S_CommonDialog:Enter(data)
    self._data = data 
    self:InitUI()
end

function S_CommonDialog:InitUI()
    FGUI:setOnClickEvent(self._ui.Button_1, handler(self, self.OnButton1))
    FGUI:setOnClickEvent(self._ui.Button_2, handler(self, self.OnButton2))
    self:UpdateView()
end

function S_CommonDialog:Close()
    self.super.Close(self)
end

function S_CommonDialog:UpdateView()
    -- 内容
    FGUI:GTextField_setText(self._ui.Text_content, self._data.str)
    -- 按钮
    if self._data.btnDesc[1] then
        FGUI:GButton_setTitle(self._ui.Button_1, self._data.btnDesc[1])
    end
    
    if self._data.btnDesc[2] then
        FGUI:GButton_setTitle(self._ui.Button_2, self._data.btnDesc[2])
        --双按钮
        FGUI:setVisible(self._ui.Button_2, true)
        -- 镜像对称
        local center_x = self.component.width / 2
        local x, y = FGUI:getPosition(self._ui.Button_2)
        local offset_x = center_x - self._ui.Button_2.width - x
        FGUI:setPosition(self._ui.Button_1, center_x + offset_x, y)
    else
        --单按钮
        FGUI:setVisible(self._ui.Button_2, false)
        local y = FGUI:getPositionY(self._ui.Button_2)
        FGUI:setPosition(self._ui.Button_1, (self.component.width - self._ui.Button_1.width) / 2, y) -- 居中
    end
end

function S_CommonDialog:OnButtonEvent(idx)
    if not self._data then return nil end
    if not self._data.callback then return nil end
    local callback = self._data.callback

    self:Close()
    callback(idx)
end

function S_CommonDialog:OnButton1()
    self:OnButtonEvent(1)
end

function S_CommonDialog:OnButton2()
    self:OnButtonEvent(2)
end

return S_CommonDialog
