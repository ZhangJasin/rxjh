local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local CommonAttrTip = class("CommonAttrTip", BaseFGUILayout)

function CommonAttrTip:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self:InitData()
    self:GetAllFGuiData()
    self:InitTouch()
end

function CommonAttrTip:InitData()
    self._setPosX = 0
    self._setPosY = 0
end

function CommonAttrTip:GetAllFGuiData()
    self._content = self._ui.content
    self._mask = self._ui.mask
end

function CommonAttrTip:InitTouch()
    local function beginFunc(eventData)
        if self then
            self.super.Close(self)
            FGUI:EventContext_CaptureTouch(eventData)
        end
    end
    local function moveFunc(eventData)
    end
    local function endFunc(eventData)
    end

    FGUI:setOnTouchEvent(self._mask, beginFunc, moveFunc, endFunc)
end

function CommonAttrTip:Enter(data)
    if not data then
       return
    end

    self.data = data
end

function CommonAttrTip:Refresh()
    if self._content then
       FGUI:GTextField_setText(self._content,self.data.showText or "")
    end

    local textWidth,textHeight = FGUI:getContentSize(self._content)
    if self.data.parent then
        -- 是否是当前锚点，并且使用的情况下
        -- 文本的锚点是(0,0)
        local posX,posY = FGUI:getWorldPosition(self.data.parent)
        if FGUI:getAsAnchor(self.data.parent) then
            local width,height = FGUI:getContentSize(self.data.parent)
            local anchX,anchY = FGUI:getAnchorPoint(self.data.parent)
            self._setPosX = posX - anchX * width
            self._setPosY = posY - anchY * height - textHeight
        else
            self._setPosX = posX
            self._setPosY = posY - textHeight
        end
    else
        self._setPosX = SL:GetValue("SCREEN_WIDTH") / 2 - textWidth/2
        self._setPosY = SL:GetValue("SCREEN_HEIGHT") / 2 - textHeight/2
    end

    FGUI:setPosition(self._content,self._setPosX,self._setPosY)
end

function CommonAttrTip:Exit()
end

return CommonAttrTip