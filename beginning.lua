local extension = Package("beginning")
extension.extensionName = "jsrg"

Fk:loadTranslationTable{
  ["beginning"] = "江山如故-起包",
  ["js"] = "江山",
}

local function getTrueSkills(player)
  local skills = {}
  for _, s in ipairs(player.player_skills) do
    if not (s.attached_equip or s.name[#s.name] == "&") then
      table.insertIfNeed(skills, s.name)
    end
  end
  return skills
end


local function Discussion(self)
  --local discussionData = table.unpack(self.data)
  local discussionData = self
  --local room = self.room
  local room = self.from.room
  local logic = room.logic
  --logic:trigger(fk.StartDiscussion, discussionData.from, discussionData)

  if discussionData.reason ~= "" then
    room:sendLog{
      type = "#StartDiscussionReason",
      from = discussionData.from.id,
      arg = discussionData.reason,
    }
  end
  discussionData.color = "noresult"

  local extraData = {
    num = 1,
    min_num = 1,
    include_equip = false,
    pattern = ".",
    reason = discussionData.reason,
  }
  local prompt = "#askForDiscussion"
  local data = { "choose_cards_skill", prompt, true, json.encode(extraData) }

  local targets = {}
  for _, to in ipairs(discussionData.tos) do
    if not (discussionData.results[to.id] and discussionData.results[to.id].toCard) then
      table.insert(targets, to)
      to.request_data = json.encode(data)
    end
  end

  room:notifyMoveFocus(targets, "AskForDiscussion")
  room:doBroadcastRequest("AskForUseActiveSkill", targets)

  for _, p in ipairs(targets) do
    local discussionCard
    if p.reply_ready then
      local replyCard = json.decode(p.client_reply).card
      discussionCard = Fk:getCardById(json.decode(replyCard).subcards[1])
    else
      discussionCard = Fk:getCardById(p:getCardIds(Player.Hand)[1])
    end

    discussionData.results[p.id] = discussionData.results[p.id] or {}
    discussionData.results[p.id].toCard = discussionCard

    p:showCards({discussionCard})
  end
  --logic:trigger(fk.DiscussionCardsDisplayed, nil, discussionData)

  local red, black = 0, 0
  for toId, result in pairs(discussionData.results) do
    local to = room:getPlayerById(toId)
    if result.toCard.color == Card.Red then
      red = red + 1
    elseif result.toCard.color == Card.Black then
      black = black + 1
    end

    local singleDiscussionData = {
      from = discussionData.from,
      to = to,
      toCard = result.toCard,
      color = result.toCard:getColorString(),
      reason = discussionData.reason,
    }

    --logic:trigger(fk.DiscussionResultConfirmed, nil, singleDiscussionData)
  end

  local discussionResult = "noresult"
  if red > black then
    discussionResult = "red"
  elseif red < black then
      discussionResult = "black"
  end
  discussionData.color = discussionResult

  room:sendLog{
    type = "#ShowDiscussionResult",
    from = discussionData.from.id,
    arg = discussionResult
  }

  --if logic:trigger(fk.DiscussionFinished, discussionData.from, discussionData) then
  if logic:trigger("fk.DiscussionFinished", discussionData.from, discussionData) then
    logic:breakEvent()
  end
  return discussionData  --FIXME
end

Fk:loadTranslationTable{
  ["#StartDiscussionReason"] = "%from 由于 %arg 而发起议事",
  ["#askForDiscussion"] = "请展示一张手牌进行议事",
  ["AskForDiscussion"] = "议事",
  ["#ShowDiscussionResult"] = "%from 的议事结果为 %arg",
  ["noresult"] = "无结果",
}

local caocao = General(extension, "js__caocao", "qun", 4)
local zhenglve = fk.CreateTriggerSkill{
  name = "zhenglve",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target.role == "lord" and player:hasSkill(self.name) and target.phase == Player.NotActive
  end,
  on_cost = function(self, event, target, player, data)
    local n = 2
    if target:getMark(self.name) > 0 then
      n = 1
    end
    return player.room:askForSkillInvoke(player, self.name, nil, "#zhenglve-invoke:::"..n)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, self.name)
    local n = 2
    if target:getMark(self.name) > 0 then
      n = 1
    end
    local targets = table.map(table.filter(room:getAlivePlayers(), function(p)
      return p:getMark("@@caocao_lie") == 0 end), function(p) return p.id end)
    if #targets == 0 then return end
    n = math.min(n, #targets)
    local tos = room:askForChoosePlayers(player, targets, 1, n, "#zhenglve-choose:::"..n, self.name, true)
    if #tos < n then
      if n - #tos == 2 then
        table.insertTable(tos, table.random(targets, 2))
      else
        table.insert(tos, table.random(targets))
      end
    end
    for _, id in ipairs(tos) do
      room:setPlayerMark(room:getPlayerById(id), "@@caocao_lie", 1)
    end
  end,

  refresh_events = {fk.EventPhaseChanging, fk.Damage},
  can_refresh = function(self, event, target, player, data)
    if target == player and player.role == "lord" then
      if event == fk.EventPhaseChanging then
        return data.from == Player.RoundStart
      else
        return player.phase ~= Player.NotActive
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseChanging then
      room:setPlayerMark(player, self.name, 0)
    else
      room:addPlayerMark(player, self.name, 1)
    end
  end,
}
local zhenglve_trigger = fk.CreateTriggerSkill{
  name = "#zhenglve_trigger",
  mute = true,
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill("zhenglve") and data.to:getMark("@@caocao_lie") > 0 and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, "zhenglve", nil, "#zhenglve-trigger")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastSkillInvoke("zhenglve")
    room:notifySkillInvoked(player, "zhenglve", "drawcard")
    player:drawCards(1, "zhenglve")
    if data.card and room:getCardArea(data.card) == Card.Processing then
      room:obtainCard(player, data.card, true, fk.ReasonJustMove)
    end
  end,
}
local zhenglve_targetmod = fk.CreateTargetModSkill{
  name = "#zhenglve_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return player:hasSkill("zhenglve") and scope == Player.HistoryPhase and to:getMark("@@caocao_lie") > 0
  end,
  bypass_distances = function(self, player, skill, card, to)
    return player:hasSkill("zhenglve") and to:getMark("@@caocao_lie") > 0
  end,
}
local huilie = fk.CreateTriggerSkill{
  name = "huilie",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #table.filter(player.room.alive_players, function (p) return p:getMark("@@caocao_lie") > 0 end) > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    room:handleAddLoseSkills(player, "pingrong|feiying", nil)
  end,
}
local pingrong = fk.CreateTriggerSkill{
  name = "pingrong",
  anim_type = "special",
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getAlivePlayers(), function(p)
      return p:getMark("@@caocao_lie") > 0 end), function(p) return p.id end)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#pingrong-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    room:setPlayerMark(to, "@@caocao_lie", 0)
    room:addPlayerMark(player, "pingrong_extra", 1)
    player:gainAnExtraTurn()
  end,

  refresh_events = {fk.Damage, fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("pingrong_extra") > 0 and not player.dead
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "pingrong_extra", 0)
    if event == fk.TurnEnd then
      room:loseHp(player, 1, self.name)
    end
  end,
}
zhenglve:addRelatedSkill(zhenglve_trigger)
zhenglve:addRelatedSkill(zhenglve_targetmod)
caocao:addSkill(zhenglve)
caocao:addSkill(huilie)
caocao:addRelatedSkill(pingrong)
caocao:addRelatedSkill("feiying")
Fk:loadTranslationTable{
  ["js__caocao"] = "曹操",
  ["zhenglve"] = "政略",
  [":zhenglve"] = "主公的回合结束后，你可以摸一张牌，然后令一名没有“猎”标记的角色获得“猎”（若主公本回合没有造成过伤害，则改为两名）；"..
  "你对有“猎”的角色使用牌无距离和次数限制。<br>每名角色的回合限一次，当你对有“猎”的角色造成伤害后，你可以摸一张牌并获得造成此伤害的牌。",
  ["huilie"] = "会猎",
  [":huilie"] = "觉醒技，准备阶段，若有“猎”的角色数大于2，你减1点体力上限，然后获得〖平戎〗和〖飞影〗。",
  ["pingrong"] = "平戎",
  [":pingrong"] = "每轮限一次，每名角色的回合结束时，你可以选择一名有“猎”的角色移去其“猎”，然后于此回合结束后你执行一个额外的回合，"..
  "该回合结束时，若你于此回合未造成过伤害，你失去1点体力。",
  ["#zhenglve-invoke"] = "政略：你可以摸一张牌并令%arg名角色获得“猎”标记",
  ["@@caocao_lie"] = "猎",
  ["#zhenglve-choose"] = "政略：令%arg名角色获得“猎”标记",
  ["#zhenglve_trigger"] = "政略",
  ["#zhenglve-trigger"] = "政略：你可以摸一张牌并获得造成伤害的牌",
  ["#pingrong-choose"] = "平戎：你可以移去一名角色的“猎”标记，然后你执行一个额外回合",

  -- CV: 樰默
  ["$zhenglve1"] = "治政用贤不以德，则四方定。",
  ["$zhenglve2"] = "秉至公而服天下，孤大略成。",
  ["$huilie1"] = "孤上承天命，会猎于江夏，幸勿观望。",
  ["$huilie2"] = "今雄兵百万，奉词伐罪，敢不归顺？",
  ["$pingrong1"] = "万里平戎，岂曰功名，孤心昭昭鉴日月。",
  ["$pingrong2"] = "四极倾颓，民心思定，试以只手补天裂。",
  ["~js__caocao"] = "汉征西，归去兮，复汉土兮…挽汉旗…",
}

local sunjian = General(extension, "js__sunjian", "qun", 4)
local pingtao = fk.CreateActiveSkill{
  name = "pingtao",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    if target:isNude() then
      room:useVirtualCard("slash", nil, player, target, self.name, true)
    else
      local card = room:askForCard(target, 1, 1, true, self.name, true, ".", "#pingtao-card:"..player.id)
      if #card > 0 then
        room:obtainCard(player, card[1], false, fk.ReasonGive)
        room:addPlayerMark(player, "@@pingtao-phase", 1)
      else
        room:useVirtualCard("slash", nil, player, target, self.name, true)
      end
    end
  end,
}
local pingtao_targetmod = fk.CreateTargetModSkill{
  name = "#pingtao_targetmod",
  residue_func = function(self, player, skill, scope)
    if player:getMark("@@pingtao-phase") > 0 and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return 1
    end
  end,
}
local juelie = fk.CreateTriggerSkill{
  name = "juelie",
  anim_type = "offensive",
  events = {fk.PreCardEffect, fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.trueName == "slash"
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.PreCardEffect then  --这个时机？
      return table.every(room:getOtherPlayers(player), function(p) return p.hp >= player.hp end) or
        table.every(room:getOtherPlayers(player), function(p) return #p.player_cards[Player.Hand] >= #player.player_cards[Player.Hand] end)
    else
      local cards = room:askForDiscard(player, 1, 999, true, self.name, true, ".", "#juelie-discard::"..data.to)
      if #cards > 0 then
        self.cost_data = #cards
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.PreCardEffect then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    else
      local room = player.room
      local to = room:getPlayerById(data.to)
      if to:isNude() then return end
      local cards = room:askForCardsChosen(player, to, 0, self.cost_data, "he", self.name)
      room:throwCard(cards, self.name, to, player)
    end
  end,
}
pingtao:addRelatedSkill(pingtao_targetmod)
sunjian:addSkill(pingtao)
sunjian:addSkill(juelie)
Fk:loadTranslationTable{
  ["js__sunjian"] = "孙坚",
  ["pingtao"] = "平讨",
  [":pingtao"] = "出牌阶段限一次，你可以令一名其他角色选择一项：1.交给你一张牌，然后你此阶段使用【杀】次数上限+1；"..
  "2.令你视为对其使用一张无距离和次数限制的【杀】。",
  ["juelie"] = "绝烈",
  [":juelie"] = "若你是手牌数最小或体力值最小的角色，则你使用的【杀】伤害+1；当你使用【杀】指定目标后，你可以弃置任意张牌，然后弃置其至多等量的牌。",
  ["@@pingtao-phase"] = "平讨",
  ["#pingtao-card"] = "平讨：交给 %src 一张牌令其可以多使用一张【杀】，否则其视为对你使用【杀】",
  ["#juelie-discard"] = "绝烈：你可以弃置任意张牌，然后弃置 %dest 至多等量的牌",

  -- CV: 樰默
  ["$pingtao1"] = "平贼之功，非我莫属。",
  ["$pingtao2"] = "贼乱数郡，宜速讨灭！",
  ["$juelie1"] = "诸君放手，祸福，某一肩担之！",
  ["$juelie2"] = "先登破城，方不负孙氏勇烈！",
  ["~js__sunjian"] = "我，竟会被暗箭所伤…",
}

local liuhong = General(extension, "js__liuhong", "qun", 4)
local chaozheng = fk.CreateTriggerSkill{
  name = "chaozheng",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start and
      not table.every(player.room:getOtherPlayers(player), function(p) return p:isKongcheng() end)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#chaozheng-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player), function(p) return not p:isKongcheng() end)
    if #targets == 0 then return end
    room:doIndicate(player.id, table.map(targets, function(p) return p.id end))
    local discussion = Discussion{
      reason = self.name,
      from = player,
      tos = targets,
      results = {},
    }
    if discussion.color == "red" then
      for _, p in ipairs(targets) do
        if p:isWounded() and not p.dead and discussion.results[p.id].toCard.color == Card.Red then
          room:recover({
            who = p,
            num = 1,
            recoverBy = player,
            skillName = self.name
          })
        end
      end
    elseif discussion.color == "black" then
      for _, p in ipairs(targets) do
        if not p.dead and discussion.results[p.id].toCard.color == Card.Red then
          room:loseHp(p, 1, self.name)
        end
      end
    end
    if table.every(targets, function(p)
      return discussion.results[p.id].toCard.color == discussion.results[targets[1].id].toCard.color end) then
      player:drawCards(#targets, self.name)
    end
  end,
}
local shenchong = fk.CreateActiveSkill{
  name = "shenchong",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:handleAddLoseSkills(target, "m_feiyang|m_bahu", nil, true, false)
    room:setPlayerMark(player, self.name, target.id)
  end,
}
local shenchong_trigger = fk.CreateTriggerSkill{
  name = "#shenchong_trigger",

  refresh_events = {fk.BeforeGameOverJudge},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("shenchong") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(player:getMark("shenchong"))
    if to.dead then return end
    local skills = getTrueSkills(to)
    room:handleAddLoseSkills(to, "-"..table.concat(skills, "|-"), nil, true, false)
    to:throwAllCards("h")
  end,
}
local julian = fk.CreateTriggerSkill{
  name = "julian$",
  anim_type = "control",
  events = {fk.AfterCardsMove, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.AfterCardsMove then
        for _, move in ipairs(data) do
          if move.to and move.to ~= player.id then
            local to = player.room:getPlayerById(move.to)
            if to.kingdom == "qun" and move.moveReason == fk.ReasonDraw and move.skillName ~= self.name and to.phase ~= Player.Draw and
              player:getMark("julian-turn") < 2 then
              self.julian_to = to
              return true
            end
          end
        end
      else
        if player.phase == Player.Finish then
          for _, p in ipairs(player.room:getOtherPlayers(player)) do
            if p.kingdom == "qun" and not p:isKongcheng() then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      return room:askForSkillInvoke(self.julian_to, self.name, nil, "#julian-draw")
    else
      return room:askForSkillInvoke(player, self.name, nil, "#julian-invoke")
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      self.julian_to:drawCards(1, self.name)
      room:addPlayerMark(self.julian_to, "julian-turn", 1)
    else
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if p.kingdom == "qun" and not p:isKongcheng() then
          local id = room:askForCardChosen(player, p, "h", self.name)
          room:obtainCard(player, id, false, fk.ReasonPrey)
        end
      end
    end
  end,
}
shenchong:addRelatedSkill(shenchong_trigger)
liuhong:addSkill(chaozheng)
liuhong:addSkill(shenchong)
liuhong:addSkill(julian)
liuhong:addRelatedSkill("m_feiyang")
liuhong:addRelatedSkill("m_bahu")
Fk:loadTranslationTable{
  ["js__liuhong"] = "刘宏",
  ["chaozheng"] = "朝争",
  [":chaozheng"] = "准备阶段，你可以令所有其他角色议事，结果为：红色，意见为红色的角色各回复1点体力；黑色，意见为红色的角色各失去1点体力。"..
  "若所有角色意见相同，则议事结束后，你摸X张牌（X为此次议事的角色数）。",
  ["shenchong"] = "甚宠",
  [":shenchong"] = "限定技，出牌阶段，你可以令一名其他角色获得〖飞扬〗和〖跋扈〗，若如此做，当你死亡时，其失去所有技能，然后其弃置全部手牌。",
  ["julian"] = "聚敛",
  [":julian"] = "主公技，其他群势力角色每回合限两次，当其于其摸牌阶段外不因此技能而摸牌后，其可以摸一张牌；<br>"..
  "结束阶段，你可以获得所有其他群势力角色各一张手牌。",
  ["#chaozheng-invoke"] = "朝争：你可以令所有其他角色议事！",
  ["#julian-draw"] = "聚敛：你可以摸一张牌",
  ["#julian-invoke"] = "聚敛：你可以获得所有其他群势力角色各一张手牌",
}

local huangfusong = General(extension, "js__huangfusong", "qun", 4)
local guanhuo = fk.CreateActiveSkill{
  name = "guanhuo",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:prohibitUse(Fk:cloneCard("fire_attack"))
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and not target:isKongcheng() and not Self:isProhibited(target, Fk:cloneCard("fire_attack"))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:useVirtualCard("fire_attack", nil, player, target, self.name)
  end,
}
local guanhuo_trigger = fk.CreateTriggerSkill{
  name = "#guanhuo_trigger",

  refresh_events = {fk.PreCardUse, fk.Damage, fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    if target == player then
      if event == fk.PreCardUse then
        return player:getMark("@@guanhuo-phase") > 0 and data.card.name == "fire_attack"
      else
        return data.card and table.contains(data.card.skillNames, "guanhuo")
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.PreCardUse then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    elseif event == fk.Damage then
      data.card.extra_data = data.card.extra_data or {}
      table.insert(data.card.extra_data, "guanhuo")
    else
      if data.card.extra_data and table.contains(data.card.extra_data, "guanhuo") then return end
      if player:usedSkillTimes("guanhuo", Player.HistoryPhase) == 1 then
        room:addPlayerMark(player, "@@guanhuo-phase", 1)
      else
        room:handleAddLoseSkills(player, "-guanhuo", nil, true, false)
      end
    end
  end,
}
local juxia = fk.CreateTriggerSkill{
  name = "juxia",
  anim_type = "defensive",
  events = {fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.from and data.from ~= player.id and
      #getTrueSkills(player.room:getPlayerById(data.from)) > #getTrueSkills(player) and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    return room:askForSkillInvoke(room:getPlayerById(data.from), self.name, nil, "#juxia-invoke:"..player.id.."::"..data.card:toLogString())
  end,
  on_use = function(self, event, target, player, data)
    if data.card.sub_type == Card.SubtypeDelayedTrick then  --延时锦囊就取消掉？-_-||
      AimGroup:cancelTarget(data, player.id)
    else
      table.insertIfNeed(data.nullifiedTargets, player.id)
    end
    player:drawCards(2, self.name)
  end,
}
guanhuo:addRelatedSkill(guanhuo_trigger)
huangfusong:addSkill(guanhuo)
huangfusong:addSkill(juxia)
Fk:loadTranslationTable{
  ["js__huangfusong"] = "皇甫嵩",
  ["guanhuo"] = "观火",
  [":guanhuo"] = "出牌阶段，你可以视为使用一张【火攻】。当你以此法使用的未造成伤害的【火攻】结算后，若此次为你于此阶段内第一次发动本技能，"..
  "则你令你此阶段内你使用【火攻】造成的伤害+1，否则你失去〖观火〗。",
  ["juxia"] = "居下",
  [":juxia"] = "每名角色的回合限一次，当其他角色使用牌指定你为目标后，若其技能数大于你，则其可以令此牌对你无效，然后令你摸两张牌。",
  ["@@guanhuo-phase"] = "观火",
  ["#juxia-invoke"] = "居下：你可以令%arg对 %src 无效并令其摸两张牌",
}

local qiaoxuan = General(extension, "qiaoxuan", "qun", 3)
local js__juezhi = fk.CreateTriggerSkill{
  name = "js__juezhi",
  anim_type = "special",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip and player:hasSkill(self.name) and
            #player:getAvailableEquipSlots(Fk:getCardById(info.cardId).sub_type) > 0 then
            local e = player.room.logic:getCurrentEvent():findParent(GameEvent.SkillEffect)
            if e and e.data[3] == self then  --FIXME：防止顶替装备时重复触发
              return false
            end
            self:doCost(event, target, player, info.cardId)
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#js__juezhi-invoke:::"..Fk:getCardById(data):toLogString())
  end,
  on_use = function(self, event, target, player, data)
    player.room:abortPlayerArea(player, {Util.convertSubtypeAndEquipSlot(Fk:getCardById(data).sub_type)})
  end,
}
local js__juezhi_trigger = fk.CreateTriggerSkill{
  name = "#js__juezhi_trigger",
  mute = true,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill("js__juezhi") and data.card and not data.chain and
      #player.sealedSlots > 0 and table.find(data.to:getCardIds("e"), function(id)
        return table.contains(player.sealedSlots, Util.convertSubtypeAndEquipSlot(Fk:getCardById(id).sub_type)) end) and
      player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastSkillInvoke("js__juezhi")
    room:notifySkillInvoked(player, "js__juezhi", "offensive")
    local n = 0
    for _, id in ipairs(data.to:getCardIds("e")) do
      if table.contains(player.sealedSlots, Util.convertSubtypeAndEquipSlot(Fk:getCardById(id).sub_type)) then
        n = n + 1
      end
    end
    data.damage = data.damage + n
  end,
}
local jizhaoq = fk.CreateTriggerSkill{
  name = "jizhaoq",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and (player.phase == Player.Start or player.phase == Player.Finish)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p)
      return not p:isKongcheng() or table.find(room.alive_players, function(to)
        return p:canMoveCardsInBoardTo(to, nil)
      end)
    end), function(p)
      return p.id
    end)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#jizhaoq-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local use = nil
    if not to:isKongcheng() then
      local pattern = "^(jink,nullification)|.|.|.|.|.|"
      for _, id in ipairs(to:getCardIds("h")) do
        local card = Fk:getCardById(id)
        if not to:prohibitUse(card) and card.skill:canUse(to, card) then
          pattern = pattern..id..","
        end
      end
      pattern = string.sub(pattern, 1, #pattern - 1)
      use = room:askForUseCard(to, "", pattern, "#jizhaoq-use:"..player.id, true, {bypass_times = true})
    end
    if use then
      use.extraUse = true
      room:useCard(use)
    else
      local targets = table.map(table.filter(room.alive_players, function(p)
        return to:canMoveCardsInBoardTo(p, nil) end), function(p) return p.id end)
      if #targets > 0 then
        local t = room:askForChoosePlayers(player, targets, 1, 1, "#jizhaoq-move::"..to.id, self.name, true)
        if #t > 0 then
          room:askForMoveCardInBoard(player, to, room:getPlayerById(t[1]), self.name, nil, to, {})
        end
      end
    end
  end,
}
js__juezhi:addRelatedSkill(js__juezhi_trigger)
qiaoxuan:addSkill(js__juezhi)
qiaoxuan:addSkill(jizhaoq)
Fk:loadTranslationTable{
  ["qiaoxuan"] = "桥玄",
  ["js__juezhi"] = "绝质",
  [":js__juezhi"] = "当你失去一张装备区里的装备牌后，你可以废除对应的装备栏；你回合内每阶段限一次，当你使用牌对目标角色造成伤害时，"..
  "其装备区里每有一张与你已废除装备栏对应的装备牌，此伤害便+1。",
  ["jizhaoq"] = "急召",
  [":jizhaoq"] = "准备阶段和结束阶段，你可以令一名角色选择一项：1.使用一张手牌；2.令你可以移动其区域里的一张牌。",
  ["#js__juezhi-invoke"] = "绝质：你失去了%arg，是否废除对应的装备栏？",
  ["#jizhaoq-choose"] = "急召：你可以指定一名角色，令其选择使用一张手牌或你移动其区域内一张牌",
  ["#jizhaoq-use"] = "急召：使用一张手牌，或点“取消” %src 可以移动你区域内一张牌",
  ["#jizhaoq-move"] = "急召：你可以选择一名角色，将 %dest 区域内的一张牌移至目标角色区域",
}

local xushao = General(extension, "js__xushao", "qun", 3)
-- xushao.hidden = true

---@param player ServerPlayer
local addFangkeSkill = function(player, skillName)
  local room = player.room
  local skill = Fk.skills[skillName]
  if (not skill) or skill.lordSkill or skill.switchSkillName
    or skill.frequency > 3 -- 锁定技=3 后面的都是特殊标签
    or player:hasSkill(skill.name) then
    return
  end

  local fangke_skills = player:getMark("js_fangke_skills")
  if fangke_skills == 0 then fangke_skills = {} end
  table.insert(fangke_skills, skillName)
  room:setPlayerMark(player, "js_fangke_skills", fangke_skills)

  --[[
  -- room:handleAddLoseSkills(player, skillName, nil, false)
  player:doNotify("AddSkill", json.encode{ player.id, skillName })

  if skill:isInstanceOf(TriggerSkill) or table.find(skill.related_skills,
    function(s) return s:isInstanceOf(TriggerSkill) end) then
    player:doNotify("AddSkill", json.encode{ player.id, skillName, true })
  end

  if skill.frequency ~= Skill.Compulsory then
  end
  --]]

  player:addFakeSkill(skill)
  player:prelightSkill(skill.name, true)
end

---@param player ServerPlayer
local removeFangkeSkill = function(player, skillName)
  local room = player.room
  local skill = Fk.skills[skillName]

  local fangke_skills = player:getMark("js_fangke_skills")
  if fangke_skills == 0 then return end
  if not table.contains(fangke_skills, skillName) then
    return
  end
  table.removeOne(fangke_skills, skillName)
  room:setPlayerMark(player, "js_fangke_skills", fangke_skills)

  --[[
  if player:hasSkill(skillName) then -- FIXME: 预亮的bug，预亮技能会导致服务器为玩家直接添加技能
    player:loseSkill(Fk.skills[skillName])
  end
  player:doNotify("LoseSkill", json.encode{ player.id, skillName })

  if skill:isInstanceOf(TriggerSkill) or table.find(skill.related_skills,
    function(s) return s:isInstanceOf(TriggerSkill) end) then
    player:doNotify("LoseSkill", json.encode{ player.id, skillName, true })
  end
  --]]

  player:loseFakeSkill(skill)
end

---@param player ServerPlayer
---@param general General
local function addFangke(player, general, addSkill)
  local room = player.room
  local glist = player:getMark("@&js_fangke")
  if glist == 0 then glist = {} end
  table.insertIfNeed(glist, general.name)
  room:setPlayerMark(player, "@&js_fangke", glist)
  --[[
  room:setPlayerMark(player, "@js_fangke_num", #glist)
  for i = 1, 4 do
    room:setPlayerMark(player, "@js_fangke" .. i, glist[i] or 0)
  end
  --]]

  if not addSkill then return end
  for _, s in ipairs(general.skills) do
    addFangkeSkill(player, s.name)
  end
  for _, sname in ipairs(general.other_skills) do
    addFangkeSkill(player, sname)
  end
end

local yingmen = fk.CreateTriggerSkill{
  name = "yingmen",
  events = {fk.GameStart, fk.TurnStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, _)
    if event == fk.GameStart then
      return player:hasSkill(self.name)
    else
      return target == player and player:hasSkill(self.name) and
        (player:getMark("@&js_fangke") == 0 or #player:getMark("@&js_fangke") < 4)
    end
  end,
  on_use = function(self, _, _, player, _)
    local room = player.room
    local exclude_list = table.map(room.players, function(p)
      return p.general
    end)
    for _, p in ipairs(room.players) do
      local deputy = p.deputyGeneral
      if deputy and deputy ~= "" then
        table.insert(exclude_list, deputy)
      end
    end

    local m = player:getMark("@&js_fangke")
    local n = 4 - (m == 0 and 0 or #m)
    local generals = Fk:getGeneralsRandomly(n, nil, exclude_list)
    for _, g in ipairs(generals) do
      addFangke(player, g, player:hasSkill("js__pingjian"))
    end
  end,
}

xushao:addSkill(yingmen)

---@param player ServerPlayer
---@param general string
local function removeFangke(player, general)
  local room = player.room
  local glist = player:getMark("@&js_fangke")
  if glist == 0 then return end
  table.removeOne(glist, general)
  room:setPlayerMark(player, "@&js_fangke", glist)
  --[[
  player:setMark("js_fangke", glist) -- 这个没必要传输
  room:setPlayerMark(player, "@js_fangke_num", #glist)
  for i = 1, 4 do
    room:setPlayerMark(player, "@js_fangke" .. i, glist[i] or 0)
  end
  --]]

  general = Fk.generals[general]
  for _, s in ipairs(general.skills) do
    removeFangkeSkill(player, s.name)
  end
  for _, sname in ipairs(general.other_skills) do
    removeFangkeSkill(player, sname)
  end
end

local pingjian = fk.CreateTriggerSkill{
  name = "js__pingjian",
  events = {fk.AfterSkillEffect},
  can_trigger = function(self, _, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player:getMark("js_fangke_skills") ~= 0 and
      table.contains(player:getMark("js_fangke_skills"), data.name)
  end,
  on_cost = function() return true end,
  on_use = function(self, _, target, player, data)
    local room = player.room
    local choices = player:getMark("@&js_fangke")
    local choice = room:askForChoice(player, choices, self.name, "#js_lose_fangke")
    removeFangke(player, choice)

    local general = Fk.generals[choice]
    if table.contains(general.skills, data) or table.contains(general.other_skills, data.name) then
      player:drawCards(1)
    end
  end,
}
xushao:addSkill(pingjian)
Fk:loadTranslationTable{
  ["js__xushao"] = "许劭",
  ["yingmen"] = "盈门",
  [":yingmen"] = "锁定技，游戏开始时，你在剩余武将牌堆中随机获得四张武将牌置于你的武将牌上，称为“访客”；回合开始前，若你的“访客”数少于四张，"..
  "则你从剩余武将牌堆中将“访客”补至四张。",
  --[[
  ["@js_fangke1"] = "",
  ["@js_fangke2"] = "",
  ["@js_fangke3"] = "",
  ["@js_fangke4"] = "",
  ["@js_fangke_num"] = "访客",
  --]]
  ["@&js_fangke"] = "访客",
  ["#js_lose_fangke"] = "评鉴：请选择移除一张访客，若移除的是本次发技能的访客则摸一张牌",
  ["js__pingjian"] = "评鉴",
  [":js__pingjian"] = "当“访客”上的无类型标签或者只有锁定技标签的技能满足发动时机时，你可以发动该技能。"..
    "此技能的效果结束后，你须移除一张“访客”，若移除的是含有该技能的“访客”，你摸一张牌。" ..
    '<br /><font color="red">（注：由于判断发动技能的相关机制尚不完善，请不要汇报发动技能后某些情况下访客不丢的bug）</font>',
}

local hejin = General(extension, "js__hejin", "qun", 4)
local zhaobing = fk.CreateTriggerSkill{
  name = "zhaobing",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#zhaobing-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = #player.player_cards[Player.Hand]
    player:throwAllCards("h")
    local targets = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p)
      return p.id end), 1, n, "#zhaobing-choose:::"..n, self.name, true)
    if #targets > 0 then
      for _, id in ipairs(targets) do
        local p = room:getPlayerById(id)
        if p:isKongcheng() then
          room:loseHp(p, 1, self.name)
        else
          local card = room:askForCard(p, 1, 1, false, self.name, true, "slash", "#zhaobing-card:"..player.id)
          if #card > 0 then
            p:showCards(card)
            room:obtainCard(player, card[1], true, fk.ReasonGive)
          else
            room:loseHp(p, 1, self.name)
          end
        end
      end
    end
  end,
}
local zhuhuanh = fk.CreateTriggerSkill{
  name = "zhuhuanh",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#zhuhuanh-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    player:showCards(player.player_cards[Player.Hand])
    for _, id in ipairs(player.player_cards[Player.Hand]) do
      if Fk:getCardById(id).trueName == "slash" then
        table.insert(cards, id)
      end
    end
    local n = #cards
    if n == 0 then return end
    room:throwCard(cards, self.name, player, player)
    local targets = table.map(room:getOtherPlayers(player), function(p) return p.id end)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#zhuhuanh-choose:::"..n..":"..n, self.name, false)
    if #to > 0 then
      to = room:getPlayerById(to[1])
    else
      to = room:getPlayerById(table.random(targets))
    end
    local choice = room:askForChoice(to, {"zhuhuanh_damage", "zhuhuanh_recover"}, self.name)
    if choice == "zhuhuanh_damage" then
      room:damage{
        from = player,
        to = to,
        damage = 1,
        skillName = self.name,
      }
      if not to.dead then
        if #to:getCardIds{Player.Hand, Player.Equip} <= n then
          to:throwAllCards("he")
        else
          room:askForDiscard(to, n, n, true, self.name, false, ".")
        end
      end
    else
      if player:isWounded() then
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      end
      player:drawCards(n, self.name)
    end
  end,
}
hejin:addSkill(zhaobing)
hejin:addSkill(zhuhuanh)
hejin:addSkill("ty__yanhuo")
Fk:loadTranslationTable{
  ["js__hejin"] = "何进",
  ["zhaobing"] = "诏兵",
  [":zhaobing"] = "结束阶段，你可以弃置全部手牌，然后令至多等量的其他角色各选择一项：1.展示并交给你一张【杀】；2.失去1点体力。",
  ["zhuhuanh"] = "诛宦",
  [":zhuhuanh"] = "准备阶段，你可以展示所有手牌并弃置所有【杀】，然后令一名其他角色选择一项：1.受到1点伤害，然后弃置等量的牌；2.你回复1点体力，然后摸等量的牌。",
  ["#zhaobing-invoke"] = "诏兵：你可以弃置全部手牌，令等量其他角色选择交给你一张【杀】或失去1点体力",
  ["#zhaobing-choose"] = "诏兵：选择至多%arg名其他角色，依次选择交给你一张【杀】或失去1点体力",
  ["#zhaobing-card"] = "诏兵：交给 %src 一张【杀】，否则失去1点体力",
  ["#zhuhuanh-invoke"] = "诛宦：你可以展示手牌并弃置所有【杀】，令一名其他角色选择受到伤害并弃牌/你回复体力并摸牌",
  ["#zhuhuanh-choose"] = "诛宦：令一名其他角色选择受到1点伤害并弃%arg张牌 / 你回复1点体力并摸%arg2张牌",
  ["zhuhuanh_damage"] = "受到1点伤害，然后弃置等量的牌",
  ["zhuhuanh_recover"] = "其回复1点体力，然后其摸等量的牌",
}

local dongbai = General(extension, "js__dongbai", "qun", 3, 3, General.Female)
local shichong = fk.CreateTriggerSkill{
  name = "shichong",
  anim_type = "switch",
  switch_skill_name = "shichong",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      data.tos and #TargetGroup:getRealTargets(data.tos) == 1 and TargetGroup:getRealTargets(data.tos)[1] ~= player.id and
      not player.room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1]):isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if player:getSwitchSkillState(self.name, false) == fk.SwitchYang then
      return room:askForSkillInvoke(player, self.name, nil, "#shichong-invoke::"..TargetGroup:getRealTargets(data.tos)[1])
    else
      local to = room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1])
      local card = room:askForCard(to, 1, 1, false, self.name, true, ".", "#shichong-card:"..player.id)
      if #card > 0 then
        self.cost_data = card[1]
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getSwitchSkillState(self.name, true) == fk.SwitchYang then
      local to = room:getPlayerById(TargetGroup:getRealTargets(data.tos)[1])
      local card = room:askForCardChosen(player, to, "h", self.name)
      room:obtainCard(player, card, false, fk.ReasonPrey)
    else
      room:obtainCard(player, self.cost_data, false, fk.ReasonGive)
    end
  end,
}
local js__lianzhu = fk.CreateActiveSkill{
  name = "js__lianzhu",
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    player:showCards(effect.cards)
    room:obtainCard(target, Fk:getCardById(effect.cards[1]), false, fk.ReasonGive)
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p.kingdom == target.kingdom and not p:isAllNude() and not player.dead then
        room:useVirtualCard("dismantlement", nil, player, p, self.name)
      end
    end
  end,
}
dongbai:addSkill(shichong)
dongbai:addSkill(js__lianzhu)
Fk:loadTranslationTable{
  ["js__dongbai"] = "董白",
  ["shichong"] = "恃宠",
  [":shichong"] = "转换技，当你使用牌指定其他角色为唯一目标后，阳：你可以获得目标角色一张手牌；阴：目标角色可以交给你一张手牌。",
  ["js__lianzhu"] = "连诛",
  [":js__lianzhu"] = "出牌阶段限一次，你可以展示一张黑色手牌并交给一名其他角色，然后视为你对所有势力与其相同的其他角色各使用一张【过河拆桥】。",
  ["#shichong-invoke"] = "恃宠：你可以获得 %dest 一张手牌",
  ["#shichong-card"] = "恃宠：你可以交给 %src 一张手牌",
}

local nanhualaoxian = General(extension, "js__nanhualaoxian", "qun", 3)
local shoushu = fk.CreateTriggerSkill{
  name = "shoushu",
  anim_type = "support",
  events = {fk.RoundStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and not table.find(player.room.alive_players, function(p)
      return p:getEquipment(Card.SubtypeArmor) and Fk:getCardById(p:getEquipment(Card.SubtypeArmor), true).name == "peace_spell" end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p)
      return p:getEquipment(Card.SubtypeArmor) == nil end), function(p) return p.id end)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#shoushu-choose", self.name, false)
    if #to > 0 then
      to = to[1]
    else
      to = table.random(targets)
    end
    for _, id in ipairs(Fk:getAllCardIds()) do
      if Fk:getCardById(id, true).name == "peace_spell" and room:getCardArea(id) == Card.Void then
        room:moveCards({
          ids = {id},
          fromArea = Card.Void,
          to = to,
          toArea = Card.PlayerEquip,
          moveReason = fk.ReasonJustMove,
          proposer = player.id,
          skillName = self.name,
        })
        break
      end
    end
  end,

  refresh_events = {fk.BeforeCardsMove},
  can_refresh = function(self, event, target, player, data)
    return true
  end,
  on_refresh = function(self, event, target, player, data)
    local id = 0
    for i = #data, 1, -1 do
      local move = data[i]
      if move.toArea ~= Card.Void then
        for j = #move.moveInfo, 1, -1 do
          local info = move.moveInfo[j]
          if info.fromArea == Card.PlayerEquip and Fk:getCardById(info.cardId, true).name == "peace_spell" then
            id = info.cardId
            table.removeOne(move.moveInfo, info)
            break
          end
        end
      end
    end
    if id ~= 0 then
      local room = player.room
      room:sendLog{
        type = "#destructDerivedCard",
        arg = Fk:getCardById(id, true):toLogString(),
      }
      room:moveCardTo(Fk:getCardById(id, true), Card.Void, nil, fk.ReasonJustMove, "", "", true)
    end
  end,
}
local xundao = fk.CreateTriggerSkill{
  name = "xundao",
  anim_type = "control",
  events = {fk.AskForRetrial},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.map(table.filter(player.room.alive_players, function(p) return not p:isNude() end), function(p) return p.id end)
    if #targets == 0 then return end
    local tos = player.room:askForChoosePlayers(player, targets, 1, 2, "#xundao-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = {}
    for _, p in ipairs(self.cost_data) do
      local card = room:askForDiscard(room:getPlayerById(p), 1, 1, true, self.name, false, ".", "#xundao-discard:"..player.id)
      if #card > 0 then
        table.insertIfNeed(ids, card[1])
      end
    end
    for i = #ids, 1, -1 do
      if room:getCardArea(ids[i]) ~= Card.DiscardPile then
        table.removeOne(ids, ids[i])
      end
    end
    if #ids == 0 then return end
    local result = room:askForGuanxing(player, ids, {}, {1, 1}, self.name, true, {"xundao_discard", "xundao_retrial"})
    local id
    if #result.bottom > 0 then
      id = result.bottom[1]
    else
      id = table.random(ids)
    end
    local move1 = {
      ids = {id},
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    }
    local move2 = {
      ids = {data.card:getEffectiveId()},
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    }
    room:moveCards(move1, move2)
    data.card = Fk:getCardById(id)
    room:sendLog{
      type = "#ChangedJudge",
      from = player.id,
      to = {player.id},
      card = {id},
      arg = self.name
    }
  end,
}
local xuanhua = fk.CreateTriggerSkill{
  name = "xuanhua",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and (player.phase == Player.Start or player.phase == Player.Finish)
  end,
  on_cost = function(self, event, target, player, data)
    local prompt = "#xuanhua1-invoke"
    if player.phase == Player.Finish then
      prompt = "#xuanhua2-invoke"
    end
    return player.room:askForSkillInvoke(player, self.name, nil, prompt)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local pattern = ".|2~9|spade"
    if player.phase == Player.Finish then
      pattern = ".|.|^spade;.|1,10~13|spade"
    end
    local judge = {
      who = player,
      reason = "lightning",
      pattern = pattern,
    }
    room:judge(judge)
    if judge.card:matchPattern(pattern) then
      room:damage{
        to = player,
        damage = 3,
        damageType = fk.ThunderDamage,
        skillName = self.name,
      }
    end
    if not player.dead and player:getMark("xuanhua-phase") == 0 then
      local targets = table.map(table.filter(room.alive_players, function(p) return p:isWounded() end), function(p) return p.id end)
      local prompt = "#xuanhua1-choose"
      if player.phase == Player.Finish then
        targets = table.map(room.alive_players, function(p) return p.id end)
        prompt = "#xuanhua2-choose"
      end
      if #targets == 0 then return end
      local to = room:askForChoosePlayers(player, targets, 1, 1, prompt, self.name, true)
      if #to > 0 then
        if player.phase == Player.Start then
          room:recover{
            who = room:getPlayerById(to[1]),
            num = 1,
            recoverBy = player,
            skillName = self.name
          }
        else
          room:damage{
            from = player,
            to = room:getPlayerById(to[1]),
            damage = 1,
            damageType = fk.ThunderDamage,
            skillName = self.name,
          }
        end
      end
    end
  end,

  refresh_events = {fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    return target == player and data.skillName == self.name and not data.from
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "xuanhua-phase", 1)
  end,
}
nanhualaoxian:addSkill(shoushu)
nanhualaoxian:addSkill(xundao)
nanhualaoxian:addSkill(xuanhua)
Fk:loadTranslationTable{
  ["js__nanhualaoxian"] = "南华老仙",
  ["shoushu"] = "授术",
  [":shoushu"] = "锁定技，每轮开始时，若场上没有【太平要术】，你将之置入一名角色的装备区；当【太平要术】离开装备区时，销毁之。",
  ["xundao"] = "寻道",
  [":xundao"] = "当你的判定牌生效前，你可以令至多两名角色各弃置一张牌，你选择其中一张代替判定牌。",
  ["xuanhua"] = "宣化",
  [":xuanhua"] = "准备阶段，你可以进行一次【闪电】判定，若你未受到伤害，你可以令一名角色回复1点体力；"..
  "结束阶段，你可以进行一次条件反转的【闪电】判定，若你未受到伤害，你可以对一名角色造成1点雷电伤害。",
  ["#shoushu-choose"] = "授术：将【太平要术】置入一名角色的装备区",
  ["#xundao-choose"] = "寻道：你可以令至多两名角色各弃置一张牌，你选择其中一张修改你的判定",
  ["#xundao-discard"] = "寻道：你需弃置一张牌，%src 可以用之修改判定",
  ["xundao_discard"] = "弃牌",
  ["xundao_retrial"] = "修改判定",
  ["#xuanhua1-invoke"] = "宣化：你可以进行【闪电】判定，若未受到伤害，你可以令一名角色回复1点体力",
  ["#xuanhua2-invoke"] = "宣化：你可以进行反转的【闪电】判定，若未受到伤害，你可以对一名角色造成1点雷电伤害",
  ["#xuanhua1-choose"] = "宣化：你可以令一名角色回复1点体力",
  ["#xuanhua2-choose"] = "宣化：你可以对一名角色造成1点雷电伤害",
}

local yangbiao = General(extension, "js__yangbiao", "qun", 3, 4)
local js__zhaohan = fk.CreateTriggerSkill{
  name = "js__zhaohan",
  mute = true,
  events = {fk.EventPhaseStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start and
      ((player:getMark(self.name) == 0 and player:isWounded()) or player:getMark(self.name) > 0)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark(self.name) == 0 then
      room:broadcastSkillInvoke("zhaohan", 1)
      room:notifySkillInvoked(player, self.name, "support")
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      })
    else
      room:broadcastSkillInvoke("zhaohan", 2)
      room:notifySkillInvoked(player, self.name, "negative")
      room:loseHp(player, 1, self.name)
    end
  end,

  refresh_events = {fk.AfterDrawPileShuffle},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, self.name, 1)
  end,
}
local js__rangjie = fk.CreateTriggerSkill{
  name = "js__rangjie",
  events = {fk.Damaged},
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and #player.room:canMoveCardInBoard() > 0
  end,
  on_trigger = function(self, event, target, player, data)
    local ret
    for i = 1, data.damage do
      ret = self:doCost(event, target, player, data)
      if ret then return ret end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = room:askForChooseToMoveCardInBoard(player, "#js__rangjie-move", self.name, true)
    if #targets > 0 then
      self.cost_data = targets
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = self.cost_data
    local card = room:askForMoveCardInBoard(player, room:getPlayerById(targets[1]), room:getPlayerById(targets[2]), self.name).card
    if player.dead then return end
    local suit = card:getSuitString(true)
    local events = room.logic:getEventsOfScope(GameEvent.MoveCards, 999, function(e)
      local move = e.data[1]
      return move.toArea == Card.DiscardPile
    end, Player.HistoryTurn)
    local ids = {}
    for _, e in ipairs(events) do
      local move = e.data[1]
      for _, id in ipairs(move.ids) do
        if room:getCardArea(id) == Card.DiscardPile and Fk:getCardById(id, true):getSuitString(true) == suit then
          table.insertIfNeed(ids, id)
        end
      end
    end
    if #ids == 0 then return end
    if room:askForSkillInvoke(player, self.name, nil, "#js__rangjie-card:::"..suit) then
      local result = room:askForGuanxing(player, ids, nil, {1, 1}, self.name, true, {"DiscardPile", "$Hand"})
      if #result.bottom > 0 then
        local dummy = Fk:cloneCard("dilu")
        dummy:addSubcards(result.bottom)
        room:obtainCard(player, dummy, false, fk.ReasonPrey)
      end
    end
  end,
}
local js__yizheng = fk.CreateActiveSkill{
  name = "js__yizheng",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getPlayerById(to_select):getHandcardNum() > Self:getHandcardNum()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({target}, self.name)
    if pindian.results[target.id].winner == player then
      room:setPlayerMark(target, "@@js__yizheng", 1)
    else
      local choice = room:askForChoice(target, {"0", "1", "2"}, self.name, "#js__yizheng-damage:"..player.id)
      if choice ~= "0" then
        room:damage{
          from = target,
          to = player,
          damage = tonumber(choice),
          skillName = self.name,
        }
      end
    end
  end,
}
local js__yizheng_trigger = fk.CreateTriggerSkill{
  name = "#js__yizheng_trigger",

  refresh_events = {fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    return target:getMark("@@js__yizheng") > 0 and data.to == Player.Draw
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(target, "@@js__yizheng", 0)
    target:skip(Player.Draw)
  end,
}
js__yizheng:addRelatedSkill(js__yizheng_trigger)
yangbiao:addSkill(js__zhaohan)
yangbiao:addSkill(js__rangjie)
yangbiao:addSkill(js__yizheng)
Fk:loadTranslationTable{
  ["js__yangbiao"] = "杨彪",
  ["js__zhaohan"] = "昭汉",
  [":js__zhaohan"] = "锁定技，准备阶段，若牌堆未洗过牌，你回复1点体力，否则你失去1点体力。",
  ["js__rangjie"] = "让节",
  [":js__rangjie"] = "当你受到1点伤害后，你可以移动场上一张牌，然后你可以获得一张花色相同的本回合进入弃牌堆的牌。",
  ["js__yizheng"] = "义争",
  [":js__yizheng"] = "出牌阶段限一次，你可以与一名手牌数大于你的角色拼点：若你赢，其跳过下个摸牌阶段；没赢，其可以对你造成至多2点伤害。",
  ["#js__rangjie-move"] = "让节：你可以移动场上一张牌，然后可以获得一张相同花色本回合进入弃牌堆的牌",
  ["#js__rangjie-card"] = "让节：你可以获得一张本回合进入弃牌堆的%arg牌",
  ["@@js__yizheng"] = "义争",
  ["#js__yizheng-damage"] = "义争：你可以对 % src 造成至多2点伤害",
}

local kongrong = General(extension, "js__kongrong", "qun", 3)
local js__lirang = fk.CreateTriggerSkill{
  name = "js__lirang",
  anim_type = "support",
  events = {fk.EventPhaseStart, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and target ~= player then
      if event == fk.EventPhaseStart then
        return target.phase == Player.Draw and #player:getCardIds{Player.Hand, Player.Equip} > 1 and
          player:usedSkillTimes(self.name, Player.HistoryRound) == 0
      else
        return target.phase == Player.Discard and player:usedSkillTimes(self.name, Player.HistoryTurn) > 0 and
          target:getMark("js__lirang-phase") ~= 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local cards = player.room:askForCard(player, 2, 2, true, self.name, true, ".", "#js__lirang-invoke::"..target.id)
      if #cards == 2 then
        self.cost_data = cards
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dummy = Fk:cloneCard("dilu")
    if event == fk.EventPhaseStart then
      dummy:addSubcards(self.cost_data)
      room:obtainCard(target, dummy, false, fk.ReasonGive)
      room:setPlayerMark(player, "js__lirang-round", target.id)
    else
      local mark = target:getMark("js__lirang-phase")
      for _, id in ipairs(mark) do
        if room:getCardArea(id) == Card.DiscardPile then
          dummy:addSubcard(id)
        end
      end
      if #dummy.subcards > 0 then
        room:obtainCard(player, dummy, true, fk.ReasonJustMove)
      end
    end
  end,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    return player.phase == Player.Discard
  end,
  on_refresh = function(self, event, target, player, data)
    local mark = player:getMark("js__lirang-phase")
    if mark == 0 then mark = {} end
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(mark, info.cardId)
        end
      end
    end
    if #mark > 0 then
      player.room:setPlayerMark(player, "js__lirang-phase", mark)
    end
  end,
}
local zhengyi = fk.CreateTriggerSkill{
  name = "zhengyi",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player:usedSkillTimes("js__lirang", Player.HistoryRound) > 0 and
      player:getMark("zhengyi-turn") == 0 then
      player.room:addPlayerMark(player, "zhengyi-turn", 1)
      return true
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(player:getMark("js__lirang-round"))
    if to.dead then return end
    return room:askForSkillInvoke(to, self.name, nil, "#zhengyi-invoke:"..player.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local new_data = table.simpleClone(data)
    new_data.to = room:getPlayerById(player:getMark("js__lirang-round"))
    room:damage(new_data)
    return true
  end,
}
kongrong:addSkill(js__lirang)
kongrong:addSkill(zhengyi)
Fk:loadTranslationTable{
  ["js__kongrong"] = "孔融",
  ["js__lirang"] = "礼让",
  [":js__lirang"] = "每轮限一次，其他角色摸牌阶段开始时，你可以交给其两张牌，然后此回合的弃牌阶段结束时，你获得其于此阶段所有弃置的牌。",
  ["zhengyi"] = "争义",
  [":zhengyi"] = "当你每回合首次受到伤害时，本轮你发动〖礼让〗的目标角色可以将此伤害转移给其。",
  ["#js__lirang-invoke"] = "礼让：你可以将两张牌交给 %dest ，此回合弃牌阶段结束时获得其弃置的牌",
  ["#zhengyi-invoke"] = "争义：你可以将 %src 受到的伤害转移给你",
}

local wangrong = General(extension, "js__wangrongh", "qun", 3, 3, General.Female)
local fengzi = fk.CreateTriggerSkill{
  name = "fengzi",
  anim_type = "control",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and
      player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng() and data.tos and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick())
  end,
  on_cost = function(self, event, target, player, data)
    local type = data.card:getTypeString()
    local card = player.room:askForDiscard(player, 1, 1, false, self.name, true, ".|.|.|.|.|"..type,
      "#fengzi-invoke:::"..type..":"..data.card:toLogString(), true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:throwCard(self.cost_data, self.name, player, player)
    data.extra_data = data.extra_data or {}
    data.extra_data.fengzi = data.extra_data.fengzi or true
  end,

  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.fengzi
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    data.extra_data.fengzi = false
    if data.card.name == "amazing_grace" then
      room.logic:trigger(fk.CardUseFinished, player, data)
      table.forEach(room.players, function(p) room:closeAG(p) end)  --手动五谷
      if data.extra_data and data.extra_data.AGFilled then
        local toDiscard = table.filter(data.extra_data.AGFilled, function(id) return room:getCardArea(id) == Card.Processing end)
        if #toDiscard > 0 then
          room:moveCards({
            ids = toDiscard,
            toArea = Card.DiscardPile,
            moveReason = fk.ReasonPutIntoDiscardPile,
          })
        end
      end
      data.extra_data.AGFilled = nil

      local toDisplay = room:getNCards(#TargetGroup:getRealTargets(data.tos))
      room:moveCards({
        ids = toDisplay,
        toArea = Card.Processing,
        moveReason = fk.ReasonPut,
      })
      table.forEach(room.players, function(p) room:fillAG(p, toDisplay) end)
      data.extra_data = data.extra_data or {}
      data.extra_data.AGFilled = toDisplay
    end
    player.room:doCardUseEffect(data)
  end,
}
local jizhan = fk.CreateTriggerSkill{
  name = "jizhan",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local get = room:getNCards(1)
    room:moveCards{
      ids = get,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    }
    while true do
      room:delay(1000)
      local choice = room:askForChoice(player, {"jizhan_more", "jizhan_less"}, self.name, "#jizhan-choice")
      local num1 = Fk:getCardById(get[#get]).number
      local id = room:getNCards(1)[1]
      local num2 = Fk:getCardById(id).number
      room:moveCards{
        ids = {id},
        toArea = Card.Processing,
        moveReason = fk.ReasonJustMove,
        skillName = self.name,
      }
      table.insert(get, id)
      if (choice == "jizhan_more" and num1 >= num2) or (choice == "jizhan_less" and num1 <= num2) then
        room:setCardEmotion(id, "judgebad")
        room:delay(1000)
        break
      else
        room:setCardEmotion(id, "judgegood")
        room:delay(1000)
      end
    end
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(get)
    room:obtainCard(player.id, dummy, true, fk.ReasonJustMove)
    return true
  end,
}
local fusong = fk.CreateTriggerSkill{
  name = "fusong",
  anim_type = "support",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, false, true)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return p.maxHp > player.maxHp and not (p:hasSkill("fengzi", true) and p:hasSkill("jizhan", true)) end), function(p) return p.id end)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#fusong-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local choices = {}
    for _, s in ipairs({"fengzi", "jizhan"}) do
      if not to:hasSkill(s, true) then
        table.insert(choices, s)
      end
    end
    local choice = room:askForChoice(to, choices, self.name, "#fusong-choice")
    room:handleAddLoseSkills(to, choice, nil, true, false)
  end,
}
wangrong:addSkill(fengzi)
wangrong:addSkill(jizhan)
wangrong:addSkill(fusong)
Fk:loadTranslationTable{
  ["js__wangrongh"] = "王荣",
  ["fengzi"] = "丰姿",
  [":fengzi"] = "出牌阶段限一次，当你使用基本牌或普通锦囊牌时，你可以弃置一张类型相同的手牌令此牌额外结算一次。",
  ["jizhan"] = "吉占",
  [":jizhan"] = "摸牌阶段，你可以改为展示牌堆顶的一张牌，猜测牌堆顶下一张牌点数大于或小于此牌，然后展示之，若猜对则继续猜测。最后你获得所有展示的牌。",
  ["fusong"] = "赋颂",
  [":fusong"] = "当你死亡时，你可以令一名体力上限大于你的角色选择获得〖丰姿〗或〖吉占〗。",
  ["#fengzi-invoke"] = "丰姿：你可以弃置一张%arg，令%arg2额外结算一次",
  ["#jizhan-choice"] = "吉占：猜测下一张牌的点数",
  ["jizhan_more"] = "下一张牌点数较大",
  ["jizhan_less"] = "下一张牌点数较小",
  ["#fusong-choose"] = "赋颂：你可以令一名角色获得〖丰姿〗或〖吉占〗",
  ["#fusong-choice"] = "赋颂：选择你获得的技能",

  ["$fengzi1"] = "丰姿秀丽，礼法不失。",
  ["$fengzi2"] = "倩影姿态，悄然入心。",
  ["$jizhan1"] = "得吉占之兆，延福运之气。",
  ["$jizhan2"] = "吉占逢时，化险为夷。",
  ["$fusong1"] = "陛下垂爱，妾身方有此位。",
  ["$fusong2"] = "长情颂，君王恩。",
  ["~js__wangrongh"] = "只求吾儿，一生平安……",
}

local duanwei = General(extension, "js__duanwei", "qun", 4)
local langmie = fk.CreateTriggerSkill{
  name = "langmie",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and target ~= player and target.phase == Player.Finish then
      for _, mark in ipairs(target:getMarkNames()) do
        if string.find(mark, "langmie_use") and target:getMark(mark) > 1 then
          player.room:addPlayerMark(target, "langmie_use-turn", 1)
          return true
        end
      end
      return target:getMark("langmie_damage-turn") > 1
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local prompt
    if target:getMark("langmie_use-turn") > 0 and target:getMark("langmie_damage-turn") > 1 then
      prompt = "#langmie3::"..target.id
    elseif target:getMark("langmie_use-turn") > 0 then
      prompt = "#langmie1"
    else
      prompt = "#langmie2::"..target.id
    end
    local card = room:askForDiscard(player, 1, 1, true, self.name, true, ".", prompt, true)
    if #card > 0 then
      self.cost_data = {prompt, card}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data[2], self.name, player, player)
    if player.dead then return end
    if string.sub(self.cost_data[1], 9, 9) == "1" then
      player:drawCards(2, self.name)
    elseif string.sub(self.cost_data[1], 9, 9) == "2" then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
    else
      local choice = room:askForChoice(player, {"draw2", "langmie_damage"}, self.name)
      if choice == "draw2" then
        player:drawCards(2, self.name)
      else
        room:damage{
          from = player,
          to = target,
          damage = 1,
          skillName = self.name,
        }
      end
    end
  end,

  refresh_events = {fk.AfterCardUseDeclared, fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return target == player and player.phase ~= Player.NotActive
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardUseDeclared then
      room:addPlayerMark(player, "langmie_use_"..data.card:getTypeString().."-turn", 1)
    else
      room:addPlayerMark(player, "langmie_damage-turn", data.damage)
    end
  end,
}
duanwei:addSkill(langmie)
Fk:loadTranslationTable{
  ["js__duanwei"] = "段煨",
  ["langmie"] = "狼灭",
  [":langmie"] = "其他角色的结束阶段，你可以选择一项：<br>1.若其本回合使用过至少两张相同类型的牌，你可以弃置一张牌，摸两张牌；<br>"..
  "2.若其本回合造成过至少2点伤害，你可以弃置一张牌，对其造成1点伤害。",
  ["#langmie1"] = "狼灭：你可以弃置一张牌，摸两张牌",
  ["#langmie2"] = "狼灭：你可以弃置一张牌，对 %dest 造成1点伤害",
  ["#langmie3"] = "狼灭：你可以弃置一张牌，然后摸两张牌或对 %dest 造成1点伤害",
  ["langmie_damage"] = "对其造成1点伤害",

  ["$langmie1"] = "群狼四起，灭其一威众。",
  ["$langmie2"] = "贪狼强力，寡义而趋利。",
  ["~js__duanwei"] = "狼伴其侧，终不胜防。",
}

local zhujun = General(extension, "js__zhujun", "qun", 4)
local fendi = fk.CreateTriggerSkill{
  name = "fendi",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.trueName == "slash" and #AimGroup:getAllTargets(data.tos) == 1 and
      not player.room:getPlayerById(AimGroup:getAllTargets(data.tos)[1]):isKongcheng() and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    local cards = room:askForCardsChosen(player, to, 1, 999, "h", self.name)
    room:setPlayerMark(to, "fendi-turn", cards)
    to:showCards(cards)
    data.card.extra_data = data.card.extra_data or {}
    table.insert(data.card.extra_data, "fendi")
  end,

  refresh_events = {fk.Damage, fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card and data.card.extra_data and table.contains(data.card.extra_data, "fendi")
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.Damage then
      if data.to:getMark("fendi-turn") ~= 0 then
        local dummy = Fk:cloneCard("dilu")
        dummy:addSubcards(data.to:getMark("fendi-turn"))
        room:setPlayerMark(data.to, "fendi-turn", 0)
        room:obtainCard(player, dummy, false, fk.ReasonPrey)
      end
    else
      for _, id in ipairs(TargetGroup:getRealTargets(data.tos)) do
        room:setPlayerMark(room:getPlayerById(id), "fendi-turn", 0)
      end
    end
  end,
}
local fendi_prohibit = fk.CreateProhibitSkill{
  name = "#fendi_prohibit",
  prohibit_use = function(self, player, card)
    if player:getMark("fendi-turn") ~= 0 then
      return not table.contains(player:getMark("fendi-turn"), card:getEffectiveId())
    end
  end,
  prohibit_response = function(self, player, card)
    if player:getMark("fendi-turn") ~= 0 then
      return not table.contains(player:getMark("fendi-turn"), card:getEffectiveId())
    end
  end,
}
local jvxiang = fk.CreateTriggerSkill{
  name = "jvxiang",
  anim_type = "offensive",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      for _, move in ipairs(data) do
        if move.to and move.to == player.id and move.toArea == Player.Hand and player.phase ~= Player.Draw then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local prompt
    if room.current and not room.current.dead then
      prompt = "#jvxiang-invoke::"..room.current.id
    else
      prompt = "#jvxiang-discard"
    end
    return room:askForSkillInvoke(player, self.name, nil, prompt)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    local suits = {}
    for _, move in ipairs(data) do
      if move.to and move.to == player.id and move.toArea == Player.Hand and player.phase ~= Player.Draw then
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(cards, info.cardId)
          local suit = Fk:getCardById(info.cardId).suit
          if suit ~= Card.NoSuit then
            table.insertIfNeed(suits, suit)
          end
        end
      end
    end
    room:throwCard(cards, self.name, player, player)
    if room.current and not room.current.dead then
      room:addPlayerMark(room.current, "@jvxiang-turn", #suits)
    end
  end,
}
local jvxiang_targetmod = fk.CreateTargetModSkill{
  name = "#jvxiang_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("@jvxiang-turn") > 0 and scope == Player.HistoryPhase then
      return player:getMark("@jvxiang-turn")
    end
  end,
}
fendi:addRelatedSkill(fendi_prohibit)
jvxiang:addRelatedSkill(jvxiang_targetmod)
zhujun:addSkill(fendi)
zhujun:addSkill(jvxiang)
Fk:loadTranslationTable{
  ["js__zhujun"] = "朱儁",
  ["fendi"] = "分敌",
  [":fendi"] = "每回合限一次，当你使用【杀】指定唯一目标后，你可以展示其至少一张手牌，然后令其只能使用或打出此次展示的牌直到此【杀】结算完毕。"..
  "若如此做，当此【杀】对其造成伤害后，你获得这些牌。",
  ["jvxiang"] = "拒降",
  [":jvxiang"] = "当你于摸牌阶段外获得牌后，你可以弃置这些牌，令当前回合角色于本回合出牌阶段使用【杀】次数上限+X（X为你此次弃置牌的花色数）。",
  ["#jvxiang-invoke"] = "拒降：你可以弃置这些牌，令 %dest 本回合使用【杀】次数上限增加",
  ["#jvxiang-discard"] = "拒降：你可以弃置这些牌",
  ["@jvxiang-turn"] = "拒降",
}

local liuyan = General(extension, "js__liuyan", "qun", 3)
local js__tushe = fk.CreateTriggerSkill{
  name = "js__tushe",
  anim_type = "drawcard",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.type ~= Card.TypeEquip and
      data.firstTarget and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#js__tushe-invoke:::"..#AimGroup:getAllTargets(data.tos))
  end,
  on_use = function(self, event, target, player, data)
    player:showCards(player.player_cards[Player.Hand])
    if #table.filter(player:getCardIds(Player.Hand), function(cid)
      return Fk:getCardById(cid).type == Card.TypeBasic end) == 0 and #AimGroup:getAllTargets(data.tos) > 0 then
      player:drawCards(#AimGroup:getAllTargets(data.tos), self.name)
    end
  end,
}
local js__limu = fk.CreateActiveSkill{
  name = "js__limu",
  anim_type = "control",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return not player:hasDelayedTrick("indulgence")
  end,
  card_filter = function(self, to_select, selected)
    local card = Fk:getCardById(to_select)
    return #selected == 0 and card.suit == Card.Diamond and not Self:isProhibited(Self, Fk:cloneCard("indulgence", card.suit, card.number))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:useVirtualCard("indulgence", effect.cards, player, player, self.name, true)
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        skillName = self.name
      }
    end
  end,
}
local js__limu_targetmod = fk.CreateTargetModSkill{
  name = "#js__limu_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return player:hasSkill("js__limu") and scope == Player.HistoryPhase and
      #player:getCardIds(Player.Judge) > 0 and player:inMyAttackRange(to)
  end,
  bypass_distances = function(self, player, skill, card, to)
    return player:hasSkill("js__limu") and #player:getCardIds(Player.Judge) > 0 and player:inMyAttackRange(to)
  end,
}
local tongjue = fk.CreateActiveSkill{
  name = "tongjue$",
  anim_type = "support",
  min_card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and to_select ~= Self.id and target.kingdom == "qun" and target:getMark("tongjue-turn") == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:obtainCard(target, effect.cards[1], false, fk.ReasonGive)
    room:addPlayerMark(target, "tongjue-turn", 1)
    if not player:isKongcheng() then
      room:askForUseActiveSkill(player, self.name, "#tongjue-invoke", true)
    end
  end,
}
local tongjue_prohibit = fk.CreateProhibitSkill{
  name = "#tongjue_prohibit",
  is_prohibited = function(self, from, to, card)
    if from:usedSkillTimes("tongjue", Player.HistoryTurn) > 0 then
      return to:getMark("tongjue-turn") > 0
    end
  end,
}
js__limu:addRelatedSkill(js__limu_targetmod)
tongjue:addRelatedSkill(tongjue_prohibit)
liuyan:addSkill(js__limu)
liuyan:addSkill(js__tushe)
liuyan:addSkill(tongjue)
Fk:loadTranslationTable{
  ["js__liuyan"] = "刘焉",
  ["js__limu"] = "立牧",
  [":js__limu"] = "出牌阶段，你可以将一张<font color='red'>♦</font>牌当【乐不思蜀】对你使用，然后你回复1点体力；"..
  "若你的判定区里有牌，则你对攻击范围内的其他角色使用牌无次数和距离限制。",
  ["js__tushe"] = "图射",
  [":js__tushe"] = "当你使用非装备牌指定目标后，你可以展示所有手牌，若其中没有基本牌，则你摸X张牌（X为此牌指定的目标数）。",
  ["tongjue"] = "通绝",
  [":tongjue"] = "主公技，出牌阶段限一次，你可以将任意张手牌交给等量的其他群势力角色各一张，若如此做，于此回合内不能选择这些角色为你使用牌的目标。",
  ["#js__tushe-invoke"] = "图射：你可以展示所有手牌，若其中没有基本牌，则摸%arg张牌",
  ["#tongjue-invoke"] = "通绝：你可以将一张手牌交给一名其他群势力角色",

  ["$js__limu1"] = "米贼作乱，吾必为益州自保。",
  ["$js__limu2"] = "废史立牧，可得一方安定。",
  ["$js__tushe1"] = "非英杰不图？吾既谋之且射毕！",
  ["$js__tushe2"] = "汉室衰微，朝纲祸乱，必图后福。",
  ["~js__liuyan"] = "背疮难治，世子难继。",
}

local liubei = General(extension, "js__liubei", "qun", 4)
local jishan = fk.CreateTriggerSkill{
  name = "jishan",
  anim_type = "support",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#jishan-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, self.name)
    room:addPlayerMark(target, self.name, 1)
    if not player.dead then
      player:drawCards(1, self.name)
      target:drawCards(1, self.name)
    end
    return true
  end,
}
local jishan_trigger = fk.CreateTriggerSkill{
  name = "#jishan_trigger",
  anim_type = "support",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, to in ipairs(room:getAlivePlayers()) do
      if to:getMark("jishan") > 0 and to:isWounded() and table.every(room:getAlivePlayers(), function(p) return p.hp >= to.hp end) then
        table.insert(targets, to.id)
      end
    end
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#jishan-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover{
      who = player.room:getPlayerById(self.cost_data),
      num = 1,
      recoverBy = player,
      skillName = self.name
    }
  end,
}
local zhenqiao = fk.CreateTriggerSkill{
  name = "zhenqiao",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.trueName == "slash" and player:getEquipment(Card.SubtypeWeapon) == nil
  end,
  on_use = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.zhenqiao = data.extra_data.zhenqiao or true
  end,

  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.zhenqiao
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:doCardUseEffect(data)
    data.extra_data.zhenqiao = false
  end,
}
local zhenqiao_attackrange = fk.CreateAttackRangeSkill{
  name = "#zhenqiao_attackrange",
  frequency = Skill.Compulsory,
  correct_func = function (self, from, to)
    if from:hasSkill("zhenqiao") then
      return 1
    end
    return 0
  end,
}
jishan:addRelatedSkill(jishan_trigger)
zhenqiao:addRelatedSkill(zhenqiao_attackrange)
liubei:addSkill(jishan)
liubei:addSkill(zhenqiao)
Fk:loadTranslationTable{
  ["js__liubei"] = "刘备",
  ["jishan"] = "积善",
  [":jishan"] = "每回合各限一次，1.当一名角色受到伤害时，你可以失去1点体力防止此伤害，然后你与其各摸一张牌；"..
  "2.当你造成伤害后，你可以令一名体力值最小且你对其发动过〖积善〗的角色回复1点体力。",
  ["zhenqiao"] = "振鞘",
  [":zhenqiao"] = "锁定技，你的攻击范围+1；当你使用【杀】指定目标后，若你的装备区没有武器牌，则此【杀】额外结算一次。",
  ["#jishan-invoke"] = "积善：你可以失去1点体力防止 %dest 受到的伤害，然后你与其各摸一张牌",
  ["#jishan_trigger"] = "积善",
  ["#jishan-choose"] = "积善：你可以令一名角色回复1点体力",

  -- CV: 玖心粽子
  ["$jishan1"] = "勿以善小而不为。",
  ["$jishan2"] = "积善成德，而神明自得。",
  ["$zhenqiao1"] = "豺狼满朝，且看我剑出鞘。",
  ["$zhenqiao2"] = "欲信大义，此剑一匡天下。",
  ["~js__liubei"] = "大义未信，唯念黎庶之苦……",
}

local wangyun = General(extension, "js__wangyun", "qun", 3)
local shelun = fk.CreateActiveSkill{
  name = "shelun",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#shelun",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and Self:inMyAttackRange(Fk:currentRoom():getPlayerById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local targets = table.filter(room:getOtherPlayers(target), function(p)
      return not p:isKongcheng() and p:getHandcardNum() <= player:getHandcardNum() end)
    room:delay(1500)
    room:doIndicate(player.id, table.map(targets, function(p) return p.id end))
    local discussion = Discussion{
      reason = self.name,
      from = player,
      tos = targets,
      results = {},
    }
    if discussion.color == "red" then
      if not target.dead and not target:isNude() and not player.dead then
        local id = room:askForCardChosen(player, target, "he", self.name)
        room:throwCard({id}, self.name, target, player)
      end
    elseif discussion.color == "black" then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
    end
  end,
}
local fayi = fk.CreateTriggerSkill{
  name = "fayi",
  anim_type = "offensive",
  events = {"fk.DiscussionFinished"},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and data.results[player.id] then
      return table.find(data.tos, function(p)
        return not p.dead and data.results[p.id] and data.results[player.id].toCard.color ~= data.results[p.id].toCard.color end)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.filter(data.tos, function(p)
      return not p.dead and data.results[p.id] and data.results[player.id].toCard.color ~= data.results[p.id].toCard.color
    end)
    local to = player.room:askForChoosePlayers(player, table.map(targets, function(p)
      return p.id end), 1, 1, "#fayi-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:damage{
      from = player,
      to = player.room:getPlayerById(self.cost_data),
      damage = 1,
      skillName = self.name,
    }
  end,
}
wangyun:addSkill(shelun)
wangyun:addSkill(fayi)
Fk:loadTranslationTable{
  ["js__wangyun"] = "王允",
  ["shelun"] = "赦论",
  [":shelun"] = "出牌阶段限一次，你可以选择一名攻击范围内的其他角色，然后你令除其外所有手牌数不大于你的角色议事，结果为：红色，你弃置其一张牌；"..
  "黑色，你对其造成1点伤害。",
  ["fayi"] = "伐异",
  [":fayi"] = "当你参与议事结束后，你可以对一名意见与你不同的角色造成1点伤害。",
  ["#shelun"] = "赦论：指定一名角色，除其外所有手牌数不大于你的角色议事<br>红色：你弃置目标一张牌；黑色，你对目标造成1点伤害",
  ["#fayi-choose"] = "伐异：你可以对一名意见与你不同的角色造成1点伤害",
}

return extension
