DSHIT = SMODS.current_mod
DSHIT.GAME = DSHIT.GAME or {}

-- adds card to queue
function add_card_queue(data)
    print("[Dshit] Got message")
    if not DSHIT.GAME.card_queue then 
        DSHIT.GAME.card_queue = {}
    end
    DSHIT.GAME.card_queue[#DSHIT.GAME.card_queue + 1] = data.info
    print("[Dshit] Adding " .. DSHIT.GAME.card_queue[#DSHIT.GAME.card_queue] .. "to card queue")
end

MP.register_mod_action("syncState", add_card_queue)


SMODS.Atlas {
    key = "potato_atlas",
    path = "potato_seal.png",
    px = 59,
    py = 50
}

SMODS.Atlas {
    key = "spuddeck",
    path = "spuddeck.png",
    px = 71,
    py = 95,
}


SMODS.Seal {
    name = 'Potato Seal',
    key = 'potato_seal',
	config = { money = 2 },
    loc_txt = {
        -- Badge name (displayed on card description when seal is applied)
        label = 'Dualsight\'s Shitshow',
        -- Tooltip description
        name = 'Potato Seal',
        text = {
            '{C:money}-$#1#{} when played',
            'Sent to your {X:purple,C:white}Nemesis{} when played or enhanced',
            'Cards are destroyed when sent, and added to decks before and after {C:attention}PvP Blinds'
        }
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { self.config.money } }
    end,
    atlas = 'potato_atlas',
    pos = {x = 0, y = 0},
    sound = { sound = 'gold_seal', per = 1.2, vol = 0.4 },
    get_p_dollars = function(self, card)
        return card.ability.seal.money * -1
    end,

    calculate = function (self, card, context)
    -- Deletes card if enhanced or played.
    -- Sends the card to opp to be added at pvp.
    if context.destroy_card == card and context.cardarea == G.play then 
            MP.ACTIONS.modded(DSHIT.id, "syncState", { 
                type = "card", 
                info = MP.UTILS.card_to_string(card)
            })
            return {
                remove = true
            }
        
    elseif context.setting_ability and context.other_card  == card and not (context.unchanged) then
            MP.ACTIONS.modded(DSHIT.id, "syncState", { 
                type = "card", 
                info = MP.UTILS.card_to_string(card)
            })
            SMODS.destroy_cards({card})
            return {}
        end

    end
  
}


SMODS.current_mod.calculate = function(self, context)
    if context.setting_blind
			and context.blind.key == "bl_mp_nemesis" then 
            if not DSHIT.GAME.card_queue or DSHIT.GAME.card_queue[0] then
                return {}
            end
            for value in getValues(DSHIT.GAME.card_queue) 
                do 
                print("[Dshit] Making " .. value .. ".")
                makeCard(value)
                end
            DSHIT.GAME.card_queue = {}
            return {}
    end
    if context.end_of_round and context.main_eval  then
            if MP.is_pvp_boss() then
                if not DSHIT.GAME.card_queue or DSHIT.GAME.card_queue[0] then
                    return {}
                end
            for value in getValues(DSHIT.GAME.card_queue) 
                do 
                print("[Dshit] Making " .. value .. ".")
                makeCard(value)
            end
            DSHIT.GAME.card_queue = {}
            return {}
        end
    end
end

    


-- This should add the card to the top of the deck but I'm least confident in this function
-- I used the same format that the MP mod uses to send cards to players at the end of the game, 
-- so I'm using basically the same one to make the card.
function makeCard(str)
		if str == "" then return {} end

		local card_params = MP.UTILS.string_split(str, "-")

		local enhancement = card_params[3]
		local edition = card_params[4]
		local seal = card_params[5]
        local _card = SMODS.create_card({
            set = 'Base',
            area = G.deck,
            rank = card_params[2],
            suit = card_params[1],
            enhancement = enhancement or nil,
            edition = getEditionFromString(edition),
            seal = seal or nil
        })

        if _card then
            _card:add_to_deck()
            G.deck:emplace(_card)
            G.playing_card = G.playing_card + 1
            table.insert(G.playing_cards, _card)
        end
end

-- Iterator 
function getValues(array)
  local i = 0
  return function() i = i + 1; return array[i] end
end

function getEditionFromString(str) 
if str == "none" then 
    return {}
end
return { [str] = true }
end

function getRankFromString(str) 
if str == "T" then 
    return '10'
end
if str == "J" then
    return 'Jack'
end
if str == "Q" then
    return 'Queen'
end
if str == "K" then 
    return 'King'
end
if str == "A" then
    return 'Ace'
end
return str
end


SMODS.Back{
    key = 'spud',
    name = 'sPuD deCK',
    atlas = 'spuddeck',
    pos = {x = 0, y = 0},
    unlocked = true,

    loc_txt = {
        name = "sPud Deck",
        text = {
            "Start with 8 {C:attention}Sevens{} and No {C:attention}Aces{}",
            "Starting Sevens have {C:attention}Potato Seals{} on them",
        },
    },

    apply = function (self, back)
        G.E_MANAGER:add_event(Event({
            func = function ()
                for _, card in ipairs(G.playing_cards) do
                    if card.base.value == 'Ace' then
                        assert(SMODS.change_base(card, nil, '7'))
                    end
                    if card.base.value == '7' then
                        card:set_seal(DSHIT.id .. '_potato_seal', true)
                    end
                end
                return true
            end
        }))
    end
}