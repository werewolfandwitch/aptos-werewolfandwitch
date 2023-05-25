
module nft_war::lands {    
    use std::bcs;
    use std::signer;    
    use std::string::{Self, String};    
    
    use aptos_token::token::{Self};    

    const BURNABLE_BY_CREATOR: vector<u8> = b"TOKEN_BURNABLE_BY_CREATOR";    
    const BURNABLE_BY_OWNER: vector<u8> = b"TOKEN_BURNABLE_BY_OWNER";
    const TOKEN_PROPERTY_MUTABLE: vector<u8> = b"TOKEN_PROPERTY_MUTATBLE";    

    const FEE_DENOMINATOR: u64 = 100000;
    

    // collection name
    const LAND_COLLECTION_NAME:vector<u8> = b"LAND TOKEN COLLECTION";
    // property for game
    const IS_LAND: vector<u8> = b"W_TOKEN_LAND";

    const LAND_A: vector<u8> = b"Castle Ruins";
    const LAND_B: vector<u8> = b"Dark Forest";
    const LAND_C: vector<u8> = b"Sacred Grove";
    const LAND_D: vector<u8> = b"Twisted Forest";

    
    public entry fun create_land<CoinType> (
        _sender: &signer,        
        description: String, 
        collection_uri: String, maximum_supply: u64, mutate_setting: vector<bool>
        ) {                                             
        token::create_collection(_sender, string::utf8(LAND_COLLECTION_NAME), description, collection_uri, maximum_supply, mutate_setting);
    }

    public entry fun mint_land<CoinType> (
        sender: &signer, token_name: String, royalty_points_numerator:u64,token_description:String, collection_uri:String, max_amount:u64, amount:u64
    ) {
        
        let creator_address = signer::address_of(sender);        
        let mutability_config = &vector<bool>[ true, true, false, true, true ];              
        let token_data_id = token::create_tokendata(
                sender,
                string::utf8(LAND_COLLECTION_NAME),
                token_name,
                token_description,
                max_amount, // 1 maximum for NFT 
                collection_uri,
                creator_address, // royalty fee to                
                FEE_DENOMINATOR,
                royalty_points_numerator,
                // we don't allow any mutation to the token
                token::create_token_mutability_config(mutability_config),
                // type
                vector<String>[string::utf8(BURNABLE_BY_OWNER),string::utf8(TOKEN_PROPERTY_MUTABLE),string::utf8(IS_LAND)],  // property_keys                
                vector<vector<u8>>[bcs::to_bytes<bool>(&true),bcs::to_bytes<bool>(&false), bcs::to_bytes<bool>(&true) ],  // values 
                vector<String>[string::utf8(b"bool"),string::utf8(b"bool"), string::utf8(b"bool")],
        );
        let token_id = token::mint_token(sender, token_data_id, amount);
        token::opt_in_direct_transfer(sender, true);
        token::direct_transfer(sender, sender, token_id, 1);        
    }  
}
