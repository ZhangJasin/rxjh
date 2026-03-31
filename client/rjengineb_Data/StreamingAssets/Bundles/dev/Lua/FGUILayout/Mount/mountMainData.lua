-- 坐骑和灵兽数据管理器
local mountMainData = {}

local Mount = require("game_config/cfgcsv/Mount")
local MountHuanhua = require("game_config/cfgcsv/MountHuanhua")
local Pet = require("game_config/cfgcsv/Pet")
local PetHuanhua = require("game_config/cfgcsv/PetHuanhua")

-- 常量定义
local TAB_TYPE = {
    MOUNT = 0, -- 坐骑标签
    MOUNT_HH = 1, -- 坐骑幻化标签
    PET = 2, -- 灵兽标签
    PET_HH = 3 -- 灵兽幻化标签
}

local STATUS = {
    FIGHT = 0, -- 出战状态
    REST = 1 -- 休息状态
}

-- 数据存储结构
local _data = {
    _subscribers = {} -- 事件订阅者
}
local _dataForMount = {
    mountHHid = 0, -- 当前坐骑id
    ischuzhan = 0, -- 是否出战
    isJh = 0, -- 是否已激活
    modelId = (Mount[1] and Mount[1].Model) or 800001, -- 当前坐骑基础模型id
    allJieshu = 0, -- 坐骑总星星数
    hhlistsj = {}, -- 坐骑幻化升级对象
    hhSortList = {} -- 坐骑幻化列表排序后的
}

local _dataForPet = {
    petHHid = 0, -- 当前灵兽幻化id
    isPetChuzhan = 0, -- 灵兽是否出战
    isPetJh = 0, -- 灵兽是否已激活
    modelId = (Pet[1] and Pet[1].Model) or 800001, -- 当前灵兽基础模型id
    allJieshu = 0, -- 灵兽总星星数
    hhlistsj = {}, -- 灵兽幻化升级对象
    hhSortList = {}, -- 灵兽幻化列表排序后的
    allPetsActive = {}, -- 当前灵兽激活情况
    allPetsToModel = {}, -- 已激活的本体
    showPetModelId = 0, -- 当前显示模型id
    petIndex = 0, -- 当前显示模型下标 0本体 0以上幻化
    allPets = {}, -- 灵兽初始化
    allPetsHH = {}, -- 灵兽幻化
    selectPetIndex = 1, -- 当前选择索引
    selectViewPetId = 0 -- 当前出战宠物本体ID
}

-- 初始化数据管理器
function mountMainData:Init()
    -- 坐骑相关数据
    _dataForMount.mountHHid = SL:GetValue("U", 36)
    _dataForMount.modelId = SL:GetValue("U", 37) > 0 and SL:GetValue("U", 37) or
                                (Mount[1] and Mount[1].Model) or 800001
    _dataForMount.ischuzhan = SL:GetValue("U", 39)
    _dataForMount.isJh = SL:GetValue("U", 40) -- 是否已激活
    _dataForMount.allJieshu = SL:GetValue("U", 35)

    local t7 = SL:GetValue("T", 7)
    if t7 and t7 ~= "" then _dataForMount.hhlistsj = SL:JsonDecode(t7) end

    if _dataForMount.hhlistsj == 0 then _dataForMount.hhlistsj = {} end
    _dataForMount.hhSortList = self:setHHListSort()

    -- 灵兽相关数据（使用新变量）
    _dataForPet.petHHid = SL:GetValue("U", 107) -- U_Pet_Take_Id 灵兽幻化ID
    _dataForPet.modelId = SL:GetValue("U", 108) > 0 and SL:GetValue("U", 108) or -- U_Pet_Base_ID
                              (Pet[1] and Pet[1].Model) or 800001
    -- U_Pet_IS_SET: 0=休息, 1=出战
    -- 客户端 isPetChuzhan: 0=休息(显示"召回"), 1=出战(显示"出战")
    -- 直接读取，不需要转换
    _dataForPet.isPetChuzhan = SL:GetValue("U", 110) or 0
    _dataForPet.isPetJh = SL:GetValue("U", 106) > 0 and 1 or 0 -- U_All_Pet_star 是否已激活 (0=未激活,1=已激活)
    _dataForPet.allJieshu = SL:GetValue("U", 106) -- U_All_Pet_star 灵兽总星级

    local t119 = SL:GetValue("T", 119) -- T_PetHuanHua 灵兽幻化激活对象
    if t119 and t119 ~= "" then 
        _dataForPet.hhlistsj = SL:JsonDecode(t119) 
    end

    -- 修复：showPetModelId应该使用U_Pet_Take_Id(107)作为显示模型，U_Pet_Base_ID(108)是基础模型
    -- 判断是否有幻化：有幻化时petHHid有值且U_Pet_IS_HH(U109)为1，否则显示基础模型
    local petISHH = tonumber(SL:GetValue("U", 109)) -- U_Pet_IS_HH 是否幻化 (0=未幻化,1=已幻化)
    print("=== Init 读取灵兽数据 ===")
    print("petHHid (U107):", _dataForPet.petHHid)
    print("petISHH (U109):", petISHH)
    print("modelId (U108):", SL:GetValue("U", 108))
    if petISHH == 1 and _dataForPet.petHHid and tonumber(_dataForPet.petHHid) > 0 then
        _dataForPet.showPetModelId = tonumber(_dataForPet.petHHid) -- 使用幻化模型ID
        print("使用幻化模型ID:", _dataForPet.showPetModelId)
    else
        _dataForPet.showPetModelId = SL:GetValue("U", 108) -- 使用基础模型ID
        print("使用基础模型ID:", _dataForPet.showPetModelId)
    end
    _dataForPet.selectViewPetId = SL:GetValue("U", 108) -- U_Pet_Base_ID 选中主体id
    if not _dataForPet.hhlistsj or _dataForPet.hhlistsj == 0 then _dataForPet.hhlistsj = {} end
    -- 兼容旧字段
    _dataForPet.allPetsActive = _dataForPet.hhlistsj
    _dataForPet.allPetsToModel = _dataForPet.hhlistsj
    -- 灵兽幻化列表排序
    _dataForPet.hhSortList = self:setPetHHListSort()
end

-- 获取单例实例
function mountMainData.Get() return mountMainData end
-- 获取当前坐骑数据状态
function mountMainData:GetDataForMount()
    return {
        mountHHid = _dataForMount.mountHHid, -- 当前坐骑id
        ischuzhan = _dataForMount.ischuzhan, -- 是否出战
        modelId = _dataForMount.modelId, -- 当前坐骑基础模型id
        isJh = _dataForMount.isJh, -- 是否已激活
        allJieshu = _dataForMount.allJieshu, -- 坐骑总星星数
        hhlistsj = _dataForMount.hhlistsj, -- 坐骑幻化升级对象
        hhSortList = _dataForMount.hhSortList -- 坐骑幻化列表排序后的
    }
end
-- 获取当前宠物数据状态
function mountMainData:GetDataForPet()
    return {
        petHHid = _dataForPet.petHHid, -- 当前灵兽幻化id
        isPetChuzhan = _dataForPet.isPetChuzhan, -- 灵兽是否出战
        modelId = _dataForPet.modelId, -- 当前灵兽基础模型id
        isPetJh = _dataForPet.isPetJh, -- 灵兽是否已激活
        allJieshu = _dataForPet.allJieshu, -- 灵兽总星星数
        hhlistsj = _dataForPet.hhlistsj, -- 灵兽幻化升级对象
        hhSortList = _dataForPet.hhSortList, -- 灵兽幻化列表排序后的
        allPetsActive = _dataForPet.allPetsActive, -- 当前灵兽激活情况
        allPetsToModel = _dataForPet.allPetsToModel, -- 已激活的本体
        showPetModelId = _dataForPet.showPetModelId, -- 当前显示模型id
        selectViewPetId = _dataForPet.selectViewPetId, -- 当前选择的主体id
        petIndex = _dataForPet.petIndex, -- 当前显示模型下标 0本体 0以上幻化
        allPets = _dataForPet.allPets, -- 灵兽初始化
        allPetsHH = _dataForPet.allPetsHH, -- 灵兽幻化
        selectPetIndex = _dataForPet.selectPetIndex -- 当前选择索引
    }
end
-- 事件系统：订阅事件
function mountMainData:Subscribe(event, callback)
    if not _data._subscribers[event] then _data._subscribers[event] = {} end
    local token = #_data._subscribers[event] + 1
    _data._subscribers[event][token] = callback
    return {event = event, token = token}
end
-- 事件系统：取消订阅
function mountMainData:Unsubscribe(subscription)
    if subscription and subscription.event and subscription.token then
        if _data._subscribers[subscription.event] then
            _data._subscribers[subscription.event][subscription.token] = nil
        end
    end
end
-- 事件系统：发布事件
function mountMainData:Publish(event, data)
    if _data._subscribers[event] then
        for _, callback in pairs(_data._subscribers[event]) do
            if callback then callback(data) end
        end
    end
end
-- 灵兽相关事件
-- 灵兽初始化数据（空函数，已废弃）
function mountMainData:initPetData()
    print("=== initPetData 已废弃 ===")
end

-- 设置灵兽主标题
function mountMainData:setPetMainTitle()
    local nowName = "龙猫"
    if _dataForPet.allJieshu > 0 then
        local petData = Pet[_dataForPet.allJieshu]
        if petData then
            nowName = petData.Name
        end
    end
    return nowName
end

-- 设置坐骑主标题
function mountMainData:setMountMainTitle()
    local nowName = "乌龙驹"
    if _dataForMount.allJieshu > 0 then
        local mountData = Mount[_dataForMount.allJieshu]
        if mountData then
            nowName = mountData.Name
        end
    end
    return nowName
end
-- 灵兽本体排序
function mountMainData:initPetDataSort()
    print("=== initPetDataSort 开始 ===")
    print("allPets 数量:", #_dataForPet.allPets)
    print("allPetsActive:", _dataForPet.allPetsActive)
    
    -- 如果 allPets 为空，从 Pet 配表初始化
    if #_dataForPet.allPets == 0 then
        print("从 Pet 配表初始化 allPets")
        for i = 1, #Pet do
            if Pet[i] and Pet[i].Name then
                local obj = Pet[i]
                -- 设置排序位置
                if _dataForPet.allPetsActive[Pet[i].Name] then
                    obj.weizhi = 1
                else
                    obj.weizhi = 2
                end
                table.insert(_dataForPet.allPets, obj)
            end
        end
    else
        print("使用现有 allPets 进行排序")
        local index = 1
        for i = 1, #_dataForPet.allPets do
            local item = _dataForPet.allPets[i]
            if _dataForPet.allPetsActive[item.Name] then
                _dataForPet.allPets[i].weizhi = 1
            else
                _dataForPet.allPets[i].weizhi = 2
            end
        end
    end
    
    -- 排序：已激活 > 未激活
    table.sort(_dataForPet.allPets, function(a, b)
        if a.weizhi == b.weizhi then
            return a.ID < b.ID
        else
            return a.weizhi < b.weizhi
        end
    end)
    
    print("=== initPetDataSort 完成, 排序后数量:", #_dataForPet.allPets, "===")
end
-- 设置灵兽幻化列表排序
function mountMainData:setPetHHListSort()
    print("=== setPetHHListSort 开始 ===")
    print("PetHuanhua 配表条目数:", #PetHuanhua)
    print("hhlistsj:", _dataForPet.hhlistsj)
    
    local names = {}
    local results = {}
    
    for i = 1, #PetHuanhua do
        local hhItem = PetHuanhua[i]
        -- 跳过非幻化数据（灵兽本体在Pet配表，不是PetHuanhua）
        if hhItem.grade and tonumber(hhItem.grade) > 0 then
            if not names[hhItem.Name] then
                -- 检查是否已激活
                if _dataForPet.hhlistsj[hhItem.Name] then
                    -- 已激活
                    names[hhItem.Name] = 1
                    local obj = hhItem
                    obj.weizhi = 2
                    -- 检查是否当前幻化
                    if self:getPetNameByModel(_dataForPet.petHHid) == hhItem.Name then
                        obj.weizhi = 1
                    end
                    table.insert(results, obj)
                    print("添加已激活幻化:", hhItem.Name, "weizhi:", obj.weizhi)
                else
                    -- 未激活但满足条件（grade=1表示该幻化的第一级）
                    if hhItem.grade == 1 and SL:GetValue(CONDITION, hhItem.Condition) then
                        names[hhItem.Name] = 1
                        local obj = hhItem
                        obj.weizhi = 3
                        table.insert(results, obj)
                        print("添加未激活幻化:", hhItem.Name, "weizhi:", obj.weizhi)
                    else
                        print("跳过未激活幻化:", hhItem.Name, "grade:", hhItem.grade, "Condition:", hhItem.Condition)
                    end
                end
            end
        end
    end
    
    -- 排序：已幻化 > 已激活 > 未激活
    table.sort(results, function(a, b)
        if a.weizhi == b.weizhi then
            return a.ID < b.ID
        else
            return a.weizhi < b.weizhi
        end
    end)
    
    print("=== setPetHHListSort 完成, 结果数量:", #results, "===")
    return results
end

-- 设置幻化列表排序
function mountMainData:setHHListSort()
    local names = {}
    local results = {}
    for i = 1, #MountHuanhua do
        if not names[MountHuanhua[i].Name] then
            if _dataForMount.hhlistsj[MountHuanhua[i].Name] then
                -- 已激活
                names[MountHuanhua[i].Name] = 1
                local obj = MountHuanhua[i]
                obj.weizhi = 2
                if self:getNameByModel(_dataForMount.mountHHid) ==
                    MountHuanhua[i].Name then obj.weizhi = 1 end
                table.insert(results, obj)
            else
                -- 未激活但满足条件
                if (not names[MountHuanhua[i].Name]) and MountHuanhua[i].grade ==
                    1 and SL:GetValue(CONDITION, MountHuanhua[i].Condition) then
                    names[MountHuanhua[i].Name] = 1
                    local obj = MountHuanhua[i]
                    obj.weizhi = 3
                    table.insert(results, obj)
                end
            end
        end
    end
    -- 排序：已幻化 > 已激活 > 未激活
    table.sort(results, function(a, b)
        if a.weizhi == b.weizhi then
            return a.ID < b.ID
        else
            return a.weizhi < b.weizhi
        end
    end)
    return results
end
-- 网络请求
-- 灵兽激活
-- {itemId = 消耗道具id}
function mountMainData:lsjihuo(data)
    ssrMessage:sendmsgEx("mountMain", "lsjihuo", data)
end
-- 灵兽升级
-- {name = 宠物名字, maxLv = 最高级别, num = 消耗数量, itemId = 升级材料id}
function mountMainData:levelUp(data)
    ssrMessage:sendmsgEx("mountMain", "levelUp", data)
end
-- 灵兽幻化 取消幻化
function mountMainData:updatePetModel(data)
    ssrMessage:sendmsgEx("mountMain", "updatePetModel", data)
end
-- 灵兽幻化激活升级
function mountMainData:petTodoHHlist(data)
    ssrMessage:sendmsgEx("mountMain", "petHuanhuajihuo", data)
end
-- 灵兽召唤
-- { btid = 本体id, isNeedBack = 1 }
function mountMainData:recallpet(data)
    ssrMessage:sendmsgEx("mountMain", "recallpet", data)
end
-- 灵兽收回
function mountMainData:unrecallpet()
    ssrMessage:sendmsgEx("mountMain", "unrecallpet", {isNeedBack = 1})
end
-- 灵兽出战
function mountMainData:petChuzhan()
    ssrMessage:sendmsgEx("mountMain", "petChuzhan")
end
-- 网络消息 - 单灵兽系统：激活灵兽
-- {lv = 灵兽等级, name = "pet"}
function mountMainData:updateLSView(data)
    -- 单灵兽系统：直接更新灵兽激活状态
    _dataForPet.isPetJh = data.lv > 0 and 1 or 0
    _dataForPet.allJieshu = data.lv
    print("=== updateLSView 单灵兽激活 === lv:", data.lv)
    self:Publish("ls_list_update", {
        _dataForPet = self:GetDataForPet(),
        selectPetIndex = 1
    })
end
-- {lv = 灵兽等级, Name = "pet"}
function mountMainData:level(data)
    -- 单灵兽系统：直接更新灵兽等级
    _dataForPet.allJieshu = data.lv
    print("=== level 单灵兽升级 === lv:", data.lv)
    -- 更新视图
    self:Publish("ls_level_result", self:GetDataForPet())
end
function mountMainData:updatePetModelResult(data)
    print("=== 客户端收到updatePetModelResult ===")
    print("data:", data)
    print("showPetModelId:", data.showPetModelId)
    _dataForPet.allPetsToModel = data.allPetsHHData
    _dataForPet.showPetModelId = data.showPetModelId
    _dataForPet.petHHid = data.petHHid or 0
    _dataForPet.hhSortList = self:setPetHHListSort()
    print("发布ls_update_model, showPetModelId:", _dataForPet.showPetModelId)
    self:Publish("ls_update_model", self:GetDataForPet())
    -- 发布幻化切换结果事件，刷新页面
    self:Publish("updatePetModelResult", data)
end

function mountMainData:recallpetResult(data)
    print("=== 客户端收到recallpetResult消息 ===")
    _dataForPet.showPetModelId = data.showPetModelId
    _dataForPet.selectViewPetId = data.selectViewPetId
    _dataForPet.isPetChuzhan = 0  -- 出战状态
    self:Publish("ls_update_model", self:GetDataForPet())
    self:Publish("petUpdateBtn", self:GetDataForPet())  -- 额外发布按钮更新事件
end

function mountMainData:unrecallpetResult()
    print("=== 客户端收到unrecallpetResult消息 ===")
    _dataForPet.showPetModelId = 0
    _dataForPet.selectViewPetId = 0
    _dataForPet.isPetChuzhan = STATUS.REST  -- 休息状态
    self:Publish("ls_unrecallpet", self:GetDataForPet())
    self:Publish("petUpdateBtn", self:GetDataForPet())  -- 额外发布按钮更新事件
end

-- 灵兽幻化模型切换
-- {mountId = 选择的灵兽幻化模型id}
function mountMainData:setPetModel(data)
    ssrMessage:sendmsgEx("mountMain", "setPetModel", data)
end

-- 坐骑
-- {mountId = 选择的模型id}
function mountMainData:setModel(data)
    ssrMessage:sendmsgEx("mountMain", "setModel", data)
end
-- 幻化结果
-- {mountHHid = U36 ,isCancel=是否取消0否1是,oldModelId=旧的幻化id}
function mountMainData:UpdateHHBtnName(data)
    _dataForMount.mountHHid = data.mountHHid
    -- 重新排序
    _dataForMount.hhSortList = self:setHHListSort()
    local selectHHIndex = 1
    if tonumber(data.isCancel) == 0 then
        selectHHIndex = 1
    else
        for i = 1, #_dataForMount.hhSortList do
            if _dataForMount.hhSortList[i].Name ==
                self:getNameByModel(data.oldModelId) then
                selectHHIndex = i
            end
        end
    end
    self:Publish("updateHHResult", {
        _dataForMount = self:GetDataForMount(),
        selectHHIndex = selectHHIndex
    })
end
function mountMainData:getNameByModel(model)
    local name = ""
    for i = 1, #MountHuanhua do
        if MountHuanhua[i].Model == tonumber(model) then
            name = MountHuanhua[i].Name
        end
    end
    return name
end

-- 根据模型获取灵兽名字
function mountMainData:getPetNameByModel(model)
    print("=== getPetNameByModel 开始, model:", model, "===")
    local name = ""
    for i = 1, #PetHuanhua do
        if PetHuanhua[i].Model == tonumber(model) then
            name = PetHuanhua[i].Name
            print("找到匹配的灵兽:", name, "Model:", PetHuanhua[i].Model)
        end
    end
    print("=== getPetNameByModel 完成, 返回:", name, "===")
    return name
end
--  idx = 幻化id
--  Name = 幻化名字
--  grade = 品阶
--  ClassID = 幻化属性
--  Cost = 材料
function mountMainData:todoHHlist(data)
    ssrMessage:sendmsgEx("mountMain", "huanhuajihuo", data)
end
-- 坐骑幻化升级激活结果
-- name = name,grade=grade,ycList=ycList,mountHHid=mountHHid
function mountMainData:updateHHmodel(data)
    _dataForMount.hhlistsj = data.ycList
    _dataForMount.mountHHid = data.mountHHid
    _dataForMount.hhSortList = self:setHHListSort()
    local selectHHIndex = 0
    for i = 1, #_dataForMount.hhSortList do
        if _dataForMount.hhSortList[i].Name == data.name then
            selectHHIndex = i
        end
    end
    self:Publish("updateHHResult", {
        _dataForMount = self:GetDataForMount(),
        selectHHIndex = selectHHIndex
    })
end

function mountMainData:shengji() ssrMessage:sendmsgEx("mountMain", "shengji") end
-- 坐骑升级后更新坐骑数据
function mountMainData:updateZQ(data)
    if data.lv == 1 then
        -- 首次激活
        _dataForMount.isJh = 1
        -- 只有当幻化列表为空时才初始化，避免覆盖已激活的幻化数据
        if not _dataForMount.hhlistsj or next(_dataForMount.hhlistsj) == nil then
            _dataForMount.hhlistsj = {}
        end
    end
    -- 更新阶数和视图
    _dataForMount.allJieshu = tonumber(data.lv)
    self:Publish("mountLevelUp", self:GetDataForMount())
end

function mountMainData:chuzhan() ssrMessage:sendmsgEx("mountMain", "chuzhan") end
-- 坐骑出战休息后
-- status 当前状态
function mountMainData:updateBtnName(data)
    _dataForMount.ischuzhan = data.status
    self:Publish("mountUpdateBtn", self:GetDataForMount())
end

-- 灵兽幻化升级激活结果
-- name = name,grade=grade,ycList=ycList,petHHid=petHHid
function mountMainData:updatePetHHmodel(data)
    _dataForPet.hhlistsj = data.ycList
    _dataForPet.petHHid = data.petHHid
    -- 同步更新showPetModelId，确保灵兽升阶页面显示幻化模型
    if data.petHHid and data.petHHid > 0 then
        _dataForPet.showPetModelId = tonumber(data.petHHid)
    end
    _dataForPet.hhSortList = self:setPetHHListSort()
    local selectHHIndex = 0
    for i = 1, #_dataForPet.hhSortList do
        if _dataForPet.hhSortList[i].Name == data.name then
            selectHHIndex = i
        end
    end
    self:Publish("petUpdateHHResult", {
        _dataForPet = self:GetDataForPet(),
        selectHHIndex = selectHHIndex
    })
end

-- 灵兽幻化结果
function mountMainData:UpdatePetHHBtnName(data)
    _dataForPet.petHHid = data.petHHid
    -- 重新排序
    _dataForPet.hhSortList = self:setPetHHListSort()
    local selectHHIndex = 1
    if tonumber(data.isCancel) == 0 then
        selectHHIndex = 1
    else
        for i = 1, #_dataForPet.hhSortList do
            if _dataForPet.hhSortList[i].Name ==
                self:getPetNameByModel(data.oldModelId) then
                selectHHIndex = i
            end
        end
    end
    self:Publish("petUpdateHHResult", {
        _dataForPet = self:GetDataForPet(),
        selectHHIndex = selectHHIndex
    })
end

-- 灵兽升级后更新灵兽数据
function mountMainData:updatePetZQ(data)
    print("=== 客户端收到灵兽升级消息 ===")
    print("等级:", data.lv, "基础模型:", data.petBaseId)
    if data.lv == 1 then
        -- 首次激活
        print("首次激活灵兽")
        _dataForPet.isPetJh = 1
        -- 只有当幻化列表为空时才初始化，避免覆盖已激活的幻化数据
        if not _dataForPet.hhlistsj or next(_dataForPet.hhlistsj) == nil then
            _dataForPet.hhlistsj = {}
        end
        -- 激活后默认为休息状态（1=休息，显示"出战"按钮）
        _dataForPet.isPetChuzhan = 1
        -- 发布按钮更新事件
        self:Publish("petUpdateBtn", self:GetDataForPet())
    end
    -- 更新阶数和视图
    _dataForPet.allJieshu = tonumber(data.lv)
    -- 更新模型ID：如果有幻化模型ID则使用幻化模型，否则使用基础模型
    if data.showPetModelId and data.showPetModelId > 0 then
        _dataForPet.modelId = tonumber(data.showPetModelId)
        _dataForPet.showPetModelId = tonumber(data.showPetModelId)
    else
        _dataForPet.modelId = tonumber(data.petBaseId)
    end
    -- 更新基础模型ID（保存到变量但不显示）
    _dataForPet.petBaseId = tonumber(data.petBaseId)
    print("更新灵兽等级:", _dataForPet.allJieshu, "模型ID:", _dataForPet.modelId)
    print("发布petLevelUp事件")
    self:Publish("petLevelUp", self:GetDataForPet())
end

-- 灵兽出战休息后（服务端消息 petUpdateBtn 回调）
function mountMainData:petUpdateBtn(data)
    print("=== 客户端收到petUpdateBtn消息 ===")
    print("data:", data)
    print("isPetChuzhan:", data.isPetChuzhan)
    -- 接收服务端返回的数据并更新内存
    if data.isPetChuzhan ~= nil then
        _dataForPet.isPetChuzhan = data.isPetChuzhan
    end
    if data.isPetJh ~= nil then
        _dataForPet.isPetJh = data.isPetJh
    end
    if data.allJieshu ~= nil then
        _dataForPet.allJieshu = data.allJieshu
    end
    self:Publish("petUpdateBtn", self:GetDataForPet())
    print("petUpdateBtn事件已发布")
end

return mountMainData
