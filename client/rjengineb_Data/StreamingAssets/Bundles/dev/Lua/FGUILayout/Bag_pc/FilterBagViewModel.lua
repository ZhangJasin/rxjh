local FilterBagViewModel = class("FilterBagViewModel")
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")

function FilterBagViewModel:ctor()
	self.bagViewModel = requireFGUILayout("Bag/BagViewModel")
	self:InitData()
end

function FilterBagViewModel:Bind(viewComponent)
	self.bagViewModel:Bind(viewComponent)
end
function FilterBagViewModel:UnBind()
	self.bagViewModel:UnBind()
end
function FilterBagViewModel:Enter()
	self.bagViewModel:Enter()
end

function FilterBagViewModel:Exit()
	self.bagViewModel:Exit()
end

function FilterBagViewModel:RefreshData()
	self.bagViewModel:RefreshData()
end

function FilterBagViewModel:InitData()
	self.bagViewModel:InitData()
end

function FilterBagViewModel:GetBagCellByIndex(index)
	return  self.bagViewModel:GetBagCellByIndex(index)
end
--通过viewIndex获取选择筛选页签之后的要显示的bagData
function FilterBagViewModel:GetCurShowBagCellData(viewIndex)
	return self.bagViewModel:GetCurShowBagCellData(viewIndex)
end

function FilterBagViewModel:GetCurShowBagCellDataAndViewIndexByPos(pos)
	return self.bagViewModel:GetCurShowBagCellDataAndViewIndexByPos(pos)
end

function FilterBagViewModel:GetItemFilterType(v)
	return ItemUtil:GetItemFilterType(v)
end


function FilterBagViewModel:DivideItem()
	self.bagViewModel:DivideItem()
end


function FilterBagViewModel:GetCellDataPosInTypeDic(itemData)
	return self.bagViewModel:GetCellDataPosInTypeDic(itemData)
end

function FilterBagViewModel:SelectFilter(index)
	self.bagViewModel.selectType = index
end

function FilterBagViewModel:CalculateShowCount()
	return self.bagViewModel:CalculateShowCount()
end

--------------------------- 注册事件 -----------------------------
function FilterBagViewModel:RegisterEvent()
	self.bagViewModel:RegisterEvent()
end

function FilterBagViewModel:UnRegisterEvent()
	self.bagViewModel:UnRegisterEvent()
end


return  FilterBagViewModel