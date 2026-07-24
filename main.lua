DSHIT = SMODS.current_mod
DSHIT.GAME = DSHIT.GAME or {}

local base_seal_money = 1

-- adds card to queue
function add_card_queue(data)
    print("[Dshit] Got card message")
    if not DSHIT.GAME.card_queue then 
        DSHIT.GAME.card_queue = {}
    end
    DSHIT.GAME.card_queue[#DSHIT.GAME.card_queue + 1] = data.info
    print("[Dshit] Adding " .. DSHIT.GAME.card_queue[#DSHIT.GAME.card_queue] .. "to card queue")
end

function add_famine_charge(data)
    print("[Dshit] Got famine message")
    if not DSHIT.GAME.famine then 
        DSHIT.GAME.famine = 0
    end
    DSHIT.GAME.famine = DSHIT.GAME.famine + 1
end

MP.register_mod_action("add-card", add_card_queue)
MP.register_mod_action("famine", add_famine_charge)

SMODS.Atlas {
    key = "modicon",
    path = "modicon.png",
    px = 34,
    py = 34
}

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

SMODS.Atlas {
    key = "couch_potato",
    path = "couchjoker.png",
    px = 71,
    py = 95,
}

SMODS.Atlas {
    key = "famine",
    path = "faminejoker.png",
    px = 71,
    py = 95,
}

SMODS.current_mod.reset_game_globals = function(run_start)  
    if run_start then  
        -- Reset seal config to base value at start of new run  
        G.P_SEALS[DSHIT.id .. '_potato_seal'].config.money = base_seal_money  
    end  
end

function add_seal_money(amount)
    G.P_SEALS[DSHIT.id .. '_potato_seal'].config.money = G.P_SEALS[DSHIT.id .. '_potato_seal'].config.money + amount
end

SMODS.Seal {
    name = 'Potato Seal',
    key = 'potato_seal',
	config = { money = base_seal_money },
    loc_txt = {
        -- Badge name (displayed on card description when seal is applied)
        label = 'Potato Seal',
        -- Tooltip description
        name = 'Potato Seal',
        text = {
            '{C:money}$#1#{} when played',
            'Sent to your {X:purple,C:white}Nemesis{} when played or enhanced',
            'Cards are destroyed when sent, and added to decks before and after {C:attention}PvP Blinds'
        }
    },
    badge_colour = HEX('C77124'),
    loc_vars = function(self, info_queue, card)
        return { vars = { self.config.money } }
    end,
    atlas = 'potato_atlas',
    pos = {x = 0, y = 0},
    sound = { sound = 'gold_seal', per = 1.2, vol = 0.4 },
    get_p_dollars = function(self, card)
        return card.ability.seal.money * 1
    end,

    calculate = function (self, card, context)
    -- Deletes card if enhanced or played.
    -- Sends the card to opp to be added at pvp.
    if context.destroy_card == card and context.cardarea == G.play then 
            MP.ACTIONS.modded(DSHIT.id, "add-card", { 
                type = "card", 
                info = MP.UTILS.card_to_string(card)
            })
            return {
                remove = true
            }
        
    elseif context.setting_ability and context.other_card  == card and not (context.unchanged) then
            MP.ACTIONS.modded(DSHIT.id, "add-card", { 
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
            if DSHIT.GAME.card_queue and DSHIT.GAME.card_queue[1] then
                for value in getValues(DSHIT.GAME.card_queue) 
                do 
                print("[Dshit] Making " .. value .. ".")
                makeCard(value)
                end
            DSHIT.GAME.card_queue = {}
            end
            if DSHIT.GAME.famine and DSHIT.GAME.famine > 0 then
                local famine_amount = 0
                while DSHIT.GAME.famine > 0 do
                    add_seal_money(-1)
                    famine_amount = famine_amount + 1
                    DSHIT.GAME.famine = DSHIT.GAME.famine - 1
                    card_eval_status_text(G.deck, 'extra', nil, nil, nil, {
                        message = "Famined!",
                        pitch = 0.5,
                        volume = 0.8,
                        delay = 1.0
                    })
                end
                DSHIT.GAME.famine = 0
            end
            return {}
    end
    if context.end_of_round and context.main_eval  then
            if MP.is_pvp_boss() then
                if not DSHIT.GAME.card_queue or not DSHIT.GAME.card_queue[1] then
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
            SMODS.calculate_context({
                playing_card_added = true,
                cards = { _card }
            })
        end
end

-- Iterator 
function getValues(array)
  local i = 0
  return function() i = i + 1; return array[i] end
end

function getEditionFromString(str) 
if #SMODS.find_card('j_' .. DSHIT.id .. '_couch_potato') > 0 then
    print("[Dshit] Bravo Six going dark")
    return { negative = true }
end
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
            "Start with 8 {C:attention}Sevens{} ",
            "with {C:attention}Potato Seals{}",
            "Potato Seals earn an additional dollar when played",
        },
    },
    initial_deck = {
        cards = {
            { rank = '7', suit = 'Spades' },
            { rank = '7', suit = 'Hearts' },
            { rank = '7', suit = 'Clubs' },
            { rank = '7', suit = 'Diamonds' },
        }
    },
    apply = function (self, back)
        G.E_MANAGER:add_event(Event({
            func = function ()
                local suits = {'Spades', 'Hearts', 'Clubs', 'Diamonds'}
                for _, suit in ipairs(suits) do
                    local card = SMODS.create_card({
                        set = 'Base',
                        area = G.deck,
                        suit = suit,
                        rank = '7'
                    })
                    table.insert(G.playing_cards, card)
                    G.deck:emplace(card)
                end
                G.P_SEALS[DSHIT.id .. '_potato_seal'].config.money = base_seal_money + 1
                for _, card in ipairs(G.playing_cards) do
                    if card.base.value == '7' then
                        card:set_seal(DSHIT.id .. '_potato_seal', true)
                    end
                end
                return true
            end
        }))
    end

}

SMODS.Joker {
    key = 'couch_potato',
    name = 'Couch Potato',
    atlas = 'couch_potato',
    loc_txt = {
        name = 'Couch Potato',
        text = {
            'If a playing card is {C:attention}sent{} to you, ',
            'set its edition to {C:dark_edition}Negative{}',
            '{C:attention}-1{} Hand Size if your deck contains',
            'a {C:attention}Potato Seal{}'
        },
    },
    config = { extra = { h_size = 0 } },
    blueprint_compat = false,
    perishable_compat = true,
    eternal_compat = true,
    rarity = 3,
    cost = 10,

    calculate = function(self, card, context)
        -- Hook into all drawing/card-state change contexts
        if context.first_hand_drawn or context.discard or context.after or context.open_booster then
            self:update_dynamic_hand_size(card)
        end
    end,

    -- Remove whatever bonus was granted when sold/destroyed
    remove_from_deck = function(self, card, from_debuff)
        if card.ability.extra.h_size ~= 0 then
            G.hand:change_size(card.ability.extra.h_size)
            card.ability.extra.h_size = 0
        end
    end,

    update_dynamic_hand_size = function(self, card)
        if G.playing_cards then
        for _, pcard in ipairs(G.playing_cards) do
            if pcard.config and pcard.seal and pcard.seal == DSHIT.id .. '_potato_seal' then
                if card.ability.extra.h_size == 0 then
                    G.hand:change_size(-1)
                    card.ability.extra.h_size = -1
                end
                return true
            end
        end
        if card.ability.extra.h_size == -1 then
            G.hand:change_size(1)
            card.ability.extra.h_size = 0
        end
        return true
    end
    end
}
--[[
SMODS.Joker {
    key = 'snack_ticket',
    name = 'Meal Ticket',
    loc_text = {
        name = "Meal Ticket",
        text = {
            "Potato Cards give an additional $2 when sent or received"
        }
    },
    blueprint_compat = true,
    perishable_compat = true,
    eternal_compat = true,
    rarity = 2,
    cost = 6
}
]]--
SMODS.Joker {
    key = 'famine',
    name = 'Famine',
    atlas = 'famine',
    loc_txt = {
        name = "Famine",
        text = {
            "When sold, all nemesis potato seals give -$1 when played.",
            "Updates at PvP Blind."
        }
    },
    blueprint_compat = true,
    perishable_compat = true,
    eternal_compat = false,
    rarity = 1,
    cost = 8,
    remove_from_deck = function(self, card, from_debuff)
        MP.ACTIONS.modded(DSHIT.id, "famine", {})
    end
}
--[[
SMODS.Joker {
    key = 'potatoprint',
    name = 'Potatoprint',
    loc_text = {
        name = "Potatoprint",
        text = {
            "Retriggers rightmost joker if a potato seal was played last hand."
        }
    },
    blueprint_compat = true,
    perishable_compat = true,
    eternal_compat = true,
    rarity = 2,
    cost = 8
}

SMODS.Joker {
    key = 'spuderman',
    name = 'Spuderman',
    loc_txt = {
        name = "Spuderman",
        text = {
            "Played 7s are retriggered an additional 2 times.",
            "Add a potato seal to each 7 played."
        }
    },
    blueprint_compat = false,
    perishable_compat = true,
    eternal_compat = true,
    rarity = 3,
    cost = 6
}

SMODS.Joker {
    key = 'hash',
    name = 'Hash Browns',
    loc_text = {
        name = "Hash Browns",
        text = {
            "This joker gains +20 Chips per Potato Seal Sent",
            "Consumed after receiving 10 Potato Seals."
        }
    },
    blueprint_compat = true,
    perishable_compat = true,
    eternal_compat = false,
    rarity = 1,
    cost = 6
} ]]--
