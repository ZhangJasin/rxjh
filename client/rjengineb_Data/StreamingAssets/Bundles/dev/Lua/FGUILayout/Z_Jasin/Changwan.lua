local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local Changwan = class("Changwan", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
Changwan.Instance = nil

function Changwan:Ret(state)
    if Changwan.Instance then
        Changwan.Instance:UpdateUI(state)
    end
end

function Changwan:Create()
    self._ui = FGUI:ui_delegate(self.component)
    Changwan.Instance = self
    local isPC = SL:GetValue("IS_PC_OPER_MODE")
    FGUI:SetCloseUIWhenClickOutside(self)

    --关闭按钮
    FGUI:setOnClickEvent(self._ui.btn_close, function()
        FGUI:Close("Z_Jasin", isPC and "PCChangwan" or "Changwan")
    end)
    --月卡按钮
    FGUI:setOnClickEvent(self._ui.btn_page2, function()
        FGUI:Open("Z_Jasin", isPC and "PCYueka" or "Yueka", {}, FGUI_LAYER.NORMAL,
            { destroyTime = 1, classPath = "FGUILayout/Z_Jasin/Yueka" })

        FGUI:Close("Z_Jasin", isPC and "PCChangwan" or "Changwan")
    end)

    ssrMessage:sendmsgEx("Changwan", "req")
end

function Changwan:UpdateUI(state)
    local isPC = SL:GetValue("IS_PC_OPER_MODE")
    --加载item
    local itemLst = {
        [1] = 1319,
        [2] = 1320,
        [3] = 1321,
        [4] = 1322,
        [5] = 1323,
        [6] = 1324,
        [7] = 1325,
        [8] = 1326,
        [9] = 1327,
    }
    for i, v in ipairs(itemLst) do
        local childNode = self._ui["item" .. i]
        if childNode then
            local item = FGUI:GetChild(childNode, "commonItem")
            if item then
                ItemUtil:RefreshItemUIByData(item, SL:GetValue("ITEM_DATA", v))
                if isPC then
                    FGUI:setOnRollOverEvent(item, function()
                        local tipData = {}
                        tipData.itemData = SL:GetValue("ITEM_DATA", v)
                        tipData.hideCompare = true
                        tipData.hideButtons = true
                        FGUIFunction:OpenItemTips(tipData)
                    end)
                    FGUI:setOnRollOutEvent(item, function()
                        FGUIFunction:CloseItemTips()
                    end)
                else
                    FGUI:setOnClickEvent(item, function()
                        local tipData = {}
                        tipData.itemData = SL:GetValue("ITEM_DATA", v)
                        tipData.hideCompare = true
                        tipData.hideButtons = true
                        FGUIFunction:OpenItemTips(tipData)
                    end)
                end
            end
        end
    end

    FGUI:GButton_setTitle(self._ui.btn_sub, state.param1 == 0 and "领 取" or "已 领 取")

    --领取按钮
    FGUI:setOnClickEvent(self._ui.btn_sub, function()
        ssrMessage:sendmsgEx("Changwan", "recv")
    end)
end

function Changwan:Destroy()
    Changwan.Instance = nil
end

function Changwan:Exit()
end

ssrMessage:RegisterNetMsg(ssrNetMsgCfg.Changwan, Changwan)
return Changwan
