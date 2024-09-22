local extension = Package("rise")
extension.extensionName = "jsrg"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["rise"] = "江山如故·兴",
}

local jiananfeng = General(extension, "jiananfeng", "jin", 3, 3, General.Female)
local fuyu = fk.CreateActiveSkill{
  name = "fuyu",
  anim_type = "offensive",
  card_num = 0,
  min_target_num = 1,
  prompt = "#fuyu",
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
    local targets = table.map(effect.tos, function(id) return room:getPlayerById(id) end)
    local discussion = U.Discussion{
      reason = self.name,
      from = player,
      tos = targets,
    }
    if not player.dead and discussion.results[player.id] and
      discussion.color == discussion.results[player.id].opinion then
      local targets1 = table.filter(targets, function (p)
        return not p.dead and discussion.results[p.id].opinion ~= discussion.results[player.id].opinion
      end)
      local targets2 = table.filter(room.alive_players, function (p)
        return not table.contains(targets, p)
      end)
      if #targets1 == 0 and #targets2 == 0 then return end
      room:setPlayerMark(player, "fuyu-tmp", {table.map(targets1, Util.IdMapper), table.map(targets2, Util.IdMapper)})
      local success, dat = room:askForUseActiveSkill(player, "fuyu_active", "#fuyu-damage", true, nil, false)
      room:setPlayerMark(player, "fuyu-tmp", 0)
      if success and dat then
        room:sortPlayersByAction(dat.targets)
        for _, id in ipairs(dat.targets) do
          local p = room:getPlayerById(id)
          if not p.dead then
            room:damage{
              from = player,
              to = p,
              damage = 1,
              skillName = self.name,
            }
          end
        end
      end
    end
  end,
}
local fuyu_active = fk.CreateActiveSkill{
  name = "fuyu_active",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 2,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return table.contains(Self:getMark("fuyu-tmp")[1], to_select) or table.contains(Self:getMark("fuyu-tmp")[2], to_select)
  end,
  feasible = function (self, selected, selected_cards)
    if #selected == 1 then
      return true
    elseif #selected == 2 then
      if table.contains(Self:getMark("fuyu-tmp")[1], selected[1]) then
        return table.contains(Self:getMark("fuyu-tmp")[2], selected[2])
      else
        return table.contains(Self:getMark("fuyu-tmp")[1], selected[2])
      end
    end
  end,
}
local shanzheng = fk.CreateTriggerSkill{
  name = "shanzheng",
  anim_type = "control",
  events = {"fk.StartDiscussion"},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and (player == data.from or table.contains(data.tos, player)) and
      (table.every(player.room.alive_players, function (p)
        return player:getHandcardNum() >= p:getHandcardNum()
      end) or
      table.every(player.room.alive_players, function (p)
        return player.hp >= p.hp
      end))
  end,
  on_cost = function(self, event, target, player, data)
    local choice = player.room:askForChoice(player, {"red", "black", "Cancel"}, self.name,
      "#shanzheng-invoke::"..data.from.id..":"..data.reason)
    if choice ~= "Cancel" then
      self.cost_data = {choice = choice}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data.results[player.id] = data.results[player.id] or {}
    data.results[player.id].opinion = self.cost_data.choice
    data.extra_data = data.extra_data or {}
    data.extra_data.shanzheng = data.extra_data.shanzheng or {}
    data.extra_data.shanzheng[player.id] = self.cost_data.choice
  end,

  refresh_events = {"fk.DiscussionResultConfirming"},
  can_refresh = function (self, event, target, player, data)
    return data.extra_data and data.extra_data.shanzheng and data.extra_data.shanzheng[player.id]
  end,
  on_refresh = function (self, event, target, player, data)
    local color = data.extra_data.shanzheng[player.id]
    data.opinions[color] = (data.opinions[color] or 0) + 1
  end,
}
local xiongbao = fk.CreateTriggerSkill{
  name = "xiongbao",
  anim_type = "offensive",
  events = {fk.CardUsing},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      table.find(player.room:getOtherPlayers(player), function(p)
        return p:isFemale() or p:getHandcardNum() < player:getHandcardNum()
      end)
  end,
  on_use = function(self, event, target, player, data)
    local targets = table.filter(player.room:getOtherPlayers(player), function(p)
      return p:isFemale() or p:getHandcardNum() < player:getHandcardNum()
    end)
    if #targets > 0 then
      data.disresponsiveList = data.disresponsiveList or {}
      for _, p in ipairs(targets) do
        table.insertIfNeed(data.disresponsiveList, p.id)
      end
    end
  end,
}
local liedu = fk.CreateTriggerSkill{
  name = "liedu",
  anim_type = "offensive",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target and target == player and player:hasSkill(self) and
      (data.to.hp < player.hp and data.to:isFemale() or data.to.hp == 1) and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#liedu-invoke::"..data.to.id)
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage * 2
  end,
}
Fk:addSkill(fuyu_active)
jiananfeng:addSkill(fuyu)
jiananfeng:addSkill(shanzheng)
jiananfeng:addSkill(xiongbao)
jiananfeng:addSkill(liedu)
Fk:loadTranslationTable{
  ["jiananfeng"] = "贾南风",
  ["#jiananfeng"] = "",
  ["illustrator:jiananfeng"] = "",

  ["fuyu"] = "覆雨",
  [":fuyu"] = "出牌阶段限一次，你可以与任意名角色议事，若结果与你的意见相同，你可以对一名意见不同和一名未参与议事的角色各造成1点伤害。",
  ["shanzheng"] = "擅政",
  [":shanzheng"] = "当你参与议事选择议事牌前，若你的手牌数或体力值为全场最大，你本次议事无需展示手牌，改为声明一种颜色作为你的意见，且你的"..
  "意见视为两名角色的意见。",
  ["xiongbao"] = "凶暴",
  [":xiongbao"] = "锁定技，其他女性角色和手牌数小于你的角色不能响应你使用的牌。",
  ["liedu"] = "烈妒",
  [":liedu"] = "每回合限一次，当你对体力值小于你的女性角色或体力值为1的角色造成伤害时，你可以令此伤害值翻倍。",
  ["#fuyu"] = "覆雨：与任意名角色议事，若结果与你的意见相同，你可以对一名意见不同和一名未参与议事的角色各造成1点伤害",
  ["fuyu_active"] = "覆雨",
  ["#fuyu-damage"] = "覆雨：你可以对一名意见不同和一名未参与议事的角色各造成1点伤害",
  ["#shanzheng-invoke"] = "擅政：%dest 因“%arg”发起议事，是否改为选择一种颜色作为你的意见？",
  ["#liedu-invoke"] = "烈妒：是否令你对 %dest 造成的伤害翻倍？",
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
    room:damage({
      from = player,
      to = to,
      damage = 1,
      skillName = self.name,
    })
    if player.dead or to.dead or (#player:getCardIds("e") == 0 and #to:getCardIds("e") == 0) then return end
    if room:askForSkillInvoke(player, self.name, nil, "#chengliu-swap::"..to.id) then
      U.swapCards(room, player, player, to, player:getCardIds("e"), to:getCardIds("e"), self.name, Card.PlayerEquip)
      if player.dead then return end
      if table.find(room.alive_players, function (p)
        return #player:getCardIds("e") > #p:getCardIds("e")
      end) then
        self:doCost(event, target, player, data)
      end
    end
  end,
}
local jianlou = fk.CreateTriggerSkill{
  name = "jianlou",
  anim_type = "control",
  events = {fk.BeforeCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and not player:isNude() then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile then
          for _, info in ipairs(move.moveInfo) do
            if (info.fromArea == Card.PlayerEquip or info.fromArea == Card.PlayerJudge) and
              Fk:getCardById(info.cardId).type == Card.TypeEquip and
              player:hasEmptyEquipSlot(Fk:getCardById(info.cardId).sub_type) then
              return true
            end
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local cards = {}
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          if (info.fromArea == Card.PlayerEquip or info.fromArea == Card.PlayerJudge) and
            Fk:getCardById(info.cardId).type == Card.TypeEquip and
            player:hasEmptyEquipSlot(Fk:getCardById(info.cardId).sub_type) then
            table.insertIfNeed(cards, info.cardId)
          end
        end
      end
    end
    if #cards == 0 then return end
    for _, id in ipairs(cards) do
      if not player:hasSkill(self) or player:isNude() or player:usedSkillTimes(self.name, Player.HistoryTurn) > 0 then return end
      self.cost_data = id
      self:doCost(event, nil, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForDiscard(player, 1, 1, true, self.name, true, nil,
      "#jianlou-invoke:::"..Fk:getCardById(self.cost_data):toLogString(), true)
    if #card > 0 then
      self.cost_data = {cards = card, extra_data = {self.cost_data}}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(self.cost_data.cards, self.name, player, player)
    if player.dead then return end
    local card = Fk:getCardById(self.cost_data.extra_data[1])
    if card.type ~= Card.TypeEquip or not player:hasEmptyEquipSlot(card.sub_type) then return end
    local new_moves = {}
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile then
        local move_info, new_info = {}, {}
        for _, info in ipairs(move.moveInfo) do
          if info.cardId ~= self.cost_data.extra_data[1] then
            table.insert(move_info, info)
          else
            table.insert(new_info, info)
          end
        end
        if #new_info > 0 then
          move.moveInfo = move_info
          local new_move = table.simpleClone(move)
          new_move.to = player.id
          new_move.toArea = Card.PlayerEquip
          new_move.moveInfo = new_info
          new_move.skillName = self.name
          new_move.moveReason = fk.ReasonPut
          new_move.proposer = player.id
          table.insert(new_moves, new_move)
        end
      end
    end
    if #new_moves > 0 then
      table.insertTable(data, new_moves)
    end
  end,
}
wangjun:addSkill(chengliu)
wangjun:addSkill(jianlou)
Fk:loadTranslationTable{
  ["js__wangjun"] = "王濬",
  ["#js__wangjun"] = "",
  ["illustrator:js__wangjun"] = "",

  ["chengliu"] = "乘流",
  [":chengliu"] = "准备阶段，你可以对一名装备区内牌数小于你的角色造成1点伤害，然后你可以交换你与其装备区的所有牌，若如此做，你可以重复此流程。",
  ["jianlou"] = "舰楼",
  [":jianlou"] = "每回合限一次，当一张装备牌从场上移动至弃牌堆时，你可以弃置一张牌，改为将之置入你的装备区。",
  ["#chengliu-invoke"] = "乘流：你可以对一名装备数小于你的角色造成1点伤害，然后你可以与其交换装备并重复此流程",
  ["#chengliu-swap"] = "乘流：是否与 %dest 交换装备？",
  ["#jianlou-invoke"] = "舰楼：%arg即将进入弃牌堆，是否弃置一张牌，改为将之置入你的装备区？",
}

local limi = General(extension, "limi", "shu", 3)
limi.subkingdom = "jin"
local nanquan = fk.CreateViewAsSkill{
  name = "nanquan",
  pattern = ".",
  prompt = "#nanquan",
  interaction = function(self)
    local all_names = U.getAllCardNames("bt")
    local names = U.getViewAsCardNames(Self, self.name, all_names)
    if #names > 0 then
      return U.CardNameBox { choices = names, all_choices = all_names }
    end
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and table.contains(Self:getHandlyIds(true), to_select)
  end,
  view_as = function(self, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    local mark = "basic"
    if use.card.type == Card.TypeBasic then
      mark = "trick"
    end
    player.room:setPlayerMark(player, "@nanquan-round", mark)
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  enabled_at_response = function(self, player, response)
    if not response and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and Fk.currentResponsePattern then
      for _, name in ipairs(U.getAllCardNames("bt")) do
        local card = Fk:cloneCard(name)
        if Exppattern:Parse(Fk.currentResponsePattern):match(card) and not player:prohibitUse(card) then
          return true
        end
      end
    end
  end,
}
local nanquan_prohibit = fk.CreateProhibitSkill{
  name = "#nanquan_prohibit",
  prohibit_use = function(self, player, card)
    return card and player:getMark("@nanquan-round") == card:getTypeString()
  end,
}
local minfeng = fk.CreateTriggerSkill{
  name = "minfeng",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if target == player and player.phase == Player.NotActive and player:getHandcardNum() < player.maxHp and
      player:hasSkill(self) and
      data.card.number > 0 and data.card.number < 13 then
      local room = player.room
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn)
      if turn_event == nil then return end
      local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event == nil then return end
      local events = room.logic.event_recorder[GameEvent.UseCard] or {}
      local last_find = false
      for i = #events, 1, -1 do
        local e = events[i]
        if e.id < turn_event.id then return end
        if e.id == use_event.id then
          last_find = true
        elseif last_find then
          if e.data[1].card.number + data.card.number == 13 then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(player.maxHp - player:getHandcardNum(), self.name)
  end,

  refresh_events = {fk.AfterCardUseDeclared, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      return player:hasSkill(self, true) and player.phase == Player.NotActive
    else
      return target == player and data == self
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardUseDeclared then
      if data.card.number == 0 then
        room:setPlayerMark(player, "@minfeng-turn", 0)
      else
        room:setPlayerMark(player, "@minfeng-turn", data.card.number)
      end
    else
      room:setPlayerMark(player, "@minfeng-turn", 0)
    end
  end,
}
nanquan:addRelatedSkill(nanquan_prohibit)
limi:addSkill(nanquan)
limi:addSkill(minfeng)
Fk:loadTranslationTable{
  ["limi"] = "李密",
  ["#limi"] = "",
  ["illustrator:limi"] = "",

  ["nanquan"] = "难全",
  [":nanquan"] = "每回合限一次，你可以将一张手牌当任意基本牌或普通锦囊牌使用，然后你本轮不能使用另一种类别的牌。",
  ["minfeng"] = "敏封",
  [":minfeng"] = "当你于回合外使用牌时，若此牌与本回合上一张被使用的牌点数之和为13，你可以将手牌摸至体力上限。",
  ["#nanquan"] = "难全：将一张手牌当任意基本牌或普通锦囊牌使用，然后你本轮不能使用另一种类别的牌",
  ["@nanquan-round"] = "禁用",
  ["@minfeng-turn"] = "敏封",
}

local wenyang = General(extension, "js__wenyang", "wei", 4)
wenyang.subkingdom = "jin"
local fuzhen = fk.CreateTriggerSkill{
  name = "fuzhen",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Start and #player.room.alive_players > 1
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), Util.IdMapper), 1, 1,
      "#fuzhen-choose", self.name, true, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local targets = table.map(room:getOtherPlayers(player), Util.IdMapper)
    if #targets > 1 then
      local _, dat = room:askForUseActiveSkill(player, "choose_players_skill", "#fuzhen-slash::"..to.id, false, {
        targets = targets,
        num = 3,
        min_num = 1,
        pattern = "",
        skillName = self.name,
        must_targets = {to.id},
      }, false)
      targets = dat.targets
    end
    room:sortPlayersByAction(targets)
    room:loseHp(player, 1, self.name)
    local use = room:useVirtualCard("thunder__slash", nil, player, table.map(targets, Util.Id2PlayerMapper), self.name, true)
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
    if not use.damageDealt or not use.damageDealt[to.id] then
      targets = table.filter(targets, function (id)
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
  ["#js__wenyang"] = "",
  ["illustrator:js__wenyang"] = "",

  ["fuzhen"] = "覆阵",
  [":fuzhen"] = "准备阶段，你可以秘密选择一名其他角色，然后失去1点体力，视为对包括其在内的至多三名角色使用一张无距离限制的雷【杀】。"..
  "此【杀】结算后，你摸造成伤害值的牌；若未对你秘密选择的角色造成伤害，你再视为对这些角色使用一张雷【杀】。",
  ["#fuzhen-choose"] = "覆阵：你可以秘密选择一名角色，失去1点体力，视为对包括其在内的至多三名角色使用雷【杀】",
  ["#fuzhen-slash"] = "覆阵：选择包括 %dest 在内的至多三名角色，视为对这些角色使用雷【杀】",
}

local zhugedan = General(extension, "js__zhugedan", "wei", 4)
local beizhi = fk.CreateActiveSkill{
  name = "beizhi",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#beizhi",
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
    local pindian = player:pindian({target}, self.name)
    local winner = pindian.results[target.id].winner
    if winner == nil or winner.dead then return end
    local loser = nil
    if winner == player then
      loser = target
    else
      loser = player
    end
    if loser == nil or loser.dead then return end
    local targets = table.map(room:getOtherPlayers(winner), Util.IdMapper)
    if #targets > 3 then
      local _, dat = room:askForUseActiveSkill(winner, "choose_players_skill", "#beizhi-duel::"..loser.id, false, {
        targets = targets,
        num = math.min(3, #targets),
        min_num = math.min(3, #targets),
        pattern = "",
        skillName = self.name,
        must_targets = {loser.id},
      }, false)
      targets = dat.targets
    end
    room:sortPlayersByAction(targets)
    room:useVirtualCard("duel", nil, winner, table.map(targets, Util.Id2PlayerMapper), self.name)
  end,
}
local beizhi_delay = fk.CreateTriggerSkill{
  name = "#beizhi_delay",
  mute = true,
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return target and target == player and not player.dead and data.card and table.contains(data.card.skillNames, "beizhi") and
      not data.to.dead and not data.to:isNude()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("beizhi")
    room:notifySkillInvoked(player, "beizhi", "control")
    room:doIndicate(player.id, {data.to.id})
    local card = room:askForCardChosen(player, data.to, "he", "beizhi", "#beizhi-prey::"..data.to.id)
    room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonPrey, "beizhi", nil, false, player.id)
  end
}
local shenjiz = fk.CreateTriggerSkill{
  name = "shenjiz",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.BeforeCardUseEffect},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and #TargetGroup:getRealTargets(data.tos) > 1 and
      table.contains(TargetGroup:getRealTargets(data.tos), player.id)
  end,
  on_use = function(self, event, target, player, data)
    local new_tos = {}
    for _, info in ipairs(data.tos) do
      if info[1] ~= player.id then
        table.insert(new_tos, info)
      end
    end
    for _, info in ipairs(data.tos) do
      if info[1] == player.id then
        table.insert(new_tos, info)
      end
    end
    data.tos = new_tos
  end,
}
beizhi:addRelatedSkill(beizhi_delay)
zhugedan:addSkill(beizhi)
zhugedan:addSkill(shenjiz)
Fk:loadTranslationTable{
  ["js__zhugedan"] = "诸葛诞",
  ["#js__zhugedan"] = "",
  ["illustrator:js__zhugedan"] = "",

  ["beizhi"] = "悖志",
  [":beizhi"] = "出牌阶段限一次，你可以与一名角色拼点，赢的角色须选择包括没赢角色在内的三名角色（不足则全选），视为对这些角色使用一张"..
  "【决斗】；此【决斗】造成伤害后，伤害来源获得受伤角色一张牌。",
  ["shenjiz"] = "深忌",
  [":shenjiz"] = "锁定技，以你为目标的牌若有其他目标，则此牌最后对你结算。",
  ["#beizhi"] = "悖志：与一名角色拼点，赢的角色视为对包括没赢角色在内的三名角色使用【决斗】",
  ["#beizhi-duel"] = "覆阵：选择包括 %dest 在内的三名角色，视为对这些角色使用【决斗】",
  ["#beizhi_delay"] = "悖志",
  ["#beizhi-prey"] = "悖志：获得 %dest 一张牌",
}

return extension
