file_path = r'd:\works\RXjianghu\rxjianghu1\Mirserver\Mir200\Envir\Market_Def\QFunction-0.lua'

with open(file_path, 'r', encoding='gbk') as f:
    content = f.read()

# Fix m_base: actor is player, target is monster
old_m_base = """function m_base(actor, target, effectId, skillId, skillLv, Param1)
    print('[m_base] ==== START ====')
    print('[m_base] actor=' .. tostring(actor) .. ', target=' .. tostring(target))
    print('[m_base] effectId=' .. tostring(effectId) .. ', skillId=' .. tostring(skillId) .. ', skillLv=' .. tostring(skillLv))
    print('[m_base] Param1=' .. tostring(Param1))
    
    local originalDamage = tonumber(Param1) or 0
    print('[m_base] originalDamage=' .. originalDamage)
    
    -- 对怪防御（属性56）：固定值减免
    local pveDef = abil(target, 56) or 0
    local curPveDef = currabil(target, 56) or 0
    print('[m_base] target abil(56)=' .. pveDef .. ', currabil=' .. curPveDef)
    
    if pveDef > 0 then
        local beforeReduce = originalDamage
        originalDamage = math.max(1, originalDamage - pveDef)
        print('[m_base] after pveDef: ' .. beforeReduce .. ' - ' .. pveDef .. ' = ' .. originalDamage)
    end
    
    -- 受怪减伤（属性116）：万分比减免
    local reducePct = abil(target, 116) or 0
    local curReducePct = currabil(target, 116) or 0
    print('[m_base] target abil(116)=' .. reducePct .. ', currabil=' .. curReducePct)
    
    if reducePct > 0 then
        local reduced = math.floor(originalDamage * reducePct / 10000)
        print('[m_base] reduce calculation: ' .. originalDamage .. ' * ' .. reducePct .. ' / 10000 = ' .. reduced)
        originalDamage = math.max(1, originalDamage - reduced)
        print('[m_base] after reducePct: final=' .. originalDamage)
    end
    
    print('[m_base] ==== END: return ' .. originalDamage .. ' ====')
    return originalDamage
end"""

new_m_base = """-- 怪物技能伤害公式函数（SkillEffect.xls Fumula=base时触发）
-- 根据引擎文档：actor=玩家对象ID, target=目标唯一ID(怪物)
-- Param1=原始伤害值
-- 返回=计算后的最终伤害
function m_base(actor, target, effectId, skillId, skillLv, Param1)
    print('[m_base] ==== START ====')
    print('[m_base] actor(玩家)=' .. tostring(actor) .. ', target(怪物)=' .. tostring(target))
    print('[m_base] effectId=' .. tostring(effectId) .. ', skillId=' .. tostring(skillId) .. ', skillLv=' .. tostring(skillLv))
    print('[m_base] Param1(原始伤害)=' .. tostring(Param1))
    
    -- actor是玩家，target是怪物
    local originalDamage = tonumber(Param1) or 0
    print('[m_base] originalDamage=' .. originalDamage)
    
    -- 对怪防御（属性56）：固定值减免，属性在玩家身上
    local pveDef = abil(actor, 56) or 0
    local curPveDef = currabil(actor, 56) or 0
    print('[m_base] actor abil(56)=' .. pveDef .. ', currabil=' .. curPveDef)
    
    if pveDef > 0 then
        local beforeReduce = originalDamage
        originalDamage = math.max(1, originalDamage - pveDef)
        print('[m_base] after pveDef: ' .. beforeReduce .. ' - ' .. pveDef .. ' = ' .. originalDamage)
    end
    
    -- 受怪减伤（属性116）：万分比减免，属性在玩家身上
    local reducePct = abil(actor, 116) or 0
    local curReducePct = currabil(actor, 116) or 0
    print('[m_base] actor abil(116)=' .. reducePct .. ', currabil=' .. curReducePct)
    
    if reducePct > 0 then
        local reduced = math.floor(originalDamage * reducePct / 10000)
        print('[m_base] reduce calculation: ' .. originalDamage .. ' * ' .. reducePct .. ' / 10000 = ' .. reduced)
        originalDamage = math.max(1, originalDamage - reduced)
        print('[m_base] after reducePct: final=' .. originalDamage)
    end
    
    print('[m_base] ==== END: return ' .. originalDamage .. ' ====')
    return originalDamage
end"""

if old_m_base in content:
    content = content.replace(old_m_base, new_m_base)
    print('Fixed m_base to read attributes from actor (player) instead of target (monster)')
else:
    print('Old m_base not found')

with open(file_path, 'w', encoding='gbk') as f:
    f.write(content)
