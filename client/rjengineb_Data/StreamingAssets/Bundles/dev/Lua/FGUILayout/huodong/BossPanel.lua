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

    self.tipsControlle = FGUI:getController(self.component, "tips")
	self.tipsbg = FGUI:ui_delegate(self._ui.panel_tips)
     -- 点击tips
    FGUI:setOnClickEvent(self._ui.btn_tips, handler(self, self.btnTipsClicked))
    FGUI:setOnClickEvent(self.tipsbg.close_tip, handler(self, self.btnTipsClicked))

    -- 列表渲染
    FGUI:GList_itemRenderer(self._ui.list_boss, handler(self, self.ListBossShow))
end

function BossPanel:Enter()
    -- 注册消息回调
    SL:RegisterNetMsg(ssrNetMsgCfg.BOSSChall_RetData, handler(self, self.RefreshBossUI))
    SL:RegisterNetMsg(ssrNetMsgCfg.BOSSChall_Begin, handler(self, self.BeginChall))
    ssrMessage:sendmsgEx("BossChall", "getData")
end

function BossPanel:Destroy()
end
function BossPanel:Exit()
    -- 注销消息回调
    SL:UnRegisterNetMsg(ssrNetMsgCfg.BOSSChall_RetData)
end

function BossPanel:btnTipsClicked()
    FGUI:Controller_setSelectedIndex(self.tipsControlle,self.tipsControlle.selectedIndex == 1 and 0 or 1)
end
-- 刷新界面数据
function BossPanel:RefreshUI()
    if not self._ui then return end
    
    -- 悬赏令数量
    local itemCount = SL:GetValue("ITEM_COUNT", 3962) or 0
    FGUI:GTextField_setText(self._ui.itemCount, itemCount)
    
    -- 已调整次数
    local maxDailyCount = SysConstant['Boss_Day_MAX_Count'] and tonumber(SysConstant['Boss_Day_MAX_Count']['Value']) or 20
    FGUI:GTextField_setText(self._ui.challCount, string.format("%s/%s", self._times or 0, maxDailyCount))
    
    -- 刷新BOSS列表
    if self._data and #self._data > 0 then
        FGUI:GList_setNumItems(self._ui.list_boss, #self._data)
    else
        FGUI:GList_setNumItems(self._ui.list_boss, 0)
    end
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

function BossPanel:BeginChall(_,_times)
    FGUI:Close("huodong", "BossPanel")
end
-- BOSS列表渲染
function BossPanel:ListBossShow(idx, item)
    if not self._data then return end
    
    local bossInfo = self._data[idx + 1]
    if not bossInfo or not bossInfo[1] or bossInfo[1] == 0 then
        FGUI:setVisible(item, false)
        return
    end
    FGUI:setVisible(item, true) 

    local bossId = bossInfo[1]
    local bossCfg = BossInfo_Cfg[bossId]
    local challCount = bossInfo[2] or 0
    
    -- 获取BOSS信息
    local bossName = bossCfg and bossCfg.name or "未知BOSS"
    local bossLv = bossCfg and bossCfg.lv or 0
    local bossGrade = bossCfg and bossCfg.grade or 1
    local bossIcon = bossCfg and bossCfg.icon or ""
    local specDrop = bossCfg and bossCfg.specDrop or 0
    local dropList = bossCfg and bossCfg.dropList or {}

    local bg_grade = FGUI:GetChild(item, "grade")
    if bg_grade then
        FGUI:GLoader_setUrl(bg_grade, string.format("ui://huodong/bg%s", bossGrade))
    end
    
    -- 设置名称
    local text_name = FGUI:GetChild(item, "name")
    if text_name then
        FGUI:GTextField_setText(text_name, bossName)
    end
    
    -- 设置等级
    local text_lv = FGUI:GetChild(item, "lv")
    if text_lv then
        FGUI:GTextField_setText(text_lv, string.format("%s级", bossLv))
    end
    
    -- 设置图标
    local bg_icon = FGUI:GetChild(item, "icon")
    if bg_icon then        
        FGUI:GLoader_setUrl(bg_icon, SL:GetValue("MONSTER_ICON", bossId) or "",nil, true)
    end
    
    -- 设置特殊道具显示 (specDrop)
    local specItem = FGUI:GetChild(item, "specItem")
    if specItem then
        if FGUI:GetChildCount(specItem) > 0 then            
            FGUI:RemoveChildAt(specItem, 0, true)
        end
        if specDrop > 0 then
            local extData = {
                hideTip = false,
                itemTipData = {Index = specDrop, Count = 1},
                clickCallback = false,
                doubleClickCallback = false,
                bgVisible = true
            }
            ItemUtil:ItemShow_Create({Index = specDrop, Count = 1}, specItem, extData)
        end
    end
    
    -- 设置奖励道具 item1, item2, item3 (从 dropList 获取)
    for i = 1, 3 do
        local rewardId = dropList[i]
        local rewardItem = FGUI:GetChild(item, string.format("item%s", i))
        if rewardItem then
            if FGUI:GetChildCount(rewardItem) > 0 then            
                FGUI:RemoveChildAt(rewardItem, 0, true)
            end
            if rewardId and rewardId > 0 then
                local rewardItemData = SL:GetValue("ITEM_DATA", rewardId)
                if rewardItemData then
                    local extData = {
                        hideTip = false,
                        itemTipData = {Index = rewardId, Count = 1},
                        clickCallback = false,
                        doubleClickCallback = false,
                        bgVisible = true
                    }
                    ItemUtil:ItemShow_Create({Index = rewardId, Count = 1}, rewardItem, extData)
                end
            end
        end
    end
    
    -- 挑战按钮
    local btn_chall = FGUI:GetChild(item, "btn_chall")
    if btn_chall then
        -- 获取挑战次数限制
        local maxSingleCount = SysConstant['Boss_Chall_Count'] and tonumber(SysConstant['Boss_Chall_Count']['Value']) or 5
        local maxDailyCount = SysConstant['Boss_Day_MAX_Count'] and tonumber(SysConstant['Boss_Day_MAX_Count']['Value']) or 20
        
        FGUI:GButton_setTitle(btn_chall, string.format("挑战：%s/%s", challCount, maxSingleCount))
        -- 检查是否可以挑战
        local canChall = challCount < maxSingleCount and (self._times or 0) < maxDailyCount
        FGUI:setTouchEnabled(btn_chall, canChall)
        
        FGUI:setOnClickEvent(btn_chall, function()
            FGUI:delayTouchEnabled(btn_chall, FGUIDefine.DelayClickTime)
            SL:OpenCommonDialog({
                title = '提示',
                str = self._times < 2 and "本次挑战将消耗一次免费挑战次数，是否进行挑战？" or "本次挑战将消耗1个悬赏令进行挑战，是否进行挑战？",
                btnDesc = {"取消", "确定"},
                callback = function(tag)
                    if tag == 2 then
                        ssrMessage:sendmsgEx("BossChall", "chall", {idx + 1})
                    end
                end
            })
            
        end)
    end
    
    -- 刷新按钮
    local btn_sx = FGUI:GetChild(item, "btn_sx")
    if btn_sx then
        -- 检查刷新卷数量 (ID: 3961)
        local refreshItemCount = SL:GetValue("ITEM_COUNT", 3961) or 0
        --FGUI:setTouchEnabled(btn_sx, refreshItemCount > 0)
        
        FGUI:setOnClickEvent(btn_sx, function()
            FGUI:delayTouchEnabled(btn_sx, FGUIDefine.DelayClickTime)
            SL:OpenCommonDialog({
                title = '提示',
                str = '是否使用1个刷新卷刷新BOSS？',
                btnDesc = {"取消", "确定"},
                callback = function(tag)
                    if tag == 2 then
                        ssrMessage:sendmsgEx("BossChall", "refresh", {idx + 1})
                    end
                end
            })            
        end)
    end    
end

return BossPanel