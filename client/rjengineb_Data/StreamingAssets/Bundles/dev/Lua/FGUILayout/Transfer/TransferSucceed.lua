local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local TransferSucceed = class("TransferSucceed", BaseFGUILayout)
local XlsTransfer = requireGameConfig("Transfer")
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
-- local tempTransferID = 400001

function TransferSucceed:Create()
    self.callback = nil
end

function TransferSucceed:Create()
    self._ui = FGUI:ui_delegate(self.component)
    FGUI:GList_itemRenderer(self._ui.list_prop, handler(self, self.PropItemRender))
    -- FGUI:GList_itemRenderer(self._ui.list_skill, handler(self, self.SkillItemRender))
    FGUI:GList_itemRenderer(self._ui.list_reward, handler(self, self.RewardItemRender))
    FGUI:GList_setDefaultItemSize(self._ui.list_reward, 90, 90)
    FGUI:setOnClickEvent(self._ui.btn_confirm, handler(self,self.Close))
end

function TransferSucceed:Enter(data)
    -- self._curCfg = XlsTransfer[tempTransferID]
    -- self._nextCfg = XlsTransfer[tempTransferID + 1]
    self._curCfg = data.curCfg
    self._nextCfg = data.nextCfg
    print("TransferSucceed:Enter", self._curCfg.ID, self._nextCfg.ID)
    self:RegisterEvent()
    self:UpdateUI()
end

function TransferSucceed:UpdateUI()
    local originName = self._curCfg.TransferName
    if self._curCfg.TransferLV > 0 then
        originName = originName .. string.format(GET_STRING(70000101), GET_STRING(5000 + self._curCfg.TransferLV))
    end
    FGUI:GTextField_setText(self._ui.txt_job_origin, originName)
    local nextName = self._nextCfg.TransferName ..string.format(GET_STRING(70000101), GET_STRING(5000 + self._nextCfg.TransferLV))
    FGUI:GTextField_setText(self._ui.txt_job_next, nextName)
    FGUI:GList_setNumItems(self._ui.list_prop, #self._nextCfg.TransferAS)
    --FGUI:GList_setNumItems(self._ui.list_skill, #self._nextCfg.UnlockSkills)
    FGUI:GList_setNumItems(self._ui.list_reward, #self._nextCfg.Reward)
end

function TransferSucceed:PropItemRender(idx, item)
    local cfg = self._nextCfg.TransferAS[idx + 1]
    local propName = SL:GetMetaValue("ATTR_CONFIG_NAME_BY_ID", cfg[1])
    FGUI:GTextField_setText(FGUI:GetChild(item, "txt_prop"), propName.."+"..tostring(cfg[2]))
end

function TransferSucceed:SkillItemRender(idx, item)
    local cfg = self._nextCfg.UnlockSkills[idx + 1]
    local skillIcon = SL:GetMetaValue("SKILL_SQUARE_ICON_PATH_BY_ID", cfg)
    FGUI:GLoader_setUrl(FGUI:GetChild(item, "img_icon"), skillIcon, nil, true)
end

function TransferSucceed:RewardItemRender(idx, item)
    local cfg = self._nextCfg.Reward[idx + 1]
    local xls = SL:GetMetaValue("ITEM_DATA", cfg[1])
    local grade = xls.Grade or 0
    local path = "ui://public/icon_item0"
    if grade then
        path = "ui://public/icon_item" .. tostring(grade)
        local img_bg = FGUI:GetChild(item, "img_bg")
        FGUI:GImage_setTexture(img_bg, path, false)
    end

    local commonItem = FGUI:GetChild(item, "commonItem")
    ItemUtil:RefreshItemUIByData(commonItem,SL:GetValue("ITEM_DATA", xls.ID))
    ItemUtil:AddItemClick(commonItem,SL:GetValue("ITEM_DATA", xls.ID))
end

function TransferSucceed:Exit()
    self:RemoveEvent()
end

function TransferSucceed:Destroy()
    self._ui = nil
end

-----------------------------------注册事件--------------------------------------
function TransferSucceed:RegisterEvent()

end

function TransferSucceed:RemoveEvent()

end

return TransferSucceed
