local extension = Package("beginning")
extension.extensionName = "jsrg"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["beginning"] = "江山如故·起",
  ["js"] = "江山",
}

local caocao = General(extension, "js__caocao", "qun", 4)
local zhenglue = fk.CreateTriggerSkill{
  name = "zhenglue",
  anim_type = "control",
  events = {fk.TurnEnd, fk.Damage},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.TurnEnd then
        return target.role == "lord"
      elseif event == fk.Damage then
        return target and target == player and data.to:getMark("@@caocao_lie") > 0 and player:getMark("zhenglue-turn") == 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.TurnEnd then
      return player.room:askForSkillInvoke(player, self.name, nil, "#zhenglue1-trigger")
    elseif event == fk.Damage then
      return player.room:askForSkillInvoke(player, self.name, nil, "#zhenglue2-trigger")
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, self.name)
    if player.dead then return end
    if event == fk.TurnEnd then
      local targets = table.map(table.filter(room.alive_players, function(p)
        return p:getMark("@@caocao_lie") == 0
      end), Util.IdMapper)
      if #targets == 0 then return end
      local x = 1
      if #targets > 1 and #player.room.logic:getActualDamageEvents(1, function (e)
        local damage = e.data[1]
        if target == damage.from then
          return true
        end
      end, Player.HistoryTurn) == 0 then
        x = 2
      end
      local tos = room:askForChoosePlayers(player, targets, 1, x, "#zhenglue-choose:::" .. tostring(x), self.name, false)
      for _, to in ipairs(tos) do
        room:setPlayerMark(room:getPlayerById(to), "@@caocao_lie", 1)
      end
    elseif event == fk.Damage then
      room:setPlayerMark(player, "zhenglue-turn", 1)
      if data.card and room:getCardArea(data.card) == Card.Processing then
        room:moveCardTo(data.card, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
      end
    end
  end,
}
local zhenglue_targetmod = fk.CreateTargetModSkill{
  name = "#zhenglue_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return card and player:hasSkill(zhenglue) and to and to:getMark("@@caocao_lie") > 0
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and player:hasSkill(zhenglue) and to and to:getMark("@@caocao_lie") > 0
  end,
}
local huilie = fk.CreateTriggerSkill{
  name = "huilie",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #table.filter(player.room.alive_players, function (p) return p:getMark("@@caocao_lie") > 0 end) > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if not player.dead then
      room:handleAddLoseSkills(player, "pingrong|feiying", nil)
    end
  end,
}
local pingrong = fk.CreateTriggerSkill{
  name = "pingrong",
  anim_type = "special",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.phase == Player.Finish and
    player:usedSkillTimes(self.name, Player.HistoryRound) == 0 and table.find(player.room.alive_players, function (p)
      return p:getMark("@@caocao_lie") > 0
    end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return p:getMark("@@caocao_lie") > 0
    end)
    local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#pingrong-choose", self.name, true)
    if #to > 0 then
      self.cost_data = {tos = to}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    room:setPlayerMark(to, "@@caocao_lie", 0)
    room:addPlayerMark(player, "@@pingrong_extra", 1)
    if player == target then
      room:setPlayerMark(player, "pingrong_self-turn", 1)
    end
    player:gainAnExtraTurn()
  end,

  refresh_events = {fk.TurnedOver, fk.AfterTurnEnd, fk.Damage},
  can_refresh = function(self, event, target, player, data)
    --FIXME:巨大隐患
    if player ~= target or player:getMark("@@pingrong_extra") == 0 then return false end
    if event == fk.TurnedOver then
      local e = player.room.logic:getCurrentEvent()
      return e.parent == nil or e:findParent(GameEvent.Turn, true) == nil
    elseif event == fk.AfterTurnEnd then
      return player:getMark("pingrong_self-turn") == 0
    elseif event == fk.Damage then
      return true
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@pingrong_extra", 0)
  end,
}
local pingrong_delay = fk.CreateTriggerSkill{
  name = "#pingrong_delay",
  anim_type = "negative",
  events = {fk.EventPhaseStart},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player == target and player.phase == Player.Finish and
    player:getMark("@@pingrong_extra") ~= 0 and player:getMark("pingrong_self-turn") == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, self.name)
  end,
}
zhenglue:addRelatedSkill(zhenglue_targetmod)
pingrong:addRelatedSkill(pingrong_delay)
caocao:addSkill(zhenglue)
caocao:addSkill(huilie)
caocao:addRelatedSkill(pingrong)
caocao:addRelatedSkill("feiying")
Fk:loadTranslationTable{
  ["js__caocao"] = "曹操",
  ["#js__caocao"] = "汉征西将军",
  ["cv:js__caocao"] = "樰默",
  ["illustrator:js__caocao"] = "凡果",

  ["zhenglue"] = "政略",
  [":zhenglue"] = "主公角色的回合结束时，你可以摸一张牌，然后令一名没有“猎”的角色获得“猎”，若主公角色于此回合内未造成过伤害，"..
  "则改为令至多两名没有“猎”的角色获得“猎”。<br>你对有“猎”的角色使用牌无距离和次数限制。<br>"..
  "每名角色的回合限一次，当你对有“猎”的角色造成伤害后，你可以摸一张牌并获得造成此伤害的牌。",
  ["huilie"] = "会猎",
  [":huilie"] = "觉醒技，准备阶段，若有“猎”的角色数大于2，你减1点体力上限，然后获得〖平戎〗和〖飞影〗。",
  ["pingrong"] = "平戎",
  [":pingrong"] = "每轮限一次，一名角色的结束阶段，你可以选择一名有“猎”的角色移去其“猎”，然后获得一个额外的回合，"..
  "此回合的结束阶段，若你于此回合内未造成过伤害，你失去1点体力。",
  ["@@caocao_lie"] = "猎",
  ["#zhenglue_trigger"] = "政略",
  ["#zhenglue-choose"] = "政略：选择至多%arg名角色，令其获得“猎”标记",
  ["#zhenglue1-trigger"] = "政略：是否摸一张牌并令角色获得“猎”？",
  ["#zhenglue2-trigger"] = "政略：你可以摸一张牌并获得造成伤害的牌",
  ["#pingrong_delay"] = "平戎",
  ["@@pingrong_extra"] = "平戎",
  ["#pingrong-choose"] = "平戎：你可以移去一名角色的“猎”标记，然后你执行一个额外回合",

  -- CV: 樰默
  ["$zhenglue1"] = "治政用贤不以德，则四方定。",
  ["$zhenglue2"] = "秉至公而服天下，孤大略成。",
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
  prompt = "#pingtao",
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
    local card = room:askForCard(target, 1, 1, true, self.name, true, ".", "#pingtao-card:"..player.id)
    if #card > 0 then
      room:moveCardTo(Fk:getCardById(card[1]), Card.PlayerHand, player, fk.ReasonGive, self.name, nil, false, target.id)
      room:addPlayerMark(player, MarkEnum.SlashResidue.."-phase", 1)
    else
      room:useVirtualCard("slash", nil, player, target, self.name, true)
    end
  end,
}
local juelie = fk.CreateTriggerSkill{
  name = "juelie",
  anim_type = "offensive",
  events = {fk.DamageCaused, fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.card and data.card.trueName == "slash" then
      if event == fk.DamageCaused then
        local room = player.room
        return not data.chain and (table.every(room.alive_players, function (p)
          return p:getHandcardNum() >= player:getHandcardNum()
        end) or table.every(room.alive_players, function (p)
          return p.hp >= player.hp
        end))
      elseif event == fk.TargetSpecified then
        local to = player.room:getPlayerById(data.to)
        return not to.dead and not player:isNude()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DamageCaused then
      return true
    else
      local cards = room:askForDiscard(player, 1, 999, true, self.name, true, ".", "#juelie-discard::"..data.to, true)
      if #cards > 0 then
        self.cost_data = {cards = cards}
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.DamageCaused then
      data.damage = data.damage + 1
    else
      local room = player.room
      local cards = table.simpleClone(self.cost_data.cards)
      room:throwCard(cards, self.name, player, player)
      local to = room:getPlayerById(data.to)
      if player.dead or to.dead or to:isNude() then return end
      cards = room:askForCardsChosen(player, to, 1, math.min(#cards, #to:getCardIds("he")), "he", self.name)
      room:throwCard(cards, self.name, to, player)
    end
  end,
}
sunjian:addSkill(pingtao)
sunjian:addSkill(juelie)
Fk:loadTranslationTable{
  ["js__sunjian"] = "孙坚",
  ["#js__sunjian"] = "拨定烈志",
  ["cv:js__sunjian"] = "樰默",
  ["illustrator:js__sunjian"] = "凡果",

  ["pingtao"] = "平讨",
  [":pingtao"] = "出牌阶段限一次，你可以令一名其他角色选择一项：1.交给你一张牌，然后你此阶段使用【杀】次数上限+1；"..
  "2.令你视为对其使用一张无距离和次数限制的【杀】。",
  ["juelie"] = "绝烈",
  [":juelie"] = "当你使用【杀】造成伤害时，若你是手牌数最小或体力值最小的角色，则此伤害+1；当你使用【杀】指定目标后，你可以弃置任意张牌，"..
  "然后弃置其至多等量的牌。",
  ["#pingtao"] = "平讨：令一名角色选择交给你一张牌或视为你对其使用【杀】",
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
    return target == player and player:hasSkill(self) and player.phase == Player.Start and
      not table.every(player.room:getOtherPlayers(player, false), function(p) return p:isKongcheng() end)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#chaozheng-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p) return not p:isKongcheng() end)
    if #targets == 0 then return end
    room:doIndicate(player.id, table.map(targets, Util.IdMapper))
    local discussion = U.Discussion(player, targets, self.name)
    if discussion.color == "red" then
      for _, p in ipairs(targets) do
        if p:isWounded() and not p.dead and discussion.results[p.id].opinion == "red" then
          room:recover({
            who = p,
            num = 1,
            recoverBy = player,
            skillName = self.name,
          })
        end
      end
    elseif discussion.color == "black" then
      for _, p in ipairs(targets) do
        if not p.dead and discussion.results[p.id].opinion == "red" then
          room:loseHp(p, 1, self.name)
        end
      end
    end
    if not player.dead and table.every(targets, function(p)
      return discussion.results[p.id].opinion == discussion.results[targets[1].id].opinion end) then
      player:drawCards(#targets, self.name)
    end
  end,
}
local shenchong = fk.CreateActiveSkill{
  name = "shenchong",
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  prompt = "#shenchong",
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
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
  mute = true,
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("shenchong") ~= 0 and not player.room:getPlayerById(player:getMark("shenchong")).dead
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("shenchong")
    room:notifySkillInvoked(player, "shenchong", "negative")
    local to = room:getPlayerById(player:getMark("shenchong"))
    room:doIndicate(player.id, {to.id})
    local skills = table.map(table.filter(to.player_skills, function(skill)
      return skill:isPlayerSkill(to)
    end), function(s)
      return s.name
    end)
    room:handleAddLoseSkills(to, "-"..table.concat(skills, "|-"), nil, true, false)
    to:throwAllCards("h")
  end,
}
local julian = fk.CreateTriggerSkill{
  name = "julian$",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.AfterCardsMove then
        for _, move in ipairs(data) do
          if move.to and move.to ~= player.id then
            local to = player.room:getPlayerById(move.to)
            if to.kingdom == "qun" and move.moveReason == fk.ReasonDraw and move.skillName ~= self.name and to.phase ~= Player.Draw and
              to:getMark("julian-turn") < 2 and not to.dead then
              return true
            end
          end
        end
      elseif event == fk.EventPhaseStart and player.phase == Player.Finish then
        return table.find(player.room.alive_players, function(p)
          return p ~= player and p.kingdom == "qun" and not p:isKongcheng() end)
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.to and move.to ~= player.id then
          local to = player.room:getPlayerById(move.to)
          if to.kingdom == "qun" and move.moveReason == fk.ReasonDraw and move.skillName ~= self.name and to.phase ~= Player.Draw and
            to:getMark("julian-turn") < 2 and not to.dead then
            self:doCost(event, target, player, {to = to})
          end
        end
      end
    elseif event == fk.EventPhaseStart then
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      if room:askForSkillInvoke(data.to, self.name, nil, "#julian-draw") then
        self.cost_data = nil
        return true
      end
    else
      if room:askForSkillInvoke(player, self.name, nil, "#julian-invoke") then
        self.cost_data = { tos = table.map(table.filter(room:getAlivePlayers(), function(p)
          return p ~= player and p.kingdom == "qun"
        end), Util.IdMapper) }
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardsMove then
      room:addPlayerMark(data.to, "julian-turn", 1)
      data.to:drawCards(1, self.name)
    else
      local tos = table.map(self.cost_data.tos, Util.Id2PlayerMapper)
      for _, p in ipairs(tos) do
        if not p:isKongcheng() then
          local id = room:askForCardChosen(player, p, "h", self.name)
          room:obtainCard(player, id, false, fk.ReasonPrey, player.id, self.name)
          if player.dead then break end
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
  ["#js__liuhong"] = "轧庭焚礼",
  ["illustrator:js__liuhong"] = "君桓文化",

  ["chaozheng"] = "朝争",
  [":chaozheng"] = "准备阶段，你可以令所有其他角色议事，结果为：红色，意见为红色的角色各回复1点体力；黑色，意见为红色的角色各失去1点体力。"..
  "若所有角色意见相同，则议事结束后，你摸X张牌（X为此次议事的角色数）。",
  ["shenchong"] = "甚宠",
  [":shenchong"] = "限定技，出牌阶段，你可以令一名其他角色获得〖飞扬〗和〖跋扈〗，若如此做，当你死亡时，其失去所有技能，然后其弃置全部手牌。",
  ["julian"] = "聚敛",
  [":julian"] = "主公技，其他群势力角色每回合限两次，当其于其摸牌阶段外不因此技能而摸牌后，其可以摸一张牌；<br>"..
  "结束阶段，你可以获得所有其他群势力角色各一张手牌。",
  ["#chaozheng-invoke"] = "朝争：你可以令所有其他角色议事！",
  ["#shenchong"] = "甚宠：令一名其他角色获得〖飞扬〗和〖跋扈〗！",
  ["#julian-draw"] = "聚敛：你可以摸一张牌",
  ["#julian-invoke"] = "聚敛：你可以获得所有其他群势力角色各一张手牌",
}

local huangfusong = General(extension, "js__huangfusong", "qun", 4)
local guanhuo = fk.CreateActiveSkill{
  name = "guanhuo",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#guanhuo",
  can_use = function(self, player)
    return not player:prohibitUse(Fk:cloneCard("fire_attack"))
  end,
  card_filter = Util.FalseFunc,
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
    return target == player and player:hasSkill(self) and data.from and data.from ~= player.id and
      #table.filter(player.room:getPlayerById(data.from).player_skills, function(skill)
        return skill:isPlayerSkill(player.room:getPlayerById(data.from))
      end) > #table.filter(player.player_skills, function(skill)
        return skill:isPlayerSkill(player)
      end) and
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
  ["#js__huangfusong"] = "安危定倾",
  ["illustrator:js__huangfusong"] = "君桓文化",

  ["guanhuo"] = "观火",
  [":guanhuo"] = "出牌阶段，你可以视为使用一张【火攻】。当你以此法使用的未造成伤害的【火攻】结算后，若此次为你于此阶段内第一次发动本技能，"..
  "则你令你此阶段内你使用【火攻】造成的伤害+1，否则你失去〖观火〗。",
  ["juxia"] = "居下",
  [":juxia"] = "每名角色的回合限一次，当其他角色使用牌指定你为目标后，若其技能数大于你，则其可以令此牌对你无效，然后令你摸两张牌。",
  ["#guanhuo"] = "观火：你可以视为使用一张【火攻】",
  ["@@guanhuo-phase"] = "观火",
  ["#juxia-invoke"] = "居下：你可以令%arg对 %src 无效并令其摸两张牌",
}

local qiaoxuan = General(extension, "qiaoxuan", "qun", 3)
local js__juezhi = fk.CreateTriggerSkill{
  name = "js__juezhi",
  anim_type = "special",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
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
          if info.fromArea == Card.PlayerEquip and player:hasSkill(self) and
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
      player.phase ~= Player.NotActive and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("js__juezhi")
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
    return target == player and player:hasSkill(self) and (player.phase == Player.Start or player.phase == Player.Finish)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p)
      return not p:isKongcheng() or table.find(room.alive_players, function(to)
        return p:canMoveCardsInBoardTo(to, nil)
      end)
    end), Util.IdMapper)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#jizhaoq-choose", self.name, true)
    if #to > 0 then
      self.cost_data = {tos = to}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
    local use = nil
    if not to:isKongcheng() then
      use = U.askForUseRealCard(room, to, to:getCardIds("h"), ".", self.name, "#jizhaoq-use:"..player.id, {bypass_times = true}, true, true)
    end
    if use then
      use.extraUse = true
      room:useCard(use)
    else
      local choices = {}
      if not to:isKongcheng() then table.insert(choices, "jizhaoq_hand") end
      local targets = table.filter(room.alive_players, function(p) return to:canMoveCardsInBoardTo(p, nil) end)
      if #targets > 0 then table.insert(choices, "jizhaoq_board") end
      if #choices == 0 then return end
      local choice = room:askForChoice(player, choices, self.name)
      if choice == "jizhaoq_hand" then targets = room:getOtherPlayers(to) end
      local t = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#jizhaoq-move::"..to.id, self.name, true)
      if #t > 0 then
        if choice == "jizhaoq_hand" then
          local cid = room:askForCardChosen(player, to, "h", self.name)
          room:moveCardTo(cid, Player.Hand, room:getPlayerById(t[1]), fk.ReasonJustMove, self.name, nil, false, player.id)
        else
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
  ["#qiaoxuan"] = "泛爱博容",
  ["illustrator:qiaoxuan"] = "君桓文化",

  ["js__juezhi"] = "绝质",
  [":js__juezhi"] = "当你失去一张装备区里的装备牌后，你可以废除对应的装备栏；你回合内每阶段限一次，当你使用牌对目标角色造成伤害时，"..
  "其装备区里每有一张与你已废除装备栏对应的装备牌，此伤害便+1。",
  ["jizhaoq"] = "急召",
  [":jizhaoq"] = "准备阶段和结束阶段，你可以令一名角色选择一项：1.使用一张手牌；2.令你可以移动其区域里的一张牌。",
  ["#js__juezhi-invoke"] = "绝质：你失去了%arg，是否废除对应的装备栏？",
  ["#jizhaoq-choose"] = "急召：你可以指定一名角色，令其选择使用一张手牌或你移动其区域内一张牌",
  ["#jizhaoq-use"] = "急召：使用一张手牌，或点“取消” %src 可以移动你区域内一张牌",
  ["#jizhaoq-move"] = "急召：你可以选择一名角色，将 %dest 区域内的一张牌移至目标角色区域",
  ["jizhaoq_hand"] = "移动手牌",
  ["jizhaoq_board"] = "移动场上牌",
}

local xushao = General(extension, "js__xushao", "qun", 3)
---@param player ServerPlayer
local addFangkeSkill = function(player, skillName)
  local room = player.room
  local skill = Fk.skills[skillName]
  if (not skill) or skill.lordSkill or skill.switchSkillName
    or skill.frequency > 3 -- 锁定技=3 后面的都是特殊标签
    or player:hasSkill(skill, true) then
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
  skill:onAcquire(player)
end

---@param player ServerPlayer
---@param skillName string
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
  skill:onLose(player)
end

---@param player ServerPlayer
---@param general General
local function addFangke(player, general, addSkill)
  local room = player.room
  room:addTableMarkIfNeed(player, "@&js_fangke", general.name)

  if not addSkill then return end
  for _, s in ipairs(general.skills) do
    addFangkeSkill(player, s.name)
  end
  for _, sname in ipairs(general.other_skills) do
    addFangkeSkill(player, sname)
  end
end

local banned_fangke = {
  "starsp__xiahoudun",  -- 原因：无敌
  "shichangshi",   -- 原因：变将与休整
  "godjiaxu", "zhangfei","js__huangzhong", "liyixiejing", "olz__wangyun", "yanyan", "duanjiong", "wolongfengchu", "wuanguo",
  "os__wangling", -- 原因：没有可用技能
  "js__pangtong", "os__xia__liubei", -- 原因：发动技能逻辑缺陷
}

local yingmen = fk.CreateTriggerSkill{
  name = "yingmen",
  events = {fk.GameStart, fk.TurnStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, _)
    if event == fk.GameStart then
      return player:hasSkill(self)
    else
      return target == player and player:hasSkill(self) and #player:getTableMark("@&js_fangke") < 4
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local exclude_list = table.map(room.players, function(p)
      return p.general
    end)
    table.insertTable(exclude_list, banned_fangke)
    for _, p in ipairs(room.players) do
      local deputy = p.deputyGeneral
      if deputy and deputy ~= "" then
        table.insert(exclude_list, deputy)
      end
    end

    local m = player:getMark("@&js_fangke")
    local n = 4
    if event ~= fk.GameStart then
      n = 4 - #player:getTableMark("@&js_fangke")
    end
    local generals = table.random(room.general_pile, n)
    for _, g in ipairs(generals) do
      addFangke(player, Fk.generals[g], player:hasSkill("js__pingjian", true))
    end
  end,

  refresh_events = {fk.SkillEffect},
  can_refresh = function (self, event, target, player, data)
    return target == player and player:getMark("js_fangke_skills") ~= 0 and
      table.contains(player:getMark("js_fangke_skills"), data.name)
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    for _, s in ipairs(data.related_skills) do
      if s:isInstanceOf(StatusSkill) then
        room:addSkill(s)
      end
    end
  end,
}

xushao:addSkill(yingmen)

---@param player ServerPlayer
---@param general_name string
local function removeFangke(player, general_name)
  local room = player.room
  local glist = player:getMark("@&js_fangke")
  if glist == 0 then return end
  table.removeOne(glist, general_name)
  room:setPlayerMark(player, "@&js_fangke", #glist > 0 and glist or 0)

  local general = Fk.generals[general_name]
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
    return target == player and player:hasSkill(self) and #player:getTableMark("@&js_fangke") > 0
      and player:getMark("js_fangke_skills") ~= 0 and
      table.contains(player:getMark("js_fangke_skills"), data.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, _, target, player, data)
    local room = player.room
    local choices = player:getMark("@&js_fangke")
    local owner = table.find(choices, function (name)
      local general = Fk.generals[name]
      return table.contains(general:getSkillNameList(), data.name)
    end) or "?"
    local choice = choices[1]
    if #choices > 1 then
      local result = player.room:askForCustomDialog(player, self.name,
      "packages/utility/qml/ChooseGeneralsAndChoiceBox.qml", {
        choices,
        {"OK"},
        "#js_lose_fangke:::"..owner,
      })
      if result ~= "" then
        local reply = json.decode(result)
        choice = reply.cards[1]
      end
    end
    removeFangke(player, choice)
    if choice == owner and not player.dead then
      player:drawCards(1, self.name)
    end
  end,

  on_lose = function (self, player)
    if player:getMark("@&js_fangke") ~= 0 then
      for _, g in ipairs(player:getMark("@&js_fangke")) do
        removeFangke(player, g)
      end
    end
  end,
}
xushao:addSkill(pingjian)
Fk:loadTranslationTable{
  ["js__xushao"] = "许劭",
  ["#js__xushao"] = "识人读心",
  ["cv:js__xushao"] = "樰默",
  ["illustrator:js__xushao"] = "凡果",

  ["yingmen"] = "盈门",
  [":yingmen"] = "锁定技，游戏开始时，你在剩余武将牌堆中随机获得四张武将牌置于你的武将牌上，称为“访客”；回合开始前，若你的“访客”数少于四张，"..
  "则你从剩余武将牌堆中将“访客”补至四张。",
  ["@&js_fangke"] = "访客",
  ["#js_lose_fangke"] = "评鉴：移除一张访客，若移除 %arg 则摸牌",
  ["js__pingjian"] = "评鉴",
  [":js__pingjian"] = "当“访客”上的无类型标签或者只有锁定技标签的技能满足发动时机时，你可以发动该技能。"..
  "此技能的效果结束后，你须移除一张“访客”，若移除的是含有该技能的“访客”，你摸一张牌。" ..
  '<br/><font color="red">（注：由于判断发动技能的相关机制尚不完善，请不要汇报发动技能后某些情况下访客不丢的bug）</font>',

  --CV：樰默
  ["$yingmen1"] = "韩侯不顾？德高，门楣自盈。",
  ["$yingmen2"] = "贫而不阿，名广，胜友满座。",
  ["$js__pingjian1"] = "太丘道广，广则不周。仲举性峻，峻则少通。",
  ["$js__pingjian2"] = "君生清平则为奸逆，处乱世当居豪雄。",
  ["~js__xushao"] = "运去朋友散，满屋余风雨……",
}

local hejin = General(extension, "js__hejin", "qun", 4)
local zhaobing = fk.CreateTriggerSkill{
  name = "zhaobing",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and not player:isKongcheng() and
      table.find(player:getCardIds("h"), function (id)
        return not player:prohibitDiscard(id)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#zhaobing-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getHandcardNum()
    player:throwAllCards("h")
    if player.dead then return end
    local targets = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player, false), Util.IdMapper), 1, n,
      "#zhaobing-choose:::"..n, self.name, true)
    if #targets == 0 then return end
    room:sortPlayersByAction(targets)
    for _, id in ipairs(targets) do
      local p = room:getPlayerById(id)
      if not p.dead then
        if p:isKongcheng() or player.dead then
          room:loseHp(p, 1, self.name)
        else
          local card = room:askForCard(p, 1, 1, false, self.name, true, "slash", "#zhaobing-card:"..player.id)
          if #card > 0 then
            p:showCards(card)
            if not player.dead and table.contains(p:getCardIds("h"), card[1]) then
              room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonGive, self.name, nil, true, p.id)
            end
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
    return target == player and player:hasSkill(self) and player.phase == Player.Start and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#zhuhuanh-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getCardIds("h")
    player:showCards(cards)
    if player.dead then return end
    cards = table.filter(cards, function (id)
      return table.contains(player:getCardIds("h"), id) and Fk:getCardById(id).trueName == "slash" and not player:prohibitDiscard(id)
    end)
    local n = #cards
    room:throwCard(cards, self.name, player, player)
    if player.dead then return end
    local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#zhuhuanh-choose:::"..n, self.name, false)
    to = room:getPlayerById(to[1])
    local choice = room:askForChoice(to, {"zhuhuanh_damage:::"..n, "zhuhuanh_recover::"..player.id..":"..n}, self.name)
    if choice:startsWith("zhuhuanh_damage") then
      room:damage{
        from = player,
        to = to,
        damage = 1,
        skillName = self.name,
      }
      if not to.dead and not to:isNude() and n > 0 then
        room:askForDiscard(to, n, n, true, self.name, false)
      end
    else
      if player:isWounded() then
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name,
        })
      end
      if not player.dead and n > 0 then
        player:drawCards(n, self.name)
      end
    end
  end,
}
hejin:addSkill(zhaobing)
hejin:addSkill(zhuhuanh)
hejin:addSkill("ty__yanhuo")
Fk:loadTranslationTable{
  ["js__hejin"] = "何进",
  ["#js__hejin"] = "独意误国谋",
  ["illustrator:js__hejin"] = "凡果_棉鞋",

  ["zhaobing"] = "诏兵",
  [":zhaobing"] = "结束阶段，你可以弃置全部手牌，然后令至多等量的其他角色各选择一项：1.展示并交给你一张【杀】；2.失去1点体力。",
  ["zhuhuanh"] = "诛宦",
  [":zhuhuanh"] = "准备阶段，你可以展示所有手牌并弃置所有【杀】，然后令一名其他角色选择一项：1.受到1点伤害，然后弃置等量的牌；"..
  "2.你回复1点体力，然后摸等量的牌。",
  ["#zhaobing-invoke"] = "诏兵：你可以弃置全部手牌，令等量其他角色选择交给你一张【杀】或失去1点体力",
  ["#zhaobing-choose"] = "诏兵：选择至多%arg名其他角色，依次选择交给你一张【杀】或失去1点体力",
  ["#zhaobing-card"] = "诏兵：交给 %src 一张【杀】，否则失去1点体力",
  ["#zhuhuanh-invoke"] = "诛宦：你可以展示手牌并弃置所有【杀】，令一名其他角色选择受到伤害并弃牌/你回复体力并摸牌",
  ["#zhuhuanh-choose"] = "诛宦：令一名其他角色选择：受到1点伤害并弃%arg张牌 / 你回复1点体力并摸%arg张牌",
  ["zhuhuanh_damage"] = "你受到1点伤害，并弃置%arg牌",
  ["zhuhuanh_recover"] = "%dest回复1点体力，并摸%arg牌",
}

local dongbai = General(extension, "js__dongbai", "qun", 3, 3, General.Female)
local shichong = fk.CreateTriggerSkill{
  name = "shichong",
  anim_type = "switch",
  switch_skill_name = "shichong",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.tos and #AimGroup:getAllTargets(data.tos) == 1 and
      data.to ~= player.id and not player.room:getPlayerById(data.to):isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if player:getSwitchSkillState(self.name, false) == fk.SwitchYang then
      if room:askForSkillInvoke(player, self.name, nil, "#shichong-invoke::"..data.to) then
        self.cost_data = {tos = {data.to}}
      end
    else
      local to = room:getPlayerById(data.to)
      local card = room:askForCard(to, 1, 1, false, self.name, true, ".", "#shichong-card:"..player.id)
      if #card > 0 then
        self.cost_data = {cards = card}
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getSwitchSkillState(self.name, true) == fk.SwitchYang then
      local to = room:getPlayerById(data.to)
      local card = room:askForCardChosen(player, to, "h", self.name)
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id)
    else
      room:moveCardTo(self.cost_data.cards, Card.PlayerHand, player, fk.ReasonGive, self.name, nil, false, data.to)
    end
  end,
}
local js__lianzhu = fk.CreateActiveSkill{
  name = "js__lianzhu",
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  prompt = "#js__lianzhu",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black and table.contains(Self:getCardIds("h"), to_select)
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    player:showCards(effect.cards)
    if player.dead or target.dead then return end
    if table.contains(player:getCardIds("h"), effect.cards[1]) then
      room:moveCardTo(effect.cards, Card.PlayerHand, target, fk.ReasonGive, self.name, nil, false, player.id)
    end
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
  ["#js__dongbai"] = "魔姬",
  ["illustrator:js__dongbai"] = "SoniaTang",

  ["shichong"] = "恃宠",
  [":shichong"] = "转换技，当你使用牌指定其他角色为唯一目标后，阳：你可以获得目标角色一张手牌；阴：目标角色可以交给你一张手牌。",
  ["js__lianzhu"] = "连诛",
  [":js__lianzhu"] = "出牌阶段限一次，你可以展示一张黑色手牌并交给一名其他角色，然后视为你对所有势力与其相同的其他角色各使用一张【过河拆桥】。",
  ["#shichong-invoke"] = "恃宠：你可以获得 %dest 一张手牌",
  ["#shichong-card"] = "恃宠：你可以交给 %src 一张手牌",
  ["#js__lianzhu"] = "连诛：你可以将一张黑色手牌展示并交给一名角色，然后视为对所有势力与其相同的其他角色各使用一张【过河拆桥】",
}

local nanhualaoxian = General(extension, "js__nanhualaoxian", "qun", 3)
local shoushu = fk.CreateTriggerSkill{
  name = "shoushu",
  anim_type = "support",
  events = {fk.RoundStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    local room = player.room
    return player:hasSkill(self) and
      room:getCardArea(U.prepareDeriveCards(room, {{"js__peace_spell", Card.Heart, 3}}, "shoushu_spell")[1]) == Card.Void and
      table.find(room.alive_players, function(p)
        return p:hasEmptyEquipSlot(Card.SubtypeArmor)
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p) return p:hasEmptyEquipSlot(Card.SubtypeArmor) end)
    local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#shoushu-choose", self.name, false)
    to = room:getPlayerById(to[1])
    local spell = U.prepareDeriveCards(room, {{"js__peace_spell", Card.Heart, 3}}, "shoushu_spell")[1]
    room:setCardMark(Fk:getCardById(spell), MarkEnum.DestructOutEquip, 1)
    room:moveCardIntoEquip(to, spell, self.name, true, player)
  end,
}
local xundao = fk.CreateTriggerSkill{
  name = "xundao",
  anim_type = "control",
  events = {fk.AskForRetrial},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      table.find(player.room.alive_players, function(p)
        return not p:isNude()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p) return not p:isNude() end)
    local tos = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 2, "#xundao-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = {tos = tos}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:sortPlayersByAction(self.cost_data.tos)
    local ids = {}
    for _, id in ipairs(self.cost_data.tos) do
      local p = room:getPlayerById(id)
      if not p.dead and not p:isNude() then
        local card = room:askForDiscard(p, 1, 1, true, self.name, false, ".", "#xundao-discard:"..player.id)
        table.insertIfNeed(ids, card[1])
      end
    end
    if player.dead then return end
    ids = table.filter(ids, function (id)
      return table.contains(room.discard_pile, id)
    end)
    if #ids == 0 then return end
    local cards = U.askforChooseCardsAndChoice(player, ids, {"OK"}, self.name, "#xundao-retrial")
    room:retrial(Fk:getCardById(cards[1]), player, data, self.name)
  end,
}
local xuanhua = fk.CreateTriggerSkill{
  name = "xuanhua",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (player.phase == Player.Start or player.phase == Player.Finish)
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
      local targets = table.map(table.filter(room.alive_players, function(p) return p:isWounded() end), Util.IdMapper)
      local prompt = "#xuanhua1-choose"
      if player.phase == Player.Finish then
        targets = table.map(room.alive_players, Util.IdMapper)
        prompt = "#xuanhua2-choose"
      end
      if #targets == 0 then return end
      local to = room:askForChoosePlayers(player, targets, 1, 1, prompt, self.name, true)
      if #to > 0 then
        to = room:getPlayerById(to[1])
        if player.phase == Player.Start then
          room:recover{
            who = to,
            num = 1,
            recoverBy = player,
            skillName = self.name,
          }
        else
          room:damage{
            from = player,
            to = to,
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
    return target == player and data.skillName == self.name
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
  ["#js__nanhualaoxian"] = "冯虚御风",
  ["illustrator:js__nanhualaoxian"] = "君桓文化",

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
  ["#xundao-retrial"] = "寻道：选择用来修改判定的牌",
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
    return target == player and player:hasSkill(self) and player.phase == Player.Start and
      ((player:getMark(self.name) == 0 and player:isWounded()) or player:getMark(self.name) > 0)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark(self.name) == 0 then
      player:broadcastSkillInvoke("zhaohan", 1)
      room:notifySkillInvoked(player, self.name, "support")
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      })
    else
      player:broadcastSkillInvoke("zhaohan", 2)
      room:notifySkillInvoked(player, self.name, "negative")
      room:loseHp(player, 1, self.name)
    end
  end,

  refresh_events = {fk.AfterDrawPileShuffle},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self, true)
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
    return target == player and player:hasSkill(self) and #player.room:canMoveCardInBoard() > 0
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
      self.cost_data = {tos = targets}
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = self.cost_data.tos
    local result = room:askForMoveCardInBoard(player, room:getPlayerById(targets[1]), room:getPlayerById(targets[2]), self.name)
    if player.dead then return end
    local suit = result.card:getSuitString(true)
    local cards = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if table.contains(room.discard_pile, info.cardId) and Fk:getCardById(info.cardId):getSuitString(true) == suit then
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
      end
    end, Player.HistoryTurn)
    if #cards > 0 then
      cards = U.askforChooseCardsAndChoice(player, cards, {"OK"}, self.name, "#js__rangjie-prey:::"..suit, {"Cancel"})
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
      end
    end
  end,
}
local js__yizheng = fk.CreateActiveSkill{
  name = "js__yizheng",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#js__yizheng",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and target:getHandcardNum() > Self:getHandcardNum() and Self:canPindian(target)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({target}, self.name)
    if pindian.results[target.id].winner == player then
      if not target.dead then
        room:setPlayerMark(target, "@@js__yizheng", 1)
      end
    else
      if player.dead or target.dead then return end
      local choice = room:askForChoice(target, {"0", "1", "2"}, self.name, "#js__yizheng-damage:"..player.id)
      if choice ~= "0" then
        room:doIndicate(target.id, {player.id})
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
  events = {fk.EventPhaseChanging},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player == target and target:getMark("@@js__yizheng") > 0 and data.to == Player.Draw
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@js__yizheng", 0)
    player:skip(Player.Draw)
    return true
  end,
}
js__yizheng:addRelatedSkill(js__yizheng_trigger)
yangbiao:addSkill(js__zhaohan)
yangbiao:addSkill(js__rangjie)
yangbiao:addSkill(js__yizheng)
Fk:loadTranslationTable{
  ["js__yangbiao"] = "杨彪",
  ["#js__yangbiao"] = "德彰海内",
  ["illustrator:js__yangbiao"] = "木美人",

  ["js__zhaohan"] = "昭汉",
  [":js__zhaohan"] = "锁定技，准备阶段，若牌堆未洗过牌，你回复1点体力，否则你失去1点体力。",
  ["js__rangjie"] = "让节",
  [":js__rangjie"] = "当你受到1点伤害后，你可以移动场上一张牌，然后你可以获得一张花色相同的本回合进入弃牌堆的牌。",
  ["js__yizheng"] = "义争",
  [":js__yizheng"] = "出牌阶段限一次，你可以与一名手牌数大于你的角色拼点：若你赢，其跳过下个摸牌阶段；没赢，其可以对你造成至多2点伤害。",
  ["#js__rangjie-move"] = "让节：你可以移动场上一张牌，然后可以获得一张相同花色本回合进入弃牌堆的牌",
  ["#js__rangjie-prey"] = "让节：你可以获得一张本回合进入弃牌堆的%arg牌",
  ["#js__yizheng"] = "义争：你可以与一名手牌数大于你的角色拼点，若赢，其跳过下个摸牌阶段；没赢，其可以对你造成至多2点伤害",
  ["@@js__yizheng"] = "义争",
  ["#js__yizheng-damage"] = "义争：你可以对 %src 造成至多2点伤害",
}

local kongrong = General(extension, "js__kongrong", "qun", 3)
local js__lirang = fk.CreateTriggerSkill{
  name = "js__lirang",
  anim_type = "support",
  events = {fk.EventPhaseStart, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target ~= player then
      if event == fk.EventPhaseStart then
        return player:hasSkill(self) and target.phase == Player.Draw and #player:getCardIds("he") > 1 and
          player:usedSkillTimes(self.name, Player.HistoryRound) == 0
      else
        return target.phase == Player.Discard and player:usedSkillTimes(self.name, Player.HistoryTurn) > 0
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      local cards = player.room:askForCard(player, 2, 2, true, self.name, true, ".", "#js__lirang-invoke::"..target.id)
      if #cards == 2 then
        self.cost_data = {tos = {target.id}, cards = cards}
        return true
      end
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:setPlayerMark(player, "js__lirang-round", target.id)
      room:moveCardTo(self.cost_data.cards, Card.PlayerHand, target, fk.ReasonGive, self.name, nil, true, player.id)
    else
      local cards = {}
      room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.from == target.id and move.moveReason == fk.ReasonDiscard then
            for _, info in ipairs(move.moveInfo) do
              table.insertIfNeed(cards, info.cardId)
            end
          end
        end
      end, Player.HistoryPhase)
      cards = table.filter(cards, function(id) return table.contains(room.discard_pile, id) end)
      if #cards == 0 then return end
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
    end
  end,
}
local zhengyi = fk.CreateTriggerSkill{
  name = "zhengyi",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes("js__lirang", Player.HistoryRound) > 0 and
      #player.room.logic:getEventsOfScope(GameEvent.Damage, 2, function (e)
        return e.data[1].to == player
      end, Player.HistoryTurn) == 1 and
      not player.room:getPlayerById(player:getMark("js__lirang-round")).dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    return room:askForSkillInvoke(room:getPlayerById(player:getMark("js__lirang-round")), self.name, nil,
      "#zhengyi-invoke:"..player.id)
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
  ["#js__kongrong"] = "北海太守",
  ["illustrator:js__kongrong"] = "凝聚永恒",
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
    return target == player and player:hasSkill(self) and player.phase == Player.Play and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and data.tos and
      player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local type = data.card:getTypeString()
    local card = player.room:askForDiscard(player, 1, 1, false, self.name, true, ".|.|.|.|.|"..type,
      "#fengzi-invoke:::"..type..":"..data.card:toLogString(), true)
    if #card > 0 then
      self.cost_data = {cards = card}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:throwCard(self.cost_data.cards, self.name, player, player)
    data.additionalEffect = (data.additionalEffect or 0) + 1
  end,
}
local jizhan = fk.CreateTriggerSkill{
  name = "jizhan",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local get = room:getNCards(1)
    room:moveCardTo(get, Card.Processing, nil, fk.ReasonJustMove, self.name, nil, true, player.id)
    while true do
      room:delay(500)
      local num1 = Fk:getCardById(get[#get]).number
      local choice = room:askForChoice(player, {"jizhan_more", "jizhan_less"}, self.name, "#jizhan-choice:::"..tostring(num1))
      local id = room:getNCards(1)[1]
      local num2 = Fk:getCardById(id).number
      room:moveCardTo(id, Card.Processing, nil, fk.ReasonJustMove, self.name, nil, true, player.id)
      table.insert(get, id)
      if (choice == "jizhan_more" and num1 >= num2) or (choice == "jizhan_less" and num1 <= num2) then
        room:setCardEmotion(id, "judgebad")
        room:delay(600)
        break
      else
        room:setCardEmotion(id, "judgegood")
        room:delay(600)
      end
    end
    room:moveCardTo(get, Card.PlayerHand, player, fk.ReasonJustMove, self.name, nil, true, player.id)
    return true
  end,
}
local fusong = fk.CreateTriggerSkill{
  name = "fusong",
  anim_type = "support",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, false, true) and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return p.maxHp > player.maxHp and not (p:hasSkill("fengzi", true) and p:hasSkill("jizhan", true))
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return p.maxHp > player.maxHp and not (p:hasSkill("fengzi", true) and p:hasSkill("jizhan", true))
    end)
    local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#fusong-choose", self.name, true)
    if #to > 0 then
      self.cost_data = {tos = to}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
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
  ["#js__wangrongh"] = "灵怀皇后",
  ["illustrator:js__wangrongh"] = "君桓文化",
  ["fengzi"] = "丰姿",
  [":fengzi"] = "每阶段限一次，当你于出牌阶段内使用基本牌或普通锦囊牌时，你可以弃置一张类型相同的手牌令此牌额外结算一次。",
  ["jizhan"] = "吉占",
  [":jizhan"] = "摸牌阶段，你可以改为展示牌堆顶的一张牌，猜测牌堆顶下一张牌点数大于或小于此牌，然后展示之，若猜对则继续猜测。最后你获得"..
  "所有展示的牌。",
  ["fusong"] = "赋颂",
  [":fusong"] = "当你死亡时，你可以令一名体力上限大于你的角色选择获得〖丰姿〗或〖吉占〗。",
  ["#fengzi-invoke"] = "丰姿：你可以弃置一张%arg，令%arg2额外结算一次",
  ["#jizhan-choice"] = "吉占：猜测下一张牌的点数与上一张（%arg点）比大小",
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
    if player:hasSkill(self) and target ~= player and target.phase == Player.Finish and not player:isNude() then
      local room = player.room
      self.cost_data = {}
      local count = {0, 0, 0}
      room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
        local use = e.data[1]
        if use.from == target.id then
          if use.card.type == Card.TypeBasic then
            count[1] = count[1] + 1
          elseif use.card.type == Card.TypeTrick then
            count[2] = count[2] + 1
          elseif use.card.type == Card.TypeEquip then
            count[3] = count[3] + 1
          end
        end
      end, Player.HistoryTurn)
      if table.find(count, function(i) return i > 1 end) then
        table.insert(self.cost_data, 1)
      end
      local n = 0
      room.logic:getActualDamageEvents(1, function(e)
        local damage = e.data[1]
        if damage.from and target == damage.from then
          n = n + damage.damage
        end
      end, Player.HistoryTurn)
      if n > 1 then
        table.insert(self.cost_data, 2)
      end
      if #self.cost_data == 2 then
        return true
      elseif #self.cost_data == 1 then
        if self.cost_data[1] == 1 then
          return true
        elseif self.cost_data[1] == 2 then
          return not target.dead
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local prompt
    if #self.cost_data == 2 then
      prompt = "#langmie3::"..target.id
    elseif self.cost_data[1] == 1 then
      prompt = "#langmie1"
    elseif self.cost_data[1] == 2 then
      prompt = "#langmie2::"..target.id
    end
    local card = room:askForDiscard(player, 1, 1, true, self.name, true, nil, prompt, true)
    if #card > 0 then
      self.cost_data = {cards = card, choice = prompt[9]}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data.cards, self.name, player, player)
    if player.dead then return end
    if self.cost_data.choice == "1" then
      player:drawCards(2, self.name)
    elseif self.cost_data.choice == "2" then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
    elseif self.cost_data.choice == "3" then
      if target.dead then
        player:drawCards(2, self.name)
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
    end
  end,
}
duanwei:addSkill(langmie)
Fk:loadTranslationTable{
  ["js__duanwei"] = "段煨",
  ["#js__duanwei"] = "凉国之英",
  ["illustrator:js__duanwei"] = "匠人绘",
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
    return target == player and player:hasSkill(self) and data.card.trueName == "slash" and
      #AimGroup:getAllTargets(data.tos) == 1 and not player.room:getPlayerById(data.to):isKongcheng() and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    local cards = room:askForCardsChosen(player, to, 1, 999, "h", self.name)
    to:showCards(cards)
    if to.dead then return end
    cards = table.filter(cards, function (id)
      return table.contains(to:getCardIds("h"), id)
    end)
    if #cards == 0 then return end
    local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if use_event == nil then return end
    room:setPlayerMark(player, "fendi_record", {use_event.id, to.id, cards})
    local mark = to:getTableMark("fendi_prohibit")
    for _, id in ipairs(cards) do
      table.insertIfNeed(mark, id)
      room:addCardMark(Fk:getCardById(id), "@@fendi-inhand", 1)
    end
    room:setPlayerMark(to, "fendi_prohibit", mark)
  end,

  refresh_events = {fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    local mark = player:getMark("fendi_record")
    if type(mark) == "table" then
      return mark[1] == player.room.logic:getCurrentEvent().id
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("fendi_record")
    local to = room:getPlayerById(mark[2])
    local cards = mark[3]
    room:setPlayerMark(player, "fendi_record", 0)
    if to.dead then return end
    local mark2 = to:getMark("fendi_prohibit")
    for _, id in ipairs(cards) do
      if table.removeOne(mark2, id) then
        room:removeCardMark(Fk:getCardById(id), "@@fendi-inhand", 1)
      end
    end
    room:setPlayerMark(to, "fendi_prohibit", #mark2 > 0 and mark2 or 0)
  end,
}
local fendi_delay = fk.CreateTriggerSkill{
  name = "#fendi_delay",
  events = {fk.Damage},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if data.card == nil or player.dead then return false end
    local room = player.room
    local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if use_event == nil then return false end
    local mark = player:getMark("fendi_record")
    if type(mark) == "table" and mark[1] == use_event.id and mark[2] == data.to.id then
      return table.find(mark[3], function (id)
        return table.contains(room.discard_pile, id) or table.contains(data.to:getCardIds("h"), id)
      end)
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getMark("fendi_record")[3], function (id)
      return table.contains(room.discard_pile, id) or table.contains(data.to:getCardIds("h"), id)
    end)
    if #cards > 0 then
      room:moveCardTo(cards, Player.Hand, player, fk.ReasonPrey, fendi.name, nil, true, player.id)
    end
  end,
}
local fendi_prohibit = fk.CreateProhibitSkill{
  name = "#fendi_prohibit",
  prohibit_use = function(self, player, card)
    local mark = player:getMark("fendi_prohibit")
    if type(mark) ~= "table" then return false end
    local cardList = card:isVirtual() and card.subcards or {card.id}
    return #cardList > 0 and table.find(cardList, function (id)
      return not table.contains(mark, id)
    end)
  end,
  prohibit_response = function(self, player, card)
    local mark = player:getMark("fendi_prohibit")
    if type(mark) ~= "table" then return false end
    local cardList = card:isVirtual() and card.subcards or {card.id}
    return #cardList > 0 and table.find(cardList, function (id)
      return not table.contains(mark, id)
    end)
  end,
}
local jvxiang = fk.CreateTriggerSkill{
  name = "jvxiang",
  anim_type = "offensive",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      for _, move in ipairs(data) do
        if move.to and move.to == player.id and move.toArea == Player.Hand and player.phase ~= Player.Draw then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#jvxiang-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    local suits = {}
    for _, move in ipairs(data) do
      if move.to == player.id and move.toArea == Player.Hand and player.phase ~= Player.Draw then
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
    local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn)
    if turn_event and not turn_event.data[1].dead then
      room:addPlayerMark(turn_event.data[1], MarkEnum.SlashResidue.."-turn", #suits)
    end
  end,
}
fendi:addRelatedSkill(fendi_delay)
fendi:addRelatedSkill(fendi_prohibit)
zhujun:addSkill(fendi)
zhujun:addSkill(jvxiang)
Fk:loadTranslationTable{
  ["js__zhujun"] = "朱儁",
  ["#js__zhujun"] = "征无遗虑",
  ["illustrator:js__zhujun"] = "沉睡千年",
  ["fendi"] = "分敌",
  [":fendi"] = "每回合限一次，当你使用【杀】指定唯一目标后，你可以展示其至少一张手牌，然后令其只能使用或打出此次展示的牌直到此【杀】结算完毕。"..
  "若如此做，当此【杀】对其造成伤害后，你获得其手牌区或弃牌堆里的这些牌。",
  ["jvxiang"] = "拒降",
  [":jvxiang"] = "当你于摸牌阶段外获得牌后，你可以弃置这些牌，令当前回合角色于本回合出牌阶段使用【杀】次数上限+X（X为你此次弃置牌的花色数）。",
  ["#jvxiang-invoke"] = "拒降：是否弃置这些牌，令当前回合角色使用【杀】次数上限增加？",
  ["#fendi_delay"] = "分敌",
  ["@@fendi-inhand"] = "分敌",
}

local liuyan = General(extension, "js__liuyan", "qun", 3)
local js__tushe = fk.CreateTriggerSkill{
  name = "js__tushe",
  anim_type = "drawcard",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.type ~= Card.TypeEquip and data.firstTarget
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#js__tushe-invoke:::"..#AimGroup:getAllTargets(data.tos))
  end,
  on_use = function(self, event, target, player, data)
    if not player:isKongcheng() then
      player:showCards(player.player_cards[Player.Hand])
    end
    if player.dead then return end
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
  prompt = "#js__limu",
  can_use = Util.TrueFunc,
  card_filter = function(self, to_select, selected)
    local card = Fk:getCardById(to_select)
    return #selected == 0 and card.suit == Card.Diamond and
      not Self:isProhibited(Self, Fk:cloneCard("indulgence", card.suit, card.number))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:useVirtualCard("indulgence", effect.cards, player, player, self.name, true)
    if player:isWounded() and not player.dead then
      room:recover{
        who = player,
        num = 1,
        skillName = self.name,
      }
    end
  end,
}
local js__limu_targetmod = fk.CreateTargetModSkill{
  name = "#js__limu_targetmod",
  main_skill = js__limu,
  bypass_times = function(self, player, skill, scope, card, to)
    return player:hasSkill(js__limu) and scope == Player.HistoryPhase and
    card and #player:getCardIds("j") > 0 and player:inMyAttackRange(to)
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and player:hasSkill(js__limu) and #player:getCardIds("j") > 0 and player:inMyAttackRange(to)
  end,
}
local tongjue = fk.CreateActiveSkill{
  name = "tongjue$",
  anim_type = "support",
  card_num = 0,
  target_num = 0,
  prompt = "#tongjue-invoke",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng() and
      table.find(Fk:currentRoom().alive_players, function(p) return p ~= player and p.kingdom == "qun" end)
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local list = room:askForYiji(
      player,
      player:getCardIds(Player.Hand),
      table.filter(
        room.alive_players,
        function(p)
          return
            p ~= player and
            p.kingdom == "qun"
        end
      ),
      self.name,
      1,
      999,
      "#tongjue-invoke",
      nil,
      false,
      1
    )
    if player.dead then return end
    local mark = player:getTableMark("tongjue-turn")
    for key, value in pairs(list) do
      if #value > 0 then
        table.insert(mark, key)
      end
    end
    room:setPlayerMark(player, "tongjue-turn", mark)
  end,
}
local tongjue_prohibit = fk.CreateProhibitSkill{
  name = "#tongjue_prohibit",
  is_prohibited = function(self, from, to, card)
    if from and card then
      return table.contains(from:getTableMark("tongjue-turn"), to.id)
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
  ["#js__liuyan"] = "裂土之宗",
  ["illustrator:js__liuyan"] = "心中一凛",
  ["js__limu"] = "立牧",
  [":js__limu"] = "出牌阶段，你可以将一张<font color='red'>♦</font>牌当【乐不思蜀】对你使用，然后你回复1点体力；"..
  "若你的判定区里有牌，则你对攻击范围内的其他角色使用牌无次数和距离限制。",
  ["js__tushe"] = "图射",
  [":js__tushe"] = "当你使用非装备牌指定目标后，你可以展示所有手牌（没有手牌则跳过），若其中没有基本牌，则你摸X张牌（X为此牌指定的目标数）。",
  ["tongjue"] = "通绝",
  [":tongjue"] = "主公技，出牌阶段限一次，你可以将任意张手牌交给等量的其他群势力角色各一张，若如此做，于此回合内不能选择这些角色为你使用牌的目标。",
  ["#js__limu"] = "立牧：你可以将一张<font color='red'>♦</font>牌当【乐不思蜀】对你使用，然后你回复1点体力",
  ["#js__tushe-invoke"] = "图射：你可以展示所有手牌，若其中没有基本牌，则摸%arg张牌",
  ["#tongjue-invoke"] = "通绝：你可以将手牌分配其他群势力角色（每名角色至多1张）",

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
  events = {fk.DamageInflicted, fk.Damage},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.DamageInflicted then
        return player:getMark("jishan_prevent-turn") == 0
      else
        return target == player and player:getMark("jishan_recover-turn") == 0 and
          table.find(player.room.alive_players, function(to)
            return table.contains(player:getTableMark("jishan_record"), to.id) and to:isWounded() and
              table.every(player.room.alive_players, function(p) return p.hp >= to.hp end)
          end)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.DamageInflicted then
      if player.room:askForSkillInvoke(player, self.name, nil, "#jishan-invoke::"..target.id) then
        self.cost_data = {tos = {target.id}}
        return true
      end
    else
      local room = player.room
      local targets = table.filter(room.alive_players, function(to)
        return table.contains(player:getTableMark("jishan_record"), to.id) and to:isWounded() and
          table.every(room.alive_players, function(p) return p.hp >= to.hp end)
      end)
      local to = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#jishan-choose", self.name, true)
      if #to > 0 then
        self.cost_data = {tos = to}
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.DamageInflicted then
      room:setPlayerMark(player, "jishan_prevent-turn", 1)
      room:addTableMarkIfNeed(player, "jishan_record", target.id)
      room:loseHp(player, 1, self.name)
      if not player.dead then
        player:drawCards(1, self.name)
      end
      if not target.dead then
        target:drawCards(1, self.name)
      end
      return true
    else
      room:setPlayerMark(player, "jishan_recover-turn", 1)
      room:recover{
        who = room:getPlayerById(self.cost_data.tos[1]),
        num = 1,
        recoverBy = player,
        skillName = self.name
      }
    end
  end,
}
local zhenqiao = fk.CreateTriggerSkill{
  name = "zhenqiao",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash" and data.firstTarget
      and #player:getEquipments(Card.SubtypeWeapon) == 0
  end,
  on_use = function(self, event, target, player, data)
    data.additionalEffect = (data.additionalEffect or 0) + 1
  end,
}
local zhenqiao_attackrange = fk.CreateAttackRangeSkill{
  name = "#zhenqiao_attackrange",
  frequency = Skill.Compulsory,
  main_skill = zhenqiao,
  correct_func = function (self, from, to)
    if from:hasSkill(zhenqiao) then
      return 1
    end
    return 0
  end,
}
zhenqiao:addRelatedSkill(zhenqiao_attackrange)
liubei:addSkill(jishan)
liubei:addSkill(zhenqiao)
Fk:loadTranslationTable{
  ["js__liubei"] = "刘备",
  ["#js__liubei"] = "负戎荷戈",
  ["cv:js__liubei"] = "玖心粽子",
  ["illustrator:js__liubei"] = "君桓文化",

  ["jishan"] = "积善",
  [":jishan"] = "每回合各限一次，1.当一名角色受到伤害时，你可以失去1点体力防止此伤害，然后你与其各摸一张牌；"..
  "2.当你造成伤害后，你可以令一名体力值最小且你对其发动过〖积善〗的角色回复1点体力。",
  ["zhenqiao"] = "振鞘",
  [":zhenqiao"] = "锁定技，你的攻击范围+1；当你使用【杀】指定目标后，若你的装备区没有武器牌，则此【杀】额外结算一次。",
  ["#jishan-invoke"] = "积善：你可以失去1点体力防止 %dest 受到的伤害，然后你与其各摸一张牌",
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
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and Self:inMyAttackRange(Fk:currentRoom():getPlayerById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local targets = table.filter(room:getOtherPlayers(target), function(p)
      return not p:isKongcheng() and p:getHandcardNum() <= player:getHandcardNum() end)
    room:delay(1500)
    room:doIndicate(player.id, table.map(targets, Util.IdMapper))
    local discussion = U.Discussion(player, targets, self.name)
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
    return player:hasSkill(self) and data.results[player.id] and
      table.find(data.tos, function(p)
        return not p.dead and data.results[p.id] and data.results[player.id].opinion ~= data.results[p.id].opinion
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.filter(data.tos, function(p)
      return not p.dead and data.results[p.id] and data.results[player.id].opinion ~= data.results[p.id].opinion
    end)
    local to = player.room:askForChoosePlayers(player, table.map(targets, Util.IdMapper), 1, 1, "#fayi-choose", self.name, true)
    if #to > 0 then
      self.cost_data = {tos = to}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:damage{
      from = player,
      to = player.room:getPlayerById(self.cost_data.tos[1]),
      damage = 1,
      skillName = self.name,
    }
  end,
}
wangyun:addSkill(shelun)
wangyun:addSkill(fayi)
Fk:loadTranslationTable{
  ["js__wangyun"] = "王允",
  ["#js__wangyun"] = "居功自矜",
  ["illustrator:js__wangyun"] = "凡果",
  ["shelun"] = "赦论",
  [":shelun"] = "出牌阶段限一次，你可以选择一名攻击范围内的其他角色，然后你令除其外所有手牌数不大于你的角色议事，结果为：红色，你弃置其一张牌；"..
  "黑色，你对其造成1点伤害。",
  ["fayi"] = "伐异",
  [":fayi"] = "当你参与议事结束后，你可以对一名意见与你不同的角色造成1点伤害。",
  ["#shelun"] = "赦论：指定一名角色，除其外所有手牌数不大于你的角色议事<br>红色：你弃置目标一张牌；黑色，你对目标造成1点伤害",
  ["#fayi-choose"] = "伐异：你可以对一名意见与你不同的角色造成1点伤害",
}

return extension
