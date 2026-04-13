ItemTips = {}
local ItemUtil = SL:RequireFile("FGUILayout/Item/ItemUtil")
local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")

local HIDE_TIP_EVENT = "HIDE_TIP_EVENT"
function ItemTips.Init()
    FGUI:StageEvent_AddListener(HIDE_TIP_EVENT,function() ItemTips.CloseItemTips()  end,2)
end
ItemTips.Init()
--[[
	data.from           --从哪个界面打开Tip,用于逻辑判断SL:GetValue("ITEMFROMUI_ENUM")
	data.itemData		--物品数据
    data.hideCompare    --如果是装备，判断否隐藏装备比较
]]
function ItemTips.ShowTip(data)
    if not data then
        return
    end
    local itemData  = data.itemData
    local from = data.from

    local groupId = itemData.TipsGroupId or 7
    local groupCfg = SL:GetValue("ITEMTIPS_GROUP_CONFIG", groupId)
    if groupCfg and groupCfg.TipsType and groupCfg.TipsType == 2 then
        ItemTips.ShowEquipTip(data)
    else
        ItemTips.ShowItemTip(data)
    end

end

function ItemTips.ShowItemTip(data)
    FGUI:Open("Common", "CommonItemTip",data)
end

function ItemTips.ShowEquipTip(data)
    FGUI:Open("Common", "CommonEquipTip",data)
end

function ItemTips.CloseItemTips()
    FGUI:Close("Common", "CommonEquipTip")
    FGUI:Close("Common", "CommonItemTip")
end



local BtnCfg = {
    [1] = {
        btnName     = "使用",
        func = function (data)
            -- 检查是否为回城符,如果是则直接调用回城接口
            local BACK_CITY_ITEM_IDS = { 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140 }
            local isBackCityItem = false
            for i = 1, #BACK_CITY_ITEM_IDS do
                if BACK_CITY_ITEM_IDS[i] == data.ID then
                    isBackCityItem = true
                    break
                end
            end
            
            if isBackCityItem then
                local righttoppanlData = requireFGUILayout("A_Right/righttoppanlData")
                righttoppanlData:Get():RequestBackCity({ data.ID })
                return
            end
            SL:RequestUseItem(data)
        end
    },
    [2] = {
        btnName     = "佩戴",
        func = function (data)
            SL:RequestUseItem(data)
        end
    },
    [3] = {
        btnName     = "拆分",
        color       = "#93683b",
        func = function (data)
            local uiData = {itemData = data,maxNum = data.OverLap}

            uiData.btnClicked = function(isOK,num)
                if isOK == 1 then
                    if num > 0 then

                        SL:RequestSplitItem(data, num)
                    end
                    FGUI:Close("Common", "CommonItemSplitDialog")
                elseif isOK == 2 then
                    FGUI:Close("Common", "CommonItemSplitDialog")
                end

             end
            FGUIFunction:OpenItemSplitPop(uiData)
        end
    },
    [4] = {
        btnName     = "放入", -- 仓库
        func        = function(data)
            FGUIFunction:RequestSaveItemToNpcStorageInCurPage(data)
        end
    },
    [5] = {
        btnName     = "取出", -- 仓库
        func        = function(data)
            SL:RequestPutOutStorageData(data)
        end
    },
    [6] = {
        btnName     = "丢弃",
        func        = function(itemData)
            FGUIFunction:DropItem(itemData)
        end
    },
    [7] = {
        btnName     = "卸下",
        color       = "#93683b",
        func = function(data)
            SL:TakeOffPlayerEquip(data)
        end
    },
    [9] = {
        btnName     = "取出", --面对面交易
        func        = function (data)
            local isMyLock = SL:GetValue("TRADE_MY_STATUS") == 1
            local isTargetLock = SL:GetValue("TRADE_TARGET_STATUS") == 1
            if isMyLock or isTargetLock then
               SL:ShowSystemTips(GET_STRING(90180031))
               return
            end
            SL:RemoveItemFromTrade(data.MakeIndex)
        end
    },
    [10] = {
        btnName     = "放入", --附加仓库
        func        = function (itemData)
            if SL:GetValue("STORAGE_EX_IS_FULL") then
			    SL:ShowSystemTips(GET_STRING(60010006))
			    return
		    end
            if itemData.OverLap > 1 then
            	-- 弹出数量输入
            	local data = {}
            	data.title = GET_STRING(90010006)
            	data.maxNum = itemData.OverLap
            	data.callback_yes = function (input)
            		local num = tonumber(input)
            		if num and num > 0 then
            			SL:RequestAddItemToStorageEx(itemData.MakeIndex, num)
            		end          
            	end
            	FGUIFunction:OpenCommonNumberInputPanel(data)
            else
            	-- 放入附加仓库
            	SL:RequestAddItemToStorageEx(itemData.MakeIndex, 1)
            end
        end
    },
    [11] = {
        btnName     = "取出", --附加仓库
        func        = function (slotInfo)
            if not slotInfo then return end
            if slotInfo.OverLap > 1 then
            	-- 弹出数量输入
            	local data = {}
            	data.title = GET_STRING(90010006)
            	data.maxNum = slotInfo.OverLap
            	data.callback_yes = function (input)
            		local num = tonumber(input)
            		if num and num > 0 then
            			SL:RequestRemoveItemFromStorageEx(slotInfo.Index, num, slotInfo.Params[1], slotInfo.Params[2])	
            		end          
            	end
            	FGUIFunction:OpenCommonNumberInputPanel(data)
            else
            	SL:RequestRemoveItemFromStorageEx(slotInfo.Index, 1, slotInfo.Params[1], slotInfo.Params[2])	
            end
        end
    },
    [-1] = {
        btnName  = "",
        func = function (data)
            print("Not ClickEvent....")
        end
    }
}

function ItemTips.GetBtnCfg(btnType)
     return BtnCfg[btnType] or BtnCfg[-1]
end
