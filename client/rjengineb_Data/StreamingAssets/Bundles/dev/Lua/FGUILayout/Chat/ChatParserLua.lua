
ChatParserLua = {}

ChatParserLua.ChatConfig={
	ITEM_UBB = "itm",
	EQUIP_UBB = "eqp",
	ITEM_UBB_DISPLAY = "<a href='%s'>[color=%s][%s][/color]</a>",   --参数要和聊天内容对应的参数一致，用ITEM_DATA_SPLIT分隔，例[itm=1&&&#000000&&&道具名]
	ITEM_DATA_SPLIT = "&&&",
	PATH_RES_EMOJI = "public/",
}

function ChatParserLua.GetItemMsgParam(id)
	local name = ""
	local color = SL:GetMetaValue("ITEM_NAME_COLOR", id)
	name = SL:GetMetaValue("ITEM_NAME", id)
	if color == "undefined" then
		color= "#FFFFFF"
	end
	return id,color,name
end

function ChatParserLua.RegisterChatParser()

	local EmojiPathFormat =  string.format("ui://%s{0}",ChatParserLua.ChatConfig.PATH_RES_EMOJI)
	SL:RegisterChatParser(function(tagName, attr)
		if tagName == ChatParserLua.ChatConfig.ITEM_UBB then
			local slices = string.split(attr, ChatParserLua.ChatConfig.ITEM_DATA_SPLIT)
			local id,color,name =ChatParserLua.GetItemMsgParam(tonumber(slices[1]))
			return string.format(ChatParserLua.ChatConfig.ITEM_UBB_DISPLAY,string.format("%s%s%s",ChatParserLua.ChatConfig.ITEM_UBB,ChatParserLua.ChatConfig.ITEM_DATA_SPLIT,id),color,name)
		elseif tagName == ChatParserLua.ChatConfig.EQUIP_UBB then
			--装备目前服务器只支持单发，在chatPanel中处理
		end
		return ""
	end,EmojiPathFormat,ChatParserLua.ChatConfig.ITEM_UBB,ChatParserLua.ChatConfig.EQUIP_UBB,ChatParserLua.ChatConfig.ITEM_UBB_DISPLAY,ChatParserLua.ChatConfig.ITEM_DATA_SPLIT)
end

function ChatParserLua.main()
	ChatParserLua.RegisterChatParser()
end