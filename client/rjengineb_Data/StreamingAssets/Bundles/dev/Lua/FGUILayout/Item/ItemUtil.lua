local ItemUtil = {}
local BaseFGUILayout = requireFGUI("BaseFGUILayout")
local enterbag_cfg   =  require("game_config/cfgcsv/enterbag")
local AttScore_cfg   =  require("game_config/AttScore")
local _PetEquipPos = {           -- 宠物装备位置
    ["灵兽利爪"]  = 0,    
    ["灵兽护具"]  = 1,    
    ["灵兽系带"]  = 2,    
    ["灵兽兽环"]  = 3,    
}
-- 服务器道具属性变更，在这里变更服务器属性为前端需要的属性
local cjson = require("cjson")
local itemconfig0 = {}
local WuXunPanlData = SL:RequireFile("FGUILayout/A_WuXun/WuXunPanlData")

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
        print("no this item: my index is " .. item.Index)
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
    attrConfigs = SL:GetValue("ATTR_CONFIGS")
    -- 数量显示
    ItemUtil:SetItemCountByItemData(fgui_obj,itemData)
    -- 更新品级
    ItemUtil:UpdateItemGradeByItemID(fgui_obj,itemData.ID)
    -- 更新头像
    ItemUtil:SetItemIconByItemID(fgui_obj,itemData.ID)
    -- 更新镶嵌层数
    ItemUtil:SetItemStarByItemData(fgui_obj, itemData)
    --自定义属性
    local isequip = SL:GetValue("BAG_ITEM_IS_EQUIP", itemData, itemData.ID)
    --print("isequip="..tostring(isequip))
    -- dump(itemDate,"itemDate")
    if isequip or _PetEquipPos[itemDate and itemDate.StdName or ""] then
        ItemUtil:SetEquipQHByItemData(fgui_obj,itemData)  --装备强化
    else
        ItemUtil:ClearHCDShow(fgui_obj)
    end
end
-- 清理合成点显示
function ItemUtil:ClearHCDShow(commonItem)
    -- 合成点显示配置
    if HCDObj_cfd[commonItem] and #HCDObj_cfd[commonItem] > 0 then
        for i=1,#HCDObj_cfd[commonItem] do
            FGUI:RemoveFromParent(HCDObj_cfd[commonItem][i], true)
        end
        HCDObj_cfd[commonItem] = nil
    end
end
-- 通过道具强化等级
function ItemUtil:SetEquipQHByItemData(commonItem,itemData)
    -- dump(commonItem)
    local ItemFrom = SL:GetValue("ITEMFROMUI_ENUM")
    local str = ""
    local stoneNum = itemData.SyntheticStone or 0
    local extraParam = {}
    -- 清理合成点显示
    ItemUtil:ClearHCDShow(commonItem)
    if stoneNum and stoneNum > 0 then    -- 未配置仅显示镶嵌属性
        local yhcnum = 0
        if itemData.Values then
            for j = 1, #itemData.Values do
                if itemData.Values[j]['Id'] == 2 then
                    yhcnum = itemData.Values[j]['Value']
                    break
                end
            end
        end
        -- print("yhcnum="..yhcnum.."  stoneNum="..stoneNum,"  name="..itemData.Name)
        if yhcnum > 0 then
            HCDObj_cfd[commonItem] = {}
            for i = 1, stoneNum do
                local itemChannel
                if i <= yhcnum then
                    itemChannel = FGUI:CreateObject(commonItem, "A_Right", "dian_liang",false)
                else
                    itemChannel = FGUI:CreateObject(commonItem, "A_Right", "dian_hui",false)
                end
                local x,y = 3+(i-1)%4*13,3+math.floor((i-1)/4)*13
                FGUI:setPositionX(itemChannel, x)
                FGUI:setPositionY(itemChannel, y) 
                --local sy = FGUI:GetChildIndex(commonItem, itemChannel)
                table.insert(HCDObj_cfd[commonItem],itemChannel)
                --FGUI:RemoveFromParent(itemChannel, true)
            end
            
        end
    end
    -- 武勋装备鉴定蒙版配置  WuXunJianDing_cfd
    if WuXunJianDing_cfd[commonItem] then
        FGUI:RemoveFromParent(WuXunJianDing_cfd[commonItem], true)
        WuXunJianDing_cfd[commonItem] = nil
    end
    -- 获取武勋装备锤炼等级 是否为武勋装备
    local wxcllv,iswxequip = 0,false
    -- dump(itemData)
    -- 判断是否为武勋装备
    if itemData.StdMode and itemData.StdMode >= 71 and itemData.StdMode <= 74 then
        local WuXun_ChuiLianList = WuXunPanlData.Get()._state.WuXun_ChuiLianList or {}
        local itemConfig = itemData.ExAbil
        local isJianDIng = false
        if itemConfig and itemConfig.abil[1] then
            isJianDIng = true
        end
        --  print("isJianDIng="..tostring(isJianDIng))
        -- 未鉴定 显示鉴定蒙版
        if not isJianDIng then
            -- 创建鉴定蒙版
            local itemChannel = FGUI:CreateObject(commonItem, "A_Right", "wuxun_jian_ding",false)
            WuXunJianDing_cfd[commonItem] = itemChannel
            local w,h = FGUI:getSize(commonItem)
            FGUI:setScale(itemChannel, w/72, h/72)
        end
        -- 是否穿戴中 武勋锤炼等级只有穿戴中的装备有
        if itemData.Where and itemData.Where > -1 then  
             
            wxcllv = WuXun_ChuiLianList[""..itemData.Where] or 0
        end
        iswxequip = true
    end

    --print("通过道具强化等级=")
    if not commonItem then
        SL:PrintError("传参错误","SetItemIconByItemID commonItem is nil")
        return
    end
    local Text_star = FGUI:GetChild(commonItem,"Text_star")
    if not Text_star then
        SL:PrintError("FGUI组件缺失错误","SetItemCountByItemData Text_star is not exist")
        return
    end
    local text_count = FGUI:GetChild(commonItem,"Text_count")
    if not text_count then
        SL:PrintError("FGUI组件缺失错误","SetItemCountByItemData Text_count is not exist")
        return
    end
    local Text_Subscript = FGUI:GetChild(commonItem,"Text_Subscript")
    if not Text_Subscript then
        SL:PrintError("FGUI组件缺失错误","SetItemCountByItemData Text_Subscript is not exist")
        return
    end

    if not itemData.Values then
        --SL:PrintError("FGUI组件缺失错误","SetItemCountByItemData itemData.Values is not exist")
        return
    end

    
    -- 装备强化等级  武勋铸阶等级
    local qhlv,wxzjLv = 0,0
    -- dump(itemData.Values)
    for i=1,#itemData.Values do
        if itemData.Values[i]['Id'] == 0 then
            qhlv = itemData.Values[i]['Value']
        elseif itemData.Values[i]['Id'] == 2 then
            wxzjLv = itemData.Values[i]['Value']
        end
    end
    -- 是武勋装备时
    FGUI:GTextField_setText(Text_star,"")
    if wxcllv > 0 then
        FGUI:setVisible(Text_star,true)
        FGUI:GTextField_setAlign(Text_star,0)
        FGUI:GTextField_setColor(Text_star,"#00ff00")
        FGUI:GTextField_setFontSize(Text_star,20)
        FGUI:GTextField_setText(Text_star,"+"..wxcllv) 
    end
    if qhlv > 0 then
        FGUI:setVisible(text_count,true)
        FGUI:GTextField_setAlign(text_count,0)
        FGUI:GTextField_setColor(text_count,"#00ff00")
        FGUI:GTextField_setFontSize(text_count,20)
        FGUI:GTextField_setText(text_count,"+"..qhlv)  
    elseif wxzjLv > 0 and iswxequip then 
        FGUI:setVisible(text_count,true)
        FGUI:GTextField_setAlign(text_count,0)
        FGUI:GTextField_setColor(text_count,"#00ff00")
        FGUI:GTextField_setFontSize(text_count,20)
        FGUI:GTextField_setText(text_count,wxzjLv.."阶")  
    end
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
        -- FGUI:GLoader_setUrl(gloader_imgGrade, string.format("ui://public/icon_item%s", itemData.Grade))
    end

    FGUI:setVisible(gloader_imgGrade, itemData.Grade)
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

    FGUI:GTextField_setText(GTextField_count, SL:GetSimpleNumber(count,0))
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
    --dump(itemData.ExAbil.abil)
    local isPercent = false  -- 是否是百分比
    if enterbag_cfg[itemData.ID] and enterbag_cfg[itemData.ID]['RightSubscript'] == 1 and itemData.ExAbil and itemData.ExAbil.abil and string.find(itemData.ExAbil.abil[1]['t'],"鉴定属性") then
        local attId     = itemData.ExAbil.abil[1]['v'][1][2] or 0     -- 属性ID 绑定表
		local percent   = AttScore_cfg[attId]['Type'] or 0   -- 是否是百分比
		local value     = itemData.ExAbil.abil[1]['v'][1][3]
		if percent == 1 then
			value = tonumber(string.format("%.0f", value / 100))
            isPercent = true
		end
        itemData.Star = value
    end
    -- 层数
    if itemData.Star then
        if isPercent then
            FGUI:GTextField_setText(starText, string.format("+%s%%", itemData.Star))
        else
            FGUI:GTextField_setText(starText, string.format("+%s", itemData.Star))
        end
        FGUI:GTextField_setColor(starText, "#00ff00")
        FGUI:GTextField_setFontSize(starText,13)
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
    -- 对齐方式#颜色#字体大小#文字内容
    local arr = string.split(itemData.Subscript,"#")
    if string.isNullOrEmpty(arr) then
        FGUI:setVisible(Text_Subscript,false)
        return
    end

    if type(arr) ~= "table"  then
        FGUI:setVisible(Text_Subscript,false)
        return
    end

    if #arr ~= 4 then
        FGUI:setVisible(Text_Subscript,false)
        return
    end

    -- 0:Left 1:Center 2:Right
    FGUI:GTextField_setAlign(Text_Subscript,tonumber(arr[1]))
    FGUI:GTextField_setColor(Text_Subscript,"#"..arr[2])
    FGUI:GTextField_setFontSize(Text_Subscript,tonumber(arr[3]))
    FGUI:GTextField_setText(Text_Subscript,arr[4] or "")
    FGUI:setVisible(Text_Subscript,true)
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

--extData参数
--extData.hideTip 是否隐藏默认的Tip
--extData.itemTipData table类型，对应ItemTips.ShowTip传入的参数
--extData.clickCallback 单击事件回调
--extData.doubleClickCallback 双击事件回调
--extData.countFontColor 数量字体颜色
--extData.CountOutlineColor 数量字体描边
--extData.bgVisible 背景隐藏
--extData.OverLap 道具数量
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
--extData.hideTip 是否隐藏默认的Tip
--extData.itemTipData table类型，对应ItemTips.ShowTip传入的参数
--extData.clickCallback 单击事件回调
--extData.doubleClickCallback 双击事件回调
--extData.countFontColor 数量字体颜色
--extData.CountOutlineColor 数量字体描边
--extData.bgVisible 背景隐藏
--extData.OverLap 道具数量
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


return ItemUtil