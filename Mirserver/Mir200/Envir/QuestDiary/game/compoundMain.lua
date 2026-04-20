-- 合成系统主逻辑
compoundMain = {}
local filname = "compoundMain"
local Compound = require("Envir/QuestDiary/game_config/cfgcsv/Compound")
-- 使用系统自带Item配置表
local Item = Item_cfg or {}

-- 注册网络消息处理（参考武勋系统）
Message.RegisterNetMsg(ssrNetMsgCfg.compound, compoundMain)

-- 打开合成界面
function compoundMain.OpenCompoundUI(actor)
    print("打开合成界面:", getname(actor))
    
    -- 获取分组数据
    local group1List = compoundMain.GetGroup1List()
    local group2Map = {}
    
    for _, g1 in ipairs(group1List) do
        group2Map[g1] = compoundMain.GetGroup2List(g1)
    end
    
    -- 推送数据到客户端
    Message.sendmsgEx(actor, "compoundMain", "initCompoundData", {
        group1List = group1List,
        group2Map = group2Map,
    })
    
    -- 打开UI
    local isPc = clientflag(actor) == 1
    if isPc then
        -- PC端
        sendmymsg(actor, ssrNetMsgCfg.OpenUI, 0, 0, 0, tbl2json({
            uiName = "A_Compound_PC",
            viewName = "compoundMain_PC"
        }))
    else
        -- 移动端
        sendmymsg(actor, ssrNetMsgCfg.OpenUI, 0, 0, 0, tbl2json({
            uiName = "A_Compound",
            viewName = "compoundMain"
        }))
    end
end

-- 合成请求处理（客户端调用 ssrMessage:sendmsgEx("compound", "CompoundRequest", {...})）
function compoundMain.CompoundRequest(actor, data)
    print("=== 收到合成请求 ===")
    print("玩家:", getname(actor))
    
    if not data or not data.compoundID then
        sendmsg(actor, 9, "请求数据错误")
        return
    end
    
    local compoundID = tonumber(data.compoundID)
    compoundMain.StartCompound(actor, compoundID)
end

-- 检查材料是否足够
function compoundMain.CheckCostItems(actor, config)
    print("检查材料...")
    
    local items = {
        {itemID = config.CostItem1, count = config.CostItemCount1},
        {itemID = config.CostItem2, count = config.CostItemCount2},
        {itemID = config.CostItem3, count = config.CostItemCount3},
    }
    
    for _, itemData in ipairs(items) do
        if itemData.itemID and itemData.itemID > 0 and itemData.count and itemData.count > 0 then
            local haveCount = bagitemcount(actor, itemData.itemID)
            print(string.format("  道具ID:%d 需要:%d 拥有:%d", 
                itemData.itemID, itemData.count, haveCount))
            
            if haveCount < itemData.count then
                print("  材料不足!")
                return false
            end
        end
    end
    
    print("材料检查通过")
    return true
end

-- 扣除材料
function compoundMain.DeductCostItems(actor, config)
    print("扣除材料...")
    
    local items = {
        {itemID = config.CostItem1, count = config.CostItemCount1},
        {itemID = config.CostItem2, count = config.CostItemCount2},
        {itemID = config.CostItem3, count = config.CostItemCount3},
    }
    
    for _, itemData in ipairs(items) do
        if itemData.itemID and itemData.itemID > 0 and itemData.count and itemData.count > 0 then
            delItemNum(actor, itemData.itemID, itemData.count)
            print(string.format("  扣除道具ID:%d 数量:%d", itemData.itemID, itemData.count))
        end
    end
    
    print("材料扣除完成")
end

-- 检查货币是否足够
function compoundMain.CheckCurrency(actor, config)
    if not config.CostCurrencyType or config.CostCurrencyType == 0 then
        return true  -- 不需要货币
    end
    
    if not config.CostCurrencyCount or config.CostCurrencyCount == 0 then
        return true
    end
    
    local playerCurrency = compoundMain.GetPlayerCurrency(actor, config.CostCurrencyType)
    print(string.format("检查货币: 类型=%d 需要=%d 拥有=%d", 
        config.CostCurrencyType, config.CostCurrencyCount, playerCurrency))
    
    return playerCurrency >= config.CostCurrencyCount
end

-- 扣除货币
function compoundMain.DeductCurrency(actor, config)
    if not config.CostCurrencyType or config.CostCurrencyType == 0 then
        return
    end
    
    if not config.CostCurrencyCount or config.CostCurrencyCount == 0 then
        return
    end
    
    compoundMain.DeductPlayerCurrency(actor, config.CostCurrencyType, config.CostCurrencyCount)
    print(string.format("扣除货币: 类型=%d 数量=%d", 
        config.CostCurrencyType, config.CostCurrencyCount))
end

-- 获取玩家货币数量
function compoundMain.GetPlayerCurrency(actor, currencyType)
    -- 货币类型: 1=金币, 2=银币, 3=钻石
    if currencyType == 1 then
        return getgold(actor) or 0
    elseif currencyType == 2 then
        return getsilver(actor) or 0
    elseif currencyType == 3 then
        return getdiamond(actor) or 0
    end
    return 0
end

-- 扣除玩家货币
function compoundMain.DeductPlayerCurrency(actor, currencyType, amount)
    if currencyType == 1 then
        takegold(actor, amount)
    elseif currencyType == 2 then
        takesilver(actor, amount)
    elseif currencyType == 3 then
        takediamond(actor, amount)
    end
end

-- 执行合成(考虑成功率)
function compoundMain.ExecuteCompound(actor, config)
    local successRate = config.SuccessRate or 100
    local randomValue = math.random(1, 100)
    
    print(string.format("合成成功率:%d%% 随机值:%d", successRate, randomValue))
    
    return randomValue <= successRate
end

-- 发放目标道具
function compoundMain.GiveTargetItem(actor, config)
    local targetItemID = config.TargetItemID
    local targetCount = config.TargetItemCount
    
    if not targetItemID or targetItemID == 0 then
        print("错误: 目标道具ID无效")
        return
    end
    
    if not targetCount or targetCount == 0 then
        targetCount = 1
    end
    
    -- 发放道具到背包
    giveitem(actor, targetItemID, targetCount)
    
    print(string.format("发放道具: ID=%d 数量=%d", targetItemID, targetCount))
    
    -- 通知客户端合成成功，刷新背包
    Message.sendmsgEx(actor, "compoundMain", "CompoundSuccess", {
        targetItemID = targetItemID,
        targetCount = targetCount,
        success = true
    })
end

-- 获取合成配置列表(按分组)
function compoundMain.GetCompoundList(actor, group1)
    local result = {}
    
    for id, config in pairs(Compound) do
        if not group1 or config.Group1 == group1 then
            table.insert(result, {
                ID = config.ID,
                Group1 = config.Group1,
                Group2 = config.Group2,
                TargetItemID = config.TargetItemID,
                TargetItemCount = config.TargetItemCount,
                SuccessRate = config.SuccessRate,
                Desc = config.Desc,
            })
        end
    end
    
    return result
end

-- 获取所有一级分组
function compoundMain.GetGroup1List()
    local group1Set = {}
    local result = {}
    
    for _, config in pairs(Compound) do
        if not group1Set[config.Group1] then
            group1Set[config.Group1] = true
            table.insert(result, config.Group1)
        end
    end
    
    table.sort(result)
    return result
end

-- 获取指定一级分组下的二级分组
function compoundMain.GetGroup2List(group1)
    local group2Set = {}
    local result = {}
    
    for _, config in pairs(Compound) do
        if config.Group1 == group1 and not group2Set[config.Group2] then
            group2Set[config.Group2] = true
            table.insert(result, config.Group2)
        end
    end
    
    table.sort(result)
    return result
end

-- 客户端打开合成界面
function compoundMain.OpenCompoundUI(actor)
    local isPc = clientflag(actor) == 1
    
    -- 发送分组数据到客户端
    local group1List = compoundMain.GetGroup1List()
    local group2Map = {}
    
    for _, g1 in ipairs(group1List) do
        group2Map[g1] = compoundMain.GetGroup2List(g1)
    end
    
    Message.sendmsgEx(actor, "compoundMain", "initCompoundData", {
        group1List = group1List,
        group2Map = group2Map,
    })
    
    -- 打开UI
    if isPc then
        FGUI:Open("A_Compound_PC", "compoundMain_PC")
    else
        FGUI:Open("A_Compound", "compoundMain")
    end
    
    print("打开合成界面:", getname(actor))
end

-- 处理客户端合成请求
function compoundMain.HandleCompoundRequest(actor, postData)
    if not postData or not postData.compoundID then
        sendmsg(actor, 9, "请求数据错误")
        return
    end
    
    local compoundID = tonumber(postData.compoundID)
    compoundMain.StartCompound(actor, compoundID)
end
