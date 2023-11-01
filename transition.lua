local extension = Package("transition")
extension.extensionName = "jsrg"

Fk:loadTranslationTable{
  ["transition"] = "江山如故·转",
}

--local guojia = General(extension, "js__guojia", "wei", 3)
Fk:loadTranslationTable{
  ["js__guojia"] = "郭嘉",
  ["qingzi"] = "轻辎",
  [":qingzi"] = "准备阶段，你可以弃置任意名其他角色装备区内的各一张牌，然后令这些角色获得〖神速〗直到你的下回合开始。",
  ["dingce"] = "定策",
  [":dingce"] = "当你受到伤害后，你可以依次弃置你和伤害来源各一张手牌，若这两张牌颜色相同，视为你使用一张【洞烛先机】。",
  ["zhenfeng"] = "针锋",
  [":zhenfeng"] = "出牌阶段每种类别的牌限一次，你可以视为使用一张存活角色技能描述中包含的牌名（无次数距离限制且须为基本牌或普通锦囊牌），"..
  "当此牌对该角色生效后，你对其造成1点伤害。",
}

--local zhangfei = General(extension, "js__zhangfei", "shu", 5)
Fk:loadTranslationTable{
  ["js__zhangfei"] = "张飞",
  ["baohe"] = "暴喝",
  [":baohe"] = "一名角色出牌阶段结束时，你可以弃置两张牌，然后视为你对攻击范围内包含其的所有角色使用一张无距离限制的【杀】，"..
  "当其中一名目标响应此【杀】后，此【杀】对剩余目标造成的伤害+1。",
  ["xushiz"] = "虚势",
  [":xushiz"] = "出牌阶段限一次，你可以交给任意名角色各一张牌，然后你获得两倍数量的【影】。",
}

local machao = General(extension, "js__machao", "qun", 4)
local zhuiming = fk.CreateTriggerSkill{
  name = "zhuiming",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.trueName == "slash" and #AimGroup:getAllTargets(data.tos) == 1 and
      not player.room:getPlayerById(AimGroup:getAllTargets(data.tos)[1]):isNude()
  end,
  on_cost = function(self, event, target, player, data)
    self.cost_data = player.room:askForChoice(player, {"red", "black", "Cancel"}, self.name,
      "#zhuiming-invoke::"..AimGroup:getAllTargets(data.tos)[1])
    return self.cost_data ~= "Cancel"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(AimGroup:getAllTargets(data.tos)[1])
    room:doIndicate(player.id, {to.id})
    room:askForDiscard(to, 0, 999, true, self.name, true, nil, "#zhuiming-discard:"..player.id.."::"..self.cost_data, false)
    if player.dead or to.dead or to:isNude() then return end
    local id = room:askForCardChosen(player, to, "he", self.name)
    to:showCards({id})
    if Fk:getCardById(id):getColorString() == self.cost_data then
      player:addCardUseHistory("slash", -1)
      data.disresponsiveList = data.disresponsiveList or {}
      table.insert(data.disresponsiveList, to.id)
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end
  end,
}
machao:addSkill(zhuiming)
machao:addSkill("mashu")
Fk:loadTranslationTable{
  ["js__machao"] = "马超",
  ["zhuiming"] = "追命",
  [":zhuiming"] = "当你使用【杀】指定唯一目标后，你可以声明一种颜色并令目标弃置任意张牌，然后你展示目标一张牌，若此牌颜色与你声明的颜色相同，"..
  "则此【杀】不计入次数限制、不可被响应且伤害+1。",
  ["#zhuiming-invoke"] = "追命：你可以对 %dest 发动“追命”声明一种颜色",
  ["#zhuiming-discard"] = "追命：%src 声明%arg，你可以弃置任意张牌",
}

Fk:loadTranslationTable{
  ["lougui"] = "娄圭",
  ["shacheng"] = "沙城",
  [":shacheng"] = "游戏开始时，你将牌堆顶的两张牌置于你的武将牌上；当一名角色使用一张【杀】结算后，你可以移去武将牌上的一张牌，"..
  "令其中一名目标角色摸X张牌（X为该目标本回合失去的牌数且至多为5）。",
  ["ninghan"] = "凝寒",
  [":ninghan"] = "锁定技，所有角色手牌中的♣【杀】均视为冰【杀】；当一名角色受到冰冻伤害后，你可以将造成此伤害的牌置于武将牌上。",
}

Fk:loadTranslationTable{
  ["js__zhangren"] = "张任",
  ["funi"] = "伏匿",
  [":funi"] = "锁定技，你的攻击范围始终为0；每轮开始时，你令任意名角色获得共计X张【影】 （X为存活角色数的一半，向上取整）；"..
  "当一张【影】进入弃牌堆时，你本回合使用牌无距离限制且不能被响应。",
  ["chuanxin"] = "穿心",
  [":chuanxin"] = "一名角色结束阶段，你可以将一张牌当伤害值+X的【杀】使用（X为目标角色本回合回复过的体力值）。",
}

Fk:loadTranslationTable{
  ["js__huangzhong"] = "黄忠",
  ["cuifeng"] = "摧锋",
  [":cuifeng"] = "限定技，出牌阶段，你可以视为使用一张唯一目标的伤害类牌（无距离限制），若此牌未造成伤害或造成的伤害数大于1，此回合结束时重置〖摧锋〗。",
  ["dengnan"] = "登难",
  [":dengnan"] = "限定技，出牌阶段，你可以视为使用一张非伤害类普通锦囊牌，此回合结束时，若此牌的目标均于此回合受到过伤害，你重置〖登难〗。",
}

Fk:loadTranslationTable{
  ["xiahourong"] = "夏侯荣",
  ["fenjian"] = "奋剑",
  [":fenjian"] = "每回合各限一次，当你需要对其他角色使用【决斗】或【桃】时，你可以令你受到的伤害+1直到本回合结束，然后你视为使用之。",
}

Fk:loadTranslationTable{
  ["js__sunshangxiang"] = "孙尚香",
  ["guiji"] = "闺忌",
  [":guiji"] = "每回合限一次，出牌阶段，你可以与一名手牌数小于你的男性角色交换手牌，然后其下个出牌阶段结束时，你可以与其交换手牌。",
  ["jiaohao"] = "骄豪",
  [":jiaohao"] = "其他角色出牌阶段限一次，其可以将手牌中的一张装备牌置于你的装备区中；准备阶段，你获得X张【影】（X为你空置的装备栏数的一半且向上取整）。",
}

Fk:loadTranslationTable{
  ["js__pangtong"] = "庞统",
  ["js__manjuan"] = "漫卷",
  [":js__manjuan"] = "若你没有手牌，你可以如手牌般使用或打出弃牌堆中本回合置入的牌（每种点数每回合限一次）。",
  ["yangming"] = "养名",
  [":yangming"] = "出牌阶段限一次，你可以与一名角色拼点：若其没赢，你可以与其重复此流程；若其赢，其摸等同于其本阶段拼点没赢次数的牌然后你回复1点体力。",
}

Fk:loadTranslationTable{
  ["js__hansui"] = "韩遂",
  ["js__niluan"] = "逆乱",
  [":js__niluan"] = "准备阶段，你可以选择一项：1.弃置一张牌，对一名未对你造成过伤害的角色造成1点伤害；2.令一名对你造成过伤害的角色摸两张牌。",
  ["huchou"] = "互雠",
  [":huchou"] = "锁定技，上一名对你使用伤害类牌的其他角色受到你造成的伤害时，此伤害+1。",
  ["jiemeng"] = "皆盟",
  [":jiemeng"] = "主公技，锁定技，所有群势力角色计算与其他角色的距离-X（X为群势力角色数）。",
}

local zhangchu = General(extension, "js__zhangchu", "qun", 3, 3, General.Female)
local huozhong = fk.CreateActiveSkill{
  name = "huozhong",
  anim_type = "drawcard",
  target_num = 0,
  card_num = 1,
  prompt = "#huozhong-invoke",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0 and not player:hasDelayedTrick("supply_shortage")
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type ~= Card.TypeTrick and Fk:getCardById(to_select).color == Card.Black
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local card = Fk:cloneCard("supply_shortage")
    card:addSubcards(effect.cards)
    player:addVirtualEquip(card)
    room:moveCardTo(card, Card.PlayerJudge, player, fk.ReasonJustMove, self.name)
    if not player.dead then
      player:drawCards(2, self.name)
    end
  end,
}
local huozhong_trigger = fk.CreateTriggerSkill{
  name = "#huozhong_trigger",

  refresh_events = {fk.GameStart, fk.EventAcquireSkill, fk.EventLoseSkill, fk.Deathed},
  can_refresh = function(self, event, target, player, data)
    if event == fk.GameStart then
      return player:hasSkill(self.name, true)
    elseif event == fk.EventAcquireSkill or event == fk.EventLoseSkill then
      return data == self and not table.find(player.room:getOtherPlayers(player), function(p) return p:hasSkill("huozhong", true) end)
    else
      return target == player and player:hasSkill(self.name, true, true) and
        not table.find(player.room:getOtherPlayers(player), function(p) return p:hasSkill("huozhong", true) end)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart or event == fk.EventAcquireSkill then
      if player:hasSkill(self.name, true) then
        for _, p in ipairs(room:getOtherPlayers(player)) do
          room:handleAddLoseSkills(p, "huozhong&", nil, false, true)
        end
      end
    elseif event == fk.EventLoseSkill or event == fk.Deathed then
      for _, p in ipairs(room:getOtherPlayers(player)) do
        room:handleAddLoseSkills(p, "-huozhong&", nil, false, true)
      end
    end
  end,
}
local huozhong_active = fk.CreateActiveSkill{
  name = "huozhong&",
  anim_type = "support",
  target_num = 0,
  card_num = 1,
  prompt = "#huozhong&-invoke",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0 and not player:hasDelayedTrick("supply_shortage")
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type ~= Card.TypeTrick and Fk:getCardById(to_select).color == Card.Black
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local card = Fk:cloneCard("supply_shortage")
    card:addSubcards(effect.cards)
    player:addVirtualEquip(card)
    room:moveCardTo(card, Card.PlayerJudge, player, fk.ReasonJustMove, self.name)
    local target
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p:hasSkill("huozhong", true) then
        target = p
        break
      end
    end
    if not target then return end
    target:broadcastSkillInvoke("huozhong")
    room:notifySkillInvoked(target, "huozhong", "drawcard")
    room:doIndicate(player.id, {target.id})
    target:drawCards(2, self.name)
  end,
}
local js__rihui = fk.CreateTriggerSkill{
  name = "js__rihui",
  anim_type = "support",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and data.card.trueName == "slash" and not data.chain and
      table.find(player.room:getOtherPlayers(player), function(p) return #p:getCardIds("j") > 0 end)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#js__rihui-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if #p:getCardIds("j") > 0 and not p.dead then
        room:doIndicate(player.id, {p.id})
        p:drawCards(1, self.name)
      end
    end
  end,
}
local js__rihui_trigger = fk.CreateTriggerSkill{
  name = "#js__rihui_trigger",
  mute = true,
  main_skill = js__rihui,
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill("js__rihui") and data.card and data.card.trueName == "slash" then
      local to = player.room:getPlayerById(data.to)
      return to:getMark("js__rihui-phase") == 0 and #to:getCardIds("j") == 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:addCardUseHistory(data.card.trueName, -1)
    room:addPlayerMark(room:getPlayerById(data.to), "js__rihui-phase", 1)
  end,
}
Fk:addSkill(huozhong_active)
huozhong:addRelatedSkill(huozhong_trigger)
js__rihui:addRelatedSkill(js__rihui_trigger)
zhangchu:addSkill(huozhong)
zhangchu:addSkill(js__rihui)
Fk:loadTranslationTable{
  ["js__zhangchu"] = "张楚",
  ["huozhong"] = "惑众",
  [":huozhong"] = "所有角色出牌阶段限一次，该角色可以将一张黑色非锦囊牌当【兵粮寸断】置于其判定区，然后令你摸两张牌。",
  ["js__rihui"] = "日彗",
  [":js__rihui"] = "当你使用【杀】对目标造成伤害后，你可以令判定区内有牌的其他角色各摸一张牌；你于出牌阶段对每名判定区内没有牌的角色"..
  "使用的首张【杀】无次数限制。",
  ["huozhong&"] = "惑众",
  [":huozhong&"] = "出牌阶段限一次，你可以将一张黑色非锦囊牌当【兵粮寸断】置于判定区，令张楚摸两张牌。",
  ["#huozhong-invoke"] = "惑众：你可以将一张黑色非锦囊牌当【兵粮寸断】置于判定区，摸两张牌",
  ["#huozhong&-invoke"] = "惑众：你可以将一张黑色非锦囊牌当【兵粮寸断】置于判定区，令张楚摸两张牌",
  ["#js__rihui-invoke"] = "日彗：你可以令判定区内有牌的其他角色各摸一张牌",
}

Fk:loadTranslationTable{
  ["js__xiahouen"] = "夏侯恩",
  ["hujian"] = "护剑",
  [":hujian"] = "游戏开始时，你从游戏外获得一张【赤血青锋】；一名角色回合结束时，此回合最后一名使用或打出过的牌的角色可以获得弃牌堆中的【赤血青锋】。",
  ["shili"] = "恃力",
  [":shili"] = "出牌阶段限一次，你可以将一张手牌中的装备牌当【决斗】使用。",
}

Fk:loadTranslationTable{
  ["js__fanjiangzhangda"] = "范疆张达",
  ["fushan"] = "负山",
  [":fushan"] = "出牌阶段开始时，所有其他角色依次可以交给你一张牌并令你本阶段使用【杀】的次数上限+1，此阶段结束时，若你使用【杀】的次数未达上限"..
  "且本阶段以此法交给你牌的角色均存活，你失去2点体力，否则你将手牌摸至体力上限。",
}

return extension
