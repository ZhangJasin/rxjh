local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCBagOnDragDropPanel = class("PCBagOnDragDropPanel",BaseFGUILayout)
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")

function PCBagOnDragDropPanel:Create()
	self._ui = FGUI:ui_delegate(self.component)
    FGUI:setSortingOrder(self.component, FGUIDefine.MainOrder.Drop)
    self:InitUI()
end

function PCBagOnDragDropPanel:Exit()
end

function PCBagOnDragDropPanel:InitUI()
    FGUI:setOnDropEvent(self.component,handler(self,self.onDropEvent))
end

function PCBagOnDragDropPanel:onDropEvent(eventData)
    if not eventData then
        return
    end

    if eventData.inputEvent.button == 0 and 
        eventData.data and 
        eventData.data.makeIndex then
        -- 从背包拖出的才触发丢弃页面
        if eventData.data.from and eventData.data.from == ItemFrom.BAG then
            local itemData = SL:GetValue("BAG_DATA_BY_MAKEINDEX",eventData.data.makeIndex)
            if itemData then
                FGUIFunction:DropItem(itemData)
            end
        end
    end
end

function PCBagOnDragDropPanel:Destory()
    FGUI:setOnDropEvent(self.component,nil)
end

return PCBagOnDragDropPanel