--campPanl = {}

local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local campPanl = class("campPanl", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemShow = SL:RequireFile("FGUILayout/Item/ItemShow")
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")
local SysConstant                 =  require("game_config/cfgcsv/SysConstant")                 -- 常量
local Language                    =  require("game_config/cfgcsv/Language")                    -- 文本描述表
-- 创建界面并绑定所有UI事件

function campPanl:Create()
    -- 获取界面代理
    self._ui = FGUI:ui_delegate(self.component)

    -- 设置点击界面外关闭UI
    FGUI:SetCloseUIWhenClickOutside(self)

    -- 恭喜获得道具
    self.GXHDItemList = SysConstant['Reward_JoinZhenYing']['Value'] or {{}}
    -- 恭喜获得界面控制器
    self.gxhdControlle = FGUI:getController(self.component, "gxhd")
    -- 恭喜获得弹窗相关
    self.gxhdbg = FGUI:ui_delegate(self._ui.panl_gxhd)
    FGUI:setOnClickEvent(self.gxhdbg.bg, function()
        if campPanl.dsqid then
            SL:UnSchedule(campPanl.dsqid)
            campPanl.dsqid = false
        end
        FGUI:Close("Transfer", "campPanl")
    end)
    -- 恭喜获得奖励列表渲染
    FGUI:GList_itemRenderer(self.gxhdbg['n8'], handler(self, self.ListGXHDShow))
    FGUI:GList_setDefaultItem(self.gxhdbg['n8'], "ui://5rez3obxqtrmv6e")
    FGUI:GList_setVirtual(self.gxhdbg['n8'])
    FGUI:GList_setNumItems(self.gxhdbg['n8'], #self.GXHDItemList)
    FGUI:GList_refreshVirtualList(self.gxhdbg['n8'])

    -- 道具展示列表渲染
    FGUI:GList_itemRenderer(self._ui.itemlist, handler(self, self.ListItemShow))
    FGUI:GList_setDefaultItem(self._ui.itemlist, "ui://5rez3obxqtrmv6e")
    FGUI:GList_setVirtual(self._ui.itemlist)
    FGUI:GList_setNumItems(self._ui.itemlist, #self.GXHDItemList)
    FGUI:GList_refreshVirtualList(self._ui.itemlist)

    FGUI:setOnClickEvent(self._ui.n58, function()
        SL:SendNetMsg(9999, 12, nil, nil, nil)
        FGUI:Close("Transfer", "campPanl")
    end)
    FGUI:setOnClickEvent(self._ui.n57, function()
        SL:SendNetMsg(9999, 13, nil, nil, nil)
        FGUI:Close("Transfer", "campPanl")
    end)
    FGUI:setOnClickEvent(self._ui.n64, function()
        SL:SendNetMsg(9999, 14, nil, nil, nil)
        self:daojishi()
        FGUI:Controller_setSelectedIndex(self.gxhdControlle,1)
    end)
    FGUI:GRichTextField_setText(self._ui.font1,Language['GoodDec_JoinZhenYing']['Dec'])
    FGUI:GRichTextField_setText(self._ui.font2,Language['EvilDec_JoinZhenYing']['Dec'])
end

-- 道具展示列表渲染
function campPanl:ListItemShow(idx, item)
    local itemRoot = FGUI:GetChild(item, "itemRoot")
    if FGUI:GetChildCount(itemRoot) > 0 then
        FGUI:RemoveChildAt(itemRoot, 0, true)
    end
    local reward = self.GXHDItemList[idx + 1]
    if reward then
        local itemData = SL:GetValue("ITEM_DATA", reward[1])
        local extData = {
            hideTip = false,
            itemTipData = itemData,
            clickCallback = false,
            doubleClickCallback = true,
            bgVisible = true,
            OverLap = reward[2]
        }
        ItemUtil:ItemShow_Create(itemData, itemRoot, extData)
    end
end

-- 恭喜获得奖励列表渲染
function campPanl:ListGXHDShow(idx, item)
    local itemRoot = FGUI:GetChild(item, "itemRoot")
    if FGUI:GetChildCount(itemRoot) > 0 then
        FGUI:RemoveChildAt(itemRoot, 0, true)
    end
    local reward = self.GXHDItemList[idx + 1]
    if reward then
        local itemData = SL:GetValue("ITEM_DATA", reward[1])
        local extData = {
            hideTip = false,
            itemTipData = itemData,
            clickCallback = false,
            doubleClickCallback = true,
            bgVisible = true,
            OverLap = reward[2]
        }
        ItemUtil:ItemShow_Create(itemData, itemRoot, extData)
    end
end

-- 恭喜获得弹窗倒计时自动关闭
function campPanl:daojishi()
    if campPanl.dsqid then
        SL:UnSchedule(campPanl.dsqid)
    end
    campPanl.time = 3
    FGUI:GTextField_setText(self.gxhdbg['daojishi'], campPanl.time .. "秒后自动关闭")
    FGUI:GTextField_setAlign(self.gxhdbg['daojishi'], 1)
    local function realivedjs()
        campPanl.time = campPanl.time - 1
        FGUI:GTextField_setText(self.gxhdbg['daojishi'], string.format("%s秒后自动关闭", "" .. campPanl.time))
        FGUI:GTextField_setAlign(self.gxhdbg['daojishi'], 1)
        if campPanl.time == 0 then
            SL:UnSchedule(campPanl.dsqid)
            campPanl.dsqid = false
            FGUI:Controller_setSelectedIndex(self.gxhdControlle,0)
            FGUI:Close("Transfer", "campPanl")
        end
    end
    campPanl.dsqid = SL:Schedule(realivedjs, 1)
end

-- 打开界面
function campPanl:Open(data)
    FGUI:Open("Transfer", "campPanl", {}, FGUI_LAYER.TOP, {destroyTime = 1})
end


return campPanl