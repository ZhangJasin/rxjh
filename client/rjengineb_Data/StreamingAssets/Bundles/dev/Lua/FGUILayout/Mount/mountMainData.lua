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

    -- 灵兽相关数据
    _dataForPet.petHHid = SL:GetValue("U", 59)
    _dataForPet.modelId = SL:GetValue("U", 60) > 0 and SL:GetValue("U", 60) or
                              (Pet[1] and Pet[1].Model) or 800001
    _dataForPet.isPetChuzhan = SL:GetValue("U", 62)
    _dataForPet.isPetJh = SL:GetValue("U", 63) -- 是否已激活
    _dataForPet.allJieshu = SL:GetValue("U", 61)

    local t9 = SL:GetValue("T", 9)
    if t9 and t9 ~= "" then _dataForPet.allPetsActive = SL:JsonDecode(t9) end

    local t17 = SL:GetValue("T", 17)
    if t17 and t17 ~= "" then _dataForPet.allPetsToModel = SL:JsonDecode(t17) end

    _dataForPet.showPetModelId = SL:GetValue("U", 57) -- 当前显示模型id
    _dataForPet.selectViewPetId = SL:GetValue("U", 58) -- 当前选择的主体id
    if _dataForPet.allPetsActive == 0 then _dataForPet.allPetsActive = {} end
    if _dataForPet.hhlistsj == 0 then _dataForPet.hhlistsj = {} end
    -- 灵兽列表排序
    self:initPetData()
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
-- 灵兽初始化数据
function mountMainData:initPetData()
    -- 分类灵兽和幻化
    _dataForPet.allPets = {}
    _dataForPet.allPetsHH = {}
    for i, v in pairs(PetHuanhua) do
        if tonumber(v.grade) == 1 then
            -- 灵兽本体（grade=1为本体，>1为幻化）
            local obj = v
            -- 设置排序位置
            if _dataForPet.allPetsActive[v.Name] then
                obj.weizhi = 1
            else
                obj.weizhi = 2
            end
            -- 不隐藏的加入列表
            if v.Is_Hide ~= 1 then
                table.insert(_dataForPet.allPets, obj)
            end
        else
            -- 灵兽幻化（grade>1）
            if v.Is_Hide ~= 1 then
                table.insert(_dataForPet.allPetsHH, v)
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
end
-- 灵兽本体排序
function mountMainData:initPetDataSort()
    local index = 1
    for i = 1, #_dataForPet.allPets do
        local item = _dataForPet.allPets[i]
        if _dataForPet.allPetsActive[item.Pet_Name] then
            _dataForPet.allPets[i].weizhi = 1
        else
            _dataForPet.allPets[i].weizhi = 2
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
end
-- 设置灵兽幻化列表排序
function mountMainData:setPetHHListSort()
    local names = {}
    local results = {}
    for i = 1, #_dataForPet.allPetsHH do
        if not names[_dataForPet.allPetsHH[i].Name] then
            if _dataForPet.hhlistsj[_dataForPet.allPetsHH[i].Name] then
                -- 已激活
                names[_dataForPet.allPetsHH[i].Name] = 1
                local obj = _dataForPet.allPetsHH[i]
                obj.weizhi = 2
                if self:getPetNameByModel(_dataForPet.petHHid) ==
                    _dataForPet.allPetsHH[i].Name then obj.weizhi = 1 end
                table.insert(results, obj)
            else
                -- 未激活但满足条件
                if (not names[_dataForPet.allPetsHH[i].Name]) and _dataForPet.allPetsHH[i].grade ==
                    1 and SL:GetValue(CONDITION, _dataForPet.allPetsHH[i].Condition) then
                    names[_dataForPet.allPetsHH[i].Name] = 1
                    local obj = _dataForPet.allPetsHH[i]
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
-- 网络消息
-- {id = 本体id, modelid = 新外型Model, btmodelId = 本体外型Model }
function mountMainData:updateLSView(data)
    _dataForPet.allPetsActive = data.allPets
    self:initPetDataSort()
    local selectPetIndex = 1
    for i = 1, #_dataForPet.allPets do
        if _dataForPet.allPets[i].Name == data.name then
            selectPetIndex = i
        end
    end
    self:Publish("ls_list_update", {
        _dataForPet = self:GetDataForPet(),
        selectPetIndex = selectPetIndex
    })
end
-- {lv = hasPet[data.name], Name = data.name}
function mountMainData:level(data)
    _dataForPet.allPetsActive[data.Name] = data.lv
    self:initPetDataSort()
    -- 更新视图
    self:Publish("ls_level_result", self:GetDataForPet())
end
function mountMainData:updatePetModelResult(data)
    _dataForPet.allPetsToModel = data.allPetsHHData
    _dataForPet.showPetModelId = data.showPetModelId
    _dataForPet.petHHid = data.petHHid or 0
    _dataForPet.hhSortList = self:setPetHHListSort()
    self:Publish("ls_update_model", self:GetDataForPet())
end

function mountMainData:recallpetResult(data)
    _dataForPet.showPetModelId = data.showPetModelId
    _dataForPet.selectViewPetId = data.selectViewPetId
    self:Publish("ls_update_model", self:GetDataForPet())
end

function mountMainData:unrecallpetResult()
    _dataForPet.showPetModelId = 0
    _dataForPet.selectViewPetId = 0
    _dataForPet.isPetChuzhan = STATUS.REST
    self:Publish("ls_unrecallpet", self:GetDataForPet())
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
    local name = ""
    for i = 1, #_dataForPet.allPetsHH do
        if _dataForPet.allPetsHH[i].Model == tonumber(model) then
            name = _dataForPet.allPetsHH[i].Name
        end
    end
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
        _dataForMount.hhlistsj = {}
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
    if data.lv == 1 then
        -- 首次激活
        _dataForPet.isPetJh = 1
        _dataForPet.hhlistsj = {}
    end
    -- 更新阶数和视图
    _dataForPet.allJieshu = tonumber(data.lv)
    self:Publish("petLevelUp", self:GetDataForPet())
end

-- 灵兽出战休息后
function mountMainData:updatePetBtnName(data)
    _dataForPet.isPetChuzhan = data.status
    self:Publish("petUpdateBtn", self:GetDataForPet())
end

return mountMainData
