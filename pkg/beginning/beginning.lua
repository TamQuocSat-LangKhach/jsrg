
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
Fk:loadTranslationTable{
  ["langmie"] = "狼灭",
  [":langmie"] = "其他角色的结束阶段，你可以选择一项：<br>1.若其本回合使用过至少两张相同类型的牌，你可以弃置一张牌，摸两张牌；<br>"..
  "2.若其本回合造成过至少2点伤害，你可以弃置一张牌，对其造成1点伤害。",
  ["#langmie1"] = "狼灭：你可以弃置一张牌，摸两张牌",
  ["#langmie2"] = "狼灭：你可以弃置一张牌，对 %dest 造成1点伤害",
  ["#langmie3"] = "狼灭：你可以弃置一张牌，然后摸两张牌或对 %dest 造成1点伤害",
  ["langmie_damage"] = "对其造成1点伤害",

  ["$langmie1"] = "群狼四起，灭其一威众。",
  ["$langmie2"] = "贪狼强力，寡义而趋利。",
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
Fk:loadTranslationTable{
  ["fendi"] = "分敌",
  [":fendi"] = "每回合限一次，当你使用【杀】指定唯一目标后，你可以展示其至少一张手牌，然后令其只能使用或打出此次展示的牌直到此【杀】结算完毕。"..
  "若如此做，当此【杀】对其造成伤害后，你获得其手牌区或弃牌堆里的这些牌。",
  ["jvxiang"] = "拒降",
  [":jvxiang"] = "当你于摸牌阶段外获得牌后，你可以弃置这些牌，令当前回合角色于本回合出牌阶段使用【杀】次数上限+X（X为你此次弃置牌的花色数）。",
  ["#jvxiang-invoke"] = "拒降：是否弃置这些牌，令当前回合角色使用【杀】次数上限增加？",
  ["@@fendi-inhand"] = "分敌",
}
