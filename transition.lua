local extension = Package("transition")
extension.extensionName = "jsrg"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["transition"] = "江山如故·转",
}

local getShade = function (room, n)
  local ids = {}
  for _, id in ipairs(room.void) do
    if n <= 0 then break end
    if Fk:getCardById(id).name == "shade" then
      room:setCardMark(Fk:getCardById(id), MarkEnum.DestructIntoDiscard, 1)
      table.insert(ids, id)
      n = n - 1
    end
  end
  while n > 0 do
    local card = room:printCard("shade", Card.Spade, 1)
    room:setCardMark(card, MarkEnum.DestructIntoDiscard, 1)
    table.insert(ids, card.id)
    n = n - 1
  end
  return ids
end

local guojia = General(extension, "js__guojia", "wei", 3)
local qingzi = fk.CreateTriggerSkill{
  name = "qingzi",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and
      table.find(player.room:getOtherPlayers(player, false), function(p) return #p:getCardIds("e") > 0 end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player, false), function(p)
      return #p:getCardIds("e") > 0 end), Util.IdMapper)
    local tos = room:askForChoosePlayers(player, targets, 1, 999, "#qingzi-choose", self.name, true)
    if #tos > 0 then
      room:sortPlayersByAction(tos)
      self.cost_data = {tos = tos}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(self.cost_data.tos) do
      if player.dead then return end
      local p = room:getPlayerById(id)
      if not p.dead and #p:getCardIds("e") > 0 then
        local c = room:askForCardChosen(player, p, "e", self.name)
        room:throwCard(c, self.name, p, player)
        if not p:hasSkill("ol_ex__shensu", true) and not p.dead then
          room:addTableMark(player, "qingzi_target", p.id)
          room:handleAddLoseSkills(p, "ol_ex__shensu", nil, true, false)
        end
      end
    end
  end,

  refresh_events = {fk.TurnStart, fk.Death},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("qingzi_target") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(player:getMark("qingzi_target")) do
      local p = room:getPlayerById(id)
      room:handleAddLoseSkills(p, "-ol_ex__shensu", nil, true, false)
    end
    room:setPlayerMark(player, "qingzi_target", 0)
  end,
}
local dingce = fk.CreateTriggerSkill{
  name = "dingce",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(self) and not player:isKongcheng() and data.from
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#dingce-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id1 = room:askForDiscard(player, 1, 1, false, self.name, false, nil, "#dingce-discard1", true)[1]
    if not id1 then return end
    room:throwCard({id1}, self.name, player, player)
    if player.dead or data.from.dead or data.from:isKongcheng() then return end
    room:doIndicate(player.id, {data.from.id})
    local id2 = room:askForCardChosen(player, data.from, "h", self.name)
    room:throwCard({id2}, self.name, data.from, player)
    if player.dead or Fk:getCardById(id1).color ~= Fk:getCardById(id2).color or Fk:getCardById(id1).color == Card.NoColor then return end
    room:useVirtualCard("foresight", nil, player, {player}, self.name)
  end,
}
local zhenfeng = fk.CreateViewAsSkill{
  name = "zhenfeng",
  prompt = "#zhenfeng",
  interaction = function(self)
    local names = {}
    for _, card in pairs(Fk.all_card_types) do
      if ((card.type == Card.TypeBasic and Self:getMark("zhenfeng_basic-phase") == 0) or
        (card:isCommonTrick() and Self:getMark("zhenfeng_trick-phase") == 0)) and
        not card.is_derived and not table.contains(names, card.name) then
        local c = Fk:cloneCard(card.name)
        c.skillName = self.name
        if Self:canUse(c) and not Self:prohibitUse(c) then
          local p = Self
          repeat
            for _, s in ipairs(p.player_skills) do
              if s:isPlayerSkill(p) and s.visible then
                if string.find(Fk:translate(":"..s.name, "zh_CN"), "【"..Fk:translate(c.name, "zh_CN").."】") or
                  string.find(Fk:translate(":"..s.name, "zh_CN"), Fk:translate(c.name, "zh_CN")[1].."【"..Fk:translate(c.trueName, "zh_CN").."】") then
                  table.insertIfNeed(names, c.name)
                end
              end
            end
            p = p:getNextAlive()
          until p.id == Self.id
        end
      end
    end
    return UI.ComboBox {choices = names}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    use.extraUse = true
    player.room:setPlayerMark(player, "zhenfeng_"..use.card:getTypeString().."-phase", 1)
  end,
  enabled_at_play = function(self, player)
    return player:getMark("zhenfeng_basic-phase") == 0 or player:getMark("zhenfeng_trick-phase") == 0
  end,
}
local zhenfeng_targetmod = fk.CreateTargetModSkill{
  name = "#zhenfeng_targetmod",
  bypass_distances = function(self, player, skill, card)
    return card and table.contains(card.skillNames, "zhenfeng")
  end,
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, "zhenfeng")
  end,
}
local zhenfeng_trigger = fk.CreateTriggerSkill{
  name = "#zhenfeng_trigger",
  main_skill = zhenfeng,
  mute = true,
  events = {fk.CardEffectFinished},
  can_trigger = function(self, event, target, player, data)
    if player.id == data.from and table.contains(data.card.skillNames, "zhenfeng") and data.to then
      local to = player.room:getPlayerById(data.to)
      if to.dead then return end
      for _, s in ipairs(to.player_skills) do
        if s:isPlayerSkill(to) and s.visible then
          if string.find(Fk:translate(":"..s.name, "zh_CN"), "【"..Fk:translate(data.card.name, "zh_CN").."】") or
            string.find(Fk:translate(":"..s.name, "zh_CN"), Fk:translate(data.card.name, "zh_CN")[1].."【"..Fk:translate(data.card.trueName, "zh_CN").."】") then
            return true
          end
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("zhenfeng")
    player.room:notifySkillInvoked(player, "zhenfeng", "offensive")
    room:doIndicate(player.id, {data.to})
    room:damage{
      from = player,
      to = room:getPlayerById(data.to),
      damage = 1,
      skillName = "zhenfeng",
    }
  end,
}
zhenfeng:addRelatedSkill(zhenfeng_targetmod)
zhenfeng:addRelatedSkill(zhenfeng_trigger)
guojia:addSkill(qingzi)
guojia:addSkill(dingce)
guojia:addSkill(zhenfeng)
guojia:addRelatedSkill("ol_ex__shensu")
Fk:loadTranslationTable{
  ["js__guojia"] = "郭嘉",
  ["#js__guojia"] = "赤壁的先知",
  ["illustrator:js__guojia"] = "KayaK&DEEMO",
  ["qingzi"] = "轻辎",
  [":qingzi"] = "准备阶段，你可以弃置任意名其他角色装备区内的各一张牌，然后令这些角色获得〖神速〗直到你的下回合开始。",
  ["dingce"] = "定策",
  [":dingce"] = "当你受到伤害后，你可以依次弃置你和伤害来源各一张手牌，若这两张牌颜色相同，视为你使用一张【洞烛先机】。",
  ["zhenfeng"] = "针锋",
  [":zhenfeng"] = "出牌阶段每种类别的牌限一次，你可以视为使用一张存活角色技能描述中包含的牌（无次数距离限制且须为基本牌或普通锦囊牌），"..
  "当此牌对该角色生效后，你对其造成1点伤害。",
  ["#qingzi-choose"] = "轻辎：你可以弃置任意名其他角色各一张装备，这些角色直到你下回合开始获得〖神速〗",
  ["#dingce-invoke"] = "定策：你可以弃置你和伤害来源各一张手牌，若颜色相同，视为你使用【洞烛先机】",
  ["#dingce-discard1"] = "定策：弃置你的一张手牌",
  ["#zhenfeng"] = "针锋：你可以视为使用一种场上角色技能描述中包含的牌",
}

local zhangfei = General(extension, "js__zhangfei", "shu", 5)
local baohe = fk.CreateTriggerSkill{
  name = "baohe",
  mute = true,
  anim_type = "support",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.phase == Player.Play and #player:getCardIds("he") >1
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForDiscard(player, 2, 2, true, self.name, true, ".", "#baohe-discard::"..target.id, true)
    if #cards > 1 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    local targets = {}
    for _, p in ipairs(player.room:getOtherPlayers(target)) do
      if Fk:currentRoom():getPlayerById(p.id):inMyAttackRange(target) and p ~= player then
        table.insert(targets, p)
      end
    end
    room:useVirtualCard("slash", nil, player, targets, self.name, true)
  end,

  refresh_events = {fk.DamageCaused, fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.DamageCaused then
        return player:getMark("baohe_adddamage-phase") ~= 0 and data.card and table.contains(data.card.skillNames, "baohe")
      else
        if data.card.name == "jink" and data.toCard and data.toCard.trueName == "slash" and table.contains(data.toCard.skillNames, "baohe") then
          return data.responseToEvent.from == player.id
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DamageCaused then
      local num = player:getMark("baohe_adddamage-phase")
      data.damage = data.damage + num
    else
      room:addPlayerMark(player, "baohe_adddamage-phase", 1)
    end
  end,
}
local xushiz = fk.CreateActiveSkill{
  name = "xushiz",
  anim_type = "offensive",
  prompt = "#xushiz-invoke",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  card_num = 0,
  target_num = 0,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local list = room:askForYiji(
      player,
      player:getCardIds("he"),
      room:getOtherPlayers(player, false),
      self.name,
      1,
      999,
      "#xushiz-invoke",
      nil,
      false,
      1
    )
    if player.dead then return end
    local x = 0
    for _, value in pairs(list) do
      if #value > 0 then
        x = x + 2
      end
    end
    room:moveCards({
      ids = getShade(room, x),
      to = player.id,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonPrey,
      proposer = player.id,
      skillName = self.name,
      moveVisible = true,
    })
  end,
}
zhangfei:addSkill(baohe)
zhangfei:addSkill(xushiz)
Fk:loadTranslationTable{
  ["js__zhangfei"] = "张飞",
  ["#js__zhangfei"] = "长坂之威",
  ["illustrator:js__zhangfei"] = "鬼画府",
  ["baohe"] = "暴喝",
  [":baohe"] = "一名角色出牌阶段结束时，你可以弃置两张牌，然后视为你对攻击范围内包含其的所有角色使用一张无距离限制的【杀】，"..
  "当其中一名目标响应此【杀】后，此【杀】对剩余目标造成的伤害+1。",
  ["xushiz"] = "虚势",
  [":xushiz"] = "出牌阶段限一次，你可以交给任意名角色各一张牌，然后你获得两倍数量的【影】。",
  ["#baohe-discard"] = "暴喝：你可以弃置两张牌，视为对所有攻击范围内包含 %dest 的角色使用【杀】",
  ["#xushiz-invoke"] = "虚势：交给任意名角色各一张牌，获得两倍数量的【影】",
}

local machao = General(extension, "js__machao", "qun", 4)
local zhuiming = fk.CreateTriggerSkill{
  name = "zhuiming",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash" and #AimGroup:getAllTargets(data.tos) == 1 and
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
    room:sendLog{
      type = "#zhuiming",
      from = player.id,
      arg = self.cost_data,
      toast = true,
    }
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
  ["#js__machao"] = "潼关之勇",
  ["illustrator:js__machao"] = "鬼画府",
  ["zhuiming"] = "追命",
  [":zhuiming"] = "当你使用【杀】指定唯一目标后，你可以声明一种颜色并令目标弃置任意张牌，然后你展示目标一张牌，若此牌颜色与你声明的颜色相同，"..
  "则此【杀】不计入次数限制、不可被响应且伤害+1。",
  ["#zhuiming-invoke"] = "追命：你可以对 %dest 发动“追命”声明一种颜色",
  ["#zhuiming"] = "%from 声明 %arg",
  ["#zhuiming-discard"] = "追命：%src 声明%arg，你可以弃置任意张牌",
}

local lougui = General(extension, "lougui", "wei", 3)
local shacheng = fk.CreateTriggerSkill{
  name = "shacheng",
  anim_type = "support",
  events = {fk.GameStart, fk.CardUseFinished},
  derived_piles = "shacheng",
  expand_pile = "shacheng",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      return event == fk.GameStart or (data.card.trueName == "slash" and #player:getPile(self.name) > 0 and data.tos and
        table.find(TargetGroup:getRealTargets(data.tos), function(id) return not player.room:getPlayerById(id).dead end))
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.GameStart then
      return true
    else
      local room = player.room
      room:setPlayerMark(player, "shacheng-tmp", table.filter(TargetGroup:getRealTargets(data.tos),
        function(id) return not room:getPlayerById(id).dead end))
      local success, dat = room:askForUseActiveSkill(player, "shacheng_active", "#shacheng-invoke", true)
      room:setPlayerMark(player, "shacheng-tmp", 0)
      if success then
        self.cost_data = dat
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      player:addToPile(self.name, room:getNCards(2), true, self.name)
    else
      room:moveCardTo(self.cost_data.cards, Card.DiscardPile, player, fk.ReasonJustMove, self.name, self.name, true, player.id)
      local to = room:getPlayerById(self.cost_data.targets[1])
      local n = 0
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.from == to.id then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                n = n + 1
              end
            end
          end
        end
      end, Player.HistoryTurn)
      if n == 0 or to.dead then return end
      to:drawCards(n, self.name)
    end
  end,
}
local shacheng_active = fk.CreateActiveSkill{
  name = "shacheng_active",
  mute = true,
  card_num = 1,
  target_num = 1,
  expand_pile = "shacheng",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Self:getPileNameOfId(to_select) == "shacheng"
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and table.contains(Self:getMark("shacheng-tmp"), to_select)
  end,
}
local ninghan = fk.CreateFilterSkill{
  name = "ninghan",
  card_filter = function(self, to_select, player)
    return RoomInstance and table.find(RoomInstance.alive_players, function (p) return p:hasSkill(self) end) and
    to_select.suit == Card.Club and to_select.trueName == "slash" and
    table.contains(player.player_cards[Player.Hand], to_select.id)
  end,
  view_as = function(self, to_select)
    local card = Fk:cloneCard("ice__slash", Card.Club, to_select.number)
    card.skillName = self.name
    return card
  end,
}
local ninghan_trigger = fk.CreateTriggerSkill{
  name = "#ninghan_trigger",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(ninghan) and not target.dead and data.damageType == fk.IceDamage and data.card and
    player.room:getCardArea(data.card) == Card.Processing
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, "ninghan", data, "#ninghan-invoke:::"..data.card:toLogString())
  end,
  on_use = function(self, event, target, player, data)
    player:addToPile("shacheng", data.card, true, "ninghan")
  end,
}
Fk:addSkill(shacheng_active)
ninghan:addRelatedSkill(ninghan_trigger)
lougui:addSkill(shacheng)
lougui:addSkill(ninghan)
Fk:loadTranslationTable{
  ["lougui"] = "娄圭",
  ["#lougui"] = "梦梅居士",
  ["illustrator:lougui"] = "鬼画府",
  ["shacheng"] = "沙城",
  [":shacheng"] = "游戏开始时，你将牌堆顶的两张牌置于你的武将牌上；当一名角色使用一张【杀】结算后，你可以移去武将牌上的一张牌，"..
  "令其中一名目标角色摸X张牌（X为该目标本回合失去的牌数且至多为5）。",
  ["ninghan"] = "凝寒",
  [":ninghan"] = "锁定技，所有角色手牌中的♣【杀】均视为冰【杀】；当一名角色受到冰冻伤害后，你可以将造成此伤害的牌置于武将牌上。",
  ["#shacheng-invoke"] = "沙城：你可以移去一张“沙城”，令其中一名目标摸其本回合失去牌数的牌",
  ["shacheng_active"] = "沙城",
  ["#ninghan_trigger"] = "凝寒",
  ["#ninghan-invoke"] = "凝寒：是否将%arg置为“沙城”？",
}

local zhangren = General(extension, "js__zhangren", "qun", 4)
local funi = fk.CreateTriggerSkill{
  name = "funi",
  mute = true,
  events = {fk.RoundStart, fk.AfterCardsMove, fk.CardUsing},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if event == fk.RoundStart then
      return player:hasSkill(self)
    elseif event == fk.AfterCardsMove then
      if player:hasSkill(self) and player:getMark("@@funi-turn") == 0 then
        for _, move in ipairs(data) do
          if move.toArea == Card.Void then
            for _, info in ipairs(move.moveInfo) do
              if Fk:getCardById(info.cardId, true).trueName == "shade" then
                return true
              end
            end
          end
        end
      end
    elseif event == fk.CardUsing then
      return target == player and player:getMark("@@funi-turn") > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.RoundStart then
      player:broadcastSkillInvoke(self.name)
      room:notifySkillInvoked(player, self.name, "control")
      local n = (#room.alive_players + 1) // 2
      local ids = getShade(room, n)
      room:askForYiji(player, ids, room.alive_players, self.name, #ids, #ids, "#funi-give", ids)
    elseif event == fk.AfterCardsMove then
      room:setPlayerMark(player, "@@funi-turn", 1)
    elseif event == fk.CardUsing then
      player:broadcastSkillInvoke(self.name)
      room:notifySkillInvoked(player, self.name, "offensive")
      data.disresponsiveList = data.disresponsiveList or {}
      for _, p in ipairs(room.alive_players) do
        table.insertIfNeed(data.disresponsiveList, p.id)
      end
    end
  end,
}
local funi_attackrange = fk.CreateAttackRangeSkill{
  name = "#funi_attackrange",
  correct_func = function (self, from, to)
    if from:hasSkill(funi) then
      return -1000
    end
    return 0
  end,
}
local funi_targetmod = fk.CreateTargetModSkill{
  name = "#funi_targetmod",
  bypass_distances = function(self, player, skill, card, to)
    return player:getMark("@@funi-turn") > 0
  end,
}
local js__chuanxin = fk.CreateTriggerSkill{
  name = "js__chuanxin",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.phase == Player.Finish and not (player:isNude() and #player:getHandlyIds(false) == 0)
  end,
  on_cost = function(self, event, target, player, data)
    local success, dat = player.room:askForUseActiveSkill(player, "#js__chuanxin_viewas", "#js__chuanxin-invoke", true)
    if success then
      self.cost_data = dat
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk.skills["#js__chuanxin_viewas"]:viewAs(self.cost_data.cards)
    local n = 0
    room.logic:getEventsOfScope(GameEvent.Recover, 999, function(e)
      local recover = e.data[1]
      for _, id in ipairs(self.cost_data.targets) do
        if recover.who.id == id then
          n = n + recover.num
        end
      end
    end, Player.HistoryTurn)
    local use = {
      from = player.id,
      tos = table.map(self.cost_data.targets, function(id) return {id} end),
      card = card,
      extraUse = true,
      additionalDamage = n,
    }
    room:useCard(use)
  end,
}
local js__chuanxin_viewas = fk.CreateViewAsSkill{
  name = "#js__chuanxin_viewas",
  handly_pile = true,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("slash")
    card:addSubcards(cards)
    card.skillName = "js__chuanxin"
    return card
  end,
}
Fk:addSkill(js__chuanxin_viewas)
funi:addRelatedSkill(funi_attackrange)
funi:addRelatedSkill(funi_targetmod)
zhangren:addSkill(funi)
zhangren:addSkill(js__chuanxin)
Fk:loadTranslationTable{
  ["js__zhangren"] = "张任",
  ["#js__zhangren"] = "索命神射",
  ["illustrator:js__zhangren"] = "鬼画府",
  ["funi"] = "伏匿",
  [":funi"] = "锁定技，你的攻击范围始终为0；每轮开始时，你令任意名角色获得共计X张【影】（X为存活角色数的一半，向上取整）；"..
  "当一张【影】进入弃牌堆时，你本回合使用牌无距离限制且不能被响应。",
  ["js__chuanxin"] = "穿心",
  [":js__chuanxin"] = "一名角色结束阶段，你可以将一张牌当伤害值+X的【杀】使用（X为目标角色本回合回复过的体力值）。",
  ["#funi-give"] = "伏匿：令任意名角色获得【影】",
  ["@@funi-turn"] = "伏匿",
  ["#js__chuanxin_viewas"] = "穿心",
  ["#js__chuanxin-invoke"] = "穿心：你可以将一张牌当【杀】使用，伤害值增加目标本回合回复的体力值",
}

local huangzhong = General(extension, "js__huangzhong", "shu", 4)
local cuifeng = fk.CreateViewAsSkill{
  name = "cuifeng",
  anim_type = "offensive",
  frequency = Skill.Limited,
  prompt = "#cuifeng-invoke",
  interaction = function()
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.is_damage_card and card.skill.target_num == 1 and not card.is_derived and
        Self:canUse(card) and not Self:prohibitUse(card) then
        table.insertIfNeed(names, card.name)
      end
    end
    return U.CardNameBox {choices = names}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
}
local cuifeng_targetmod = fk.CreateTargetModSkill{
  name = "#cuifeng_targetmod",
  bypass_distances = function(self, player, skill, card)
    return card and table.contains(card.skillNames, "cuifeng")
  end,
}
local cuifeng_trigger = fk.CreateTriggerSkill{
  name = "#cuifeng_trigger",
  mute = true,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:usedSkillTimes("cuifeng", Player.HistoryTurn) > 0 and player:hasSkill("cuifeng", true) then
      local n = 0
      player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data[1]
        if use.from == player.id and table.contains(use.card.skillNames, "cuifeng") then
          if use.damageDealt then
            for _, p in ipairs(player.room:getAllPlayers()) do
              if use.damageDealt[p.id] then
                n = n + use.damageDealt[p.id]
              end
            end
          end
        end
        return false
      end, Player.HistoryTurn)
      return n ~= 1
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke("cuifeng")
    player.room:notifySkillInvoked(player, "cuifeng", "special")
    player:setSkillUseHistory("cuifeng", 0, Player.HistoryGame)
  end,
}
local dengnan = fk.CreateViewAsSkill{
  name = "dengnan",
  anim_type = "control",
  frequency = Skill.Limited,
  prompt = "#dengnan-invoke",
  interaction = function()
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card:isCommonTrick() and not card.is_damage_card and not card.is_derived and
        Self:canUse(card) and not Self:prohibitUse(card) then
        table.insertIfNeed(names, card.name)
      end
    end
    return U.CardNameBox {choices = names}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
}
local dengnan_trigger = fk.CreateTriggerSkill{
  name = "#dengnan_trigger",
  mute = true,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:usedSkillTimes("dengnan", Player.HistoryTurn) > 0 and player:hasSkill("dengnan", true) then
      local mark = player:getMark("dengnan-turn")
      if mark == 0 then mark = {} end
      player.room.logic:getEventsOfScope(GameEvent.ChangeHp, 999, function(e)
        local damage = e.data[5]
        if damage then
          table.removeOne(mark, damage.to.id)
        end
      end, Player.HistoryTurn)
      return #mark == 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke("dengnan")
    player.room:notifySkillInvoked(player, "dengnan", "special")
    player:setSkillUseHistory("dengnan", 0, Player.HistoryGame)
  end,

  refresh_events = {fk.TargetSpecified},
  can_refresh = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, "dengnan")
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "dengnan-turn", TargetGroup:getRealTargets(data.tos))
    for _, id in ipairs(TargetGroup:getRealTargets(data.tos)) do
      local p = room:getPlayerById(id)
      room:setPlayerMark(p, "@@dengnan-turn", 1)
    end
  end,
}
cuifeng:addRelatedSkill(cuifeng_targetmod)
cuifeng:addRelatedSkill(cuifeng_trigger)
dengnan:addRelatedSkill(dengnan_trigger)
huangzhong:addSkill(cuifeng)
huangzhong:addSkill(dengnan)
Fk:loadTranslationTable{
  ["js__huangzhong"] = "黄忠",
  ["#js__huangzhong"] = "定军之英",
  ["cuifeng"] = "摧锋",
  [":cuifeng"] = "限定技，出牌阶段，你可以视为使用一张唯一目标的伤害类牌（无距离限制），若此牌未造成伤害或造成的伤害数大于1，此回合结束时重置〖摧锋〗。",
  ["dengnan"] = "登难",
  [":dengnan"] = "限定技，出牌阶段，你可以视为使用一张非伤害类普通锦囊牌，此回合结束时，若此牌的目标均于此回合受到过伤害，你重置〖登难〗。",
  ["#cuifeng-invoke"] = "摧锋：视为使用一种伤害牌！若没造成伤害或造成伤害大于1则回合结束时重置！",
  ["#cuifeng_trigger"] = "摧锋",
  ["#dengnan-invoke"] = "登难：视为使用一种非伤害普通锦囊牌！若目标本回合均受到伤害则回合结束时重置！",
  ["@@dengnan-turn"] = "登难",
  ["#dengnan_trigger"] = "登难",
}

local xiahourong = General(extension, "xiahourong", "wei", 4)
local fenjian = fk.CreateViewAsSkill{
  name = "fenjian",
  anim_type = "special",
  pattern = "duel,peach",
  prompt = "#fenjian-invoke",
  interaction = function()
    local names = {}
    local pattern = Fk.currentResponsePattern
    local duel = Fk:cloneCard("duel")
    if pattern == nil and duel.skill:canUse(Self, duel) and Self:getMark("fenjian_duel-turn") == 0 then
      table.insert(names, "duel")
    else
      if Exppattern:Parse(pattern):matchExp("peach") and Self:getMark("fenjian_peach-turn") == 0 then
        table.insert(names, "peach")
      end
    end
    if #names == 0 then return end
    return U.CardNameBox {choices = names}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    if self.interaction.data == nil then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    room:addPlayerMark(player, "@fenjian-turn", 1)
    room:setPlayerMark(player, "fenjian_"..use.card.trueName.."-turn", 1)
  end,
  enabled_at_play = function(self, player)
    return player:getMark("fenjian_duel-turn") == 0
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:getMark("fenjian_peach-turn") == 0 and not player.dying  --FIXME！
  end,
}
local fenjian_prohibit = fk.CreateProhibitSkill{
  name = "#fenjian_prohibit",
  is_prohibited = function(self, from, to, card)
    if from:hasSkill("fenjian", true) then
      return table.contains(card.skillNames, "fenjian") and from == to
    end
  end,
}
local fenjian_trigger = fk.CreateTriggerSkill{
  name = "#fenjian_trigger",
  mute = true,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@fenjian-turn") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke("fenjian")
    player.room:notifySkillInvoked(player, "fenjian", "negative")
    data.damage = data.damage + player:getMark("@fenjian-turn")
  end,
}
fenjian:addRelatedSkill(fenjian_prohibit)
fenjian:addRelatedSkill(fenjian_trigger)
xiahourong:addSkill(fenjian)
Fk:loadTranslationTable{
  ["xiahourong"] = "夏侯荣",
  ["#xiahourong"] = "擐甲执兵",
  ["fenjian"] = "奋剑",
  [":fenjian"] = "每回合各限一次，当你需要对其他角色使用【决斗】或【桃】时，你可以令你受到的伤害+1直到本回合结束，然后你视为使用之。",
  ["@fenjian-turn"] = "奋剑",
  ["#fenjian-invoke"] = "奋剑：你可以令你本回合受到的伤害+1，视为使用一张【决斗】或【桃】",
}

local sunshangxiang = General(extension, "js__sunshangxiang", "wu", 3, 3, General.Female)
local guiji = fk.CreateActiveSkill{
  name = "guiji",
  anim_type = "support",
  target_num = 1,
  prompt = "#guiji-prompt",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return Self.id ~= to_select and target:isMale() and #selected == 0 and target:getHandcardNum() < Self:getHandcardNum() 
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    U.swapHandCards(room, player, player, to, self.name)
    local mark = to:getMark("@@guiji")
    if mark == 0 then mark = {} end
    table.insertIfNeed(mark, player.id)
    room:setPlayerMark(to, "@@guiji", mark)
  end,
}
local guiji_delay = fk.CreateTriggerSkill{
  name = "#guiji_delay",
  events = {fk.EventPhaseEnd},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target.dead or player.dead then return false end
    local mark = target:getMark("@@guiji")
    if type(mark) == "table" and table.contains(mark, player.id) and target.phase == Player.Play then
      return true
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#guiji-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, guiji.name)
    player:broadcastSkillInvoke(guiji.name)
    room:doIndicate(player.id, {target.id})
    U.swapHandCards(room, player, player, target, self.name)
    local mark = target:getMark("@@guiji")
    if type(mark) == "table" and table.removeOne(mark, player.id) then
      room:setPlayerMark(target, "@@guiji", #mark > 0 and mark or 0)
    end
  end,

  refresh_events = {fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    return player == target and target:getMark("@@guiji") ~= 0 and data.from == Player.Play
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(target, "@@guiji", 0)
  end,
}
local jiaohao = fk.CreateTriggerSkill{
  name = "jiaohao",
  anim_type = "control",
  attached_skill_name = "jiaohao&",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Start then
      return #player:getCardIds("e") < #player:getAvailableEquipSlots()
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local num = (#player:getAvailableEquipSlots() - #player:getCardIds("e") + 1) // 2
    room:moveCards({
      ids = getShade(room, num),
      to = player.id,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonPrey,
      proposer = player.id,
      skillName = self.name,
      moveVisible = true,
    })
  end,
}
local jiaohao_active = fk.CreateActiveSkill{
  name = "jiaohao&",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  prompt = "#jiaohao&",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip and Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected == 0 and #selected_cards == 1 then
      local target = Fk:currentRoom():getPlayerById(to_select)
      local card = Fk:getCardById(selected_cards[1])
      return to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):hasSkill("jiaohao") and
        target:hasEmptyEquipSlot(card.sub_type)
    end
  end,
  on_use = function(self, room, effect)
    room:moveCards({
      ids = effect.cards,
      from = effect.from,
      to = effect.tos[1],
      toArea = Card.PlayerEquip,
      moveReason = fk.ReasonPut,
      skillName = "jiaohao",
    })
  end,
}
Fk:addSkill(jiaohao_active)
guiji:addRelatedSkill(guiji_delay)
sunshangxiang:addSkill(guiji)
sunshangxiang:addSkill(jiaohao)
Fk:loadTranslationTable{
  ["js__sunshangxiang"] = "孙尚香",
  ["#js__sunshangxiang"] = "情断吴江",
  ["cv:js__sunshangxiang"] = "山风",
  ["illustrator:js__sunshangxiang"] = "鬼画府",
  ["guiji"] = "闺忌",
  [":guiji"] = "每回合限一次，出牌阶段，你可以与一名手牌数小于你的男性角色交换手牌，然后其下个出牌阶段结束时，你可以与其交换手牌。",
  ["jiaohao"] = "骄豪",
  [":jiaohao"] = "其他角色出牌阶段限一次，其可以将手牌中的一张装备牌置于你的装备区中；准备阶段，你获得X张【影】（X为你空置的装备栏数的一半且向上取整）。",
  ["#guiji_delay"] = "闺忌",
  ["@@guiji"] = "闺忌",
  ["#guiji-prompt"] = "闺忌：你可以与一名手牌数小于你的男性角色交换手牌",
  ["#guiji-invoke"] = "闺忌：是否与 %dest 交换手牌？",
  ["jiaohao&"] = "骄豪",
  [":jiaohao&"] = "出牌阶段限一次，你可以将手牌中的一张装备牌置于孙尚香的装备区内。",
  ["#jiaohao&"] = "骄豪：你可以将手牌中的一张装备牌置入孙尚香的装备区",

  ["$guiji1"] = "孙家虎女，向来无所忌讳。",
  ["$guiji2"] = "厮杀半生，尚惧兵器邪？",
  ["$jiaohao1"] = "桃花马、请长缨，将军何必是丈夫。",
  ["$jiaohao2"] = "本夫人处事，何须犬马置喙？",
  ["~js__sunshangxiang"] = "手裁蜀锦君肩上，情断吴江帆影中……",
}

local pangtong = General(extension, "js__pangtong", "qun", 3)
local js__manjuan = fk.CreateViewAsSkill{
  name = "js__manjuan",
  pattern = ".",
  expand_pile = function() return Self:getTableMark("js__manjuan-turn") end,
  card_filter = function(self, to_select, selected)
    if #selected == 0 and table.contains(Self:getTableMark("js__manjuan-turn"), to_select)
    and not table.contains(Self:getTableMark("js__manjuan_used-turn"), Fk:getCardById(to_select).number) then
      local card = Fk:getCardById(to_select)
      if Fk.currentResponsePattern == nil then
        return Self:canUse(card) and not Self:prohibitUse(card)
      else
        return Exppattern:Parse(Fk.currentResponsePattern):match(card)
      end
    end
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    return Fk:getCardById(cards[1])
  end,
  before_use = function (self, player, use)
    player.room:addTableMark(player, "js__manjuan_used-turn", use.card.number)
  end,
  enabled_at_play = function(self, player)
    return player:isKongcheng()
  end,
  enabled_at_response = function(self, player, response)
    return player:isKongcheng()
  end,

  on_acquire = function (self, player, is_start)
    local room = player.room
    local ids = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 999, function(e)
      for _, move in ipairs(e.data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(room.discard_pile, info.cardId) then
              table.insertIfNeed(ids, info.cardId)
            end
          end
        end
      end
    end, Player.HistoryTurn)
    room:setPlayerMark(player, "js__manjuan-turn", ids)
  end,
}
local js__manjuan_trigger = fk.CreateTriggerSkill{
  name = "#js__manjuan_trigger",

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self, true) then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(player.room.discard_pile, info.cardId) then
              return true
            end
          end
        end
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.DiscardPile and not table.contains(player.room.discard_pile, info.cardId) then
            return true
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local ids = player:getTableMark("js__manjuan-turn")
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          if table.contains(room.discard_pile, info.cardId) then
            table.insertIfNeed(ids, info.cardId)
          end
        end
      end
      for _, info in ipairs(move.moveInfo) do
        if info.fromArea == Card.DiscardPile and not table.contains(room.discard_pile, info.cardId) then
          table.removeOne(ids, info.cardId)
        end
      end
    end
    room:setPlayerMark(player, "js__manjuan-turn", ids)
  end,
}
local yangming = fk.CreateActiveSkill{
  name = "yangming",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#yangming",
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Self:canPindian(Fk:currentRoom():getPlayerById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    while not (player.dead or target.dead) and player:canPindian(target) do
      local pindian = player:pindian({target}, self.name)
      if pindian.results[target.id].winner ~= target then
        if not player.dead and not target.dead and player:canPindian(target)
        and room:askForSkillInvoke(player, self.name, nil, "#yangming-invoke::"..target.id) then
          player:broadcastSkillInvoke(self.name)
          room:notifySkillInvoked(player, self.name)
          room:doIndicate(player.id, {target.id})
        else
          break
        end
      else
        if not target.dead then
          local n = #room.logic:getEventsOfScope(GameEvent.Pindian, 999, function (e)
            local dat = e.data[1]
            return dat.results[target.id] and dat.results[target.id].winner ~= target
          end, Player.HistoryPhase)
          if n > 0 then
            target:drawCards(n, self.name)
          end
        end
        if not player.dead and player:isWounded() then
          room:recover{
            who = player,
            num = 1,
            recoverBy = player,
            skillName = self.name
          }
        end
        break
      end
    end
  end,
}
js__manjuan:addRelatedSkill(js__manjuan_trigger)
pangtong:addSkill(js__manjuan)
pangtong:addSkill(yangming)
Fk:loadTranslationTable{
  ["js__pangtong"] = "庞统",
  ["#js__pangtong"] = "荊楚之高俊",
  ["js__manjuan"] = "漫卷",
  [":js__manjuan"] = "若你没有手牌，你可以如手牌般使用或打出本回合进入弃牌堆的牌（每种点数每回合限一次）。",
  ["yangming"] = "养名",
  [":yangming"] = "出牌阶段限一次，你可以与一名角色拼点：若其没赢，你可以与其重复此流程；若其赢，其摸等同于其本阶段拼点没赢次数的牌，你回复1点体力。",
  ["js__manjuan&"] = "漫卷",
  ["#yangming"] = "养名：与一名角色拼点，若其没赢，你可以继续与其拼点；若其赢，其摸拼点没赢次数的牌，你回复1点体力",
  ["#yangming-invoke"] = "养名：你可以继续发动“养名”与 %dest 拼点",
}

local hansui = General(extension, "js__hansui", "qun", 4)
local js__niluan = fk.CreateTriggerSkill{
  name = "js__niluan",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local success, dat = player.room:askForUseActiveSkill(player, "js__niluan_active", "#js__niluan-invoke", true)
    if success and dat then
      self.cost_data = {tos = dat.targets, cards = dat.cards}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    player:broadcastSkillInvoke(self.name)
    if #self.cost_data.cards > 0 then
      room:notifySkillInvoked(player, self.name, "offensive")
      room:throwCard(self.cost_data.cards, self.name, player, player)
      if to.dead then return end
      room:damage({
        from = player,
        to = to,
        damage = 1,
        skillName = self.name
      })
    else
      room:notifySkillInvoked(player, self.name, "support")
      to:drawCards(2, self.name)
    end
  end,

  refresh_events = {fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, true) and data.from and
      not table.contains(player:getTableMark(self.name), data.from.id)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addTableMark(player, self.name, data.from.id)
  end,

  on_acquire = function (self, player, is_start)
    local room = player.room
    local mark = {}
    room.logic:getActualDamageEvents(1, function (e)
      local damage = e.data[1]
      if damage.to == player and damage.from then
        table.insertIfNeed(mark, damage.from.id)
      end
    end, Player.HistoryGame)
    room:setPlayerMark(player, self.name, mark)
  end,
}
local js__niluan_active = fk.CreateActiveSkill{
  name = "js__niluan_active",
  mute = true,
  min_card_num = 0,
  max_card_num = 1,
  target_num = 1,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected == 0 then
      local mark = Self:getMark("js__niluan")
      if #selected_cards == 0 then
        return mark ~= 0 and table.contains(mark, to_select)
      else
        return mark == 0 or not table.contains(mark, to_select)
      end
    end
  end,
}
local huchou = fk.CreateTriggerSkill{
  name = "huchou",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return data.from and data.from == player and player:getMark(self.name) == target.id
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,

  refresh_events = {fk.TargetConfirmed},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, true) and
      data.card.is_damage_card and data.from ~= player.id and player:getMark(self.name) ~= data.from
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, self.name, data.from)
    room:setPlayerMark(player, "@huchou", room:getPlayerById(data.from).general)
  end,

  on_acquire = function (self, player, is_start)
    local room = player.room
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      local use = e.data[1]
      if use.tos and table.contains(TargetGroup:getRealTargets(use.tos), player.id) and
        use.card.is_damage_card and use.from ~= player.id then
        room:setPlayerMark(player, self.name, use.from)
        room:setPlayerMark(player, "@huchou", room:getPlayerById(use.from).general)
        return true
      end
    end, Player.HistoryGame)
  end,
}
local jiemeng = fk.CreateDistanceSkill{
  name = "jiemeng$",
  correct_func = function(self, from, to)
    if table.find(Fk:currentRoom().alive_players, function(p) return p:hasSkill(self) end) and from.kingdom == "qun" then
      local n = 0
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        if p.kingdom == "qun" then
          n = n + 1
        end
      end
      return -n
    end
    return 0
  end,
}
Fk:addSkill(js__niluan_active)
hansui:addSkill(js__niluan)
hansui:addSkill(huchou)
hansui:addSkill(jiemeng)
Fk:loadTranslationTable{
  ["js__hansui"] = "韩遂",
  ["#js__hansui"] = "雄踞北疆",
  ["js__niluan"] = "逆乱",
  [":js__niluan"] = "准备阶段，你可以选择一项：1.弃置一张牌，对一名未对你造成过伤害的角色造成1点伤害；2.令一名对你造成过伤害的角色摸两张牌。",
  ["huchou"] = "互雠",
  [":huchou"] = "锁定技，上一名对你使用伤害类牌的其他角色受到你造成的伤害时，此伤害+1。",
  ["jiemeng"] = "皆盟",
  [":jiemeng"] = "主公技，锁定技，所有群势力角色计算与其他角色的距离-X（X为群势力角色数）。",
  ["js__niluan_active"] = "逆乱",
  ["#js__niluan-invoke"] = "逆乱：弃一张牌，对一名未对你造成过伤害的角色造成1点伤害；或令一名对你造成过伤害的角色摸两张牌",
  ["@huchou"] = "互雠",
}

local zhangchu = General(extension, "js__zhangchu", "qun", 3, 3, General.Female)
local huozhong = fk.CreateActiveSkill{
  name = "huozhong",
  attached_skill_name = "huozhong&",
  anim_type = "drawcard",
  target_num = 0,
  card_num = 1,
  prompt = "#huozhong-invoke",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:hasDelayedTrick("supply_shortage")
    and not table.contains(player.sealedSlots, Player.JudgeSlot)
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type ~= Card.TypeTrick and Fk:getCardById(to_select).color == Card.Black
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local card = Fk:cloneCard("supply_shortage")
    card:addSubcards(effect.cards)
    player:addVirtualEquip(card)
    room:moveCardTo(card, Card.PlayerJudge, player, fk.ReasonPut, self.name)
    if not player.dead then
      player:drawCards(2, self.name)
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
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:hasDelayedTrick("supply_shortage")
    and not table.contains(player.sealedSlots, Player.JudgeSlot)
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type ~= Card.TypeTrick and Fk:getCardById(to_select).color == Card.Black
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local card = Fk:cloneCard("supply_shortage")
    card:addSubcards(effect.cards)
    player:addVirtualEquip(card)
    room:moveCardTo(card, Card.PlayerJudge, player, fk.ReasonPut, "huozhong")
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
    target:drawCards(2, "huozhong")
  end,
}
local js__rihui = fk.CreateTriggerSkill{
  name = "js__rihui",
  anim_type = "support",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card and data.card.trueName == "slash" and not data.chain and
      table.find(player.room:getOtherPlayers(player, false), function(p) return #p:getCardIds("j") > 0 end)
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
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:addCardUseHistory(data.card.trueName, -1)
    room:addPlayerMark(room:getPlayerById(data.to), "js__rihui-phase", 1)
  end,
}
Fk:addSkill(huozhong_active)
js__rihui:addRelatedSkill(js__rihui_trigger)
zhangchu:addSkill(huozhong)
zhangchu:addSkill(js__rihui)
Fk:loadTranslationTable{
  ["js__zhangchu"] = "张楚",
  ["#js__zhangchu"] = "大贤后裔",
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

local xiahouen = General(extension, "js__xiahouen", "wei", 4)
local hujian = fk.CreateTriggerSkill{
  name = "hujian",
  anim_type = "special",
  events = {fk.GameStart, fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return true
      else
        if table.find(player.room.discard_pile, function(id) return Fk:getCardById(id).trueName == "blood_sword" end) then
          local room = player.room
          local e = room.logic:getCurrentEvent()
          local end_id = e.id
          local id = 0
          local events = room.logic.event_recorder[GameEvent.UseCard] or Util.DummyTable
          for i = #events, 1, -1 do
            e = events[i]
            if e.id <= end_id then break end
            end_id = e.id
            local use = e.data[1]
            id = use.from
          end
          events = room.logic.event_recorder[GameEvent.RespondCard] or Util.DummyTable
          for i = #events, 1, -1 do
            e = events[i]
            if e.id <= end_id then break end
            end_id = e.id
            local response = e.data[1]
            id = response.from
          end
          if id ~= 0 and not room:getPlayerById(id).dead then
            self.cost_data = id
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.GameStart then
      return true
    else
      return player.room:askForSkillInvoke(player.room:getPlayerById(self.cost_data), self.name, nil, "#hujian-invoke")
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local card = room:printCard("blood_sword", Card.Spade, 6)
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
    else
      local p = room:getPlayerById(self.cost_data)
      local card = room:getCardsFromPileByRule("blood_sword", 1, "discardPile")
      if #card > 0 then
        room:moveCardTo(card, Card.PlayerHand, p, fk.ReasonJustMove, self.name, nil, true, p.id)
      end
    end
  end,
}
local shili = fk.CreateViewAsSkill{
  name = "shili",
  anim_type = "offensive",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip and table.contains(Self:getCardIds("h"), to_select)
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("duel")
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
}
xiahouen:addSkill(hujian)
xiahouen:addSkill(shili)
Fk:loadTranslationTable{
  ["js__xiahouen"] = "夏侯恩",
  ["#js__xiahouen"] = "背剑之将",
  ["hujian"] = "护剑",
  [":hujian"] = "游戏开始时，你从游戏外获得一张【赤血青锋】；一名角色回合结束时，此回合最后一名使用或打出过的牌的角色可以获得弃牌堆中的【赤血青锋】。",
  ["shili"] = "恃力",
  [":shili"] = "出牌阶段限一次，你可以将一张手牌中的装备牌当【决斗】使用。",
  ["#hujian-invoke"] = "护剑：你可以获得弃牌堆中的【赤血青锋】",
}

local fanjiangzhangda = General(extension, "js__fanjiangzhangda", "wu", 5)
local fushan = fk.CreateTriggerSkill{
  name = "fushan",
  mute = true,
  events = {fk.EventPhaseStart, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Play then
      if event == fk.EventPhaseStart then
        return not table.every(player.room:getOtherPlayers(player, false), function(p) return p:isNude() end)
      else
        if player:getMark("@fushan-phase") == 0 then return end
        local card = Fk:cloneCard("slash")
        local skill = card.skill
        local n = skill:getMaxUseTime(player, Player.HistoryPhase, card, nil)
        if not n or player:usedCardTimes("slash", Player.HistoryPhase) < n then
          if table.every(player:getMark("fushan-phase"), function(id) return not player.room:getPlayerById(id).dead end) then
            return true
          end
        end
        return player:getHandcardNum() < player.maxHp
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.EventPhaseStart then
      room:notifySkillInvoked(player, self.name, "special")
      local targets = table.filter(room:getOtherPlayers(player, false), function(p) return not p:isNude() end)
      if #targets == 0 then return end
      room:doIndicate(player.id, table.map(targets, Util.IdMapper))
      local mark = {}
      for _, p in ipairs(targets) do
        if player.dead then return end
        if not p.dead and not p:isNude() then
          local cards = room:askForCard(p, 1, 1, true, self.name, true, nil, "#fushan-give:"..player.id)
          if #cards > 0 then
            room:moveCardTo(Fk:getCardById(cards[1]), Card.PlayerHand, player, fk.ReasonGive, self.name, nil, false, p.id)
            room:addPlayerMark(player, "@fushan-phase", 1)
            table.insert(mark, p.id)
          end
        end
      end
      if #mark > 0 then
        room:setPlayerMark(player, "fushan-phase", mark)
      end
    else
      local card = Fk:cloneCard("slash")
      local skill = card.skill
      local n = skill:getMaxUseTime(player, Player.HistoryPhase, card, nil)
      if not n or player:usedCardTimes("slash", Player.HistoryPhase) < n then
        if table.every(player:getMark("fushan-phase"), function(id) return not room:getPlayerById(id).dead end) then
          room:notifySkillInvoked(player, self.name, "negative")
          room:loseHp(player, 2, self.name)
          return
        end
      end
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:drawCards(player.maxHp - player:getHandcardNum(), self.name)
    end
  end,
}
local fushan_targetmod = fk.CreateTargetModSkill{
  name = "#fushan_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("@fushan-phase") > 0 and scope == Player.HistoryPhase then
      return player:getMark("@fushan-phase")
    end
  end,
}
fushan:addRelatedSkill(fushan_targetmod)
fanjiangzhangda:addSkill(fushan)
Fk:loadTranslationTable{
  ["js__fanjiangzhangda"] = "范疆张达",
  ["#js__fanjiangzhangda"] = "你死我亡",
  ["fushan"] = "负山",
  [":fushan"] = "出牌阶段开始时，所有其他角色依次可以交给你一张牌并令你本阶段使用【杀】的次数上限+1；此阶段结束时，若你使用【杀】的次数未达上限"..
  "且本阶段以此法交给你牌的角色均存活，你失去2点体力，否则你将手牌摸至体力上限。",
  ["#fushan-give"] = "负山：是否交给 %src 一张牌令其本阶段使用【杀】次数上限+1？",
  ["@fushan-phase"] = "负山",
}

return extension
