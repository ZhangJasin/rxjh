--BossPanel = {}

local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local BossPanel = class("BossPanel", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemShow = SL:RequireFile("FGUILayout/Item/ItemShow")
local SysConstant = require("game_config/cfgcsv/SysConstant")
local BossInfo_Cfg = require("game_config/cfgcsv/BOSSInfo")


-- 创建界面并绑定所有UI事件
function BossPanel:Create()
    -- 获取界面代理
    self._ui = FGUI:ui_delegate(self.component)

    --适配pc端UI
    local isPC = SL:GetValue("IS_PC_OPER_MODE")
    local screenW = SL:GetValue("SCREEN_WIDTH")
    local screenH = SL:GetValue("SCREEN_HEIGHT")
    if isPC then 
        FGUI:setScale(self.component, 0.75, 0.75)
        FGUI:setPosition(self.component, screenW / 2, screenH / 2)
        FGUI:setAnchorPoint(self.component, 0.5, 0.5, true)
    end
     
    -- 关闭按钮
    FGUI:setOnClickEvent(self._ui.btn_close, function()
        FGUI:Close("huodong", "BossPanel")
    end)

    -- 列表渲染
    FGUI:GList_itemRenderer(self._ui.list_boss, handler(self, self.ListBossShow))
end

function BossPanel:Enter()
    -- 注册消息回调
    SL:RegisterNetMsg(ssrNetMsgCfg.BOSSChall_RetData, handler(self, self.RefreshBossUI))    
    ssrMessage:sendmsgEx("BossChall", "getData")
end

function BossPanel:Destroy()
end
function BossPanel:Exit()
    -- 注销消息回调
    SL:UnRegisterNetMsg(ssrNetMsgCfg.BOSSChall_RetData)
end

-- 刷新界面数据
function BossPanel:RefreshUI()
    if not self._ui then return end
   

end

function BossPanel:RefreshBossUI(_,_times,_,_,data)
    if data then
		-- 将JSON字符串转换为对象
		local dataObj = nil
		if type(data) == "string" and data ~= "" then
			dataObj = cjson.decode(data)
		elseif type(data) == "table" then
			dataObj = data
		end
        self._times = _times
        self._data = dataObj
        self:RefreshUI() 
    end
end

-- 当前列表渲染
function BossPanel:ListBossShow(idx, item)
    local val = FGUI:GetChild(item, "val")
    if self._curCfg and self._curCfg.TransferAS then
        local propData = self._curCfg.TransferAS[idx + 1]
        if propData then
            FGUI:GTextField_setText(val, propData[2])
        end
    end
end



return BossPanel