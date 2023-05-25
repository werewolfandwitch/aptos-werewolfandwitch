
module nft_war::potion {    
    use std::bcs;
    use std::signer;    
    use std::string::{Self, String};    
        
    use aptos_token::token::{Self};    


    const BURNABLE_BY_CREATOR: vector<u8> = b"TOKEN_BURNABLE_BY_CREATOR";    
    const BURNABLE_BY_OWNER: vector<u8> = b"TOKEN_BURNABLE_BY_OWNER";
    const TOKEN_PROPERTY_MUTABLE: vector<u8> = b"TOKEN_PROPERTY_MUTATBLE";    
    const FEE_DENOMINATOR: u64 = 100000;
    

    const POTION_COLLECTION_NAME:vector<u8> = b"POTION TOKEN COLLECTION";
    // property for game
    const IS_POTION:vector<u8> = b"W_TOKEN_POTION";
    const POTION_TYPE:vector<u8> = b"W_POTION_TYPE";

    const POTION_A: vector<u8> = b"POTION A"; // 6 
    const POTION_B: vector<u8> = b"POTION B"; // 8
    const POTION_C: vector<u8> = b"POTION C"; // 10    
    
    public entry fun create_potion_collection<CoinType> (
        sender: &signer,        
        description: String, 
        collection_uri: String, maximum_supply: u64, mutate_setting: vector<bool>
        ) {                                             
        token::create_collection(sender, string::utf8(POTION_COLLECTION_NAME), description, collection_uri, maximum_supply, mutate_setting);                
    }

    public entry fun mint_potion<CoinType> (
        sender: &signer,        
        token_name: String,collection_uri:String, royalty_points_numerator:u64, token_description:String, potion_type:u64, max_amount:u64, amount:u64
    ) {        
        let creator_address = signer::address_of(sender);
        let mutability_config = &vector<bool>[ false, true, true, true, true ];              
        let token_data_id = token::create_tokendata(
                sender,
                string::utf8(POTION_COLLECTION_NAME),
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
                vector<String>[string::utf8(BURNABLE_BY_OWNER),string::utf8(TOKEN_PROPERTY_MUTABLE),string::utf8(POTION_TYPE),string::utf8(IS_POTION)],  // property_keys                
                vector<vector<u8>>[bcs::to_bytes<bool>(&true),bcs::to_bytes<bool>(&false), bcs::to_bytes<u64>(&potion_type), bcs::to_bytes<bool>(&true) ],  // values 
                vector<String>[string::utf8(b"bool"),string::utf8(b"bool"), string::utf8(b"u64"), string::utf8(b"bool")],
        );
        let token_id = token::mint_token(sender, token_data_id, amount);
        token::opt_in_direct_transfer(sender, true);
        token::direct_transfer(sender, sender, token_id, 1);        
    }
    
}
