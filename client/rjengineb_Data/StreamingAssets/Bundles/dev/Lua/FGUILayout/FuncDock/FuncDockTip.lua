local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local FuncDockTip = class("FuncDockTip", BaseFGUILayout)
local FuncDockUtil = requireFGUILayout("FuncDock/FuncDockUtil")

-- 角色面板弹窗
function FuncDockTip:Create()
    self._ui = FGUI:ui_delegate(self.component)
    self.dialog_player_info = self._ui.dialog_player_info
    FGUIFunction:SetCloseUIWhenClickOutside(self)
    self:GetAllFGuiData()
    self:InitGridLayout()
    self:InitOnClickEvent()
end

-- 获取所有需要用到的组件和controller
function FuncDockTip:GetAllFGuiData()
    self.mask = self._ui.mask
    self.btn_close = FGUI:GetChild(self.dialog_player_info,"btn_close")
    self.text_player_name = FGUI:GetChild(self.dialog_player_info,"text_player_name")
    self.text_player_level = FGUI:GetChild(self.dialog_player_info,"text_player_level")
    self.text_player_sect = FGUI:GetChild(self.dialog_player_info,"text_player_sect")
    self.loader_player_head = FGUI:GetChild(self.dialog_player_info,"loader_player_head")
    self.grid_layout_btn = FGUI:GetChild(self.dialog_player_info,"grid_layout_btn")
    self.com_playerIcon = FGUI:GetChild(self.dialog_player_info,"com_playerIcon")
end

function FuncDockTip:InitOnClickEvent()
    FGUI:setOnClickEvent(self.mask,handler(self,self.OnClose))
    FGUI:setOnClickEvent(self.btn_close,handler(self,self.OnClose))
end

function FuncDockTip:InitGridLayout()
    FGUI:GList_itemRenderer(self.grid_layout_btn,handler(self,self.ListViewCellsItemRenderer))
    self.LineGap = FGUI:GList_getLineGap(self.grid_layout_btn)
    self.itemHeight = 50
end

function FuncDockTip:ListViewCellsItemRenderer(idx,item)
    local btnType = self.btnTypes[idx + 1]
    FGUI:setOnClickEvent(item,function()
        FuncDockUtil:DoFunction(btnType, self._data.targetId)
        FGUI:Close("FuncDock", "FuncDockTip")
    end)

    local btn_name = FuncDockUtil.BtnTypeShowName[btnType] or FuncDockUtil:GetBtnTypeShowNameDynamic(btnType) or ""
    FGUI:GButton_setTitle(item, btn_name)
end

-- 可以根据类别动态设置按钮
function FuncDockTip:InitData()
    FuncDockUtil.SetLayerType(self._data)
    self.btnTypes = FuncDockUtil:GetBtns(self._data.targetId,self._data.TipsType,self._data) or {}
    self:DynamicSetBgHeight()
end

-- 动态设置背景高度(已经在fgui做了动态对齐方式)
function FuncDockTip:DynamicSetBgHeight()
    local nums = #self.btnTypes
    local lines = math.ceil(nums / 2)
    local height = lines* self.itemHeight + lines*self.LineGap + 5
    FGUI:setHeight(self.grid_layout_btn,height)
end

function FuncDockTip:RefreshBtnGridLayout()
    FGUI:GList_setNumItems(self.grid_layout_btn, #self.btnTypes)
end

function FuncDockTip:Enter(data)
    if not data then
        SL:PrintEx("FuncDockTip data is nil")
        return
    end

    self._data = data
    self:InitData()
    self:RefreshUIContent()
    self:RegisterEvent()
end

function FuncDockTip:Exit()
    self:RemoveEvent()
end

-- 刷新UI内容
function FuncDockTip:RefreshUIContent()
    local headData = {}
    headData.AvatarID  = self._data.AvatarID
    headData.Job  = self._data.Job
    headData.Sex  = self._data.Sex
    headData.FrameID = self._data.FrameID
    FGUIFunction:SetCommonPlayerFrame(self.com_playerIcon,headData)
    FGUI:GTextField_setText(self.text_player_name,FGUIFunction:GetServerName(self._data.targetName))
    FGUI:GTextField_setText(self.text_player_level,"Lv."..self._data.Level)
    if self._data.GuildName and  self._data.GuildName ~= "" then
        FGUI:GTextField_setText(self.text_player_sect,GET_STRING(30000003) .. FGUIFunction:GetServerName((self._data.GuildName)))
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
function FuncDockTip:OnClose()
    FGUI:Close("FuncDock", "FuncDockTip")
end

function FuncDockTip:OnResponsePlayerData()
end

-----------------------------------注册事件--------------------------------------
function FuncDockTip:RegisterEvent()
end

function FuncDockTip:RemoveEvent()
end

return FuncDockTip
