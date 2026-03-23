TreasureShop = {}

function TreasureShop.main()
	SL:RegisterLUAEvent(LUA_EVENT_NPCSTORE_RECY_RES, "TreasureShop", TreasureShop.onResRecycleItem)
end


-- costList结构


-- 请求购买的通用弹窗
function TreasureShop.ReqBuyDialog(costList,callback)
	if not costList then
		return
	end

	local len = table.nums(costList)
	if len ~= 1 then
		local index = 1
		local str = ""
		for k,v in pairs(costList) do
			if index ~= 1 then
				local coinData = SL:GetValue("ITEM_DATA", v.costID)
				str = string.format("%s[color=#FF00000]%s%s[/color]%s", str, v.costCount, coinData.Name, ((index ~= len) and SL:GetValue("I18N_STRING",30000401) or ""))
			end
			index = index + 1
		end
		local data = {}
		data.str =  string.format(SL:GetValue("I18N_STRING",30000400),str)
		data.btnDesc = {SL:GetValue("I18N_STRING",1001),SL:GetValue("I18N_STRING",1000)}
		data.callback = function(num)
			if num == 1 then
				if callback then callback() end
			elseif num == 2 then
			end
			FGUIFunction:CloseItemTips()
		end
		SL:OpenCommonDialog(data)
	else
		if callback then callback() end
	end
end


-- 回收消息
function TreasureShop.onResRecycleItem(code)
	if code > 0 then return end
	if code == 0 then
		SL:ShowSystemTips(GET_STRING(30000107))
	elseif code == -1 then
		SL:ShowSystemTips(GET_STRING(30000104))
	elseif code == -2 then
		SL:ShowSystemTips(GET_STRING(30000105))
	else
		SL:ShowSystemTips(GET_STRING(30000106))
	end
end