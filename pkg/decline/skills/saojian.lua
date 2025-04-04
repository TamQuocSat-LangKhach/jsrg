local saojian = fk.CreateSkill {
  name = "saojian"
}

Fk:loadTranslationTable{
  ['saojian'] = '埽奸',
  ['#saojian'] = '埽奸：你可观看一名其他角色的手牌，令其弃置手牌直到弃到你所选的牌',
  ['reveal'] = '他人可观看',
  ['not_reveal'] = '不可观看',
  ['#saojian-view'] = '埽奸：当前观看的是 %dest 的手牌',
  ['#SaoJianReveal'] = '%from选择',
  ['#saojian-discard'] = '埽奸：请弃置一张手牌，直到你弃置到“埽奸”选择的牌（剩余 %arg 次）',
  [':saojian'] = '出牌阶段限一次，你可以观看一名其他角色的手牌并选择其中一张令除其外的角色观看，然后其重复弃置一张手牌（至多五次），直至其弃置了你选择的牌。然后若其手牌数大于你，你失去1点体力。',
  ['$saojian1'] = '虎豹豺狼、蚊蝇鼠蟑，按律，皆斩。',
  ['$saojian2'] = '蒙鹰犬之任，埽朝廷奸鄙。',
  ['$saojian3'] = '陛下，请假臣一月之期！',
  ['$saojian4'] = '出生，你又藏了什么？',
}

saojian:addEffect('active', {
  name = "saojian",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#saojian",
  mute = true,
  can_use = function(self, player)
    return player:usedSkillTimes(saojian.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select.id ~= player.id and not Fk:currentRoom():getPlayerById(to_select.id):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:notifySkillInvoked(player, saojian.name)
    player:broadcastSkillInvoke(saojian.name, math.random(1, 2))

    local to = room:getPlayerById(effect.tos[1])
    if to:isKongcheng() then
      return
    end

    local ids, choice = U.askforChooseCardsAndChoice(
      player,
      to:getCardIds("h"),
      { "reveal", "not_reveal" },
      saojian.name,
      "#saojian-view::" .. to.id,
      nil,
      1,
      1
    )

    if choice == "reveal" then
      local toViewPlayers = table.filter(room.alive_players, function(p) return p ~= to end)
      if #toViewPlayers > 0 then
        for _, p in ipairs(toViewPlayers) do
          p:doNotify(
            "ShowCard",
            json.encode{
              from = player.id,
              cards = ids,
            }
          )
        end
        room:sendFootnote(ids, {
          type = "#SaoJianReveal",
          from = player.id,
        })
      end
    end

    for i = 1, 5 do
      local idsDiscarded = room:askToDiscard(to, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = saojian.name,
        cancelable = false,
        prompt = "#saojian-discard:::" .. 6 - i,
      })
      if #idsDiscarded > 0 and idsDiscarded[1] == ids[1] then
        break
      end
      if i == 5 then player:broadcastSkillInvoke("saojian", 4) end
    end

    if player:isAlive() and to:getHandcardNum() > player:getHandcardNum() then
      player:broadcastSkillInvoke(saojian.name, 3)
      room:loseHp(player, 1, saojian.name)
    end
  end,
})

return saojian
