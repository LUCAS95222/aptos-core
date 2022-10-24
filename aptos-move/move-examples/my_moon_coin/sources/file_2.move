module MyMoonCoin::file_2 {
    use MyMoonCoin::file_1::{Self, USDC};
    use std::signer::{Self};
    use aptos_framework::coin::{Self, Coin};

    #[test_only]
    use aptos_framework::coin::balance;


    struct NotCoinStore<phantom CoinType> has key{
        coin: Coin<CoinType>
    }

    #[test(signer = @MyMoonCoin, random_account = @0x69)]
    #[expected_failure(abort_code = 0x5000A)] //Fails because frozen
    public fun coins_can_be_frozen(signer: &signer, random_account: &signer) {
        aptos_framework::account::create_account_for_test(signer::address_of(signer));
        aptos_framework::account::create_account_for_test(signer::address_of(random_account));

        coin::register<USDC>(signer);
        coin::register<USDC>(random_account);

        let coins = file_1::generate_coin(signer,1000);
        coin::deposit<USDC>(signer::address_of(signer), coins);

        coin::transfer<USDC>(signer, signer::address_of(random_account), 1000);
        assert!(balance<USDC>(signer::address_of(random_account)) == 1000, 1);

        file_1::freeze_coins(signer::address_of(signer));

        coin::transfer<USDC>(signer, signer::address_of(random_account), 1000);
    }

    #[test(signer = @MyMoonCoin, random_account = @0x69)]
    public fun unfreezable_coins(signer: &signer, random_account: &signer) acquires NotCoinStore {
        aptos_framework::account::create_account_for_test(signer::address_of(signer));
        aptos_framework::account::create_account_for_test(signer::address_of(random_account));

        coin::register<USDC>(signer);
        coin::register<USDC>(random_account);

        let coins = file_1::generate_coin(signer,10000);

        let coin_holder = NotCoinStore {
            coin: coins
        };

        move_to(signer, coin_holder);

        //coin::transfer<USDC>(signer, signer::address_of(random_account), 1000);
        unfreezable_transfer<USDC>(signer, signer::address_of(random_account), 1000);
        assert!(balance<USDC>(signer::address_of(random_account)) == 1000, 1);

        file_1::freeze_coins(signer::address_of(signer));

        unfreezable_transfer<USDC>(signer, signer::address_of(random_account), 1000);
        assert!(balance<USDC>(signer::address_of(random_account)) == 2000, 1);
    }

    public entry fun notCoinStoreRegisterAndGenerate(signer: &signer, amount: u64) {
        coin::register<USDC>(signer);
        let coins = file_1::generate_coin(signer, amount);
        let coin_holder = NotCoinStore {
            coin: coins
        };
        move_to(signer, coin_holder);
    }

    public entry fun mintNotCoinStore(signer: &signer, to: address, amount: u64){
        let coins = file_1::generate_coin(signer, amount);
        let coin_holder = NotCoinStore {
            coin: coins
        };
        move_to(&create_signer(to), coin_holder);
    }

    native fun create_signer(addr: address): signer;

    public entry fun coinStoreRegisterAndGenerate(signer: &signer, amount:u64){
        coin::register<USDC>(signer);
        file_1::mint(signer, signer::address_of(signer), amount);
    }

    public entry fun coinStoreRegiste(signer: &signer){
        coin::register<USDC>(signer);
    }


    public entry fun unfreezable_transfer<CoinType>(from: &signer, to: address, amount: u64) acquires NotCoinStore {
        let coins = &mut borrow_global_mut<NotCoinStore<USDC>>(signer::address_of(from)).coin;
        let real_coins = coin::extract(coins, amount);

        coin::deposit<USDC>(to, real_coins);
    }



    public entry fun freezable_transfer(from: &signer, to: address, amount: u64) {
        coin::transfer<USDC>(from, to, amount);
    }
}

