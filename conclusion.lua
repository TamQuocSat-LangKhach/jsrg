local extension = Package("conclusion")
extension.extensionName = "jsrg"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["conclusion"] = "江山如故·合",
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

---@param player ServerPlayer @ 操作蓄谋的玩家
---@param card integer | Card  @ 用来蓄谋的牌
---@param skill_name? string @ 技能名
---@param proposer? integer @ 移动操作者的id
---@return nil
local premeditate = function(player, card, skill_name, proposer)
  skill_name = skill_name or ""
  proposer = proposer or player.id
  local room = player.room
  if type(card) == "table" then
    assert(not card:isVirtual() or #card.subcards == 1)
    card = card:getEffectiveId()
  end
  local xumou = Fk:cloneCard("premeditate")
  xumou:addSubcard(card)
  player:addVirtualEquip(xumou)
  room:moveCardTo(xumou, Player.Judge, player, fk.ReasonJustMove, skill_name, "", false, proposer, "", {proposer, player.id})
end

local premeditate_rule = fk.CreateTriggerSkill{
  name = "#premeditate_rule",
  events = {fk.EventPhaseStart},
  mute = true,
  global = true,
  priority = 0,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Judge
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getCardIds(Player.Judge)
    for i = #cards, 1, -1 do
      if table.contains(player:getCardIds(Player.Judge), cards[i]) then
        if player.dead then return end
        local xumou = player:getVirualEquip(cards[i])
        if xumou and xumou.name == "premeditate" then
          local use = U.askForUseRealCard(room, player, {cards[i]}, ".", "premeditate",
            "#premeditate-use:::"..Fk:getCardById(cards[i], true):toLogString(),
            {expand_pile = {cards[i]}, extra_use = true}, true, true)
          if use then
            room:setPlayerMark(player, "premeditate_"..use.card.trueName.."-phase", 1)
            use.extra_data = use.extra_data or {}
            use.extra_data.premeditate = true
            room:useCard(use)
          else
            break
          end
        end
      end
    end
    cards = player:getCardIds(Player.Judge)
    local xumou = table.filter(cards, function(id)
      local card = player:getVirualEquip(id)
      return card and card.name == "premeditate"
    end)
    room:moveCardTo(xumou, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, "premeditate", nil, true, player.id)
  end,
}
local premeditate_prohibit = fk.CreateProhibitSkill{
  name = "#premeditate_prohibit",
  global = true,
  prohibit_use = function(self, player, card)
    return card and player:getMark("premeditate_"..card.trueName.."-phase") > 0
  end,
}
Fk:addSkill(premeditate_rule)
Fk:addSkill(premeditate_prohibit)
Fk:loadTranslationTable{
  ["#premeditate-use"] = "你可以使用此蓄谋牌%arg，或点“取消”将所有蓄谋牌置入弃牌堆",
}

local zhugeliang = General(extension, "js__zhugeliang", "shu", 3)
local wentian = fk.CreateViewAsSkill{
  name = "wentian",
  pattern = "fire_attack,nullification",
  interaction = function()
    local availableNames = { "fire_attack", "nullification" }
    local names = U.getViewAsCardNames(Self, "wentian", availableNames)
    if #names > 0 then
      return U.CardNameBox { choices = names, all_choices = availableNames }
    end
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    if #cards ~= 0 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    local topCardId = room:getNCards(1)[1]

    use.card:addSubcard(topCardId)
    local cardColor = Fk:getCardById(topCardId).color
    if
      (use.card.name == "nullification" and cardColor ~= Card.Black) or
      (use.card.name == "fire_attack" and cardColor ~= Card.Red)
    then
      room:invalidateSkill(player, self.name, "-round")
    end
  end,
  enabled_at_play = Util.TrueFunc,
  enabled_at_response = function(self, player, response)
    return not response
  end,
}
local wentianTrigger = fk.CreateTriggerSkill{
  name = "#wentian_trigger",
  anim_type = "control",
  main_skill = wentian,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(wentian) and
      player:getMark("wentian_trigger-turn") == 0 and
      player.phase > 1 and player.phase < 8
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, "wentian", data, "#wentian-ask:::" .. Util.PhaseStrMapper(player.phase))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "wentian_trigger-turn", 1)
    local topCardIds = U.turnOverCardsFromDrawPile(player, 5, self.name, false)

    local others = room:getOtherPlayers(player, false)
    if #others > 0 then
      local _, ret = room:askForUseActiveSkill(player, "ex__choose_skill", "#wentian-give", false, {
        targets = table.map(others, Util.IdMapper),
        min_c_num = 1,
        max_c_num = 1,
        min_t_num = 1,
        max_t_num = 1,
        pattern = tostring(Exppattern{ id = topCardIds }),
        skillName = "wentian",
        expand_pile = topCardIds,
      }, false)

      local toGive = ret and ret.cards[1] or topCardIds[1]
      table.removeOne(topCardIds, toGive)
      room:moveCardTo(
        toGive,
        Card.PlayerHand,
        ret and room:getPlayerById(ret.targets[1]) or room:getOtherPlayers(player)[1],
        fk.ReasonGive,
        "wentian",
        nil,
        false,
        player.id,
        nil,
        player.id
      )

      if player.dead then
        room:cleanProcessingArea(topCardIds, self.name)
        return false
      end
    end

    local result = room:askForGuanxing(player, topCardIds, nil, nil, "wentian", true)
    room:sendLog{
      type = "#GuanxingResult",
      from = player.id,
      arg = #result.top,
      arg2 = #result.bottom,
    }
    local moveInfos = {}
    if #result.top > 0 then
      table.insert(moveInfos, {
        ids = table.reverse(result.top),
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
        proposer = player.id,
        moveVisible = false,
        visiblePlayers = player.id,
        drawPilePosition = 1
      })
    end
    if #result.bottom > 0 then
      table.insert(moveInfos, {
        ids = result.bottom,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
        proposer = player.id,
        moveVisible = false,
        visiblePlayers = player.id,
        drawPilePosition = -1
      })
    end
    room:moveCards(table.unpack(moveInfos))
  end,
}
local chushi = fk.CreateActiveSkill{
  name = "chushi",
  anim_type = "support",
  card_num = 0,
  prompt = "#chushi",
  target_num = function(self)
    return #table.filter(Fk:currentRoom().alive_players, function(p) return p.role == "lord" end) > 1 and 1 or 0 
  end,
  can_use = function(self, player)
    return
      player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and
      table.find(Fk:currentRoom().alive_players, function(p) return p.role == "lord" end) and
      (
        not player:isKongcheng() or
        table.find(Fk:currentRoom().alive_players, function(p) return p.role == "lord" and not p:isKongcheng() end)
      )
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    if #table.filter(Fk:currentRoom().alive_players, function(p) return p.role == "lord" end) < 2 then
      return false
    end

    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and target.role == "lord" and not (Self:isKongcheng() and target:isKongcheng())
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local targetId = #effect.tos > 0 and effect.tos[1] or table.find(room.alive_players, function(p) return p.role == "lord" end).id
    local target = room:getPlayerById(targetId)

    room:delay(1000)
    local targets = { player }
    if target ~= player then
      table.insert(targets, target)
    end

    room:doIndicate(player.id, table.map(targets, Util.IdMapper))
    local discussion = U.Discussion(player, table.filter(targets, function(p) return not p:isKongcheng() end), self.name)
    if discussion.color == "red" then
      local drawTargets = { player.id }
      if player ~= target then
        table.insert(drawTargets, target.id)
        room:sortPlayersByAction(drawTargets)
      end

      drawTargets = table.map(drawTargets, Util.Id2PlayerMapper)

      for _, p in ipairs(drawTargets) do
        p:drawCards(1, self.name)
      end

      local loopLock = 1
      repeat
        for _, p in ipairs(drawTargets) do
          p:drawCards(1, self.name)
        end

        loopLock = loopLock + 1
      until player:getHandcardNum() + (player ~= target and target:getHandcardNum() or 0) >= 7 or loopLock == 20
    elseif discussion.color == "black" then
      room:addPlayerMark(player, "@chushiBuff-round")
    end
  end,
}
local chushiBuff = fk.CreateTriggerSkill{
  name = "#chushi_buff",
  anim_type = "offensive",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@chushiBuff-round") > 0 and data.damageType ~= fk.NormalDamage
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + player:getMark("@chushiBuff-round")
  end,
}
local yinlue = fk.CreateTriggerSkill{
  name = "yinlue",
  anim_type = "support",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    local availableDMGTypes = {fk.ThunderDamage, fk.FireDamage}
    return
      player:hasSkill(self) and
      table.contains(availableDMGTypes, data.damageType) and
      player:getMark("yinlueUsed" .. data.damageType .. "-round") == 0
  end,
  on_cost = function(self, event, target, player, data)
    local damageTypeTable = {
      [fk.FireDamage] = "fire_damage",
      [fk.ThunderDamage] = "thunder_damage",
    }
    local phase =  data.damageType == fk.FireDamage and "phase_draw" or "phase_discard"

    return player.room:askForSkillInvoke(
      player,
      self.name,
      data,
      "#yinlue-ask::" .. data.to.id .. ":" .. damageTypeTable[data.damageType] .. ":" .. phase
    )
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "yinlueUsed".. data.damageType.. "-round", 1)
    if room.logic:getCurrentEvent():findParent(GameEvent.Turn, true) then
      local phase = data.damageType == fk.FireDamage and Player.Draw or Player.Discard
      player:gainAnExtraTurn(true, self.name, { phase_table = { phase } })
    end
    return true
  end,
}
chushi:addRelatedSkill(chushiBuff)
wentian:addRelatedSkill(wentianTrigger)
zhugeliang:addSkill(wentian)
zhugeliang:addSkill(chushi)
zhugeliang:addSkill(yinlue)
Fk:loadTranslationTable{
  ["js__zhugeliang"] = "诸葛亮",
  ["#js__zhugeliang"] = "炎汉忠魂",
  ["illustrator:js__zhugeliang"] = "鬼画府",

  ["wentian"] = "问天",
  ["#wentian_trigger"] = "问天",
  [":wentian"] = "你可以将牌堆顶的牌当【无懈可击】/【火攻】使用，若此牌不为黑色/红色，本技能于本轮内失效；\
  每回合限一次，你的任意阶段开始时，你可以观看牌堆顶五张牌，然后将其中一张牌交给一名其他角色，其余牌以任意顺序置于牌堆顶或牌堆底。",
  ["chushi"] = "出师",
  [":chushi"] = "出牌阶段限一次，你可以和主公议事，若结果为：红色，你与其各摸一张牌，然后重复此摸牌流程，直到你与其手牌之和不小于7\
  （若此主公为你，则改为你重复摸一张牌直到你的手牌数不小于7）；黑色，当你于本轮内造成属性伤害时，此伤害+1。",
  ["yinlue"] = "隐略",
  [":yinlue"] = "每轮每项各限一次，当一名角色受到火焰/雷电伤害时，你可以防止此伤害，然后若此时在一名角色的回合内，\
  你于此回合结束后执行一个仅有摸牌/弃牌阶段的额外回合。",
  ["#wentian-ask"] = "你是否发动技能“问天”（当前为 %arg ）？",
  ["wentian_give"] = "问天给牌",
  ["#wentian-give"] = "问天：请选择其中一张牌交给一名其他角色",
  ["#chushi_buff"] = "出师",
  ["#chushi"] = "出师：你可以和主公议事，红色你与其摸牌，黑色你本轮属性伤害增加",
  ["@chushiBuff-round"] = "出师+",
  ["#yinlue-ask"] = "隐略：你可以防止 %dest 受到的 %arg 伤害，回合结束执行仅有 %arg2 的回合",
}

local jiangwei = General(extension, "js__jiangwei", "shu", 4)
Fk:loadTranslationTable{
  ["js__jiangwei"] = "姜维",
  ["#js__jiangwei"] = "赤血化龙",
  ["illustrator:js__jiangwei"] = "鬼画府",
}

local jinfa = fk.CreateActiveSkill{
  name = "js__jinfa",
  anim_type = "drawcard",
  card_num = 1,
  target_num = 0,
  prompt = "#js__jinfa",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Player.Hand
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local targets = table.filter(room.alive_players, function(p) return not p:isKongcheng() and p.maxHp <= player.maxHp end)

    player:showCards(effect.cards)
    room:delay(1500)

    room:doIndicate(player.id, table.map(targets, Util.IdMapper))
    U.Discussion(player, targets, self.name, { jinfaCard = effect.cards[1] })
  end,
}
local jinfaTrigger = fk.CreateTriggerSkill{
  name = "#js__jinfa_trigger",
  anim_type = "drawcard",
  events = {"fk.DiscussionResultConfirmed"},
  can_trigger = function(self, event, target, player, data)
    return target == player and data.reason == "js__jinfa" and data.extra_data.jinfaCard
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.color == Fk:getCardById(data.extra_data.jinfaCard):getColorString() then
      local toDraw = table.filter(data.tos, function(p) return p:isAlive() and p:getHandcardNum() < p.maxHp end)
      if #toDraw > 0 then
        local result = room:askForChoosePlayers(player, table.map(toDraw, Util.IdMapper), 1, 2, "#js__jinfa-ask", "js__jinfa", false)
        room:sortPlayersByAction(result)
        for _, playerId in ipairs(result) do
          local p = room:getPlayerById(playerId)
          p:drawCards(p.maxHp - p:getHandcardNum(), "js__jinfa")
        end
      end
    else
      room:moveCards({
        ids = getShade(room, 2),
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = "js__jinfa",
        moveVisible = true,
      })
    end

    local hasSameOpinion = false
    for playerId, result in pairs(data.results) do
      if playerId ~= player.id and result.opinion == data.results[player.id].opinion then
        hasSameOpinion = true
        break
      end
    end

    if not hasSameOpinion then
      local kingdoms = {"wei", "shu", "wu", "qun", "jin", "Cancel"}
      local choices = table.simpleClone(kingdoms)
      table.removeOne(choices, player.kingdom)
      local choice = player.room:askForChoice(player, choices, "js__jinfa", "#js__jinfa-change", false, kingdoms)

      if choice ~= "Cancel" then
        room:changeKingdom(player, choice, true)
      end
    end
  end,
}
Fk:loadTranslationTable{
  ["js__jinfa"] = "矜伐",
  ["#js__jinfa_trigger"] = "矜伐",
  [":js__jinfa"] = "出牌阶段限一次，你可以展示一张手牌，然后与体力上限不大于你的所有角色议事，当此议事结果确定后，若结果与你展示牌的颜色：相同，" ..
  "你令至多两名参与议事的角色将手牌摸至体力上限；不同，你获得两张【影】。最后若没有其他角色与你意见相同，则你可变更势力。",
  ["#js__jinfa"] = "矜伐：你可展示一张手牌并议事，结果和展示牌相同则摸牌，不同则获得【影】",
  ["#js__jinfa-ask"] = "矜伐：你可令其中至多两名角色将手牌摸至体力上限",
  ["#js__jinfa-change"] = "矜伐：你可以变更势力",
}

jinfa:addRelatedSkill(jinfaTrigger)
jiangwei:addSkill(jinfa)

local fumouViewas = fk.CreateViewAsSkill{
  name = "#js__fumou_viewas",
  handly_pile = true,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).name == "shade"
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("unexpectation")
    card:addSubcard(cards[1])
    card.skillName = "js__fumou_tag"
    return card
  end,
  before_use = function(self, player, use)
    table.remove(use.card.skillNames, "js__fumou_tag")
    use.card.skillName = "js__fumou"
  end,
}
Fk:addSkill(fumouViewas)
local fumou = fk.CreateTriggerSkill{
  name = "js__fumou",
  anim_type = "offensive",
  events = {"fk.DiscussionFinished"},
  can_trigger = function(self, event, target, player, data)
    if not (player:hasSkill(self) and data.results[player.id]) then
      return false
    end

    for playerId, result in pairs(data.results) do
      if player.room:getPlayerById(playerId):isAlive() and result.opinion ~= data.results[player.id].opinion then
        return true
      end
    end

    return false
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room

    local diffResults = {}
    local diffPlayerIds = {}
    for playerId, result in pairs(data.results) do
      if player.room:getPlayerById(playerId):isAlive() and result.opinion ~= data.results[player.id].opinion then
        diffResults[playerId] = result
        table.insert(diffPlayerIds, playerId)
      end
    end

    room:doIndicate(player.id, diffPlayerIds)

    for playerId, result in pairs(diffResults) do
      if result.opinion ~= "nocolor" then
        local to = room:getPlayerById(playerId)
        room:addTableMark(to, "@js__fumouDebuff-turn", result.opinion)
      end
    end

    room:setPlayerMark(player, "js__fumou_targets", diffPlayerIds)
    local success, dat = player.room:askForUseActiveSkill(player, "#js__fumou_viewas", "#js__fumou-use", true)
    room:setPlayerMark(player, "js__fumou_targets", 0)
    if success then
      local card = Fk.skills["#js__fumou_viewas"]:viewAs(dat.cards)
      room:useCard{
        from = player.id,
        tos = table.map(dat.targets, function(id) return {id} end),
        card = card,
      }
    end
  end,
}
local fumouProhibit = fk.CreateProhibitSkill{
  name = "#js__fumou_prohibit",
  prohibit_use = function(self, player, card)
    return card and table.contains(player:getTableMark("@js__fumouDebuff-turn"), card:getColorString())
  end,
  prohibit_response = function(self, player, card)
    return card and table.contains(player:getTableMark("@js__fumouDebuff-turn"), card:getColorString())
  end,
  is_prohibited = function(self, from, to, card)
    return card and table.contains(card.skillNames, "js__fumou_tag") and not table.contains(from:getTableMark("js__fumou_targets"), to.id)
  end,
}
Fk:loadTranslationTable{
  ["js__fumou"] = "复谋",
  [":js__fumou"] = "魏势力技，当你参与的议事结束后，所有与你意见不同的角色本回合内不能使用或打出其意见颜色的牌，然后" ..
  "你可将一张【影】当【出其不意】对其中一名角色使用。",
  ["@js__fumouDebuff-turn"] = "复谋",
  ["#js__fumou_viewas"] = "复谋",
  ["#js__fumou-use"] = "复谋：你可将一张【影】当【出其不意】对其中一名角色使用",
}

fumou:addRelatedSkill(fumouProhibit)
fumou:addAttachedKingdom("wei")
jiangwei:addSkill(fumou)

local xuanfeng = fk.CreateViewAsSkill{
  name = "js__xuanfeng",
  anim_type = "offensive",
  pattern = "stab__slash",
  prompt = "#js__xuanfeng-viewas",
  handly_pile = true,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).name == "shade"
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("stab__slash")
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
}
local xuanfengBuff = fk.CreateTargetModSkill{
  name = "#js__xuanfeng_buff",
  bypass_times = function(self, player, skill, scope, card, to)
    return card and card.name == "stab__slash" and table.contains(card.skillNames, "js__xuanfeng")
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and card.name == "stab__slash" and table.contains(card.skillNames, "js__xuanfeng")
  end,
}
Fk:loadTranslationTable{
  ["js__xuanfeng"] = "选锋",
  [":js__xuanfeng"] = "蜀势力技，你可以将一张【影】当无距离次数限制的刺【杀】使用。",
  ["#js__xuanfeng-viewas"] = "选锋：你可将一张【影】当无距离次数限制的刺【杀】使用",
}

xuanfeng:addRelatedSkill(xuanfengBuff)
xuanfeng:addAttachedKingdom("shu")
jiangwei:addSkill(xuanfeng)

local liuyong = General(extension, "js__liuyong", "shu", 3)
local js__danxinn = fk.CreateActiveSkill{
  name = "js__danxinn",
  anim_type = "control",
  card_num = 1,
  min_target_num = 1,
  can_use = function(self, player)
    return not player:isNude()
  end,
  card_filter = function(self, to_select, selected, player)
    if #selected == 0 then
      local c = Fk:cloneCard("sincere_treat")
      c.skillName = self.name
      c:addSubcard(to_select)
      return player:canUse(c) and not player:prohibitUse(c)
    end
  end,
  target_filter = function(self, to_select, selected, selected_cards, _, _, player)
    if #selected_cards ~= 1 then return false end
    local c = Fk:cloneCard("sincere_treat")
    c.skillName = self.name
    c:addSubcards(selected_cards)
    return c.skill:targetFilter(to_select, selected, selected_cards, c, nil, player) and
    not player:isProhibited(Fk:currentRoom():getPlayerById(to_select), c)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local c = Fk:cloneCard("sincere_treat")
    c.skillName = self.name
    c:addSubcards(effect.cards)
    local use = {
      from = player.id,
      tos = table.map(effect.tos, function (id) return {id} end),
      card = c,
      extra_data = {js__danxinn_user = player.id},
    }
    room:useCard(use)
    if player.dead then return end
    for _, pid in ipairs(TargetGroup:getRealTargets(use.tos)) do
      local p = room:getPlayerById(pid)
      if not p.dead then
        room:addPlayerMark(p, "js__danxinn_"..player.id.."-turn")
      end
    end
  end,
}
local js__danxinn_delay = fk.CreateTriggerSkill{
  name = "#js__danxinn_delay",
  events = {fk.AfterCardsMove},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    local e = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
    if e then
      local use = e.data[1]
      if table.contains(use.card.skillNames, "js__danxinn") then
        local ids = {}
        for _, move in ipairs(data) do
          if move.toArea == Card.PlayerHand and move.to == player.id then
            for _, info in ipairs(move.moveInfo) do
              if table.contains(player:getCardIds("h"), info.cardId) then
                table.insertIfNeed(ids, info.cardId)
              end
            end
          end
        end
        if #ids > 0 then
          self.cost_data = ids
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = self.cost_data
    local e = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
    if e then
      local use = e.data[1]
      local me = room:getPlayerById(use.extra_data.js__danxinn_user)
      me:showCards(ids)
      if not player.dead and player:isWounded() and table.find(ids, function (id)
        return Fk:getCardById(id).suit == Card.Heart
      end) then
        room:recover { num = 1, skillName = self.name, who = player, recoverBy = me}
      end
    end
  end,
}
local js__danxinn_distance = fk.CreateDistanceSkill{
  name = "#js__danxinn_distance",
  correct_func = function(self, from, to)
    return to:getMark("js__danxinn_"..from.id.."-turn")
  end,
}
js__danxinn:addRelatedSkill(js__danxinn_distance)
js__danxinn:addRelatedSkill(js__danxinn_delay)
liuyong:addSkill(js__danxinn)
local js__fengxiang = fk.CreateTriggerSkill{
  name = "js__fengxiang",
  events = {fk.Damaged},
  frequency = Skill.Compulsory,
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(self) and #player.room.alive_players > 1
    and table.find(player.room.alive_players, function(p) return #p:getCardIds("e") > 0 end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = player.room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player, false), Util.IdMapper), 1, 1, "#js__fengxiang-choose", self.name, false)
    if #tos > 0 then
      local to = room:getPlayerById(tos[1])
      local num = 0
      local cards1 = player:getCardIds("e")
      local cards2 = to:getCardIds("e")
      local moveInfos = {}
      if #cards1 > 0 then
        table.insert(moveInfos, {
          from = player.id,
          ids = cards1,
          toArea = Card.Processing,
          moveReason = fk.ReasonExchange,
          proposer = player.id,
          skillName = self.name,
        })
      end
      if #cards2 > 0 then
        table.insert(moveInfos, {
          from = to.id,
          ids = cards2,
          toArea = Card.Processing,
          moveReason = fk.ReasonExchange,
          proposer = player.id,
          skillName = self.name,
        })
      end
      if #moveInfos > 0 then
        room:moveCards(table.unpack(moveInfos))
      end

      moveInfos = {}

      if not to.dead then
        local to_ex_cards1 = table.filter(cards1, function (id)
          return room:getCardArea(id) == Card.Processing and to:getEquipment(Fk:getCardById(id).sub_type) == nil
        end)
        if #to_ex_cards1 > 0 then
          table.insert(moveInfos, {
            ids = to_ex_cards1,
            fromArea = Card.Processing,
            to = to.id,
            toArea = Card.PlayerEquip,
            moveReason = fk.ReasonExchange,
            proposer = player.id,
            skillName = self.name,
          })
        end
      end
      if not player.dead then
        local to_ex_cards = table.filter(cards2, function (id)
          return room:getCardArea(id) == Card.Processing and player:getEquipment(Fk:getCardById(id).sub_type) == nil
        end)
        num = #cards1 - #to_ex_cards
        if #to_ex_cards > 0 then
          table.insert(moveInfos, {
            ids = to_ex_cards,
            fromArea = Card.Processing,
            to = player.id,
            toArea = Card.PlayerEquip,
            moveReason = fk.ReasonExchange,
            proposer = player.id,
            skillName = self.name,
          })
        end
      end
      if #moveInfos > 0 then
        room:moveCards(table.unpack(moveInfos))
      end

      if not player.dead then
        if num > 0 then
          player:drawCards(num, self.name)
        end
      end
    end
  end,
}
liuyong:addSkill(js__fengxiang)
Fk:loadTranslationTable{
  ["js__liuyong"] = "刘永",
  ["#js__liuyong"] = "甘陵王",
  ["designer:js__liuyong"] = "山巅隐士",
  ["illustrator:js__liuyong"] = "君桓文化",
  ["js__danxinn"] = "丹心",
  [":js__danxinn"] = "你可以将一张牌当做【推心置腹】使用，你须展示获得和给出的牌，以此法得到<font color='red'>♥</font>牌的角色回复1点体力，"..
  "此牌结算后，本回合内你计算与此牌目标的距离+1。",
  ["#js__danxinn_delay"] = "丹心",
  ["js__fengxiang"] = "封乡",
  [":js__fengxiang"] = "锁定技，当你受到伤害后，你须与一名其他角色交换装备区内的所有牌，若你装备区内的牌数因此而减少，你摸等同于减少数的牌。",
  ["#js__fengxiang-choose"] = "封乡：与一名其他角色交换装备区内的所有牌",
}

local guoxun = General(extension, "js__guoxiu", "wei", 4)
guoxun.total_hidden = true
local eqian = fk.CreateTriggerSkill{
  name = "eqian",
  anim_type = "control",
  events = {fk.EventPhaseStart, fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.EventPhaseStart then
        return player.phase == Player.Finish and not player:isKongcheng() and not table.contains(player.sealedSlots, Player.JudgeSlot)
      else
        return (data.card.trueName == "slash" or (data.extra_data and data.extra_data.premeditate)) and
          #AimGroup:getAllTargets(data.tos) == 1 and data.to ~= player.id
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      local cards = room:askForCard(player, 1, 1, false, self.name, true, "", "#eqian-put")
      if #cards > 0 then
        self.cost_data = cards[1]
        return true
      end
    else
      return room:askForSkillInvoke(player, self.name, nil, "#eqian-invoke:::"..data.card:toLogString())
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      premeditate(player, self.cost_data, self.name, player.id)
      while not player:isKongcheng() and not player.dead and not table.contains(player.sealedSlots, Player.JudgeSlot) do
        local cards = room:askForCard(player, 1, 1, false, self.name, true, "", "#eqian-put")
        if #cards > 0 then
          premeditate(player, cards[1], self.name, player.id)
        else
          return
        end
      end
    else
      data.extraUse = true
      player:addCardUseHistory(data.card.trueName, -1)
      local to = room:getPlayerById(data.to)
      if not to.dead and not to:isNude() then
        local card = room:askForCardChosen(player, to, "he", self.name, "#eqian-prey::"..to.id)
        room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, self.name, "", false, player.id)
        if not to.dead and room:askForSkillInvoke(to, self.name, nil, "#eqian-distance:"..player.id) then
          room:addPlayerMark(to, "@eqian-turn", 2)
        end
      end
    end
  end,
}
local eqian_distance = fk.CreateDistanceSkill{
  name = "#eqian_distance",
  correct_func = function(self, from, to)
    if from.phase ~= Player.NotActive then
      return to:getMark("@eqian-turn")
    end
    return 0
  end,
}
local fusha = fk.CreateActiveSkill{
  name = "fusha",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = function()
    return "#fusha-prompt:::"..math.min(Self:getAttackRange(), #Fk:currentRoom().players)
  end,
  card_filter = Util.FalseFunc,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      #table.filter(Fk:currentRoom().alive_players, function(p) return player:inMyAttackRange(p) end) == 1
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and Self:inMyAttackRange(Fk:currentRoom():getPlayerById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:damage{
      from = player,
      to = target,
      damage = math.min(player:getAttackRange(), #room.players),
      skillName = self.name,
    }
  end
}
eqian:addRelatedSkill(eqian_distance)
guoxun:addSkill(eqian)
guoxun:addSkill(fusha)
Fk:loadTranslationTable{
  ["js__guoxiu"] = "郭循",
  ["#js__guoxiu"] = "秉心不回",
  ["illustrator:js__guoxiu"] = "鬼画府",

  ["eqian"] = "遏前",
  [":eqian"] = "结束阶段，你可以“蓄谋”任意次；当你使用【杀】或“蓄谋”牌指定其他角色为唯一目标后，你可以令此牌不计入次数限制且获得目标一张牌，"..
  "然后目标可以令你本回合计算与其的距离+2。"..
  "<br/><font color='grey'>#<b>蓄谋</b>：将一张手牌扣置于判定区，判定阶段开始时，按置入顺序（后置入的先处理）依次处理“蓄谋”牌：1.使用此牌，"..
  "然后此阶段不能再使用此牌名的牌；2.将所有“蓄谋”牌置入弃牌堆。",
  ["fusha"] = "伏杀",
  [":fusha"] = "限定技，出牌阶段，若你的攻击范围内仅有一名角色，你可以对其造成X点伤害（X为你的攻击范围且至多为游戏人数）。",
  ["#eqian-put"] = "遏前：你可以“蓄谋”任意次，将一张手牌作为“蓄谋”牌扣置于判定区",
  ["#eqian-invoke"] = "遏前：你可以令此%arg不计次数，并获得目标一张牌",
  ["#eqian-prey"] = "遏前：获得 %dest 一张牌",
  ["#eqian-distance"] = "遏前：是否令 %src 本回合与你距离+2？",
  ["@eqian-turn"] = "遏前",
  ["#fusha-prompt"] = "伏杀：对一名角色造成%arg点伤害！",
}

local zhaoyun = General(extension, "js__zhaoyun", "shu", 4)
local longlin = fk.CreateTriggerSkill{
  name = "longlin",
  anim_type = "offensive",
  events ={fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if
      player:hasSkill(self) and
      target ~= player and
      target.phase == Player.Play and
      data.card.trueName == "slash" and
      data.firstTarget and
      not player:isNude()
    then
      local room = player.room
      local logic = room.logic

      local mark = player:getMark("longlin_record-phase")
      if mark == 0 then
        logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
          local use = e.data[1]
          if use.card.trueName == "slash" and use.from == target.id then
            mark = e.id
            room:setPlayerMark(player, "longlin_record-phase", mark)
            return true
          end
          return false
        end, Player.HistoryPhase)
      end

      return mark == logic:getCurrentEvent().id
    end

    return false
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, nil, "#longlin-invoke::"..data.from..":"..data.card:toLogString(), true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(data.from)
    room:throwCard(self.cost_data, self.name, player, player)
    data.nullifiedTargets = table.map(room.players, Util.IdMapper)
    if not target:isProhibited(player, Fk:cloneCard("duel")) and room:askForSkillInvoke(from, self.name, nil, "#longlin-duel::"..player.id) then
      room:useVirtualCard("duel", nil, target, player, self.name, true)
    end
  end,
    refresh_events = {fk.Damage},
    can_refresh = function(self, event, target, player, data)
      return player:hasSkill(self, true) and data.card and data.card.trueName == "duel" and data.to ~= player and not data.to.dead and table.contains(data.card.skillNames, self.name)
    end,
    on_refresh = function(self, event, target, player, data)
      player.room:setPlayerMark(data.to, "@@longlin-phase", 1)
    end,
}
local longlin_prohibit = fk.CreateProhibitSkill{
  name = "#longlin_prohibit",
  prohibit_use = function(self, player, card)
    if player:getMark("@@longlin-phase") > 0 then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds(Player.Hand), id)
      end)
    end
  end,
}
local zhendan = fk.CreateViewAsSkill{
  name = "zhendan",
  pattern = ".|.|.|.|.|basic",
  prompt = "#zhendan_vies",
  interaction = function()
    local all_names = U.getAllCardNames("b")
    local names = U.getViewAsCardNames(Self, "zhendan", all_names)
    if #names > 0 then
      return U.CardNameBox { choices = names, all_choices = all_names }
    end
  end,
  card_filter = function(self, to_select, selected)
    if #selected == 1 then return false end
    local card = Fk:getCardById(to_select)
    return card.type ~= Card.TypeBasic and Fk:currentRoom():getCardArea(to_select) == Player.Hand
  end,
  view_as = function(self, cards)
    if not self.interaction.data then return end
    if #cards ~= 1 then
      return nil
    end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = self.name
    return card
  end,
  enabled_at_play = Util.TrueFunc,
  enabled_at_response = Util.TrueFunc,
}
local zhendan_trigger = fk.CreateTriggerSkill{
  name = "#zhendan_trigger",
  anim_type = "masochism",
  main_skill = zhendan,
  mute = true,
  events = {fk.Damaged, fk.RoundEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhendan) and not (event == fk.Damaged and target ~= player)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("zhendan")
    room:notifySkillInvoked(player, "zhendan", "masochism")
    local num = #room.logic:getEventsOfScope(GameEvent.Turn, 99, function (e)
      return true
    end, Player.HistoryRound)
    player:drawCards(math.min(num, 5), "zhendan")
    room:invalidateSkill(player, "zhendan", "-round")
  end,
}
longlin:addRelatedSkill(longlin_prohibit)
zhendan:addRelatedSkill(zhendan_trigger)
zhaoyun:addSkill(longlin)
zhaoyun:addSkill(zhendan)
Fk:loadTranslationTable{
  ["js__zhaoyun"] = "赵云",
  ["#js__zhaoyun"] = "北伐之柱",
  ["illustrator:js__zhaoyun"] = "鬼画府",
  ["longlin"] = "龙临",
  [":longlin"] = "当其他角色于其出牌阶段内首次使用【杀】指定目标后，你可以弃置一张牌令此【杀】无效，然后其可以视为对你使用一张【决斗】，你以此法造成伤害后，其本阶段不能再使用手牌。",
  ["#longlin-invoke"] = "龙临:是否弃置一张牌，令%dest 使用的%arg 无效，然后其可以视为对你使用一张【决斗】 ",
  ["#longlin-duel"] = "龙临:是否对%dest 视为使用一张【决斗】",
  ["zhendan"] = "镇胆",
  ["#zhendan_trigger"] = "镇胆",
  [":zhendan"] = "你可以将一张非基本手牌当做任意基本牌使用或打出；当你受到伤害后或每轮结束时，你摸X张牌，然后此技能本轮失效（X为本轮所有角色执行过的回合数且至多为5）。",
  ["#zhendan_vies"] = "镇胆:你可以将一张非基本牌当做一张基本牌使用或打出",
  ["@@longlin-phase"] = "龙临 禁用手牌",
}

local caofang = General(extension, "js__caofang", "wei", 3, 4)
local zhaotu = fk.CreateViewAsSkill{
  name = "zhaotu",
  anim_type = "control",
  pattern = "indulgence",
  prompt = "#zhaotu",
  card_filter = function(self, to_select, selected)
    if #selected == 1 then return false end
    local card = Fk:getCardById(to_select)
    return card.color == Card.Red and card.type ~= Card.TypeTrick
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then
      return nil
    end
    local c = Fk:cloneCard("indulgence")
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
}
local zhaotu_trigger = fk.CreateTriggerSkill{
  name = "#zhaotu_trigger",
  anim_type = "offensive",
  mute = true,
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "indulgence" and #AimGroup:getAllTargets(data.tos) == 1 and table.contains(data.card.skillNames, "zhaotu")
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(AimGroup:getAllTargets(data.tos)[1])
    room:setPlayerMark(to, "@@zhaotu", 1)
    to:gainAnExtraTurn(true, "zhaotu")
  end,

  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target:getMark("@@zhaotu") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(target, "@@zhaotu", 0)
    room:setPlayerMark(target, "@@zhaotu-turn", 1)
  end,
}
local zhaotu_maxcards = fk.CreateMaxCardsSkill {
  name = "#zhaotu_maxcards",
  correct_func = function(self, player)
    if player:getMark("@@zhaotu-turn") ~= 0 then
      return -2
    else
      return 0
    end
  end,
}
zhaotu:addRelatedSkill(zhaotu_maxcards)
zhaotu:addRelatedSkill(zhaotu_trigger)
local jingju = fk.CreateViewAsSkill{
  name = "jingju",
  pattern = ".|.|.|.|.|basic",
  interaction = function(self)
    local all_names = U.getAllCardNames("b")
    local names = U.getViewAsCardNames(Self, self.name, all_names)
    return U.CardNameBox {choices = names, all_choices = all_names}
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player)
    local room = player.room
    local targets = table.map(table.filter(player.room:getOtherPlayers(player, false), function(p)
      return p:canMoveCardsInBoardTo(player, "j") end), Util.IdMapper)
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#jingju-choose", self.name, false)
    local to = room:getPlayerById(tos[1])
    if to then
      room:askForMoveCardInBoard(player, to, player, self.name, "j", to)
    end
  end,
  enabled_at_play = function(self, player)
    return table.find(Fk:currentRoom().alive_players, function(p) return p:canMoveCardsInBoardTo(player, "j") end)
  end,
  enabled_at_response = function(self, player, response)
    return not response and
      table.find(Fk:currentRoom().alive_players, function(p) return p:canMoveCardsInBoardTo(player, "j") end)
  end,
}

local weizhui = fk.CreateTriggerSkill{
  name = "weizhui$",
  events = {fk.EventPhaseStart},
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player ~= target and target.phase == Player.Finish and not player:isAllNude()
    and not target:isNude() and target.kingdom == "wei"
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cardIds = table.filter(target:getCardIds("he"), function (id)
      if Fk:getCardById(id).color ~= Card.Black then return false end
      local c = Fk:cloneCard("dismantlement")
      c.skillName = self.name
      c:addSubcard(id)
      return target:canUseTo(c, player)
    end)
    if #cardIds == 0 then return end
    local card = room:askForCard(target, 1, 1, true, self.name, true, tostring(Exppattern{ id = cardIds }), "#weizhui-use:"..player.id)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useVirtualCard("dismantlement", self.cost_data, target, player, self.name, true)
  end,
}
caofang:addSkill(zhaotu)
caofang:addSkill(jingju)
caofang:addSkill(weizhui)
Fk:loadTranslationTable{
  ["js__caofang"] = "曹芳",
  ["#js__caofang"] = "引狼入廟",
  ["cv:js__caofang"] = "甄弦",
  ["illustrator:js__caofang"] = "鬼画府",
  ["zhaotu"] = "招图",
  [":zhaotu"] = "每轮限一次，你可以将一张红色非锦囊牌当做【乐不思蜀】使用，此回合结束后，目标执行一个手牌上限-2的回合。",
  ["#zhaotu"] = "招图：你可以将一张红色非锦囊牌当做【乐不思蜀】使用",
  ["@@zhaotu"] = "招图",
  ["@@zhaotu-turn"] = "招图",
  ["jingju"] = "惊惧",
  [":jingju"] = "你可以将其他角色判定区里的一张牌移至你的判定区里，视为你使用一张基本牌。",
  ["#jingju-choose"] = "惊惧：请选择你要移动判定区牌的角色",
  ["weizhui"] = "危坠",
  [":weizhui"] = "主公技，其他魏势力角色的结束阶段，其可以将一张黑色牌当做【过河拆桥】对你使用。",
  ["#weizhui-use"] = "危坠：你可以将一张黑色牌当【过河拆桥】对 %src 使用",
  ["weizhui_active"] = "危坠",

  ["$zhaotu1"] = "卿持此诏，惟盈惟谨，勿蹈山阳公覆辙。",
  ["$zhaotu2"] = "司马师觑百官如草芥，社稷早晚必归此人。",
  ["$jingju1"] = "朕有罪…求大将军饶恕…",
  ["$jingju2"] = "朕本无此心、绝无此心！",
  ["$weizhui1"] = "大魏高楼百尺，竟无一栋梁。",
  ["$weizhui2"] = "高飞入危云，簌簌兮如坠。",
  ["~js__caofang"] = "报应不爽，司马家亦有今日。",
}

local simayi = General(extension, "js__simayi", "wei", 4)
local yingshi = fk.CreateTriggerSkill{
  name = "js__yingshi",
  anim_type = "control",
  events = {fk.TurnedOver},
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = #table.filter(room.players, function(p) return p.dead end)
    local num = 3
    if n > 2 then num = 5 end
    local cards = room:getNCards(num, "bottom")
    local ret = room:askForArrangeCards(player, self.name, {{}, cards, "Top", "Bottom"}, "", true, 0, {num, num}, {0, 0})
    local top, bottom = ret[1], ret[2]
    for i = #top, 1, -1 do
      table.removeOne(room.draw_pile, top[i])
      table.insert(room.draw_pile, 1, top[i])
    end
    for i = 1, #bottom, 1 do
      table.removeOne(room.draw_pile, bottom[i])
      table.insert(room.draw_pile, bottom[i])
    end
    room:sendLog{
      type = "#GuanxingResult",
      from = player.id,
      arg = #top,
      arg2 = #bottom,
    }
  end,
}
local tuigu = fk.CreateTriggerSkill{
  name = "tuigu",
  mute = true,
  events = {fk.TurnStart},
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local draw = #room.alive_players // 2
    return room:askForSkillInvoke(player, self.name, nil, "#tuigu-invoke:::"..tostring(draw))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name, math.random(2))
    room:notifySkillInvoked(player, self.name, "drawcard")
    player:turnOver()
    if player.dead then return false end
    local n = #room.alive_players // 2
    room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, n)
    room:drawCards(player, n, self.name)
    if player.dead then return false end
    U.askForUseVirtualCard(room, player, "demobilized", nil, self.name, "#tuigu-jiejia", false)
  end,

  refresh_events = {fk.AfterCardsMove, fk.AfterTurnEnd},
  can_refresh = function(self, event, target, player, data)
    if event == fk.AfterCardsMove then
      return true
    elseif event == fk.AfterTurnEnd then
      return player == target
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.AfterCardsMove then
      local room = player.room
      local cards = {}
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Card.PlayerHand and move.skillName == "demobilized" then
          for _, info in ipairs(move.moveInfo) do
            local id = info.cardId
            if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player then
              table.insertIfNeed(cards, id)
            end
          end
        end
      end
      if #cards == 0 then return false end
      local cardEffectData = room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
      if cardEffectData then
        local cardEffectEvent = cardEffectData.data[1]
        if table.contains(cardEffectEvent.card.skillNames, "tuigu") then
          for _, id in ipairs(cards) do
            room:setCardMark(Fk:getCardById(id), "@@tuigu-inhand", 1)
          end
        end
      end
    elseif event == fk.AfterTurnEnd then
      U.clearHandMark(player, "@@tuigu-inhand")
    end
  end,
}
local tuigu_recoverAndTurn = fk.CreateTriggerSkill{
  name = "#tuigu_recoverAndTurn",
  anim_type = "control",
  main_skill = tuigu,
  mute = true,
  events = {fk.AfterCardsMove, fk.RoundEnd},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(tuigu) then return false end
    if event == fk.AfterCardsMove then
      if not player:isWounded() then return false end
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    elseif event == fk.RoundEnd then
      return #player.room.logic:getEventsOfScope(GameEvent.Turn, 1, function (e)
        return e.data[1] == player
      end, Player.HistoryRound) == 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.RoundEnd then
      player:broadcastSkillInvoke("tuigu", math.random(3,5))
      room:notifySkillInvoked(player, "tuigu", "control")
      player:gainAnExtraTurn(true, "tuigu")
    else
      room:notifySkillInvoked(player, "tuigu", "defensive")
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = tuigu.name
      })
    end
  end,
}
local tuigu_prohibit = fk.CreateProhibitSkill{
  name = "#tuigu_prohibit",
  prohibit_use = function(self, player, card)
    local cardList = card:isVirtual() and card.subcards or {card.id}
    return table.find(cardList, function (id) return Fk:getCardById(id):getMark("@@tuigu-inhand") > 0 end)
  end,
}
tuigu:addRelatedSkill(tuigu_recoverAndTurn)
tuigu:addRelatedSkill(tuigu_prohibit)
simayi:addSkill(yingshi)
simayi:addSkill(tuigu)
Fk:loadTranslationTable{
  ["js__simayi"] = "司马懿",
  ["#js__simayi"] = "危崖隐羽",
  ["cv:js__simayi"] = "寂镜",
  ["illustrator:js__simayi"] = "鬼画府",

  ["js__yingshi"] = "鹰视",
  [":js__yingshi"] = "当你翻面后，你可以观看牌堆底的三张牌（若场上阵亡角色数大于2则改为五张），" ..
  "然后将其中任意牌以任意顺序放置牌堆顶，其余牌以任意顺序放置牌堆底。",
  ["tuigu"] = "蜕骨",
  [":tuigu"] = "回合开始时，你可以翻面令你本回合手牌上限+X，然后摸X张牌并视为使用一张【解甲归田】（目标角色不能使用这些装备牌直到其回合结束，X为场上角色数的一半，向下取整）；每轮结束时，若你本轮未行动过，你执行一个额外的回合；当你失去装备区里的牌后，你回复一点体力。",
  ["#tuigu-invoke"] = "蜕骨：你可以将武将牌翻面，令本回合手牌上限+%arg ，然后摸 %arg 张牌",
  ["#tuigu-jiejia"] = "蜕骨：选择你使用【解甲归田】的目标（令其收回装备区所有牌）",
  ["@@tuigu-inhand"] = "蜕骨",

  ["$js__yingshi1"] = "亮志大而不见机，已堕吾画中。",
  ["$js__yingshi2"] = "贼偏执一端不能察变，破之必矣。",
  ["$tuigu1"] = "臣老年虚乏，唯愿乞骸骨。",
  ["$tuigu2"] = "今指水为誓，若有相违，天弃之！",
  ["$tuigu3"] = "汉室世衰，天命在曹；曹氏世衰，天命归我。",
  ["$tuigu4"] = "天时已至而犹谦让，舜禹所不为也。",
  ["$tuigu5"] = "皇天眷我，神人同谋，当取此天下。",
  ["~js__simayi"] = "天下汹汹，我当何去何从……",
}

local guozhao = General(extension, "js__guozhao", "wei", 3, 3, General.Female)
local js__pianchong = fk.CreateTriggerSkill{
  name = "js__pianchong",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target.phase == Player.Finish then
      local room = player.room
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, false)
      if turn_event == nil then return false end
      local end_id = turn_event.id
      return #room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.from == player.id then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                return true
              end
            end
          end
        end
        return false
      end, end_id) > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".|.|^nosuit",
    }
    room:judge(judge)
    local color = judge.card.color
    if color == Card.NoColor then return false end
    local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, false)
    if turn_event == nil then return false end
    local end_id = turn_event.id
    local cards = {}
    room.logic:getEventsByRule(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if room:getCardArea(info.cardId) == Card.DiscardPile and Fk:getCardById(info.cardId).color == color then
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
      end
      return false
    end, end_id)
    local x = #cards
    if x > 0 then
      room:drawCards(player, x, self.name)
    end
  end,
}
local js__zunwei = fk.CreateActiveSkill{
  name = "js__zunwei",
  anim_type = "control",
  prompt = "#js__zunwei-active",
  dynamic_desc = function(self, player)
    local texts = {"js__zunwei_inner", "", "js__zunwei_choice1", "", "js__zunwei_choice2", "", "js__zunwei_choice3"}
    local x = 0
    for i = 1, 3, 1 do
      if player:getMark(self.name .. tostring(i)) > 0 then
        texts[2 * i] = "js__zunwei_color"
        x = x + 1
      end
    end
    return (x == 3) and "dummyskill" or table.concat(texts, ":")
  end,
  card_num = 0,
  target_num = 1,
  interaction = function()
    local choices, all_choices = {}, {}
    for i = 1, 3 do
      local choice = "js__zunwei"..tostring(i)
      table.insert(all_choices, choice)
      if Self:getMark(choice) == 0 then
        table.insert(choices, choice)
      end
    end
    return UI.ComboBox {choices = choices, all_choices = all_choices}
  end,
  can_use = function(self, player)
    if player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 then
      for i = 1, 3, 1 do
        if player:getMark(self.name .. tostring(i)) == 0 then
          return true
        end
      end
    end
    return false
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return self.interaction.data and #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local choice = self.interaction.data
    if choice == "js__zunwei1" then
      local x = math.min(target:getHandcardNum() - player:getHandcardNum(), 5)
      if x > 0 then
        room:drawCards(player, x, self.name)
      end
    elseif choice == "js__zunwei2" then
      while not (player.dead or target.dead) and
      #player.player_cards[Player.Equip] <= #target.player_cards[Player.Equip] and
      target:canMoveCardsInBoardTo(player, "e") do
        room:askForMoveCardInBoard(player, target, player, self.name, "e", target)
      end
    elseif choice == "js__zunwei3" and player:isWounded() then
      local x = target.hp - player.hp
      if x > 0 then
      room:recover{
        who = player,
        num = math.min(player:getLostHp(), x),
        recoverBy = player,
        skillName = self.name}
      end
    end
    room:setPlayerMark(player, choice, 1)
  end,

  on_lose = function (self, player, is_death)
    local room = player.room
    room:setPlayerMark(player, "js__zunwei1", 0)
    room:setPlayerMark(player, "js__zunwei2", 0)
    room:setPlayerMark(player, "js__zunwei3", 0)
  end,
}
guozhao:addSkill(js__pianchong)
guozhao:addSkill(js__zunwei)
Fk:loadTranslationTable{
  ["js__guozhao"] = "郭照",
  ["#js__guozhao"] = "碧海青天",
  ["illustrator:js__guozhao"] = "君桓文化", -- 传说皮：烟缈媚眸
  ["js__pianchong"] = "偏宠",
  [":js__pianchong"] = "一名角色的结束阶段，若你于此回合内失去过牌，你可以判定，"..
  "你摸X张牌（X为弃牌堆里于此回合内移至此区域的与判定结果颜色相同的牌数）。",
  ["js__zunwei"] = "尊位",
  [":js__zunwei"] = "出牌阶段限一次，你可以选择一名其他角色，并选择执行以下一个选项，然后移除该选项："..
  "1.将手牌补至与其手牌数相同（至多摸五张）；"..
  "2.将其装备里的牌移至你的装备区，直到你装备区里的牌数不小于其装备区里的牌数；"..
  "3.将体力值回复至与其相同。",

  [":js__zunwei_inner"] = "出牌阶段限一次，你可以选择一名其他角色，并选择执行以下一个选项，然后移除该选项：{1}{2}{3}{4}{5}{6}。",
  ["js__zunwei_choice1"] = "1.将手牌补至与其手牌数相同（至多摸五张）；</font>",
  ["js__zunwei_choice2"] = "2.将其装备里的牌移至你的装备区，直到你装备区里的牌数不小于其装备区里的牌数；</font>",
  ["js__zunwei_choice3"] = "3.将体力值回复至与其相同</font>",

  [":dummyskill"] = "无效果。",
  ["js__zunwei_color"] = "<font color='gray'>",

  ["#js__zunwei-active"] = "发动 尊位，选择一名其他角色并执行一项效果",
  ["js__zunwei1"] = "将手牌摸至与其相同（最多摸五张）",
  ["js__zunwei2"] = "移动其装备至你的装备区直到比你少",
  ["js__zunwei3"] = "回复体力至与其相同",

  ["$js__pianchong1"] = "承君恩露于椒房，得君恩宠于万世。",
  ["$js__pianchong2"] = "后宫有佳丽三千，然陛下独宠我一人。",
  ["$js__zunwei1"] = "妾蒲柳之姿，幸蒙君恩方化从龙之凤。",
  ["$js__zunwei2"] = "尊位椒房、垂立九五，君之恩也、妾之幸也。",
  ["~js__guozhao"] = "曹元仲，你为何害我？",
}

local luxun = General(extension, "js__luxun", "wu", 3)
local js__youjin = fk.CreateTriggerSkill{
  name = "js__youjin",
  events = {fk.EventPhaseStart},
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player == target and player.phase == Player.Play and not player:isKongcheng()
    and table.find(player.room.alive_players, function (p) return player:canPindian(p) end)
  end,
  on_cost = function (self, event, target, player, data)
    local targets = table.filter(player.room.alive_players, function (p) return player:canPindian(p) end)
    local tos = player.room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#js__youjin-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local pindian = player:pindian({to}, self.name)
    local winner = pindian.results[to.id].winner
    local fromNum = pindian.fromCard.number
    if fromNum > 0 and not player.dead then
      fromNum = math.max(fromNum, player:getMark("@js__youjin-turn"))
      room:setPlayerMark(player, "@js__youjin-turn", fromNum)
    end
    local toNum = pindian.results[to.id].toCard.number
    if toNum > 0 and not to.dead then
      fromNum = math.max(toNum, to:getMark("@js__youjin-turn"))
      room:setPlayerMark(to, "@js__youjin-turn", toNum)
    end
    if winner and not winner.dead then
      local loser = (winner == player) and to or player
      if not loser.dead then
        room:useVirtualCard("slash", nil, winner, loser, self.name, true)
      end
    end
  end,
}
local js__youjin_prohibit = fk.CreateProhibitSkill{
  name = "#js__youjin_prohibit",
  prohibit_use = function(self, player, card)
    local mark = player:getMark("@js__youjin-turn")
    if mark ~= 0 and card and card.number > 0 and card.number < mark then
      local cards = card:isVirtual() and card.subcards or {card.id}
      return #cards > 0 and table.every(cards, function(id)
        return table.contains(player.player_cards[Player.Hand], id)
      end)
    end
  end,
  prohibit_response = function(self, player, card)
    local mark = player:getMark("@js__youjin-turn")
    if mark ~= 0 and card and card.number > 0 and card.number < mark then
      local cards = card:isVirtual() and card.subcards or {card.id}
      return #cards > 0 and table.every(cards, function(id)
        return table.contains(player.player_cards[Player.Hand], id)
      end)
    end
  end,
}
js__youjin:addRelatedSkill(js__youjin_prohibit)
luxun:addSkill(js__youjin)
local js__dailao = fk.CreateActiveSkill{
  name = "js__dailao",
  anim_type = "drawcard",
  can_use = function(self, player)
    return not player:isKongcheng() and table.every(player:getCardIds("h"), function (id)
      local card = Fk:getCardById(id)
      return player:prohibitUse(card) or not player:canUse(card)
      or not table.find(Fk:currentRoom().alive_players, function (p)
        return not player:isProhibited(p, card) and card.skill:modTargetFilter(p.id, {}, player, card, true)
      end)
    end)
  end,
  target_num = 0,
  card_num = 0,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    player:showCards(player:getCardIds("h"))
    player:drawCards(2, self.name)
    room:endTurn()
  end,
}
luxun:addSkill(js__dailao)
local js__zhubei = fk.CreateTriggerSkill{
  name = "js__zhubei",
  anim_type = "offensive",
  events = {fk.DamageCaused},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      #player.room.logic:getActualDamageEvents(2, function(e)
        return e.data[1].to == data.to
      end) > 0
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function (self, event, target, player, data)
    if player:getMark("js__zhubei_lost-turn") == 0 and player:isKongcheng() then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "js__zhubei_lost-turn", 1)
  end,
}
local js__zhubei_targetmod = fk.CreateTargetModSkill{
  name = "#js__zhubei_targetmod",
  bypass_times = function (self, player, skill, scope, card, to)
    return card and player:hasSkill("js__zhubei") and to and to:getMark("js__zhubei_lost-turn") > 0
  end,
}
js__zhubei:addRelatedSkill(js__zhubei_targetmod)
luxun:addSkill(js__zhubei)
Fk:loadTranslationTable{
  ["js__luxun"] = "陆逊",
  ["#js__luxun"] = "却敌安疆",
  ["illustrator:js__luxun"] = "鬼画府",
  ["js__youjin"] = "诱进",
  [":js__youjin"] = "出牌阶段开始时，你可以与一名角色拼点，双方本回合不能使用或打出点数小于各自拼点牌的手牌，赢的角色视为对没赢的角色使用一张【杀】。",
  ["#js__youjin-choose"] = "诱进：可以拼点，双方不能使用或打出点数小于各自拼点牌的手牌，赢的角色视为对对方使用【杀】",
  ["@js__youjin-turn"] = "诱进",
  ["js__dailao"] = "待劳",
  [":js__dailao"] = "出牌阶段，若你没有可以使用的手牌，你可以展示所有手牌并摸两张牌，然后结束回合。",
  ["js__zhubei"] = "逐北",
  [":js__zhubei"] = "锁定技，你对本回合受到过伤害/失去过最后手牌的角色造成的伤害+1/使用牌无次数限制。",
}

local sunjun = General(extension, "js__sunjun", "wu", 4)
local yaoyan = fk.CreateTriggerSkill{
  name = "yaoyan",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room

    room:setPlayerMark(player, "yaoyan_owner-turn", 1)
    room:doIndicate(player.id, table.map(room:getOtherPlayers(player, false), Util.IdMapper))
    for _, p in ipairs(room:getAlivePlayers()) do
      if room:askForSkillInvoke(p, self.name, data, "#yaoyan-ask") then
        room:setPlayerMark(p, "@@yaoyan-turn", 1)
      end
    end
  end,
}
local yaoyanDiscussion = fk.CreateTriggerSkill{
  name = "#yaoyan_discussion",
  anim_type = "offensive",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:getMark("yaoyan_owner-turn") > 0 and
      table.find(player.room.alive_players, function(p) return p:getMark("@@yaoyan-turn") > 0 and not p:isKongcheng() end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room

    local targets = table.filter(room.alive_players, function(p) return p:getMark("@@yaoyan-turn") > 0 and not p:isKongcheng() end)
    local discussion = U.Discussion(player, targets, self.name)

    if discussion.color == "red" then
      local others = table.filter(room.alive_players, function(p)
        return not table.contains(targets, p) and not p:isKongcheng()
      end)

      if #others > 0 then
        local tos = room:askForChoosePlayers(player, table.map(others, Util.IdMapper), 1, 999, "#yaoyan-prey", "yaoyan", false, false)
        room:sortPlayersByAction(tos)
        for _, playerId in ipairs(tos) do
          local p = room:getPlayerById(playerId)
          if not p:isKongcheng() then
            local card = room:askForCardChosen(player, p, "h", "yaoyan")
            room:obtainCard(player.id, card, false, fk.ReasonPrey)
          end
        end
      end
    elseif discussion.color == "black" then
      targets = table.filter(targets, function(p) return p:isAlive() end)
      local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#yaoyan-damage", "yaoyan", true, false)
      if #tos > 0 then
        room:damage{
          from = player,
          to = room:getPlayerById(tos[1]),
          damage = 2,
          damageType = fk.NormalDamage,
          skillName = self.name,
        }
      end
    end
  end,
}
local bazheng = fk.CreateTriggerSkill{
  name = "bazheng",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {"fk.DiscussionCardsDisplayed"},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.results[player.id] and
      #player.room.logic:getActualDamageEvents(1, function(e)
        local damage = e.data[1]
        return damage.from and damage.from == player and damage.to ~= player and damage.to:isAlive() and data.results[damage.to.id]
      end, Player.HistoryTurn) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room

    local targets = {}
    player.room.logic:getActualDamageEvents(999, function(event)
      local damageData = event.data[1]
      local victimId = damageData.to.id
      if damageData.from == player and damageData.to ~= player and damageData.to:isAlive() and data.results[victimId] then
        data.results[victimId].opinion = data.results[player.id].opinion
        table.insert(targets, victimId)
      end
    end, Player.HistoryTurn)
    room:doIndicate(player.id, targets)

    room:sendLog{
      type = "#LogChangeOpinion",
      to = targets,
      arg = data.results[player.id].opinion,
      toast = true,
    }
  end,
}
yaoyan:addRelatedSkill(yaoyanDiscussion)
sunjun:addSkill(yaoyan)
sunjun:addSkill(bazheng)
Fk:loadTranslationTable{
  ["js__sunjun"] = "孙峻",
  ["#js__sunjun"] = "朋党执虎",
  ["illustrator:js__sunjun"] = "鬼画府",

  ["yaoyan"] = "邀宴",
  ["#yaoyan_discussion"] = "邀宴",
  [":yaoyan"] = "准备阶段开始时，你可以令所有角色依次选择是否于本回合结束时参与议事，若此议事结果为：红色，你获得至少一名未参与议事的角色各一张手牌" ..
  "；黑色，你对一名参与议事的角色造成2点伤害。",
  ["bazheng"] = "霸政",
  [":bazheng"] = "锁定技，当你参与的议事展示意见后，参与议事角色中本回合受到过你造成伤害的角色意见改为与你相同。",
  ["@@yaoyan-turn"] = "邀宴",
  ["#yaoyan-ask"] = "邀宴；你是否于本回合结束后参与议事？",
  ["#yaoyan-prey"] = "邀宴；你可以选择其中至少一名角色，获得他们的各一张手牌",
  ["#yaoyan-damage"] = "邀宴：你可以对其中一名角色造成2点伤害",
  ["#LogChangeOpinion"] = "%to 的意见被视为 %arg",
}

--local sunlubansunluyu = General(extension, "js__sunlubansunluyu", "wu", 3, 3, General.Female)
Fk:loadTranslationTable{
  ["js__sunlubansunluyu"] = "孙鲁班孙鲁育",
  ["#js__sunlubansunluyu"] = "恶紫夺朱",
  ["illustrator:js__sunlubansunluyu"] = "鬼画府",

  ["daimou"] = "殆谋",
  [":daimou"] = "每回合各限一次，当一名角色使用【杀】指定其他角色/你为目标时，你可以用牌堆顶的牌“蓄谋”/你须弃置你区域里的一张“蓄谋”牌。"..
  "当其中一名目标响应此【杀】后，此【杀】对剩余目标造成的伤害+1。"..
  "<br/><font color='grey'>#\"<b>蓄谋</b>\"：将一张手牌扣置于判定区，判定阶段开始时，按置入顺序（后置入的先处理）依次处理“蓄谋”牌：1.使用此牌，"..
  "然后此阶段不能再使用此牌名的牌；2.将所有“蓄谋”牌置入弃牌堆。",
  ["fangjie"] = "芳洁",
  [":fangjie"] = "准备阶段，若你没有“蓄谋”牌，你回复一点体力并摸一张牌，否则你可以弃置任意张你区域里的“蓄谋”牌并失去此技能。",
}

local weiwenzhugezhi = General(extension, "js__weiwenzhugezhi", "wu", 4)
local fuhaiw = fk.CreateActiveSkill{
  name = "js__fuhaiw",
  anim_type = "drawcard",
  prompt = "#js__fuhaiw",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and #Fk:currentRoom().alive_players > 1
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local targets = room:getOtherPlayers(player)
    room:doIndicate(player.id, table.map(targets, Util.IdMapper))
    targets = table.filter(targets, function (p)
      return not p:isKongcheng()
    end)
    if #targets == 0 then
      player:drawCards(1, self.name)
      return
    end
    local result = U.askForJointCard(targets, 1, 1, false, self.name, false, nil, "#js__fuhaiw-show:"..player.id)
    if player.dead then return end
    if #targets == 1 then
      player:drawCards(1, self.name)
      return
    end
    local numbers = {}
    for _, p in ipairs(targets) do
      table.insert(numbers, Fk:getCardById(result[p.id][1]).number)
      room:showCards(result[p.id], p)
    end
    local n1, n2 = 1, 1
    local tag = ""
    if numbers[2] > numbers[1] then
      tag = "increase"
      n1 = 2
    elseif numbers[2] < numbers[1] then
      tag = "decline"
      n1 = 2
    end
    if tag ~= "" then
      for i = 3, #targets, 1 do
        local yes = (tag == "increase" and numbers[i] > numbers[i - 1]) or numbers[i] < numbers[i - 1]
        if yes then
          n1 = n1 + 1
        else
          break
        end
      end
    end
    if numbers[2] > numbers[1] then
      tag = "increase"
      n2 = 2
    elseif numbers[2] < numbers[1] then
      tag = "decline"
      n2 = 2
    else
      tag = ""
    end
    if tag ~= "" then
      for i = #targets - 2, 1, -1 do
        local yes = (tag == "increase" and numbers[i] > numbers[i + 1]) or numbers[i] < numbers[i + 1]
        if yes then
          n2 = n2 + 1
        else
          break
        end
      end
    end
    local choice = room:askForChoice(player, {"js__fuhaiw1:::"..n1, "js__fuhaiw2:::"..n2}, self.name)
    local n = choice[11] == "1" and n1 or n2
    player:drawCards(n, self.name)
  end,
}
weiwenzhugezhi:addSkill(fuhaiw)
Fk:loadTranslationTable{
  ["js__weiwenzhugezhi"] = "卫温诸葛直",
  ["#js__weiwenzhugezhi"] = "帆至夷洲",
  ["illustrator:js__weiwenzhugezhi"] = "猎枭",

  ["js__fuhaiw"] = "浮海",
  [":js__fuhaiw"] = "出牌阶段限一次，你可以令所有其他角色同时展示一张手牌（没有手牌则跳过），然后你选择顺时针或逆时针方向，摸X张牌（X为"..
  "从你开始该方向上角色展示牌点数严格递增或严格递减的数量，至少为1）。",
  ["#js__fuhaiw"] = "浮海：令所有其他角色同时展示一张手牌，你根据点数递增递减情况摸牌",
  ["#js__fuhaiw-show"] = "浮海：展示一张手牌，有可能令 %src 摸牌",
  ["js__fuhaiw1"] = "逆时针方向（摸%arg张牌）",
  ["js__fuhaiw2"] = "顺时针方向（摸%arg张牌）",
}

return extension
