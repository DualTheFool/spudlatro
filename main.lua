DSPUD = SMODS.current_mod
DSPUD.GAME = DSPUD.GAME or {}

local base_seal_money = 1
local last_scored_hand = {}

-- adds card to queue
function add_card_queue(data)
    print("[DSPUD] Got card message")
    if not DSPUD.GAME.card_queue then 
        DSPUD.GAME.card_queue = {}
    end
    DSPUD.GAME.card_queue[#DSPUD.GAME.card_queue + 1] = data.info
    print("[DSPUD] Adding " .. DSPUD.GAME.card_queue[#DSPUD.GAME.card_queue] .. "to card queue")
end

function add_famine_charge(data)
    print("[DSPUD] Got famine message")
    if not DSPUD.GAME.famine then 
        DSPUD.GAME.famine = 0
    end
    DSPUD.GAME.famine = DSPUD.GAME.famine + 1
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

SMODS.Atlas {
    key = "pprint",
    path = "grandmajoker.png",
    px = 71,
    py = 95,
}

SMODS.Atlas {
    key = "potatohead",
    path = "potatohead.png",
    px = 71,
    py = 95,
}

SMODS.current_mod.reset_game_globals = function(run_start)  
    if run_start then  
        -- Reset seal config to base value at start of new run  
        G.P_SEALS[DSPUD.id .. '_potato_seal'].config.money = base_seal_money  
        last_scored_hand = {}
    end  
end

function add_seal_money(amount)
    G.P_SEALS[DSPUD.id .. '_potato_seal'].config.money = G.P_SEALS[DSPUD.id .. '_potato_seal'].config.money + amount
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
            MP.ACTIONS.modded(DSPUD.id, "add-card", { 
                type = "card", 
                info = MP.UTILS.card_to_string(card)
            })
            return {
                remove = true
            }
        
    elseif context.setting_ability and context.other_card  == card and not (context.unchanged) then
            MP.ACTIONS.modded(DSPUD.id, "add-card", { 
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
            if DSPUD.GAME.card_queue and DSPUD.GAME.card_queue[1] then
                for value in getValues(DSPUD.GAME.card_queue) 
                do 
                print("[DSPUD] Making " .. value .. ".")
                makeCard(value)
                end
            DSPUD.GAME.card_queue = {}
            end
            if DSPUD.GAME.famine and DSPUD.GAME.famine > 0 then
                local famine_amount = 0
                while DSPUD.GAME.famine > 0 do
                    add_seal_money(-1)
                    famine_amount = famine_amount + 1
                    DSPUD.GAME.famine = DSPUD.GAME.famine - 1
                    card_eval_status_text(G.deck, 'extra', nil, nil, nil, {
                        message = "Famined!",
                        pitch = 0.5,
                        volume = 0.8,
                        delay = 1.0
                    })
                end
                DSPUD.GAME.famine = 0
            end
            return {}
    end
    if context.end_of_round and context.main_eval  then
            if MP.is_pvp_boss() then
                if not DSPUD.GAME.card_queue or not DSPUD.GAME.card_queue[1] then
                    return {}
                end
            for value in getValues(DSPUD.GAME.card_queue) 
                do 
                print("[DSPUD] Making " .. value .. ".")
                makeCard(value)
            end
            DSPUD.GAME.card_queue = {}
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
if #SMODS.find_card('j_' .. DSPUD.id .. '_couch_potato') > 0 then
    print("[DSPUD] Bravo Six going dark")
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
            "Start with 4 additional{C:attention}Sevens{} ",
            "and a {C:dark_editionNegative{} {C:attention}Mr. Potato Head{}",
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
                G.P_SEALS[DSPUD.id .. '_potato_seal'].config.money = base_seal_money + 1
                SMODS.add_card({
                    key = 'j_' .. DSPUD.id .. '_potatohead', -- Change to any Joker key
                    edition = 'e_negative',
                    area = G.jokers
                })
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
            '{C:attention}-1{} hand size if your deck contains',
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
            if pcard.config and pcard.seal and pcard.seal == DSPUD.id .. '_potato_seal' then
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
            "When sold, all {X:purple,C:white}Nemesis{} {C:attention}potato seals{} give {C:money}-$1{} when played,",
            "Updates at {C:attention}PvP Blind{}"
        }
    },
    blueprint_compat = true,
    perishable_compat = true,
    eternal_compat = false,
    rarity = 1,
    cost = 8,
    remove_from_deck = function(self, card, from_debuff)
        MP.ACTIONS.modded(DSPUD.id, "famine", {})
    end
}

SMODS.Joker {
    key = 'potatoprint',
    name = 'Potatoprint',
    atlas = 'pprint',
    config = { active = false },
    loc_txt = {
        name = "Grandma's Mashed Potato Recipe",
        text = {
            "Retriggers rightmost {C:attention}Joker{} if a {C:attention}potato seal{} was scored last hand."
        }
    },
    blueprint_compat = true,
    perishable_compat = true,
    eternal_compat = true,
    rarity = 2,
    cost = 10,
    calculate = function (self, card, context)
        if self.config.active == true then
            if #G.jokers.cards > 0 then 
                local other_joker = G.jokers.cards[(#G.jokers.cards)]
                if other_joker and other_joker ~= card then
                     		        local other_joker_ret = SMODS.blueprint_effect(card, other_joker, context)
 		        if other_joker_ret then
 			        return other_joker_ret
 		        end
                end
            end
        end
        if context.after and not context.repetition then  
            last_scored_hand = {}
            self.config.active = false
            for _, pcard in ipairs(context.scoring_hand or {}) do
                if pcard.config and pcard.seal and pcard.seal == DSPUD.id .. '_potato_seal' then
                    self.config.active  = true
                end
            end
        end

    end
    
}

SMODS.Joker {
    key = 'potatohead',
    name = 'potatohead',
    atlas = 'potatohead',
    loc_txt = {
        name = "Mr. Potato Head",
        text = {
            "Retrigger each played {C:attention}7{}",
            "Add a {C:attention}potato seal{} to each {C:attention}7{} played."
        }
    },
    config = { extra = { repetitions = 1 } },
    blueprint_compat = true,
    perishable_compat = true,
    eternal_compat = true,
    rarity = 1,
    cost = 6,
    calculate = function (self, card, context)
		if context.cardarea == G.play and context.repetition and not context.repetition_only then
			-- context.other_card is something that's used when either context.individual or context.repetition is true
			-- It is each card 1 by 1, but in other cases, you'd need to iterate over the scoring hand to check which cards are there.
			if context.other_card.base.value == '7' then
                context.other_card:set_seal(DSPUD.id .. '_potato_seal', true)
				return {
					repetitions = card.ability.extra.repetitions,
				}
			end
        end

    end
}

--[[
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
