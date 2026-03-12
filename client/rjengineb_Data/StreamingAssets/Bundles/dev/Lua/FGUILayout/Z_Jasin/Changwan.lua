local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local Changwan = class("Changwan", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")

function Changwan:Create()
    self._ui = FGUI:ui_delegate(self.component)
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
        local item = FGUI:GetChild(self._ui["item" .. i], "commonItem")
        if item then
            ItemUtil:RefreshItemUIByData(item, SL:GetValue("ITEM_DATA", v))
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
        end
    end

    --领取按钮
    FGUI:setOnClickEvent(self._ui.btn_sub, function()
        SL:dump("领取")
        ssrMessage:sendmsgEx("Changwan", "recv")
    end)
end

function Changwan:Destroy()
end

function Changwan:Exit()
end

return Changwan
