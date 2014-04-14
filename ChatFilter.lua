------------------------------------------------------
-- #插件功能：根据关键字进行聊天过滤筛选
-- #插件说明：用OutputMessage接口进行聊天信息模拟，并用
-- 			NPC队聊频道进行聊天输出。插件在使用前需要
-- 			新建一个聊天页并且勾选NPC队聊频道，之后插
-- 			件跟根据事先设置的关键字进行聊天输出。
-- #过滤说明：所有关键字组以或关系进行过滤，同一组中以与
-- 			关系进行过滤，括号表示在同一组内在分小组。
-- #插件作者：crazy
-- #创建日期：2014-01-29
-- #插件版本：v1.0.1
------------------------------------------------------

ChatFilter = {
	bEnabled = true,				-- 插件总开关
	tKeyWords = {					-- 过滤关键字
		{szName = "大战", bOn = false},
		{szName = "(10|25)&(战宝|ZB)", bOn = true},
		{szName = "(10|25)&(血战|XZ)", bOn = true},
		{szName = "(10|25)&(大明宫|DMG)", bOn = true},
	},
	szDataPath = "\\Interface\\ChatFilter\\config.dat",
}

RegisterCustomData("ChatFilter.bEnabled")

local tChannel = {"MSG_WORLD", "MSG_CAMP", "MSG_MAP", "MSG_SCHOOL","MSG_FRIEND"}

local function CheckKeyWord(szMsg)
	--取得最内层括号内的内容
	local function fnBracket(szText)
		while string.find(szText, "%b()") do
			szText = string.sub(szText:match("%b()"), 2, -2)
		end
		return szText
	end
	--处理匹配规则
	local function fnProcess(szMsg, szKey)
		local szOper, bAnd = "|", false
		if string.find(szKey, "&") then
			szOper, bAnd = "&", true
		end
		local tKey = SplitString(szKey, szOper)
		for _, v in ipairs(tKey) do
			v = tonumber(v) or v 	--若能转换成数字则转换，否则为字符不变
			if type(v) == "string" then		--字符匹配
				if StringFindW(szMsg, v) and szOper == "|" then
					return true
				elseif not StringFindW(szMsg, v) and szOper == "&" then
					return false
				end
			elseif type(v) == "number" then		--数字准确匹配
				for s in string.gmatch(szMsg, "%d+") do
					if (tonumber(s) == v) and szOper == "|" then
						return true
					elseif (tonumber(s) ~= v) and szOper == "&" then
						return false
					end
				end
			end
		end
		return bAnd
	end
	local szRet, bRet, tRet = "", nil, nil
	local szKey, nTol, nNum, tKey = "", 0, 0, nil
	for k, v in ipairs(ChatFilter.tKeyWords) do
		if v.bOn then
			tRet, szKey = {}, v.szName
			if not string.find(szKey, "%b()") then
				table.insert(tRet, tostring(fnProcess(szMsg, szKey)))	--存储匹配结果
			else
				tKey = SplitString(szKey, "&")
				for _, s in ipairs(tKey) do
					szRet = fnBracket(s)
					table.insert(tRet, tostring(fnProcess(szMsg, szRet)))
				end
			end
			nTol, nNum = #tRet, 0
			if nTol > 0 then
				table.foreach(tRet, function(k, v) nNum = (v == "true") and (nNum + 1) or nNum end)		--对匹配正确的进行计数
				bRet = (nTol == nNum) and true or false		--所有匹配全符合时则通过
			end
			if bRet then
				break		--一旦有通过的则跳出循环
			end
		end
	end
	return bRet
end

function ChatFilter.OnTalk(szMsg, nFont, bRich, r, g, b)
	local szText = GetPureText(szMsg)
	local nStart, nEnd = StringFindW(szText, g_tStrings.STR_TALK_HEAD_SAY1)
	szText = string.sub(szText, nEnd + 1, -1)
	szText = string.gsub(szText, "%l+", function(s) return string.upper(s) end)	--将喊话中的小写字母全转大写
	if CheckKeyWord(szText) then
		OutputMessage("MSG_NPC_PARTY", szMsg, true)
	end
end

function ChatFilter.GetMenu()
	local menu = {szOption = "聊天过滤"}
	local m_1 = {
		szOption = "开启过滤",
		bCheck = true,
		bChecked = ChatFilter.bEnabled,
		fnAction = function()
			ChatFilter.bEnabled = not ChatFilter.bEnabled
			if ChatFilter.bEnabled then
				RegisterMsgMonitor(ChatFilter.OnTalk, tChannel)
			else
				UnRegisterMsgMonitor(ChatFilter.OnTalk, tChannel)
			end
		end
	}
	table.insert(menu, m_1)
	table.insert(menu, {bDevide = true})

	local m_2 = {szOption = "过滤规则"}
	for k, v in ipairs(ChatFilter.tKeyWords) do
		local m = {
			szOption = v.szName,
			bCheck = true,
			bChecked = v.bOn,
			fnDisable = function()
				return not ChatFilter.bEnabled
			end,
			fnAction = function()
				v.bOn = not v.bOn
			end,
			{
				szOption = "◇修改◇",
				fnAction = function()
					GetUserInput("修改过滤规则（字母必须大写）", function(szText)
						v.szName = szText
						OutputMessage("MSG_SYS", string.format("规则【%s】修改成功！\n", szText))
					end, nil, nil, nil,v.szName, nil)
				end
			},
			{
				szOption = "◇删除◇",
				fnAction = function()
					local szName = ChatFilter.tKeyWords[k].szName
					table.remove(ChatFilter.tKeyWords, k)
					OutputMessage("MSG_SYS", string.format("规则【%s】删除成功！\n", szName))
				end
			}
		}
		table.insert(m_2, m)
	end
	table.insert(menu, m_2)
	table.insert(menu, {bDevide = true})

	local m_3 = {
		szOption = "自定义",
		fnAction = function()
			GetUserInput("添加过滤规则（字母必须大写）", function(szText)
				table.insert(ChatFilter.tKeyWords, {szName = szText, bOn = true})
				OutputMessage("MSG_SYS", string.format("规则【%s】添加成功！\n", szText))
			end, nil, nil, nil, nil, nil)
		end
	}
	table.insert(menu, m_3)

	return menu
end

--初始化监控器
do
	if ChatFilter.bEnabled then
		RegisterMsgMonitor(ChatFilter.OnTalk, tChannel)
	end
end

--保存配置
do
	for k, v in ipairs({"GAME_EXIT", "PLAYER_EXIT_GAME"}) do
		RegisterEvent(v, function()
			SaveLUAData(ChatFilter.szDataPath, ChatFilter.tKeyWords)
		end)
	end
end

RegisterEvent("LOGIN_GAME", function()
	--读取配置
	if IsFileExist(ChatFilter.szDataPath) then
		ChatFilter.tKeyWords = LoadLUAData(ChatFilter.szDataPath)
	end
	--生成头像菜单
	local tMenu = {
		function()
			return { ChatFilter.GetMenu() }
		end,
	}
	Player_AppendAddonMenu(tMenu)
end)
