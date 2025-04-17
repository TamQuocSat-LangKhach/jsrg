---@class jsUtil : Object
local jsUtil = {}

---印影
---@param room Room
---@param n number
jsUtil.getShade = function (room, n)
  local ids = {}
  for _, id in ipairs(room.void) do
    if n <= 0 then break end
    if Fk:getCardById(id).name == "shade" then
      room:setCardMark(Fk:getCardById(id), MarkEnum.DestructIntoDiscard, 1)
      table.insert(ids, id)
      n = n - 1
    end
  end
  while n > 0 do
    local card = room:printCard("shade", Card.Spade, 1)
    room:setCardMark(card, MarkEnum.DestructIntoDiscard, 1)
    table.insert(ids, card.id)
    n = n - 1
  end
  return ids
end

---蓄谋
---@param player ServerPlayer @ 被蓄谋的玩家
---@param card integer | Card | integer[] | Card[]  @ 用来蓄谋的牌，每次只能蓄谋一张
---@param skill_name? string @ 技能名
---@param proposer? ServerPlayer @ 移动操作者，默认和player相同
---@return nil
jsUtil.premeditate = function(player, card, skill_name, proposer)
  skill_name = skill_name or ""
  proposer = proposer or player
  assert(#Card:getIdList(card) == 1)

  local room = player.room
  room:addSkill("premeditate_rule")

  card = Card:getIdList(card)[1]
  local xumou = Fk:cloneCard("premeditate")
  xumou:addSubcard(card)
  player:addVirtualEquip(xumou)
  room:moveCardTo(xumou, Player.Judge, player, fk.ReasonJustMove, skill_name, nil, false, proposer, nil, {proposer.id, player.id})
end

return jsUtil
