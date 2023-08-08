local extension = Package("continue")
extension.extensionName = "jsrg"

Fk:loadTranslationTable{
  ["continue"] = "江山如故-承包",
}

-- local sunce = General(extension, "js__sunce", "wu", 4)
Fk:loadTranslationTable{
  ["js__sunce"] = "孙策",
  ["duxing"] = "独行",
  [":duxing"] = "出牌阶段限一次，你可以视为使用一张以任意名角色为目标的【决斗】，" ..
    "此牌结算过程中，所有目标的手牌均视为【杀】。",
  ["js__zhiheng"] = "猘横",
  [":js__zhiheng"] = "锁定技，当你使用牌对目标角色造成伤害时，" ..
    "若其于本回合内使用或打出牌响应过你使用的牌，则此伤害+1。",
  ["zhasi"] = "诈死",
  [":zhasi"] = "限定技，当你受到致命伤害时，你可以防止之，失去猘横并获得制衡，" ..
    "然后令你不计入座次和距离计算直到你对其他角色使用牌或当你受到伤害后。",
  ["bashi"] = "霸世",
  [":bashi"] = "主公技，当你需要打出【杀】或【闪】时，你可令其他吴势力角色各选择是否代替你打出。",
}

--许贡 严夫人 淳于琼 陶谦 二次元 手杀高览 麹义 曹嵩
--这些没改技能的话就不做

local xuyou = General(extension, "js__xuyou", "qun", 3)
xuyou.subkingdom = "wei"
local chanpan = fk.CreateTriggerSkill{
  name = "chanpan",
  anim_type = "drawcard",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.to == Player.NotActive
  end,
  on_cost = function(self, event, target, player, data)
    local kingdoms = {"Cancel", "wei", "shu", "wu", "qun", "jin"}
    local choices = table.simpleClone(kingdoms)
    table.removeOne(choices, player.kingdom)
    local choice = player.room:askForChoice(player, choices, self.name, "#chanpan-invoke", false, kingdoms)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player.kingdom = self.cost_data
    room:broadcastProperty(player, "kingdom")
    if player.general == "js__xuyou" or player.deputyGeneral == "js__xuyou" then
      local skills = ""
      if player.kingdom == "qun" then
        if player:hasSkill("kuimie", true) then
          skills = "-kuimie|"
        end
        room:handleAddLoseSkills(player, skills.."qingxix", nil, true, false)
      elseif player.kingdom == "wei" then
        if player:hasSkill("qingxix", true) then
          skills = "-qingxix|"
        end
        room:handleAddLoseSkills(player, skills.."kuimie", nil, true, false)
      else
        room:handleAddLoseSkills(player, "-qingxix|-kuimie", nil, true, false)
      end
    end
    local tos = table.filter(room:getOtherPlayers(player), function(p) return p.kingdom == player.kingdom end)
    if #tos > 0 then
      player:drawCards(#tos, self.name)
    end
    player:gainAnExtraPhase(Player.Play, true)
  end,
}
local chanpan_trigger = fk.CreateTriggerSkill{
  name = "#chanpan_trigger",
  mute = true,
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and player:usedSkillTimes("chanpan", Player.HistoryTurn) > 0 and
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
        local card = room:askForCard(p, 1, 1, true, "chanpan", true, ".", "#chanpan-duel::"..player.id)
        if #card > 0 then
          room:useVirtualCard("duel", card, p, player, "chanpan")
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
    return #selected == 0 and target:getHandcardNum() < Self:getHandcardNum() and not Self:isProhibited(target, Fk:cloneCard("slash")) and
      target:getMark("qingxix-phase") == 0
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
      card = Fk:cloneCard("slash"),  --TODO: 真的刺杀
      extraUse = true,
    }
    use.card.skillName = self.name
    room:useCard(use)
  end,
}
local qingxix_trigger = fk.CreateTriggerSkill{
  name = "#qingxix_trigger",
  mute = true,
  events = {fk.CardEffectCancelledOut},
  can_trigger = function(self, event, target, player, data)
    return data.card.trueName == "slash" and table.contains(data.card.skillNames, "qingxix") and
      data.to == player.id and not player.dead and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #player.room:askForDiscard(player, 1, 1, false, "qingxix", true, ".", "#qingxix-discard") == 0 then
      return true
    end
  end,
}
local kuimie = fk.CreateActiveSkill{
  name = "kuimie",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#kuimie",
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
chanpan:addRelatedSkill(chanpan_trigger)
qingxix:addRelatedSkill(qingxix_trigger)
qingxix:addAttachedKingdom("qun")
kuimie:addAttachedKingdom("wei")
xuyou:addSkill(chanpan)
xuyou:addSkill(qingxix)
xuyou:addSkill(kuimie)
Fk:loadTranslationTable{
  ["js__xuyou"] = "许攸",
  ["chanpan"] = "谗叛",--有可能看错技能名
  [":chanpan"] = "回合结束时，你可以变更势力，然后摸X张牌并执行一个额外的出牌阶段（X为势力与你相同的其他角色数）。此阶段结束时，"..
  "所有势力与你相同的其他角色可以将一张牌当【决斗】对你使用。",
  ["qingxix"] = "轻袭",
  [":qingxix"] = "群势力技，出牌阶段对每名角色限一次，你可以选择一名手牌数小于你的角色，你将手牌弃至与其相同，"..
  "然后视为对其使用一张无距离和次数限制的刺【杀】。",
  ["kuimie"] = "殨灭",--？
  [":kuimie"] = "魏势力技，出牌阶段限一次，你可以选择一名手牌数大于你的角色，视为对其使用一张无距离和次数限制的火【杀】。此牌造成伤害后，"..
  "你将其手牌弃置至与你相同。",
  ["#chanpan-invoke"] = "谗叛：你可以改变势力并摸牌，然后执行一个出牌阶段",
  ["#chanpan-duel"] = "谗叛：你可以将一张牌当【决斗】对 %dest 使用",
  ["#qingxix"] = "轻袭：选择一名手牌数小于你的角色，将手牌弃至与其相同，视为对其使用刺【杀】",
  ["#qingxix-discard"] = "轻袭：弃置一张手牌，否则此【杀】依然对你造成伤害",
  ["#kuimie"] = "殨灭：选择一名手牌数大于你的角色，视为对其使用火【杀】，若造成伤害弃置其手牌",
}

-- local lvbu = General(extension, "js__lvbu", "qun", 5)
--lvbu.subkingdom = "shu"  --傻逼
Fk:loadTranslationTable{
  ["js__lvbu"] = "吕布",
  ["wudang"] = "无当",
  [":wudang"] = "当你得到其他角色的牌后，你变更势力至与其相同；当你使用【杀】或【决斗】对势力与你相同的角色造成伤害时，你令此伤害+1，然后你变更势力至群。",
  ["qingjiaol"] = "轻狡",
  [":qingjiaol"] = "群势力技，出牌阶段各限一次，你可以将一张牌当【推心置腹】/【趁火打劫】对一名手牌数大于/小于你的角色使用。",
  ["chengxu"] = "乘虚",
  [":chengxu"] = "蜀势力技，锁定技，势力与你相同的其他角色不能响应你使用的牌。",--描述没写锁定技
}

-- local zhanghe = General(extension, "js__zhanghe", "qun", 4)
--zhanghe.subkingdom = "wei"
Fk:loadTranslationTable{
  ["js__zhanghe"] = "张郃",
  ["qiongda"] = "穷达",--第二个字没看清
  [":qiongda"] = "群势力技，每回合限一次，你可以将一张非基本牌置于武将牌上视为使用一张【无懈可击】，若该【无懈可击】生效，你摸一张牌，否则你变更势力至魏"..
  "并获得武将牌上的所有牌。",
  ["xianzhu"] = "先著",
  [":xianzhu"] = "魏势力技，你可以将一张普通锦囊牌当无次数限制的【杀】使用，此【杀】对唯一目标造成伤害后，你视为对目标额外执行该锦囊牌的效果。",
}

-- local zoushi = General(extension, "js__zoushi", "qun", 3, 3, General.Female)
Fk:loadTranslationTable{
  ["js__zoushi"] = "邹氏",
  ["guyin"] = "孤吟",
  [":guyin"] = "准备阶段，你可以翻面，然后令所有其他男性角色。",
  ["balabalabala"] = "",
  ["balabalabala:"] = "当一名武将牌背面朝上的角色需要使用【酒】时，若你的武将牌背面朝上，其可以视为使用之。当本技能于一回合内第二次发动时，你翻面至正面朝上。",
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
        ((Fk.currentResponsePattern == nil and card.skill:canUse(Self)) or
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
local shuiwei = fk.CreateTriggerSkill{
  name = "shuiwei",
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
    local tos = room:askForChoosePlayers(player, targets, 2, 2, "#shuiwei-choose", self.name, true)
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
chendeng:addSkill(shuiwei)
Fk:loadTranslationTable{
  ["js__chendeng"] = "陈登",
  ["lunshi"] = "论势",
  [":lunshi"] = "出牌阶段限一次，你可以令一名角色摸等同于其攻击范围内角色数的牌（至多摸至五张），然后令该角色弃置等同于攻击范围内含有其的角色数的牌。",
  ["shuiwei"] = "说围",
  [":shuiwei"] = "准备阶段，你可以交换场上的两张武器牌，然后攻击范围因此以此法减少的角色回复1点体力。",
  ["#lunshi"] = "论势：令一名角色摸其攻击范围内角色数牌，然后其弃置攻击范围内含有其角色数牌",
  ["#shuiwei-choose"] = "说围：你可以交换场上两张武器牌，攻击范围减小的角色回复1点体力",
}

-- local zhenfu = General(extension, "js__zhenji", "qun", 3, 3, General.Female)
Fk:loadTranslationTable{
  ["js__zhenji"] = "甄宓",
  ["jixiang"] = "济乡",
  [":jixiang"] = "回合内对每种牌名限一次，当一名其他角色需要使用或打出一张基本牌，你可以弃置一张牌令其视为使用或打出之，然后你摸一张牌并令〖称贤〗"..
  "于此阶段可发动次数+1。",
  ["chengxian"] = "称贤",
  [":chengxian"] = "出牌阶段限两次，你可以将一张手牌当一张本回合未以此法使用过的普通锦囊牌使用，以此法转化后普通锦囊牌须与原牌名的牌合法目标角色数相同。",
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
      player.kingdom = "wei"
      room:broadcastProperty(player, "kingdom")
      if player.general == "js__zhangliao" or player.deputyGeneral == "js__zhangliao" then
        room:handleAddLoseSkills(player, "-zhengbing|tuwei", nil, true, false)
      end
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
