local LoadingLayerManager = class("LoadingLayerManager")

function LoadingLayerManager:ctor()
    SL:RegisterLUAEvent(LUA_EVENT_LOADING_ONENTER, "LoadingLayerManager", handler(self, self.OnLoadingPanelEnter))
end

function LoadingLayerManager:OpenLayer(data)
    local isPC = SL:GetValue("IS_PC_OPER_MODE")
    if isPC then 
        FGUI:Open("Loading_pc","PCLoadingPanel", data, FGUI_LAYER.LOADING)
    else  
        FGUI:Open("Loading","LoadingPanel", data, FGUI_LAYER.LOADING)
    end 
end

function LoadingLayerManager:CloseLayer()
    local isPC = SL:GetValue("IS_PC_OPER_MODE")
    if isPC then 
        FGUI:Close("Loading_pc", "PCLoadingPanel")
    else  
        FGUI:Close("Loading", "LoadingPanel")
    end 
end

function LoadingLayerManager:SetPercent(percent)
    SL:onLUAEvent(LUA_EVENT_LOADING_SET_PERCENT, percent)
end

function LoadingLayerManager:SetLoadingPanelEnterCB(callback)
    self._enterCallback = callback
end

function LoadingLayerManager:OnLoadingPanelEnter()
    if self._enterCallback then
        self._enterCallback()
    end
end

function LoadingLayerManager:IsLoadingPanelOpen()
    local isPC = SL:GetValue("IS_PC_OPER_MODE")
    if isPC then 
        return FGUI:CheckOpen("Loading_pc", "PCLoadingPanel")
    else  
        return FGUI:CheckOpen("Loading", "LoadingPanel")
    end 
end

return LoadingLayerManager