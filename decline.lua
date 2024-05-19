local extension = Package("decline")
extension.extensionName = "jsrg"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["decline"] = "江山如故·衰",
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

local yuanshao = General(extension, "js__yuanshao", "qun", 4)
Fk:loadTranslationTable{
  ["js__yuanshao"] = "袁绍",
  ["#js__yuanshao"] = "号令天下",
  ["illustrator:js__yuanshao"] = "鬼画府",
  ["~js__yuanshao"] = "",
}

local zhimeng = fk.CreateTriggerSkill{
  name = "js__zhimeng",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(#room.alive_players)
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
      proposer = player.id,
    })
    room:delay(2000)

    local targets = table.filter(room.alive_players, function(p) return not p:isKongcheng() end)
    if #targets > 0 then
      local extraData = {
        num = 1,
        min_num = 1,
        include_equip = false,
        pattern = ".",
        reason = self.name,
      }
      local prompt = "#js__zhimeng-display"
      local data = { "choose_cards_skill", prompt, false, extraData }

      for _, to in ipairs(targets) do
        to.request_data = json.encode(data)
      end

      room:notifyMoveFocus(targets, self.name)
      room:doBroadcastRequest("AskForUseActiveSkill", targets)

      local suitsDisplayed = {}
      for _, p in ipairs(targets) do
        local cardDisplayed
        if p.reply_ready then
          local replyCard = json.decode(p.client_reply).card
          cardDisplayed = Fk:getCardById(json.decode(replyCard).subcards[1])
        else
          cardDisplayed = Fk:getCardById(p:getCardIds(Player.Hand)[1])
        end

        suitsDisplayed[cardDisplayed:getSuitString()] = suitsDisplayed[cardDisplayed:getSuitString()] or {}
        table.insert(suitsDisplayed[cardDisplayed:getSuitString()], p.id)
        p:showCards(cardDisplayed)
      end
      room:delay(2000)

      local targetsToObtain = {}
      local playersDisplayed = {}
      for suit, pIds in pairs(suitsDisplayed) do
        if #pIds == 1 then
          table.insert(targetsToObtain, pIds[1])
          playersDisplayed[pIds[1]] = suit
        end
      end
  
      room:sortPlayersByAction(targetsToObtain)
      for _, pId in ipairs(targetsToObtain) do
        local cardsInProcessing = table.filter(cards, (function(id) return room:getCardArea(id) == Card.Processing end))
        local cardsToGain = table.filter(cardsInProcessing, function(id) return Fk:getCardById(id):getSuitString() == playersDisplayed[pId] end)
        if #cardsToGain > 0 then
          room:obtainCard(room:getPlayerById(pId), cardsToGain, true, fk.ReasonPrey, pId, self.name)
        end
      end
    end

    local toThrow = table.filter(cards, function(id) return room:getCardArea(id) == Card.Processing end)
    if #toThrow then
      room:moveCards{
        ids = toThrow,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = self.name,
      }
    end
  end,
}
Fk:loadTranslationTable{
  ["js__zhimeng"] = "执盟",
  [":js__zhimeng"] = "准备阶段开始时，你可以亮出牌堆顶存活角色数的牌，令所有角色同时展示一张手牌，展示不重复花色手牌的角色获得亮出牌中此花色的所有牌。",
  ["#js__zhimeng-display"] = "执盟：请展示一张手牌，若与其他角色展示的牌花色均不同，则你获得亮出牌中此花色的牌",
}

yuanshao:addSkill(zhimeng)

local tianyu = fk.CreateTriggerSkill{
  name = "js__tianyu",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then
      return false
    end

    local toObtain = {}
    for _, info in ipairs(data) do
      if info.toArea == Card.DiscardPile then
        for _, moveInfo in ipairs(info.moveInfo) do
          local cardMoved = Fk:getCardById(moveInfo.cardId)
          if cardMoved.is_damage_card or cardMoved.type == Card.TypeEquip then
            table.insert(toObtain, moveInfo.cardId)
          end
        end
      end
    end

    if #toObtain == 0 then
      return false
    end

    local room = player.room
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
      for _, info in ipairs(e.data) do
        if
          info.from
        then
          local infosFound = table.filter(
            info.moveInfo,
            function(moveInfo) return table.contains({ Card.PlayerHand, Card.PlayerEquip }, moveInfo.fromArea) end
          )
          for _, moveInfo in ipairs(infosFound) do 
            table.removeOne(toObtain, moveInfo.cardId)
          end
        end
      end
      return false
    end, Player.HistoryTurn)

    table.filter(toObtain, function(id) return room:getCardArea(id) == Card.DiscardPile end)
    if #toObtain > 0 then
      self.cost_data = toObtain
      return true
    end
  end,
  on_cost = function(self, event, target, player, data)
    local cards, choice = U.askforChooseCardsAndChoice(
      player,
      self.cost_data,
      { "OK" },
      self.name,
      "#js__tianyu-choose",
      { "get_all", "Cancel" },
      1,
      #self.cost_data
    )

    if choice == "Cancel" then
      return false
    end

    if choice == "OK" then
      self.cost_data = cards
    end

    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local toObtain = table.filter(self.cost_data, function(id) return room:getCardArea(id) == Card.DiscardPile end)
    if #toObtain > 0 then
      room:obtainCard(player, toObtain, true, fk.ReasonPrey, player.id, self.name)
    end
  end,
}
Fk:loadTranslationTable{
  ["js__tianyu"] = "天予",
  [":js__tianyu"] = "当一张伤害牌或装备牌进入弃牌堆后，若此牌于本回合内未属于过任何角色，则你可以获得之。",
  ["#js__tianyu-choose"] = "天予：选择要获得的牌",
}

yuanshao:addSkill(tianyu)

local zhuni = fk.CreateActiveSkill{
  name = "zhuni",
  anim_type = "offensive",
  card_num = 0,
  target_num = 0,
  prompt = "#zhuni",
  can_use = function(self, player)
    local alivePlayers = Fk:currentRoom().alive_players
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not (#alivePlayers == 1 and alivePlayers[1] == player.id)
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local targets = table.map(table.filter(room.alive_players, function(p) return p ~= player end), Util.IdMapper)
    local extraData = {
      targets = targets,
      num = 1,
      min_num = 1,
      pattern = "",
      skillName = self.name,
    }
    local prompt = "#zhuni-choose:" .. player.id
    local data = { "choose_players_skill", prompt, false, extraData, false }

    for _, to in ipairs(room.alive_players) do
      to.request_data = json.encode(data)
      room:doIndicate(effect.from, { to.id })
    end

    room:notifyMoveFocus(room.alive_players, self.name)
    room:doBroadcastRequest("AskForUseActiveSkill", room.alive_players)

    local yourTarget
    if player:hasSkill("hezhi") then
      if player.reply_ready then
        yourTarget = json.decode(player.client_reply).targets[1]
      else
        yourTarget = targets[1]
      end
    end

    local targetsMap = {}
    for _, p in ipairs(room:getAlivePlayers()) do
      local to
      if p.reply_ready then
        to = json.decode(p.client_reply).targets[1]
      else
        to = targets[1]
      end

      room:sendLog{
        type = "#ShowPlayerChosen",
        from = p.id,
        to = { to },
      }
      room:doIndicate(p.id, { to })
      room:delay(500)

      if yourTarget and p.kingdom == "qun" and p ~= player and yourTarget ~= to then
        to = yourTarget
        player:broadcastSkillInvoke("hezhi")
        room:notifySkillInvoked(player, "hezhi", "control")
        room:sendLog{
          type = "#ChangeZhuNiChosen",
          from = p.id,
          to = { to },
          toast = true,
        }
      end
      targetsMap[to] = (targetsMap[to] or 0) + 1
    end

    local maxTarget
    local maxNum = 0
    for pId, num in pairs(targetsMap) do
      if num > maxNum then
        maxNum = num
        maxTarget = pId
      elseif num == maxNum and maxTarget then
        maxTarget = nil
      end
    end

    if maxTarget then
      local maxPlayer = room:getPlayerById(maxTarget)
      local zhuniOwners = U.getMark(maxPlayer, ("@@zhuniOnwers-turn"))
      table.insertIfNeed(zhuniOwners, player.id)
      room:setPlayerMark(maxPlayer, "@@zhuniOnwers-turn", zhuniOwners)
    end
  end,
}
local zhuniTargetmod = fk.CreateTargetModSkill{
  name = "#zhuni_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    if card and to then
      return table.contains(U.getMark(to, "@@zhuniOnwers-turn"), player.id)
    end
  end,
  bypass_distances = function(self, player, skill, card, to)
    if card and to then
      return table.contains(U.getMark(to, "@@zhuniOnwers-turn"), player.id)
    end
  end,
}
Fk:loadTranslationTable{
  ["zhuni"] = "诛逆",
  [":zhuni"] = "出牌阶段限一次，你可以令所有角色同时选择一名除你外的角色，你本回合对此次被指定次数唯一最多的角色使用牌无距离次数限制。",
  ["#zhuni"] = "诛逆：你可令所有角色同时选择角色，你对唯一指定次数最多的角色使用牌无距离次数限制",
  ["#zhuni-choose"] = "诛逆：请选择其中一名角色，若你选择角色为被选择次数唯一最多的角色，%src 对其使用牌无距离次数限制",
  ["#ShowPlayerChosen"] = "%from 选择了 %to",
  ["#ChangeZhuNiChosen"] = "%from 选择的角色被改为了 %to",
  ["@@zhuniOnwers-turn"] = "被诛逆",
}

zhuni:addRelatedSkill(zhuniTargetmod)
yuanshao:addSkill(zhuni)

local hezhi = fk.CreateTriggerSkill{
  name = "hezhi$",
  frequency = Skill.Compulsory,
}
Fk:loadTranslationTable{
  ["hezhi"] = "合志",
  [":hezhi"] = "主公技，锁定技，其他群势力角色因“诛逆”指定的角色视为与你指定的角色相同。",
}

yuanshao:addSkill(hezhi)

local songhuanghou = General(extension, "songhuanghou", "qun", 3, 3, General.Female)
Fk:loadTranslationTable{
  ["songhuanghou"] = "宋皇后",
  ["#songhuanghou"] = "兰心慧质",
  ["illustrator:songhuanghou"] = "峰雨同程",
  ["~songhuanghou"] = "",
}

local zhongzen = fk.CreateTriggerSkill{
  name = "zhongzen",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(self) and
      player.phase == Player.Discard and
      player:getHandcardNum() > 1 and
      table.find(
        player.room.alive_players,
        function(p) return p:getHandcardNum() < player:getHandcardNum() and not p:isKongcheng() end
      )
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(
      room:getAlivePlayers(),
      function(p) return p:getHandcardNum() < player:getHandcardNum() and not p:isKongcheng() end
    )

    if #targets > 0 then
      room:doIndicate(player.id, table.map(targets, Util.IdMapper))

      for _, p in ipairs(targets) do
        if player:isAlive() and p:getHandcardNum() > 0 and p:isAlive() then
          local ids = room:askForCard(p, 1, 1, false, self.name, false, '.', '#zhongzhen::' .. player.id)
          room:obtainCard(player, ids, false, fk.ReasonGive, p.id, self.name)
        end
      end

      room:setPlayerMark(player, "@@zhongzen-phase", 1)
    end
  end,
}
local zhongzenDebuff = fk.CreateTriggerSkill{
  name = "#zhongzen_debuff",
  mute = true,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if not (target == player and player:getMark("@@zhongzen-phase") > 0 and not player:isNude()) then
      return false
    end

    local spadeDiscarded = {}
    player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
      for _, info in ipairs(e.data) do
        if info.moveReason == fk.ReasonDiscard and info.proposer == player.id then
          table.insertTable(
            spadeDiscarded,
            table.map(
              table.filter(info.moveInfo, function(moveInfo) return Fk:getCardById(moveInfo.cardId).suit == Card.Spade end),
              function(moveInfo) return moveInfo.cardId end
            )
          )
        end
      end
      return false
    end, Player.HistoryPhase)

    return #spadeDiscarded > player.hp
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:throwAllCards("he")
  end,
}
Fk:loadTranslationTable{
  ["zhongzen"] = "众谮",
  [":zhongzen"] = "锁定技，弃牌阶段开始时，你令所有手牌数小于你的角色须各交给你一张手牌。若如此做，此阶段结束时，" ..
  "若你本阶段弃置的♠牌数大于体力值，你弃置所有牌。",
  ["@@zhongzen-phase"] = "众谮",
  ["#zhongzhen"] = "众谮：请交给 %dest 一张手牌",
  ["#zhongzen_debuff"] = "众谮",
}

zhongzen:addRelatedSkill(zhongzenDebuff)
songhuanghou:addSkill(zhongzen)

local xuchong = fk.CreateTriggerSkill{
  name = "xuchong",
  anim_type = "drawcard",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(player, { "xuchong_draw", "xuchong_hand::" .. room.current.id, "Cancel" }, self.name, "#xuchong-choose")
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end

    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data == "xuchong_draw" then
      player:drawCards(1, self.name)
    else
      room:addPlayerMark(room.current, MarkEnum.AddMaxCardsInTurn, 2)
    end

    local shades = getShade(room, 1)
    room:obtainCard(player, shades, true, fk.ReasonPrey, player.id, self.name)
  end,
}
Fk:loadTranslationTable{
  ["xuchong"] = "虚宠",
  [":xuchong"] = "当你成为牌的目标后，你可以选择一项：1.摸一张牌；2.令当前回合角色本回合手牌上限+2。选择项执行完成后，你获得一张【影】。",
  ["xuchong_draw"] = "摸一张牌",
  ["xuchong_hand"] = "令%dest本回合手牌上限+2",
  ["#xuchong-choose"] = "虚宠：选择项执行完成后你获得一张【影】",
}

songhuanghou:addSkill(xuchong)

local luzhi = General(extension, "js__luzhi", "qun", 3)
Fk:loadTranslationTable{
  ["js__luzhi"] = "卢植",
  ["#js__luzhi"] = "眸宿渊亭",
  ["illustrator:js__luzhi"] = "峰雨同程",
  ["~js__luzhi"] = "",
}

local ruzong = fk.CreateTriggerSkill{
  name = "ruzong",
  anim_type = "drawcard",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(self)) then
      return false
    end

    local room = player.room
    local sameTarget
    local diffFound = room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      if e.data[1].from ~= player.id then
        return false
      end

      local tos = TargetGroup:getRealTargets(e.data[1].tos)
      if #tos > 1 then
        return true
      elseif #tos == 0 then
        return false
      elseif not sameTarget then
        sameTarget = tos[1]
      elseif sameTarget ~= tos[1] then
        return true
      end
      return false
    end, Player.HistoryTurn)

    if #diffFound == 0 and sameTarget and room:getPlayerById(sameTarget):isAlive() then
      if
        (sameTarget ~= player.id and player:getHandcardNum() >= room:getPlayerById(sameTarget):getHandcardNum()) or
        (
          sameTarget == player.id and
          not table.find(room.alive_players, function(p) return p ~= player and p:getHandcardNum() < player:getHandcardNum() end)
        )
      then
        return false
      end

      self.cost_data = sameTarget
      return true
    end

    return false
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local sameTarget = room:getPlayerById(self.cost_data)
    self.cost_data = nil
    if sameTarget ~= player then
      if
        room:askForSkillInvoke(
          player,
          self.name,
          data,
          "#ruzong-invoke::" .. sameTarget.id
        )
      then
        self.cost_data = sameTarget.id
        return true
      end
    else
      local targets = table.filter(room.alive_players, function(p) return p ~= player and p:getHandcardNum() < player:getHandcardNum() end)
      local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, #targets, "#ruzong-choose", self.name)
      if #tos > 0 then
        self.cost_data = tos
        return true
      end
    end

    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if type(self.cost_data) == "number" then
      local sameTarget = room:getPlayerById(self.cost_data)
      if sameTarget:getHandcardNum() > player:getHandcardNum() then
        player:drawCards(math.min(sameTarget:getHandcardNum() - player:getHandcardNum(), 5), self.name)
      end
    else
      for _, pId in ipairs(self.cost_data) do
        local p = room:getPlayerById(pId)
        if player:getHandcardNum() > p:getHandcardNum() then
          p:drawCards(player:getHandcardNum() - p:getHandcardNum(), self.name)
        end
      end
    end
  end,
}
Fk:loadTranslationTable{
  ["ruzong"] = "儒宗",
  [":ruzong"] = "回合结束时，若你本回合使用牌指定过的目标角色均为同一角色，则你可以将手牌数摸至与其相同（至多摸五张），" ..
  "若该目标为你，则改为你可令至少一名其他角色将手牌数摸至与你相同。",
  ["#ruzong-invoke"] = "儒宗：你可以将手牌数摸至与 %dest 相同",
  ["#ruzong-choose"] = "儒宗：你可以令至少一名其他角色将手牌数摸至与你相同",
}

luzhi:addSkill(ruzong)

local daoren = fk.CreateActiveSkill{
  name = "daoren",
  anim_type = "offensive",
  card_num = 1,
  target_num = 1,
  prompt = "#daoren",
  can_use = function(self, player)
    local alivePlayers = Fk:currentRoom().alive_players
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not (#alivePlayers == 1 and alivePlayers[1] == player.id)
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Card.PlayerHand
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    room:obtainCard(to, effect.cards, false, fk.ReasonGive, player.id, self.name)

    local sameTargets = table.filter(room:getAlivePlayers(), function(p) return player:inMyAttackRange(p) and to:inMyAttackRange(p) end)
    if #sameTargets then
      for _, p in ipairs(sameTargets) do
        room:damage{
          from = player,
          to = p,
          damage = 1,
          skillName = self.name,
        }
      end
    end
  end,
}
Fk:loadTranslationTable{
  ["daoren"] = "蹈刃",
  [":daoren"] = "出牌阶段限一次，你可以交给一名角色一张手牌，然后你对你与其攻击范围内均包含的所有角色各造成1点伤害。",
  ["#daoren"] = "蹈刃：你可交给一名角色手牌，你对你与其攻击范围内均包含的所有角色各造成1点伤害",
}

luzhi:addSkill(daoren)

--local caojiewangfu = General(extension, "caojiewangfu", "qun", 3)
Fk:loadTranslationTable{
  ["caojiewangfu"] = "曹节王甫",
  ["#caojiewangfu"] = "祸乱海内",
  ["illustrator:caojiewangfu"] = "鬼画府",
  ["zonghai"] = "纵害",
  [":zonghai"] = "每轮限一次，当其他角色进入濒死状态时，你可以令其选择至多两名角色，仅被选择的角色能在此次濒死结算中使用牌；"..
  "其脱离濒死状态或死亡后，你对其选择的角色各造成一点伤害。",
  ["jueli"] = "绝礼",
  [":jueli"] = "当你每回合首次受到伤害后，你可以摸三张牌，然后本回合所有角色受到的伤害+1。",
}

local zhangjiao = General(extension, "js__zhangjiao", "qun", 4)
Fk:loadTranslationTable{
  ["js__zhangjiao"] = "张角",
  ["#js__zhangjiao"] = "万蛾扑火",
  ["illustrator:js__zhangjiao"] = "鬼画府",
}

local js__xiangru = fk.CreateTriggerSkill{
  name = "js__xiangru",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if not (player:hasSkill(self) and data.from and data.from:isAlive() and data.damage >= (target.hp + target.shield)) then
      return false
    end

    local room = player.room
    if target == player then
      return table.find(room.alive_players, function(p) return p ~= player and #p:getCardIds("he") > 1 and p ~= data.from end)
    elseif target ~= player and target:isWounded() then
      return #player:getCardIds("he") > 1 and player ~= data.from
    end

    return false
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if target ~= player then
      local cards = room:askForCard(player, 2, 2, true, self.name, true, ".", "#xiangru-give:" .. target.id .. ":" .. data.from.id)
      if #cards > 1 then
        self.cost_data = cards
        return true
      end
    else
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if #p:getCardIds("he") > 1 and p:isWounded() and p ~= data.from then
          local cards = room:askForCard(p, 2, 2, true, self.name, true, ".", "#xiangru-give:" .. target.id .. ":" .. data.from.id)
          if #cards > 1 then
            self.cost_data = cards
            return true       
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:obtainCard(data.from.id, self.cost_data, false, fk.ReasonGive, (room:getCardOwner(self.cost_data[1]) or {}).id)
    return true
  end,
}
Fk:loadTranslationTable{
  ["js__xiangru"] = "相濡",
  [":js__xiangru"] = "当一名已受伤的其他角色/你受到致命伤害时，你/其他已受伤的角色可以交给伤害来源两张牌防止此伤害。",
  ["#xiangru-give"] = "相濡：是否交给 %dest 两张牌，防止 %src 受到的伤害？",
}

zhangjiao:addSkill(js__xiangru)

local js__wudao = fk.CreateTriggerSkill{
  name = "js__wudao",
  frequency = Skill.Wake,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if player:isWounded() and not player.dead then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    if player.dead then return false end
    room:handleAddLoseSkills(player, "js__jinglei")
  end,
}
Fk:loadTranslationTable{
  ["js__wudao"] = "悟道",
  [":js__wudao"] = "觉醒技，当一名角色进入濒死状态时，若你没有手牌，你增加一点体力上限并回复一点体力，获得技能“惊雷”。",
}

zhangjiao:addSkill(js__wudao)

local jinglei_active = fk.CreateActiveSkill{
  name = "jinglei_active",
  card_num = 0,
  card_filter = Util.FalseFunc,
  min_target_num = 1,
  target_filter = function(self, to_select, selected)
    local n = Fk:currentRoom():getPlayerById(to_select):getHandcardNum()
    for _, p in ipairs(selected) do
      n = n + Fk:currentRoom():getPlayerById(p):getHandcardNum()
    end
    return n < Self:getMark("js__jinglei")
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:setPlayerMark(player, "jinglei", 0)
  end,
}
Fk:addSkill(jinglei_active)
local js__jinglei = fk.CreateTriggerSkill{
  name = "js__jinglei",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local min_num = 999
    for _, p in ipairs(room.alive_players) do
      min_num = math.min(min_num, p:getHandcardNum())
    end
    local to = room:askForChoosePlayers(
      player,
      table.map(table.filter(room.alive_players, function(p) return p:getHandcardNum() > min_num end), Util.IdMapper),
      1,
      1,
      "#jinglei-choose",
      self.name,
      true
    )
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local n = to:getHandcardNum()
    room:setPlayerMark(player, self.name, n)
    local success, dat = room:askForUseActiveSkill(player, "jinglei_active", "#jinglei-use::" .. to.id .. ":" .. n, false)
    if success then
      local tos = table.simpleClone(dat.targets)
      room:sortPlayersByAction(tos)
      for _, id in ipairs(tos) do
        local p = room:getPlayerById(id)
        if p:isAlive() and to:isAlive() then
          room:doIndicate(p.id, { to.id })
          room:damage{
            from = p,
            to = to,
            damage = 1,
            damageType = fk.ThunderDamage,
            skillName = self.name
          }
        end
      end
    end
  end,
}
Fk:loadTranslationTable{
  ["js__jinglei"] = "惊雷",
  [":js__jinglei"] = "准备阶段开始时，你可以选择一名手牌数不为唯一最少的角色，然后你令任意名手牌数之和小于其的角色各对其造成1点雷电伤害。",  
  ["#jinglei-choose"] = "惊雷：你可选择一名角色，然后令任意名手牌数之和小于其的角色各对其造成一点雷电伤害",
  ["#jinglei-use"] = "惊雷：选择任意名手牌数之和不大于 %arg 的角色各对 %dest 造成一点雷电伤害。",
  ["jinglei_active"] = "惊雷",
}

zhangjiao:addRelatedSkill(js__jinglei)

--local dongzhuo = General(extension, "js__dongzhuo", "qun", 4)
Fk:loadTranslationTable{
  ["js__dongzhuo"] = "董卓",
  ["#js__dongzhuo"] = "华夏震栗",
  ["illustrator:js__dongzhuo"] = "鬼画府",
  ["guanshi"] = "观势",
  [":guanshi"] = "出牌阶段限一次，你可以将【杀】当做【火攻】对任意名角色使用，"..
  "当此牌未对其中一名角色造成伤害时，此牌对剩余角色视为【决斗】结算。",
  ["cangxiong"] = "藏凶",
  [":cangxiong"] = "每当你的一张牌被弃置或被其他角色获得后，你可以用此牌蓄谋，然后若此时是你的出牌阶段，你摸一张牌。",
  ["jiebingx"] = "劫柄",
  [":jiebingx"] = "觉醒技，准备阶段，若你区域内的蓄谋牌大于主公的体力值，你加2点体力上限并回复2点体力，然后获得〖暴威〗。",
  ["baowei"] = "暴威",
  [":baowei"] = "锁定技，结束阶段，你对一名本回合使用或打出过牌的其他角色造成2点伤害，若满足条件的角色大于两名，则改为你失去2点体力。",
}

--local zhanghuan = General(extension, "zhanghuan", "qun", 4)
Fk:loadTranslationTable{
  ["zhanghuan"] = "张奂",
  ["#zhanghuan"] = "正身洁己",
  ["illustrator:zhanghuan"] = "峰雨同程",
  ["zhushou"] = "诛首",
  [":zhushou"] = "你失去过牌的回合结束时，你可以选择弃牌中本回合置入的点数唯一最大的牌，"..
  "然后你对本回合一名失去过牌的角色造成一点伤害。",
  ["yangge"] = "扬戈",
  [":yangge"] = "每轮限一次，体力值最低的其他角色可以于其出牌阶段对你发动〖密诏〗。"
}

local yangqiu = General(extension, "yangqiu", "qun", 4)
Fk:loadTranslationTable{
  ["yangqiu"] = "阳球",
  ["#yangqiu"] = "身滔水火",
  ["illustrator:yangqiu"] = "鬼画府",
}

local saojian = fk.CreateActiveSkill{
  name = "saojian",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#saojian",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.tos[1])
    if to:isKongcheng() then
      return
    end

    local ids, choice = U.askforChooseCardsAndChoice(
      player,
      to:getCardIds("h"),
      { "OK" },
      self.name,
      "#saojian-view::" .. to.id,
      nil,
      1,
      1
    )

    local toViewPlayers = table.filter(room.alive_players, function(p) return p ~= player and p ~= to end)
    if #toViewPlayers > 0 then
      U.viewCards(toViewPlayers, ids, "saojian_view", "#saojian-view::" .. to.id)
    end

    for i = 1, 5 do
      local idsDiscarded = room:askForDiscard(to, 1, 1, false, self.name, false, ".", "#saojian-discard:::" .. 6 - i)
      if #idsDiscarded > 0 and idsDiscarded[1] == ids[1] then
        break
      end
    end

    if player:isAlive() and to:getHandcardNum() > player:getHandcardNum() then
      room:loseHp(player, 1, self.name)
    end
  end,
}

Fk:loadTranslationTable{
  ["saojian"] = "埽奸",
  [":saojian"] = "出牌阶段限一次，你可以观看一名其他角色的手牌并选择其中一张令除其外的角色观看，然后其重复弃置一张手牌（至多五次），" ..
  "直至其弃置了你选择的牌。然后若其手牌数大于你，你失去一点体力。",
  ["#saojian"] = "埽奸：你可观看一名其他角色的手牌，令其弃置手牌直到弃到你所选的牌",
  ["saojian_view"] = "埽奸观看",
  ["#saojian-view"] = "埽奸：当前观看的是 %dest 的手牌",
  ["#saojian-discard"] = "埽奸：请弃置一张手牌，直到你弃置到“埽奸”选择的牌（剩余 %arg 次）",
}

yangqiu:addSkill(saojian)

--local liubiao = General(extension, "js__liubiao", "qun", 4)
Fk:loadTranslationTable{
  ["js__liubiao"] = "刘表",
  ["#js__liubiao"] = "单骑入荆",
  ["illustrator:js__liubiao"] = "鬼画府",
  ["yansha"] = "宴杀",
  [":yansha"] = "出牌阶段限一次，你可以视为使用一张以任意名角色为目标的【五谷丰登】；"..
  "结算后所有非目标角色依次可以将一张装备牌当做无距离限制的【杀】对其中一名目标使用。",
  ["qingping"] = "清平",
  [":qingping"] = "结束阶段，若你攻击范围内的角色手牌数均大于0且不大于你，你摸等同于这些角色的牌数。",
}

--local chengfan = General(extension, "chenfan", "qun", 3)
Fk:loadTranslationTable{
  ["chenfan"] = "陈蕃",
  ["#chenfan"] = "不畏强禦",
  ["illustrator:chenfan"] = "峰雨同程",
  ["gangfen"] = "刚忿",
  [":gangfen"] = "手牌数大于你的角色使用【杀】指定目标后，你可以成为此【杀】的额外目标，并令所有其他角色均可以如此做。"..
  "然后使用者展示所有手牌，若其中黑色牌小于目标数，则取消所有目标。",
  ["dangren"] = "当仁",
  [":dangren"] = "转换技，阳：当你需要对你使用【桃】时，你可以视为使用之；阴：当你需要对其他角色使用【桃】时，你须视为使用之。",
}

--local zhangju = General(extension, "zhangju", "qun", 4)
Fk:loadTranslationTable{
  ["zhangju"] = "张举",
  ["#zhangju"] = "草头天子",
  ["illustrator:zhangju"] = "峰雨同程",
  ["qiluanh"] = "起乱",
  [":qiluanh"] = "每回合限两次，当你需要使用【杀】或【闪】时，你可以弃置任意张牌并令至多等量名其他角色选择是否替你使用之。"..
  "当有角色响应时，你摸等同于弃置的牌数。",
  ["xiangjia"] = "相假",
  [":xiangjia"] = "出牌阶段限一次，若你装备区有武器牌，你可以视为使用一张【借刀杀人】。结算后目标可以视为对你使用一张【借刀杀人】。",
}

return extension
