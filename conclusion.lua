local extension = Package("conclusion")
extension.extensionName = "jsrg"

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["conclusion"] = "江山如故·合",
}

local zhugeliang = General(extension, "js__zhugeliang", "shu", 3)
Fk:loadTranslationTable{
  ["js__zhugeliang"] = "诸葛亮",
}

local wentian = fk.CreateViewAsSkill{
  name = "wentian",
  pattern = "fire_attack,nullification",
  interaction = function()
    local names = {}
    local availableNames = { "fire_attack", "nullification" }
    for _, name in ipairs(availableNames) do
      local card = Fk:cloneCard(name)
      if 
        ((Fk.currentResponsePattern == nil and Self:canUse(card)) or
        (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card)))
      then
        table.insertIfNeed(names, name)
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
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
      room:setPlayerMark(player, "@@wentian_nullified-round", 1)
    end
  end,
  enabled_at_play = function(self, player)
    return player:getMark("@@wentian_nullified-round") == 0
  end,
  enabled_at_response = function(self, player, response)
    return player:getMark("@@wentian_nullified-round") == 0 and not response
  end,
}
local wentianGive = fk.CreateActiveSkill{
  name = "wentian_give",
  expand_pile = "wentian",
  card_num = 1,
  target_num = 1,
  card_filter = function(self, to_select, selected, targets)
    local ids = Self:getMark("wentianCards")
    return #selected == 0 and type(ids) == "table" and table.contains(ids, to_select)
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id
  end,
}
Fk:addSkill(wentianGive)
local wentianTrigger = fk.CreateTriggerSkill{
  name = "#wentian_trigger",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    local normalPhases = {
      Player.Start,
      Player.Judge,
      Player.Draw,
      Player.Play,
      Player.Discard,
      Player.Finish,
    }

    return
      target == player and
      player:hasSkill(self) and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
      player:getMark("@@wentian_nullified-round") == 0 and
      table.contains(normalPhases, player.phase)
  end,
  on_cost = function(self, event, target, player, data)
    local phase_name_table = {
      [2] = "phase_start",
      [3] = "phase_judge",
      [4] = "phase_draw",
      [5] = "phase_play",
      [6] = "phase_discard",
      [7] = "phase_finish",
    }

    return player.room:askForSkillInvoke(player, "wentian", data, "#wentian-ask:::" .. phase_name_table[player.phase])
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local topCardIds = room:getNCards(5)

    local others = room:getOtherPlayers(player)
    if #others > 0 then
      player.special_cards["wentian"] = topCardIds
      player:doNotify("ChangeSelf", json.encode {
        id = player.id,
        handcards = player:getCardIds("h"),
        special_cards = player.special_cards,
      })
      room:setPlayerMark(player, "wentianCards", topCardIds)
      local _, ret = room:askForUseActiveSkill(player, "wentian_give", "#wentian-give", true, nil, true)
      room:setPlayerMark(player, "wentianCards", 0)
      player.special_cards["wentian"] = topCardIds
      player:doNotify("ChangeSelf", json.encode {
        id = player.id,
        handcards = player:getCardIds("h"),
        special_cards = player.special_cards,
      })

      local toGive = ret and ret.cards[1] or topCardIds[1]
      table.removeOne(topCardIds, toGive)
      room:moveCardTo(toGive, Card.PlayerHand, room:getPlayerById(ret.targets[1]), fk.ReasonGive, "wentian", nil, false, player.id)

      room:askForGuanxing(player, topCardIds, nil, nil, "wentian")
    end
  end,
}
Fk:loadTranslationTable{
  ["wentian"] = "问天",
  ["#wentian_trigger"] = "问天",
  [":wentian"] = "你可以将牌堆顶的牌当【无懈可击】/【火攻】使用，若此牌不为黑色/红色，本技能于本轮内失效；\
  每回合限一次，你的任意阶段开始时，你可以观看牌堆顶五张牌，然后将其中一张牌交给一名其他角色，其余牌以任意顺序置于牌堆顶或牌堆底。",
  ["@@wentian_nullified-round"] = "问天失效",
  ["#wentian-ask"] = "你是否发动技能“问天”（当前为 %arg ）？",
  ["wentian_give"] = "问天给牌",
  ["#wentian-give"] = "问天：请选择其中一张牌交给一名其他角色",
}

wentian:addRelatedSkill(wentianTrigger)
zhugeliang:addSkill(wentian)

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
      (not player:isKongcheng() or
      table.find(Fk:currentRoom().alive_players, function(p) return p.role == "lord" and not p:isKongcheng() end))
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
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

    room:doIndicate(player.id, table.map(targets, function(p) return p.id end))
    local discussion = U.Discussion{
      reason = self.name,
      from = player,
      tos = table.filter(targets, function(p) return not p:isKongcheng() end),
      results = {},
    }
    if discussion.color == "red" then
      local drawTargets = { player.id }
      if player ~= target then
        table.insert(drawTargets, target.id)
        room:sortPlayersByAction(drawTargets)
      end

      drawTargets = table.map(drawTargets, function(id) return room:getPlayerById(id) end)

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
Fk:loadTranslationTable{
  ["chushi"] = "出师",
  ["#chushi"] = "出师：你可以和主公议事，红色你与其摸牌，黑色你本轮属性伤害增加",
  ["#chushi_buff"] = "出师",
  [":chushi"] = "出牌阶段限一次，你可以和主公议事，若结果为：红色，你与其各摸一张牌，然后重复此摸牌流程，直到你与其手牌之和不小于7\
  （若此主公为你，则改为你重复摸一张牌直到你的手牌数不小于7）；黑色，当你于本轮内造成属性伤害时，此伤害+1。",
  ["@chushiBuff-round"] = "出师+",
}

chushi:addRelatedSkill(chushiBuff)
zhugeliang:addSkill(chushi)

local yinlve = fk.CreateTriggerSkill{
  name = "yinlve",
  anim_type = "support",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    local availableDMGTypes = {fk.ThunderDamage, fk.FireDamage}
    return
      player:hasSkill(self) and
      table.contains(availableDMGTypes, data.damageType) and
      player:getMark("yinlveUsed" .. data.damageType .. "-round") == 0
  end,
  on_cost = function(self, event, target, player, data)
    local damageTypeTable = {
      [fk.FireDamage] = "fire_damage",
      [fk.ThunderDamage] = "thunder_damage",
    }

    local phase_name_table = {
      [3] = "phase_draw",
      [2] = "phase_discard",
    }

    return player.room:askForSkillInvoke(
      player,
      self.name,
      data,
      "#yinlve-ask::" .. data.to.id .. ":" .. damageTypeTable[data.damageType] .. ":" .. phase_name_table[data.damageType]
    )
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "yinlveUsed" .. data.damageType .. "-round", 1)
    
    local logic = room.logic
    local turn = logic:getCurrentEvent():findParent(GameEvent.Turn, true)
    if turn then
      turn:prependExitFunc(
        function()
          room:sendLog{
            type = "#GainAnExtraTurn",
            from = player.id
          }
        
          local current = room.current
          room.current = player
        
          player.tag["_extra_turn_count"] = player.tag["_extra_turn_count"] or {}
          local ex_tag = player.tag["_extra_turn_count"]
          table.insert(ex_tag, "yinlveTurn" .. data.damageType)

          GameEvent(GameEvent.Turn, player):exec()
        
          table.remove(ex_tag)
        
          room.current = current
        end
      )
    end

    return true
  end,

  refresh_events = {fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    local extraTurnInfo = player.tag["_extra_turn_count"]

    return
      target == player and
      type(extraTurnInfo) == "table" and
      #extraTurnInfo > 0 and
      type(extraTurnInfo[#extraTurnInfo]) == "string" and
      extraTurnInfo[#extraTurnInfo]:startsWith("yinlveTurn") and
      data.to == Player.RoundStart
  end,
  on_refresh = function(self, event, target, player, data)
    local excludePhases = { Player.Start, Player.Judge, Player.Play, Player.Finish }
    local extraTurnInfo = player.tag["_extra_turn_count"]
    table.insert(excludePhases, extraTurnInfo[#extraTurnInfo] == "yinlveTurn" .. fk.ThunderDamage and Player.Draw or Player.Discard)

    for _, phase in ipairs(excludePhases) do
      table.removeOne(player.phases, phase)
    end
  end,
}
Fk:loadTranslationTable{
  ["yinlve"] = "隐略",
  [":yinlve"] = "每轮每项各限一次，当一名角色受到火焰/雷电伤害时，你可以防止此伤害，然后于本回合结束后执行一个仅有摸牌/弃牌阶段的额外回合。",
  ["#yinlve-ask"] = "隐略：你可以防止 %dest 受到的 %arg 伤害，回合结束执行仅有 %arg2 的回合",
}

zhugeliang:addSkill(yinlve)

 --local jiangwei = General(extension, "js__jiangwei", "wu", 4)
Fk:loadTranslationTable{
  ["js__jiangwei"] = "姜维",
}

 --local liuyong = General(extension, "js__liuyong", "shu", 3)
Fk:loadTranslationTable{
  ["js__liuyong"] = "刘永",
  ["js__danxin"] = "丹心",
  [":js__danxin"] = "你可以将一张牌当做【推心置腹】使用，你须展示获得和给出的牌，以此法得到♥️牌的角色回复1点体力，此牌结算后，本回合内你计算与此牌目标的距离+1。",
  ["js__fengxiang"] = "封乡",
  [":js__fengxiang"] = "锁定技，当你受到伤害后，你须与一名其他角色交换装备区内的所有牌，若你装备区内的牌数因此而减少，你摸等同于减少数的牌。",
}

 --local guoxun = General(extension, "js__guoxun", "shu", 4)
Fk:loadTranslationTable{
  ["js__guoxun"] = "郭循",
  ["eqian"] = "遏前",
  [":eqian"] = "结束阶段，你可以【蓄谋】任意次;当你使用【杀】或【蓄谋】牌指定其他角色为唯一目标后，"..
  "你可以令此牌不计入次数限制且获得目标一张牌，然后目标可以令你本回合计算与其的距离+2。",
  ["fusha"] = "伏杀",
  [":fusha"] = "限定技，出牌阶段，若你的攻击范围内仅有一名角色，你可以对其造成X点伤害(X为你的攻击范围且至多为游戏人数)。",
}

 --local gaoxiang = General(extension, "js__gaoxiang", "shu", 4)
Fk:loadTranslationTable{
  ["js__gaoxiang"] = "高翔",
  ["js__chiying"] = "驰应",
  [":js__chiying"] = "出牌阶段限一次，你可以选择一名体力值小于等于你的角色，令其攻击范围内的其他角色各弃置一张牌。若你选择的是其他角色，则其获得其中的基本牌。",
}

--local zhaoyun = General(extension, "js__zhaoyun", "shu", 5)
Fk:loadTranslationTable{
  ["js__zhaoyun"] = "赵云",
}

--local caofang = General(extension, "js__caofang", "wei", 3)
Fk:loadTranslationTable{
  ["js__caofang"] = "曹芳",
}

--local guozhao = General(extension, "js__guozhao", "wei", 3, 3, General.Female)
Fk:loadTranslationTable{
  ["js__guozhao"] = "郭照",
  ["js__pianchon"] = "偏宠",
  [":js__pianchon"] = "每名角色的结束阶段，若你于此回合内失去过牌，你可以进行一次判定，若判定结果为:黑色/红色，你摸此回合进入弃牌的红色/黑色牌数量的牌",
  ["js__zunwei"] = "尊位",
  [":js__zunwei"] = "出牌阶段限一次，你可以选择一名其他角色，并选择执行以下一个选择，然后移除该选项: 1，将手牌补至与其手牌数量相同(至多摸五张)。2，将其装备牌移至你的装备区内，直到你装备区内的牌不少于其。3，将体力值回复至与其相同。",
}

--local wenqin = General(extension, "js__wenqin", "wei", 4)
Fk:loadTranslationTable{
  ["js__wenqin"] = "文钦",
  ["js__guangao"] = "广傲",
  [":js__guangao"] = "你使用【杀】可以多指定一个目标，其他角色使用【杀】可以多指定你为目标，若你的手牌数为偶数，你可以摸一张牌，并令此【杀】对其中任意目标无效。",
  ["js__huiqi"] = "慧企",
  [":js__huiqi"] = "觉醒技，每回合结束后，若本回合内有且仅有包含你在内的三名角色成为过牌的目标，你回复一点体力，并获得“楷举”。",
  ["js__kaiju"] = "楷举",
  [":js__kaiju"] = "出牌阶段限一次，你可以令任意名本回合内成为过牌的目标的角色可以将一张黑色牌当做【杀】使用。",
}

--local luxun = General(extension, "js__luxun", "wu", 3)
Fk:loadTranslationTable{
  ["js__luxun"] = "陆逊",
}

--local sunjun = General(extension, "js__sunjun", "wu", 4)
Fk:loadTranslationTable{
  ["js__sunjun"] = "孙峻",
}

--local weiwenzhugezhi = General(extension, "weiwenzhugezhi", "wu", 4)
Fk:loadTranslationTable{
  ["js__weiwenzhugezhi"] = "卫温&诸葛直",
  ["js__fuhai"] = "浮海",
  [":js__fuhai"] = "出牌阶段限一次，你可以令所有其他角色同时展示一张手牌(没有则跳过)，然后你选择一个方向(顺时针或者逆时针)，并摸X张牌(X为从你开始，该方向上的角色展示的牌点数严格递增或严格递减的牌数，且至少为1)。",
}

--local zhangxuan = General(extension, "js__zhangxuan", "wu", 3, 3, General.Female)
Fk:loadTranslationTable{
  ["js__zhangxuan"] = "张璇",
  ["js__tongli"] = "同礼",
  [":js__tongli"] = "出牌阶段，当你使用基本牌或普通锦囊牌指定目标后，若你手牌中的花色数等于你此阶段使用牌的张数，你可以展示所有手牌，令此牌效果额外结算一次。",
  ["js__shezang"] = "奢葬",
  [":js__shezang"] = "每轮限一次，当你进入濒死状态时或其他角色于你的回合内进入濒死状态时，你可以可以亮出牌堆顶的四张牌，并获得其中任意张花色各不相同的牌。",
}

--local sunlubansunluyu = General(extension, "js__sunlubansunluyu", "wu", 3, 3, General.Female)
Fk:loadTranslationTable{
  ["js__sunlubansunluyu"] = "孙鲁班&孙鲁育",
  ["daimou"] = "殆谋",
  [":daimou"] = "每回合各限一次，当一名角色使用【杀】指定其他角色/你为目标时，你可以用牌堆顶的牌【蓄谋】/你须弃置你区域里的一张【蓄谋】牌。"..
  "当其中一名目标响应此【杀】后，此【杀】对剩余目标造成的伤害+1。",
  ["fangjie"] = "芳潔",
  [":fangjie"] = "准备阶段，若你没有【蓄谋】牌，你回复一点体力并摸一张牌，否则你可以弃置任意张你区域里的【蓄谋】牌并失去此技能。",
}

return extension
