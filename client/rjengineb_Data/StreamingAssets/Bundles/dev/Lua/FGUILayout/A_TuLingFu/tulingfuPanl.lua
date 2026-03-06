--tulingfuPanl = {}

local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local tulingfuPanl = class("tulingfuPanl", BaseFGUILayout)
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemShow = SL:RequireFile("FGUILayout/Item/ItemShow")
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")

-- 添加数据层引用
local TulingData = SL:RequireFile("FGUILayout/A_TuLingFu/tulingfuPanlData"):Get()
-- 创建界面并绑定所有UI事件

function tulingfuPanl:Create()
    -- 移除全局变量赋值，改为本地变量
    self.itemobjlist = {}
    self._eventTokens = {}  -- 存储事件订阅token

    -- 获取界面代理
    self._ui = FGUI:ui_delegate(self.component)

    -- 设置点击界面外关闭UI
    FGUI:SetCloseUIWhenClickOutside(self)

    -- 关闭按钮事件绑定
    FGUI:setOnClickEvent(self._ui.btn_close, function()  --关闭按钮
        FGUI:Close("A_TuLingFu", "tulingfuPanl")
    end)

    -- 获取并绑定控制器组件
    self.tulingControlle = FGUI:getController(self.component, "tanchaung")

    -- 初始化添加和删除界面的代理
    self.panl_add = FGUI:ui_delegate(self._ui.panl_add)
    self.panl_del = FGUI:ui_delegate(self._ui.panl_del)


    -- 删除按钮事件绑定：始终切换到索引 2
    FGUI:setOnClickEvent(self._ui.btn_del, function()  --删除
        FGUI:Controller_setSelectedIndex(self.tulingControlle, 2)
    end)

    -- 添加按钮事件绑定：始终切换到索引 1
    FGUI:setOnClickEvent(self._ui.btn_add, function()  --记录
        FGUI:GTextField_setText(self.panl_add.n2, SL:GetValue("MAP_NAME") or "地图名称")
        FGUI:Controller_setSelectedIndex(self.tulingControlle, 1)
    end)

    -- 传送按钮事件绑定
    FGUI:setOnClickEvent(self._ui.btn_move, function()  --传送
        local state = TulingData:GetState()
        TulingData:RequestUseTuLing(state.Index)
    end)

    -- 清除传送选择按钮事件绑定
    FGUI:setOnClickEvent(self._ui.btnDie, function()  --传送
        TulingData:SetIndex(0)
        FGUI:GList_clearSelection(self.movelist)
        FGUI:GButton_setSelected(self._ui.btnHCF, false)
    end)
    -- 清除传送选择按钮事件绑定
    FGUI:setOnClickEvent(self._ui.btnHCF, function()  --传送
        TulingData:SetIndex(-1)
        FGUI:GList_clearSelection(self.movelist)
        FGUI:GButton_setSelected(self._ui.btnDie, false)
    end)

    -- 初始化移动列表并绑定相关回调
    self.movelist = self._ui.movelist
    FGUI:GList_itemRenderer(self.movelist, handler(self, self.ListViewCellMove))
    FGUI:GList_setDefaultItem(self.movelist, "ui://h5wbakzpoqrp8")
    FGUI:GList_setVirtual(self.movelist)
    FGUI:GList_setNumItems(self.movelist, 6)
    FGUI:GList_addOnClickItemEvent(self.movelist, function(context)
        local index = FGUI:GetIntData(context.data)
        TulingData:SetIndex(index)
        TulingData:SetName("")
        FGUI:GButton_setSelected(self._ui.btnDie, false)
        FGUI:GButton_setSelected(self._ui.btnHCF, false)
    end)

    -- 绑定添加界面的关闭按钮（删除界面）
    FGUI:setOnClickEvent(self.panl_add.closebg, function()  --关闭按钮
        FGUI:Controller_setSelectedIndex(self.tulingControlle, 0)
    end)
    -- 绑定删除界面的关闭按钮
    FGUI:setOnClickEvent(self.panl_del.closebg, function()  --关闭按钮
        FGUI:Controller_setSelectedIndex(self.tulingControlle, 0)
    end)

    -- 删除界面按钮事件绑定
    FGUI:setOnClickEvent(self.panl_del.n6, function()
        FGUI:Controller_setSelectedIndex(self.tulingControlle, 0)
    end)
    FGUI:setOnClickEvent(self.panl_del.n7, function()  --删除记录点
        local state = TulingData:GetState()
        TulingData:RequestDelPos(state.Index)
        FGUI:Controller_setSelectedIndex(self.tulingControlle, 0)
    end)

    -- 添加界面按钮事件绑定
    FGUI:setOnClickEvent(self.panl_add.n6, function()
        FGUI:Controller_setSelectedIndex(self.tulingControlle, 0)
    end)
    FGUI:setOnClickEvent(self.panl_add.n7, function()  --添加记录点
        local state = TulingData:GetState()
        TulingData:RequestAddPos(state.Index, state.Name)
        FGUI:Controller_setSelectedIndex(self.tulingControlle, 0)
    end)

    -- 文本输入框改变事件，实时更新数据层名称
    FGUI:GTextInput_setOnChanged(self.panl_add['srk1'], function(context)
        local text = FGUI:GTextInput_getText(self.panl_add['srk1'])
        -- print(text)
        TulingData:SetName(text)
    end)

    -- 订阅数据层事件
    self:_subscribeDataEvents()
end
-- 界面销毁时清理
function tulingfuPanl:Destroy()
    self:_unsubscribeDataEvents()
end

-- 订阅数据层事件
function tulingfuPanl:_subscribeDataEvents()
    -- 数据更新事件
    self._eventTokens.dataUpdate = TulingData:Subscribe("data_update", function(data)
        self:OnDataUpdate(data)
    end)

end

-- 取消订阅数据层事件
function tulingfuPanl:_unsubscribeDataEvents()
    for _, token in pairs(self._eventTokens) do
        TulingData:Unsubscribe(token)
    end
    self._eventTokens = {}
end

-- 列表渲染单元格函数
-- 根据索引 idx 渲染列表单元格内容
function tulingfuPanl:ListViewCellMove(idx, item)
    -- 设置当前单元格数据为索引 + 1
    FGUI:SetIntData(item, idx + 1)
    
    local title = FGUI:GetChild(item, "title")
    local mapname = FGUI:GetChild(item, "mapname")
    local name = FGUI:GetChild(item, "name")

    -- 根据数据层中的数据决定显示样式
    local state = TulingData:GetState()
    if state.TuLingPosTab["" .. (idx + 1)] then
        FGUI:setVisible(title, false)
        FGUI:setVisible(mapname, true)
        FGUI:setVisible(name, true)
        local nameValue = state.TuLingPosTab["" .. (idx + 1)][5]
        FGUI:GTextField_setText(mapname, "" .. state.TuLingPosTab["" .. (idx + 1)][4])
        FGUI:GTextField_setText(name, "" .. nameValue)
    else
        FGUI:setVisible(title, true)
        FGUI:setVisible(mapname, false)
        FGUI:setVisible(name, false)
    end
end

-- 打开界面
-- data.param1 用于初始化 tulingfuUI.TuLingPosTab 数据
-- 数据更新回调
function tulingfuPanl:OnDataUpdate(data)
    FGUI:GList_refreshVirtualList(self.movelist) --刷新虚拟列表
end

return tulingfuPanl