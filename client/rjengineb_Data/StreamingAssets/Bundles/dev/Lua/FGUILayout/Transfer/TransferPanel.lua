--TransferPanel = {}

local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local TransferPanel = class("TransferPanel", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemShow = SL:RequireFile("FGUILayout/Item/ItemShow")
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")
local SysConstant                 =  require("game_config/cfgcsv/SysConstant")                 -- 常量
local Language                    =  require("game_config/cfgcsv/Language")                    -- 文本描述表
local Transfer_cfg                    =  require("game_config/Transfer")                    -- 转职表
-- 创建界面并绑定所有UI事件

function TransferPanel:Create()
    -- 获取界面代理
    self._ui = FGUI:ui_delegate(self.component)


    FGUI:setOnClickEvent(self._ui.btn_close, function()
        FGUI:Close("Transfer", "TransferPanel")
    end)
end

-- 奖励展示列表渲染
function TransferPanel:ListItemShow(idx, item)
    local itemRoot = FGUI:GetChild(item, "itemRoot")
    if FGUI:GetChildCount(itemRoot) > 0 then
        FGUI:RemoveChildAt(itemRoot, 0, true)
    end
   
end


return TransferPanel