
module nft_war::utils {    
    use std::bcs;
    use std::string::{Self, String};
    use std::vector;    
    use aptos_std::from_bcs;
    use std::hash;

    // use aptos_framework::block;
    use aptos_framework::transaction_context;
    use aptos_framework::timestamp;
    use aptos_token::token::{Self, TokenId, TokenDataId};
        
    public fun average(a: u64, b: u64): u64 {
        if (a < b) {
            a + (b - a) / 2
        } else {
            b + (a - b) / 2
        }
    }

    public fun token_mint_and_transfer (
        resource_signer: signer, receiver: &signer, token_data_id:TokenDataId
    ): TokenId { 
        let token_id = token::mint_token(&resource_signer, token_data_id, 1);
        token::opt_in_direct_transfer(receiver, true);
        token::direct_transfer(&resource_signer, receiver, token_id, 1);
        token_id
    }

    public fun to_string(value: u128): String {
        if (value == 0) {
            return string::utf8(b"0")
        };
        let buffer = vector::empty<u8>();
        while (value != 0) {
            vector::push_back(&mut buffer, ((48 + value % 10) as u8));
            value = value / 10;
        };
        vector::reverse(&mut buffer);
        string::utf8(buffer)
    }    

    public fun random(add:address, max:u64):u64
    {                
        let number = timestamp::now_microseconds();
        let script_hash: vector<u8> = transaction_context::get_script_hash();
        let x = bcs::to_bytes<address>(&add);        
        let z = bcs::to_bytes<u64>(&number);
        vector::append(&mut x,script_hash);           
        vector::append(&mut x, z);
        let tmp = hash::sha2_256(x);

        let data = vector<u8>[];
        let i =24;
        while (i < 32)
        {
            let x =vector::borrow(&tmp,i);
            vector::append(&mut data,vector<u8>[*x]);
            i= i+1;
        };
        let random = from_bcs::to_u64(data) % max;
        random
    }

    public fun random_with_nonce(add:address, max:u64, nonce:u64):u64
    {                        
        let number = timestamp::now_microseconds();
        let script_hash: vector<u8> = transaction_context::get_script_hash();
        let x = bcs::to_bytes<address>(&add);        
        let z = bcs::to_bytes<u64>(&number);
        let y = bcs::to_bytes<u64>(&nonce);
        vector::append(&mut x,script_hash);           
        vector::append(&mut x, z);
        vector::append(&mut x, y);
        let tmp = hash::sha2_256(x);

        let data = vector<u8>[];
        let i =24;
        while (i < 32)
        {
            let x =vector::borrow(&tmp,i);
            vector::append(&mut data,vector<u8>[*x]);
            i= i+1;
        };
        let random = from_bcs::to_u64(data) % max;
        random
    }    
}
