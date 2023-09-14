
# NFT War Game based on move smart contract
## Aptos hackathon project in Seoul hackathon

- Live: [werewolfandwitch.xyz](https://werewolfandwitch.xyz/)
- Twitter: [Werewolf and witch](https://twitter.com/AWW_xyz)

## move functions
1. init_game  - init for move events / stores
2. create_game - set up games 
3. admin_withdraw - add more prize for fun
4. admin_deposit - get funds 
5. listing_battle 
6. delisting_battle 
7. battle
8. end_game
9. withdraw_prize
10. mint_token
11. burn_token_and_enhance

## Cloning the repository
```git clone https://github.com/werewolfandwitch/aptos-werewolfandwitch.git```

## Initialize
Initialize with ```aptos init``` in the ```aptos-werewolfandwitch``` folder you just cloned

## Compile
```aptos move compile --named-addresses nft_war=default```

## Publish
```aptos move publish --named-addresses nft_war=default```


License
=======

    Copyright 2023 Werewolf and Witch

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.


