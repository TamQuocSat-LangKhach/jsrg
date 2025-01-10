local extension = Package("rise")
extension.extensionName = "jsrg"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["rise"] = "江山如故·兴",
  ["js2"] = "江山",
}

local simazhao = General(extension, "js__simazhao", "wei", 4)
local qiantun = fk.CreateActiveSkill{
  name = "qiantun",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#qiantun",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cards = room:askForCard(target, 1, 999, false, self.name, false, nil, "#qiantun-ask:"..player.id)
    target:showCards(cards)
    cards = table.filter(cards, function (id)
      return table.contains(target:getCardIds("h"), id)
    end)
    if player.dead or target.dead or #cards == 0 or not player:canPindian(target) then return end
    local pindian = {
      from = player,
      tos = {target},
      reason = self.name,
      fromCard = nil,
      results = {},
      extra_data = {
        qiantun = {
          to = target.id,
          cards = cards,
        },
      },
    }
    room:pindian(pindian)
    if player.dead or target.dead then return end
    if pindian.results[target.id].winner == player then
      cards = table.filter(target:getCardIds("h"), function (id)
        return table.contains(cards, id)
      end)
    else
      cards = table.filter(target:getCardIds("h"), function (id)
        return not table.contains(cards, id)
      end)
    end
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id)
    end
    if not player.dead and not player:isKongcheng() then
      player:showCards(player:getCardIds("h"))
    end
  end,
}
local qiantun_trigger = fk.CreateTriggerSkill{
  name = "#qiantun_trigger",
  mute = true,
  events = {fk.StartPindian},
  can_trigger = function(self, event, target, player, data)
    if player == data.from and data.reason == "qiantun" and data.extra_data and data.extra_data.qiantun then
      for _, to in ipairs(data.tos) do
        if not (data.results[to.id] and data.results[to.id].toCard) and
          data.extra_data.qiantun.to == to.id and
          table.find(data.extra_data.qiantun.cards, function (id)
            return table.contains(to:getCardIds("h"), id)
          end) then
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, to in ipairs(data.tos) do
      if not (to.dead or to:isKongcheng() or (data.results[to.id] and data.results[to.id].toCard)) and
        data.extra_data.qiantun.to == to.id then
        local cards = table.filter(data.extra_data.qiantun.cards, function (id)
          return table.contains(to:getCardIds("h"), id)
        end)
        if #cards > 0 then
          local card = room:askForCard(to, 1, 1, false, "qiantun", false, tostring(Exppattern{ id = cards }),
            "#qiantun-pindian:"..data.from.id)
          data.results[to.id] = data.results[to.id] or {}
          data.results[to.id].toCard = Fk:getCardById(card[1])
        end
      end
    end
  end,
}
local xiezheng = fk.CreateTriggerSkill{
  name = "xiezheng",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and
      table.find(player.room.alive_players, function (p)
        return not p:isKongcheng()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return not p:isKongcheng()
    end)
    local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 3,
      "#xiezheng-choose", self.name, true)
    if #tos > 0 then
      room:sortPlayersByAction(tos)
      self.cost_data = {tos = tos}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(self.cost_data.tos) do
      local p = room:getPlayerById(id)
      if not p.dead and not p:isKongcheng() then
        local card = room:askForCard(p, 1, 1, false, self.name, false, nil, "#xiezheng-ask:"..player.id)
        room:moveCards({
          ids = card,
          from = id,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonPut,
          skillName = self.name,
        })
      end
    end
    if player.dead then return end
    local use = U.askForUseVirtualCard(room, player, "enemy_at_the_gates", nil, self.name, "#xiezheng-use", false)
    if use and not player.dead and not (use.extra_data and use.extra_data.xiezheng_damageDealt) then
      room:loseHp(player, 1, self.name)
    end
  end,

  refresh_events = {fk.Damage},
  can_refresh = function (self, event, target, player, data)
    return target == player and data.card and data.card.trueName == "slash" and
      table.contains(data.card.skillNames, "enemy_at_the_gates_skill")
  end,
  on_refresh = function (self, event, target, player, data)
    local e = player.room.logic:getCurrentEvent().parent
    while e do
      if e.event == GameEvent.UseCard then
        local use = e.data[1]
        if use.card.name == "enemy_at_the_gates" and table.contains(use.card.skillNames, "xiezheng") then
          use.extra_data = use.extra_data or {}
          use.extra_data.xiezheng_damageDealt = true
          return
        end
      end
      e = e.parent
    end
  end,
}
local zhaoxiong = fk.CreateTriggerSkill{
  name = "zhaoxiong",
  anim_type = "special",
  events = {fk.EventPhaseStart},
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      player:isWounded() and player:usedSkillTimes("xiezheng", Player.HistoryGame) > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#zhaoxiong-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.general == "js__simazhao" then
      player.general = "js2__simazhao"
      room:broadcastProperty(player, "general")
    elseif player.deputyGeneral == "js__simazhao" then
      player.deputyGeneral = "js2__simazhao"
      room:broadcastProperty(player, "deputyGeneral")
    end
    if player.kingdom ~= "jin" then
      room:changeKingdom(player, "jin", true)
    end
    if not player.dead then
      room:handleAddLoseSkills(player, "-qiantun|weisi|dangyi", nil, true, false)
    end
  end,
}
qiantun:addRelatedSkill(qiantun_trigger)
simazhao:addSkill(qiantun)
simazhao:addSkill(xiezheng)
simazhao:addSkill(zhaoxiong)
Fk:loadTranslationTable{
  ["js__simazhao"] = "司马昭",
  ["#js__simazhao"] = "堕节肇业",
  ["illustrator:js__simazhao"] = "云涯",

  ["qiantun"] = "谦吞",
  [":qiantun"] = "出牌阶段限一次，你可以令一名其他角色展示至少一张手牌，并与其拼点，其本次拼点牌只能从展示牌中选择。若你赢，你获得其展示的手牌；"..
  "若你没赢，你获得其未展示的手牌。然后你展示手牌。",
  ["xiezheng"] = "挟征",
  [":xiezheng"] = "结束阶段，你可以令至多三名角色依次将一张手牌置于牌堆顶，然后视为你使用一张【兵临城下】，结算后若未造成过伤害，你失去1点体力。",
  ["zhaoxiong"] = "昭凶",
  [":zhaoxiong"] = "限定技，准备阶段，若你已受伤且发动过〖挟征〗，你可以变更势力至晋，失去〖谦吞〗，获得〖威肆〗〖荡异〗。",
  ["#qiantun"] = "谦吞：令一名角色展示任意张手牌并与其拼点，若赢，你获得展示牌；若没赢，你获得其未展示的手牌",
  ["#qiantun-ask"] = "谦吞：请展示任意张手牌，你将只能用这些牌与 %src 拼点，根据拼点结果其获得你的展示牌或未展示牌！",
  ["#qiantun-pindian"] = "谦吞：你只能用这些牌与 %src 拼点！若其赢，其获得你的展示牌；若其没赢，其获得你未展示的手牌",
  ["#xiezheng-choose"] = "挟征：令至多三名角色依次将一张手牌置于牌堆顶，然后你视为使用一张【兵临城下】！",
  ["#xiezheng-ask"] = "挟征：%src 将视为使用【兵临城下】！请将一张手牌置于牌堆顶",
  ["#xiezheng-use"] = "挟征：视为使用一张【兵临城下】！若未造成伤害，你失去1点体力",
  ["#zhaoxiong-invoke"] = "昭凶：是否变为晋势力、失去“谦吞”、获得“威肆”和“荡异”？",
}

local simazhao2 = General(extension, "js2__simazhao", "jin", 4)
simazhao2.hidden = true
local weisi = fk.CreateActiveSkill{
  name = "weisi",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#weisi",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cards = room:askForCard(target, 1, 999, false, self.name, true, nil, "#weisi-ask:"..player.id)
    if #cards > 0 then
      target:addToPile("$weisi", cards, false, self.name, target.id)
    end
    if player.dead or target.dead then return end
    room:useVirtualCard("duel", nil, player, target, self.name)
  end,
}
local weisi_delay = fk.CreateTriggerSkill{
  name = "#weisi_delay",
  mute = true,
  events = {fk.Damage, fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if event == fk.Damage then
      return target == player and not player.dead and player.room.logic:damageByCardEffect(true) and
        data.card and table.contains(data.card.skillNames, "weisi") and
        not data.to:isKongcheng()
    elseif event == fk.TurnEnd then
      return #player:getPile("$weisi") > 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damage then
      room:moveCardTo(data.to:getCardIds("h"), Card.PlayerHand, player, fk.ReasonPrey, "weisi", nil, false, player.id)
    elseif event == fk.TurnEnd then
      room:moveCardTo(player:getPile("$weisi"), Card.PlayerHand, player, fk.ReasonJustMove, "weisi", nil, false, player.id)
    end
  end,
}
local dangyi = fk.CreateTriggerSkill{
  name = "dangyi",
  anim_type = "offensive",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:getMark("@dangyi") > 0
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#dangyi-invoke::"..data.to.id..":"..player:getMark("@dangyi"))
  end,
  on_use = function(self, event, target, player, data)
    player.room:removePlayerMark(player, "@dangyi", 1)
    data.damage = data.damage + 1
  end,

  on_acquire = function (self, player, is_start)
    player.room:addPlayerMark(player, "@dangyi", player:getLostHp() + 1)
  end,
  on_lose = function (self, player, is_death)
    player.room:setPlayerMark(player, "@dangyi", 0)
  end,
}
weisi:addRelatedSkill(weisi_delay)
simazhao2:addSkill(weisi)
simazhao2:addSkill("xiezheng")
simazhao2:addSkill(dangyi)
Fk:loadTranslationTable{
  ["js2__simazhao"] = "司马昭",
  ["#js2__simazhao"] = "独祆吞天",
  ["illustrator:js2__simazhao"] = "腥鱼仔",

  ["weisi"] = "威肆",
  [":weisi"] = "出牌阶段限一次，你可以选择一名其他角色，令其将任意张手牌移出游戏直到回合结束，然后视为对其使用一张【决斗】，"..
  "此牌对其造成伤害后，你获得其所有手牌。",
  ["dangyi"] = "荡异",
  [":dangyi"] = "主公技，当你造成伤害时，你可以令此伤害值+1，本局游戏限X次（X为你获得此技能时已损失体力值+1）。",
  ["#weisi"] = "威肆：令一名角色将任意张手牌移出游戏直到回合结束，然后视为对其使用【决斗】！",
  ["#weisi-ask"] = "威肆：%src 将对你使用【决斗】！请将任意张手牌本回合移出游戏，【决斗】对你造成伤害后其获得你所有手牌！",
  ["$weisi"] = "威肆",
  ["#weisi_delay"] = "威肆",
  ["#dangyi-invoke"] = "荡异：是否令你对 %dest 造成的伤害+1？（还剩%arg次！）",
  ["@dangyi"] = "荡异",
}

local lukang = General(extension, "js__lukang", "wu", 4)
local zhuwei = fk.CreateActiveSkill{
  name = "js__zhuwei",
  anim_type = "control",
  card_num = 0,
  target_num = 2,
  prompt = "#js__zhuwei",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    if #selected == 0 then
      return true
    elseif #selected == 1 then
      return Fk:currentRoom():getPlayerById(selected[1]):canMoveCardsInBoardTo(target, "e")
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local record = {}
    for _, p in ipairs(room.players) do
      if p.dead then
        table.insert(record, 999)
      else
        table.insert(record, #table.filter(room.alive_players, function (q)
          return p:inMyAttackRange(q)
        end))
      end
    end
    room:askForMoveCardInBoard(player, room:getPlayerById(effect.tos[1]), room:getPlayerById(effect.tos[2]), self.name, "e")
    if player.dead then return end
    local targets = {}
    for i = 1, #room.players, 1 do
      local p = room.players[i]
      if not p.dead then
        local n = #table.filter(room.alive_players, function (q)
          return p:inMyAttackRange(q)
        end)
        if n == 0 and n ~= record[i] then
          table.insert(targets, p.id)
        end
      end
    end
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#js__zhuwei-choose", self.name, true)
    if #to > 0 then
      room:loseHp(room:getPlayerById(to[1]), 2, self.name)
    end
  end,
}
local kuangjian = fk.CreateViewAsSkill{
  name = "kuangjian",
  anim_type = "special",
  pattern = ".|.|.|.|.|basic",
  prompt = "#kuangjian",
  interaction = function(self)
    local all_names = U.getAllCardNames("b")
    local names = U.getViewAsCardNames(Self, self.name, all_names)
    if #names > 0 then
      return U.CardNameBox { choices = names, all_choices = all_names }
    end
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip
  end,
  before_use = function (self, player, use)
    use.extraUse = true
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
  after_use = function (self, player, use)
    local room = player.room
    if table.contains(room.discard_pile, use.card.subcards[1]) then
      local card = Fk:getCardById(use.card.subcards[1])
      if card.type ~= Card.TypeEquip then return end
      for _, id in ipairs(TargetGroup:getRealTargets(use.tos)) do
        local p = room:getPlayerById(id)
        if not p.dead and not p:prohibitUse(card) then
          room:useCard{
            from = p.id,
            tos = {{p.id}},
            card = card,
          }
        end
      end
    end
  end,
  enabled_at_response = function (self, player, response)
    local banner = Fk:currentRoom():getBanner("kuangjian_dying")
    if banner == player.id then return false end
    return not response
  end,
}
local kuangjian_prohibit = fk.CreateProhibitSkill{
  name = "#kuangjian_prohibit",
  is_prohibited = function(self, from, to, card)
    return table.contains(card.skillNames, "kuangjian") and from == to
  end,
}
local kuangjian_targetmod = fk.CreateTargetModSkill{
  name = "#kuangjian_targetmod",
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, "kuangjian")
  end,
}
--- FIXME: 求桃无视合法性判断
local kuangjian_trigger = fk.CreateTriggerSkill{
  name = "#kuangjian_trigger",

  refresh_events = {fk.HandleAskForPlayCard},
  can_refresh = function(self, event, target, player, data)
    return data.cardName == "peach" and data.extraData and table.contains(data.extraData.must_targets or {}, player.id)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if not data.afterRequest then
      room:setBanner("kuangjian_dying", player.id)
    else
      room:setBanner("kuangjian_dying", 0)
    end
  end,
}
kuangjian:addRelatedSkill(kuangjian_prohibit)
kuangjian:addRelatedSkill(kuangjian_targetmod)
kuangjian:addRelatedSkill(kuangjian_trigger)
lukang:addSkill(zhuwei)
lukang:addSkill(kuangjian)
Fk:loadTranslationTable{
  ["js__lukang"] = "陆抗",
  ["#js__lukang"] = "架海金梁",
  ["illustrator:js__lukang"] = "小罗没想好",

  ["js__zhuwei"] = "筑围",
  [":js__zhuwei"] = "出牌阶段限一次，你可以移动场上一张装备牌，然后你可以令一名攻击范围内的角色数变为0的角色失去2点体力。",
  ["kuangjian"] = "匡谏",
  [":kuangjian"] = "你可以将装备牌当任意基本牌使用（目标不能为你且无次数限制），结算后目标角色使用弃牌堆中的此装备牌。",
  ["#js__zhuwei"] = "筑围：移动场上一张装备牌，然后可以令一名攻击范围内角色数因此变为0的角色失去2点体力！",
  ["#js__zhuwei-choose"] = "筑围：你可以令其中一名角色失去2点体力！",
  ["#kuangjian"] = "匡谏：将装备牌当任意基本牌使用（目标不能为你且无次数限制），结算后目标角色使用弃牌堆中此装备牌",
}

local malong = General(extension, "malong", "jin", 4)
local fennan = fk.CreateActiveSkill{
  name = "fennan",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#fennan",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < #Self:getCardIds("e")
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (self, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local choices = {"fennan1:"..player.id}
    if not target:isKongcheng() then
      table.insert(choices, "fennan2:"..player.id)
    end
    local choice = room:askForChoice(target, choices, self.name)
    if choice[7] == "1" then
      player:turnOver()
      if player.dead then return end
      local cards = {}
      room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.toArea == Card.PlayerEquip or move.toArea == Card.PlayerJudge then
            for _, info in ipairs(move.moveInfo) do
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
      end, Player.HistoryTurn)
      local targets = table.filter(room:getOtherPlayers(target), function (p)
        return table.find(target:getCardIds("ej"), function (id)
          return not table.contains(cards, id) and target:canMoveCardInBoardTo(p, id)
        end)
      end)
      if #targets == 0 then return end
      local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1,
        "#fennan-move::"..target.id, self.name, false)
      to = room:getPlayerById(to[1])
      room:askForMoveCardInBoard(player, target, to, self.name, nil, target, cards)
    else
      local n = #player:getCardIds("e")
      local cards = U.askforChooseCardsAndChoice(player, target:getCardIds("h"), {"OK"}, self.name,
        "#fennan-recast::"..target.id..":"..n, {"Cancel"}, 0, n)
      if #cards > 0 then
        room:recastCard(cards, target, self.name)
      end
    end
  end,
}
local xunjim = fk.CreateTriggerSkill{
  name = "xunjim",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Finish then
      local room = player.room
      local targets = {}
      room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data[1]
        if use.from == player.id then
          for _, id in ipairs(TargetGroup:getRealTargets(use.tos)) do
            if id ~= player.id then
              table.insertIfNeed(targets, id)
            end
          end
        end
      end, Player.HistoryTurn)
      if #targets == 0 then return end
      room.logic:getActualDamageEvents(1, function (e)
        local damage = e.data[1]
        if damage.from == player then
          table.removeOne(targets, damage.to.id)
        end
      end, Player.HistoryTurn)
      if #targets > 0 then return end
      local cards = {}
      room.logic:getActualDamageEvents(1, function (e)
        local damage = e.data[1]
        if damage.card then
          table.insertTableIfNeed(cards, Card:getIdList(damage.card))
        end
      end, Player.HistoryTurn)
      cards = table.filter(cards, function (id)
        return table.contains(room.discard_pile, id)
      end)
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:askForYiji(player, self.cost_data, room.alive_players, self.name, 1, 10, "#xunjim-give", self.cost_data, false, 1)
  end,
}
malong:addSkill(fennan)
malong:addSkill(xunjim)
Fk:loadTranslationTable{
  ["malong"] = "马隆",
  ["#malong"] = "困局诡阵",
  ["illustrator:malong"] = "荆芥",

  ["fennan"] = "奋难",
  [":fennan"] = "出牌阶段限X次，你可以令一名角色选择一项：1.令你翻面，然后你移动其场上一张本回合未移动过的牌；2.你观看并重铸其至多X张手牌"..
  "（X为你装备区内牌的数量）。",
  ["xunjim"] = "勋济",
  [":xunjim"] = "结束阶段，若你于本回合对回合内你使用牌指定过的其他角色均造成过伤害，你可以将弃牌堆中本回合造成伤害的牌分配给至多等量角色各一张。",
  ["#fennan"] = "奋难：令一名角色选择：你翻面，然后移动其场上一张牌；你观看并重铸其手牌",
  ["fennan1"] = "%src翻面，然后其移动场上一张牌",
  ["fennan2"] = "%src观看并重铸你的手牌",
  ["#fennan-move"] = "奋难：请将 %dest 场上一张牌移动给另一名角色",
  ["#fennan-recast"] = "奋难：你可以选择 %dest 至多%arg张手牌，令其重铸",
  ["#xunjim-give"] = "勋济：你可以分配这些牌，每名角色至多一张",
}

local wangjun = General(extension, "js__wangjun", "jin", 4)
local chengliu = fk.CreateTriggerSkill{
  name = "chengliu",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and
      table.find(player.room.alive_players, function (p)
        return #player:getCardIds("e") > #p:getCardIds("e")
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function (p)
      return #player:getCardIds("e") > #p:getCardIds("e")
    end)
    local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#chengliu-invoke", self.name, true)
    if #to > 0 then
      self.cost_data = {tos = to}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    room:addTableMark(player, "chengliu-turn", to.id)
    room:damage({
      from = player,
      to = to,
      damage = 1,
      skillName = self.name,
    })
    while not player.dead and #player:getCardIds("e") > 0 do
      local targets = table.filter(room.alive_players, function (p)
        return #player:getCardIds("e") > #p:getCardIds("e") and not table.contains(player:getTableMark("chengliu-turn"), p.id)
      end)
      if #targets == 0 then return end
      local cards = table.filter(player:getCardIds("e"), function (id)
        return not player:prohibitDiscard(id)
      end)
      local success, dat = room:askForUseActiveSkill(player, "ex__choose_skill", "#chengliu-discard", true, {
        targets = table.map(targets, Util.IdMapper),
        min_c_num = 1,
        max_c_num = 1,
        min_t_num = 1,
        max_t_num = 1,
        pattern = tostring(Exppattern{ id = cards }),
        skillName = self.name,
      }, false)
      if success then
        to = room:getPlayerById(dat.targets[1])
        room:addTableMark(player, "chengliu-turn", to.id)
        room:throwCard(dat.cards, self.name, player, player)
        if not to.dead then
          room:damage({
            from = player,
            to = to,
            damage = 1,
            skillName = self.name,
          })
        end
      else
        return
      end
    end
  end,
}
local jianlou = fk.CreateTriggerSkill{
  name = "jianlou",
  anim_type = "control",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and not player:isNude() then
      local cards = {}
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).type == Card.TypeEquip and
              table.contains(player.room.discard_pile, info.cardId) then
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
      end
      cards = U.moveCardsHoldingAreaCheck(player.room, cards)
      if #cards > 0 then
        self.cost_data = cards
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local cards = table.simpleClone(self.cost_data)
    local card = {}
    if #cards == 1 then
      card = player.room:askForDiscard(player, 1, 1, true, self.name, true, nil,
        "#jianlou1-invoke:::"..Fk:getCardById(cards[1]):toLogString(), true)
    elseif #cards > 1 then
      card = player.room:askForDiscard(player, 1, 1, true, self.name, true, nil,
        "#jianlou2-invoke", true)
    end
    if #card > 0 then
      self.cost_data = {cards = card, extra_data = cards}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data.cards, self.name, player, player)
    if player.dead then return end
    local id = 0
    if #self.cost_data.extra_data == 1 then
      if table.contains(room.discard_pile, self.cost_data.extra_data[1]) then
        id = self.cost_data.extra_data[1]
      else
        return
      end
    else
      local cards = table.filter(self.cost_data.extra_data, function (c)
        return table.contains(room.discard_pile, c)
      end)
      if #cards == 0 then return end
      id = U.askforChooseCardsAndChoice(player, cards, {"OK"}, self.name, "#jianlou-prey")[1]
    end
    room:moveCardTo(id, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
    if player.dead or not table.contains(player:getCardIds("h"), id) then return end
    local card = Fk:getCardById(id)
    if #player:getEquipments(card.sub_type) == 0 and not player:prohibitUse(card) then
      room:useCard{
        from = player.id,
        tos = {{player.id}},
        card = card,
      }
    end
  end,
}
wangjun:addSkill(chengliu)
wangjun:addSkill(jianlou)
Fk:loadTranslationTable{
  ["js__wangjun"] = "王濬",
  ["#js__wangjun"] = "顺流长驱",
  ["illustrator:js__wangjun"] = "荆芥",

  ["chengliu"] = "乘流",
  [":chengliu"] = "准备阶段，你可以对一名装备区内牌数小于你的角色造成1点伤害，然后你可以弃置装备区内的一张牌，对一名本回合未以此法选择过的角色"..
  "重复此流程。",
  ["jianlou"] = "舰楼",
  [":jianlou"] = "每回合限一次，当一张装备牌进入弃牌堆后，你可以弃置一张牌并获得之，然后若你对应装备栏没有装备，你使用之。",
  ["#chengliu-invoke"] = "乘流：对一名装备数小于你的角色造成1点伤害，然后你可以弃置一张装备重复此流程",
  ["#chengliu-discard"] = "乘流：是否弃置一张装备，继续造成伤害？",
  ["#jianlou1-invoke"] = "舰楼：%arg进入弃牌堆，是否弃置一张牌获得之？",
  ["#jianlou2-invoke"] = "舰楼：装备牌进入弃牌堆，是否弃置一张牌获得之？",
  ["#jianlou-prey"] = "舰楼：选择你要获得的装备牌",
}

local limi = General(extension, "limi", "shu", 3)
local ciying = fk.CreateViewAsSkill{
  name = "ciying",
  pattern = ".|.|.|.|.|basic",
  prompt = function (self, selected, selected_cards)
    return "#ciying:::"..math.max(4 - #Self:getTableMark("@ciying-turn"), 1)
  end,
  interaction = function(self)
    local all_names = U.getAllCardNames("b")
    local names = U.getViewAsCardNames(Self, self.name, all_names)
    if #names > 0 then
      return U.CardNameBox { choices = names, all_choices = all_names }
    end
  end,
  card_filter = Util.TrueFunc,
  view_as = function(self, cards)
    if #cards == 0 or #cards < (4 - #Self:getTableMark("@ciying-turn")) or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = self.name
    return card
  end,
  after_use = function (self, player, use)
    if not player.dead and #player:getTableMark("@ciying-turn") == 4 and player:getHandcardNum() < player.maxHp then
      player:drawCards(player.maxHp - player:getHandcardNum(), self.name)
    end
  end,
  enabled_at_play = function (self, player)
    return player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  enabled_at_response = function (self, player, response)
    return player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
}
local ciying_trigger = fk.CreateTriggerSkill{
  name = "#ciying_trigger",

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(ciying, true) and #player:getTableMark("@ciying-turn") < 4 then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          return true
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local mark = player:getTableMark("@ciying-turn")
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          local suit = Fk:getCardById(info.cardId):getSuitString(true)
          if suit ~= "log_nosuit" then
            table.insertIfNeed(mark, suit)
          end
        end
      end
    end
    player.room:setPlayerMark(player, "@ciying-turn", mark)
  end,
}
local chendu = fk.CreateTriggerSkill{
  name = "chendu",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local cards = {}
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          if move.from == player.id and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                table.insertIfNeed(cards, info.cardId)
              end
            end
          elseif move.from == nil and
            table.contains({fk.ReasonUse, fk.ReasonResonpse}, move.moveReason) then
            local parent_event = player.room.logic:getCurrentEvent().parent
            if parent_event ~= nil then
              local card_ids = {}
              if parent_event.event == GameEvent.UseCard or parent_event.event == GameEvent.RespondCard then
                local use = parent_event.data[1]
                if use.from == player.id then
                  parent_event:searchEvents(GameEvent.MoveCards, 1, function(e2)
                    if e2.parent and e2.parent.id == parent_event.id then
                      for _, move2 in ipairs(e2.data) do
                        if (move2.moveReason == fk.ReasonUse or move2.moveReason == fk.ReasonResonpse) then
                          for _, info in ipairs(move2.moveInfo) do
                            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                              table.insertIfNeed(card_ids, info.cardId)
                            end
                          end
                        end
                      end
                    end
                  end)
                end
              end
              if #card_ids > 0 then
                for _, info in ipairs(move.moveInfo) do
                  if table.contains(card_ids, info.cardId) and info.fromArea == Card.Processing then
                    table.insertIfNeed(cards, info.cardId)
                  end
                end
              end
            end
          end
        end
      end
      cards = table.filter(cards, function (id)
        return table.contains(player.room.discard_pile, id)
      end)
      cards = U.moveCardsHoldingAreaCheck(player.room, cards)
      if #cards > player.hp and #cards > 0 then
        local turn_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn)
        if turn_event == nil or turn_event.data[1].dead then return end
        if #player.room:getOtherPlayers(player, false) == 0 then return end
        self.cost_data = cards
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local all_cards = table.simpleClone(self.cost_data)
    local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn)
    if turn_event == nil or turn_event.data[1].dead then return end
    local to = turn_event.data[1]
    if to == player then
      room:askForYiji(player, all_cards, room:getOtherPlayers(player, false), self.name, #all_cards, #all_cards,
        "#chendu1-give", all_cards)
    else
      local cards = table.simpleClone(all_cards)
      local ids = room:askForCard(player, 1, 999, false, self.name, false, tostring(Exppattern{ id = all_cards }),
        "#chendu2-give::"..to.id, all_cards)
      for _, id in ipairs(ids) do
        table.removeOne(cards, id)
        room:setCardMark(Fk:getCardById(id), "@DistributionTo", Fk:translate(to.general))
      end
      if #cards == 0 then
        for _, id in ipairs(ids) do
          room:setCardMark(Fk:getCardById(id), "@DistributionTo", 0)
        end
        room:moveCardTo(ids, Card.PlayerHand, to, fk.ReasonGive, self.name, nil, true, player.id)
      else
        local list = room:askForYiji(player, cards, room:getOtherPlayers(player, false), self.name, #cards, #cards,
          "#chendu1-give", cards, true)
        for _, id in ipairs(ids) do
          table.insert(list[to.id], id)
        end
        for _, id in ipairs(all_cards) do
          room:setCardMark(Fk:getCardById(id), "@DistributionTo", 0)
        end
        room:doYiji(list, player.id, self.name)
      end
    end
  end,
}
ciying:addRelatedSkill(ciying_trigger)
limi:addSkill(ciying)
limi:addSkill(chendu)
Fk:loadTranslationTable{
  ["limi"] = "李密",
  ["#limi"] = "情切哺乌",
  ["illustrator:limi"] = "小罗没想好",

  ["ciying"] = "辞应",
  [":ciying"] = "每回合限一次，你可以将至少X张牌当任意基本牌使用或打出（X为本回合未进入过弃牌堆的花色数，至少为1）。此牌结算结束后，若本回合"..
  "所有花色的牌均进入过弃牌堆，你将手牌摸至体力上限。",
  ["chendu"] = "陈笃",
  [":chendu"] = "锁定技，当你的牌因使用、打出或弃置进入弃牌堆后，若数量大于你的体力值，你将这些牌分配给其他角色（若不为你的回合，"..
  "则选择的角色必须包含当前回合角色）。",
  ["@ciying-turn"] = "辞应",
  ["#ciying"] = "辞应：你可以将至少%arg张牌当任意基本牌使用或打出",
  ["#chendu1-give"] = "陈笃：请将这些牌任意分配给其他角色",
  ["#chendu2-give"] = "陈笃：请将这些牌任意分配给其他角色，先必须分配给 %dest",
}

local simaliang = General(extension, "simaliang", "jin", 3, 4)
local shejus = fk.CreateTriggerSkill{
  name = "shejus",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecified, fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      (event == fk.TargetSpecified and data.firstTarget or event == fk.TargetConfirmed) and data.card.trueName == "slash" and
      #AimGroup:getAllTargets(data.tos) == 1 and
      not player.room:getPlayerById(data.from):isKongcheng() and not player.room:getPlayerById(data.to):isKongcheng() and
      not player.room:getPlayerById(data.from).dead and not player.room:getPlayerById(data.to).dead
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.from)
    if data.from == player.id then
      to = room:getPlayerById(data.to)
    end
    room:doIndicate(player.id, {to.id})
    local discussion = U.Discussion(player, {player, to}, self.name)
    if discussion.color == "black" then
      if not player.dead then
        room:changeMaxHp(player, -1)
      end
      if not to.dead then
        room:changeMaxHp(to, -1)
      end
    else
      for _, p in ipairs({player, to}) do
        if not p.dead and discussion.results[p.id].opinion == "black" then
          p:drawCards(2, self.name)
        end
      end
    end
  end,
}
local zuwang = fk.CreateTriggerSkill{
  name = "zuwang",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      (player.phase == Player.Start or player.phase == Player.Finish) and
      player:getHandcardNum() < player.maxHp
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(player.maxHp - player:getHandcardNum(), self.name)
  end,
}
simaliang:addSkill(shejus)
simaliang:addSkill(zuwang)
Fk:loadTranslationTable{
  ["simaliang"] = "司马亮",
  ["#simaliang"] = "冲粹的蒲牢",
  ["illustrator:simaliang"] = "小罗没想好",

  ["shejus"] = "慑惧",
  [":shejus"] = "锁定技，当你使用【杀】指定唯一目标后或成为【杀】的唯一目标后，你与对方议事：若结果为黑色，双方各减1点体力上限；否则意见为"..
  "黑色的角色摸两张牌。",
  ["zuwang"] = "族望",
  [":zuwang"] = "锁定技，准备阶段和结束阶段，你将手牌摸至体力上限。",
}

local wenyang = General(extension, "js__wenyang", "wei", 4)
local fuzhen = fk.CreateTriggerSkill{
  name = "fuzhen",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and #player.room.alive_players > 1
  end,
  on_cost = function(self, event, target, player, data)
    local use = U.askForUseVirtualCard(player.room, player, "thunder__slash", nil, self.name,
      "#fuzhen-invoke", true, true, true, true, nil, true)
    if use then
      self.cost_data = use
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local use = self.cost_data
    local targets = room:getUseExtraTargets(use, true)
    if #targets > 0 then
      local tos = room:askForChoosePlayers(player, targets, 1, 2, "#fuzhen-choose", self.name, true)
      if #tos > 0 then
        for _, id in ipairs(tos) do
          table.insert(use.tos, {id})
        end
      end
    end
    local to = room:askForChoosePlayers(player, TargetGroup:getRealTargets(use.tos), 1, 1, "#fuzhen-secret", self.name, false, false)
    room:loseHp(player, 1, self.name)
    room:useCard(use)
    if player.dead then return end
    if use.damageDealt then
      local n = 0
      for _, p in ipairs(room.players) do
        if use.damageDealt[p.id] then
          n = n + use.damageDealt[p.id]
        end
      end
      player:drawCards(n, self.name)
    end
    if not use.damageDealt or not use.damageDealt[to[1]] then
      targets = table.filter(TargetGroup:getRealTargets(use.tos), function (id)
        return not room:getPlayerById(id).dead
      end)
      if #targets > 0 then
        room:useVirtualCard("thunder__slash", nil, player, table.map(targets, Util.Id2PlayerMapper), self.name, true)
      end
    end
  end,
}
wenyang:addSkill(fuzhen)
Fk:loadTranslationTable{
  ["js__wenyang"] = "文鸯",
  ["#js__wenyang"] = "貔貅若拒",
  ["illustrator:js__wenyang"] = "town",

  ["fuzhen"] = "覆阵",
  [":fuzhen"] = "准备阶段，你可以失去1点体力，视为使用一张无距离限制的雷【杀】，此【杀】可以额外指定至多两个目标，你秘密选择其中一名目标角色。"..
  "此【杀】结算后，你摸造成伤害值的牌；若未对你秘密选择的角色造成伤害，你再视为对这些角色使用一张雷【杀】。",
  ["#fuzhen-invoke"] = "覆阵：你可以失去1点体力，视为使用无距离限制的雷【杀】",
  ["#fuzhen-choose"] = "覆阵：你可以为此雷【杀】增加至多两个目标",
  ["#fuzhen-secret"] = "覆阵：秘密选择一名目标角色，若未对其造成伤害，再视为对这些角色使用雷【杀】！",
}

local jiananfeng = General(extension, "jiananfeng", "jin", 3, 3, General.Female)
local shanzheng = fk.CreateActiveSkill{
  name = "shanzheng",
  anim_type = "offensive",
  card_num = 0,
  min_target_num = 1,
  prompt = "#shanzheng",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    table.insert(effect.tos, player.id)
    room:sortPlayersByAction(effect.tos)
    local targets = table.map(effect.tos, Util.Id2PlayerMapper)
    local discussion = U.Discussion(player, targets, self.name)
    if player.dead then return end
    if discussion.color == "red" then
      targets = table.filter(room.alive_players, function (p)
        return not table.contains(targets, p)
      end)
      if #targets == 0 then return end
      local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#shanzheng-damage", self.name, true)
      if #to > 0 then
        room:damage{
          from = player,
          to = room:getPlayerById(to[1]),
          damage = 1,
          skillName = self.name,
        }
      end
    elseif discussion.color == "black" then
      local cards = {}
      for _, p in ipairs(targets) do
        if not p.dead and p ~= player then
          local ids = table.filter(discussion.results[p.id].toCards, function (id)
            return table.contains(p:getCardIds("h"), id)
          end)
          if #ids > 0 then
            table.insertTableIfNeed(cards, ids)
          end
        end
      end
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, true, player.id)
      end
    end
  end,
}
local xiongbao = fk.CreateTriggerSkill{
  name = "xiongbao",
  anim_type = "control",
  events = {"fk.StartDiscussion"},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and (player == data.from or table.contains(data.tos, player)) and
      player:getHandcardNum() > 1
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForCard(player, 2, 2, false, self.name, true, nil,
      "#xiongbao-invoke::"..data.from.id..":"..data.reason)
    if #cards > 0 then
      self.cost_data = {cards = cards}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    for _, p in ipairs(data.tos) do
      data.results[p.id] = data.results[p.id] or {}
      if p == player then
        data.results[player.id].toCards = self.cost_data.cards
        local card = table.map(self.cost_data.cards, function (id)
          return Fk:getCardById(id)
        end)
        if card[1]:getColorString() == card[2]:getColorString() then
          data.results[player.id].opinion = card[1]:getColorString()
        else
          data.results[player.id].opinion = "noresult"
        end
      else
        local id = table.random(p:getCardIds("h"))
        data.results[p.id].toCards = {id}
        data.results[p.id].opinion = Fk:getCardById(id):getColorString()
      end
    end
  end,
}
local liedu = fk.CreateTriggerSkill{
  name = "liedu",
  anim_type = "offensive",
  events = {fk.CardUsing},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return p:isFemale() or p:getHandcardNum() > player:getHandcardNum()
      end)
  end,
  on_use = function(self, event, target, player, data)
    local targets = table.filter(player.room:getOtherPlayers(player, false), function(p)
      return p:isFemale() or p:getHandcardNum() > player:getHandcardNum()
    end)
    if #targets > 0 then
      data.disresponsiveList = data.disresponsiveList or {}
      for _, p in ipairs(targets) do
        table.insertIfNeed(data.disresponsiveList, p.id)
      end
    end
  end,
}
jiananfeng:addSkill(shanzheng)
jiananfeng:addSkill(xiongbao)
jiananfeng:addSkill(liedu)
Fk:loadTranslationTable{
  ["jiananfeng"] = "贾南风",
  ["#jiananfeng"] = "凤啸峻旹",
  ["illustrator:jiananfeng"] = "小罗没想好",

  ["shanzheng"] = "擅政",
  [":shanzheng"] = "出牌阶段限一次，你可以与任意名角色议事，若结果为：红色，你可以对一名未参与议事的角色造成1点伤害；黑色，你获得所有意见牌。",
  ["xiongbao"] = "凶暴",
  [":xiongbao"] = "当你参与议事选择议事牌前，你可以改为额外展示一张手牌，若如此做，其他角色改为随机展示一张手牌。",
  ["liedu"] = "烈妒",
  [":liedu"] = "锁定技，其他女性角色和手牌数大于你的角色不能响应你使用的牌。",
  ["#shanzheng"] = "擅政：与任意名角色议事，红色：你可以对一名未参与议事的角色造成1点伤害；黑色：你获得所有意见牌",
  ["#shanzheng-damage"] = "擅政：你可以对一名未参与议事的角色造成1点伤害",
  ["#xiongbao-invoke"] = "擅政：%dest 发起“%arg”议事，你可以展示两张意见牌（双倍意见！）令其他议事角色改为随机展示一张手牌",
}

local tufashujineng = General(extension, "tufashujineng", "qun", 4)
local qinrao = fk.CreateTriggerSkill{
  name = "qinrao",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(self) and target.phase == Player.Play and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local success, dat = player.room:askForUseActiveSkill(player, "qinrao_viewas",
      "#qinrao-use::"..target.id, true, {must_targets = {target.id},})
    if success then
      self.cost_data = dat
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useVirtualCard("duel", self.cost_data.cards, player, target, self.name)
  end,
}
local qinrao_viewas = fk.CreateViewAsSkill{
  name = "qinrao_viewas",
  card_filter = function (self, to_select, selected)
    return #selected == 0
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("duel")
    card.skillName = "qinrao"
    card:addSubcard(cards[1])
    return card
  end,
}
local qinraoDuelSkill = fk.CreateActiveSkill{
  name = "qinrao__duel_skill",
  prompt = "#duel_skill",
  mod_target_filter = function(self, to_select, selected, user, card)
    return user ~= to_select
  end,
  target_filter = function(self, to_select, selected, _, card)
    if #selected < self:getMaxTargetNum(Self, card) then
      return self:modTargetFilter(to_select, selected, Self.id, card)
    end
  end,
  target_num = 1,
  on_effect = function(self, room, effect)
    local to = room:getPlayerById(effect.to)
    local from = room:getPlayerById(effect.from)
    local responsers = { to, from }
    local currentTurn = 1
    local currentResponser = to

    while currentResponser:isAlive() do
      local loopTimes = 1
      if effect.fixedResponseTimes then
        local canFix = currentResponser == to
        if effect.fixedAddTimesResponsors then
          canFix = table.contains(effect.fixedAddTimesResponsors, currentResponser.id)
        end

        if canFix then
          if type(effect.fixedResponseTimes) == 'table' then
            loopTimes = effect.fixedResponseTimes["slash"] or 1
          elseif type(effect.fixedResponseTimes) == 'number' then
            loopTimes = effect.fixedResponseTimes
          end
        end
      end

      local cardResponded
      for i = 1, loopTimes do
        if currentResponser == to then
          cardResponded = room:askForResponse(currentResponser, "slash", nil, "#qinrao-duel", true, nil, effect)
        else
          cardResponded = room:askForResponse(currentResponser, "slash", nil, nil, true, nil, effect)
        end
        if cardResponded then
          room:responseCard({
            from = currentResponser.id,
            card = cardResponded,
            responseToEvent = effect,
          })
        else
          if currentResponser == to then
            local cards = table.filter(to:getCardIds("h"), function (id)
              local card = Fk:getCardById(id)
              return card.trueName == "slash" and not to:prohibitResponse(card)
            end)
            if #cards > 0 then
              cardResponded = Fk:getCardById(table.random(cards))
              room:responseCard({
                from = to.id,
                card = cardResponded,
                responseToEvent = effect,
              })
            else
              if not to:isKongcheng() then
                to:showCards(to:getCardIds("h"))
              end
              break
            end
          else
            break
          end
        end
      end

      if not cardResponded then break end

      currentTurn = currentTurn % 2 + 1
      currentResponser = responsers[currentTurn]
    end

    if currentResponser:isAlive() then
      room:damage({
        from = responsers[currentTurn % 2 + 1],
        to = currentResponser,
        card = effect.card,
        damage = 1,
        damageType = fk.NormalDamage,
        skillName = "duel_skill",
      })
    end
  end
}
qinraoDuelSkill.cardSkill = true
Fk:addSkill(qinraoDuelSkill)
local qinrao_trigger = fk.CreateTriggerSkill{
  name = "#qinrao_trigger",

  refresh_events = {fk.PreCardEffect},
  can_refresh = function(self, event, target, player, data)
    return data.from == player.id and data.card.trueName == "duel" and table.contains(data.card.skillNames, "qinrao")
  end,
  on_refresh = function(self, event, target, player, data)
    local card = data.card:clone()
    local c = table.simpleClone(data.card)
    for k, v in pairs(c) do
      card[k] = v
    end
    card.skill = qinraoDuelSkill
    data.card = card
  end,
}
local furan = fk.CreateTriggerSkill{
  name = "furan",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.from and
      (data.from.dead or not data.from:inMyAttackRange(player))
  end,
}
local furan_delay = fk.CreateTriggerSkill{
  name = "#furan_delay",
  anim_type = "support",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:usedSkillTimes("furan", Player.HistoryTurn) > 0 and player:isWounded() and not player.dead
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player.room:recover{
      who = player,
      num = math.min(player:usedSkillTimes("furan", Player.HistoryTurn), player:getLostHp()),
      recoverBy = player,
      skillName = "furan",
    }
  end,
}
Fk:addSkill(qinrao_viewas)
qinrao:addRelatedSkill(qinrao_trigger)
furan:addRelatedSkill(furan_delay)
tufashujineng:addSkill(qinrao)
tufashujineng:addSkill(furan)
Fk:loadTranslationTable{
  ["tufashujineng"] = "秃发树机能",
  ["#tufashujineng"] = "朔西扰攘",
  ["illustrator:tufashujineng"] = "荆芥",

  ["qinrao"] = "侵扰",
  [":qinrao"] = "其他角色出牌阶段开始时，你可以将一张牌当【决斗】对其使用，若其手牌中有可以打出的【杀】，其必须打出响应，否则其展示所有手牌。",
  ["furan"] = "复燃",
  [":furan"] = "当你受到伤害后，若你不在伤害来源攻击范围内，你可以于此回合结束时回复1点体力。",
  ["#qinrao-use"] = "侵扰：你可以将一张牌当【决斗】对 %dest 使用",
  ["qinrao_viewas"] = "侵扰",
  ["#qinrao-duel"] = "侵扰：你必须打出一张【杀】！点“取消”则随机打出一张【杀】，若没有则展示手牌",
  ["#furan_delay"] = "复燃",
}

local dengai = General(extension, "js__dengai", "wei", 4)
local piqi = fk.CreateViewAsSkill{
  name = "piqi",
  anim_type = "control",
  prompt = "#piqi",
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    local card = Fk:cloneCard("snatch")
    card.skillName = self.name
    return card
  end,
  before_use = function (self, player, use)
    local room = player.room
    local to = room:getPlayerById(TargetGroup:getRealTargets(use.tos)[1])
    room:addTableMark(player, "piqi-phase", to.id)
    for _, p in ipairs(room.alive_players) do
      if p:distanceTo(to) < 2 then
        room:handleAddLoseSkills(p, "piqi&", nil, false, true)
        room.logic:getCurrentEvent():findParent(GameEvent.Turn):addCleaner(function()
          room:handleAddLoseSkills(p, "-piqi&", nil, false, true)
        end)
      end
    end
  end,
  times = function(self)
    return Self.phase == Player.Play and 2 - Self:usedSkillTimes(self.name, Player.HistoryPhase) or -1
  end,
  enabled_at_play = function (self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 2
  end,
}
local piqi_prohibit = fk.CreateProhibitSkill{
  name = "#piqi_prohibit",
  is_prohibited = function(self, from, to, card)
    return table.contains(card.skillNames, "piqi") and table.contains(from:getTableMark("piqi-phase"), to.id)
  end,
}
local piqi_targetmod = fk.CreateTargetModSkill{
  name = "#piqi_targetmod",
  bypass_distances = function(self, player, skill, card)
    return card and table.contains(card.skillNames, "piqi")
  end,
}
local piqi_viewas = fk.CreateViewAsSkill{
  name = "piqi&",
  anim_type = "control",
  pattern = "nullification",
  prompt = "#piqi&",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).trueName == "jink" and table.contains(Self:getHandlyIds(true), to_select)
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("nullification")
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_response = function (self, player, response)
    return not response
  end,
}
local zhoulind = fk.CreateTriggerSkill{
  name = "zhoulind",
  anim_type = "offensive",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card and data.card.trueName == "slash" and
      table.contains(player:getTableMark("zhoulind-turn"), data.to.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = Util.TrueFunc,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local mark = {}
    for _, p in ipairs(room.alive_players) do
      if not player:inMyAttackRange(p) then
        table.insert(mark, p.id)
      end
    end
    room:setPlayerMark(player, "zhoulind-turn", mark)
  end,
}
piqi:addRelatedSkill(piqi_prohibit)
piqi:addRelatedSkill(piqi_targetmod)
Fk:addSkill(piqi_viewas)
dengai:addSkill(piqi)
dengai:addSkill(zhoulind)
Fk:loadTranslationTable{
  ["js__dengai"] = "邓艾",
  ["#js__dengai"] = "策袭鼎迁",
  ["illustrator:js__dengai"] = "小罗没想好",

  ["piqi"] = "辟奇",
  [":piqi"] = "出牌阶段限两次，你可以视为使用一张无距离限制的【顺手牵羊】（两次目标不能为同一名角色），与目标距离1以内的角色本回合可以将"..
  "【闪】当【无懈可击】使用。",
  ["zhoulind"] = "骤临",
  [":zhoulind"] = "当你使用【杀】对一名角色造成伤害时，若本回合开始时其不在你的攻击范围内，此伤害+1。",
  ["#piqi"] = "辟奇：视为使用一张无距离限制的【顺手牵羊】，与目标距离1以内的角色本回合可以将【闪】当【无懈可击】使用",
  ["piqi&"] = "辟奇",
  [":piqi&"] = "你可以将【闪】当【无懈可击】使用。",
  ["#piqi&"] = "辟奇：你可以将【闪】当【无懈可击】使用",
}

local zhugedan = General(extension, "js__zhugedan", "wei", 4)
local zuozhan = fk.CreateTriggerSkill{
  name = "zuozhan",
  anim_type = "special",
  events = {fk.GameStart, fk.Deathed},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.GameStart then
        return #player.room.alive_players > 1
      else
        return table.contains(player:getTableMark(self.name), target.id)
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player, false), Util.IdMapper), 1, 2,
        "#zuozhan-choose", self.name, false)
      table.insert(tos, player.id)
      room:setPlayerMark(player, self.name, tos)
      for _, id in ipairs(tos) do
        local p = room:getPlayerById(id)
        room:setPlayerMark(p, "@@zuozhan", 1)
      end
    else
      local nums = {0}
      for _, id in ipairs(player:getTableMark(self.name)) do
        local p = room:getPlayerById(id)
        table.insert(nums, p.hp)
      end
      local n = math.max(table.unpack(nums))
      if n == 0 then return end
      local cards = {}
      for _, id in ipairs(room.discard_pile) do
        local card = Fk:getCardById(id)
        if card.type == Card.TypeBasic then
          cards[card.trueName] = cards[card.trueName] or {}
          table.insert(cards[card.trueName], id)
        end
      end
      if next(cards) == nil then return end
      local to = room:askForChoosePlayers(player, player:getTableMark(self.name), 1, 1, "#zuozhan-prey:::"..n, self.name, false)
      to = room:getPlayerById(to[1])
      local card_data = {}
      for _, name in ipairs({"slash", "jink", "peach", "analeptic"}) do  --按杀闪桃酒顺序排列
        if cards[name] then
          table.insert(card_data, {name, cards[name]})
        end
      end
      for name, ids in pairs(cards) do
        if not table.contains({"slash", "jink", "peach", "analeptic"}, name) and #ids > 0 then  --其他基本牌按牌名排列
          table.insert(card_data, {name, ids})
        end
      end
      local ret = room:askForPoxi(to, self.name, card_data, {num = n}, false)
      room:moveCardTo(ret, Card.PlayerHand, to, fk.ReasonJustMove, self.name, nil, true, to.id)
    end
  end,
}
Fk:addPoxiMethod{
  name = "zuozhan",
  prompt = function (data, extra_data)
    return "#zuozhan:::"..math.floor(extra_data.num)
  end,
  card_filter = function(to_select, selected, data, extra_data)
    return #selected < extra_data.num
  end,
  feasible = function(selected, data)
    if data and #data >= #selected then
      local areas = {}
      for _, id in ipairs(selected) do
        for _, v in ipairs(data) do
          if table.contains(v[2], id) then
            table.insertIfNeed(areas, v[2])
            break
          end
        end
      end
      return #areas >= #selected
    end
  end,
  default_choice = function(data)
    if not data then return {} end
    local cids = table.map(data, function(v) return v[2][1] end)
    return cids
  end,
}
local zuozhan_attackrange = fk.CreateAttackRangeSkill{
  name = "#zuozhan_attackrange",
  correct_func = function (self, from, to)
    if from:getMark("zuozhan") ~= 0 then
      local nums = {0}
      for _, id in ipairs(from:getTableMark("zuozhan")) do
        local p = Fk:currentRoom():getPlayerById(id)
        table.insert(nums, p.hp)
      end
      return math.max(table.unpack(nums))
    end
  end,
}
local cuibing = fk.CreateTriggerSkill{
  name = "cuibing",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and
      player:getHandcardNum() ~= math.min(#table.filter(player.room.alive_players, function (p)
        return player:inMyAttackRange(p)
      end), 5)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    local n = player:getHandcardNum() - math.min(#table.filter(player.room.alive_players, function (p)
      return player:inMyAttackRange(p)
    end), 5)
    if n > 0 then
      room:notifySkillInvoked(player, self.name, "control")
      local cards = room:askForDiscard(player, n, n, false, self.name, false)
      if #cards > 0 and not player.dead then
        n = #cards
        while n > 0 and not player.dead do
          local targets = table.filter(room.alive_players, function (p)
            return #p:getCardIds("ej") > 0
          end)
          if #targets == 0 then return end
          local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#cuibing-choose:::"..n, self.name, true)
          if #to > 0 then
            to = room:getPlayerById(to[1])
            cards = room:askForCardsChosen(player, to, 1, n, "ej", self.name, "#cuibing-discard::"..to.id..":"..n)
            n = n - #cards
            room:throwCard(cards, self.name, to, player)
          else
            return
          end
        end
      end
    elseif n < 0 then
      room:notifySkillInvoked(player, self.name, "drawcard")
      player:drawCards(-n, self.name)
      player:skip(Player.Discard)
    end
  end,
}
local langan = fk.CreateTriggerSkill{
  name = "langan",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.Deathed},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      })
    end
    if player.dead then return end
    player:drawCards(2, self.name)
    if not player.dead and player:getMark(self.name) < 3 then
      room:addPlayerMark(player, self.name, 1)
     end
  end,
}
local langan_attackrange = fk.CreateAttackRangeSkill{
  name = "#langan_attackrange",
  correct_func = function (self, from, to)
    return -from:getMark("langan")
  end,
}
zuozhan:addRelatedSkill(zuozhan_attackrange)
langan:addRelatedSkill(langan_attackrange)
zhugedan:addSkill(zuozhan)
zhugedan:addSkill(cuibing)
zhugedan:addSkill(langan)
Fk:loadTranslationTable{
  ["js__zhugedan"] = "诸葛诞",
  ["#js__zhugedan"] = "护国孤獒",
  ["illustrator:js__zhugedan"] = "特特肉",

  ["zuozhan"] = "坐瞻",
  [":zuozhan"] = "游戏开始时，你选择你与至多两名其他角色，你的攻击范围+X（X为你选择角色中最大的体力值，至多为5）。当“坐瞻”角色死亡后，"..
  "你令一名存活的“坐瞻”角色从弃牌堆中获得至多X张牌名各不相同的基本牌。",
  ["cuibing"] = "摧冰",
  [":cuibing"] = "锁定技，出牌阶段结束时，你将手牌摸或弃置至X张（X为你攻击范围内的角色数且至多为5）。若你因此弃置了牌，你弃置场上至多等量张牌；"..
  "否则你跳过弃牌阶段。",
  ["langan"] = "阑干",
  [":langan"] = "锁定技，当其他角色死亡后，你回复1点体力并摸两张牌，然后你的攻击范围-1（至多减3）。",
  ["#zuozhan-choose"] = "坐瞻：请选择至多两名“坐瞻”角色，你的攻击范围增加你和这些角色中最大的体力值",
  ["@@zuozhan"] = "坐瞻",
  ["#zuozhan-prey"] = "坐瞻：令一名“坐瞻”角色从弃牌堆获得至多%arg张牌名各不相同的基本牌",
  ["#zuozhan"] = "坐瞻：获得至多%arg张牌名各不相同的基本牌",
  ["#cuibing-choose"] = "摧冰：你可以弃置一名角色场上的牌（还剩%arg张！）",
  ["#cuibing-discard"] = "摧冰：弃置 %dest 场上至多%arg张牌",
}

return extension
