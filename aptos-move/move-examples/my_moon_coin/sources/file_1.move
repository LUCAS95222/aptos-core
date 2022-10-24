module MyMoonCoin::file_1 {

    use aptos_framework::coin::{Coin};
    use std::signer;
    use std::string::{utf8};

    struct Authorities<phantom CoinType> has key {
        burn_cap: BurnCapability<CoinType>,
        freeze_cap: FreezeCapability<CoinType>,
        mint_cap: MintCapability<CoinType>,
    }
    use aptos_framework::coin::{Self, MintCapability, BurnCapability, FreezeCapability};

    struct USDC has key {
    }

    public entry fun generate_coin(signer_1: &signer, amount: u64): Coin<USDC> acquires Authorities {
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<USDC>(signer_1, utf8(b"hey"), utf8(b"b"), 8, false);
        let authorities = Authorities {
            burn_cap,
            freeze_cap,
            mint_cap
        };

        move_to<Authorities<USDC>>(signer_1, authorities);
        let mint_cap_ref = &borrow_global<Authorities<USDC>>(signer::address_of(signer_1)).mint_cap;
        let coins: Coin<USDC> = coin::mint<USDC>(amount, mint_cap_ref);
        coins
    }

    public entry fun generate_coin2(signer_1: &signer, amount: u64): Coin<USDC> acquires Authorities {
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<USDC>(signer_1, utf8(b"hey"), utf8(b"b"), 8, false);
        let authorities = Authorities {
            burn_cap,
            freeze_cap,
            mint_cap
        };

        move_to<Authorities<USDC>>(signer_1, authorities);
        let mint_cap_ref = &borrow_global<Authorities<USDC>>(signer::address_of(signer_1)).mint_cap;
        let coins: Coin<USDC> = coin::mint<USDC>(amount, mint_cap_ref);
        coins
    }

    public entry fun generate_coin3(signer_1: &signer, amount: u64)acquires Authorities {
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<USDC>(signer_1, utf8(b"hey"), utf8(b"b"), 8, false);
        let authorities = Authorities {
            burn_cap,
            freeze_cap,
            mint_cap
        };

        move_to<Authorities<USDC>>(signer_1, authorities);
        let mint_cap_ref = &borrow_global<Authorities<USDC>>(signer::address_of(signer_1)).mint_cap;
        let coins: Coin<USDC> = coin::mint<USDC>(amount, mint_cap_ref);
        coin::deposit<USDC>(signer::address_of(signer_1), coins);
    }


    public entry fun mint(signer:&signer, to: address, amount:u64)acquires Authorities {
        let mint_cap_ref = &borrow_global<Authorities<USDC>>(signer::address_of(signer)).mint_cap;
        let coins: Coin<USDC> = coin::mint<USDC>(amount, mint_cap_ref);
        coin::deposit<USDC>(to, coins);

    }

    public entry fun freeze_coins(person_1: address) acquires Authorities {
        let freeze_cap = &borrow_global<Authorities<USDC>>(person_1).freeze_cap;
        coin::freeze_coin_store<USDC>(person_1, freeze_cap);
    }

    public entry fun unfreeze_coins(person_1: address) acquires Authorities{
        let freeze_cap = &borrow_global<Authorities<USDC>>(person_1).freeze_cap;
        coin::unfreeze_coin_store(person_1, freeze_cap);
    }

    public entry fun burn_coins(person_1: address) acquires Authorities {
        let burn_cap = &borrow_global<Authorities<USDC>>(person_1).burn_cap;
        coin::burn_from<USDC>(person_1, 10000, burn_cap);
    }

}

