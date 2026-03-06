local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local BagItemIcon = class("BagItemIcon", BaseFGUILayout)
SL:RequireFile("FGUILayout/Bag/BagCell")

function BagItemIcon:Create()
	self._ui = FGUI:ui_delegate(self.component)
end

function BagItemIcon:Enter(data)
	if data then
		self.typeCapture = data.typeCapture
		self.path = data.path
		self:Capture(data)
	end
end

function BagItemIcon:Exit()
end

function BagItemIcon:Capture(data)
    self.cacheBagCell = BagCell.new(0,data.itemData,true)
	local content = FGUI:GetChild(self.component,"bg")
	local itemContentView =ItemUtil:ItemShow_Create(data.itemData,content,{disableClick = true})
end
function BagItemIcon:OnClose()
    self.super.Close(self)
end

return BagItemIcon