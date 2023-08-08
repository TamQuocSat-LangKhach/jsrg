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
xuyou:addSkill(chanpan)
qingxix:addAttachedKingdom("qun")
xuyou:addSkill(qingxix)
kuimie:addAttachedKingdom("wei")
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

-- local guanyu = General(extension, "js__guanyu", "shu", 5)--蓝框
Fk:loadTranslationTable{
  ["js__guanyu"] = "关羽",
  ["guanjue"] = "冠绝",
  [":guanjue"] = "锁定技，当你使用或打出一张牌时，你令所有其他角色于此回合内不能使用或打出花色与之相同的牌。",
  ["nianen"] = "念恩",
  [":nianen"] = "你可以将你的一张牌当任意基本牌使用或打出，然后若你以此法转化后的牌不为普通【杀】或此牌不为红色，则直到此回合结束，你视为拥有〖马术〗"..
  "且不能发动本技能。",
}

-- local chendeng = General(extension, "js__chendeng", "qun", 3)
Fk:loadTranslationTable{
  ["js__chendeng"] = "陈登",
  ["lunshi"] = "论势",
  [":lunshi"] = "出牌阶段限一次，你可以令一名角色摸等同于其攻击范围内角色数的牌（至多摸至五张），然后令该角色弃置等同于攻击范围内含有其的角色数的牌。",
  ["shuiwei"] = "说围",
  [":shuiwei"] = "准备阶段，你可以交换场上的两张武器牌，然后攻击范围因此以此法减少的角色回复1点体力。",
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

--[[local zhangliao = General(extension, "js__zhangliao", "qun", 4)
zhangliao.subkingdom = "wei"
local xbing = fk.CreateActiveSkill{
  name = "xbing",
  anim_type = "drawcard",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 3
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:recastCard(effect.cards, player, self.name)
  end,
}
zhangliao:addSkill(xbing)]]--
Fk:loadTranslationTable{
  ["js__zhangliao"] = "张辽",
  ["xbing"] = "x兵",
  [":xbing"] = "群势力技，出牌阶段限三次，你可以重铸一张牌，若此牌为：【杀】，你此回合手牌上限+2；【闪】，你摸一张牌；【桃】，你变更势力至魏。",
  ["dingwei"] = "定围",--大概不对
  [":dingwei"] = "魏势力技，出牌阶段开始时，你可以获得攻击范围内任意名角色各一张牌；回合结束时，这些角色中本回合未受到过伤害的角色各获得你的一张牌。",
}

return extension
