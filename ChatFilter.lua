------------------------------------------------------
-- #������ܣ����ݹؼ��ֽ����������ɸѡ
-- #���˵������OutputMessage�ӿڽ���������Ϣģ�⣬����
-- 			NPC����Ƶ��������������������ʹ��ǰ��Ҫ
-- 			�½�һ������ҳ���ҹ�ѡNPC����Ƶ����֮���
-- 			���������������õĹؼ��ֽ������������
-- #����˵�������йؼ������Ի��ϵ���й��ˣ�ͬһ��������
-- 			��ϵ���й��ˣ����ű�ʾ��ͬһ�����ڷ�С�顣
-- #������ߣ�crazy
-- #�������ڣ�2014-01-29
-- #����汾��v1.0.1
------------------------------------------------------

ChatFilter = {
	bEnabled = true,				-- ����ܿ���
	tKeyWords = {					-- ���˹ؼ���
		{szName = "��ս", bOn = false},
		{szName = "(10|25)&(ս��|ZB)", bOn = true},
		{szName = "(10|25)&(Ѫս|XZ)", bOn = true},
		{szName = "(10|25)&(������|DMG)", bOn = true},
	},
	szDataPath = "\\Interface\\ChatFilter\\config.dat",
}

RegisterCustomData("ChatFilter.bEnabled")

local tChannel = {"MSG_WORLD", "MSG_CAMP", "MSG_MAP", "MSG_SCHOOL","MSG_FRIEND"}

local function CheckKeyWord(szMsg)
	--ȡ�����ڲ������ڵ�����
	local function fnBracket(szText)
		while string.find(szText, "%b()") do
			szText = string.sub(szText:match("%b()"), 2, -2)
		end
		return szText
	end
	--����ƥ�����
	local function fnProcess(szMsg, szKey)
		local szOper, bAnd = "|", false
		if string.find(szKey, "&") then
			szOper, bAnd = "&", true
		end
		local tKey = SplitString(szKey, szOper)
		for _, v in ipairs(tKey) do
			v = tonumber(v) or v 	--����ת����������ת��������Ϊ�ַ�����
			if type(v) == "string" then		--�ַ�ƥ��
				if StringFindW(szMsg, v) and szOper == "|" then
					return true
				elseif not StringFindW(szMsg, v) and szOper == "&" then
					return false
				end
			elseif type(v) == "number" then		--����׼ȷƥ��
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
				table.insert(tRet, tostring(fnProcess(szMsg, szKey)))	--�洢ƥ����
			else
				tKey = SplitString(szKey, "&")
				for _, s in ipairs(tKey) do
					szRet = fnBracket(s)
					table.insert(tRet, tostring(fnProcess(szMsg, szRet)))
				end
			end
			nTol, nNum = #tRet, 0
			if nTol > 0 then
				table.foreach(tRet, function(k, v) nNum = (v == "true") and (nNum + 1) or nNum end)		--��ƥ����ȷ�Ľ��м���
				bRet = (nTol == nNum) and true or false		--����ƥ��ȫ����ʱ��ͨ��
			end
			if bRet then
				break		--һ����ͨ����������ѭ��
			end
		end
	end
	return bRet
end

function ChatFilter.OnTalk(szMsg, nFont, bRich, r, g, b)
	local szText = GetPureText(szMsg)
	local nStart, nEnd = StringFindW(szText, g_tStrings.STR_TALK_HEAD_SAY1)
	szText = string.sub(szText, nEnd + 1, -1)
	szText = string.gsub(szText, "%l+", function(s) return string.upper(s) end)	--�������е�Сд��ĸȫת��д
	if CheckKeyWord(szText) then
		OutputMessage("MSG_NPC_PARTY", szMsg, true)
	end
end

function ChatFilter.GetMenu()
	local menu = {szOption = "�������"}
	local m_1 = {
		szOption = "��������",
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

	local m_2 = {szOption = "���˹���"}
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
				szOption = "���޸ġ�",
				fnAction = function()
					GetUserInput("�޸Ĺ��˹�����ĸ�����д��", function(szText)
						v.szName = szText
						OutputMessage("MSG_SYS", string.format("����%s���޸ĳɹ���\n", szText))
					end, nil, nil, nil,v.szName, nil)
				end
			},
			{
				szOption = "��ɾ����",
				fnAction = function()
					local szName = ChatFilter.tKeyWords[k].szName
					table.remove(ChatFilter.tKeyWords, k)
					OutputMessage("MSG_SYS", string.format("����%s��ɾ���ɹ���\n", szName))
				end
			}
		}
		table.insert(m_2, m)
	end
	table.insert(menu, m_2)
	table.insert(menu, {bDevide = true})

	local m_3 = {
		szOption = "�Զ���",
		fnAction = function()
			GetUserInput("��ӹ��˹�����ĸ�����д��", function(szText)
				table.insert(ChatFilter.tKeyWords, {szName = szText, bOn = true})
				OutputMessage("MSG_SYS", string.format("����%s����ӳɹ���\n", szText))
			end, nil, nil, nil, nil, nil)
		end
	}
	table.insert(menu, m_3)

	return menu
end

--��ʼ�������
do
	if ChatFilter.bEnabled then
		RegisterMsgMonitor(ChatFilter.OnTalk, tChannel)
	end
end

--��������
do
	for k, v in ipairs({"GAME_EXIT", "PLAYER_EXIT_GAME"}) do
		RegisterEvent(v, function()
			SaveLUAData(ChatFilter.szDataPath, ChatFilter.tKeyWords)
		end)
	end
end

RegisterEvent("LOGIN_GAME", function()
	--��ȡ����
	if IsFileExist(ChatFilter.szDataPath) then
		ChatFilter.tKeyWords = LoadLUAData(ChatFilter.szDataPath)
	end
	--����ͷ��˵�
	local tMenu = {
		function()
			return { ChatFilter.GetMenu() }
		end,
	}
	Player_AppendAddonMenu(tMenu)
end)
