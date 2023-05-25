
module nft_war::dungeons {                

    use nft_war::utils;
    
    // 1 : 15, 2: 40, 3: 60, 4: 80, 5: 200, 6: 999
    const MONSTER_STRENGTH_1:u64 = 15;
    const MONSTER_STRENGTH_2:u64 = 45;
    const MONSTER_STRENGTH_3:u64 = 75;
    const MONSTER_STRENGTH_4:u64 = 95;
    const MONSTER_STRENGTH_5:u64 = 300;
    const MONSTER_STRENGTH_6:u64 = 600;
    const MONSTER_STRENGTH_7:u64 = 999;
        
    public fun beginner(str:u64, is_hero:bool,dungeon_type: u64, resource_account_address:address): bool {                
        assert!(str < 50,1);
        let random = utils::random_with_nonce(resource_account_address, 1000, MONSTER_STRENGTH_1) + 1; // 1~1000
        let fight_str = if (is_hero) { str + 5 } else { str };
        let diff;        
        let win_rate;
        let result = false;
        if(dungeon_type == 1) {
            diff = if (fight_str > MONSTER_STRENGTH_1) { fight_str - MONSTER_STRENGTH_1 } else { MONSTER_STRENGTH_1 - fight_str };
            let diff_multi = diff * 10;
            if(diff_multi > 450) {
                diff_multi = 450;
            };
            win_rate = if (fight_str > MONSTER_STRENGTH_1) { 500 + diff_multi } else { 500 - diff_multi };             
            result = if(random <= win_rate) { true } else { false };            
        };

        if(dungeon_type == 2) {
            diff = if (fight_str > MONSTER_STRENGTH_2) { fight_str - MONSTER_STRENGTH_2 } else { MONSTER_STRENGTH_2 - fight_str };
            let diff_multi = diff * 10;
            if(diff_multi > 450) {
                diff_multi = 450;
            };
            win_rate = if (fight_str > MONSTER_STRENGTH_2) { 500 + diff_multi } else { 500 - diff_multi };             
            result = if(random <= win_rate) { true } else { false };            
        };
        result     
    }
    

    // Intermediate Strength 50 ~ 100

    public fun intermediate(str:u64, is_hero:bool, dungeon_type: u64, resource_account_address:address) : bool {                
        assert!(str >= 50,1);
        assert!(str < 100,1);
       let random = utils::random_with_nonce(resource_account_address, 1000, MONSTER_STRENGTH_3) + 1; // 1~1000
        let fight_str = if (is_hero) { str + 15 } else { str };        
        let diff;        
        let win_rate;
        let result = false;
        if(dungeon_type == 3) {
            diff = if (fight_str > MONSTER_STRENGTH_3) { fight_str - MONSTER_STRENGTH_3 } else { MONSTER_STRENGTH_3 - fight_str };
            let diff_multi = diff * 5;
            if(diff_multi > 450) {
                diff_multi = 450;
            };
            win_rate = if (fight_str > MONSTER_STRENGTH_3) { 500 + diff_multi } else { 500 - diff_multi };             
            result = if(random <= win_rate) { true } else { false };            
        };

        if(dungeon_type == 4) {
            diff = if (fight_str > MONSTER_STRENGTH_4) { fight_str - MONSTER_STRENGTH_4 } else { MONSTER_STRENGTH_4 - fight_str };
            let diff_multi = diff * 5;
            if(diff_multi > 450) {
                diff_multi = 450;
            };
            win_rate = if (fight_str > MONSTER_STRENGTH_4) { 500 + diff_multi } else { 500 - diff_multi };             
            result = if(random <= win_rate) { true } else { false };            
        };
        result         
    }

    // Advanced Strength  +100

    public fun advanced(str:u64, is_hero:bool,  dungeon_type: u64, resource_account_address:address) : bool {                        
        assert!(str >= 100, 1);
        let random = utils::random_with_nonce(resource_account_address, 1000, MONSTER_STRENGTH_5) + 1; // 1~1000
        let fight_str = if (is_hero) { str * 2 } else { str };        
        let diff;        
        let win_rate;
        let result = false;
        if(dungeon_type == 5) {
            diff = if (fight_str > MONSTER_STRENGTH_5) { fight_str - MONSTER_STRENGTH_5 } else { MONSTER_STRENGTH_5 - fight_str };
            let diff_multi = diff * 2;
            if(diff_multi > 400) {
                diff_multi = 400;
            };
            win_rate = if (fight_str > MONSTER_STRENGTH_5) { 500 + diff_multi } else { 500 - diff_multi };             
            result = if(random <= win_rate) { true } else { false };            
        };

        if(dungeon_type == 6) {
            diff = if (fight_str > MONSTER_STRENGTH_6) { fight_str - MONSTER_STRENGTH_6 } else { MONSTER_STRENGTH_6 - fight_str }; 
            let diff_multi = diff;
            if(diff_multi > 400) {
                diff_multi = 400;
            };
            win_rate = if (fight_str > MONSTER_STRENGTH_6) { 500 + diff_multi } else { 500 - diff_multi };             
            result = if(random <= win_rate) { true } else { false };            
        };

        if(dungeon_type == 7) {
            diff = if (fight_str > MONSTER_STRENGTH_7) { fight_str - MONSTER_STRENGTH_7 } else { MONSTER_STRENGTH_7 - fight_str }; 
            let diff_multi = diff;
            if(diff_multi > 499) {
                diff_multi = 499;
            };
            win_rate = if (fight_str > MONSTER_STRENGTH_7) { 500 + diff_multi } else { 500 - diff_multi };             
            result = if(random <= win_rate) { true } else { false };            
        };
        result       
    }    
       
}
