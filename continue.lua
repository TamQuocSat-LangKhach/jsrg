local extension = Package("continue")
extension.extensionName = "jsrg"

Fk:loadTranslationTable{
  ["continue"] = "江山如故-承包",
}

---@param player ServerPlayer @ 目标玩家
---@param kingdom string @ 要变为的势力
--变更势力并增删势力技
local function ChangeKingdom(player, kingdom)
  kingdom = kingdom or "qun"
  local room = player.room
  if player.kingdom == kingdom then return end
  local skills = {}
  for _, s in ipairs(Fk.generals[player.general].skills) do
    if #s.attachedKingdom > 0 and table.contains(s.attachedKingdom, player.kingdom) then
      table.insertIfNeed(skills, "-"..s.name)
    end
  end
  if player.deputyGeneral ~= "" then
    for _, s in ipairs(Fk.generals[player.deputyGeneral].skills) do
      if #s.attachedKingdom > 0 and table.contains(s.attachedKingdom, player.kingdom) then
        table.insertIfNeed(skills, "-"..s.name)
      end
    end
  end
  player.kingdom = kingdom
  room:broadcastProperty(player, "kingdom")
  for _, s in ipairs(Fk.generals[player.general].skills) do
    if #s.attachedKingdom > 0 and table.contains(s.attachedKingdom, player.kingdom) then
      table.insertIfNeed(skills, s.name)
    end
  end
  if player.deputyGeneral ~= "" then
    for _, s in ipairs(Fk.generals[player.deputyGeneral].skills) do
      if #s.attachedKingdom > 0 and table.contains(s.attachedKingdom, player.kingdom) then
        table.insertIfNeed(skills, s.name)
      end
    end
  end
  if #skills > 0 then
    room:handleAddLoseSkills(player, table.concat(skills, "|"), nil, true, false)
  end
end

local sunce = General(extension, "js__sunce", "wu", 4)
local duxing = fk.CreateActiveSkill{
  name = "duxing",
  anim_type = "offensive",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 999,
  prompt = "#duxing",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    local card = Fk:cloneCard("duel")
    card.skillName = self.name
    return card.skill:modTargetFilter(to_select, selected, Self.id,card)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local targets = table.map(effect.tos, function(id) return room:getPlayerById(id) end)
    for _, p in ipairs(targets) do
      room:setPlayerMark(p, "duxing-phase", 1)
    end
    room:useVirtualCard("duel", nil, player, targets, self.name)
    for _, p in ipairs(targets) do
      room:setPlayerMark(p, "duxing-phase", 0)
    end
  end,
}
local duxing_filter = fk.CreateFilterSkill{
  name = "#duxing_filter",
  card_filter = function(self, card, player)
    return player:getMark("duxing-phase") > 0 and not table.contains(player:getCardIds("ej"), card.id)
  end,
  view_as = function(self, card)
    return Fk:cloneCard("slash", card.suit, card.number)
  end,
}
local zhihengs = fk.CreateTriggerSkill{
  name = "zhihengs",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and data.card and not data.chain then
      local room = player.room
      local useEvent = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if useEvent then
        local dat = useEvent.data[1]
        if table.contains(TargetGroup:getRealTargets(dat.tos), data.to.id) then
          local events = room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
            local use = e.data[1]
            return use.responseToEvent and use.responseToEvent.from == player.id and use.from == data.to.id
          end, Player.HistoryTurn)
          if #events > 0 then return true end
          events = room.logic:getEventsOfScope(GameEvent.RespondCard, 1, function(e)
            local response = e.data[1]
            return response.responseToEvent and response.responseToEvent.from == player.id and response.from == data.to.id
          end, Player.HistoryTurn)
          if #events > 0 then return true end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
local zhasi = fk.CreateTriggerSkill{
  name = "zhasi",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.damage >= player.hp and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#zhasi-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:handleAddLoseSkills(player, "-zhihengs|ex__zhiheng", nil, true, false)
    room:setPlayerMark(player, "@@zhasi", 1)
    return true
  end,

  refresh_events = {fk.TargetSpecified, fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    if target == player and player:getMark("@@zhasi") > 0 then
      if event == fk.TargetSpecified then
        return data.firstTarget and table.find(TargetGroup:getRealTargets(data.tos), function(id) return id ~= player.id end)
      else
        return true
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@zhasi", 0)
  end,
}
local zhasi_distance = fk.CreateDistanceSkill{
  name = "#zhasi_distance",
  correct_func = function(self, from, to)
    if to:getMark("@@zhasi") > 0 then
      return 10086
    end
    return 0
  end,
}
local bashi = fk.CreateTriggerSkill{
  name = "bashi$",
  anim_type = "defensive",
  events = {fk.AskForCardResponse},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      table.find(Fk:currentRoom().alive_players, function(p) return p.kingdom == "wu" and p ~= player end) and
      ((data.cardName and (data.cardName == "slash" or data.cardName == "jink")) or
      (data.pattern and Exppattern:Parse(data.pattern):matchExp("slash,jink")))
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#bashi-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    for _, name in ipairs({"slash", "jink"}) do
      local card = Fk:cloneCard(name)
      if data.pattern then
        if Exppattern:Parse(data.pattern):match(card) then
          table.insert(choices, name)
        end
      elseif data.cardName and data.cardName == name then
        table.insert(choices, name)
      end
    end
    local name = room:askForChoice(player, choices, self.name, "#bashi-choice")
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p.kingdom == "wu" then
        local cardResponded = room:askForResponse(p, name, name, "#bashi-ask:"..player.id.."::"..name, true)
        if cardResponded then
          room:responseCard({
            from = p.id,
            card = cardResponded,
          })
          data.result = Fk:cloneCard(cardResponded.name, cardResponded.suit, cardResponded.number)
          data.result.skillName = self.name
        end
      end
    end
  end,
}
duxing:addRelatedSkill(duxing_filter)
zhasi:addRelatedSkill(zhasi_distance)
sunce:addSkill(duxing)
sunce:addSkill(zhihengs)
sunce:addSkill(zhasi)
sunce:addSkill(bashi)
sunce:addRelatedSkill("ex__zhiheng")
Fk:loadTranslationTable{
  ["js__sunce"] = "孙策",
  ["duxing"] = "独行",
  [":duxing"] = "出牌阶段限一次，你可以视为使用一张以任意名角色为目标的【决斗】，直到此【决斗】结算完毕，所有目标的手牌均视为【杀】。",
  ["zhihengs"] = "猘横",
  [":zhihengs"] = "锁定技，当你使用牌对目标角色造成伤害时，若其本回合使用或打出牌响应过你使用的牌，此伤害+1。",
  ["zhasi"] = "诈死",
  [":zhasi"] = "限定技，当你受到致命伤害时，你可以防止之，失去〖猘横〗并获得〖制衡〗，" ..
    --"然后你不计入座次和距离计算，直到你对其他角色使用牌或当你受到伤害后。",
    "<font color='red'>然后其他角色计算与你的距离+10086，</font>直到你使用牌指定其他角色为目标后或当你受到伤害后。",
  ["bashi"] = "霸世",
  [":bashi"] = "主公技，当你需要打出【杀】或【闪】时，你可令其他吴势力角色各选择是否代替你打出。",
  ["#duxing"] = "独行：视为使用一张指定任意个目标的【决斗】，结算中所有目标角色的手牌均视为【杀】！",
  ["#zhasi-invoke"] = "诈死：你可以防止受到的致命伤害，不计入距离和座次！",
  ["@@zhasi"] = "诈死",
  ["#bashi-invoke"] = "霸世：你可令其他吴势力角色替你打出【杀】或【闪】",
  ["#bashi-choice"] = "霸世：选择你想打出的牌，令其他吴势力角色替你打出之",
  ["#bashi-ask"] = "霸世：你可打出一张【%arg】，视为 %src 打出之",
}

local xugong = General(extension, "js__xugong", "wu", 3)
xugong.subkingdom = "qun"
local js__biaozhao = fk.CreateTriggerSkill{
  name = "js__biaozhao",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start and #player.room.alive_players > 2
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room:getOtherPlayers(player), function(p) return p.id end)
    local tos = room:askForChoosePlayers(player, targets, 2, 2, "#js__biaozhao-choose", self.name, true)
    if #tos == 2 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local target1, target2 = room:getPlayerById(self.cost_data[1]), room:getPlayerById(self.cost_data[2])
    local mark1 = target1:getMark("@@js__biaozhao1")
    if mark1 == 0 then mark1 = {} end
    table.insert(mark1, player.id)
    room:setPlayerMark(target1, "@@js__biaozhao1", mark1)
    local mark2 = target2:getMark("@@js__biaozhao2")
    if mark2 == 0 then mark2 = {} end
    table.insert(mark2, player.id)
    room:setPlayerMark(target2, "@@js__biaozhao2", mark2)
  end,

  refresh_events = {fk.EventPhaseChanging, fk.Death},
  can_refresh = function(self, event, target, player, data)
    if target == player and table.find(player.room.alive_players, function(p)
      return (p:getMark("@@js__biaozhao1") ~= 0 and table.contains(p:getMark("@@js__biaozhao1"), player.id)) or
        (p:getMark("@@js__biaozhao2") ~= 0 and table.contains(p:getMark("@@js__biaozhao2"), player.id)) end) then
      if event == fk.EventPhaseChanging then
        return data.from == Player.RoundStart
      else
        return true
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      if p:getMark("@@js__biaozhao1") ~= 0 then
        table.removeOne(p:getMark("@@js__biaozhao1"), player.id)
        if #p:getMark("@@js__biaozhao1") == 0 then
          room:setPlayerMark(p, "@@js__biaozhao1", 0)
        end
      end
      if p:getMark("@@js__biaozhao2") ~= 0 then
        table.removeOne(p:getMark("@@js__biaozhao2"), player.id)
        if #p:getMark("@@js__biaozhao2") == 0 then
          room:setPlayerMark(p, "@@js__biaozhao2", 0)
        end
      end
    end
  end,
}
local js__biaozhao_targetmod = fk.CreateTargetModSkill{
  name = "#js__biaozhao_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return player:getMark("@@js__biaozhao1") ~= 0 and scope == Player.HistoryPhase and to:getMark("@@js__biaozhao2") ~= 0 and
      table.find(to:getMark("@@js__biaozhao2"), function(id) return table.contains(player:getMark("@@js__biaozhao1"), id) end)
  end,
  bypass_distances = function(self, player, skill, card, to)
    return player:getMark("@@js__biaozhao1") ~= 0 and to:getMark("@@js__biaozhao2") ~= 0 and
      table.find(to:getMark("@@js__biaozhao2"), function(id) return table.contains(player:getMark("@@js__biaozhao1"), id) end)
  end,
}
local js__biaozhao_trigger = fk.CreateTriggerSkill{
  name = "#js__biaozhao_trigger",
  mute = true,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@js__biaozhao2") ~= 0 and data.card and
      table.contains(player:getMark("@@js__biaozhao2"), data.to.id)
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("js__biaozhao")
    room:notifySkillInvoked(data.to, "js__biaozhao", "negative")
    data.damage = data.damage + 1
  end,
}
local js__yechou = fk.CreateTriggerSkill{
  name = "js__yechou",
  anim_type = "offensive",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name, false, true)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room:getOtherPlayers(player), function (p) return p.id end)
    local p = room:askForChoosePlayers(player, targets, 1, 1, "#js__yechou-choose", self.name, true)
    if #p > 0 then
      self.cost_data = p[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    room:addPlayerMark(to, "@@js__yechou", 1)
  end,
}
local js__yechou_trigger = fk.CreateTriggerSkill{
  name = "#js__yechou_trigger",
  mute = true,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@js__yechou") > 0 and data.damage >= player.hp
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("js__yechou")
    room:notifySkillInvoked(player, "js__yechou", "negative")
    data.damage = data.damage * (2 ^ player:getMark("@@js__yechou"))
  end,
}
js__biaozhao:addRelatedSkill(js__biaozhao_targetmod)
js__biaozhao:addRelatedSkill(js__biaozhao_trigger)
xugong:addSkill(js__biaozhao)
js__yechou:addRelatedSkill(js__yechou_trigger)
xugong:addSkill(js__yechou)
Fk:loadTranslationTable{
  ["js__xugong"] = "许贡",
  ["js__biaozhao"] = "表召",
  [":js__biaozhao"] = "准备阶段，你可以选择两名其他角色，直到你下回合开始时或你死亡后，你选择的第一名角色对第二名角色使用牌无距离次数限制，"..
  "第二名角色对你使用牌造成伤害+1。",
  ["js__yechou"] = "业仇",
  [":js__yechou"] = "当你死亡时，你可以选择一名其他角色，本局游戏当其受到致命伤害时，此伤害翻倍。",
  ["#js__biaozhao-choose"] = "表召：选择两名角色，A对B使用牌无距离次数限制，B使用牌对你造成伤害+1",
  ["@@js__biaozhao1"] = "表召",
  ["@@js__biaozhao2"] = "表召目标",
  ["#js__yechou-choose"] = "业仇：你可以令一名角色本局游戏受到致命伤害时加倍！",
  ["@@js__yechou"] = "业仇",
}

local chunyuqiong = General(extension, "js__chunyuqiong", "qun", 4)
local js__cangchu = fk.CreateTriggerSkill{
  name = "js__cangchu",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and target.phase == Player.Finish and player:getMark("@js__cangchu") == 0 then
      local events = player.room.logic:getEventsOfScope(GameEvent.MoveCards, 999, function(e)
        for _, move in ipairs(e.data) do
          return move.to == player.id and move.toArea == Card.PlayerHand
        end
      end, Player.HistoryTurn)
      return #events > 0
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    local events = room.logic:getEventsOfScope(GameEvent.MoveCards, 999, function(e)
      for _, move in ipairs(e.data) do
        if move.to == player.id and move.toArea == Card.PlayerHand then
          n = n + #move.moveInfo
        end
      end
    end, Player.HistoryTurn)
    self:doCost(event, target, player, n)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room.alive_players, function(p) return p.id end)
    local prompt = "#js__cangchu1-choose:::"..math.min(#room.alive_players, data)
    if data > #room.alive_players then
      prompt = "#js__cangchu2-choose:::"..math.min(#room.alive_players, data)
    end
    local tos = room:askForChoosePlayers(player, targets, 1, data, prompt, self.name, true)
    if #tos > 0 then
      self.cost_data = {tos, tonumber(prompt[13])}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(self.cost_data[1]) do
      local p = room:getPlayerById(id)
      if not p.dead then
        p:drawCards(self.cost_data[2], self.name)
      end
    end
  end,
}
local js__shishou = fk.CreateTriggerSkill{
  name = "js__shishou",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if event == fk.CardUsing then
        return data.card.trueName == "analeptic"
      else
        return data.damageType == fk.FireDamage
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      player:drawCards(3, self.name)
      room:setPlayerMark(player, "@js__shishou-turn", 1)
    else
      room:setPlayerMark(player, "@js__cangchu", 1)
    end
  end,

  refresh_events = {fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    return target == player and data.to == Player.NotActive and player:getMark("@js__cangchu") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@js__cangchu", 0)
  end,
}
local js__shishou_prohibit = fk.CreateProhibitSkill{
  name = "#js__shishou_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("@js__shishou-turn") > 0
  end,
}
js__shishou:addRelatedSkill(js__shishou_prohibit)
chunyuqiong:addSkill(js__cangchu)
chunyuqiong:addSkill(js__shishou)
Fk:loadTranslationTable{
  ["js__chunyuqiong"] = "淳于琼",
  ["js__cangchu"] = "仓储",
  [":js__cangchu"] = "每名角色的结束阶段，你可以令至多X名角色各摸一张牌；若X大于存活角色数，则改为各摸两张牌（X为你此回合得到过的牌数）。",
  ["js__shishou"] = "失守",
  [":js__shishou"] = "锁定技，当你使用【酒】时，你摸三张牌，然后你不能使用牌直到回合结束。当你受到火焰伤害后，〖仓储〗失效直到你下回合结束。",
  ["#js__cangchu1-choose"] = "仓储：你可以令至多%arg名角色各摸一张牌",
  ["#js__cangchu2-choose"] = "仓储：你可以令至多%arg名角色各摸两张牌",
  ["@js__shishou-turn"] = "失守",
  ["@js__cangchu"] = "仓储失效",
}

local xuyou = General(extension, "js__xuyou", "qun", 3)
xuyou.subkingdom = "wei"
local lipan = fk.CreateTriggerSkill{
  name = "lipan",
  anim_type = "drawcard",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.to == Player.NotActive
  end,
  on_cost = function(self, event, target, player, data)
    local kingdoms = {"Cancel", "wei", "shu", "wu", "qun", "jin"}
    local choices = table.simpleClone(kingdoms)
    table.removeOne(choices, player.kingdom)
    local choice = player.room:askForChoice(player, choices, self.name, "#lipan-invoke", false, kingdoms)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    ChangeKingdom(player, self.cost_data)
    local tos = table.filter(room:getOtherPlayers(player), function(p) return p.kingdom == player.kingdom end)
    if #tos > 0 then
      player:drawCards(#tos, self.name)
    end
    player:gainAnExtraPhase(Player.Play, true)
  end,
}
local lipan_trigger = fk.CreateTriggerSkill{
  name = "#lipan_trigger",
  mute = true,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:usedSkillTimes("lipan", Player.HistoryTurn) > 0 and
      table.find(player.room:getOtherPlayers(player), function(p) return p.kingdom == player.kingdom and not p:isNude() end)
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if player.dead then return end
      if p.kingdom == player.kingdom and not p:isNude() and not p.dead then
        local card = room:askForCard(p, 1, 1, true, "lipan", true, ".", "#lipan-duel::"..player.id)
        if #card > 0 then
          room:useVirtualCard("duel", card, p, player, "lipan")
        end
      end
    end
  end,
}
local qingxix = fk.CreateActiveSkill{
  name = "qingxix",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#qingxix",
  can_use = function(self, player)
    return not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and target:getHandcardNum() < Self:getHandcardNum() and target:getMark("qingxix-phase") == 0 and
      not Self:isProhibited(target, Fk:cloneCard("stab__slash"))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(target, "qingxix-phase", 1)
    local n = player:getHandcardNum() - target:getHandcardNum()
    if n <= 0 then return end
    local cards = room:askForDiscard(player, n, n, false, self.name, false, ".|.|.|hand")
    if #cards < n then return end
    local use = {
      from = player.id,
      tos = {{target.id}},
      card = Fk:cloneCard("stab__slash"),
      extraUse = true,
    }
    use.card.skillName = self.name
    room:useCard(use)
  end,
}
local jinmie = fk.CreateActiveSkill{
  name = "jinmie",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#jinmie",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and target:getHandcardNum() > Self:getHandcardNum() and not Self:isProhibited(target, Fk:cloneCard("fire__slash"))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local use = {
      from = player.id,
      tos = {{target.id}},
      card = Fk:cloneCard("fire__slash"),
      extraUse = true,
    }
    use.card.skillName = self.name
    room:useCard(use)
    if not player.dead and not target.dead and use.damageDealt and use.damageDealt[target.id] then
      local n = target:getHandcardNum() - player:getHandcardNum()
      if n <= 0 then return end
      room:doIndicate(player.id, {target.id})
      local cards = room:askForCardsChosen(player, target, n, n, "h", self.name)
      room:throwCard(cards, self.name, target, player)
    end
  end,
}
lipan:addRelatedSkill(lipan_trigger)
qingxix:addAttachedKingdom("qun")
jinmie:addAttachedKingdom("wei")
xuyou:addSkill(lipan)
xuyou:addSkill(qingxix)
xuyou:addSkill(jinmie)
Fk:loadTranslationTable{
  ["js__xuyou"] = "许攸",
  ["lipan"] = "离叛",
  [":lipan"] = "回合结束时，你可以变更势力，然后摸X张牌并执行一个额外的出牌阶段（X为势力与你相同的其他角色数）。此阶段结束时，"..
  "所有势力与你相同的其他角色可以将一张牌当【决斗】对你使用。",
  ["qingxix"] = "轻袭",
  [":qingxix"] = "群势力技，出牌阶段对每名角色限一次，你可以选择一名手牌数小于你的角色，你将手牌弃至与其相同，"..
  "然后视为对其使用一张无距离和次数限制的刺【杀】。",
  ["jinmie"] = "烬灭",
  [":jinmie"] = "魏势力技，出牌阶段限一次，你可以选择一名手牌数大于你的角色，视为对其使用一张无距离和次数限制的火【杀】。此牌造成伤害后，"..
  "你将其手牌弃置至与你相同。",
  ["#lipan-invoke"] = "离叛：你可以改变势力并摸牌，然后执行一个出牌阶段",
  ["#lipan-duel"] = "离叛：你可以将一张牌当【决斗】对 %dest 使用",
  ["#qingxix"] = "轻袭：选择一名手牌数小于你的角色，将手牌弃至与其相同，视为对其使用刺【杀】",
  ["#qingxix-discard"] = "轻袭：弃置一张手牌，否则此【杀】依然对你造成伤害",
  ["#jinmie"] = "烬灭：选择一名手牌数大于你的角色，视为对其使用火【杀】，若造成伤害弃置其手牌",
}

local lvbu = General(extension, "js__lvbu", "qun", 5)
lvbu.subkingdom = "shu"  --傻逼
local wuchang = fk.CreateTriggerSkill{
  name = "wuchang",
  mute = true,
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove, fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.AfterCardsMove then
        for _, move in ipairs(data) do
          if move.to == player.id and move.from and move.from ~= player.id and move.toArea == Card.PlayerHand then
            return player.room:getPlayerById(move.from).kingdom ~= player.kingdom
          end
        end
      else
        return target == player and data.card and table.contains({"slash", "duel"}, data.card.trueName) and player.kingdom == data.to.kingdom
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.to == player.id and move.from and move.from ~= player.id and move.toArea == Card.PlayerHand then
          local p = room:getPlayerById(move.from)
          if p.kingdom ~= player.kingdom then
            room:notifySkillInvoked(player, self.name, "special")
            ChangeKingdom(player, p.kingdom)
          end
        end
      end
    else
      room:notifySkillInvoked(player, self.name, "offensive")
      data.damage = data.damage + 1
      ChangeKingdom(player, "qun")
    end
  end,
}
local qingjiaol = fk.CreateViewAsSkill{
  name = "qingjiaol",
  anim_type = "control",
  prompt = function(self, selected, selected_cards)
    if self.interaction.data == "sincere_treat" then
      return "#qingjiaol-sincere_treat"
    elseif self.interaction.data == "looting" then
      return "#qingjiaol-looting"
    end
  end,
  interaction = function(self)
    local names = {}
    for _, name in ipairs({"sincere_treat", "looting"}) do
      if Self:getMark("qingjiaol_"..name.."-phase") == 0 then
        table.insert(names, name)
      end
    end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
  before_use = function(self, player, use)
    player.room:setPlayerMark(player, "qingjiaol_"..use.card.name.."-phase", 1)
  end,
  enabled_at_play = function(self, player)
    return player:getMark("qingjiaol_sincere_treat-phase") == 0 or player:getMark("qingjiaol_looting-phase") == 0
  end,
}
local qingjiaol_prohibit = fk.CreateProhibitSkill{
  name = "#qingjiaol_prohibit",
  is_prohibited = function(self, from, to, card)
    if table.contains(card.skillNames, "qingjiaol") then
      if card.name == "sincere_treat" then
        return to:getHandcardNum() <= from:getHandcardNum()
      elseif card.name == "looting" then
        return to:getHandcardNum() >= from:getHandcardNum()
      end
    end
  end,
}
local chengxu = fk.CreateTriggerSkill{
  name = "chengxu",
  anim_type = "offensive",
  events = {fk.AfterCardUseDeclared},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.type ~= Card.TypeEquip and
      table.find(player.room:getOtherPlayers(player), function(p) return p.kingdom == player.kingdom end)
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    for _, p in ipairs(player.room:getOtherPlayers(player)) do
      if p.kingdom == player.kingdom then
        table.insertIfNeed(data.disresponsiveList, p.id)
      end
    end
  end,
}
lvbu:addSkill(wuchang)
qingjiaol:addRelatedSkill(qingjiaol_prohibit)
qingjiaol:addAttachedKingdom("qun")
chengxu:addAttachedKingdom("shu")
lvbu:addSkill(qingjiaol)
lvbu:addSkill(chengxu)
Fk:loadTranslationTable{
  ["js__lvbu"] = "吕布",
  ["wuchang"] = "无常",
  [":wuchang"] = "当你得到其他角色的牌后，你变更势力至与其相同；当你使用【杀】或【决斗】对势力与你相同的角色造成伤害时，你令此伤害+1，然后你变更势力至群。",
  ["qingjiaol"] = "轻狡",
  [":qingjiaol"] = "群势力技，出牌阶段各限一次，你可以将一张牌当【推心置腹】/【趁火打劫】对一名手牌数大于/小于你的角色使用。",
  ["chengxu"] = "乘虚",
  [":chengxu"] = "蜀势力技，锁定技，势力与你相同的其他角色不能响应你使用的牌。",--描述没写锁定技
  ["#qingjiaol-sincere_treat"] = "轻狡：你可以将一张牌当【推心置腹】对一名手牌数大于你的角色使用",
  ["#qingjiaol-looting"] = "轻狡：你可以将一张牌当【趁火打劫】对一名手牌数小于你的角色使用",
}

local zhanghe = General(extension, "js__zhanghe", "qun", 4)
zhanghe.subkingdom = "wei"
local qiongtu = fk.CreateViewAsSkill{
  name = "qiongtu",
  anim_type = "control",
  pattern = "nullification",
  prompt = "#qiongtu",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type ~= Card.TypeBasic
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("nullification")
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
  before_use = function(self, player, use)
    player:addToPile(self.name, use.card.subcards, true, self.name)
    use.card:clearSubcards()  --FIXME: 伪实现以增强游戏体验，目前大概没有“锦囊不能被黑色无懈响应”之类的技能
  end,
  enabled_at_response = function(self, player, response)
    return not response and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and not player:isNude()
  end,
}
local qiongtu_trigger = fk.CreateTriggerSkill{
  name = "#qiongtu_trigger",
  mute = true,
  events = {fk.CardEffectCancelledOut, fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and table.contains(data.card.skillNames, "qiongtu")
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardEffectCancelledOut then
      local e = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if e then
        local use = e.data[1]
        use.qiongtu = true
      end
    else
      if data.qiongtu then
        ChangeKingdom(player, "wei")
        if #player:getPile("qiongtu") > 0 then
          local dummy = Fk:cloneCard("dilu")
          dummy:addSubcards(player:getPile("qiongtu"))
          room:obtainCard(player, dummy, true, fk.ReasonJustMove)
        end
      else
        player:drawCards(1, "qiongtu")
      end
    end
  end,
}
local js__xianzhu = fk.CreateViewAsSkill{
  name = "js__xianzhu",
  anim_type = "offensive",
  pattern = "slash",
  prompt = "#js__xianzhu",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select):isCommonTrick()
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("slash")
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_response = function(self, player, response)
    return not response
  end,
}
local js__xianzhu_targetmod = fk.CreateTargetModSkill{
  name = "#js__xianzhu_targetmod",
  bypass_times = function(self, player, skill, scope, card)
    return card and scope == Player.HistoryPhase and table.contains(card.skillNames, "js__xianzhu")
  end,
}
local js__xianzhu_trigger = fk.CreateTriggerSkill{
  name = "#js__xianzhu_trigger",
  anim_type = "control",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    if target == player and data.card and table.contains(data.card.skillNames, "js__xianzhu") and not player.dead and not data.to.dead then
      local card = Fk:getCardById(data.card.subcards[1])
      local to_use = Fk:cloneCard(card.name)
      if card:isCommonTrick() and not player:prohibitUse(to_use) and not player:isProhibited(data.to, to_use) and
          card.skill:modTargetFilter(data.to.id, {}, player.id, card, true) then
        local room = player.room
        local e = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
        if e then
          local use = e.data[1]
          return #TargetGroup:getRealTargets(use.tos) == 1 and TargetGroup:getRealTargets(use.tos)[1] == data.to.id
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:getCardById(data.card.subcards[1])
    local tos = {data.to.id}
    local to_use = Fk:cloneCard(card.name)
    to_use.skillName = self.name
    if not card:isCommonTrick() or card.skill:getMinTargetNum() > 2 then
      return false
    elseif card.skill:getMinTargetNum() == 2 then
      local targets = table.filter(room.alive_players, function (p)
        return card.skill:targetFilter(p.id, tos, {}, to_use)
      end)
      if #targets > 0 then
        local to_slash = room:askForChoosePlayers(player, table.map(targets, function (p)
          return p.id
        end), 1, 1, "#js__xianzhu-choose::"..data.to.id..":"..card.name, self.name, false)
        if #to_slash > 0 then
          table.insert(tos, to_slash[1])
        end
      else
        return false
      end
    end
    room:useCard({
      from = player.id,
      tos = table.map(tos, function(pid) return { pid } end),
      card = to_use,
      extraUse = true,
    })
  end,
}
qiongtu:addRelatedSkill(qiongtu_trigger)
qiongtu:addAttachedKingdom("qun")
js__xianzhu:addRelatedSkill(js__xianzhu_targetmod)
js__xianzhu:addRelatedSkill(js__xianzhu_trigger)
js__xianzhu:addAttachedKingdom("wei")
zhanghe:addSkill(qiongtu)
zhanghe:addSkill(js__xianzhu)
Fk:loadTranslationTable{
  ["js__zhanghe"] = "张郃",
  ["qiongtu"] = "穷途",
  [":qiongtu"] = "群势力技，每回合限一次，你可以将一张非基本牌置于武将牌上视为使用一张【无懈可击】，若该【无懈可击】生效，你摸一张牌，否则你变更势力至魏"..
  "并获得武将牌上的所有牌。",
  ["js__xianzhu"] = "先著",
  [":js__xianzhu"] = "魏势力技，你可以将一张普通锦囊牌当无次数限制的【杀】使用，此【杀】对唯一目标造成伤害后，你视为对目标额外执行该锦囊牌的效果。",
  ["#qiongtu"] = "穷途：将一张非基本牌置于武将牌上，视为使用【无懈可击】",
  ["#js__xianzhu"] = "先著：你可以将一张普通锦囊牌当无次数限制的【杀】使用，若对唯一目标造成伤害，视为对其使用此锦囊",
  ["#js__xianzhu_trigger"] = "先著",
  ["#js__xianzhu-choose"] = "先著：选择对%dest使用的【%arg】的副目标",
}

local zoushi = General(extension, "js__zoushi", "qun", 3, 3, General.Female)
local guyin = fk.CreateTriggerSkill{
  name = "guyin",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    player:turnOver()
    local room = player.room
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p.dead and p.gender == General.Male and
          room:askForChoice(p, {"turnOver", "Cancel"}, self.name, "#guyin-choice:" .. player.id) == "turnOver" then
        p:turnOver()
      end
    end
    local x = #table.filter(room.players, function (p)
      return p.gender == General.Male
    end)
    local drawer = player
    for _ = 1, x, 1 do
      if drawer.dead then break end
      room:drawCards(drawer, 1, self.name)
      local all_player = room:getAllPlayers()
      local index = table.indexOf(all_player, drawer)
      local next_drawer = player
      if index < #all_player then
        for i = index+1, #all_player, 1 do
          local p = all_player[i]
          if not (p.dead or p.faceup) then
            next_drawer = p
            break
          end
        end
      end
      drawer = next_drawer
    end
  end,
}
local zhangdeng = fk.CreateViewAsSkill{
  name = "zhangdeng",
  prompt = "#zhangdeng-active",
  pattern = "analeptic",
  card_filter = function() return false end,
  before_use = function(self, player)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      room:addPlayerMark(p, "zhangdeng_used-turn")
    end
  end,
  view_as = function(self, cards)
    local c = Fk:cloneCard("analeptic")
    c.skillName = self.name
    return c
  end,
  enabled_at_play = function (self, player)
    return not player.faceup
  end,
  enabled_at_response = function (self, player, response)
    return not response and not player.faceup
  end,
}
local zhangdeng_trigger = fk.CreateTriggerSkill{
  name = "#zhangdeng_trigger",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and not player.faceup and table.contains(data.card.skillNames, zhangdeng.name) and
    player:getMark("zhangdeng_used-turn") > 1
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    player:turnOver()
  end,

  refresh_events = {fk.EventAcquireSkill, fk.EventLoseSkill, fk.BuryVictim},
  can_refresh = function(self, event, target, player, data)
    if event == fk.EventAcquireSkill or event == fk.EventLoseSkill then
      return data == self
    elseif event == fk.BuryVictim then
      return player:hasSkill(self.name, true, true)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if table.every(room.alive_players, function(p) return not p:hasSkill(self.name, true) or p == player end) then
      if player:hasSkill("zhangdeng&", true, true) then
        room:handleAddLoseSkills(player, "-zhangdeng&", nil, false, true)
      end
    else
      if not player:hasSkill("zhangdeng&", true, true) then
        room:handleAddLoseSkills(player, "zhangdeng&", nil, false, true)
      end
    end
  end,
}
local zhangdeng_attached = fk.CreateViewAsSkill{
  name = "zhangdeng&",
  prompt = "#zhangdeng-active",
  pattern = "analeptic",
  card_filter = function() return false end,
  before_use = function(self, player)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      room:addPlayerMark(p, "zhangdeng_used-turn")
    end
  end,
  view_as = function(self, cards)
    local c = Fk:cloneCard("analeptic")
    c.skillName = zhangdeng.name
    return c
  end,
  enabled_at_play = function (self, player)
    return not player.faceup and not table.every(Fk:currentRoom().alive_players, function (p)
      return not p:hasSkill(zhangdeng.name) or p.faceup
    end)
  end,
  enabled_at_response = function (self, player, response)
    return not response and not player.faceup and  not table.every(Fk:currentRoom().alive_players, function (p)
      return not p:hasSkill(zhangdeng.name) or p.faceup
    end)
  end,
}

Fk:addSkill(zhangdeng_attached)
zhangdeng:addRelatedSkill(zhangdeng_trigger)
zoushi:addSkill(guyin)
zoushi:addSkill(zhangdeng)

Fk:loadTranslationTable{
  ["js__zoushi"] = "邹氏",
  ["guyin"] = "孤吟",
  [":guyin"] = "准备阶段，你可以翻面，然后令所有其他男性角色各选择其是否翻面，然后你和所有翻面的角色轮流各摸一张牌直到以此法摸牌数达到X张"..
  "（X为本局游戏男性角色数）。",
  ["zhangdeng"] = "帐灯",
  ["#zhangdeng_trigger"] = "帐灯",
  [":zhangdeng"] = "当一名武将牌背面朝上的角色需要使用【酒】时，若你的武将牌背面朝上，其可以视为使用之。当本技能于一回合内第二次及以上发动时，你翻面至正面朝上。",
  ["zhangdeng&"] = "帐灯",
  [":zhangdeng&"] = "当你需要使用【酒】时，若邹氏的武将牌背面朝上，你可以视为使用之。",
  ["#guyin-choice"] = "%src发动了孤吟，是否将武将牌翻面",
  ["turnOver"] = "翻面",
  ["#zhangdeng-active"] = "发动帐灯，视为使用一张【酒】",
}

local guanyu = General(extension, "js__guanyu", "shu", 5)--蓝框
local guanjue = fk.CreateTriggerSkill{
  name = "guanjue",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.suit ~= Card.NoSuit and
      (player:getNextAlive():getMark("@guanjue-turn") == 0 or
      not table.contains(player:getNextAlive():getMark("@guanjue-turn"), data.card:getSuitString(true)))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getNextAlive():getMark("@guanjue-turn")
    if mark == 0 then mark = {} end
    table.insert(mark, data.card:getSuitString(true))
    for _, p in ipairs(room:getOtherPlayers(player)) do
      room:doIndicate(player.id, {p.id})
      room:setPlayerMark(p, "@guanjue-turn", mark)
    end
  end,
}
local guanjue_prohibit = fk.CreateProhibitSkill{
  name = "#guanjue_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("@guanjue-turn") ~= 0 and table.contains(player:getMark("@guanjue-turn"), card:getSuitString(true))
  end,
  prohibit_response = function(self, player, card)
    return player:getMark("@guanjue-turn") ~= 0 and table.contains(player:getMark("@guanjue-turn"), card:getSuitString(true))
  end,
}
local nianen = fk.CreateViewAsSkill{
  name = "nianen",
  pattern = ".|.|.|.|.|basic",
  interaction = function()
    local names = {}
    local mark = Self:getMark("@$nianen")
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic and not card.is_derived and
        ((Fk.currentResponsePattern == nil and card.skill:canUse(Self, card)) or
        (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))) then
        if mark == 0 or (not table.contains(mark, card.trueName)) then
          table.insertIfNeed(names, card.name)
        end
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    if use.card.name ~= "slash" or use.card.color ~= Card.Red then
      local room = player.room
      room:setPlayerMark(player, "@@nianen-turn", 1)
      if not player:hasSkill("mashu", true) then
        room:setPlayerMark(player, "nianen-turn", 1)
        room:handleAddLoseSkills(player, "mashu", nil, true, false)
      end
    end
  end,
  enabled_at_play = function(self, player)
    return not player:isNude() and player:getMark("@@nianen-turn") == 0
  end,
  enabled_at_response = function(self, player, response)
    return not player:isNude() and player:getMark("@@nianen-turn") == 0
  end,
}
local nianen_trigger = fk.CreateTriggerSkill {
  name = "#nianen_trigger",
  mute = true,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return player:getMark("nianen-turn") > 0 and data.to == Player.NotActive
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    player.room:handleAddLoseSkills(player, "-mashu", nil, true, false)
  end,
}
guanjue:addRelatedSkill(guanjue_prohibit)
nianen:addRelatedSkill(nianen_trigger)
guanyu:addSkill(guanjue)
guanyu:addSkill(nianen)
Fk:loadTranslationTable{
  ["js__guanyu"] = "关羽",
  ["guanjue"] = "冠绝",
  [":guanjue"] = "锁定技，当你使用或打出一张牌时，所有其他角色不能使用或打出此花色的牌直到回合结束。",
  ["nianen"] = "念恩",
  [":nianen"] = "你可以将你的一张牌当任意基本牌使用或打出；若转化后的牌不为红色普【杀】，〖念恩〗失效且你获得〖马术〗直到回合结束。",
  ["@guanjue-turn"] = "冠绝",
  ["@@nianen-turn"] = "念恩失效",
}

local chendeng = General(extension, "js__chendeng", "qun", 3)
local lunshi = fk.CreateActiveSkill{
  name = "lunshi",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#lunshi",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local n = #table.filter(room.alive_players, function(p) return target:inMyAttackRange(p) end)
    if n > 0 and target:getHandcardNum() < 5 then
      target:drawCards(math.min(n, 5 - target:getHandcardNum()), self.name)
    end
    if target.dead then return end
    n = #table.filter(room.alive_players, function(p) return p:inMyAttackRange(target) end)
    if n > 0 then
      room:askForDiscard(target, n, n, true, self.name, false)
    end
  end,
}
local guitu = fk.CreateTriggerSkill{
  name = "guitu",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start and
      #table.filter(player.room.alive_players, function(p) return p:getEquipment(Card.SubtypeWeapon) end) > 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p)
      return p:getEquipment(Card.SubtypeWeapon) end), function (p) return p.id end)
    local tos = room:askForChoosePlayers(player, targets, 2, 2, "#guitu-choose", self.name, true)
    if #tos == 2 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(self.cost_data, function(id) return room:getPlayerById(id) end)
    local n = {targets[1]:getAttackRange(), targets[2]:getAttackRange()}
    local id1, id2 = targets[1]:getEquipment(Card.SubtypeWeapon), targets[2]:getEquipment(Card.SubtypeWeapon)
    local move1 = {
      from = self.cost_data[1],
      ids = {id1},
      toArea = Card.Processing,
      moveReason = fk.ReasonExchange,
      proposer = player.id,
      skillName = self.name,
    }
    local move2 = {
      from = self.cost_data[2],
      ids = {id2},
      toArea = Card.Processing,
      moveReason = fk.ReasonExchange,
      proposer = player.id,
      skillName = self.name,
    }
    room:moveCards(move1, move2)
    local move3 = {
      ids = table.filter({id1}, function(id) return room:getCardArea(id) == Card.Processing end),
      fromArea = Card.Processing,
      to = self.cost_data[2],
      toArea = Card.PlayerEquip,
      moveReason = fk.ReasonExchange,
      proposer = player.id,
      skillName = self.name,
    }
    local move4 = {
      ids = table.filter({id2}, function(id) return room:getCardArea(id) == Card.Processing end),
      fromArea = Card.Processing,
      to = self.cost_data[1],
      toArea = Card.PlayerEquip,
      moveReason = fk.ReasonExchange,
      proposer = player.id,
      skillName = self.name,
    }
    room:moveCards(move3, move4)
    for i = 1, 2, 1 do
      if not targets[i].dead and targets[i]:isWounded() and targets[i]:getAttackRange() < n[i] then
        room:recover{
          who = targets[i],
          num = 1,
          recoverBy = player,
          skillName = self.name
        }
      end
    end
  end,
}
chendeng:addSkill(lunshi)
chendeng:addSkill(guitu)
Fk:loadTranslationTable{
  ["js__chendeng"] = "陈登",
  ["lunshi"] = "论势",
  [":lunshi"] = "出牌阶段限一次，你可以令一名角色摸等同于其攻击范围内角色数的牌（至多摸至五张），然后令该角色弃置等同于攻击范围内含有其的角色数的牌。",
  ["guitu"] = "诡图",
  [":guitu"] = "准备阶段，你可以交换场上的两张武器牌，然后攻击范围因此以此法减少的角色回复1点体力。",
  ["#lunshi"] = "论势：令一名角色摸其攻击范围内角色数牌，然后其弃置攻击范围内含有其角色数牌",
  ["#guitu-choose"] = "诡图：你可以交换场上两张武器牌，攻击范围减小的角色回复1点体力",
}

local zhenfu = General(extension, "js__zhenji", "qun", 3, 3, General.Female)
local function initializeAllCardNames(player, mark)
  if type(player:getMark(mark)) == "table" then
    return player:getMark(mark)
  end
  local names = {}
  for _, id in ipairs(Fk:getAllCardIds()) do
    local card = Fk:getCardById(id)
    if card.type == Card.TypeBasic and not card.is_derived then
      table.insertIfNeed(names, card.name)
    end
  end
  player.room:setPlayerMark(player, mark, names)
  return names
end
local jixiang = fk.CreateTriggerSkill{
  name = "jixiang",
  anim_type = "defensive",
  events = {fk.AskForCardUse, fk.AskForCardResponse},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and player.phase ~= Player.NotActive and player ~= target and data.pattern then
      local names = initializeAllCardNames(player, "jixiang_names")
      local mark = player:getMark("jixiang-turn")
      for _, name in ipairs(names) do
        local card = Fk:cloneCard(name)
        if (type(mark) ~= "table" or not table.contains(mark, card.trueName)) and Exppattern:Parse(data.pattern):match(card) then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#jixiang-invoke::"..target.id, true)
    if #card > 0 then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data, self.name, player, player)
    local names = initializeAllCardNames(player, "jixiang_names")
    local names2 = {}
    local mark = player:getMark("jixiang-turn")
    for _, name in ipairs(names) do
      local card = Fk:cloneCard(name)
      if (type(mark) ~= "table" or not table.contains(mark, card.trueName)) and Exppattern:Parse(data.pattern):match(card) then
        table.insertIfNeed(names2, name)
      end
    end
    if #names2 == 0 then return false end
    if event == fk.AskForCardUse then
      local extra_data = data.extraData
      local isAvailableTarget = function(card, p)
        if extra_data then
          if type(extra_data.must_targets) == "table" and #extra_data.must_targets > 0 and
              not table.contains(extra_data.must_targets, p.id) then
            return false
          end
          if type(extra_data.exclusive_targets) == "table" and #extra_data.exclusive_targets > 0 and
              not table.contains(extra_data.exclusive_targets, p.id) then
            return false
          end
        end
        return not target:isProhibited(p, card) and card.skill:modTargetFilter(p.id, {}, target.id, card, true)
      end
      local findCardTarget = function(card)
        local tos = {}
        for _, p in ipairs(room.alive_players) do
          if isAvailableTarget(card, p) then
            table.insert(tos, p.id)
          end
        end
        return tos
      end
      names2 = table.filter(names2, function (c_name)
        local card = Fk:cloneCard(c_name)
        return not target:prohibitUse(card) and (card.skill:getMinTargetNum() == 0 or #findCardTarget(card) > 0)
      end)
      if #names2 == 0 then return false end
      local name = room:askForChoice(player, names2, self.name, "#jixiang-name::" .. target.id, false, names)
      local card = Fk:cloneCard(name)
      card.skillName = self.name
      data.result = {
        from = target.id,
        card = card,
      }
      if card.skill:getMinTargetNum() == 1 then
        local tos = findCardTarget(card)
        if #tos > 0 then
          data.result.tos = {room:askForChoosePlayers(target, tos, 1, 1, "#jixiang-target:::" .. name, self.name, false, true)}
        else
          return false
        end
      end
      if data.eventData then
        data.result.toCard = data.eventData.toCard
        data.result.responseToEvent = data.eventData.responseToEvent
      end
      local mark = player:getMark("jixiang-turn")
      if type(mark) ~= "table" then mark = {} end
      table.insert(mark, card.trueName)
      room:setPlayerMark(player, "jixiang-turn", mark)
      return true
    else
      names2 = table.filter(names2, function (c_name)
        return not target:prohibitResponse(Fk:cloneCard(c_name))
      end)
      if #names2 == 0 then return false end
      local name = room:askForChoice(player, names2, self.name, "#jixiang-name::" .. target.id, false, names)
      local card = Fk:cloneCard(name)
      card.skillName = self.name
      data.result = card
      local mark = player:getMark("jixiang-turn")
      if type(mark) ~= "table" then mark = {} end
      table.insert(mark, card.trueName)
      room:setPlayerMark(player, "jixiang-turn", mark)
      return true
    end
  end
}
local jixiang_delay = fk.CreateTriggerSkill{
  name = "#jixiang_delay",
  events = {fk.CardUseFinished, fk.CardRespondFinished},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and player.phase ~= Player.NotActive and table.contains(data.card.skillNames, jixiang.name)
  end,
  on_cost = function() return true end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, jixiang.name)
    player.room:addPlayerMark(player, "chengxian_extratimes-phase")
  end,
}
local chengxian = fk.CreateViewAsSkill{
  name = "chengxian",
  prompt = "#chengxian-active",
  interaction = function()
    local names = {}
    local mark = Self:getMark("chengxian-turn")
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card:isCommonTrick() and not card.is_derived then
        local to_use = Fk:cloneCard(card.name)
        if Self:canUse(to_use) and not Self:prohibitUse(to_use) then
          if type(mark) ~= "table" or (not table.contains(mark, card.trueName)) then
            table.insertIfNeed(names, card.name)
          end
        end
      end
    end
    return UI.ComboBox { choices = names }
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 2 + player:getMark("chengxian_extratimes-phase")
  end,
  card_filter = function(self, to_select, selected)
    local targetsNum = function(card)
      if Self:prohibitUse(card) or not Self:canUse(card) then return 0 end
      if card.skill:getMinTargetNum() == 0 and not card.multiple_targets then
        return 1
      else
        local x = 0
        for _, p in ipairs(Fk:currentRoom().alive_players) do
          if not Self:isProhibited(p, card) and card.skill:modTargetFilter(p.id, {}, Self.id, card, true) then
            x = x + 1
          end
        end
        return x
      end
    end
    if self.interaction.data == nil or #selected > 0 or Fk:currentRoom():getCardArea(to_select) == Player.Equip then return false end
    local to_use = Fk:cloneCard(self.interaction.data)
    to_use:addSubcard(to_select)
    to_use.skillName = self.name
    return targetsNum(to_use) == targetsNum(Fk:getCardById(to_select))
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return nil end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    local mark = player:getMark("chengxian-turn")
    if mark == 0 then mark = {} end
    table.insert(mark, use.card.trueName)
    player.room:setPlayerMark(player, "chengxian-turn", mark)
  end,
}
jixiang:addRelatedSkill(jixiang_delay)
zhenfu:addSkill(jixiang)
zhenfu:addSkill(chengxian)
Fk:loadTranslationTable{
  ["js__zhenji"] = "甄宓",
  ["jixiang"] = "济乡",
  ["#jixiang_delay"] = "济乡",
  [":jixiang"] = "回合内对每种牌名限一次，当一名其他角色需要使用或打出一张基本牌，你可以弃置一张牌令其视为使用或打出之，然后你摸一张牌并令〖称贤〗"..
  "于此阶段可发动次数+1。",
  ["chengxian"] = "称贤",
  [":chengxian"] = "出牌阶段限两次，你可以将一张手牌当一张本回合未以此法使用过的普通锦囊牌使用，以此法转化后普通锦囊牌须与原牌名的牌合法目标角色数相同。",

  ["#jixiang-invoke"] = "是否使用 济乡，弃置一张牌，令%dest视为使用或打出所需的基本牌",
  ["#jixiang-name"] = "济乡：选择%dest视为使用或打出的所需的基本牌的牌名",
  ["#jixiang-target"] = "济乡：选择使用【%arg】的目标角色",
  ["#chengxian-active"] = "发动称贤，将一张手牌当普通锦囊牌使用（两者必须合法目标数相同）",
}

local zhangliao = General(extension, "js__zhangliao", "qun", 4)
zhangliao.subkingdom = "wei"
local zhengbing = fk.CreateActiveSkill{
  name = "zhengbing",
  anim_type = "drawcard",
  card_num = 1,
  target_num = 0,
  prompt = "#zhengbing",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 3
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local name = Fk:getCardById(effect.cards[1]).trueName
    room:recastCard(effect.cards, player, self.name)
    if player.dead then return end
    if name == "slash" then
      room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, 2)
    elseif name == "jink" then
      player:drawCards(1, self.name)
    elseif name == "peach" then
      ChangeKingdom(player, "wei")
    end
  end,
}
local tuwei = fk.CreateTriggerSkill{
  name = "tuwei",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and
      table.find(player.room.alive_players, function(p) return player:inMyAttackRange(p) and not p:isNude() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return player:inMyAttackRange(p) and not p:isNude() end), function (p) return p.id end)
    local tos = room:askForChoosePlayers(player, targets, 1, #targets, "#tuwei-choose:::"..#targets, self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "tuwei-turn", self.cost_data)
    for _, id in ipairs(self.cost_data) do
      if player.dead then return end
      local p = room:getPlayerById(id)
      if not p.dead then
        local c = room:askForCardChosen(player, p, "he", self.name)
        room:obtainCard(player, c, false, fk.ReasonPrey)
      end
    end
  end,
}
local tuwei_trigger = fk.CreateTriggerSkill{
  name = "#tuwei_trigger",
  mute = true,
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and data.to == Player.NotActive and player:getMark("tuwei-turn") ~= 0 and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(player:getMark("tuwei-turn")) do
      if player.dead or player:isNude() then return end
      local p = room:getPlayerById(id)
      if not p.dead then
        local events = player.room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function(e)
          local damage = e.data[5]
          return damage and p == damage.to
        end, Player.HistoryTurn)
        if #events == 0 then
          room:doIndicate(id, {player.id})
          local c = room:askForCardChosen(p, player, "he", "tuwei")
          room:obtainCard(p, c, false, fk.ReasonPrey)
        end
      end
    end
  end,
}

zhengbing:addAttachedKingdom("qun")
tuwei:addRelatedSkill(tuwei_trigger)
tuwei:addAttachedKingdom("wei")
zhangliao:addSkill(zhengbing)
zhangliao:addSkill(tuwei)
Fk:loadTranslationTable{
  ["js__zhangliao"] = "张辽",
  ["zhengbing"] = "整兵",
  [":zhengbing"] = "群势力技，出牌阶段限三次，你可以重铸一张牌，若此牌为：<br>【杀】，你此回合手牌上限+2；<br>【闪】，你摸一张牌；<br>"..
  "【桃】，你变更势力至魏。",
  ["tuwei"] = "突围",
  [":tuwei"] = "魏势力技，出牌阶段开始时，你可以获得攻击范围内任意名角色各一张牌；回合结束时，这些角色中本回合未受到过伤害的角色各获得你的一张牌。",
  ["#zhengbing"] = "整兵：你可以重铸一张牌，若为基本牌，获得额外效果",
  ["#tuwei-choose"] = "突围：你可以获得攻击范围内任意名角色各一张牌",
}

return extension
