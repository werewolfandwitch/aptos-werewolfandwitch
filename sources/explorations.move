
module nft_war::explorations {                

    use nft_war::utils;
    
    const ENOT_IN_RANGE_LEVEL:u64 = 1;    
    const MONSTER_STRENGTH_1:u64 = 15;
    const MONSTER_STRENGTH_2:u64 = 45;
    const MONSTER_STRENGTH_3:u64 = 75;
    const MONSTER_STRENGTH_4:u64 = 95;
        
    // public fun beginner(str:u64, is_hero:bool,dungeon_type: u64, resource_account_address:address): bool {                
    //     assert!(str < 50, ENOT_IN_RANGE_LEVEL);
           
    // }    

    // // Intermediate Strength 50 ~ 100

    // public fun intermediate(str:u64, is_hero:bool, dungeon_type: u64, resource_account_address:address) : bool {                
    //     assert!(str >= 50,ENOT_IN_RANGE_LEVEL);
    //     assert!(str < 100,ENOT_IN_RANGE_LEVEL);
                
    // }

    // // Advanced Strength  +100

    // public fun advanced(str:u64, is_hero:bool,  dungeon_type: u64, resource_account_address:address) : bool {                        
    //     assert!(str >= 100, ENOT_IN_RANGE_LEVEL);                     
    // }       
       
}
