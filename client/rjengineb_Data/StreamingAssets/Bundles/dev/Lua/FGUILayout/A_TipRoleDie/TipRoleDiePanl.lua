local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local TipRoleDiePanlData = require("FGUILayout/A_TipRoleDie/TipRoleDiePanlData")
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")

local TipRoleDiePanl = class("TipRoleDiePanl", BaseFGUILayout)

function TipRoleDiePanl:Create()
    self.itemobjlist = {}
    self._ui = FGUI:ui_delegate(self.component)
    
    -- 保存回调函数引用
    self.dataUpdateCallback = handler(self, self.OnDataUpdate)
    
    -- 订阅数据更新
    TipRoleDiePanlData:Subscribe(self.dataUpdateCallback)
    TipRoleDiePanlData:ResetTime()
    -- 初始化UI
    self:InitUI()
    
    -- 启动倒计时
    self:StartCountdown()
end

function TipRoleDiePanl:Destroy()
    -- 取消订阅
    TipRoleDiePanlData:Unsubscribe(self.dataUpdateCallback)
    
    -- 清理定时器
    if self.dsqid then
        SL:UnSchedule(self.dsqid)
        self.dsqid = nil
    end
end

function TipRoleDiePanl:InitUI()
    local cfgData = TipRoleDiePanlData:GetConfigData()
    
    -- 设置标题
    FGUI:GTextField_setText(self._ui['title'], cfgData[1]['title'])
    FGUI:GTextField_setAlign(self._ui['title'], 1)
    
    -- 初始化物品和按钮
    for i=1,#cfgData do
        if self._ui['item'..i] and cfgData[i]['xhitem_arr'] then
            local itemData = SL:GetValue("ITEM_DATA", cfgData[i]['xhitem_arr'][1])
            local extData = {}
            extData.hideTip = false
            extData.itemTipData = itemData
            extData.clickCallback = false
            extData.doubleClickCallback = true
            extData.bgVisible = true
            self.itemobjlist[i] = ItemUtil:ItemShow_Create(itemData, self._ui['item'..i], extData)
            local image_bind = FGUI:GetChild(self._ui['item'..i], "Image_bind")
            FGUI:setVisible(image_bind, false)
            
            FGUI:GTextField_setText(self._ui['xhfont'..i], "消耗：         "..cfgData[i]['xhitem_arr'][2])
        end
        
        -- 设置按钮事件
        FGUI:setOnClickEvent(self._ui['n'..i], function()
            ssrMessage:sendmsgEx("TipsRealiveBox", "openshow", {i})
        end)
        
        -- 设置按钮文字
        FGUI:GTextField_setText(self._ui['btnfont'..i], TipRoleDiePanlData:GetBtnFont(i))
        FGUI:GTextField_setAlign(self._ui['btnfont'..i], 1)
    end
end

function TipRoleDiePanl:OnDataUpdate(data)
    -- 更新倒计时显示
    if self._ui and self._ui['daojishi'] then
        local cfgData = TipRoleDiePanlData:GetConfigData()
        FGUI:GTextField_setText(self._ui['daojishi'], string.format(cfgData[1]['realivefont'], ""..data.time))
        FGUI:GTextField_setAlign(self._ui['daojishi'], 1)
    end
end

function TipRoleDiePanl:StartCountdown()
    local function realivedjs()
        if TipRoleDiePanlData:GetTime() == 0 then
            ssrMessage:sendmsgEx("TipsRealiveBox", "openshow", {4})
            SL:UnSchedule(self.dsqid)
            self.dsqid = nil
        end
        TipRoleDiePanlData:DecreaseTime()
    end
    self.dsqid = SL:Schedule(realivedjs, 1)
end


return TipRoleDiePanl