local fuhaiw = fk.CreateSkill {
  name = "js__fuhaiw"
}

Fk:loadTranslationTable{
  ['js__fuhaiw'] = '浮海',
  ['#js__fuhaiw'] = '浮海：令所有其他角色同时展示一张手牌，你根据点数递增递减情况摸牌',
  ['#js__fuhaiw-show'] = '浮海：展示一张手牌，有可能令 %src 摸牌',
  ['js__fuhaiw1'] = '逆时针方向（摸%arg张牌）',
  ['js__fuhaiw2'] = '顺时针方向（摸%arg张牌）',
  [':js__fuhaiw'] = '出牌阶段限一次，你可以令所有其他角色同时展示一张手牌（没有手牌则跳过），然后你选择顺时针或逆时针方向，摸X张牌（X为从你开始该方向上角色展示牌点数严格递增或严格递减的数量，至少为1）。',
}

fuhaiw:addEffect('active', {
  anim_type = "drawcard",
  prompt = "#js__fuhaiw",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(fuhaiw.name, Player.HistoryPhase) == 0 and #Fk:currentRoom().alive_players > 1
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local targets = room:getOtherPlayers(player)
    room:doIndicate(player.id, table.map(targets, Util.IdMapper))
    targets = table.filter(targets, function (p)
      return not p:isKongcheng()
    end)
    if #targets == 0 then
      player:drawCards(1, fuhaiw.name)
      return
    end
    local result = room:askToJointCard(targets, {
      num = 1,
      include_equip = false,
      skill_name = fuhaiw.name,
      cancelable = false,
      prompt = "#js__fuhaiw-show:"..player.id,
    })
    if player.dead then return end
    if #targets == 1 then
      player:drawCards(1, fuhaiw.name)
      return
    end
    local numbers = {}
    for _, p in ipairs(targets) do
      table.insert(numbers, Fk:getCardById(result[p.id][1]).number)
      room:showCards(result[p.id], p)
    end
    local n1, n2 = 1, 1
    local tag = ""
    if numbers[2] > numbers[1] then
      tag = "increase"
      n1 = 2
    elseif numbers[2] < numbers[1] then
      tag = "decline"
      n1 = 2
    end
    if tag ~= "" then
      for i = 3, #targets, 1 do
        local yes = (tag == "increase" and numbers[i] > numbers[i - 1]) or numbers[i] < numbers[i - 1]
        if yes then
          n1 = n1 + 1
        else
          break
        end
      end
    end
    if numbers[2] > numbers[1] then
      tag = "increase"
      n2 = 2
    elseif numbers[2] < numbers[1] then
      tag = "decline"
      n2 = 2
    else
      tag = ""
    end
    if tag ~= "" then
      for i = #targets - 2, 1, -1 do
        local yes = (tag == "increase" and numbers[i] > numbers[i + 1]) or numbers[i] < numbers[i + 1]
        if yes then
          n2 = n2 + 1
        else
          break
        end
      end
    end
    local choice = room:askToChoice(player, {
      choices = {"js__fuhaiw1:::"..n1, "js__fuhaiw2:::"..n2},
      skill_name = fuhaiw.name,
    })
    local n = choice[11] == "1" and n1 or n2
    player:drawCards(n, fuhaiw.name)
  end,
})

return fuhaiw
