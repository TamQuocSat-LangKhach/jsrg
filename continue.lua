local extension = Package("continue")
extension.extensionName = "jsrg"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["continue"] = "江山如故·承",
}

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
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    local card = Fk:cloneCard("duel")
    card.skillName = self.name
    return card.skill:modTargetFilter(to_select, selected, Self, card)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local targets = table.map(effect.tos, Util.Id2PlayerMapper)
    for _, p in ipairs(targets) do
      room:setPlayerMark(p, "duxing-phase", 1)
      p:filterHandcards()
    end
    room:useVirtualCard("duel", nil, player, targets, self.name)
    for _, p in ipairs(targets) do
      room:setPlayerMark(p, "duxing-phase", 0)
      p:filterHandcards()
    end
  end,
}
local duxing_filter = fk.CreateFilterSkill{
  name = "#duxing_filter",
  card_filter = function(self, card, player)
    return player:getMark("duxing-phase") > 0 and table.contains(player.player_cards[Player.Hand], card.id)
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
    if target == player and player:hasSkill(self) and data.card and not data.chain then
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
  frequency = Skill.Limited,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.damage >= player.hp and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#zhasi-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:handleAddLoseSkills(player, "-zhihengs|ex__zhiheng", nil, true, false)
    room:setPlayerMark(player, "@@zhasi", 1)
    room:addPlayerMark(player, MarkEnum.PlayerRemoved, 1)
    return true
  end,

  refresh_events = {fk.TargetSpecified, fk.Damaged},
  can_refresh = function(self, event, target, player, data)
    if target == player and player:getMark("@@zhasi") > 0 then
      if event == fk.TargetSpecified then
        return data.firstTarget and table.find(AimGroup:getAllTargets(data.tos), function(id) return id ~= player.id end)
      else
        return true
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@zhasi", 0)
    player.room:removePlayerMark(player, MarkEnum.PlayerRemoved, 1)
  end,
}

local bashi = fk.CreateTriggerSkill{
  name = "bashi$",
  anim_type = "defensive",
  events = {fk.AskForCardResponse},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
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
      if p.kingdom == "wu" and p:isAlive() then
        local cardResponded = room:askForResponse(p, name, name, "#bashi-ask:"..player.id.."::"..name, true)
        if cardResponded then
          room:responseCard({
            from = p.id,
            card = cardResponded,
            skipDrop = true,
          })
          data.result = cardResponded
          data.result.skillName = self.name
          return true
        end
      end
    end
  end,
}
duxing:addRelatedSkill(duxing_filter)
sunce:addSkill(duxing)
sunce:addSkill(zhihengs)
sunce:addSkill(zhasi)
sunce:addSkill(bashi)
sunce:addRelatedSkill("ex__zhiheng")
Fk:loadTranslationTable{
  ["js__sunce"] = "孙策",
  ["#js__sunce"] = "问鼎的霸王",
  ["illustrator:js__sunce"] = "君桓文化",
  ["duxing"] = "独行",
  [":duxing"] = "出牌阶段限一次，你可以视为使用一张以任意名角色为目标的【决斗】，直到此【决斗】结算完毕，所有目标的手牌均视为【杀】。",
  ["zhihengs"] = "猘横",
  [":zhihengs"] = "锁定技，当你使用牌对目标角色造成伤害时，若其本回合使用或打出牌响应过你使用的牌，此伤害+1。",
  ["zhasi"] = "诈死",
  [":zhasi"] = "限定技，当你受到致命伤害时，你可以防止之，失去〖猘横〗并获得〖制衡〗，" ..
    "然后你不计入座次和距离计算，直到你对其他角色使用牌或当你受到伤害后。",
  ["bashi"] = "霸世",
  [":bashi"] = "主公技，当你需要打出【杀】或【闪】时，你可令其他吴势力角色各选择是否代替你打出。",
  ["#duxing"] = "独行：视为使用一张指定任意个目标的【决斗】，结算中所有目标角色的手牌均视为【杀】！",
  ["#zhasi-invoke"] = "诈死：你可以防止受到的致命伤害，不计入距离和座次！",
  ["@@zhasi"] = "诈死",
  ["#bashi-invoke"] = "霸世：你可令其他吴势力角色替你打出【杀】或【闪】",
  ["#bashi-choice"] = "霸世：选择你想打出的牌，令其他吴势力角色替你打出之",
  ["#bashi-ask"] = "霸世：你可打出一张【%arg】，视为 %src 打出之",

  --CV：凉水汐月
  ["$duxing1"] = "尔辈世族皆碌碌，千里函关我独行！",
  ["$duxing2"] = "江东英豪，可当我一人乎？",
  ["$zhihengs1"] = "杀尽逆竖，何人还敢平视！",
  ["$zhihengs2"] = "畏罪而返，区区螳臂，我何惧之！",
  ["$zhasi1"] = "内外大事悉付权弟，无需问我。",
  ["$zhasi2"] = "今遭小人暗算，不如将计就计。",
  ["$ex__zhiheng_js__sunce1"] = "省身以严，用权以慎，方能上使下力。",
  ["$ex__zhiheng_js__sunce2"] = "惩前毖后，宽严相济，士人自念吾恩。",
  ["$bashi1"] = "江东多逆，必兴兵戈，敢战者，进禄加官。",
  ["$bashi2"] = "汉失其鹿，群雄竞逐，从我者，封妻荫子。",
  ["~js__sunce"] = "天不假年……天不假年！",
}

local xugong = General(extension, "js__xugong", "wu", 3)
xugong.subkingdom = "qun"
local js__biaozhao = fk.CreateTriggerSkill{
  name = "js__biaozhao",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and #player.room.alive_players > 2
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    local tos = room:askForChoosePlayers(player, targets, 2, 2, "#js__biaozhao-choose", self.name, true)
    if #tos == 2 then
      self.cost_data = {tos = tos}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local target1, target2 = room:getPlayerById(self.cost_data.tos[1]), room:getPlayerById(self.cost_data.tos[2])
    room:addTableMark(target1, "@@js__biaozhao1", player.id)
    room:addTableMark(target2, "@@js__biaozhao2", player.id)
  end,

  refresh_events = {fk.TurnStart, fk.Death},
  can_refresh = function(self, event, target, player, data)
    return target == player and table.find(player.room.alive_players, function(p)
      return table.contains(p:getTableMark("@@js__biaozhao1"), player.id) or table.contains(p:getTableMark("@@js__biaozhao2"), player.id)
    end)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room.alive_players) do
      if p:getMark("@@js__biaozhao1") ~= 0 then
        room:removeTableMark(p, "@@js__biaozhao1", player.id)
      end
      if p:getMark("@@js__biaozhao2") ~= 0 then
        room:removeTableMark(p, "@@js__biaozhao2", player.id)
      end
    end
  end,
}
local js__biaozhao_targetmod = fk.CreateTargetModSkill{
  name = "#js__biaozhao_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return card and player:getMark("@@js__biaozhao1") ~= 0 and scope == Player.HistoryPhase and to and to:getMark("@@js__biaozhao2") ~= 0 and
      table.find(to:getMark("@@js__biaozhao2"), function(id) return table.contains(player:getMark("@@js__biaozhao1"), id) end)
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and player:getMark("@@js__biaozhao1") ~= 0 and to and to:getMark("@@js__biaozhao2") ~= 0 and
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
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.to:broadcastSkillInvoke("js__biaozhao")
    room:notifySkillInvoked(data.to, "js__biaozhao", "negative")
    data.damage = data.damage + 1
  end,
}
local js__yechou = fk.CreateTriggerSkill{
  name = "js__yechou",
  anim_type = "offensive",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, false, true)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#js__yechou-choose", self.name, true)
    if #to > 0 then
      self.cost_data = {tos = to}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data.tos[1])
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
  on_cost = Util.TrueFunc,
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
  ["#js__xugong"] = "独计击流",
  ["illustrator:js__xugong"] = "君桓文化",
  ["js__biaozhao"] = "表召",
  [":js__biaozhao"] = "准备阶段，你可以选择两名其他角色，直到你下回合开始时或你死亡后，你选择的第一名角色对第二名角色使用牌无距离次数限制，"..
  "第二名角色对你使用牌造成伤害+1。",
  ["js__yechou"] = "业仇",
  [":js__yechou"] = "当你死亡时，你可以选择一名其他角色，本局游戏当其受到致命伤害时，此伤害翻倍。",
  ["#js__biaozhao-choose"] = "表召：你可选择两名角色，第一个对第二个使用牌无距离次数限制，第二个使用牌对你造成伤害+1",
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
    if player:hasSkill(self) and target.phase == Player.Finish and player:getMark("@js__cangchu") == 0 then
      local n = 0
      local max_num = #player.room.alive_players
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          if move.to == player.id and move.toArea == Card.PlayerHand then
            n = n + #move.moveInfo
          end
        end
        return n > max_num
      end, Player.HistoryTurn)
      if n > 0 then
        self.cost_data = n
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local x = self.cost_data
    local targets = table.map(room.alive_players, Util.IdMapper)
    local prompt = "#js__cangchu1-choose:::"..x
    if x > #targets then
      x = #targets
      prompt = "#js__cangchu2-choose:::"..x
    end
    local tos = room:askForChoosePlayers(player, targets, 1, x, prompt, self.name, true)
    if #tos > 0 then
      room:sortPlayersByAction(tos)
      self.cost_data = {tos = tos, num = tonumber(prompt[13])}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local num = self.cost_data.num
    for _, id in ipairs(self.cost_data.tos) do
      local p = room:getPlayerById(id)
      if not p.dead then
        p:drawCards(num, self.name)
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
    if target == player and player:hasSkill(self) then
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

  refresh_events = {fk.AfterTurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@js__cangchu") > 0
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
  ["#js__chunyuqiong"] = "乌巢酒仙",
  ["illustrator:js__chunyuqiong"] = "君桓文化",
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
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local kingdoms = {"Cancel", "wei", "shu", "wu", "qun", "jin"}
    local choices = table.simpleClone(kingdoms)
    table.removeOne(choices, player.kingdom)
    local choice = player.room:askForChoice(player, choices, self.name, "#lipan-invoke", false, kingdoms)
    if choice ~= "Cancel" then
      self.cost_data = {choice = choice}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeKingdom(player, self.cost_data.choice, true)
    local tos = table.filter(room:getOtherPlayers(player, false), function(p) return p.kingdom == player.kingdom end)
    if #tos > 0 then
      player:drawCards(#tos, self.name)
    end
    if not player.dead then
      player:gainAnExtraPhase(Player.Play, true)
    end
  end,
}
local lipan_trigger = fk.CreateTriggerSkill{
  name = "#lipan_trigger",
  mute = true,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:usedSkillTimes("lipan", Player.HistoryTurn) > 0 and
      table.find(player.room:getOtherPlayers(player, false), function(p) return p.kingdom == player.kingdom and not p:isNude() end)
  end,
  on_cost = Util.TrueFunc,
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
  card_filter = Util.FalseFunc,
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
  card_filter = Util.FalseFunc,
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
  ["#js__xuyou"] = "毕方骄翼",
  ["illustrator:js__xuyou"] = "鬼画府",
  ["lipan"] = "离叛",
  [":lipan"] = "结束阶段结束时，你可以变更势力，然后摸X张牌并执行一个额外的出牌阶段（X为势力与你相同的其他角色数）。此阶段结束时，"..
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
    if player:hasSkill(self) then
      if event == fk.AfterCardsMove then
        for _, move in ipairs(data) do
          if move.to == player.id and move.from and move.from ~= player.id and move.toArea == Card.PlayerHand and player.room:getPlayerById(move.from).kingdom ~= player.kingdom then
            if table.find(move.moveInfo, function(info) return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip end) then
              return true
            end
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
        if move.to == player.id and move.from and move.from ~= player.id and move.toArea == Card.PlayerHand
        and table.find(move.moveInfo, function(info) return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip end) then
          local p = room:getPlayerById(move.from)
          if p.kingdom ~= player.kingdom then
            room:notifySkillInvoked(player, self.name, "special")
            room:changeKingdom(player, p.kingdom, true)
          end
        end
      end
    else
      room:notifySkillInvoked(player, self.name, "offensive")
      data.damage = data.damage + 1
      room:changeKingdom(player, "qun", true)
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
    return U.CardNameBox {choices = names}
  end,
  handly_pile = true,
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
    return target == player and player:hasSkill(self) and data.card.type ~= Card.TypeEquip and
      table.find(player.room:getOtherPlayers(player, false), function(p) return p.kingdom == player.kingdom end)
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    for _, p in ipairs(player.room:getOtherPlayers(player, false)) do
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
  ["#js__lvbu"] = "虎视中原",
  ["illustrator:js__lvbu"] = "鬼画府",
  ["wuchang"] = "无常",
  [":wuchang"] = "锁定技，当你得到其他角色的牌后，你变更势力至与其相同；当你使用【杀】或【决斗】对势力与你相同的角色造成伤害时，你令此伤害+1，然后你变更势力至群。",
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
    self.cost_data = cards
    return card
  end,
  before_use = function(self, player, use)
    player:addToPile(self.name, self.cost_data, true, self.name)
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
  on_cost = Util.TrueFunc,
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
        room:changeKingdom(player, "wei", true)
        if #player:getPile("qiongtu") > 0 then
          room:obtainCard(player, player:getPile("qiongtu"), true, fk.ReasonJustMove)
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
  handly_pile = true,
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
          card.skill:modTargetFilter(data.to.id, {}, player, card, true) then
        local room = player.room
        local e = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
        if e then
          local use = e.data[1]
          return #TargetGroup:getRealTargets(use.tos) == 1 and TargetGroup:getRealTargets(use.tos)[1] == data.to.id
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
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
        return not table.contains(tos, p.id) and card.skill:targetFilter(p.id, tos, {}, to_use, nil, player)
      end)
      if #targets > 0 then
        local to_slash = room:askForChoosePlayers(player, table.map(targets, Util.IdMapper),
        1, 1, "#js__xianzhu-choose::"..data.to.id..":"..card.name, self.name, false)
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
  ["#js__zhanghe"] = "微子去殷",
  ["illustrator:js__zhanghe"] = "君桓文化",
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
    return target == player and player:hasSkill(self) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    player:turnOver()
    local room = player.room
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p.dead and p:isMale() and
          room:askForChoice(p, {"turnOver", "Cancel"}, self.name, "#guyin-choice:" .. player.id) == "turnOver" then
        p:turnOver()
      end
    end
    local x = #table.filter(room.players, function (p)
      return p:isMale()
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
  attached_skill_name = "zhangdeng&",
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
    return player:hasSkill(self) and not player.faceup and table.contains(data.card.skillNames, zhangdeng.name) and
    player:getMark("zhangdeng_used-turn") > 1
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:turnOver()
  end,
}
local zhangdeng_attached = fk.CreateViewAsSkill{
  name = "zhangdeng&",
  prompt = "#zhangdeng-active",
  pattern = "analeptic",
  card_filter = Util.FalseFunc,
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
      return not p:hasSkill(zhangdeng) or p.faceup
    end)
  end,
  enabled_at_response = function (self, player, response)
    return not response and not player.faceup and  not table.every(Fk:currentRoom().alive_players, function (p)
      return not p:hasSkill(zhangdeng) or p.faceup
    end)
  end,
}

Fk:addSkill(zhangdeng_attached)
zhangdeng:addRelatedSkill(zhangdeng_trigger)
zoushi:addSkill(guyin)
zoushi:addSkill(zhangdeng)

Fk:loadTranslationTable{
  ["js__zoushi"] = "邹氏",
  ["#js__zoushi"] = "淯水香魂",
  ["illustrator:js__zoushi"] = "君桓文化",
  ["guyin"] = "孤吟",
  [":guyin"] = "准备阶段，你可以翻面，然后令所有其他男性角色各选择其是否翻面，然后你和所有翻面的角色轮流各摸一张牌直到以此法摸牌数达到X张"..
  "（X为本局游戏男性角色数）。",
  ["zhangdeng"] = "帐灯",
  ["#zhangdeng_trigger"] = "帐灯",
  [":zhangdeng"] = "当一名武将牌背面朝上的角色需要使用【酒】时，若你的武将牌背面朝上，其可以视为使用之。当本技能于一回合内第二次及以上发动时，你翻面至正面朝上。",
  ["zhangdeng&"] = "帐灯",
  [":zhangdeng&"] = "当你需要使用【酒】时，若你与邹氏的武将牌均为背面朝上，你可以视为使用之。",
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
    return target == player and player:hasSkill(self) and data.card.suit ~= Card.NoSuit and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return not table.contains(p:getTableMark("@guanjue-turn"), data.card:getSuitString(true))
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getOtherPlayers(player, false)) do
      room:doIndicate(player.id, {p.id})
      room:addTableMark(p, "@guanjue-turn", data.card:getSuitString(true))
    end
  end,
}
local guanjue_prohibit = fk.CreateProhibitSkill{
  name = "#guanjue_prohibit",
  prohibit_use = function(self, player, card)
    return card and table.contains(player:getTableMark("@guanjue-turn"), card:getSuitString(true))
  end,
  prohibit_response = function(self, player, card)
    return card and table.contains(player:getTableMark("@guanjue-turn"), card:getSuitString(true))
  end,
}
local nianen = fk.CreateViewAsSkill{
  name = "nianen",
  pattern = ".|.|.|.|.|basic",
  mute = true,
  prompt = "#nianen",
  interaction = function()
    local all_names = U.getAllCardNames("b")
    local names = U.getViewAsCardNames(Self, "nianen", all_names)
    if #names > 0 then
      return U.CardNameBox { choices = names, all_choices = all_names }
    end
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
    local room = player.room
    room:notifySkillInvoked(player, self.name)
    if use.card.name ~= "slash" or use.card.color ~= Card.Red then
      player:broadcastSkillInvoke(self.name, math.random(3, 4))
      room:invalidateSkill(player, self.name, "-turn")
      if not player:hasSkill("mashu", true) then
        room:handleAddLoseSkills(player, "mashu")
        room.logic:getCurrentEvent():findParent(GameEvent.Turn):addCleaner(function()
          room:handleAddLoseSkills(player, "-mashu")
        end)
      end
    else
      player:broadcastSkillInvoke(self.name, math.random(1, 2))
    end
  end,
  enabled_at_play = Util.TrueFunc,
  enabled_at_response = Util.TrueFunc,
}
guanjue:addRelatedSkill(guanjue_prohibit)
guanyu:addSkill(guanjue)
guanyu:addSkill(nianen)
Fk:loadTranslationTable{
  ["js__guanyu"] = "关羽",
  ["#js__guanyu"] = "羊左之义",
  ["cv:js__guanyu"] = "雨叁大魔王",
  ["illustrator:js__guanyu"] = "鬼画府",
  ["guanjue"] = "冠绝",
  [":guanjue"] = "锁定技，当你使用或打出一张牌时，所有其他角色不能使用或打出此花色的牌直到回合结束。",
  ["nianen"] = "念恩",
  [":nianen"] = "你可以将你的一张牌当任意基本牌使用或打出；若转化后的牌不为红色普【杀】，〖念恩〗失效且你获得〖马术〗直到回合结束。",
  ["#nianen"] = "念恩：将一张牌当任意基本牌使用或打出，若转化后的牌不为红色普【杀】，“念恩”失效且你获得“马术”直到回合结束",
  ["@guanjue-turn"] = "冠绝",

  ["$guanjue1"] = "河北诸将，以某观之，如土鸡瓦狗！",
  ["$guanjue2"] = "小儿舞刀，不值一哂。",
  ["$nianen1"] = "丞相厚恩，今斩将以报。",
  ["$nianen2"] = "丈夫信义为先，恩信岂可负之？",
  ["$nianen3"] = "桃园之谊，殷殷在怀，不敢或忘。",
  ["$nianen4"] = "解印封金离许都，惟思恩义走长途。",
  ["~js__guanyu"] = "皇叔厚恩，来世再报了…",
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
  card_filter = Util.FalseFunc,
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
    return target == player and player:hasSkill(self) and player.phase == Player.Start and
      #table.filter(player.room.alive_players, function(p) return p:getEquipment(Card.SubtypeWeapon) end) > 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p)
      return #p:getEquipments(Card.SubtypeWeapon) > 0 end), function (p) return p.id end)
    local tos = room:askForChoosePlayers(player, targets, 2, 2, "#guitu-choose", self.name, true)
    if #tos == 2 then
      self.cost_data = {tos = tos}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(self.cost_data.tos, Util.Id2PlayerMapper)
    local n = {targets[1]:getAttackRange(), targets[2]:getAttackRange()}
    local cards = {}
    for _, p in ipairs(targets) do
      if #p:getEquipments(Card.SubtypeWeapon) == 1 then
        table.insert(cards, p:getEquipments(Card.SubtypeWeapon))
      else
        local card = U.askforChooseCardsAndChoice(player, p:getEquipments(Card.SubtypeWeapon), {"OK"}, self.name,
          "#guitu-card::"..p.id)
        table.insert(cards, card)
      end
    end
    U.swapCards(room, player, targets[1], targets[2], cards[1], cards[2], self.name, Card.PlayerEquip)
    for i = 1, 2, 1 do
      if not targets[i].dead and targets[i]:isWounded() and targets[i]:getAttackRange() < n[i] then
        room:recover{
          who = targets[i],
          num = 1,
          recoverBy = player,
          skillName = self.name,
        }
      end
    end
  end,
}
chendeng:addSkill(lunshi)
chendeng:addSkill(guitu)
Fk:loadTranslationTable{
  ["js__chendeng"] = "陈登",
  ["#js__chendeng"] = "惊涛弄潮",
  ["illustrator:js__chendeng"] = "鬼画府",
  ["lunshi"] = "论势",
  [":lunshi"] = "出牌阶段限一次，你可以令一名角色摸等同于其攻击范围内角色数的牌（至多摸至五张），然后令该角色弃置等同于攻击范围内含有其的角色数的牌。",
  ["guitu"] = "诡图",
  [":guitu"] = "准备阶段，你可以交换场上的两张武器牌，然后攻击范围因此以此法减少的角色回复1点体力。",
  ["#lunshi"] = "论势：令一名角色摸其攻击范围内角色数牌，然后其弃置攻击范围内含有其角色数牌",
  ["#guitu-choose"] = "诡图：你可以交换场上两张武器牌，攻击范围减小的角色回复1点体力",
  ["#guitu-card"] = "诡图：选择 %dest 的一张武器牌",
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
    if player:hasSkill(self) and player.phase ~= Player.NotActive and player ~= target and data.pattern then
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
        return not target:isProhibited(p, card) and card.skill:modTargetFilter(p.id, {}, target, card, true)
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
local function getTargetsNum(player, card)
  if player:prohibitUse(card) or not player:canUse(card) then return 0 end
  if card.skill:getMinTargetNum() == 0 and not card.multiple_targets then
    return 1
  else
    local x = 0
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if not player:isProhibited(p, card) and card.skill:modTargetFilter(p.id, {}, player, card, true) then
        x = x + 1
      end
    end
    return x
  end
end
local chengxian = fk.CreateViewAsSkill{
  name = "chengxian",
  prompt = "#chengxian-active",
  interaction = function()
    local mark = Self:getTableMark("chengxian-turn")
    local all_names = U.getAllCardNames("t")
    local handcards = Self:getCardIds(Player.Hand)
    local names = table.filter(all_names, function(name)
      return not table.contains(mark, Fk:cloneCard(name).trueName) and table.find(handcards, function (id)
        local to_use = Fk:cloneCard(name)
        to_use:addSubcard(id)
        to_use.skillName = "chengxian"
        local x = getTargetsNum(Self, to_use)
        return x > 0 and x == getTargetsNum(Self, Fk:getCardById(id))
      end)
    end)
    if #names > 0 then
      return U.CardNameBox { choices = names, all_choices = all_names }
    end
  end,
  times = function(self)
    if Self.phase == Player.Play then
      return  2 + Self:getMark("chengxian_extratimes-phase") - Self:usedSkillTimes(self.name, Player.HistoryPhase)
    end
    return -1
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 2 + player:getMark("chengxian_extratimes-phase")
  end,
  card_filter = function(self, to_select, selected)
    if self.interaction.data == nil or #selected > 0 or Fk:currentRoom():getCardArea(to_select) == Player.Equip then return false end
    local to_use = Fk:cloneCard(self.interaction.data)
    to_use:addSubcard(to_select)
    to_use.skillName = self.name
    return getTargetsNum(Self, to_use) == getTargetsNum(Self, Fk:getCardById(to_select))
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return nil end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    player.room:addTableMark(player, "chengxian-turn", use.card.trueName)
  end,
}
jixiang:addRelatedSkill(jixiang_delay)
zhenfu:addSkill(jixiang)
zhenfu:addSkill(chengxian)
Fk:loadTranslationTable{
  ["js__zhenji"] = "甄宓",
  ["#js__zhenji"] = "一顾倾国",
  ["illustrator:js__zhenji"] = "君桓文化",
  ["cv:js__zhenji"] = "离瞳鸭",
  ["jixiang"] = "济乡",
  ["#jixiang_delay"] = "济乡",
  [":jixiang"] = "当其他角色于你的回合内需要使用或打出基本牌时（每回合每种牌名各限一次），你可以弃置一张牌令其视为使用或打出之，"..
  "然后你摸一张牌并令〖称贤〗于此阶段可发动次数+1。",
  ["chengxian"] = "称贤",
  [":chengxian"] = "出牌阶段限两次，你可以将一张手牌当任意普通锦囊牌使用"..
  "（每回合每种牌名各限一次，且以此法转化后的牌须与转化前的牌的合法目标角色数相等）。",

  ["#jixiang-invoke"] = "济乡：你可以弃置一张牌，令%dest视为使用或打出所需的基本牌",
  ["#jixiang-name"] = "济乡：选择%dest视为使用或打出的所需的基本牌的牌名",
  ["#jixiang-target"] = "济乡：选择使用【%arg】的目标角色",
  ["#chengxian-active"] = "称贤：将一张手牌当普通锦囊牌使用（两者必须合法目标数相同）",

  --CV：离瞳鸭
  ["$jixiang1"] = "珠玉不足贵，德行传家久。",
  ["$jixiang2"] = "人情一日不食则饥，愿母亲慎思之。",
  ["$chengxian1"] = "所愿广求淑媛，以丰继嗣。",
  ["$chengxian2"] = "贤妻夫祸少，夫宽妻多福。",
  ["~js__zhenji"] = "乱世人如苇，随波雨打浮……",
}

local zhangliao = General(extension, "js__zhangliao", "qun", 4)
zhangliao.subkingdom = "wei"
local zhengbing = fk.CreateActiveSkill{
  name = "zhengbing",
  anim_type = "drawcard",
  card_num = 1,
  target_num = 0,
  prompt = "#zhengbing",
  times = function(self)
    return Self.phase == Player.Play and 3 - Self:usedSkillTimes(self.name, Player.HistoryPhase) or -1
  end,
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
      room:changeKingdom(player, "wei", true)
    end
  end,
}
local tuwei = fk.CreateTriggerSkill{
  name = "tuwei",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and
      table.find(player.room.alive_players, function(p) return player:inMyAttackRange(p) and not p:isNude() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player, false), function(p)
      return player:inMyAttackRange(p) and not p:isNude() end), Util.IdMapper)
    local tos = room:askForChoosePlayers(player, targets, 1, #targets, "#tuwei-choose:::"..#targets, self.name, true)
    if #tos > 0 then
      self.cost_data = {tos = tos}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:sortPlayersByAction(self.cost_data.tos)
    local mark = player:getTableMark("tuwei-turn")
    for _, id in ipairs(self.cost_data.tos) do
      if player.dead then return end
      local p = room:getPlayerById(id)
      if not p.dead then
        table.insertIfNeed(mark, id)
        local card = room:askForCardChosen(player, p, "he", self.name)
        room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, false, player.id)
      end
    end
    room:setPlayerMark(player, "tuwei-turn", mark)
  end,
}
local tuwei_trigger = fk.CreateTriggerSkill{
  name = "#tuwei_trigger",
  mute = true,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("tuwei-turn") ~= 0 and not player:isNude()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("tuwei-turn")
    room:sortPlayersByAction(mark)
    for _, id in ipairs(mark) do
      if player.dead or player:isNude() then return end
      local p = room:getPlayerById(id)
      if not p.dead then
        local events = player.room.logic:getActualDamageEvents(1, function(e)
          local damage = e.data[1]
          return p == damage.to
        end, Player.HistoryTurn)
        if #events == 0 then
          room:doIndicate(id, {player.id})
          local card = room:askForCardChosen(p, player, "he", "tuwei")
          room:moveCardTo(card, Card.PlayerHand, p, fk.ReasonPrey, "tuwei", nil, false, id)
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
  ["#js__zhangliao"] = "利刃风骑",
  ["illustrator:js__zhangliao"] = "君桓文化",
  ["zhengbing"] = "整兵",
  [":zhengbing"] = "群势力技，出牌阶段限三次，你可以重铸一张牌，若此牌为：<br>【杀】，你此回合手牌上限+2；<br>【闪】，你摸一张牌；<br>"..
  "【桃】，你变更势力至魏。",
  ["tuwei"] = "突围",
  [":tuwei"] = "魏势力技，出牌阶段开始时，你可以获得攻击范围内任意名角色各一张牌；回合结束时，这些角色中本回合未受到过伤害的角色各获得你的一张牌。",
  ["#zhengbing"] = "整兵：你可以重铸一张牌，若为基本牌，获得额外效果",
  ["#tuwei-choose"] = "突围：你可以获得攻击范围内任意名角色各一张牌",
}

return extension
