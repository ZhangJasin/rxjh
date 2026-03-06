local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local PCFuncDockTip = class("PCFuncDockTip", BaseFGUILayout)
local FuncDockUtil = requireFGUILayout("FuncDock_pc/FuncDockUtil")

-- 角色面板弹窗
function PCFuncDockTip:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self.dialog_player_info = self._ui.dialog_player_info
    FGUI:SetCloseUIWhenClickOutside(self)
    self:GetAllFGuiData()
    self:InitGridLayout()
    self:InitOnClickEvent()
end

-- 获取所有需要用到的组件和controller
function PCFuncDockTip:GetAllFGuiData()
    self.mask = self._ui.mask
    self.btn_close = FGUI:GetChild(self.dialog_player_info,"btn_close")
    self.text_player_name = FGUI:GetChild(self.dialog_player_info,"text_player_name")
    self.text_player_level = FGUI:GetChild(self.dialog_player_info,"text_player_level")
    self.text_player_sect = FGUI:GetChild(self.dialog_player_info,"text_player_sect")
    self.loader_player_head = FGUI:GetChild(self.dialog_player_info,"loader_player_head")
    self.grid_layout_btn = FGUI:GetChild(self.dialog_player_info,"grid_layout_btn")
    self.com_playerIcon = FGUI:GetChild(self.dialog_player_info,"com_playerIcon")
end

function PCFuncDockTip:InitOnClickEvent()
    FGUI:setOnClickEvent(self.mask,handler(self,self.OnClose))
    FGUI:setOnClickEvent(self.btn_close,handler(self,self.OnClose))
end

function PCFuncDockTip:InitGridLayout()
    FGUI:GList_itemRenderer(self.grid_layout_btn,handler(self,self.ListViewCellsItemRenderer))
    self.LineGap = FGUI:GList_getLineGap(self.grid_layout_btn)
    self.itemHeight = 36
end

function PCFuncDockTip:ListViewCellsItemRenderer(idx,item)
    local btnType = self.btnTypes[idx + 1]
    FGUI:setOnClickEvent(item,function()
        FuncDockUtil:DoFunction(btnType, self._data.targetId)
        FGUI:Close("FuncDock", "PCFuncDockTip")
    end)

    local btn_name = FuncDockUtil.BtnTypeShowName[btnType] or FuncDockUtil:GetBtnTypeShowNameDynamic(btnType) or ""
    FGUI:GButton_setTitle(item, btn_name)
end

-- 可以根据类别动态设置按钮
function PCFuncDockTip:InitData()
    FuncDockUtil.SetLayerType(self._data)
    self.btnTypes = FuncDockUtil:GetBtns(self._data.targetId,self._data.TipsType,self._data) or {}
    self:DynamicSetBgHeight()
end

-- 动态设置背景高度(已经在fgui做了动态对齐方式)
function PCFuncDockTip:DynamicSetBgHeight()
    local nums = #self.btnTypes
    local lines = math.ceil(nums / 2)
    local height = 4 + lines * self.itemHeight + lines * self.LineGap
    FGUI:setHeight(self.grid_layout_btn,height)
end

function PCFuncDockTip:RefreshBtnGridLayout()
    FGUI:GList_setNumItems(self.grid_layout_btn, #self.btnTypes)
end

function PCFuncDockTip:Enter(data)
    if not data then
        SL:PrintEx("PCFuncDockTip data is nil")
        return
    end

    ------------- 解决面板字体糊的问题，坐标取整   -------------
    local x,y = FGUI:getPosition(self.dialog_player_info)
    FGUI:setPosition(self.dialog_player_info,math.floor(x),math.floor(y))
    ------------------------------------------------------------


    self._data = data
    self:InitData()
    self:RefreshUIContent()
    self:RegisterEvent()
end

function PCFuncDockTip:Exit()
    self:RemoveEvent()
end

-- 刷新UI内容
function PCFuncDockTip:RefreshUIContent()
    local headData = {}
    headData.AvatarID  = self._data.AvatarID
    headData.Job  = self._data.Job
    headData.Sex  = self._data.Sex
    headData.FrameID = self._data.FrameID
    FGUIFunction:SetCommonPlayerFrame(self.com_playerIcon,headData)
    FGUI:GTextField_setText(self.text_player_name,FGUIFunction:GetServerName(self._data.targetName))
    FGUI:GTextField_setText(self.text_player_level,"Lv."..self._data.Level)
    if self._data.GuildName and  self._data.GuildName ~= "" then
        FGUI:GTextField_setText(self.text_player_sect,GET_STRING(30000003) .. FGUIFunction:GetServerName(self._data.GuildName))
    else
        FGUI:GTextField_setText(self.text_player_sect,GET_STRING(30000008))
    end
    self:RefreshBtnGridLayout()

    if self._data.pos then
        if self._data.pos.x then
            FGUI:setPositionX(self.dialog_player_info, self._data.pos.x)
        end

        if self._data.pos.y then
            FGUI:setPositionX(self.dialog_player_info, self._data.pos.y)
        end
    end
end

-- 关闭面板
function PCFuncDockTip:OnClose()
    FGUI:Close("FuncDock_pc", "PCFuncDockTip")
end

function PCFuncDockTip:OnResponsePlayerData()
end

-----------------------------------注册事件--------------------------------------
function PCFuncDockTip:RegisterEvent()
end

function PCFuncDockTip:RemoveEvent()
end

return PCFuncDockTip
