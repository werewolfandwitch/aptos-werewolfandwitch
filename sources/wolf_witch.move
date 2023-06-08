
module nft_war::wolf_witch {
    use std::error;
    use std::bcs;
    use std::signer;
    use std::option::{Self};
    use std::string::{Self, String};
        

    use aptos_framework::guid;
    use std::vector;
    use aptos_framework::account;    
    use aptos_framework::timestamp;
    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::coin;    
    use aptos_std::table::{Self, Table};  
    // use aptos_std::iterable_table::{Self, IterableTable};    for rank
    use aptos_token::token::{Self, TokenId};    
    use aptos_token::property_map::{Self, PropertyMap};
    use aptos_std::type_info;

    use item_gen::item_materials;
    use item_gen::item_equip;
    // use aptos_framework::aptos_coin::AptosCoin;
    

    // custom modules
    use nft_war::utils;
    use nft_war::dungeons;

    const FEE_DENOMINATOR: u64 = 100000; 
    const WAR_COIN_DECIMAL:u64 = 100000000;   
    
    const ENOT_READY_END: u64 = 1;
    const ENOT_PUBLIC: u64 = 2;    
    const ENOT_ENOUGH_NFT: u64 = 3;
    const ENOT_READY_MINT:u64 = 4;
    const EONGOING_GAME:u64 = 5;
    const ESAME_TYPE:u64 = 6;
    const ENOT_IN_BATTLE:u64 = 7;
    const ECANT_FIGHT:u64 = 8;
    const ENOT_WIN_FACTION:u64 = 9;
    const ENOT_AUTHORIZED: u64 = 10;
    const ENO_NOT_EQUAL: u64 = 11;
    const ENO_NOT_ENOUGH_LIMIT: u64 = 12; 
    const ENO_NOT_IN_WHITELIST: u64 = 13;
    const EMINIMUM_REQUIRED: u64 = 14;
    const EALREADY_STAKED: u64 = 15;
    const EMUST_SAME_AMOUNT: u64 = 16;
    const EFIGHTER_HAS_NO_MONEY:u64 = 17;
    const ENO_SUFFICIENT_FUND:u64 = 18;
    const ENOT_ENOUGH_MONEY: u64 = 19;
    const ENOT_AUTHORIZED_CREATOR:u64 = 20;
    
    

    // Game Configs
    const PRICE_FOR_NFT:u64 = 10000000; // 0.1 APT
    const PRESALE_PRICE_FOR_NFT:u64 = 9000000; // 0.09 APT
    const BATTLE_INCENTVE:u64 = 1000000000; // 10 WAR COIN per day. 10 WAR COIN per each NFT or players. battle incentives
    const RATIO_FOR_WIN:u64 = 7; // at least 70% of witches or werewolves should be alive in the war
    const NO_BATTLE_TIME_LIMIT:u64 = 604800; // 7 days, The war can be ended if there is no combat for more than 7 days
    const MINIMUM_BET_WAR_COIN:u64 = 1000000; // 0.01 WAR COIN    
    const LAND_STAKING_TIME:u64 = 2592000; // earned WAR coins equal to my Strength in 30 days
    
    // configs for battle incentive system
    const FULL_INCENTIVE_STAKE_TIME:u64 = 86400; // Ensure that the maximum value of the BATTLE_INCENTVE is accumulated within a day

    // monster regen time
    const MINIMUM_REGEN_TIME_A:u64 = 10800; // 8 time in one day
    const MINIMUM_REGEN_TIME_B:u64 = 10800; // 8 time every one day
    const MINIMUM_REGEN_TIME_C:u64 = 10800; // 8 times every one days. 
    const MINIMUM_REGEN_TIME_D:u64 = 21600; // 4 times every one days. 
    const MINIMUM_REGEN_TIME_E:u64 = 21600; // 4 times every one days. 

    const MINIMUM_ELAPSED_TIME_FOR_BATTLE_COIN:u64 = 60; // at least 1min should be passed for stacking coins

    const BURNABLE_BY_CREATOR: vector<u8> = b"TOKEN_BURNABLE_BY_CREATOR";    
    const BURNABLE_BY_OWNER: vector<u8> = b"TOKEN_BURNABLE_BY_OWNER";
    const TOKEN_PROPERTY_MUTABLE: vector<u8> = b"TOKEN_PROPERTY_MUTATBLE";    
    
    // property for game
    const GAME_STRENGTH: vector<u8> = b"W_TOKEN_GAME_STRENGTH";
    const IS_WOLF: vector<u8> = b"W_TOKEN_IS_WOLF";   
    const IS_HERO: vector<u8> = b"W_TOKEN_IS_HERO"; 
    const IS_EQUIP:vector<u8> = b"W_TOKEN_IS_EQUIP";
    const POTION_TYPE:vector<u8> = b"W_POTION_TYPE";
    // item property
    const ITEM_LEVEL: vector<u8> = b"W_ITEM_LEVEL";
    const ITEM_DEFAULT_STR: vector<u8> = b"W_ITEM_DEFAULT_STRENGTH";
    
    // collection name // TODO change
    const PRE_SEASON_WEREWOLF_AND_WITCH_COLLECTION:vector<u8> =b"WEREWOLF AND WITCH #S05"; // lose faction
    const WEREWOLF_AND_WITCH_COLLECTION:vector<u8> =b"WEREWOLF AND WITCH #S06";
    
    const LAND_COLLECTION_NAME:vector<u8> = b"LAND TOKEN COLLECTION";    
    const POTION_COLLECTION_NAME:vector<u8> = b"POTION TOKEN COLLECTION";
    // HONOR
    const DRAGON_SLAYER_HONOR_NFT:vector<u8> = b"W&W DRAGON SLAYER HONOR";

    const WEREWOLF_JSON_URL:vector<u8> = b"https://werewolfandwitch-mainnet.s3.ap-northeast-2.amazonaws.com/werewolf-json/";
    const WITCH_JSON_URL:vector<u8> = b"https://werewolfandwitch-mainnet.s3.ap-northeast-2.amazonaws.com/witch-json/";
    
    // item names
    const POTION_A: vector<u8> = b"POTION A"; // 6 
    const POTION_B: vector<u8> = b"POTION B"; // 8
    const POTION_C: vector<u8> = b"POTION C"; // 10
    const POTION_D: vector<u8> = b"POTION D"; // Dungeon posion

    const LAND_A: vector<u8> = b"Castle Ruins";
    const LAND_B: vector<u8> = b"Dark Forest";
    const LAND_C: vector<u8> = b"Sacred Grove";
    const LAND_D: vector<u8> = b"Twisted Forest";
    const HERO_A: vector<u8> = b"Blitzgrizz";
    const HERO_B: vector<u8> = b"Grommash";
    const HERO_C: vector<u8> = b"Sylvana";
    const HERO_D: vector<u8> = b"Helen";
    const HERO_E: vector<u8> = b"Selena Shadowmoon";
    const HERO_F: vector<u8> = b"Nyx Nightshade";
    const HERO_G: vector<u8> = b"Blazefang";   

    // item materials
    const MATERIAL_A: vector<u8> = b"Glimmering Crystals";
    const MATERIAL_B: vector<u8> = b"Ethereal Essence";
    const MATERIAL_C: vector<u8> = b"Dragon Scale";
    const MATERIAL_D: vector<u8> = b"Celestial Dust";
    const MATERIAL_E: vector<u8> = b"Essence of the Ancients";
    const MATERIAL_F: vector<u8> = b"Phoenix Feather";
    const MATERIAL_G: vector<u8> = b"Moonstone Ore";
    const MATERIAL_H: vector<u8> = b"Enchanted Wood";
    const MATERIAL_I: vector<u8> = b"Kraken Ink";
    const MATERIAL_J: vector<u8> = b"Elemental Essence";
    
    // This struct stores an NFT collection's relevant information
    struct WarGame has store, key {          
        signer_cap: account::SignerCapability,        
        minimum_elapsed_time:u64,
        wolf: u64, // count for wolves
        witch: u64, // count for witches
        total_prize:u64,
        total_nft_count:u64,
        presale_mint_price:u64,
        presale_mint_start_timestamp:u64,
        public_mint_price:u64,
        public_mint_start_timestamp:u64,        
        is_on_game: bool,
        token_url:String,        
        token_description:String,
        token_royalty_points_numerator:u64,
        last_battle_time: u64     
    }

    struct MonsterRegenTimer has store, key {                                  
        last_killed_time_type_1:u64,
        last_killed_time_type_2:u64,
        last_killed_time_type_3:u64,        
        last_killed_time_type_4:u64,
        last_killed_time_type_5:u64,
    }

    struct MonsterKilledEvent has drop, store {        
        killed_time: u64,
        killer: address,
        monster_type: u64
    }
    
    struct BatteArena has key {
        listings: Table<token::TokenId, ListingFighter>
    }

    struct CollectionId has store, copy, drop {
        creator: address,
        name: String,
    }

    struct LandStake has store, copy, drop {
        start_time: u64,        
        owner:address,
        fighter_token_id:token::TokenId,
    }

    struct LandStaking has key {
        stakings: Table<token::TokenId, LandStake> // land_token_id and land stake information pair.
    }

    struct StakeEvent has drop, store {        
        start_time: u64,        
        owner:address,
        fighter_token_id:token::TokenId,
        land_token_id:token::TokenId,
        
    }

    struct UnStakeEvent has drop, store {        
        end_time: u64,        
        owner:address,
        fighter_token_id:token::TokenId,
        land_token_id:token::TokenId,
    }
    // white list structs
    struct WhiteListKey has copy, drop, store {
        white_address: address,
        collection_id: CollectionId,
    }

    struct WhiteList has key, store {
        whitelist: Table<WhiteListKey, u64>
    }        


    struct WhitelistEvent has drop, store {
        whitelist_key: WhiteListKey,
        limit: u64,
    }
    
    
    struct GameEvents has key {
        token_minting_events: EventHandle<TokenMintingEvent>,
        collection_created_events: EventHandle<CollectionCreatedEvent>,
        create_game_event: EventHandle<CreateGameEvent>,
        list_fighter_events: EventHandle<ListFighterEvent>,
        delist_fighter_events:EventHandle<DeListFighterEvent>,
        game_score_changed_events: EventHandle<GameScoreChangedEvent>, 
        game_result_events: EventHandle<GameResultEvent>, 
        war_state_events: EventHandle<WarStateEvent>,
        whitelist_events: EventHandle<WhitelistEvent>,
        stake_events:EventHandle<StakeEvent>,
        unstake_events:EventHandle<UnStakeEvent>,
        fighter_events:EventHandle<FighterChangeEvent>,        
        item_stock_events: EventHandle<ItemStockChangeEvent>,
        earn_prize_events: EventHandle<EarnPrizeEvent>,
        monster_killed_events: EventHandle<MonsterKilledEvent>,
        dungeon_result_events: EventHandle<GameResultDungeonEvent>,
    }    

    struct CreateGameEvent has drop, store {        
        minimum_elapsed_time: u64,
        game_address:address
    }

    struct FighterChangeEvent has drop, store {
        token_name: String,
        strength: u64,
        owner: address,
    }

    struct EarnPrizeEvent has drop, store {
        burner: address,
        token_name: String,        
    }

    struct GameResultEvent has drop, store {
        win: bool,
        battle_time: u64,
        paid: u64,        
    }

    struct CollectionCreatedEvent has drop, store {        
        collection_id: CollectionId,
    }        

    struct ListingFighter has drop, store {                          
        listing_id: u64,
        owner: address,
        bet:u64        
    }    

    struct WarStateEvent has drop,store {
        in_war: bool
    }
    
    struct GameScoreChangedEvent has drop,store {
        wolf: u64, // count for wolves
        witch: u64, // count for witches
        total_prize: u64,
        total_nft_count:u64,     
    }

    struct GameResultDungeonEvent has drop, store {
        win: bool,
        battle_time: u64,
        earn: u64,
        death: bool        
    }

    struct ItemStockChangeEvent has drop,store {
       item_name: String,
       minus_count:u64
    }

    struct TokenMintingEvent has drop, store {
        token_receiver_address: address,        
        is_wolf: bool,
        public_price: u64
    }

    struct ListFighterEvent has drop, store {
        timestamp: u64,
        token_id:token::TokenId,
        is_wolf: bool,
        is_hero: bool,        
        strength: u64,
        listing_id: u64,
        bet: u64,
        owner: address,
    }

    struct DeListFighterEvent has drop, store {
        timestamp: u64,
        token_id:token::TokenId,        
        owner: address,
    }            

    fun create_collection_data_id(
        creator: address,
        name: String        
    ): CollectionId {        
        CollectionId { creator, name }
    }    

    fun get_resource_account_cap(minter_address : address) : signer acquires WarGame {
        let minter = borrow_global<WarGame>(minter_address);
        account::create_signer_with_capability(&minter.signer_cap)
    }    

    fun get_pm_properties(pm:PropertyMap): (bool,u64,bool) {
        let is_wolf_1 = property_map::read_bool(&pm, &string::utf8(IS_WOLF));        
        let token_id_1_str = property_map::read_u64(&pm, &string::utf8(GAME_STRENGTH));
        let is_hero = property_map::read_bool(&pm, &string::utf8(IS_HERO));
        (is_wolf_1, token_id_1_str, is_hero)
    }

    fun game_score_change_event_emit(game_address:address, is_wolf:bool, receiver_address:address) acquires WarGame, GameEvents {
        let game = borrow_global_mut<WarGame>(game_address);
        if(is_wolf) {             
            game.wolf = game.wolf + 1;
            } else { 
            game.witch = game.witch + 1;
        };        
        game.total_prize = game.total_prize + PRICE_FOR_NFT;
        game.total_nft_count = game.total_nft_count + 1;
        // emit events 
        let game_events = borrow_global_mut<GameEvents>(game_address);                
        event::emit_event(&mut game_events.token_minting_events, TokenMintingEvent { 
            token_receiver_address: receiver_address,
            is_wolf:is_wolf,
            public_price: PRICE_FOR_NFT,
        });
        event::emit_event(&mut game_events.game_score_changed_events, GameScoreChangedEvent { 
            wolf:game.wolf,
            witch:game.witch,
            total_prize: game.total_prize,
            total_nft_count:game.total_nft_count,
        });

    }

    // admin functions

    entry fun admin_deposit_items(sender: &signer, creator:address, collection:String, name:String, property_version:u64, 
        amount: u64) acquires WarGame {     
        // war_coin::init_module(sender);
        let sender_addr = signer::address_of(sender);
        let resource_signer = get_resource_account_cap(sender_addr);                        
        let token_id_1 = token::create_token_id_raw(creator, collection, name, property_version);
        let token = token::withdraw_token(sender, token_id_1, amount);
        token::deposit_token(&resource_signer, token);
    }

    entry fun admin_withdraw_items(sender: &signer, creator:address, collection:String, name:String, property_version:u64, 
        amount: u64) acquires WarGame {     
        // war_coin::init_module(sender);
        let sender_addr = signer::address_of(sender);
        let resource_signer = get_resource_account_cap(sender_addr);
        let token_id_1 = token::create_token_id_raw(creator, collection, name, property_version);                        
        let token = token::withdraw_token(&resource_signer, token_id_1, amount);
        token::deposit_token(sender, token);        
    }

    entry fun admin_withdraw<CoinType>(sender: &signer, amount: u64) acquires WarGame {
        let sender_addr = signer::address_of(sender);
        let resource_signer = get_resource_account_cap(sender_addr);                                
        let coins = coin::withdraw<CoinType>(&resource_signer, amount);                
        coin::deposit(sender_addr, coins);
    }

    fun coin_address<CoinType>(): address {
       let type_info = type_info::type_of<CoinType>();
       type_info::account_address(&type_info)
    }

    entry fun admin_deposit<CoinType>(sender: &signer, amount: u64, total_prize_change: bool) acquires WarGame, GameEvents {
        let sender_addr = signer::address_of(sender);
        let game = borrow_global_mut<WarGame>(sender_addr);        
        if(total_prize_change) {
            game.total_prize = game.total_prize + amount;
            let game_events = borrow_global_mut<GameEvents>(sender_addr);                     
            event::emit_event(&mut game_events.game_score_changed_events, GameScoreChangedEvent { 
                wolf:game.wolf,
                witch:game.witch,
                total_prize: game.total_prize,
                total_nft_count:game.total_nft_count,
            });
        };                                 
        let resource_signer = get_resource_account_cap(sender_addr);                        
        let coins = coin::withdraw<CoinType>(sender, amount);        
        coin::deposit(signer::address_of(&resource_signer), coins);        
    }       

     // admin functions
    entry fun admin_withdraw_war_coin<WarCoinType>(sender: &signer, amount: u64) acquires WarGame {
        let sender_addr = signer::address_of(sender);
        let resource_signer = get_resource_account_cap(sender_addr);                                
        let coins = coin::withdraw<WarCoinType>(&resource_signer, amount);                
        coin::deposit(sender_addr, coins);
    }

    entry fun admin_deposit_war_coin<WarCoinType>(sender: &signer, amount: u64,        
        ) acquires WarGame {                
        let sender_addr = signer::address_of(sender);
        let resource_signer = get_resource_account_cap(sender_addr);                        
        let coins = coin::withdraw<WarCoinType>(sender, amount);        
        coin::deposit(signer::address_of(&resource_signer), coins);   
    }

    entry fun register_war_coin_type<WarCoinType>(sender: &signer) acquires WarGame {     
        let sender_addr = signer::address_of(sender);     
        let resource_signer = get_resource_account_cap(sender_addr);                        
        if(!coin::is_account_registered<WarCoinType>(signer::address_of(&resource_signer))){
            coin::register<WarCoinType>(&resource_signer);
        };
    }

    entry fun register_war_coin_type_user<WarCoinType>(sender: &signer) {
        if(!coin::is_account_registered<WarCoinType>(signer::address_of(sender))){
            coin::register<WarCoinType>(sender);
        };
    }     
    
    entry fun init_game<CoinType>(sender: &signer,
        minimum_elapsed_time:u64, token_url: String,
        token_description:String, royalty_points_numerator:u64, presale_mint_start_timestamp:u64, public_mint_start_timestamp:u64,
        init_wolf:u64,init_witch:u64,init_total_prize:u64, init_total_nft_count:u64,
        ) acquires GameEvents {
        let sender_addr = signer::address_of(sender);                
        let (resource_signer, signer_cap) = account::create_resource_account(sender, x"01");    
        token::initialize_token_store(&resource_signer);                
        let time_to_end = timestamp::now_seconds() + minimum_elapsed_time;

        if(!exists<WarGame>(sender_addr)){            
            move_to(sender, WarGame {                
                signer_cap,
                is_on_game: false,
                wolf: init_wolf,
                witch: init_witch,
                total_prize: init_total_prize,
                total_nft_count: init_total_nft_count,
                presale_mint_price: PRESALE_PRICE_FOR_NFT,
                presale_mint_start_timestamp,
                public_mint_price: PRICE_FOR_NFT,
                public_mint_start_timestamp,
                minimum_elapsed_time: time_to_end,                                
                token_url, 
                token_description,
                token_royalty_points_numerator:royalty_points_numerator,
                last_battle_time: timestamp::now_seconds() + MINIMUM_ELAPSED_TIME_FOR_BATTLE_COIN,                
            });
        };
                

        if(!exists<GameEvents>(sender_addr)){
            move_to(sender, GameEvents {
                token_minting_events: account::new_event_handle<TokenMintingEvent>(sender),
                collection_created_events: account::new_event_handle<CollectionCreatedEvent>(sender),
                create_game_event: account::new_event_handle<CreateGameEvent>(sender),
                list_fighter_events: account::new_event_handle<ListFighterEvent>(sender),
                delist_fighter_events: account::new_event_handle<DeListFighterEvent>(sender),
                game_score_changed_events: account::new_event_handle<GameScoreChangedEvent>(sender), 
                game_result_events: account::new_event_handle<GameResultEvent>(sender),                
                war_state_events: account::new_event_handle<WarStateEvent>(sender),
                whitelist_events: account::new_event_handle<WhitelistEvent>(sender),
                stake_events: account::new_event_handle<StakeEvent>(sender),
                unstake_events: account::new_event_handle<UnStakeEvent>(sender),
                fighter_events: account::new_event_handle<FighterChangeEvent>(sender),
                item_stock_events: account::new_event_handle<ItemStockChangeEvent>(sender),
                earn_prize_events: account::new_event_handle<EarnPrizeEvent>(sender),
                monster_killed_events: account::new_event_handle<MonsterKilledEvent>(sender),
                dungeon_result_events: account::new_event_handle<GameResultDungeonEvent>(sender),
            });
        };        
        
        if(!exists<WhiteList>(sender_addr)){
            move_to(sender, WhiteList{
                whitelist: table::new()
            });
        };

        if(!exists<BatteArena>(sender_addr)){
            move_to(sender, BatteArena{
                listings: table::new()
            });
        };

        if(!exists<LandStaking>(sender_addr)){
            move_to(sender, LandStaking{
                stakings: table::new()
            });
        };
        
        if(!exists<MonsterRegenTimer>(sender_addr)){
            move_to(sender, MonsterRegenTimer{
                last_killed_time_type_1:timestamp::now_seconds() - MINIMUM_REGEN_TIME_A,
                last_killed_time_type_2:timestamp::now_seconds() - MINIMUM_REGEN_TIME_B,
                last_killed_time_type_3:timestamp::now_seconds() - MINIMUM_REGEN_TIME_C,                
                last_killed_time_type_4:timestamp::now_seconds() - MINIMUM_REGEN_TIME_D,                
                last_killed_time_type_5:timestamp::now_seconds() - MINIMUM_REGEN_TIME_E,                
            });
        };        
            
        if(!coin::is_account_registered<CoinType>(signer::address_of(&resource_signer))){
            coin::register<CoinType>(&resource_signer);
        };        
        
        let game_events = borrow_global_mut<GameEvents>(sender_addr);                     
        event::emit_event(&mut game_events.game_score_changed_events, GameScoreChangedEvent { 
            wolf:init_wolf,
            witch:init_witch,
            total_prize: init_total_prize,
            total_nft_count:init_total_nft_count,
        }); 
        event::emit_event(&mut game_events.create_game_event, CreateGameEvent { 
            minimum_elapsed_time: time_to_end,
            game_address:sender_addr            
        });        
    }        

    // create a collection minter for game 
    entry fun create_game (
        sender: &signer,
            _game_address:address, description: String, 
            collection_uri: String, maximum_supply: u64, mutate_setting: vector<bool>,
            token_url: String, royalty_points_numerator:u64       
        ) acquires WarGame, GameEvents {
        let sender_addr = signer::address_of(sender);                                        
        let resource_signer = get_resource_account_cap(sender_addr);        
        // let resource_account_address = signer::address_of(&resource_signer);
        token::create_collection(&resource_signer, string::utf8(WEREWOLF_AND_WITCH_COLLECTION), description, collection_uri, maximum_supply, mutate_setting);

        let game = borrow_global_mut<WarGame>(sender_addr);
        game.is_on_game = true;
        game.token_url = token_url;
        game.token_description = description;
        game.token_royalty_points_numerator = royalty_points_numerator;

        // emit events 
        let game_events = borrow_global_mut<GameEvents>(sender_addr);        
        event::emit_event(&mut game_events.war_state_events, WarStateEvent { in_war: true });        
    }

    // register for battle
    entry fun listing_battle<CoinType>( 
        owner: &signer, game_address:address, creator:address, collection: String, name: String, property_version: u64,
        ) acquires WarGame, GameEvents, BatteArena {      
        let coin_address = coin_address<CoinType>();
        assert!(coin_address == @aptos_coin, error::permission_denied(ENOT_AUTHORIZED));
        let game = borrow_global_mut<WarGame>(game_address);
        assert!(game.is_on_game, error::permission_denied(EONGOING_GAME));
        let resource_signer = get_resource_account_cap(game_address);
        let owner_addr = signer::address_of(owner);        
        // prevant using pre-season token        
        let pre_season:vector<u8> = PRE_SEASON_WEREWOLF_AND_WITCH_COLLECTION;        
        let new_token_id = token::create_token_id_raw(creator, collection, name, property_version);
        if (token::check_tokendata_exists(creator, string::utf8(pre_season), name)) {
          new_token_id = transform_native<CoinType>(owner, game_address, creator, name, property_version);
        };               
        
        let token_id = new_token_id;
        let (creator ,_,_,_) = token::get_token_id_fields(&token_id);
        assert!(creator == @season_now_creator, error::permission_denied(ENOT_AUTHORIZED_CREATOR));                
        let guid = account::create_guid(&resource_signer);
        let listing_id = guid::creation_num(&guid);        
        
        let pm = token::get_property_map(signer::address_of(owner), token_id);                
        let is_wolf = property_map::read_bool(&pm, &string::utf8(IS_WOLF));
        let token_id_str = property_map::read_u64(&pm, &string::utf8(GAME_STRENGTH));
        let is_hero = property_map::read_bool(&pm, &string::utf8(IS_HERO));

        let token = token::withdraw_token(owner, token_id, 1);
        token::deposit_token(&resource_signer, token);        

        let battle_field = borrow_global_mut<BatteArena>(game_address);
                                        
        table::add(&mut battle_field.listings, token_id, ListingFighter {
            listing_id: listing_id,
            owner: owner_addr,
            bet:0
        });
                
        let game_events = borrow_global_mut<GameEvents>(game_address);       
        
        event::emit_event(&mut game_events.list_fighter_events, ListFighterEvent {            
            owner: owner_addr,
            token_id: token_id,
            is_wolf: is_wolf,
            is_hero: is_hero,
            strength: token_id_str,
            listing_id: listing_id,
            bet:0,
            timestamp: timestamp::now_microseconds(),
        });
        
    }

    entry fun delisting_battle <CoinType> (
        sender: &signer,
        game_address:address,
        creator: address, collection:String, name: String, property_version: u64        
        ) acquires WarGame, GameEvents, BatteArena{

        let sender_addr = signer::address_of(sender);       
        let resource_signer = get_resource_account_cap(game_address);        
        assert!(creator == @season_now_creator, error::permission_denied(ENOT_AUTHORIZED_CREATOR));                                
        let token_id = token::create_token_id_raw(creator, collection, name, property_version);        
        let battle_field = borrow_global_mut<BatteArena>(game_address);
        let fighter = table::borrow(&battle_field.listings, token_id);
        assert!(fighter.owner == sender_addr, error::permission_denied(ENOT_AUTHORIZED));            
        let token = token::withdraw_token(&resource_signer, token_id, 1);
        token::deposit_token(sender, token);
        table::remove(&mut battle_field.listings, token_id);    
        let game_events = borrow_global_mut<GameEvents>(game_address);                   
        event::emit_event(&mut game_events.delist_fighter_events, DeListFighterEvent {            
            owner: sender_addr,            
            token_id: token_id,
            timestamp: timestamp::now_microseconds(),            
        });                                
    }

    entry fun battle<CoinType, WarCoinType>(holder: &signer, 
        game_address:address,                 
        collection_1:String, creator_1:address, name_1: String, property_version_1: u64, // me 
        collection_2:String, creator_2:address, name_2: String, property_version_2: u64, // enemy               
        ) acquires WarGame, BatteArena, GameEvents {
        let coin_address = coin_address<WarCoinType>();
        assert!(coin_address == @war_coin, error::permission_denied(ENOT_AUTHORIZED));
        let coin_address2 = coin_address<CoinType>();
        assert!(coin_address2 == @aptos_coin, error::permission_denied(ENOT_AUTHORIZED));
        if(!coin::is_account_registered<WarCoinType>(signer::address_of(holder))){
            coin::register<WarCoinType>(holder);
        };
        let resource_signer = get_resource_account_cap(game_address);
        let resource_account_address = signer::address_of(&resource_signer);
        let pre_season:vector<u8> = PRE_SEASON_WEREWOLF_AND_WITCH_COLLECTION;
        // first token        
        let new_token_id_1 = token::create_token_id_raw(creator_1, collection_1, name_1, property_version_1);        
        if (token::check_tokendata_exists(creator_1, string::utf8(pre_season), name_1)) {
          new_token_id_1 = transform_native<CoinType>(holder, game_address, creator_1, name_1, property_version_1);
        };
        //second token = target
        let new_token_id_2 = token::create_token_id_raw(creator_2, collection_2, name_2, property_version_2);        
        if (token::check_tokendata_exists(creator_2, string::utf8(pre_season), name_2)) {
          new_token_id_2 = transform_native<CoinType>(holder, game_address, creator_2, name_2, property_version_2);
        };
        let token_id_1 = new_token_id_1;
        let token_id_2 = new_token_id_2;
        let (creator_1,_,name_1,_) = token::get_token_id_fields(&token_id_1);
        let (creator_2,_,name_2,_) = token::get_token_id_fields(&token_id_2);
        
        assert!(creator_1 == @season_now_creator, error::permission_denied(ENOT_AUTHORIZED_CREATOR));
        assert!(creator_2 == @season_now_creator, error::permission_denied(ENOT_AUTHORIZED_CREATOR));

        let battle_field = borrow_global_mut<BatteArena>(game_address);            
        
        assert!(table::contains(&mut battle_field.listings, token_id_2), error::permission_denied(ENOT_IN_BATTLE));
        // check type of nft        
        let pm = token::get_property_map(signer::address_of(holder), token_id_1);                
        let is_wolf_1 = property_map::read_bool(&pm, &string::utf8(IS_WOLF));

        let pm2 = token::get_property_map(signer::address_of(&resource_signer), token_id_2);                
        let is_wolf_2 = property_map::read_bool(&pm2, &string::utf8(IS_WOLF));
        assert!(is_wolf_1 != is_wolf_2, error::permission_denied(ESAME_TYPE));

        // get strength from NFT
        
        let token_id_1_str = property_map::read_u64(&pm, &string::utf8(GAME_STRENGTH));
        let token_id_2_str = property_map::read_u64(&pm2, &string::utf8(GAME_STRENGTH));
        let guid = account::create_guid(&resource_signer);
        let nonce = guid::creation_num(&guid);
        let random = utils::random_with_nonce(resource_account_address, 100, nonce) + 1; // 1~100
        let diff = if(token_id_1_str > token_id_2_str) { token_id_1_str - token_id_2_str } else { token_id_2_str - token_id_1_str }; 
        // can't fight if the enemy is too strong.
        assert!(diff < 10, error::permission_denied(ECANT_FIGHT));
        let strong_one = if(token_id_1_str > token_id_2_str) { name_1 } else { name_2 }; 
        let fighter = table::borrow(&battle_field.listings, token_id_2);
        
        // incentive for battle. coins will be staked by elapsed time.
        let game = borrow_global_mut<WarGame>(game_address);          
        assert!(game.is_on_game, error::permission_denied(EONGOING_GAME));
        let now_second = timestamp::now_seconds();
        let last_battle_time = game.last_battle_time;
        let price_for_incentive = BATTLE_INCENTVE / FULL_INCENTIVE_STAKE_TIME; 
        let send_amount = (now_second - last_battle_time) * price_for_incentive;
        if(send_amount > BATTLE_INCENTVE * 2 ) {
            send_amount = BATTLE_INCENTVE * 2; // can't bigger than twice of NFT price .
        };        
        let coins = coin::withdraw<WarCoinType>(&resource_signer, send_amount);                
        let fight_fee = coin::extract(&mut coins, send_amount / 2);
        coin::deposit(fighter.owner, fight_fee);
        coin::deposit(signer::address_of(holder), coins);
        game.last_battle_time = now_second;
        
        let game_events = borrow_global_mut<GameEvents>(game_address);            
        let win_rate = 51 + diff; 
        let lose_rate = 102 - win_rate; 
        if(name_1 == strong_one) {
            if(random < win_rate) {
                // let battle_field = borrow_global_mut<BatteArena>(game_address);            
                let token = token::withdraw_token(&resource_signer, token_id_2, 1);
                token::deposit_token(holder, token);
                event::emit_event(&mut game_events.delist_fighter_events, DeListFighterEvent {            
                    owner: fighter.owner,                    
                    token_id: token_id_2,
                    timestamp: timestamp::now_microseconds(),            
                });
                table::remove(&mut battle_field.listings, token_id_2);
                event::emit_event(&mut game_events.game_result_events, GameResultEvent {            
                    win: true,
                    battle_time:now_second,
                    paid:0,
                });
                item_material_drop(holder, string::utf8(MATERIAL_J), 10);
            } else {
                let token = token::withdraw_token(holder, token_id_1, 1);                        
                token::direct_deposit_with_opt_in(fighter.owner, token);
                event::emit_event(&mut game_events.game_result_events, GameResultEvent {            
                    win: false,
                    battle_time:now_second,
                    paid:0,
                });
                item_material_drop(holder, string::utf8(MATERIAL_C), 5);
            };
        } else {
            if(random < lose_rate) { 
                // let battle_field = borrow_global_mut<BatteArena>(game_address);            
                let token = token::withdraw_token(&resource_signer, token_id_2, 1);
                token::deposit_token(holder, token);

                event::emit_event(&mut game_events.delist_fighter_events, DeListFighterEvent {            
                    owner: fighter.owner,                    
                    token_id: token_id_2,
                    timestamp: timestamp::now_microseconds(),            
                });
                table::remove(&mut battle_field.listings, token_id_2);
                event::emit_event(&mut game_events.game_result_events, GameResultEvent {            
                    win: true,
                    battle_time:now_second,
                    paid:0,                    
                });
                item_material_drop(holder, string::utf8(MATERIAL_I), 10);
            } else { 
                let token = token::withdraw_token(holder, token_id_1, 1);                        
                token::direct_deposit_with_opt_in(fighter.owner, token);
                event::emit_event(&mut game_events.game_result_events, GameResultEvent {            
                    win: false,
                    battle_time:now_second,
                    paid:0,                    
                });                
            };
        };           
    }
    // drink a potion
    entry fun drink_potion(holder: &signer, 
        game_address:address, 
        creator:address, name_1: String, creator_potion:address, collection_potion:String,
        name_potion:String, property_version_potion:u64,property_version_1: u64 // my nft 
        ) acquires WarGame, GameEvents {
        let war_game = borrow_global_mut<WarGame>(game_address);
        assert!(war_game.is_on_game, error::permission_denied(EONGOING_GAME));
        //      
        assert!(creator == @season_now_creator, error::permission_denied(ENOT_AUTHORIZED_CREATOR));
        let is_authorized = (creator_potion == @item_pre_creator) || (creator_potion == @item_now_creator);
        assert!(is_authorized, error::permission_denied(ENOT_AUTHORIZED_CREATOR));
        let holder_addr = signer::address_of(holder);
        let resource_signer = get_resource_account_cap(game_address);        
        let token_id_1 = token::create_token_id_raw(creator, string::utf8(WEREWOLF_AND_WITCH_COLLECTION), name_1, property_version_1);
        let pm = token::get_property_map(signer::address_of(holder), token_id_1);
        let (is_wolf_1,token_id_1_str,is_hero) = get_pm_properties(pm);        
        
        let token_id_potion = token::create_token_id_raw(creator_potion, collection_potion, name_potion, property_version_potion);        
        
        let potion_pm = token::get_property_map(signer::address_of(holder), token_id_potion);
        let potion_type = property_map::read_u64(&potion_pm, &string::utf8(POTION_TYPE));
        let type_a = potion_type;
        let guid = account::create_guid(&resource_signer);
        let nonce = guid::creation_num(&guid);
        let random = utils::random_with_nonce(holder_addr, type_a,nonce) + 1;
        let new_str = if(!is_hero) { token_id_1_str + random } else { token_id_1_str + (random * 2) };
        token::mutate_one_token(            
            &resource_signer,
            holder_addr,
            token_id_1,            
            vector<String>[string::utf8(GAME_STRENGTH), string::utf8(IS_WOLF)],  // property_keys                
            vector<vector<u8>>[bcs::to_bytes<u64>(&new_str), bcs::to_bytes<bool>(&is_wolf_1)],  // values 
            vector<String>[string::utf8(b"u64"), string::utf8(b"bool")],      // type
        );
        token::burn(holder, creator_potion, collection_potion, name_potion, property_version_potion, 1);                                

        let game_events = borrow_global_mut<GameEvents>(game_address);       
        event::emit_event(&mut game_events.fighter_events, FighterChangeEvent {            
            owner: holder_addr,            
            token_name: name_1,
            strength: new_str,
        });
    }

    // stake a land
    entry fun stake_land(holder: &signer,
        game_address:address, 
        creator:address,      // NFT  
        name_1: String, property_version_1: u64,
        creator_land:address,
        name_land:String, property_version_land:u64,
        ) acquires WarGame, LandStaking, GameEvents {
        
        let holder_addr = signer::address_of(holder);
        let resource_signer = get_resource_account_cap(game_address);        
        assert!(creator == @season_now_creator, error::permission_denied(ENOT_AUTHORIZED_CREATOR));
        let is_authorized = (creator_land == @item_pre_creator) || (creator_land == @item_now_creator);
        assert!(is_authorized, error::permission_denied(ENOT_AUTHORIZED_CREATOR));
                
           
        let token_id_1 = token::create_token_id_raw(creator, string::utf8(WEREWOLF_AND_WITCH_COLLECTION), name_1, property_version_1);
        let token_id_land = token::create_token_id_raw(creator_land, string::utf8(LAND_COLLECTION_NAME), name_land, property_version_land);                        
                
        let now_second = timestamp::now_seconds();
        
        let token_wolfwitch = token::withdraw_token(holder, token_id_1, 1);
        token::deposit_token(&resource_signer, token_wolfwitch);        
        let token_land = token::withdraw_token(holder, token_id_land, 1);
        token::deposit_token(&resource_signer, token_land);        

        let staking = borrow_global_mut<LandStaking>(game_address);

        assert!(!table::contains(&mut staking.stakings, token_id_land), error::permission_denied(EALREADY_STAKED));
        table::add(&mut staking.stakings, token_id_land, LandStake {
            start_time: now_second,            
            owner:holder_addr,
            fighter_token_id:token_id_1,
        });
        let game_events = borrow_global_mut<GameEvents>(game_address);       
        
        event::emit_event(&mut game_events.stake_events, StakeEvent {            
            start_time: now_second,        
            owner: holder_addr,
            fighter_token_id:token_id_1,
            land_token_id:token_id_land,            
        });
    }

    entry fun unstake_land<WarCoinType>(
        sender: &signer,
        game_address:address, 
        creator:address, name_1: String, property_version_1: u64, 
        creator_land:address, name_land:String, property_version_land:u64,        
        ) acquires WarGame,LandStaking, GameEvents {
        if(!coin::is_account_registered<WarCoinType>(signer::address_of(sender))){
            coin::register<WarCoinType>(sender);
        };
        let coin_address = coin_address<WarCoinType>();
        assert!(coin_address == @war_coin, error::permission_denied(ENOT_AUTHORIZED));
        
        let holder_addr = signer::address_of(sender);         
        let resource_signer = get_resource_account_cap(game_address);
        let resource_account_address = signer::address_of(&resource_signer);        
        assert!(creator == @season_now_creator, error::permission_denied(ENOT_AUTHORIZED_CREATOR));
        let is_authorized = (creator_land == @item_pre_creator) || (creator_land == @item_now_creator);
        assert!(is_authorized, error::permission_denied(ENOT_AUTHORIZED_CREATOR));

        let token_id_1 = token::create_token_id_raw(creator, string::utf8(WEREWOLF_AND_WITCH_COLLECTION), name_1, property_version_1);
        let token_id_land = token::create_token_id_raw(creator_land, string::utf8(LAND_COLLECTION_NAME), name_land, property_version_land);
        
        let pm = token::get_property_map(resource_account_address, token_id_1);                                
        let token_id_1_str = property_map::read_u64(&pm, &string::utf8(GAME_STRENGTH));
                
        let now_second = timestamp::now_seconds();        
        let token_fighter = token::withdraw_token(&resource_signer, token_id_1, 1);
        token::deposit_token(sender, token_fighter);
        let token_land = token::withdraw_token(&resource_signer, token_id_land, 1);        
        token::deposit_token(sender, token_land);        
        let staking = borrow_global_mut<LandStaking>(game_address);        
        let stake = table::borrow(&staking.stakings, token_id_land);
        assert!(holder_addr == stake.owner, error::permission_denied(ENOT_AUTHORIZED_CREATOR));
        let start_stake = stake.start_time;
        let elapsed_time = now_second - start_stake;
        if(token_id_1_str > 800) {
            token_id_1_str = 800;
        };        
        let war_token_amount = elapsed_time * token_id_1_str * 36;
        // assert!(war_token_amount > 100000, error::permission_denied(EMINIMUM_REQUIRED));
        let coins = coin::withdraw<WarCoinType>(&resource_signer, war_token_amount);
        coin::deposit(signer::address_of(sender), coins);
        table::remove(&mut staking.stakings, token_id_land);    
        
        let game_events = borrow_global_mut<GameEvents>(game_address);               
        event::emit_event(&mut game_events.unstake_events, UnStakeEvent {            
            end_time: now_second,        
            owner: holder_addr,
            fighter_token_id:token_id_1,
            land_token_id:token_id_land,                        
        });
    }

    // claim_token
    entry fun claim_war_in_land<WarCoinType>(sender: &signer,game_address:address, 
            creator_land:address, name_land:String, property_version_land:u64,
            creator:address, name_1: String, property_version_1: u64,            
        ) acquires WarGame, LandStaking, GameEvents {
        if(!coin::is_account_registered<WarCoinType>(signer::address_of(sender))){
            coin::register<WarCoinType>(sender);
        };        
        let coin_address = coin_address<WarCoinType>();
        assert!(coin_address == @war_coin, error::permission_denied(ENOT_AUTHORIZED));

        let holder_addr = signer::address_of(sender);        
        
        assert!(creator == @season_now_creator, error::permission_denied(ENOT_AUTHORIZED_CREATOR));
        let is_authorized = (creator_land == @item_pre_creator) || (creator_land == @item_now_creator);
        assert!(is_authorized, error::permission_denied(ENOT_AUTHORIZED_CREATOR));
        
        let staking = borrow_global_mut<LandStaking>(game_address);
        let resource_signer = get_resource_account_cap(game_address);
        let resource_account_address = signer::address_of(&resource_signer);

        let token_id_1 = token::create_token_id_raw(creator, string::utf8(WEREWOLF_AND_WITCH_COLLECTION), name_1, property_version_1);
        let token_id_land = token::create_token_id_raw(creator_land, string::utf8(LAND_COLLECTION_NAME), name_land, property_version_land);
        let pm = token::get_property_map(resource_account_address, token_id_1);                                
        let token_id_1_str = property_map::read_u64(&pm, &string::utf8(GAME_STRENGTH));
        let now_second = timestamp::now_seconds();        
            
        let stake = table::borrow(&staking.stakings, token_id_land);
        if(token_id_1_str > 800) {
            token_id_1_str = 800;
        };
        assert!(holder_addr == stake.owner, error::permission_denied(ENOT_AUTHORIZED));
        let start_stake = stake.start_time;
        let elapsed_time = now_second - start_stake;
        let war_token_amount = elapsed_time * token_id_1_str * 36;
        // assert!(war_token_amount > 100000, error::permission_denied(EMINIMUM_REQUIRED));
        let coins = coin::withdraw<WarCoinType>(&resource_signer, war_token_amount);
        coin::deposit(signer::address_of(sender), coins);
        table::upsert(&mut staking.stakings, token_id_land, LandStake {
            start_time: now_second,            
            owner: stake.owner,
            fighter_token_id:stake.fighter_token_id,
        });
        let game_events = borrow_global_mut<GameEvents>(game_address);               
        event::emit_event(&mut game_events.stake_events, StakeEvent {            
            start_time: now_second,        
            owner: holder_addr,
            fighter_token_id:token_id_1,
            land_token_id:token_id_land,                           
        });
    }


    entry fun listing_battle_bet<CoinType, WarCoinType> ( 
        owner: &signer,
        game_address:address,
        creator:address, collection:String, name: String, property_version: u64, bet_amount:u64
        ) acquires WarGame, GameEvents, BatteArena {
        let game = borrow_global_mut<WarGame>(game_address);
        assert!(game.is_on_game, error::permission_denied(EONGOING_GAME));
        if(!coin::is_account_registered<WarCoinType>(signer::address_of(owner))){
            coin::register<WarCoinType>(owner);
        };
        let coin_address = coin_address<WarCoinType>();
        assert!(coin_address == @war_coin, error::permission_denied(ENOT_AUTHORIZED));
        assert!(creator == @season_now_creator, error::permission_denied(ENOT_AUTHORIZED_CREATOR));
        let resource_signer = get_resource_account_cap(game_address);
        let owner_addr = signer::address_of(owner);
        assert!(coin::balance<WarCoinType>(owner_addr) >= bet_amount, error::invalid_argument(ENO_SUFFICIENT_FUND));
        assert!(bet_amount >= MINIMUM_BET_WAR_COIN, error::permission_denied(EMINIMUM_REQUIRED));
        let pre_season:vector<u8> = PRE_SEASON_WEREWOLF_AND_WITCH_COLLECTION;    
        let new_token_id = token::create_token_id_raw(creator, collection, name, property_version);
        if (token::check_tokendata_exists(creator, string::utf8(pre_season), name)) {
          new_token_id = transform_native<CoinType>(owner, game_address, creator, name, property_version);
        };
        let token_id = new_token_id;
        let guid = account::create_guid(&resource_signer);
        let listing_id = guid::creation_num(&guid);        
        
        let pm = token::get_property_map(signer::address_of(owner), token_id);                
        let is_wolf = property_map::read_bool(&pm, &string::utf8(IS_WOLF));
        let token_id_str = property_map::read_u64(&pm, &string::utf8(GAME_STRENGTH));
        let is_hero = property_map::read_bool(&pm, &string::utf8(IS_HERO));
        let token = token::withdraw_token(owner, token_id, 1);
        token::deposit_token(&resource_signer, token);

        let coins = coin::withdraw<WarCoinType>(owner, bet_amount);
        coin::deposit(signer::address_of(&resource_signer), coins);        

        let battle_field = borrow_global_mut<BatteArena>(game_address);
                                        
        table::add(&mut battle_field.listings, token_id, ListingFighter {
            listing_id: listing_id,
            owner: owner_addr,
            bet:bet_amount
        });
                
        let game_events = borrow_global_mut<GameEvents>(game_address);       
        
        event::emit_event(&mut game_events.list_fighter_events, ListFighterEvent {            
            owner: owner_addr,
            token_id: token_id,
            is_wolf: is_wolf,
            is_hero: is_hero,
            strength: token_id_str,
            listing_id: listing_id,
            bet:bet_amount,
            timestamp: timestamp::now_microseconds(),
        });
        
    }

    entry fun delisting_battle_bet<CoinType, WarCoinType> (
        sender: &signer,
        game_address:address,
        creator:address, collection:String, name: String, property_version: u64        
        ) acquires WarGame, GameEvents, BatteArena{

        let coin_address = coin_address<WarCoinType>();
        assert!(coin_address == @war_coin, error::permission_denied(ENOT_AUTHORIZED));
        assert!(creator == @season_now_creator, error::permission_denied(ENOT_AUTHORIZED_CREATOR));
        let sender_addr = signer::address_of(sender);       
        let resource_signer = get_resource_account_cap(game_address);                
        let token_id = token::create_token_id_raw(creator, collection, name, property_version);
        let battle_field = borrow_global_mut<BatteArena>(game_address);        
        let fighter = table::borrow(&battle_field.listings, token_id);
        assert!(fighter.owner == sender_addr, error::permission_denied(ENOT_AUTHORIZED));
        
        let token = token::withdraw_token(&resource_signer, token_id, 1);
        token::deposit_token(sender, token);
        
        let left_amount = fighter.bet;
        let coins = coin::withdraw<WarCoinType>(&resource_signer, left_amount);
        coin::deposit(signer::address_of(sender), coins);

        table::remove(&mut battle_field.listings, token_id);
        
        let game_events = borrow_global_mut<GameEvents>(game_address);       
        
        event::emit_event(&mut game_events.delist_fighter_events, DeListFighterEvent {            
            owner: sender_addr,            
            token_id: token_id,
            timestamp: timestamp::now_microseconds(),            
        });                
    }
        
    entry fun battle_with_bet<CoinType, WarCoinType>(holder: &signer, 
        game_address:address, 
        // creator:address,         
        bet_amount: u64,
        creator_1:address, collection_1:String, name_1: String, property_version_1: u64, // me 
        creator_2:address, collection_2:String, name_2: String, property_version_2: u64, // enemy               
        ) acquires WarGame, BatteArena, GameEvents {        
        if(!coin::is_account_registered<WarCoinType>(signer::address_of(holder))){
            coin::register<WarCoinType>(holder);
        };
        
        let coin_address = coin_address<WarCoinType>();
        assert!(coin_address == @war_coin, error::permission_denied(ENOT_AUTHORIZED));        
        let resource_signer = get_resource_account_cap(game_address);
        // let resource_account_address = signer::address_of(&resource_signer);
        let holder_addr =  signer::address_of(holder);

        let pre_season:vector<u8> = PRE_SEASON_WEREWOLF_AND_WITCH_COLLECTION;
        // first token        
        let new_token_id_1 = token::create_token_id_raw(creator_1, collection_1, name_1, property_version_1);        
        if (token::check_tokendata_exists(creator_1, string::utf8(pre_season), name_1)) {
          new_token_id_1 = transform_native<CoinType>(holder, game_address, creator_1, name_1, property_version_1);
        };
        //second token = target
        let new_token_id_2 = token::create_token_id_raw(creator_2, collection_2, name_2, property_version_2);        
        if (token::check_tokendata_exists(creator_2, string::utf8(pre_season), name_2)) {
          new_token_id_2 = transform_native<CoinType>(holder, game_address, creator_2, name_2, property_version_2);
        };
        let token_id_1 = new_token_id_1; // me 
        let token_id_2 = new_token_id_2; // enemy 
        let (creator_1,_,name_1,_) = token::get_token_id_fields(&token_id_1);
        let (creator_2,_,name_2,_) = token::get_token_id_fields(&token_id_2);
        assert!(creator_1 == @season_now_creator, error::permission_denied(ENOT_AUTHORIZED_CREATOR));
        assert!(creator_2 == @season_now_creator, error::permission_denied(ENOT_AUTHORIZED_CREATOR));
        let battle_field = borrow_global_mut<BatteArena>(game_address);            
        
        assert!(table::contains(&mut battle_field.listings, token_id_2), error::permission_denied(ENOT_IN_BATTLE));
        // check type of nft        
        let pm = token::get_property_map(signer::address_of(holder), token_id_1);                
        let is_wolf_1 = property_map::read_bool(&pm, &string::utf8(IS_WOLF));

        let pm2 = token::get_property_map(signer::address_of(&resource_signer), token_id_2);                
        let is_wolf_2 = property_map::read_bool(&pm2, &string::utf8(IS_WOLF));
        assert!(is_wolf_1 != is_wolf_2, error::permission_denied(ESAME_TYPE));

        // get strength from NFT
        
        let token_id_1_str = property_map::read_u64(&pm, &string::utf8(GAME_STRENGTH));
        let token_id_2_str = property_map::read_u64(&pm2, &string::utf8(GAME_STRENGTH));
        // let is_hero_2 = property_map::read_bool(&pm2, &string::utf8(IS_HERO));
        let guid = account::create_guid(&resource_signer);
        let nonce = guid::creation_num(&guid);
        let random = utils::random_with_nonce(holder_addr, 100, nonce) + 1; // 1~100
        let diff = if(token_id_1_str > token_id_2_str) { token_id_1_str - token_id_2_str } else { token_id_2_str - token_id_1_str }; 
        // can't fight if the enemy is too strong.
        assert!(diff < 5, error::permission_denied(ECANT_FIGHT));
        let strong_one = if(token_id_1_str > token_id_2_str) { name_1 } else { name_2 }; 
        
        let fighter = table::borrow(&battle_field.listings, token_id_2);
        let bet_amount_fighter = fighter.bet;        
        // check bidder has sufficient balance
        assert!(coin::balance<WarCoinType>(holder_addr) >= bet_amount_fighter, error::invalid_argument(ENO_SUFFICIENT_FUND));                
        assert!(bet_amount_fighter >=  MINIMUM_BET_WAR_COIN , error::invalid_argument(EFIGHTER_HAS_NO_MONEY));
        assert!(bet_amount_fighter == bet_amount, error::permission_denied(EMUST_SAME_AMOUNT));
        // incentive for battle. coins will be staked by elapsed time.
        let game = borrow_global_mut<WarGame>(game_address); 
        assert!(game.is_on_game, error::permission_denied(EONGOING_GAME));       
        let now_second = timestamp::now_seconds();
        let last_battle_time = game.last_battle_time;
        let price_for_incentive = BATTLE_INCENTVE / FULL_INCENTIVE_STAKE_TIME; 
        let send_amount = (now_second - last_battle_time) * price_for_incentive;
        if(send_amount > BATTLE_INCENTVE * 2 ) {
            send_amount = BATTLE_INCENTVE * 2; 
        };        
        let coins = coin::withdraw<WarCoinType>(&resource_signer, send_amount);                
        let fight_fee = coin::extract(&mut coins, send_amount / 2);
        coin::deposit(fighter.owner, fight_fee);
        coin::deposit(signer::address_of(holder), coins);
        game.last_battle_time = now_second;
        
        let game_events = borrow_global_mut<GameEvents>(game_address);
        let win_rate = 51 + diff; 
        let lose_rate = 102 - win_rate;   
        
        if(name_1 == strong_one) { // if i'm strong
            let pay_amount = bet_amount * (lose_rate -1) / 100;
            if(random < win_rate) {
                // if i win, get WAR Coin from vault                
                let coins = coin::withdraw<WarCoinType>(&resource_signer, pay_amount);
                coin::deposit(holder_addr, coins);
                
                let token = token::withdraw_token(&resource_signer, token_id_2, 1);
                token::deposit_token(holder, token);
                
                let coins2 = coin::withdraw<WarCoinType>(&resource_signer, fighter.bet - pay_amount);
                coin::deposit(fighter.owner, coins2);
                event::emit_event(&mut game_events.delist_fighter_events, DeListFighterEvent {            
                    owner: fighter.owner,                    
                    token_id: token_id_2,
                    timestamp: timestamp::now_microseconds(),            
                }); 

                table::remove(&mut battle_field.listings, token_id_2);                                               
                event::emit_event(&mut game_events.game_result_events, GameResultEvent {            
                    win: true,
                    battle_time:now_second,
                    paid: pay_amount,                    
                });
                item_material_drop(holder, string::utf8(MATERIAL_A), 20);
            } else {                
                
                let coins = coin::withdraw<WarCoinType>(holder, pay_amount);
                coin::deposit(fighter.owner, coins);

                let coins2 = coin::withdraw<WarCoinType>(&resource_signer, fighter.bet);
                coin::deposit(fighter.owner, coins2);                       
                
                event::emit_event(&mut game_events.delist_fighter_events, DeListFighterEvent {            
                    owner: fighter.owner,                    
                    token_id: token_id_2,
                    timestamp: timestamp::now_microseconds(),            
                });
                
                let token = token::withdraw_token(holder, token_id_1, 1);                        
                token::direct_deposit_with_opt_in(fighter.owner, token); 
                table::remove(&mut battle_field.listings, token_id_2);                                                                           
                event::emit_event(&mut game_events.game_result_events, GameResultEvent {            
                    win: false,
                    battle_time:now_second,
                    paid:pay_amount,                    
                });
                item_material_drop(holder, string::utf8(MATERIAL_B), 10);
            };
        } else { // if i'm weak
            let pay_amount = bet_amount * (win_rate - 1) / 100;
            if(random < lose_rate) { 
                let coins = coin::withdraw<WarCoinType>(&resource_signer, pay_amount);
                coin::deposit(holder_addr, coins);                                                
                let token = token::withdraw_token(&resource_signer, token_id_2, 1);
                token::deposit_token(holder, token);                
                let coins2 = coin::withdraw<WarCoinType>(&resource_signer, fighter.bet - pay_amount);
                coin::deposit(fighter.owner, coins2);

                event::emit_event(&mut game_events.delist_fighter_events, DeListFighterEvent {            
                    owner: fighter.owner,                    
                    token_id: token_id_2,
                    timestamp: timestamp::now_microseconds(),            
                });
                table::remove(&mut battle_field.listings, token_id_2);

                event::emit_event(&mut game_events.game_result_events, GameResultEvent {            
                    win: true,
                    battle_time:now_second,
                    paid: pay_amount,
                });             
                item_material_drop(holder, string::utf8(MATERIAL_C), 20);
            } else {                 
                let coins = coin::withdraw<WarCoinType>(holder, pay_amount);
                coin::deposit(fighter.owner, coins);

                let coins2 = coin::withdraw<WarCoinType>(&resource_signer, fighter.bet);
                coin::deposit(fighter.owner, coins2);
                                
                event::emit_event(&mut game_events.delist_fighter_events, DeListFighterEvent {            
                    owner: fighter.owner,                    
                    token_id: token_id_2,
                    timestamp: timestamp::now_microseconds(),            
                });
                
                let token = token::withdraw_token(holder, token_id_1, 1);                        
                token::direct_deposit_with_opt_in(fighter.owner, token);
                table::remove(&mut battle_field.listings, token_id_2);
                event::emit_event(&mut game_events.game_result_events, GameResultEvent {            
                    win: false,
                    battle_time:now_second,
                    paid:pay_amount,                    
                });              
                item_material_drop(holder, string::utf8(MATERIAL_I), 10);                
            };
        };           
    }

    entry fun bulk_mint<CoinType>(receiver: &signer, game_address:address, amount:u64) acquires WarGame, GameEvents, WhiteList {
        let ind = 1;
        assert!(amount > 1, error::permission_denied(ENOT_AUTHORIZED));
        assert!(amount < 1000, error::permission_denied(ENOT_AUTHORIZED));        
        item_material_drop(receiver, string::utf8(MATERIAL_E), 5);
        while (ind <= amount) {
            mint_token<CoinType>(receiver, game_address, false, ind);
            ind = ind + 1;
        };        
    }

    entry fun end_game(game_address:address) acquires WarGame, GameEvents {
        // check game it could be end
        let game = borrow_global_mut<WarGame>(game_address);
        assert!(game.is_on_game, error::permission_denied(EONGOING_GAME));       
        let minimum_elapsed_time = game.minimum_elapsed_time;
        let nft_count = game.total_nft_count;
        // at least 10 nfts required to be end        
        assert!(nft_count > 10, error::permission_denied(ENOT_ENOUGH_NFT));
        assert!(minimum_elapsed_time < timestamp::now_seconds() , error::permission_denied(ENOT_READY_END));        
        let minimum_alive = (nft_count / 10) * RATIO_FOR_WIN;        
        let bigger = if (game.wolf > game.witch) { game.wolf } else { game.witch };
        let is_game_over = if(bigger > minimum_alive) { true } else { false };        
        assert!(is_game_over, error::permission_denied(ENOT_READY_END));        
        let no_battle_time = timestamp::now_seconds() - game.last_battle_time;
        if(is_game_over || (no_battle_time > NO_BATTLE_TIME_LIMIT)) {
            let game = borrow_global_mut<WarGame>(game_address);
            game.is_on_game = false;
            let game_events = borrow_global_mut<GameEvents>(game_address);        
            event::emit_event(&mut game_events.war_state_events, WarStateEvent { in_war: false }); 
        };                
    }

    entry fun withdraw_prize<CoinType> (sender: &signer, game_address:address, creator:address, collection:String,name: String, property_version:u64) 
        acquires WarGame, GameEvents {    
        let coin_address = coin_address<CoinType>();
        assert!(coin_address == @aptos_coin, error::permission_denied(ENOT_AUTHORIZED));    
        let sender_addr = signer::address_of(sender);        
        let pre_season:vector<u8> = PRE_SEASON_WEREWOLF_AND_WITCH_COLLECTION;    
        let new_token_id = token::create_token_id_raw(creator, collection, name, property_version);
        if (token::check_tokendata_exists(creator, string::utf8(pre_season), name)) {
          new_token_id = transform_native<CoinType>(sender, game_address, creator, name, property_version);
        };        
        let token_id_1 = new_token_id;
        let (new_creator,_,name_1,_) = token::get_token_id_fields(&token_id_1);
        assert!(new_creator == @season_now_creator, error::permission_denied(ENOT_AUTHORIZED_CREATOR));        
        let game = borrow_global_mut<WarGame>(game_address);
        let pm = token::get_property_map(signer::address_of(sender), token_id_1);                
        let is_wolf = property_map::read_bool(&pm, &string::utf8(IS_WOLF));
        let wolf_win = if (game.wolf > game.witch) { true } else { false };
        assert!(is_wolf == wolf_win, error::permission_denied(ENOT_WIN_FACTION));        
        assert!(!game.is_on_game, error::permission_denied(EONGOING_GAME));
        let total_prize = game.total_prize;        
        let winner_count = if (game.wolf > game.witch) { game.wolf } else { game.witch };
        let prize_per_each = total_prize / winner_count;
        let resource_signer = get_resource_account_cap(game_address); 
        let resource_account_address = signer::address_of(&resource_signer);
        assert!(resource_account_address == new_creator, ENOT_AUTHORIZED_CREATOR);        
        let coins = coin::withdraw<CoinType>(&resource_signer, prize_per_each);                        
        coin::deposit(sender_addr, coins); 
        token::burn(sender, new_creator, string::utf8(WEREWOLF_AND_WITCH_COLLECTION), name_1, property_version, 1);                                
        let game_events = borrow_global_mut<GameEvents>(game_address);               
        event::emit_event(&mut game_events.earn_prize_events, EarnPrizeEvent {            
           burner: sender_addr,
           token_name: name_1,        
        });
    }

    entry fun mint_token<CoinType>(
        receiver: &signer, game_address:address, white_list_mint:bool, _nonce:u64) 
        acquires WarGame, GameEvents, WhiteList {
        let coin_address = coin_address<CoinType>();
        assert!(coin_address == @aptos_coin, error::permission_denied(ENOT_AUTHORIZED));
        
        let resource_signer = get_resource_account_cap(game_address); 
        let resource_account_address = signer::address_of(&resource_signer);        
        let receiver_address = signer::address_of(receiver);
        
        // special features                
        let minter = borrow_global<WarGame>(game_address);
        let collection_id = create_collection_data_id(game_address, string::utf8(WEREWOLF_AND_WITCH_COLLECTION));                        
        assert!(timestamp::now_seconds() > minter.presale_mint_start_timestamp, error::permission_denied(ENOT_READY_MINT));
        if(white_list_mint) {
            let whitelist_store = borrow_global_mut<WhiteList>(game_address);
            let whitelist_key = WhiteListKey { white_address: receiver_address, collection_id};                          
            assert!(table::contains(&mut whitelist_store.whitelist, whitelist_key), error::permission_denied(ENO_NOT_IN_WHITELIST));
            let limit = table::borrow(&whitelist_store.whitelist, whitelist_key);
            let checker = if (*limit > 0) { true } else { false };
            assert!(checker, error::permission_denied(ENO_NOT_ENOUGH_LIMIT));                        
            table::upsert(&mut whitelist_store.whitelist, whitelist_key, (*limit - 1));
        } else {
            assert!(timestamp::now_seconds() > minter.public_mint_start_timestamp, error::permission_denied(ENOT_READY_MINT));
        };       

        assert!(minter.is_on_game, error::permission_denied(EONGOING_GAME));
        // get random 
        let guid = account::create_guid(&resource_signer);
        let nonce = guid::creation_num(&guid);
        let random = utils::random_with_nonce(receiver_address, 10, nonce) + 1;
        let isWolf = if (random <= 5) { true } else { false };
        
        let price_for_mint = if(white_list_mint) { minter.presale_mint_price } else { minter.public_mint_price };        
        assert!(coin::balance<CoinType>(receiver_address) >= price_for_mint, error::invalid_argument(ENO_SUFFICIENT_FUND));
        let coins = coin::withdraw<CoinType>(receiver, price_for_mint);
        coin::deposit(resource_account_address, coins);  // send to vault for prize for winners
        
        let token_description = minter.token_description;
        let royalty_points_numerator = minter.token_royalty_points_numerator;

        let supply_count = &mut token::get_collection_supply(resource_account_address, string::utf8(WEREWOLF_AND_WITCH_COLLECTION));        
        let new_supply = option::extract<u64>(supply_count);
        let count_string = utils::to_string((new_supply as u128));
        let token_name = string::utf8(WEREWOLF_AND_WITCH_COLLECTION);
        string::append_utf8(&mut token_name, b" #");
        string::append(&mut token_name, count_string);
        // add uri json string                
        
        let uri = if (isWolf) { string::utf8(WEREWOLF_JSON_URL) } else { string::utf8(WITCH_JSON_URL) };                
        string::append(&mut uri, count_string);
        string::append_utf8(&mut uri, b".json");

        if(token::check_tokendata_exists(resource_account_address, string::utf8(WEREWOLF_AND_WITCH_COLLECTION), token_name)){
            let i = 0;
            let token_name_new = string::utf8(WEREWOLF_AND_WITCH_COLLECTION);
            let collection_max_count = new_supply;
            while (i < collection_max_count + 1) {
                let new_token_name = token_name_new;
                
                string::append_utf8(&mut new_token_name, b" #");
                let count_string = utils::to_string((i as u128));
                string::append(&mut new_token_name, count_string);                            
                
                if(!token::check_tokendata_exists(resource_account_address, string::utf8(WEREWOLF_AND_WITCH_COLLECTION), new_token_name)) {
                    token_name = new_token_name;
                    let new_uri = if (isWolf) { string::utf8(WEREWOLF_JSON_URL) } else { string::utf8(WITCH_JSON_URL) };                            
                    string::append(&mut new_uri, count_string);
                    string::append_utf8(&mut new_uri, b".json");
                    uri = new_uri;
                    break
                };
                i = i + 1;
            };                                       
        }; 

        let mutability_config = &vector<bool>[ false, true, true, true, true ];
        let guid = account::create_guid(&resource_signer);
        let nonce = guid::creation_num(&guid);
        let randomStrength = utils::random_with_nonce(receiver_address, 5, nonce) + 1;
        let token_data_id = token::create_tokendata(
                &resource_signer,
                string::utf8(WEREWOLF_AND_WITCH_COLLECTION),
                token_name,
                token_description,
                1, // 1 maximum for NFT 
                uri,
                resource_account_address, // royalty fee to
                FEE_DENOMINATOR,
                royalty_points_numerator,
                // we don't allow any mutation to the token
                token::create_token_mutability_config(mutability_config),
                // type
                vector<String>[string::utf8(BURNABLE_BY_OWNER),string::utf8(TOKEN_PROPERTY_MUTABLE), string::utf8(GAME_STRENGTH), string::utf8(IS_WOLF),string::utf8(IS_HERO), string::utf8(IS_EQUIP)],  // property_keys                
                vector<vector<u8>>[bcs::to_bytes<bool>(&true),bcs::to_bytes<bool>(&true), bcs::to_bytes<u64>(&randomStrength), bcs::to_bytes<bool>(&isWolf),bcs::to_bytes<bool>(&false), bcs::to_bytes<bool>(&false)],  // values 
                vector<String>[string::utf8(b"bool"),string::utf8(b"bool"), string::utf8(b"u64"), string::utf8(b"bool"),string::utf8(b"bool"),string::utf8(b"bool")],      // type
        );        
        utils::token_mint_and_transfer(resource_signer,receiver,token_data_id);                
        
        let receiver_address = signer::address_of(receiver);
        game_score_change_event_emit(game_address,isWolf, receiver_address);
        
    }
    

    // burn enemy nft and get strength
    entry fun burn_token_and_enhance<CoinType>(
        holder: &signer, 
        game_address:address,         
        creator_1:address, collection_1:String, name_1: String, property_version_1: u64, // mine
        creator_2:address, collection_2:String, name_2: String, property_version_2: u64, // target
        ) acquires WarGame, GameEvents {        
        let resource_signer = get_resource_account_cap(game_address);         
        let holder_addr = signer::address_of(holder);
        let pre_season:vector<u8> = PRE_SEASON_WEREWOLF_AND_WITCH_COLLECTION;        
        let new_token_id_1 = token::create_token_id_raw(creator_1, collection_1, name_1, property_version_1);        
        if (token::check_tokendata_exists(creator_1, string::utf8(pre_season), name_1)) {
          new_token_id_1 = transform_native<CoinType>(holder, game_address, creator_1, name_1, property_version_1);
        };        
        let new_token_id_2 = token::create_token_id_raw(creator_2, collection_2, name_2, property_version_2);        
        if (token::check_tokendata_exists(creator_2, string::utf8(pre_season), name_2)) {
          new_token_id_2 = transform_native<CoinType>(holder, game_address, creator_2, name_2, property_version_2);
        };
        let token_id_1 = new_token_id_1; // me 
        let token_id_2 = new_token_id_2; // enemy        
        
        let (creator_1,_,_,_) = token::get_token_id_fields(&token_id_1);
        let (creator_2,_,_,_) = token::get_token_id_fields(&token_id_2);
        assert!(creator_1 == @season_now_creator, error::permission_denied(ENOT_AUTHORIZED_CREATOR));
        assert!(creator_2 == @season_now_creator, error::permission_denied(ENOT_AUTHORIZED_CREATOR));
        let pm = token::get_property_map(holder_addr, token_id_1);                
        let is_wolf_1 = property_map::read_bool(&pm, &string::utf8(IS_WOLF));
        let token_id_1_str = property_map::read_u64(&pm, &string::utf8(GAME_STRENGTH));
        
        let pm2 = token::get_property_map(holder_addr, token_id_2);                
        let is_wolf_2 = property_map::read_bool(&pm2, &string::utf8(IS_WOLF));
        
        assert!(is_wolf_1 != is_wolf_2, error::permission_denied(ESAME_TYPE));

        let token_id_2_str = property_map::read_u64(&pm2, &string::utf8(GAME_STRENGTH));
        let guid = account::create_guid(&resource_signer);
        let nonce = guid::creation_num(&guid);        
        let random_strength = utils::random_with_nonce(holder_addr, token_id_2_str, nonce) + 1;
        let new_str = token_id_1_str + random_strength;

        token::mutate_one_token(            
            &resource_signer,
            holder_addr,
            token_id_1,            
            vector<String>[string::utf8(GAME_STRENGTH), string::utf8(IS_WOLF)],  // property_keys                
            vector<vector<u8>>[bcs::to_bytes<u64>(&new_str), bcs::to_bytes<bool>(&is_wolf_1)],  // values 
            vector<String>[string::utf8(b"u64"), string::utf8(b"bool")],      // type
        );        
         
        let game = borrow_global_mut<WarGame>(game_address);
        assert!(game.is_on_game, error::permission_denied(EONGOING_GAME));
        game.total_nft_count = game.total_nft_count - 1;
        if(is_wolf_2) { // if enemy is wolf
            game.wolf = game.wolf - 1;
        } else {
            game.witch = game.witch - 1;
        };        
        let (creator_addr,_,new_token_name, new_property_version) = token::get_token_id_fields(&new_token_id_2);
        token::burn(holder, creator_addr, string::utf8(WEREWOLF_AND_WITCH_COLLECTION), new_token_name, new_property_version, 1);
        
        let game_events = borrow_global_mut<GameEvents>(game_address);        
        event::emit_event(&mut game_events.game_score_changed_events, GameScoreChangedEvent { 
            wolf:game.wolf,
            witch:game.witch,
            total_prize: game.total_prize,
            total_nft_count:game.total_nft_count,
        }); 
        event::emit_event(&mut game_events.fighter_events, FighterChangeEvent {            
            owner: holder_addr,            
            token_name: name_1,
            strength: new_str,
        });       
    }

    // white list features

    entry fun add_whitelist<CoinType>(creator: &signer, game_address:address, whitelists:vector<address>, whitelists_limit:vector<u64>) acquires WhiteList,GameEvents {
        assert!(vector::length(&whitelists) == vector::length(&whitelists_limit), error::permission_denied(ENO_NOT_EQUAL));
        let creator_addr = signer::address_of(creator);
        let collection_id = create_collection_data_id(creator_addr, string::utf8(WEREWOLF_AND_WITCH_COLLECTION));        
        let whitelist_store = borrow_global_mut<WhiteList>(game_address);
        let i = 0;
        let game_events = borrow_global_mut<GameEvents>(game_address);        
        while (i < vector::length(&whitelists)) {
            let addr = *vector::borrow(&whitelists, i);
            let limit = *vector::borrow(&whitelists_limit, i);        
            let whitelist_key = WhiteListKey { white_address: addr, collection_id};              
            table::upsert(&mut whitelist_store.whitelist, whitelist_key, limit);
            event::emit_event(&mut game_events.whitelist_events, WhitelistEvent { whitelist_key: whitelist_key, limit });                        
            i = i + 1;        
        }                    
    }     

    entry fun remove_whitelist<CoinType>(creator: &signer, game_address:address, whitelists:vector<address>) acquires WhiteList,GameEvents {        
        let creator_address = signer::address_of(creator);        
        let collection_id = create_collection_data_id(creator_address, string::utf8(WEREWOLF_AND_WITCH_COLLECTION));            
        let whitelist_store = borrow_global_mut<WhiteList>(game_address);
        let i = 0;
        let game_events = borrow_global_mut<GameEvents>(game_address);        
        while (i < vector::length(&whitelists)) {
            let addr = *vector::borrow(&whitelists, i);
            let limit = 0;        
            let whitelist_key = WhiteListKey { white_address: addr, collection_id };              
            table::upsert(&mut whitelist_store.whitelist, whitelist_key, limit);
            event::emit_event(&mut game_events.whitelist_events, WhitelistEvent { whitelist_key: whitelist_key, limit });                        
            i = i + 1;        
        }                    
    }     

    entry fun create_collection_hero<CoinType> (
        sender: &signer, description: String, 
        collection_uri: String, maximum_supply: u64, mutate_setting: vector<bool>        
        ) acquires WarGame {                                        
        let sender_addr = signer::address_of(sender);      
        let resource_signer = get_resource_account_cap(sender_addr);
        token::create_collection(&resource_signer, string::utf8(WEREWOLF_AND_WITCH_COLLECTION), description, collection_uri, maximum_supply, mutate_setting);
    }

    entry fun create_hero<CoinType> (
        sender: &signer, game_address: address, name: String, is_wolf: bool, description:String, uri:String, royalty_points_numerator:u64, init_str: u64         
    ) acquires WarGame, GameEvents {               
        let mutability_config = &vector<bool>[ false, true, true, true, true ];            
        let sender_addr = signer::address_of(sender);
        assert!(sender_addr == game_address, error::permission_denied(ENOT_AUTHORIZED));      
        let resource_signer = get_resource_account_cap(sender_addr);        
        let token_data_id = token::create_tokendata(
                &resource_signer,
                string::utf8(WEREWOLF_AND_WITCH_COLLECTION),
                name,
                description,
                1, // 1 maximum for NFT 
                uri,
                sender_addr, // royalty fee to                
                FEE_DENOMINATOR,
                royalty_points_numerator,
                // we don't allow any mutation to the token
                token::create_token_mutability_config(mutability_config),
                // type
                vector<String>[string::utf8(BURNABLE_BY_OWNER),string::utf8(TOKEN_PROPERTY_MUTABLE), string::utf8(GAME_STRENGTH), string::utf8(IS_WOLF), string::utf8(IS_HERO)],  // property_keys                
                vector<vector<u8>>[bcs::to_bytes<bool>(&true),bcs::to_bytes<bool>(&true), bcs::to_bytes<u64>(&init_str), bcs::to_bytes<bool>(&is_wolf), bcs::to_bytes<bool>(&true)],  // values 
                vector<String>[string::utf8(b"bool"),string::utf8(b"bool"), string::utf8(b"u64"), string::utf8(b"bool"), string::utf8(b"bool")],
        );
        let token_id = token::mint_token(&resource_signer, token_data_id, 1);
        token::opt_in_direct_transfer(sender, true);
        token::direct_transfer(&resource_signer, sender, token_id, 1);        
        // emit events 
        let game_events = borrow_global_mut<GameEvents>(game_address);        
     
        event::emit_event(&mut game_events.token_minting_events, TokenMintingEvent { 
            token_receiver_address: sender_addr,
            is_wolf:is_wolf,
            public_price: 0,
        });        
        
    }
    // shop
    entry fun buy_potion<WarCoinType> (
        sender: &signer, game_address:address, creator_potion:address,
        name_potion:String, property_version_potion:u64,
        amount: u64,
    ) acquires WarGame , GameEvents{
        let resource_signer = get_resource_account_cap(game_address);
        let coin_address = coin_address<WarCoinType>();
        assert!(coin_address == @war_coin, error::permission_denied(ENOT_AUTHORIZED));

        let items = vector<String>[
            string::utf8(POTION_A),string::utf8(POTION_B), string::utf8(POTION_C), string::utf8(POTION_D)
         ];
        let game_events = borrow_global_mut<GameEvents>(game_address);                
        let selected_item;        
        let ind = 0;
        while (ind < vector::length(&items)) {
            let item = *vector::borrow(&items, ind);
            if (name_potion == item) {
                selected_item = item;
                event::emit_event(&mut game_events.item_stock_events, ItemStockChangeEvent {
                    item_name: selected_item,
                    minus_count:1
                });
            };
            ind = ind + 1;
        };

        let resource_account_address = signer::address_of(&resource_signer);
        let coins = coin::withdraw<WarCoinType>(sender, amount);
        assert!(amount >= 15000000000, ENOT_ENOUGH_MONEY); // price: 150 WAR TOKEN
        coin::deposit(resource_account_address, coins);
        let token_id_1 = token::create_token_id_raw(creator_potion, string::utf8(POTION_COLLECTION_NAME), name_potion, property_version_potion);
        let token = token::withdraw_token(&resource_signer, token_id_1, 1);
        token::deposit_token(sender, token);
    }

    entry fun buy_hero<WarCoinType> (
        sender: &signer, game_address:address, creator_hero:address,
        name_hero:String, property_version:u64,
        amount: u64,
    ) acquires WarGame , GameEvents{
        let coin_address = coin_address<WarCoinType>();
        assert!(coin_address == @war_coin, error::permission_denied(ENOT_AUTHORIZED));

        let items = vector<String>[
            string::utf8(HERO_A),string::utf8(HERO_B),
            string::utf8(HERO_C), string::utf8(HERO_D),
            string::utf8(HERO_E), string::utf8(HERO_F),
            string::utf8(HERO_G)
         ];
        let game_events = borrow_global_mut<GameEvents>(game_address);                
        let selected_item;        
        let ind = 0;
        while (ind < vector::length(&items)) {
            let item = *vector::borrow(&items, ind);
            if (name_hero == item) {
                selected_item = item;
                event::emit_event(&mut game_events.item_stock_events, ItemStockChangeEvent {
                    item_name: selected_item,
                    minus_count:1
                });
            };
            ind = ind + 1;
        };

        let resource_signer = get_resource_account_cap(game_address);        
        let resource_account_address = signer::address_of(&resource_signer);
        let coins = coin::withdraw<WarCoinType>(sender, amount);
        assert!(amount >= 1000000000000, ENOT_ENOUGH_MONEY); // price: 10,000 WAR TOKEN
        coin::deposit(resource_account_address, coins);
        let token_id_1 = token::create_token_id_raw(creator_hero, string::utf8(WEREWOLF_AND_WITCH_COLLECTION), name_hero, property_version);
        let token = token::withdraw_token(&resource_signer, token_id_1, 1);
        token::deposit_token(sender, token);
    }
    
    entry fun buy_land<WarCoinType> (
        sender: &signer, game_address:address, 
        creator_land:address, name_land:String, property_version_land:u64,
        amount: u64,
    ) acquires WarGame, GameEvents {
        let resource_signer = get_resource_account_cap(game_address);
        let coin_address = coin_address<WarCoinType>();
        assert!(coin_address == @war_coin, error::permission_denied(ENOT_AUTHORIZED));
        // item count process
        let items = vector<String>[
            string::utf8(LAND_A),string::utf8(LAND_B),
            string::utf8(LAND_C), string::utf8(LAND_D)
        ];
        let game_events = borrow_global_mut<GameEvents>(game_address);                
        let selected_item;        
        let ind = 0;
        while (ind < vector::length(&items)) {
            let item = *vector::borrow(&items, ind);
            if (name_land == item) {
                selected_item = item;
                event::emit_event(&mut game_events.item_stock_events, ItemStockChangeEvent {
                    item_name: selected_item,
                    minus_count:1
                });
            };
            ind = ind + 1;
        };

        let resource_account_address = signer::address_of(&resource_signer);
        let coins = coin::withdraw<WarCoinType>(sender, amount);
        assert!(amount >= 1000000000000, ENOT_ENOUGH_MONEY); // price: 10000 WAR TOKEN
        coin::deposit(resource_account_address, coins);
        let token_id_1 = token::create_token_id_raw(creator_land, string::utf8(LAND_COLLECTION_NAME), name_land, property_version_land);
        let token = token::withdraw_token(&resource_signer, token_id_1, 1);
        token::deposit_token(sender, token);
    }

    entry fun transform<CoinType> (
        receiver: &signer, game_address:address, creator:address, token_name_1:String, property_version:u64            
    ) acquires WarGame, GameEvents{
        transform_native<CoinType>(receiver, game_address, creator, token_name_1, property_version);                                                            
    }    

    fun transform_native<CoinType> (
        receiver: &signer, game_address:address, creator:address, token_name_1:String, property_version:u64            
    ): TokenId acquires WarGame,GameEvents  { 
        let coin_address = coin_address<CoinType>();
        assert!(coin_address == @aptos_coin, error::permission_denied(ENOT_AUTHORIZED));        
        assert!(creator == @season_pre_creator, error::permission_denied(ENOT_AUTHORIZED_CREATOR));
        let minter = borrow_global<WarGame>(game_address);        
        assert!(minter.is_on_game, error::permission_denied(EONGOING_GAME));                
        let token_description = minter.token_description;
        let royalty_points_numerator = minter.token_royalty_points_numerator;            
        let pre_season:vector<u8> = PRE_SEASON_WEREWOLF_AND_WITCH_COLLECTION;
        let new_season:vector<u8> = WEREWOLF_AND_WITCH_COLLECTION;
        // resources 
        let resource_signer = get_resource_account_cap(game_address);         
        let resource_account_address = signer::address_of(&resource_signer);        
        let coins = coin::withdraw<CoinType>(receiver, PRICE_FOR_NFT);                        
        coin::deposit(resource_account_address, coins);
        let token_id_1 = token::create_token_id_raw(creator, string::utf8(pre_season), token_name_1, property_version); // origin
        let token_data_id_1 = token::create_token_data_id(creator,string::utf8(pre_season),token_name_1);        
        let token = token::withdraw_token(receiver, token_id_1, 1);
        token::deposit_token(&resource_signer, token);

        let pm = token::get_property_map(resource_account_address, token_id_1);                
        let is_wolf_1 = property_map::read_bool(&pm, &string::utf8(IS_WOLF));
        let token_id_1_str = property_map::read_u64(&pm, &string::utf8(GAME_STRENGTH));
        let is_hero = property_map::read_bool(&pm, &string::utf8(IS_HERO));
        let is_equip = false; // SHOULD BE CHANGED IN NEXT SEASON
        let supply_count = &mut token::get_collection_supply(resource_account_address, string::utf8(WEREWOLF_AND_WITCH_COLLECTION));        
        let new_supply = option::extract<u64>(supply_count);
        let count_string = utils::to_string((new_supply as u128));
        let token_name = string::utf8(WEREWOLF_AND_WITCH_COLLECTION);
        string::append_utf8(&mut token_name, b" #");
        string::append(&mut token_name, count_string);
        // add uri json string                
        let uri = if (is_wolf_1) { string::utf8(WEREWOLF_JSON_URL) } else { string::utf8(WITCH_JSON_URL) };        
        
        string::append(&mut uri, count_string);
        string::append_utf8(&mut uri, b".json");

        if(token::check_tokendata_exists(resource_account_address, string::utf8(WEREWOLF_AND_WITCH_COLLECTION), token_name)){
            let i = 0;
            let token_name_new = string::utf8(WEREWOLF_AND_WITCH_COLLECTION);
            let collection_max_count = new_supply;
            while (i < collection_max_count + 1) {
                let new_token_name = token_name_new;
                
                string::append_utf8(&mut new_token_name, b" #");
                let count_string = utils::to_string((i as u128));
                string::append(&mut new_token_name, count_string);                            
                
                if(!token::check_tokendata_exists(resource_account_address, string::utf8(WEREWOLF_AND_WITCH_COLLECTION), new_token_name)) {
                    token_name = new_token_name;
                    let new_uri = if (is_wolf_1) { string::utf8(WEREWOLF_JSON_URL) } else { string::utf8(WITCH_JSON_URL) };                            
                    string::append(&mut new_uri, count_string);
                    string::append_utf8(&mut new_uri, b".json");
                    uri = new_uri;
                    break
                };
                i = i + 1;
            }; 
                                      
        }; 
        let mutability_config = &vector<bool>[ false, true, true, true, true ];                    
        if(is_hero) {          
            uri = token::get_tokendata_uri(creator,token_data_id_1);
            token_description = token::get_tokendata_description(token_data_id_1);
            let (_,_,token_name_new,_) = token::get_token_id_fields(&token_id_1);
            token_name = token_name_new;
        };
        //     vector<String>[string::utf8(IS_EQUIP), string::utf8(ITEM_LEVEL), string::utf8(ITEM_DEFAULT_STR)],  // property_keys                
        //     vector<vector<u8>>[bcs::to_bytes<bool>(&true), bcs::to_bytes<u64>(&level),bcs::to_bytes<u64>(&default_str)],  // values 
        //     vector<String>[string::utf8(b"bool"),string::utf8(b"u64"),string::utf8(b"u64")],      // type

        let token_data_id = token::create_tokendata(
                &resource_signer,
                string::utf8(new_season),
                token_name,
                token_description,
                1, // 1 maximum for NFT 
                uri,
                resource_account_address, // royalty fee to
                FEE_DENOMINATOR,
                royalty_points_numerator,
                // we don't allow any mutation to the token
                token::create_token_mutability_config(mutability_config),
                // type
                vector<String>[
                    string::utf8(BURNABLE_BY_OWNER),string::utf8(TOKEN_PROPERTY_MUTABLE), string::utf8(GAME_STRENGTH), 
                    string::utf8(IS_WOLF),string::utf8(IS_HERO),string::utf8(IS_EQUIP)
                ],  // property_keys                
                vector<vector<u8>>[
                    bcs::to_bytes<bool>(&true),bcs::to_bytes<bool>(&true), bcs::to_bytes<u64>(&token_id_1_str), 
                    bcs::to_bytes<bool>(&is_wolf_1),bcs::to_bytes<bool>(&is_equip)
                ],  // values 
                vector<String>[
                    string::utf8(b"bool"),string::utf8(b"bool"), string::utf8(b"u64"), string::utf8(b"bool"), 
                    string::utf8(b"bool"), string::utf8(b"bool")
                ],      // type
        );        
        
        token::burn(&resource_signer, creator, string::utf8(pre_season), token_name_1, property_version, 1);
        let token_id = utils::token_mint_and_transfer(resource_signer, receiver,token_data_id);
        // game score and event 
        let receiver_address = signer::address_of(receiver);
        game_score_change_event_emit(game_address,is_wolf_1, receiver_address);                

        token_id            
    }    
    
    entry fun pre_season_reward<WarCoinType> (
        sender: &signer, game_address:address,
        creator:address, name_1: String, property_version_1: u64,
    ) acquires WarGame {     
        let coin_address = coin_address<WarCoinType>();    
        if(!coin::is_account_registered<WarCoinType>(signer::address_of(sender))){
            coin::register<WarCoinType>(sender);
        };    
        assert!(creator == @season_pre_creator, error::permission_denied(ENOT_AUTHORIZED));
        assert!(coin_address == @war_coin, error::permission_denied(ENOT_AUTHORIZED));
        let resource_signer = get_resource_account_cap(game_address);                
        let sender_addr = signer::address_of(sender);
        let pre_season:vector<u8> = PRE_SEASON_WEREWOLF_AND_WITCH_COLLECTION;        
        let token_id = token::create_token_id_raw(creator, string::utf8(pre_season), name_1, property_version_1);   
        let pm = token::get_property_map(signer::address_of(sender), token_id);
        let (_, token_id_1_str, _) = get_pm_properties(pm);
        let coins = coin::withdraw<WarCoinType>(&resource_signer, token_id_1_str * WAR_COIN_DECIMAL);                
        coin::deposit(sender_addr, coins); 
        token::burn(sender, creator, string::utf8(pre_season), name_1, property_version_1, 1);
    }
    // dungeon
    // dungeon_type 1~10
    entry fun entering_dungeon<WarCoinType> (
        sender: &signer, game_address:address,
        creator:address, name_1: String, property_version_1: u64, monster_type: u64
    ) acquires WarGame, MonsterRegenTimer,GameEvents {        
        let coin_address = coin_address<WarCoinType>();
        assert!(creator == @season_now_creator, error::permission_denied(ENOT_AUTHORIZED_CREATOR));
        assert!(coin_address == @war_coin, error::permission_denied(ENOT_AUTHORIZED));        
        let minter = borrow_global<WarGame>(game_address);        
        assert!(minter.is_on_game, error::permission_denied(EONGOING_GAME));                
        let resource_signer = get_resource_account_cap(game_address);                
        let resource_account_address = signer::address_of(&resource_signer);        
        let sender_addr = signer::address_of(sender);
        let game_events = borrow_global_mut<GameEvents>(game_address);
        let now_second = timestamp::now_seconds();
        // entrance fee = 1WAR Coin
        assert!(coin::balance<WarCoinType>(sender_addr) >= WAR_COIN_DECIMAL, error::invalid_argument(ENO_SUFFICIENT_FUND));
        let token_id_1 = token::create_token_id_raw(creator, string::utf8(WEREWOLF_AND_WITCH_COLLECTION), name_1, property_version_1);            
        let pm = token::get_property_map(signer::address_of(sender), token_id_1);
        let (_is_wolf_1, token_id_1_str, is_hero) = get_pm_properties(pm);
        if (token_id_1_str < 50) {
            assert!(monster_type < 3, error::permission_denied(ENOT_AUTHORIZED));
            assert!(monster_type > 0, error::permission_denied(ENOT_AUTHORIZED));
            // entrance fee
            let coins = coin::withdraw<WarCoinType>(sender, WAR_COIN_DECIMAL);        
            coin::deposit(signer::address_of(&resource_signer), coins);
            let regen_timer = borrow_global_mut<MonsterRegenTimer>(game_address);            
            assert!(regen_timer.last_killed_time_type_1 < now_second, ENOT_READY_END);
            let win = dungeons::beginner(token_id_1_str, is_hero, monster_type, resource_account_address);            
            if(win) {                
                let prize_war = utils::random_with_nonce(resource_account_address, 5, token_id_1_str) + 1; // 1~15
                if(monster_type == 2) {
                    prize_war = prize_war + 5;                    
                };
                regen_timer.last_killed_time_type_1 = timestamp::now_seconds() + MINIMUM_REGEN_TIME_A;
                let coins = coin::withdraw<WarCoinType>(&resource_signer, prize_war * WAR_COIN_DECIMAL);                
                coin::deposit(sender_addr, coins);
                event::emit_event(&mut game_events.monster_killed_events, MonsterKilledEvent { 
                    killed_time: now_second,
                    killer: sender_addr,
                    monster_type: monster_type
                });
                event::emit_event(&mut game_events.dungeon_result_events, GameResultDungeonEvent {            
                    win: true,
                    battle_time:now_second,
                    earn: prize_war * WAR_COIN_DECIMAL,
                    death:false
                });
                item_material_drop(sender, string::utf8(MATERIAL_A), 60);
            } else {
                event::emit_event(&mut game_events.dungeon_result_events, GameResultDungeonEvent {            
                    win: false,
                    battle_time:now_second,
                    earn:0,
                    death:false
                });            
                item_material_drop(sender, string::utf8(MATERIAL_G), 20);
            };            
        };

        if(token_id_1_str < 100 && token_id_1_str >= 50) {
            assert!(monster_type < 5, error::permission_denied(ENOT_AUTHORIZED));
            assert!(monster_type > 2, error::permission_denied(ENOT_AUTHORIZED));
            // entrance fee
            let coins = coin::withdraw<WarCoinType>(sender, WAR_COIN_DECIMAL * 2);        
            coin::deposit(signer::address_of(&resource_signer), coins);
            let regen_timer = borrow_global_mut<MonsterRegenTimer>(game_address);            
            assert!(regen_timer.last_killed_time_type_2 < now_second, ENOT_READY_END);
            let win = dungeons::intermediate(token_id_1_str, is_hero, monster_type, resource_account_address);
            if(win) {
                let regen_timer = borrow_global_mut<MonsterRegenTimer>(game_address);
                let prize_war = utils::random_with_nonce(resource_account_address, 10, token_id_1_str) + 1; // 1~50
                if(monster_type == 4) {
                    prize_war = prize_war + 10;
                };
                regen_timer.last_killed_time_type_2 = timestamp::now_seconds() + MINIMUM_REGEN_TIME_B;
                let coins = coin::withdraw<WarCoinType>(&resource_signer, prize_war * WAR_COIN_DECIMAL);                
                coin::deposit(sender_addr, coins);                
                if(prize_war < 3) {                    
                    let creator_potion = @item_now_creator;                    
                    let token_id_1 = token::create_token_id_raw(creator_potion, string::utf8(POTION_COLLECTION_NAME), string::utf8(POTION_D), 0); 
                    let token = token::withdraw_token(&resource_signer, token_id_1, 1);
                    token::deposit_token(sender, token);
                };
                event::emit_event(&mut game_events.monster_killed_events, MonsterKilledEvent { 
                    killed_time: now_second,
                    killer: sender_addr,
                    monster_type: monster_type
                });
                event::emit_event(&mut game_events.dungeon_result_events, GameResultDungeonEvent {            
                    win: true,
                    battle_time:now_second,
                    earn: prize_war * WAR_COIN_DECIMAL,
                    death:false
                });
                item_material_drop(sender, string::utf8(MATERIAL_B), 60);
            } else {
                event::emit_event(&mut game_events.dungeon_result_events, GameResultDungeonEvent {            
                    win: false,
                    battle_time:now_second,
                    earn:0,
                    death:false
                });
                item_material_drop(sender, string::utf8(MATERIAL_H), 30);            
            };            
        };
        // advanced 1 1 - 30
        if(token_id_1_str >= 100 && token_id_1_str <= 400) {
            assert!(monster_type > 4, error::permission_denied(ENOT_AUTHORIZED));
            assert!(monster_type <= 7, error::permission_denied(ENOT_AUTHORIZED));
            let coins = coin::withdraw<WarCoinType>(sender, WAR_COIN_DECIMAL * 3);        
            coin::deposit(signer::address_of(&resource_signer), coins);
            let regen_timer = borrow_global_mut<MonsterRegenTimer>(game_address);            
            assert!(regen_timer.last_killed_time_type_3 < now_second, ENOT_READY_END);
            let win = dungeons::advanced(token_id_1_str, is_hero, monster_type, resource_account_address);
            if(win) {
                let regen_timer = borrow_global_mut<MonsterRegenTimer>(game_address);
                let prize_war = utils::random_with_nonce(resource_account_address, 20, token_id_1_str) + 1; // 1~200
                if(monster_type == 6) {
                    prize_war = prize_war + 6;                    
                };
                if(monster_type == 7) {
                    prize_war = prize_war + 10;                    
                };
                regen_timer.last_killed_time_type_3 = timestamp::now_seconds() + MINIMUM_REGEN_TIME_C;                
                let coins = coin::withdraw<WarCoinType>(&resource_signer, prize_war * WAR_COIN_DECIMAL);                
                coin::deposit(sender_addr, coins);
                if(monster_type == 7) // honored dradon slayer 
                {                    
                    
                    let mutate_setting = vector<bool>[ true, true, true ];                    
                    let mutability_config = &vector<bool>[ false, true, true, true, true ];
                    let uri = b"https://werewolfandwitch-mainnet.s3.ap-northeast-2.amazonaws.com/dungeon-json/achievement/dragon-slayer-medal.json";
                    let description = b"It is an honor bestowed upon the one who hunts a dragon first";
                    let token_name = b"DRAGON SLAYER NFT";                    
                    if(!token::check_collection_exists(resource_account_address, string::utf8(DRAGON_SLAYER_HONOR_NFT))) {
                        token::create_collection(&resource_signer, string::utf8(DRAGON_SLAYER_HONOR_NFT), string::utf8(description), string::utf8(uri), 1000, mutate_setting);
                    };
                    if(!token::check_tokendata_exists(resource_account_address, string::utf8(DRAGON_SLAYER_HONOR_NFT), string::utf8(token_name))) {
                        let token_data_id = token::create_tokendata(
                                &resource_signer,
                                string::utf8(DRAGON_SLAYER_HONOR_NFT),
                                string::utf8(token_name),
                                string::utf8(description),
                                1, // 1 maximum for NFT 
                                string::utf8(uri),
                                sender_addr, // royalty fee to                
                                FEE_DENOMINATOR,
                                2000, // Numerator
                                // we don't allow any mutation to the token
                                token::create_token_mutability_config(mutability_config),
                                // type
                                vector<String>[string::utf8(BURNABLE_BY_OWNER),string::utf8(TOKEN_PROPERTY_MUTABLE)],  // property_keys                
                                vector<vector<u8>>[bcs::to_bytes<bool>(&true),bcs::to_bytes<bool>(&true)],  // values 
                                vector<String>[string::utf8(b"bool"), string::utf8(b"bool")],
                        );
                        let token_id = token::mint_token(&resource_signer, token_data_id, 1);
                        token::opt_in_direct_transfer(sender, true);
                        token::direct_transfer(&resource_signer, sender, token_id, 1);
                    };                      
                };
                event::emit_event(&mut game_events.monster_killed_events, MonsterKilledEvent { 
                    killed_time: timestamp::now_seconds(),
                    killer: sender_addr,
                    monster_type: monster_type
                });
                event::emit_event(&mut game_events.dungeon_result_events, GameResultDungeonEvent {            
                    win: true,
                    battle_time:now_second,
                    earn: prize_war * WAR_COIN_DECIMAL,
                    death:false
                });
                item_material_drop(sender, string::utf8(MATERIAL_C), 60);
            } else {
                item_material_drop(sender, string::utf8(MATERIAL_F), 10);
                event::emit_event(&mut game_events.dungeon_result_events, GameResultDungeonEvent {            
                    win: false,
                    battle_time:now_second,
                    earn:0,
                    death:false
                });
            };            
                        
        };

        // advanced 2 1-40
        if(token_id_1_str > 400 && token_id_1_str <= 600) {
            assert!(monster_type >= 8, error::permission_denied(ENOT_AUTHORIZED));
            assert!(monster_type <= 9, error::permission_denied(ENOT_AUTHORIZED));
            let coins = coin::withdraw<WarCoinType>(sender, WAR_COIN_DECIMAL * 4); // pay 4 WAR COIN  
            coin::deposit(signer::address_of(&resource_signer), coins);
            let regen_timer = borrow_global_mut<MonsterRegenTimer>(game_address);            
            assert!(regen_timer.last_killed_time_type_4 < now_second, ENOT_READY_END);
            let win = dungeons::advanced_2(token_id_1_str, is_hero, monster_type, resource_account_address);
            if(win) {
                let regen_timer = borrow_global_mut<MonsterRegenTimer>(game_address);
                let prize_war = utils::random_with_nonce(resource_account_address, 34, token_id_1_str) + 1; // 1~200
                if(monster_type == 9) {
                    prize_war = prize_war + 6;                    
                };                
                regen_timer.last_killed_time_type_4 = timestamp::now_seconds() + MINIMUM_REGEN_TIME_D;                
                let coins = coin::withdraw<WarCoinType>(&resource_signer, prize_war * WAR_COIN_DECIMAL);                
                coin::deposit(sender_addr, coins);                
                event::emit_event(&mut game_events.monster_killed_events, MonsterKilledEvent { 
                    killed_time: timestamp::now_seconds(),
                    killer: sender_addr,
                    monster_type: monster_type
                });
                event::emit_event(&mut game_events.dungeon_result_events, GameResultDungeonEvent {            
                    win: true,
                    battle_time:now_second,
                    earn: prize_war * WAR_COIN_DECIMAL,
                    death:false
                });
                item_material_drop(sender, string::utf8(MATERIAL_D), 60);
            } else {
                event::emit_event(&mut game_events.dungeon_result_events, GameResultDungeonEvent {            
                    win: false,
                    battle_time:now_second,
                    earn:0,
                    death:false
                });
                item_material_drop(sender, string::utf8(MATERIAL_G), 20);
            };            
                        
        };
        // advanced 3 // 1~50
        if(token_id_1_str > 600) {
            assert!(monster_type >= 10, error::permission_denied(ENOT_AUTHORIZED));
            assert!(monster_type <= 11, error::permission_denied(ENOT_AUTHORIZED));
            let coins = coin::withdraw<WarCoinType>(sender, WAR_COIN_DECIMAL * 5); // pay 5 WAR COIN  
            coin::deposit(signer::address_of(&resource_signer), coins);
            let regen_timer = borrow_global_mut<MonsterRegenTimer>(game_address);            
            assert!(regen_timer.last_killed_time_type_5 < now_second, ENOT_READY_END);
            let win = dungeons::advanced_3(token_id_1_str, is_hero, monster_type, resource_account_address);
            if(win) {
                let regen_timer = borrow_global_mut<MonsterRegenTimer>(game_address);
                let prize_war = utils::random_with_nonce(resource_account_address, 45, token_id_1_str) + 1;
                if(monster_type == 11) {
                    prize_war = prize_war + 5;                    
                };                
                regen_timer.last_killed_time_type_5 = timestamp::now_seconds() + MINIMUM_REGEN_TIME_E;                
                let coins = coin::withdraw<WarCoinType>(&resource_signer, prize_war * WAR_COIN_DECIMAL);                
                coin::deposit(sender_addr, coins);                
                event::emit_event(&mut game_events.monster_killed_events, MonsterKilledEvent { 
                    killed_time: timestamp::now_seconds(),
                    killer: sender_addr,
                    monster_type: monster_type
                });
                event::emit_event(&mut game_events.dungeon_result_events, GameResultDungeonEvent {            
                    win: true,
                    battle_time:now_second,
                    earn: prize_war * WAR_COIN_DECIMAL,
                    death:false
                });
                item_material_drop(sender, string::utf8(MATERIAL_E), 30);
            } else {
                event::emit_event(&mut game_events.dungeon_result_events, GameResultDungeonEvent {            
                    win: false,
                    battle_time:now_second,
                    earn:0,
                    death:false
                });
                item_material_drop(sender, string::utf8(MATERIAL_F), 30);
            };            
                        
        };
    }

    entry fun exploration<WarCoinType> (
        sender: &signer, game_address:address,
        creator:address, name_1: String, property_version_1: u64, exploration_type: u64 // 1~2
    ) acquires WarGame {        
        let coin_address = coin_address<WarCoinType>();
        assert!(creator == @season_now_creator, error::permission_denied(ENOT_AUTHORIZED_CREATOR));
        assert!(coin_address == @war_coin, error::permission_denied(ENOT_AUTHORIZED));        
        let minter = borrow_global<WarGame>(game_address);        
        assert!(minter.is_on_game, error::permission_denied(EONGOING_GAME));                
        let resource_signer = get_resource_account_cap(game_address);                
        // let resource_account_address = signer::address_of(&resource_signer);        
        let sender_addr = signer::address_of(sender);
        // let game_events = borrow_global_mut<GameEvents>(game_address);        
        // entrance fee = 1WAR Coin
        assert!(coin::balance<WarCoinType>(sender_addr) >= WAR_COIN_DECIMAL, error::invalid_argument(ENO_SUFFICIENT_FUND));
        let token_id_1 = token::create_token_id_raw(creator, string::utf8(WEREWOLF_AND_WITCH_COLLECTION), name_1, property_version_1);            
        let pm = token::get_property_map(signer::address_of(sender), token_id_1);
        let (_is_wolf_1, token_id_1_str, _is_hero) = get_pm_properties(pm);
        if (token_id_1_str < 50) {            
            // entrance fee
            assert!(exploration_type == 1, error::permission_denied(ENOT_AUTHORIZED));
            let coins = coin::withdraw<WarCoinType>(sender, WAR_COIN_DECIMAL);        
            coin::deposit(signer::address_of(&resource_signer), coins);            
            let random = utils::random_with_nonce(sender_addr, 100, timestamp::now_seconds()) + 1;
            let win = if(random < 45) { true } else { false };
            if(win) {
                if(random < 5) {
                    item_material_drop(sender, string::utf8(MATERIAL_H), 5);
                } else {
                    item_material_drop(sender, string::utf8(MATERIAL_G), 5);
                };
                let coins = coin::withdraw<WarCoinType>(&resource_signer, 2 * WAR_COIN_DECIMAL);                
                coin::deposit(sender_addr, coins);                
            }
        };
        if(token_id_1_str >= 50) {            
            // entrance fee
            assert!(exploration_type == 2, error::permission_denied(ENOT_AUTHORIZED));
            let coins = coin::withdraw<WarCoinType>(sender, WAR_COIN_DECIMAL * 2);        
            coin::deposit(signer::address_of(&resource_signer), coins);
            let random = utils::random_with_nonce(sender_addr, 100, timestamp::now_seconds()) + 1;
            let win = if(random < 45) { true } else { false };
            if(win) {
                if(random < 5) {
                    item_material_drop(sender, string::utf8(MATERIAL_J), 5);
                } else {
                    item_material_drop(sender, string::utf8(MATERIAL_I), 5);
                };                
                let coins = coin::withdraw<WarCoinType>(&resource_signer, 4 * WAR_COIN_DECIMAL);                
                coin::deposit(sender_addr, coins);                
            }
        };                
    }

    fun item_material_drop (sender: &signer, token_name:String, drop_rate:u64) {
        let sender_addr = signer::address_of(sender);
        let random = utils::random_with_nonce(sender_addr, 100, timestamp::now_seconds()) + 1; // 1~100
        if(random <= drop_rate) {
            item_materials::mint_item_material(
                sender,
                token_name                     
            )
        };
        // let items = vector<String>[
        //     string::utf8(b"Glimmering Crystals"), string::utf8(b"Ethereal Essence"),
        //     string::utf8(b"Dragon Scale"), string::utf8(b"Celestial Dust"),
        //     string::utf8(b"Essence of the Ancients"), string::utf8(b"Phoenix Feather"),
        //     string::utf8(b"Moonstone Ore"), string::utf8(b"Enchanted Wood"),
        //     string::utf8(b"Kraken Ink"), string::utf8(b"Elemental Essence"),
        // ];        
        // let selected_item;        
        // let ind = 0;
        // while (ind < vector::length(&items)) {
        //     let item = *vector::borrow(&items, ind);
        //     if (token_name == item) {
        //         selected_item = item;                
        //     };
        //     ind = ind + 1;
        // };
    }

    // item equip / unequip

    entry fun item_equip(
        sender: &signer, game_address:address, contract_address:address,
        fighter_token_name: String, fighter_collection_name:String, fighter_creator:address,fighter_property_version:u64,
        owner: address, item_token_name:String, item_collection_name:String, item_creator:address, item_property_version:u64
        ) acquires WarGame { 
        
        assert!(fighter_creator == @season_now_creator, error::permission_denied(ENOT_AUTHORIZED_CREATOR));
        let holder_addr = signer::address_of(sender);
        let resource_signer = get_resource_account_cap(game_address);
        let fight_token_id = token::create_token_id_raw(fighter_creator, fighter_collection_name, fighter_token_name, fighter_property_version);
        // check holding
        let token = token::withdraw_token(sender, fight_token_id, 1);
        token::deposit_token(sender, token);

        let item_token_id = token::create_token_id_raw(item_creator, item_collection_name, item_token_name, item_property_version);
        // get item property
        
        let pm = token::get_property_map(holder_addr, item_token_id);
        let level = property_map::read_u64(&pm, &string::utf8(ITEM_LEVEL));
        let default_str = property_map::read_u64(&pm, &string::utf8(ITEM_DEFAULT_STR));

        token::mutate_one_token(            
            &resource_signer,
            holder_addr,
            fight_token_id,            
            vector<String>[string::utf8(IS_EQUIP), string::utf8(ITEM_LEVEL), string::utf8(ITEM_DEFAULT_STR)],  // property_keys                
            vector<vector<u8>>[bcs::to_bytes<bool>(&true), bcs::to_bytes<u64>(&level),bcs::to_bytes<u64>(&default_str)],  // values 
            vector<String>[string::utf8(b"bool"),string::utf8(b"u64"),string::utf8(b"u64")],      // type
        );
        // get item properties        
        item_equip::item_equip(
            sender, contract_address,
            fighter_token_name, fighter_collection_name, fighter_creator,
            owner, item_token_name, item_collection_name, item_creator, item_property_version                     
        )                
    }    

    entry fun item_unequip(
        sender: &signer, game_address:address, contract_address:address,
        fighter_token_name: String, fighter_collection_name:String, fighter_creator:address, fighter_property_version:u64,
        owner: address, item_token_name:String, item_collection_name:String, item_creator:address, item_property_version:u64
        ) acquires WarGame { 
        assert!(fighter_creator == @season_now_creator, error::permission_denied(ENOT_AUTHORIZED_CREATOR));
        let holder_addr = signer::address_of(sender);
        let resource_signer = get_resource_account_cap(game_address);
        let fight_token_id = token::create_token_id_raw(fighter_creator, fighter_collection_name, fighter_token_name, fighter_property_version);                        
        // check holding
        let token = token::withdraw_token(sender, fight_token_id, 1);
        token::deposit_token(sender, token);

        token::mutate_one_token(            
            &resource_signer,
            holder_addr,
            fight_token_id,            
            vector<String>[string::utf8(IS_EQUIP)],  // property_keys                
            vector<vector<u8>>[bcs::to_bytes<bool>(&false)],  // values 
            vector<String>[string::utf8(b"bool")],      // type
        );
        item_equip::item_unequip(
            sender, contract_address,
            fighter_token_name, fighter_collection_name, fighter_creator,
            owner, item_token_name, item_collection_name, item_creator, item_property_version                    
        )                               
    }
    
}
