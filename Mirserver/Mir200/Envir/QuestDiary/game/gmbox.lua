--require("Envir/QuestDiary/util.lua")
gmbox = {}
local filname = "gmbox"
local Task_cfg  =  require("Envir/QuestDiary/game_config/cfgcsv/Task.lua")
local Language_cfg = require("Envir/QuestDiary/game_config/cfgcsv/Language")

function gmbox.wudiclose(actor)
	setstate(actor, 2, 0)
	-- setscriptabilvalue(actor, 23, "=", 0)
	-- setscriptabilvalue(actor, 9, "=", 0)
	-- setscriptabilvalue(actor, 5, "=", 0)
	delattlist(actor, VarCfg.Attr_GM_Invincible)
end
function gmbox.wudiopen(actor)
	setstate(actor, 2, 1)
	-- setscriptabilvalue(actor, 23, "=", 9999999)
	-- setscriptabilvalue(actor, 9, "=", 100000)
	-- setscriptabilvalue(actor, 5, "=", 100000)
	addattlist(actor, VarCfg.Attr_GM_Invincible, "=", "23#999999999&9#100000&5#100000")
end

function gmbox.func(actor,params)
	-- changeabil(actor, 74, "=", 5)
	-- print("params="..tostring(params))
	-- changescriptappear(actor, 12, 500094)
	-- print("职业",job(actor)) 
	-- print("移动速度",abil(actor, 9))
	local index1,index2,index3 = tonumber(params[1]),tonumber(params[2]),tonumber(params[3])
	local data = Strsplit(params[4], "|")
	local player = actor
	local mapid = targetinfo(player, "NEWMAP")  --当前地图id
	if index1 == 1 then  --玩家
		local playname = data[1]
		if playname ~= "0" then
			player = uniqueid(playname)
		end
		if not checkstate(player,2) then 
			sendmsg(actor, 9, "玩家不在线")
			return
		end
		if tostring(player) == "0" then 
			sendmsg(actor, 9, "玩家不在线")
			return
		end
		if index2 == 1 then   --货币
			if index3 == 3 then
				changemoney(player, 1, "+", 100000000)
				sendmsg(player, 6, "当前金币数量为："..money(player, 1))
				return
			elseif index3 == 4 then
				changemoney(player, 1, "=", 0)
				sendmsg(player, 6, "当前金币数量为："..money(player, 1))
				return
			elseif index3 == 5 then
				changemoney(player, 2, "+", 100000000)
				sendmsg(player, 6, "当前元宝数量为："..money(player, 2))
				return
			elseif index3 == 6 then
				changemoney(player, 2, "=", 0)
				sendmsg(player, 6, "当前元宝数量为："..money(player, 2))
				return
			end
			if tonumber(data[2]) > 100 or tonumber(data[2]) < 1 then
				sendmsg(player, 9, "货币id错误")
				return
			end
			if index3 == 1 then
				changemoney(player, tonumber(data[2]), "=", tonumber(data[3]))
				sendmsg(player, 6, "货币数量修改为："..tonumber(data[3]))
				return
			elseif index3 == 2 then
				sendmsg(player, 6, "当前货币数量为："..money(player, tonumber(data[2])))
				return
			end
		elseif index2 == 2 then   --等级
			if tonumber(data[2]) < 1 then
				sendmsg(player, 9, "请输入正确的数字！")
				return
			end
			changelevel(player, "=", tonumber(data[2]))
			sendmsg(player, 6, "当前角色等级为："..level(player))
		elseif index2 == 3 then   --技能
			if tonumber(data[2]) == 0 then
				sendmsg(player, 9, "请输入技能id！")
				return
			end
			if index3 == 1 then
				if getmagicinfo(player, tonumber(data[2]), 6) == 1 then
					chgskilllv(player, tonumber(data[2]), 1)
				else
					addskill(player, tonumber(data[2]), 1)
				end
				sendmsg(player, 9, "技能已添加！")
				return
			elseif index3 == 2 then
				delskill(player, tonumber(data[2]))
				sendmsg(player, 9, "技能已删除！")
				return
			end
		elseif index2 == 4 then   --buff
			if tonumber(data[2]) == 0 then
				sendmsg(player, 9, "请输入buffid！")
				return
			end
			if index3 == 1 then
				if hasbuff(player, tonumber(data[2])) then
					delbuff(player, tonumber(data[2]))
				end
				local attrtable = {}  --attrtable = {[1]=10}
				if addbuff(player, tonumber(data[2]), tonumber(data[3]), 1, player, attrtable) then
					sendmsg(player, 6, "addbuff-true")
				else
					sendmsg(player, 6, "addbuff-false")
				end
				return
			elseif index3 == 2 then
				if hasbuff(player, tonumber(data[2])) then
					delbuff(player, tonumber(data[2]))
					sendmsg(player, 9, "buff已删除！")
					return
				end
			end
		elseif index2 == 5 then   --属性
			if tonumber(data[2]) == 0 then
				sendmsg(player, 9, "请输入属性id！")
				return
			end
			if tonumber(data[2]) <= 4 then
				changeabil(player, tonumber(data[2]), "=", tonumber(data[3]))
			end
			-- 角色生命属性当前值 增加100点
			setscriptabilvalue(player, tonumber(data[2]), "=", tonumber(data[3]))
		elseif index2 == 6 then   --转职
			settargetinfo(player, "GOODEVILID",tonumber(data[2]))
			if data[2] then
				sethumvar(player,VarCfg.U_Camp_Type,tonumber(data[2]))
                setrefdata(player, 1, tonumber(data[2]))
			end
			settargetinfo(player,"RELEVEL",tonumber(data[3]))
		elseif index2 == 7 then   --变性
			-- if tonumber(data[2]) == 0 then
			-- 	sendmsg(player, 9, "请输入职业等级！")
			-- 	return
			-- end
			changegender(player, tonumber(data[2]))
			sendmsg(player, 9, "性别已修改！")
		end
	elseif index1 == 2 then  --怪物
		if data[1] ~= "0" then
			mapid = data[1]
		end
		--local MAPTITLE = targetinfo(player, "MAPTITLE")
		if index2 == 1 then   --刷怪
			local x = targetinfo(player, "X")  
			local y = targetinfo(player, "Y")  
			mongenex(mapid, x, y, 2, ""..data[2], tonumber(data[3]), 0, 0, "@gmshuaguai")
		elseif index2 == 2 then   --刷怪
			local mon = "*"
			if data[2] ~= "0" then
				mon = data[2]
			end
			clearmapmon(mapid, "*", "*", "*", mon, tonumber(data[3]), 0)
		end
	elseif index1 == 3 then  --道具
		if index2 == 1 then   --添加删除道具
			local playname = data[1]
			if playname ~= "0" then
				player = uniqueid(playname)
			end
			if data[2] == "0" or data[3] == "0" then
				sendmsg(player, 9, "请输入道具名和数量！")
				return
			end 
			if index3 == 1 then
				local objinfo = giveitem(player, data[2].."#"..data[3])
				-- dump(objinfo)
				-- for i=1,#objinfo do
				-- 	local itemobj = objinfo[i]
				-- 	changeitemaddvalue(actor, itemobj, 1, "=", 222)
				-- end
			elseif index3 == 2 then
				local itemnum = bagitemcount(player,data[2])
				if itemnum < tonumber(data[3]) then
					sendmsg(player, 9, "背包物品数量不足！")
					return
				end
				takeitem(player,data[2].."#"..data[3],0)
			end
		elseif index2 == 2 then   --清理背包
			local playname = data[1]
			if playname ~= "0" then
				player = uniqueid(playname)
			end
			local itemlist = getbagitems(player)
			for k,v in pairs(itemlist) do
				delitembymakeindex(player, v)
			end
		elseif index2 == 3 then   --地图上生成道具
			if data[1] ~= "0" then
				mapid = data[1]
			end
			if data[2] == "0" or data[3] == "0" then
				sendmsg(player, 9, "请输入道具名和数量！")
				return
			end 
			local x = targetinfo(player, "X")  
			local y = targetinfo(player, "Y")  
			throwitem(mapid, x, y, 5, data[2], data[3].."|10", 1, 0)
		end
	elseif index1 == 4 then  --地图
		if data[1] ~= "0" then
			mapid = data[1]
		end
		if index2 == 1 then  --传送
			if data[2] ~= "0" then
				if not data[3] then
					data[3] = data[2]
				end
				if not data[4] then
					data[4] = 3
				end
				mapmove(player, mapid, tonumber(data[2]), tonumber(data[3]), tonumber(data[4]))
			else
				map(player, mapid)
			end
		elseif index2 == 2 then  --清理地图掉落
			local x,y = "*","*"
			local range,itemname = "*","*"
			if data[2] ~= "0" then 
				range,x,y = tonumber(data[2]),targetinfo(player, "X"),targetinfo(player, "Y")  
			end
			if data[3] ~= "0" then 
				itemname = data[3]
			end
			clearitemmap(actor, mapid,x,y, range, itemname)
		end
	elseif index1 == 5 then  --系统
		if index2 == 1 then
			local playname = data[1]
			if playname ~= "0" then
				player = uniqueid(playname)
			end
			local first_byte = string.sub(data[2], 1, 1)
			if first_byte ~= "N" and first_byte ~= "U" then
				sendmsg(player, 6, "请输入正确的变量格式")
				return
			end
			if index3 == 1 then
				sethumvar(player, data[2], tonumber(data[3]))
				sendmsg(player, 6, data[2].."："..gethumvar(player,data[2]))
				return
			elseif index3 == 2 then
				sendmsg(player, 6, data[2].."："..gethumvar(player,data[2]))
			end
		elseif index2 == 2 then
			local playname = data[1]
			if playname ~= "0" then
				player = uniqueid(playname)
			end
			local first_byte = string.sub(data[2], 1, 1)
			if first_byte ~= "S" and first_byte ~= "T" then
				sendmsg(player, 6, "请输入正确的变量格式")
				return
			end
			if index3 == 1 then
				sethumvar(player, data[2], tonumber(data[3]))
				sendmsg(player, 6, data[2].."："..gethumvar(player,data[2]))
				return
			elseif index3 == 2 then
				sendmsg(player, 6, data[2].."："..gethumvar(player,data[2]))
			end
		elseif index2 == 3 then
			local first_byte = string.sub(data[1], 1, 1)
			if first_byte ~= "G" then
				sendmsg(player, 6, "请输入正确的变量格式")
				return
			end
			if index3 == 1 then
				sethumvar(0, data[1], tonumber(data[2]))
				sendmsg(player, 6, data[1].."："..gethumvar(0,data[1]))
				return
			elseif index3 == 2 then
				sendmsg(player, 6, data[1].."："..gethumvar(0,data[1]))
			end
		elseif index2 == 4 then
			local first_byte = string.sub(data[1], 1, 1)
			if first_byte ~= "A" then
				sendmsg(player, 6, "请输入正确的变量格式")
				return
			end
			if index3 == 1 then
				sethumvar(0, data[1], data[2])
				sendmsg(player, 6, data[1].."："..gethumvar(0,data[1]))
				return
			elseif index3 == 2 then
				sendmsg(player, 6, data[1].."："..gethumvar(0,data[1]))
			end
		elseif index2 == 5 then
			local playname = data[1]
			if playname ~= "0" then
				player = uniqueid(playname)
			end
			if not checkstate(player,2) then 
				sendmsg(actor, 9, "玩家不在线")
				return
			end
			if tostring(player) == "0" then 
				sendmsg(actor, 9, "玩家不在线")
				return
			end
			local TaskProgress_data = gethumvar(actor,VarCfg.T_TaskProgress_data) or "" 
    		if TaskProgress_data ~= "" then
    		    TaskProgress_data = json2tbl(TaskProgress_data)
    		else
    		    TaskProgress_data = {   --默认接取第一个任务
    		        ["100001"] = {state = _taskState.ongoing,count = 0}
    		    } 
    		end
			local taskid = tonumber(data[2]) or 0
			-- print("taskid="..taskid)
			if TaskProgress_data[""..taskid] then
				local neednum = Task_cfg[taskid]['task_progress'] or 1
				TaskProgress_data[""..taskid]['count'] = neednum
				TaskProgress_data[""..taskid]['state'] = 2
				sethumvar(actor,VarCfg.T_TaskProgress_data,tbl2json(TaskProgress_data))  -- 当前已接取任务列表
        		Message.sendmsgEx(actor, "MainMission","UpdataTask",{param1 = TaskProgress_data})   -- 更新客户端任务进度变量
			end
		end
	end
end

--登录更新属性
GameEvent.add(EventCfg.onLogin, function (actor)
    -- setstate(actor, 2, 0)
end, gmbox)

Message.RegisterNetMsg(ssrNetMsgCfg.gmbox, gmbox)
return gmbox