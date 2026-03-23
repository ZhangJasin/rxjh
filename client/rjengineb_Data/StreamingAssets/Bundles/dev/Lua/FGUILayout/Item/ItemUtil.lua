local ItemUtil = {}

ItemUtil.SORTING_ORDER_BG          = 1 -- 背景
ItemUtil.SORTING_ORDER_ICON        = 2 -- 图标
ItemUtil.SORTING_ORDER_ARROW       = 3 -- 箭头
ItemUtil.SORTING_ORDER_BIND        = 4 -- 锁图标
ItemUtil.SORTING_ORDER_COUNT       = 5 -- 数量文本
ItemUtil.SORTING_ORDER_SUBSCRIPT   = 6 -- subScript文本
ItemUtil.SORTING_ORDER_STAR        = 7 -- 星级文本
ItemUtil.SORTING_ORDER_LIMIT_TIME  = 8 -- 限时标志

-- 服务器道具属性变更，在这里变更服务器属性为前端需要的属性
local cjson = require("cjson")
local itemconfig0 = {}
function ItemUtil:FixItemDataByServerRawData(item, onEquip)
    if not item or not next(item) then
        print("=======================================")
        print("item data error")
        print("=======================================")
    end

    local ItemConfigProxy = global.Facade:retrieveProxy(global.ProxyTable.ItemConfigProxy)
    itemconfig0 = ItemConfigProxy:GetItemConfigByIndex(item.Index)
    if not itemconfig0 or next(itemconfig0) == nil then
        print("=======================================")
        print("no this item: my index is " .. tostring(item.Index))
        print("=======================================")
    end

    local itemconfig = {}
    setmetatable(itemconfig, {
        __index = function(table, key)
            if not table.Index then
                return
            end

            local config = ItemConfigProxy:GetItemConfigByIndex(table.Index)
            if not config then  
                return 
            end 
            
            rawset(table, key, config[key])
            return config[key]
        end
    })

    itemconfig.Index = item.Index
    itemconfig.MakeIndex = item.makeindex
    itemconfig.Dura = item.dura
    itemconfig.DuraMax = item.duramax
    itemconfig.Values = item.values -- 0-49
    itemconfig.ValuesEx = item.valuesEX -- 0-29
    itemconfig.Where = item.where
    itemconfig.OverLap = item.overlap > 0 and item.overlap or 1

    -- 物品来源
    if item.ExtendInfo and string.len(item.ExtendInfo) > 0 then
        itemconfig.ExtendInfo = cjson.decode(item.ExtendInfo)
    end

    -- 查看别人玩家 物品来源
    if item.Src and type(item.Src)== "table" then 
        itemconfig.ExtendInfo = item.Src
    end 

    -- vtime + rtime = 截止时间
    itemconfig.startTime = item.vtime       -- 获取时的时间戳
    itemconfig.totalTime = item.rtime       -- 剩余时间
    itemconfig.Bind = item.bind             -- 绑定
    if item.color and item.color > 0 then   -- 颜色
        itemconfig.Color = item.color
    end
    itemconfig.Bontime = item.bontime       -- 交易行物品上架时间
    itemconfig.Star = item.star             -- 镶嵌宝石的叠加层数
    itemconfig.Inlays = item.Inlays         -- 宝石镶嵌 [{id = 宝石ID, c = 属性叠加层数, v = 附加属性值}, ...]

    if item.ExAbil then
        if type(item.ExAbil)== "string" and string.len(item.ExAbil) > 0 then
            local exAbilJsonData = cjson.decode(item.ExAbil)
            itemconfig.ExAbil = exAbilJsonData
            if exAbilJsonData.name and string.len(exAbilJsonData.name) > 0 then
                if not itemconfig.originName then
                    itemconfig.originName = itemconfig.Name
                end
                itemconfig.Name = exAbilJsonData.name
            end
        else
            if type(item.ExAbil)== "table" then
                itemconfig.ExAbil = item.ExAbil
            end
            if itemconfig.ExAbil and itemconfig.ExAbil.name and string.len(itemconfig.ExAbil.name) > 0 then
                if not itemconfig.originName then
                    itemconfig.originName = itemconfig.Name
                end
                itemconfig.Name = itemconfig.ExAbil.name
            end
        end
    end

    return itemconfig
end

function ItemUtil:RefreshItemUIByData(fgui_obj,itemData)
    if not fgui_obj or not itemData then
        SL:PrintError("itemData or fgui_obj is nil")
        return
    end

    -- 数量显示
    ItemUtil:SetItemCountByItemData(fgui_obj,itemData)
    -- 更新品级
    ItemUtil:UpdateItemGradeByItemID(fgui_obj,itemData.ID)
    -- 更新头像
    ItemUtil:SetItemIconByItemID(fgui_obj,itemData.ID)
    -- 更新镶嵌层数
    ItemUtil:SetItemStarByItemData(fgui_obj, itemData)
	-- 设置特效
    ItemUtil:SetEffectByItemID(fgui_obj,itemData.ID)
    -- PC模式下焦点进出tip显示
    ItemUtil:SetTipItemInAndOut(fgui_obj,itemData)
end

-- 通过ItemID设置头像ICON
function ItemUtil:GetIconResPathByItemID(itemID)
    if not itemID then
        SL:PrintError("GetIconResPath itemID is nil")
        return
    end

    local itemData = SL:GetValue("ITEM_DATA",itemID)
    if not itemData then
        SL:PrintError("GetIconResPath itemData is nil")
        return
    end

    if itemData.Looks and itemData.Looks > 0 then
        return itemData.Looks >= 100000 and string.format("ui://ItemIcon/%d", itemData.Looks) or string.format("ui://ItemIcon/%06d", itemData.Looks)
    end

    return ""
end

-- 道具品质框
function ItemUtil:UpdateItemGradeByItemID(component, itemID)
    if not component then
        SL:PrintError("UpdateItemGradeByItemID component is nil")
        return
    end

    -- 品级框是否存在
    if not itemID then
        SL:PrintError("UpdateItemGradeByItemID itemID is nil")
        return
    end

    local itemData = SL:GetValue("ITEM_DATA",itemID)
    if not itemData then
        SL:PrintError("UpdateItemGradeByItemID itemData is nil")
        return
    end

    local gloader_imgGrade = FGUI:GetChild(component,"Image_bg")
    if not gloader_imgGrade then
        SL:PrintError("UpdateItemGradeByItemID gloader_imgGrade is nil")
        return
    end
    
    if itemData.Grade then
        local ctrl_control = FGUI:getController(component,"grade")
        ctrl_control.selectedIndex = itemData.Grade
    end

    FGUI:setVisible(gloader_imgGrade, itemData.Grade)
end

-- pc模式下设置焦点进出tip
function ItemUtil:SetTipItemInAndOut(component,itemData)
    if not component then
        return
    end

    if not itemData or not next(itemData) then
        return
    end

    if SL:GetValue("IS_PC_OPER_MODE") then
        FGUI:setOnRollOverEvent(component,function()
            FGUIFunction:OpenItemTips({itemData = itemData,hideButtons = true})
        end)

        FGUI:setOnRollOutEvent(component,function()
            FGUIFunction:CloseItemTips()
        end)
    end
end


-- 添加点击事件
function ItemUtil:AddItemClick(component,itemData,clickCallBack)
    FGUI:setOnClickEvent(component,function()
        if clickCallBack then
            clickCallBack()
        else
            FGUIFunction:OpenItemTips({itemData = itemData,hideButtons = true})
        end
    end)
end

function ItemUtil:RemoveItemClick(component)
    FGUI:setOnClickEvent(component,nil)
end

-- 道具数量
function ItemUtil:UpdateItemCount(GTextField_count, count)
    if count < 0 then
        FGUI:GTextField_setText(GTextField_count, 0)
        return
    end
    
    FGUI:GTextField_setText(GTextField_count, SL:GetSimpleNumber(count))
end


-- 是否显示绑定图标
-- 如果显示货币图片是否是绑定货币显示
-- 4=> 绑定金币
-- 5=> 绑定元宝
-- 17=> 绑定热血币
function ItemUtil:UpdateIsShowLockByItemID(commonItem,itemData)
    if not commonItem then
        SL:PrintError("传参错误","commonItem is nil")
        return
    end

    if not itemData then
        SL:PrintError("传参错误","itemData is nil")
        return
    end

    local isShowBindMoneyImg = false
    if not itemData then
        isShowBindMoneyImg =  false
    else
        isShowBindMoneyImg = SL:GetMetaValue("ITEM_IS_BIND", itemData)
    end

    ItemUtil:SetLockedIsShow(commonItem,isShowBindMoneyImg)
end

-- 是否显示锁图标
function ItemUtil:SetLockedIsShow(commonItem,isShow)
    local image_bind = FGUI:GetChild(commonItem,"Image_bind")
    if image_bind then
        FGUI:setVisible(image_bind,isShow)
    else
        SL:PrintError("FGUI组件缺失错误","Image_bind is nil")
    end
end

--------------------------------------commonItem------------------------------------------------
-- 显示隐藏品质框
function ItemUtil:SetItemGradeVisible(commonItem,isShow)
    if not commonItem then
        SL:PrintError("传参错误","commonItem is nil")
        return
    end

    local image_bg = FGUI:GetChild(commonItem,"Image_bg")
    if not image_bg then
        SL:PrintError("FGUI组件缺失错误","image_bg is nil")
    end

    FGUI:setVisible(image_bg,isShow)
end

-- 显示隐藏数量
function ItemUtil:SetItemCountVisible(commonItem,isShow)
    if not commonItem then
        SL:PrintError("传参错误","commonItem is nil")
        return
    end

    local text_count = FGUI:GetChild(commonItem,"Text_count")
    if not text_count then
        SL:PrintError("FGUI组件缺失错误","SetItemCountVisible component is not exist")
        return
    end

    FGUI:setVisible(text_count,isShow)
end

-- 更新数量
function ItemUtil:SetItemCountByItemData(commonItem,itemData)
    local text_count = FGUI:GetChild(commonItem,"Text_count")
    if not text_count then
        SL:PrintError("FGUI组件缺失错误","SetItemCountByItemData component is not exist")
        return
    end

    if not itemData then
        SL:PrintError("传参错误","SetItemCountByItemData itemData is nil")
        return
    end

    --数量显示
    if itemData.isShowCount then
        if itemData.OverLap then         --用服务器字段名
            ItemUtil:UpdateItemCount(text_count,itemData.OverLap)
        end
    end
    FGUI:setVisible(text_count, itemData.isShowCount)
end

-- 更新镶嵌宝石层数
function ItemUtil:SetItemStarByItemData(commonItem, itemData)
    local starText = FGUI:GetChild(commonItem, "Text_star")
    if not starText then
        SL:PrintError("FGUI组件缺失错误","SetItemStarByItemData component is not exist")
        return
    end

    if not itemData then
        SL:PrintError("传参错误","SetItemStarByItemData itemData is nil")
        return
    end

    -- 层数
    if itemData.Star then
        FGUI:GTextField_setText(starText, string.format("+%s", itemData.Star))
    end
    FGUI:setVisible(starText, itemData.Star and itemData.Star > 0 and true or false)
end

-- 设置commonItem组件下的Icon
function ItemUtil:SetItemIconByItemID(commonItem,itemID)
    if not commonItem then
        SL:PrintError("传参错误","SetItemIconByItemID commonItem is nil")
        return
    end

    if not itemID then
        SL:PrintError("传参错误","SetItemIconByItemID itemID is nil")
        return
    end
    
    local itemData = SL:GetValue("ITEM_DATA",itemID)
    if not itemData then
        SL:PrintError("SetItemIconByItemID itemData is nil")
        return
    end
    
    local image_icon = FGUI:GetChild(commonItem,"Image_icon")
    if not image_icon then
        SL:PrintError("FGUI组件缺失错误","commponent Image_icon is not exist")
        return
    end
    
    local path = "ui://public/icon_item0"
    if itemData.Looks then
        if itemData.Looks and itemData.Looks >= 0 then
            path = ItemUtil:GetIconResPathByItemID(itemData.ID)
        end
    else
        SL:PrintError(" SetItemIconByItemID itemData.ID = [".. itemData.ID .."] Looks is nil")
    end
    
    FGUI:GLoader_setUrl(image_icon, path)
end

function ItemUtil:SetItemSubScriptByItemID(commonItem,itemID)
    if not commonItem then
        SL:PrintError("传参错误","SetItemSubScriptByItemID commonItem is nil")
        return
    end

    if not itemID then
        SL:PrintError("传参错误","SetItemSubScriptByItemID itemID is nil")
        return
    end

    local itemData = SL:GetValue("ITEM_DATA",itemID)
    if not itemData then
        SL:PrintError("SetItemSubScriptByItemID itemData is nil")
        return
    end

    local Text_Subscript = FGUI:GetChild(commonItem,"Text_Subscript")
    if not Text_Subscript then
        SL:PrintError("FGUI组件缺失错误","commponent Text_Subscript is not exist")
        return
    end

    if string.isNullOrEmpty(itemData.Subscript) then
        FGUI:setVisible(Text_Subscript,false)
        return
    end
    -- 对齐方式移动端颜色#字体大小#文字内容&
    local arr = string.split(itemData.Subscript,"&")
    if string.isNullOrEmpty(arr) then
        FGUI:setVisible(Text_Subscript,false)
        return
    end

    if type(arr) ~= "table"  then
        FGUI:setVisible(Text_Subscript,false)
        return
    end

    if not SL:GetValue("IS_PC_OPER_MODE") then
        if arr[1] then
            local arrContent = string.split(arr[1],"#")
            -- 0:Left 1:Center 2:Right
            FGUI:GTextField_setAlign(Text_Subscript,tonumber(arrContent[1]))
            FGUI:GTextField_setColor(Text_Subscript,"#"..arrContent[2])
            FGUI:GTextField_setFontSize(Text_Subscript,tonumber(arrContent[3]))
            FGUI:GTextField_setText(Text_Subscript,arrContent[4] or "")
            FGUI:setVisible(Text_Subscript,true)
        end
    else
        if arr[2] then
            local arrContent = string.split(arr[2],"#")
            -- 0:Left 1:Center 2:Right
            FGUI:GTextField_setAlign(Text_Subscript,tonumber(arrContent[1]))
            FGUI:GTextField_setColor(Text_Subscript,"#"..arrContent[2])
            FGUI:GTextField_setFontSize(Text_Subscript,tonumber(arrContent[3]))
            FGUI:GTextField_setText(Text_Subscript,arrContent[4] or "")
            FGUI:setVisible(Text_Subscript,true)
        end
    end
end


function ItemUtil:SetCountTextFontColor(commonItem,colorRGB)
    if not commonItem then
        SL:PrintError("传参错误","SetCountTextFontColor commonItem is nil")
        return
    end

    if not colorRGB then
        SL:PrintError("传参错误","SetCountTextFontColor colorRGB is nil")
        return
    end

    local Text_count = FGUI:GetChild(commonItem,"Text_count")
    if not Text_count then
        SL:PrintError("FGUI错误","找不到名为Text_count组件")
        return
    end

    FGUI:GTextField_setColor(Text_count,colorRGB)
end

function ItemUtil:SetCountTextOutLine(commonItem,outlineColor,outlinesize)
    if not commonItem then
        SL:PrintError("传参错误","SetCountTextOutLine commonItem is nil")
        return
    end

    if not outlinesize and type(outlinesize) ~= "number"then
        SL:PrintError("传参错误","SetCountTextOutLine outlinesize is nil or outlinesize is not number")
        return
    end

    if not outlineColor then
        SL:PrintError("传参错误","SetCountTextOutLine outlineColor is nil")
        return
    end

    local Text_count = FGUI:GetChild("Text_count")
    if not Text_count then
        SL:PrintError("FGUI错误","找不到名为Text_count组件")
        return
    end

    local textFormat = Text_count.textFormat
    textFormat.outline = outlinesize
    textFormat.outlineColor = SL:ConvertHexStrToColor(outlineColor)
end

-- 是否置灰头像
function ItemUtil:SetIconGray(commonItem,isGray)
    if not commonItem then
        SL:PrintError("传参错误","SetIconGray commonItem is nil")
        return
    end
    local image_icon = FGUI:GetChild(commonItem,"Image_icon")
    if not image_icon then
        SL:PrintError("FGUI组件缺失错误","SetIconGray Image_icon is not exist")
        return
    end
    
    FGUI:setGrey(image_icon,isGray)
end
--------------------------------------commonItem------------------------------------------------

--------------------------------------commonEquip------------------------------------------------
function ItemUtil:SetEquipArrowType(commonEquip, arrowType)
    if not commonEquip then
        SL:PrintError("传参错误", "SetEquipArrowType commonEquip is nil")
        return
    end

    if not arrowType then
        SL:PrintError("传参错误", "SetEquipArrowType arrowType is nil")
        return
    end

    local arrowImg = FGUI:GetChild(commonEquip, "Image_arrow")
    if not arrowImg then
        SL:PrintError("FGUI组件缺失错误", "SetEquipArrowType Image_arrow is not exist")
        return
    end

    local controller = FGUI:getController(commonEquip, "arrowType")
    if controller then
        controller.selectedIndex = arrowType
    end
end
--------------------------------------commonEquip------------------------------------------------

--[[
--extData参数
--extData.hideTip 是否隐藏默认的Tip
--extData.itemTipData table类型，对应ItemTips.ShowTip传入的参数
--extData.clickCallback 单击事件回调
--extData.doubleClickCallback 双击事件回调
--extData.countFontColor 数量字体颜色
--extData.CountOutlineColor 数量字体描边
--extData.bgVisible 背景隐藏
--extData.OverLap 道具数量
--]]
function ItemUtil:ItemShow_Create(itemData,parent,extData)
    local isEquip = SL:GetValue("BAG_ITEM_IS_EQUIP",itemData)
    local comName = isEquip and "CommonEquip" or "CommonItem"
    local packageName = SL:GetValue("IS_PC_OPER_MODE") and "public_pc" or "public"
    local item = Pool.Get(packageName, comName, parent)
    item.comName = comName
    item:Init(item.component)
    if parent then
        local targetObj = item._component
        local w,h = FGUI:getSize(parent)
        FGUI:setSize(targetObj, w, h)
    end

    item:UpdateUIByData(itemData,extData)
    return item
end

-- 通过itemID创建itemShow
--[[
--extData.hideTip 是否隐藏默认的Tip
--extData.itemTipData table类型，对应ItemTips.ShowTip传入的参数
--extData.clickCallback 单击事件回调
--extData.doubleClickCallback 双击事件回调
--extData.countFontColor 数量字体颜色
--extData.CountOutlineColor 数量字体描边
--extData.bgVisible 背景隐藏
--extData.OverLap 道具数量
--]]
function ItemUtil:ItemShow_CreateEX(extData,parent)
    local itemData = SL:GetValue("ITEM_DATA",extData.ID)
    local isEquip = SL:GetValue("BAG_ITEM_IS_EQUIP",itemData)
    local comName = isEquip and "CommonEquip" or "CommonItem"
    local packageName = SL:GetValue("IS_PC_OPER_MODE") and "public_pc" or "public"
    local item = Pool.Get(packageName, comName, parent)
    item.comName = comName
    item:Init(item.component)
    if parent then
        local targetObj = item._component
        local  w,h = FGUI:getSize(parent)
        FGUI:setSize(targetObj, w, h)
    end
    item:UpdateUIByData(itemData,extData)
    return item
end


function ItemUtil:ItemShow_Release(item)
    if not item then
        return
    end
    item:Clean()
    local packageName = SL:GetValue("IS_PC_OPER_MODE") and "public_pc" or "public"
    Pool.Release(packageName, item.comName, item)
end

---------------------------------------Equip---------------------------------------------
---
function ItemUtil:CheckNeed(itemData)
    local needStr = itemData.Need
    local needStrList = SL:Split(needStr or "", "&")
    local needLevel = 0
    for i = 1, #needStrList do
        local param = needStrList[i]
        if param and string.len(param) > 0 then
            local paramList = SL:Split(param, "#")
            local tag = tonumber(paramList[1])
            if tag == 1 then        -- 属性
                local attId = tonumber(paramList[2]) or 0
                local needValue = tonumber(paramList[3]) or 0
                if SL:GetValue("CUR_ATTR_BY_ID", attId) < needValue then
                    local attName = SL:GetValue("ATTR_CONFIG_NAME_BY_ID", attId)
                    return false, string.format("%s不足", attName)
                end
            elseif tag == 2 then    -- 货币
                local coinId = tonumber(paramList[2]) or 0
                local needValue = tonumber(paramList[3]) or 0
                if SL:GetValue("ITEM_COUNT", coinId) < needValue then
                    local coinName = SL:GetValue("ITEM_NAME", coinId)
                    return false, string.format("%s不足", coinName or "货币")
                end
            end
        end
    end
    return true
end

function ItemUtil:CheckNeedLevel(itemData)
    return SL:GetValue("LEVEL") >= (itemData.NeedLevel or 0)
end

function ItemUtil:CheckEquipNeedSex(itemData)
    local sexOk = true
    -- 0男 1女 2通用
    local equipSex = itemData.Gender
    if equipSex == 2 then
        return sexOk
    end

    if equipSex ~= SL:GetValue("SEX") then
        return false
    end
    return sexOk
end

function ItemUtil:CheckJob(itemData)
    local itemConfigData = itemData
    if not itemData.ID then
        itemConfigData = SL:GetValue("ITEM_DATA", itemData.Index)
    end
    if itemConfigData then
        local config = SL:GetMetaValue("TRANSFER_CONFIG_BY_ID", itemConfigData.TransferID)
        if config then
            if config.ClassID == 0 then     -- 0: 通用职业
                return true
            end
            return SL:GetValue("JOB") == config.ClassID
        end
    end
    return false
end

function ItemUtil:CheckTransferLV(itemData)
    local itemConfigData = itemData
    if not itemData.ID then
        itemConfigData = SL:GetValue("ITEM_DATA", itemData.Index)
    end
    if itemConfigData then
        local config = SL:GetMetaValue("TRANSFER_CONFIG_BY_ID", itemData.TransferID)
        if config then
            return SL:GetValue("RELEVEL") >= config.TransferLV
        end
    end
    return false
end

function ItemUtil:CheckTransferCamp(itemData)
    local itemConfigData = itemData
    if not itemData.ID then
        itemConfigData = SL:GetValue("ITEM_DATA", itemData.Index)
    end
    if itemConfigData then
        local config = SL:GetMetaValue("TRANSFER_CONFIG_BY_ID", itemData.TransferID)
        if config then
            if config.Type == 0 then    -- 0: 通用阵营
                return true
            end
            return SL:GetValue("GOODEVILID") == config.Type
        end
    end
    return false
end

function ItemUtil:CheckCanEquip(itemData)
    if not self:CheckEquipNeedSex(itemData) then
        return false, "性别不符"
    end
    local canUse, conditionStr = self:CheckNeed(itemData)
    if not canUse then
        return false, conditionStr
    end
    if not self:CheckJob(itemData) then
        return false, "职业不满足"
    end
    if not self:CheckTransferCamp(itemData) then
        return false, "派系不符"
    end
    if not self:CheckTransferLV(itemData) then
        return false, "转职等级不满足"
    end
    return true
end

-- 满足基础部分穿戴条件
function ItemUtil:CheckBaseCanEquip(itemData)
    if not self:CheckEquipNeedSex(itemData) then
        return false
    end
    if not self:CheckJob(itemData) then
        return false
    end
    if not self:CheckTransferCamp(itemData) then
        return false
    end

    return true
end

function ItemUtil:CheckItemUseType(itemData)
    local itemConfigData = itemData
    if not itemData.ID then
        itemConfigData = SL:GetValue("ITEM_DATA", itemData.Index)
    end
    return SL:GetValue("ITEMTYPE", itemConfigData) == SL:GetValue("ITEMTYPE_ENUM").CanUseItem
end

function ItemUtil:CheckItemCanUse(itemData)
    if not self:CheckNeedLevel(itemData) then
        return false
    end
    if not self:CheckItemUseType(itemData) then
        return false
    end
    return true
end

function ItemUtil:IsEquip(itemData)
    local itemConfigData = itemData
    if not itemData.ID then
        itemConfigData = SL:GetValue("ITEM_DATA", itemData.Index)
    end
    return SL:GetValue("ITEMTYPE", itemConfigData) == SL:GetValue("ITEMTYPE_ENUM").Equip
end

--背包类定义的筛选type和item表里的转换规则,默认1全部，2装备
function ItemUtil:GetItemFilterType(itemData)

    local isEquip = self:IsEquip(itemData)
    local realType = -1
    if isEquip then
        realType = 2
    else
        if itemData.ItemType then -- 配置数据
            local itemType = itemData.ItemType
            realType = itemType + 2
        else
            if itemData.Index then -- 服务器数据
                local config = SL:GetValue("ITEM_DATA", itemData.Index)
                if config then
                    local itemType = config.ItemType or 1
                    realType = itemType + 2
                else
                    SL:PrintError("item表可能不存在id["..itemData.Index.."]或者是非法ID")
                end
            end
        end
    end
    return realType
end

function ItemUtil:CheckShowPreviewModel(itemData)
	local isShow = false
	if not itemData then
		return isShow
	end
	local groupId = itemData.TipsGroupId or 7
    local groupCfg = SL:GetValue("ITEMTIPS_GROUP_CONFIG", groupId)
    if groupCfg.Preview and groupCfg.Preview == 1 then
		local featureData = SL:GetValue("FEATURE")
		local modelID = itemData.Model
		if not featureData or not modelID then
			return isShow
		end

		local pos = SL:GetValue("EQUIP_POS_BY_STDMODE", itemData.StdMode)
		if not pos then
			return isShow
		end

		local appearPos = SL:GetValue("APPEAR_POS_BY_EQUIP_POS", pos)
		if not appearPos or appearPos == -1 then
			return isShow
		end
		
		local sex = SL:GetValue("SEX")
		local job = SL:GetValue("JOB")

		local cSex = itemData.Gender or 0
		-- 性别不同不显示预览
		if sex ~= cSex then
			return isShow
		end

		isShow = true
	end

	return isShow
end

local TIME_INTERVAL = 1.5
function ItemUtil:SetLongPressOrClick(component,pressCall,longPressCall,TimeInterval)
    local touchBeginTime = 0
    if not component then
        return
    end

    if not TimeInterval then
        TimeInterval = TIME_INTERVAL
    end

    local scheduleId = nil

    local function beginFunc(eventData)
        touchBeginTime = SL:GetValue("TIME")
        scheduleId = SL:ScheduleOnce(function()
            if longPressCall then
                longPressCall(eventData)
            end
        scheduleId = nil
        end,TimeInterval)
        FGUI:EventContext_CaptureTouch(eventData)
    end
    local function moveFunc(eventData)
        if scheduleId then
            SL:UnSchedule(scheduleId)
            scheduleId = nil 
        end
    end
    local function endFunc(eventData)
        if SL:GetValue("TIME") - touchBeginTime < TimeInterval then
            if scheduleId then
                SL:UnSchedule(scheduleId)
                scheduleId = nil 
            end
            if pressCall then
                pressCall(eventData)
            end
        end
    end
    FGUI:setOnTouchEvent(component, beginFunc, moveFunc, endFunc)
end

-- 初始化component的sortingOrder，可以通过改变SortingOrder改变组件层级
function ItemUtil:InitSortingOrder(component)
    if not component then
        return
    end

    local Image_bg = FGUI:GetChild(component,"Image_bg")
    if Image_bg then
        FGUI:setSortingOrder(Image_bg,ItemUtil.SORTING_ORDER_BG)
    end

    local Image_icon = FGUI:GetChild(component,"Image_icon")
    if Image_icon then
        FGUI:setSortingOrder(Image_icon,ItemUtil.SORTING_ORDER_ICON)
    end

    local Image_arrow = FGUI:GetChild(component,"Image_arrow")
    if Image_arrow then
        FGUI:setSortingOrder(Image_arrow,ItemUtil.SORTING_ORDER_ARROW)
    end

    local Image_bind = FGUI:GetChild(component,"Image_bind")
    if Image_bind then
        FGUI:setSortingOrder(Image_bind,ItemUtil.SORTING_ORDER_BIND)
    end

    local Text_count = FGUI:GetChild(component,"Text_count")
    if Text_count then
        FGUI:setSortingOrder(Text_count,ItemUtil.SORTING_ORDER_COUNT)
    end
    
    local Text_Subscript = FGUI:GetChild(component,"Text_Subscript")
    if Text_Subscript then
        FGUI:setSortingOrder(Text_Subscript,ItemUtil.SORTING_ORDER_SUBSCRIPT)
    end

    local Text_star = FGUI:GetChild(component,"Text_star")
    if Text_star then
        FGUI:setSortingOrder(Text_star,ItemUtil.SORTING_ORDER_STAR)
    end

	SL:Print("设置层级")
end


ItemUtil.effectDictCache = {}                 
function ItemUtil:SetEffectByItemID(component,itemID)
    if ENABLE_PROFILER then
        Profiler.BeginSample("SetEffectByItemID start")
    end
    local obj = nil 
    if not component then
        return obj
    end
	
	local parentGuid = FGUI:GetID(component)
	-- 先清理特效
	ItemUtil:ClearDictEffectByItemComponent(parentGuid)
    if not itemID then
        return obj
    end

    if type(itemID) == "string" then
        itemID = tonumber(itemID)
    end
	
    local itemData = SL:GetValue("ITEM_DATA",itemID)
    if string.isNullOrEmpty(itemData.bEffect) then
        return obj
    end

    ItemUtil:InitSortingOrder(component)
    
	if ENABLE_PROFILER then
        Profiler.EndSample()
    end

    if not component.onDispose then
        FGUI:addOnDispose(component,function()
            ItemUtil:ClearDictEffectByItemComponent(parentGuid)
        end)
    end

    SL:Print("特效字段",itemData.bEffect)
    if ENABLE_PROFILER then
        Profiler.BeginSample("SetEffectByItemID 1")
    end
    local part = string.split(itemData.bEffect,"&")
    --特效ID#模式#播放速度&X坐标#Y坐标#缩放比例&PC端X坐标#PC端Y坐标#PC端缩放比例
    local paramPart1 = string.split(part[1],"#")
    -- 特效ID#模式#播放速度
    local sfxID = paramPart1[1]
    local mode = tonumber(paramPart1[2])
    local speed = paramPart1[3]
    if ENABLE_PROFILER then
        Profiler.EndSample()
    end
    if ENABLE_PROFILER then
        Profiler.BeginSample("SetEffectByItemID GMovieClip_create")
    end
    
    obj = FGUI:GMovieClip_create(component,sfxID)
    if ENABLE_PROFILER then
        Profiler.EndSample()
    end
    if ENABLE_PROFILER then
        Profiler.BeginSample("SetEffectByItemID logic")
    end
    -- 设置特效组件锚点为正中心(0.5,0.5)
    FGUI:setAnchorPoint(obj,0.5,0.5,true)
    local paramPart2 = string.split(part[2],"#")
    -- X坐标#Y坐标#缩放比例 移动端参数
    local mobileOffsetX = tonumber(paramPart2[1])
    local mobileOffsetY = tonumber(paramPart2[2])
    local mobileScale = tonumber(paramPart2[3])

    local paramPart3 = string.split(part[3],"#")
    -- PC端X坐标#PC端Y坐标#PC端缩放比例
    local pcOffsetX = tonumber(paramPart3[1])
    local pcOffsetY = tonumber(paramPart3[2])
    local pcScale = tonumber(paramPart3[3])
    local width,height = FGUI:getSize(component)
    -- 设置特效大小与父组件大小一样，可通过比例调整适配
    -- FGUI:setSize(obj, width, height)
    if SL:GetValue("IS_PC_OPER_MODE") then
        local baseWidth = 44
        local scale = width / baseWidth

        FGUI:setScale(obj,pcScale * scale,pcScale * scale)
        FGUI:setPosition(obj,width/2 + pcOffsetX,height/2 + pcOffsetY)
    else
        local baseWidth = 64
        local scale = width / baseWidth
        FGUI:setScale(obj,mobileScale * scale,mobileScale * scale)
        FGUI:setPosition(obj,width/2 + mobileOffsetX,height/2 + mobileOffsetY)
    end

    -- 设置播放速度
    FGUI:GMovieClip_setTimeScale(obj, speed)
    -- 设置显示层级
    local Image_icon = FGUI:GetChild(component,"Image_icon")
    if Image_icon and obj then
        local sortingOrder =  FGUI:getSortingOrder(Image_icon)
		-- 设置层级
        -- 修改显示层级
		SL:Print("设置层级",sortingOrder)    
        FGUI:setSortingOrder(obj,(mode == 1) and sortingOrder + 1 or sortingOrder - 1)
    end

    local data = {}
    data.obj = obj
    data.sfxID = sfxID
    data.itemID = itemID
    ItemUtil:SaveEffectDataToDict(parentGuid,data)
    if ENABLE_PROFILER then
        Profiler.EndSample()
    end
end


-- 移除通过配置表bEffect字段添加的特效
function ItemUtil:RemoveAllEffectOnItem(component)
	if not component then
		return
	end 
	
	local parentGuid = FGUI:GetID(component)
	if parentGuid then
		ItemUtil:ClearDictEffectByItemComponent(parentGuid)
	end
end


-- 存储特效
function ItemUtil:SaveEffectDataToDict(parentGuid,data)
    if not ItemUtil.effectDictCache then
        return
    end

    if not ItemUtil.effectDictCache[parentGuid] then
        ItemUtil.effectDictCache[parentGuid] = {}
    end

    table.insert(ItemUtil.effectDictCache[parentGuid],data)
end


-- parentGuid可以通过FGUI:GetID(component)获取
function ItemUtil:ClearDictEffectByItemComponent(parentGuid)
    if not parentGuid then
        return
    end

    if not ItemUtil.effectDictCache or not next(ItemUtil.effectDictCache) then
        return
    end

    if not ItemUtil.effectDictCache[parentGuid] then
        return
    end

    for k,v in pairs(ItemUtil.effectDictCache[parentGuid]) do
        FGUI:RemoveFromParent(v.obj, true)
        SL:Print("清理物品["..v.itemID.."]特效"..v.sfxID)
        v = nil
    end

    ItemUtil.effectDictCache[parentGuid] = {}
end


function ItemUtil:ClearCache()
    -- 清理item特效记录容器
    for k,v in pairs(ItemUtil.effectDictCache) do
        ItemUtil:ClearDictEffectByItemComponent(k)
    end
end

return ItemUtil