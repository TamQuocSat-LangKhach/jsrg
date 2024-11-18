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
      local result = U.askForJointCard(targets, 1, 1, false, self.name, false, nil, "#js__zhimeng-display")

      local suitsDisplayed = {}
      for _, p in ipairs(targets) do
        local cardDisplayed = Fk:getCardById(result[p.id][1])
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
          if moveInfo.fromArea ~= Player.Hand and moveInfo.fromArea ~= Player.Equip then
            local cardMoved = Fk:getCardById(moveInfo.cardId)
            if cardMoved.is_damage_card or cardMoved.type == Card.TypeEquip then
              table.insert(toObtain, moveInfo.cardId)
            end
          end
        end
      end
    end
    local room = player.room
    table.filter(toObtain, function(id) return room:getCardArea(id) == Card.DiscardPile end)

    if #toObtain == 0 then
      return false
    end

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
      return #toObtain == 0
    end, Player.HistoryTurn)

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
    room:doIndicate(player.id, table.map(room.alive_players, Util.IdMapper))
    local targets = room:getOtherPlayers(player)
    local req = Request:new(targets, "AskForUseActiveSkill")
    req.focus_text = self.name
    local extraData = {
      targets = table.map(targets, Util.IdMapper),
      num = 1,
      min_num = 1,
      pattern = "",
      skillName = self.name,
    }
    local data = { "choose_players_skill", "#zhuni-choose:"..player.id, false, extraData, false }
    for _, p in ipairs(room.alive_players) do
      req:setData(p, data)
      req:setDefaultReply(p, table.random(targets).id)
    end
    req:ask()
    local yourTarget
    if player:hasSkill("hezhi") then
      if type(req:getResult(player)) == "table" then
        yourTarget = req:getResult(player).targets[1]
      else
        yourTarget = table.random(targets).id
      end
    end

    local targetsMap = {}
    for _, p in ipairs(room:getAlivePlayers()) do
      local to
      if type(req:getResult(p)) == "table" then
        to = req:getResult(p).targets[1]
      else
        to = table.random(targets).id
      end
      room:sendLog{
        type = "#ShowPlayerChosen",
        from = p.id,
        to = { to },
        toast = true,
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
      local zhuniOwners = maxPlayer:getTableMark(("@@zhuniOnwers-turn"))
      table.insertIfNeed(zhuniOwners, player.id)
      room:setPlayerMark(maxPlayer, "@@zhuniOnwers-turn", zhuniOwners)
    end
  end,
}
local zhuniTargetmod = fk.CreateTargetModSkill{
  name = "#zhuni_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    if card and to then
      return table.contains(to:getTableMark("@@zhuniOnwers-turn"), player.id)
    end
  end,
  bypass_distances = function(self, player, skill, card, to)
    if card and to then
      return table.contains(to:getTableMark("@@zhuniOnwers-turn"), player.id)
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
  ["#songhuanghou"] = "兰心蕙质",
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

local caojiewangfu = General(extension, "caojiewangfu", "qun", 3)
Fk:loadTranslationTable{
  ["caojiewangfu"] = "曹节王甫",
  ["#caojiewangfu"] = "浊乱海内",
  ["illustrator:caojiewangfu"] = "鬼画府",
}

local zonghai = fk.CreateTriggerSkill{
  name = "zonghai",
  anim_type = "drawcard",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return
      target ~= player and
      player:hasSkill(self) and
      player:usedSkillTimes(self.name, Player.HistoryRound) == 0 and
      target:isAlive() and
      target.hp < 1
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#zonghai-invoke::" .. data.who)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local victim = room:getPlayerById(data.who)
    room:doIndicate(player.id, { victim.id })
    local tos = room:askForChoosePlayers(
      victim,
      table.map(room.alive_players, Util.IdMapper),
      1,
      2,
      "#zonghai-choose",
      self.name,
      false
    )

    for _, to in ipairs(tos) do
      local to = room:getPlayerById(to)
      local zonghaiSource = to:getTableMark("@@zonghai")
      table.insertIfNeed(zonghaiSource, player.id)
      room:setPlayerMark(to, "@@zonghai", zonghaiSource)
    end

    local curDyingEvent = room.logic:getCurrentEvent():findParent(GameEvent.Dying)
    if curDyingEvent then
      curDyingEvent:addCleaner(function()
        for _, p in ipairs(tos) do
          local to = room:getPlayerById(p)
          local zonghaiSource = to:getTableMark("@@zonghai")
          table.removeOne(zonghaiSource, player.id)
          room:setPlayerMark(to, "@@zonghai", #zonghaiSource > 0 and zonghaiSource or 0)
        end
      end)
    end

    data.extra_data = (data.extra_data or {})
    data.extra_data.zonghaiUsed = data.extra_data.zonghaiUsed or {}
    data.extra_data.zonghaiUsed[player.id] = data.extra_data.zonghaiUsed[player.id] or {}
    table.insertTableIfNeed(data.extra_data.zonghaiUsed[player.id], tos)
  end,
}
local zonghaiDamage = fk.CreateTriggerSkill{
  name = "#zonghai_damage",
  mute = true,
  events = {fk.AfterDying},
  can_trigger = function(self, event, target, player, data)
    return
      ((data.extra_data or {}).zonghaiUsed or {})[player.id] and
      player:isAlive() and
      table.find(
        ((data.extra_data or {}).zonghaiUsed or {})[player.id],
        function(p) return player.room:getPlayerById(p):isAlive() end
      )
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(
      data.extra_data.zonghaiUsed[player.id],
      function(p) return player.room:getPlayerById(p):isAlive() end
    )

    if #targets == 0 then
      return false
    end

    room:sortPlayersByAction(targets)
    for _, pId in ipairs(targets) do
      local p = room:getPlayerById(pId)
      if p:isAlive() and player:isAlive() then
        room:doIndicate(player.id, { p.id })
        room:damage{
          from = player,
          to = p,
          damage = 1,
          skillName = "zonghai",
        }
      end
    end
  end,
}
local zonghaiProhibit = fk.CreateProhibitSkill{
  name = "#zonghai_prohibit",
  prohibit_use = function(self, player, card)
    return
      player:getMark("@@zonghai") == 0 and
      table.find(Fk:currentRoom().alive_players, function(p) return p:getMark("@@zonghai") ~= 0 end)
  end,
}
Fk:loadTranslationTable{
  ["zonghai"] = "纵害",
  [":zonghai"] = "每轮限一次，当其他角色进入濒死状态时，你可以令其选择至多两名角色，未被选择的角色于此次濒死结算中不能使用牌。"..
  "此濒死结算结束后，你对其选择的角色各造成1点伤害。",
  ["#zonghai-invoke"] = "纵害：是否对 %dest 发动本技能？",
  ["#zonghai-choose"] = "纵害：请选择至多两名角色，未被选择的角色在本次濒死中不能使用牌，濒死结算后所选角色受到伤害",
  ["@@zonghai"] = "纵害",
  ["#zonghai_damage"] = "纵害",
  ["#zonghai_prohibit"] = "纵害",
}


zonghai:addRelatedSkill(zonghaiDamage)
zonghai:addRelatedSkill(zonghaiProhibit)
caojiewangfu:addSkill(zonghai)

local jueyin = fk.CreateTriggerSkill{
  name = "jueyin",
  anim_type = "drawcard",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(self)) then
      return false
    end

    local room = player.room
    local record_id = player:getMark("jueyin_damage-turn")
    if record_id == 0 then
      room.logic:getActualDamageEvents(1, function(e)
        if e.data[1].to == player then
          record_id = e.id
          room:setPlayerMark(player, "jueyin_damage-turn", record_id)
          return true
        end
      end)
    end
    return room.logic:getCurrentEvent().id == record_id
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(3, self.name)
    for _, p in ipairs(room.alive_players) do
      room:addPlayerMark(p, "@jueyin_debuff-turn")
    end
  end,
}
local jueyinDebuff = fk.CreateTriggerSkill{
  name = "#jueyin_debuff",
  mute = true,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@jueyin_debuff-turn") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
Fk:loadTranslationTable{
  ["jueyin"] = "绝禋",
  [":jueyin"] = "当你每回合首次受到伤害后，你可以摸三张牌，然后本回合所有角色受到的伤害+1。",
  ["#jueyin_debuff"] = "绝禋",
  ["@jueyin_debuff-turn"] = "绝禋+",
}

jueyin:addRelatedSkill(jueyinDebuff)
caojiewangfu:addSkill(jueyin)

local zhangjiao = General(extension, "js__zhangjiao", "qun", 4)
Fk:loadTranslationTable{
  ["js__zhangjiao"] = "张角",
  ["#js__zhangjiao"] = "万蛾赴火",
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
  [":js__wudao"] = "觉醒技，当一名角色进入濒死状态时，若你没有手牌，你增加1点体力上限并回复1点体力，获得〖惊雷〗。",
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
  [":js__jinglei"] = "准备阶段开始时，你可以选择一名手牌数不为最少的角色，然后你令任意名手牌数之和小于其的角色各对其造成1点雷电伤害。",  
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

local zhanghuan = General(extension, "zhanghuan", "qun", 4)
Fk:loadTranslationTable{
  ["zhanghuan"] = "张奂",
  ["#zhanghuan"] = "正身洁己",
  ["illustrator:zhanghuan"] = "峰雨同程",
}
local zhushou = fk.CreateTriggerSkill{
  name = "zhushou",
  anim_type = "offensive",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    local room = player.room
    if
      not (
        player:hasSkill(self) and
        #room.logic:getEventsOfScope(
          GameEvent.MoveCards,
          1,
          function(e)
            return
              table.find(
                e.data,
                function(info)
                  return info.from == player.id and
                  table.find(
                    info.moveInfo,
                    function(moveInfo) return table.contains({ Card.PlayerHand, Card.PlayerEquip }, moveInfo.fromArea) end
                  )
                end
              )
          end,
          Player.HistoryTurn
        ) > 0
      )
    then
      return false
    end

    local cardWithBiggestNumber
    local biggestNumber = 0
    room.logic:getEventsOfScope(
      GameEvent.MoveCards,
      1,
      function(e)
        for _, info in ipairs(e.data) do
          if info.toArea == Card.DiscardPile then
            for _, moveInfo in ipairs(info.moveInfo) do
              if room:getCardArea(moveInfo.cardId) == Card.DiscardPile then
                local card = Fk:getCardById(moveInfo.cardId)
                if card.number > biggestNumber then
                  cardWithBiggestNumber = card.id
                  biggestNumber = card.number
                elseif card.number == biggestNumber then
                  cardWithBiggestNumber = nil
                end
              end
            end
          end
        end
        return false
      end,
      Player.HistoryTurn
    )

    if cardWithBiggestNumber then
      local targets = {}
      room.logic:getEventsOfScope(
        GameEvent.MoveCards,
        1,
        function(e)
          for _, info in ipairs(e.data) do
            if
              info.from and
              table.find(
                info.moveInfo,
                function(moveInfo)
                  return
                    moveInfo.cardId == cardWithBiggestNumber and
                    table.contains({ Card.PlayerHand, Card.PlayerEquip }, moveInfo.fromArea)
                end
              )
            then
              table.insertIfNeed(targets, info.from)
            end
          end
          return false
        end,
        Player.HistoryTurn
      )

      if #targets > 0 then
        self.cost_data = targets
        return true
      end
    end

    return false
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askForChoosePlayers(player, self.cost_data, 1, 1, "#zhushou-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos[1]
      return true
    end

    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    if to:isAlive() then
      room:damage{
        from = player,
        to = to,
        damage = 1,
        skillName = self.name
      }
    end
  end,
}
Fk:loadTranslationTable{
  ["zhushou"] = "诛首",
  [":zhushou"] = "你失去过牌的回合结束时，你可以选择弃牌堆中本回合进入的点数唯一最大的牌，"..
  "然后你对本回合失去过此牌的一名角色造成1点伤害。",
  ["#zhushou-choose"] = "诛首：你可对其中一名角色造成1点伤害",
}

zhanghuan:addSkill(zhushou)

local yangge = fk.CreateTriggerSkill{
  name = "yangge",
  refresh_events = {fk.EventAcquireSkill, fk.EventLoseSkill, fk.BuryVictim},
  can_refresh = function(self, event, target, player, data)
    if event == fk.EventAcquireSkill or event == fk.EventLoseSkill then
      return data == self
    elseif event == fk.BuryVictim then
      return player:hasSkill(self, true, true)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if table.every(room.alive_players, function(p) return not p:hasSkill(self, true) or p == player end) then
      if player:hasSkill("yangge&", true, true) then
        room:handleAddLoseSkills(player, "-yangge&", nil, false, true)
      end
    else
      if not player:hasSkill("yangge&", true, true) then
        room:handleAddLoseSkills(player, "yangge&", nil, false, true)
      end
    end
  end,
}
local yanggeActive = fk.CreateActiveSkill{
  name = "yangge&",
  anim_type = "support",
  prompt = "#yangge",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return
      not player:isKongcheng() and
      not table.find(Fk:currentRoom().alive_players, function(p)
        return p.hp < player.hp
      end) and
      table.find(Fk:currentRoom().alive_players, function(p)
        return p ~= player and p:hasSkill(yangge) and p:usedSkillTimes(yangge.name, Player.HistoryRound) == 0
      end)
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    local to = Fk:currentRoom():getPlayerById(to_select)
    return
      #selected == 0 and
      to_select ~= Self.id and
      to:hasSkill(yangge) and
      to:usedSkillTimes(yangge.name, Player.HistoryRound) == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])

    target:addSkillUseHistory(yangge.name, 1)
    room:obtainCard(target.id, player:getCardIds("h"), false, fk.ReasonGive, player.id, yangge.name)
    if player.dead or target.dead then return end
    local targets = table.filter(room:getOtherPlayers(player), function(p)
      return target:canPindian(p) and p ~= target
    end)
    if #targets == 0 then return end
    local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#mizhao-choose::" .. target.id, yangge.name, false)
    local to = room:getPlayerById(tos[1])
    local pindian = target:pindian({to}, yangge.name)
    if pindian.results[to.id].winner then
      local winner, loser
      if pindian.results[to.id].winner == target then
        winner = target
        loser = to
      else
        winner = to
        loser = target
      end
      if loser.dead then return end
      room:useVirtualCard("slash", nil, winner, { loser }, yangge.name, true)
    end
  end,
}
Fk:loadTranslationTable{
  ["yangge"] = "扬戈",
  [":yangge"] = "每轮限一次，体力值最低的其他角色可以于其出牌阶段对你发动〖密诏〗。",
  ["yangge&"] = "扬戈",
  [":yangge&"] = "出牌阶段，若你体力值为最低，你可以对一名有〖扬戈〗的角色发动〖密诏〗（其每轮限一次）。",
  ["#yangge"] = "扬戈：你可选择一名拥有〖扬戈〗角色，对其发动〖密诏〗",
}

Fk:addSkill(yanggeActive)
zhanghuan:addSkill(yangge)
zhanghuan:addRelatedSkill("mizhao")

local yangqiu = General(extension, "yangqiu", "qun", 4)
Fk:loadTranslationTable{
  ["yangqiu"] = "阳球",
  ["#yangqiu"] = "身蹈水火",
  ["cv:yangqiu"] = "KEVIN",
  ["illustrator:yangqiu"] = "鬼画府",
  ["$saojian1"] = "虎豹豺狼、蚊蝇鼠蟑，按律，皆斩。",
  ["$saojian2"] = "蒙鹰犬之任，埽朝廷奸鄙。",
  ["$saojian3"] = "陛下，请假臣一月之期！",
  ["$saojian4"] = "出生，你又藏了什么？",
  ["~yangqiu"] = "党人皆力锄奸宦而死，阳球之后，亦有志士。",
}

local saojian = fk.CreateActiveSkill{
  name = "saojian",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#saojian",
  mute = true,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:notifySkillInvoked(player, self.name)
    player:broadcastSkillInvoke(self.name, math.random(1, 2))

    local to = room:getPlayerById(effect.tos[1])
    if to:isKongcheng() then
      return
    end

    local ids, choice = U.askforChooseCardsAndChoice(
      player,
      to:getCardIds("h"),
      { "reveal", "not_reveal" },
      self.name,
      "#saojian-view::" .. to.id,
      nil,
      1,
      1
    )

    if choice == "reveal" then
      local toViewPlayers = table.filter(room.alive_players, function(p) return p ~= to end)
      if #toViewPlayers > 0 then
        for _, p in ipairs(toViewPlayers) do
          p:doNotify(
            "ShowCard",
            json.encode{
              from = player.id,
              cards = ids,
            }
          )
        end
        room:sendFootnote(ids, {
          type = "#SaoJianReveal",
          from = player.id,
        })
      end
    end

    for i = 1, 5 do
      local idsDiscarded = room:askForDiscard(to, 1, 1, false, self.name, false, ".", "#saojian-discard:::" .. 6 - i)
      if #idsDiscarded > 0 and idsDiscarded[1] == ids[1] then
        break
      end
      if i == 5 then player:broadcastSkillInvoke("saojian", 4) end
    end

    if player:isAlive() and to:getHandcardNum() > player:getHandcardNum() then
      player:broadcastSkillInvoke("saojian", 3)
      room:loseHp(player, 1, self.name)
    end
  end,
}

Fk:loadTranslationTable{
  ["saojian"] = "埽奸",
  [":saojian"] = "出牌阶段限一次，你可以观看一名其他角色的手牌并选择其中一张令除其外的角色观看，然后其重复弃置一张手牌（至多五次），" ..
  "直至其弃置了你选择的牌。然后若其手牌数大于你，你失去1点体力。",
  ["#saojian"] = "埽奸：你可观看一名其他角色的手牌，令其弃置手牌直到弃到你所选的牌",
  ["saojian_view"] = "埽奸观看",
  ["reveal"] = "他人可观看",
  ["not_reveal"] = "不可观看",
  ["#SaoJianReveal"] = "%from选择",
  ["#saojian-view"] = "埽奸：当前观看的是 %dest 的手牌",
  ["#saojian-discard"] = "埽奸：请弃置一张手牌，直到你弃置到“埽奸”选择的牌（剩余 %arg 次）",
}

yangqiu:addSkill(saojian)

local liubiao = General(extension, "js__liubiao", "qun", 3)
Fk:loadTranslationTable{
  ["js__liubiao"] = "刘表",
  ["#js__liubiao"] = "单骑入荆",
  ["illustrator:js__liubiao"] = "鬼画府",
}

local yansha = fk.CreateActiveSkill{
  name = "yansha",
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  prompt = "#yansha",
  can_use = function(self, player)
    return
      player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and
      player:canUse(Fk:cloneCard("amazing_grace"))
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return Self:canUseTo(Fk:cloneCard("amazing_grace"), Fk:currentRoom():getPlayerById(to_select))
  end,
  on_use = function(self, room, effect)
    local amazingGrace = Fk:cloneCard("amazing_grace")
    amazingGrace.skillName = self.name

    local useData = {
      from = effect.from,
      tos = table.map(effect.tos, function(to) return { to } end),
      card = amazingGrace,
    }
    room:useCard(useData)

    local targets = TargetGroup:getRealTargets(useData.tos)
    if #targets > 0 then
      for _, p in ipairs(room:getAlivePlayers()) do
        if p:isAlive() and not table.contains(targets, p.id) then
          room:setPlayerMark(p, self.name, TargetGroup:getRealTargets(useData.tos))
          local success, dat = room:askForUseViewAsSkill(
            p,
            "yanshaViewas",
            "#yansha-slash",
            true,
            {bypass_times = true, bypass_distances = true}
          )
          room:setPlayerMark(p, self.name, 0)

          if success then
            local card = Fk.skills["yanshaViewas"]:viewAs(dat.cards)
            table.removeOne(card.skillNames, "yanshaSlash")
            room:useCard{
              from = p.id,
              tos = table.map(dat.targets, function(toId) return { toId } end),
              card = card,
              extraUse = true,
            }
          end
        end
      end
    end
  end,
}
local yanshaViewas = fk.CreateViewAsSkill{
  name = "yanshaViewas",
  pattern = "slash",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("slash")
    card:addSubcard(cards[1])
    card.skillName = "yanshaSlash"
    return card
  end,
}
local yanshaProhibit = fk.CreateProhibitSkill{
  name = "#yansha_prohibit",
  is_prohibited = function(self, from, to, card)
    return
      card and
      table.contains(card.skillNames, "yanshaSlash") and
      not table.contains(from:getTableMark(yansha.name), to.id)
  end,
}
Fk:loadTranslationTable{
  ["yansha"] = "宴杀",
  [":yansha"] = "出牌阶段限一次，你可以视为使用一张以至少一名角色为目标的【五谷丰登】，"..
  "然后所有非目标角色依次可以将一张装备牌当做无距离限制的【杀】对其中一名目标角色使用。",
  ["#yansha"] = "宴杀：你可视为使用指定任意目标的【五谷丰登】，结算后非目标可将装备当【杀】对目标使用",
  ["yanshaViewas"] = "宴杀",
  ["#yansha-slash"] = "宴杀：你可以将一张装备牌当无距离限制的【杀】对其中一名角色使用",
}

Fk:addSkill(yanshaViewas)
yansha:addRelatedSkill(yanshaProhibit)
liubiao:addSkill(yansha)

local qingping = fk.CreateTriggerSkill{
  name = "qingping",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(self) and
      player.phase == Player.Finish and
      not table.find(
        player.room.alive_players,
        function(p)
          return
            player:inMyAttackRange(p) and
            (
              p:getHandcardNum() < 1 or
              p:getHandcardNum() > player:getHandcardNum()
            )
        end
      )
  end,
  on_use = function(self, event, target, player, data)
    local targetNum = #table.filter(
      player.room.alive_players,
      function(p)
        return
          player:inMyAttackRange(p) and
          p:getHandcardNum() > 0 and
          p:getHandcardNum() <= player:getHandcardNum()
      end
    )
    player:drawCards(targetNum, self.name)
  end,
}
Fk:loadTranslationTable{
  ["qingping"] = "清平",
  [":qingping"] = "结束阶段开始时，若你攻击范围内的角色手牌数均大于0且不大于你，则你可以摸等同于这些角色数的牌。",
}

liubiao:addSkill(qingping)

local chenfan = General(extension, "chenfan", "qun", 3)
Fk:loadTranslationTable{
  ["chenfan"] = "陈蕃",
  ["#chenfan"] = "不畏强御",
  ["illustrator:chenfan"] = "峰雨同程",
}

local gangfen = fk.CreateTriggerSkill{
  name = "gangfen",
  events = {fk.TargetSpecifying},
  can_trigger = function(self, event, target, player, data)
    return
      data.firstTarget and
      data.card.trueName == "slash" and
      player:hasSkill(self) and
      target:getHandcardNum() > player:getHandcardNum() and
      table.contains(player.room:getUseExtraTargets(data, true, true), player.id)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    return
      room:askForSkillInvoke(
        player,
        self.name,
        data,
        "#gangfen-invoke::" .. target.id .. ":" .. data.card:toLogString() .. ":" .. #U.getActualUseTargets(room, data, event)
      )
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    AimGroup:addTargets(room, data, player.id)
    room:sendLog{
      type = "#GangFenAdd",
      from = player.id,
      to = { target.id },
      arg = data.card:toLogString(),
      arg2 = #U.getActualUseTargets(room, data, event),
      toast = true,
    }
    local availableTargets = room:getUseExtraTargets(data, true, true)
    room:sortPlayersByAction(availableTargets)
    for _, pId in ipairs(availableTargets) do
      if
        room:askForSkillInvoke(
          room:getPlayerById(pId),
          self.name,
          data,
          "#gangfen-invoke::" .. target.id .. ":" .. data.card:toLogString() .. ":" .. #U.getActualUseTargets(room, data, event)
        )
      then
        room:doIndicate(target.id, { pId })
        AimGroup:addTargets(room, data, pId)
        room:sendLog{
          type = "#GangFenAdd",
          from = pId,
          to = { target.id },
          arg = data.card:toLogString(),
          arg2 = #U.getActualUseTargets(room, data, event),
          toast = true,
        }
      end
    end

    local handcards = target:getCardIds("h")
    if target:isAlive() and #handcards > 0 then
      target:showCards(handcards)
      room:delay(2000)
    end

    if
      #table.filter(handcards, function(id) return Fk:getCardById(id).color == Card.Black end) <
      #U.getActualUseTargets(room, data, event)
    then
      for _, id in ipairs(AimGroup:getAllTargets(data.tos)) do
        AimGroup:cancelTarget(data, id)
      end
      room:sendLog{
        type = "#GangFenCancel",
        from = target.id,
        arg = data.card:toLogString(),
        toast = true,
      }

      return true
    end
  end,
}
Fk:loadTranslationTable{
  ["gangfen"] = "刚忿",
  [":gangfen"] = "当手牌数大于你的角色使用【杀】指定第一个目标时，你可以成为此【杀】的额外目标，并令所有其他角色均可以如此做。"..
  "然后使用者展示所有手牌，若其中黑色牌小于目标数，则取消所有目标。",
  ["#gangfen-invoke"] = "刚忿：你可以成为 %dest 使用的 %arg 的额外目标，若最后使用者手中黑牌少于目标数则取消所有目标（当前目标数为%arg2）",
  ["#GangFenAdd"] = "%from 因“刚忿”选择成为 %to 使用的 %arg 的目标（当前目标数为%arg2）",
  ["#GangFenCancel"] = "%from 手牌中的黑色牌数小于 %arg 的目标数，因“刚忿”被取消",
}

chenfan:addSkill(gangfen)

local dangren = fk.CreateViewAsSkill{
  name = "dangren",
  anim_type = "support",
  pattern = "peach",
  switch_skill_name = "dangren",
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    if #cards ~= 0 then
      return nil
    end
    local c = Fk:cloneCard("peach")
    c.skillName = self.name
    return c
  end,
  enabled_at_play = function(self, player)
    return player:getSwitchSkillState(self.name) == fk.SwitchYang
  end,
  enabled_at_response = function(self, player, res)
    return
      not res and
      player:getSwitchSkillState(self.name) == fk.SwitchYang and
      not table.find(Fk:currentRoom().alive_players, function(p) return p ~= player and p.dying end)
  end,
}
local dangrenTrigger = fk.CreateTriggerSkill{
  name = "#dangren_trigger",
  anim_type = "support",
  events = {fk.AskForCardUse},
  switch_skill_name = "dangren",
  main_skill = dangren,
  can_trigger = function(self, event, target, player, data)
    if
      not (
        target == player and
        player:hasSkill(dangren) and
        player:getSwitchSkillState(dangren.name) == fk.SwitchYin and 
        data.pattern
      )
    then
      return false
    end

    local matcherParsed = Exppattern:Parse(data.pattern)
    local peach = Fk:cloneCard("peach")
    return
      table.find(
        matcherParsed.matchers,
        function(matcher)
          return
            table.contains(matcher.name or {}, "peach") or
            table.contains(matcher.trueName or {}, "peach")
        end
      ) and
      matcherParsed:match(peach) and
      table.find(
        ((data.extraData or {}).must_targets or {}),
        function(p)
          return
            p ~= player.id and
            not (
              player:prohibitUse(peach) and
              player:isProhibited(player.room:getPlayerById(p), peach)
            )
        end
      )
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local peach = Fk:cloneCard("peach")
    local others = table.filter(
      data.extraData.must_targets, 
      function(p)
        return
          p ~= player.id and
          not (
            player:prohibitUse(peach) and
            player:isProhibited(player.room:getPlayerById(p), peach)
          )
      end
    )

    if #others > 0 then
      room:sortPlayersByAction(others)
      data.result = {
        from = player.id,
        to = others[1],
        card = peach,
      }

      return true
    end
  end,
}
Fk:loadTranslationTable{
  ["dangren"] = "当仁",
  [":dangren"] = "转换技，阳：当你需要对你使用【桃】时，你可以视为使用之；阴：当你需要对其他角色使用【桃】时，你须视为使用之。",
  ["#dangren_trigger"] = "当仁",
}

dangren:addRelatedSkill(dangrenTrigger)
chenfan:addSkill(dangren)

local zhangju = General(extension, "zhangju", "qun", 4)
Fk:loadTranslationTable{
  ["zhangju"] = "张举",
  ["#zhangju"] = "草头天子",
  ["illustrator:zhangju"] = "峰雨同程",
}

local qiluanChooser = fk.CreateActiveSkill{
  name = "js__qiluan_chooser",
  min_card_num = 1,
  min_target_num = 1,
  card_filter = function(self, to_select, selected)
    return not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected < #selected_cards and Self.id ~= to_select
  end,
}
local qiluan = fk.CreateViewAsSkill{
  name = "js__qiluan",
  anim_type = "offensive",
  pattern = "slash",
  prompt = "#js__qiluan",
  times = function(self)
    return 2 - Self:usedSkillTimes(self.name)
  end,
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    if #cards ~= 0 then
      return nil
    end
    local c = Fk:cloneCard("slash")
    c.skillName = self.name
    return c
  end,
  before_use = function(self, player, use)
    local room = player.room
    if use.tos then
      room:doIndicate(player.id, TargetGroup:getRealTargets(use.tos))
    end

    local success, dat = room:askForUseActiveSkill(player, "js__qiluan_chooser", "#js__qiluan-use_slash", false)
    local targets = success and dat.targets or room:getOtherPlayers(player)[1]
    local cards =
      success and
      dat.cards or
      table.find(player:getCardIds("he"), function(id) return not player:prohibitDiscard(Fk:getCardById(id)) end)

    room:throwCard(cards, self.name, player, player)

    for _, pId in ipairs(targets) do
      local cardResponded = room:askForResponse(room:getPlayerById(pId), "slash", "slash", "#js__qiluan-slash:" .. player.id, true)
      if cardResponded then
        player:drawCards(#cards, self.name)

        room:responseCard({
          from = pId,
          card = cardResponded,
          skipDrop = true,
        })

        use.card = cardResponded
        return
      end
    end

    return self.name
  end,
  enabled_at_play = function(self, player)
    return
      player:usedSkillTimes(self.name) < 2 and
      table.find(player:getCardIds("he"), function(id) return not player:prohibitDiscard(Fk:getCardById(id)) end) and
      table.find(Fk:currentRoom().alive_players, function(p) return p ~= player end)
  end,
  enabled_at_response = function(self, player, response)
    return
      not response and
      player:usedSkillTimes(self.name) < 2 and
      table.find(player:getCardIds("he"), function(id) return not player:prohibitDiscard(Fk:getCardById(id)) end) and
      table.find(Fk:currentRoom().alive_players, function(p) return p ~= player end)
  end,
}
local qiluanJink = fk.CreateTriggerSkill{
  name = "#js__qiluan_jink",
  anim_type = "defensive",
  main_skill = qiluan,
  events = {fk.AskForCardUse},
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(self) and
      player:usedSkillTimes(self.name) < 2 and
      (data.cardName == "jink" or (data.pattern and Exppattern:Parse(data.pattern):matchExp("jink|0|nosuit|none"))) and
      (data.extraData == nil or data.extraData.jsQiluanAsk == nil)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askForUseActiveSkill(player, "js__qiluan_chooser", "#js__qiluan-use_jink", true)
    
    if success then
      self.cost_data = dat
      return true
    end

    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data.cards, self.name, player, player)

    room:doIndicate(player.id, self.cost_data.targets)
    for _, pId in ipairs(self.cost_data.targets) do
      local p = room:getPlayerById(pId)
      if p:isAlive() then
        local cardResponded = room:askForResponse(p, "jink", "jink", "#js__qiluan-jink:" .. player.id, true, { jsQiluanAsk = true })
        if cardResponded then
          player:drawCards(#self.cost_data.cards, self.name)

          room:responseCard({
            from = p.id,
            card = cardResponded,
            skipDrop = true,
          })

          data.result = {
            from = player.id,
            card = Fk:cloneCard('jink'),
          }
          data.result.card:addSubcards(room:getSubcardsByRule(cardResponded, { Card.Processing }))
          data.result.card.skillName = self.name

          if data.eventData then
            data.result.toCard = data.eventData.toCard
            data.result.responseToEvent = data.eventData.responseToEvent
          end
          return true
        end
      end
    end
  end,
}
Fk:loadTranslationTable{
  ["js__qiluan"] = "起乱",
  [":js__qiluan"] = "每回合限两次，当你需要使用【杀】或【闪】时，你可以弃置至少一张牌并令至多等量名其他角色选择是否替你使用之。"..
  "当有角色响应时，你摸等同于弃置的牌数。",
  ["#js__qiluan"] = "起乱：你可选择【杀】的目标，然后弃任意牌令等量其他角色选择是否替你出【杀】",
  ["js__qiluan_chooser"] = "起乱",
  ["#js__qiluan-use_slash"] = "起乱：选择任意张牌和等量其他角色，令其选择是否替你出【杀】",
  ["#js__qiluan-use_jink"] = "起乱：选择任意张牌和等量其他角色，令其选择是否替你出【闪】",
  ["#js__qiluan-slash"] = "起乱：你可打出一张【杀】视为 %src 使用此牌",
  ["#js__qiluan_jink"] = "起乱",
  ["#js__qiluan-jink"] = "起乱：你可打出一张【闪】视为 %src 使用此牌",
}

Fk:addSkill(qiluanChooser)
qiluan:addRelatedSkill(qiluanJink)
zhangju:addSkill(qiluan)

local xiangjia = fk.CreateViewAsSkill{
  name = "xiangjia",
  anim_type = "control",
  pattern = "collateral",
  prompt = "#xiangjia",
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    if #cards ~= 0 then
      return nil
    end
    local c = Fk:cloneCard("collateral")
    c.skillName = self.name
    return c
  end,
  after_use = function(self, player, use)
    local room = player.room
    local targets = TargetGroup:getRealTargets(use.tos)
    local collateral = Fk:cloneCard("collateral")
    for _, pId in ipairs(targets) do
      local p = room:getPlayerById(pId)
      if p:isAlive() and p:canUseTo(collateral, player) then
        local availableTargets = table.map(
          table.filter(
            room.alive_players,
            function(to) return collateral.skill:targetFilter(to.id, { player.id }, nil, collateral) end
          ),
          Util.IdMapper
        )

        if #availableTargets > 0 then
          local tos = room:askForChoosePlayers(p, availableTargets, 1, 1, "#xiangjia-use::" .. player.id, self.name)
          if #tos > 0 then
            room:useCard{
              from = pId,
              tos = {{ player.id }, { tos[1] }},
              card = collateral,
            }
          end
        end
      end
    end
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and player:getEquipment(Card.SubtypeWeapon)
  end,
}
Fk:loadTranslationTable{
  ["xiangjia"] = "相假",
  [":xiangjia"] = "出牌阶段限一次，若你装备区有武器牌，你可以视为使用一张【借刀杀人】，然后目标角色可以视为对你使用一张【借刀杀人】。",
  ["#xiangjia"] = "相假：你可视为使用【借刀杀人】，然后目标角色可视为对你使用【借刀杀人】",
  ["#xiangjia-use"] = "相假：你可视为对 %dest 使用【借刀杀人】（请选择 %dest 【杀】的目标）",
}

zhangju:addSkill(xiangjia)

return extension
