#[test_only]
module QF::qf_tests {
    // use std::debug;
    use std::signer;
    use std::unit_test;
    use std::vector;
    use aptos_framework::aptos_account;
    use aptos_framework::aptos_coin::{Self, AptosCoin};
    use aptos_framework::coin;
    use aptos_framework::managed_coin::Self;

    use QF::qf;

    struct TestCoin {}

    fun setup_test_coin(
        minter: &signer,
        receiver: &signer,
        balance: u64
    ) {
        let minter_addr = signer::address_of(minter);
        let receiver_addr = signer::address_of(receiver);

        if (!coin::is_coin_initialized<TestCoin>()) {
            managed_coin::initialize<TestCoin>(
                minter,
                b"Test Coin",
                b"Test",
                8u8,
                true
            );
        };

        if (!coin::is_account_registered<TestCoin>(minter_addr)) {
            coin::register<TestCoin>(minter);
        };

        if (!coin::is_account_registered<TestCoin>(receiver_addr)) {
            coin::register<TestCoin>(receiver)
        };

        managed_coin::mint<TestCoin>(
            minter,
            receiver_addr,
            balance
        )
    }
    
    fun setup_aptos(
        aptos_framework: &signer,
        accounts: vector<address>,
        balances: vector<u64>
    ) {
        if (!coin::is_coin_initialized<AptosCoin>()) {
            let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);
            coin::destroy_mint_cap<AptosCoin>(mint_cap);
            coin::destroy_burn_cap<AptosCoin>(burn_cap);
        };

        assert!(vector::length(&accounts) == vector::length(&balances), 1);

        while (!vector::is_empty(&accounts)) {
            let account = vector::pop_back(&mut accounts);
            let balance = vector::pop_back(&mut balances);
            aptos_account::create_account(account);
            aptos_coin::mint(aptos_framework, account, balance);
        };
    }

    fun get_account(): signer {
        vector::pop_back(&mut unit_test::create_signers_for_testing(1))
    }

    #[test(
        aptos_framework = @aptos_framework,
        owner = @QF,
        operator = @0x123,
    )]
    fun initialize_should_work(
        aptos_framework: signer,
        owner: &signer,
        operator: &signer,
    ) {
        let operator_addr = signer::address_of(operator);
        let owner_addr = signer::address_of(owner);

        setup_aptos(
            &aptos_framework,
            vector<address>[operator_addr, owner_addr],
            vector<u64>[0, 0]
        );
        qf::initialize(owner, operator_addr);
        qf::check_operator(owner_addr, true);
        qf::check_operator(operator_addr, true);
        qf::check_operator(@0xEEE, false);
    }

    #[test(
        aptos_framework = @aptos_framework,
        owner = @QF,
        operator = @0x123,
        user = @0x456,
    )]
    fun withdraw_all_should_work(
        aptos_framework: signer,
        owner: &signer,
        operator: &signer,
        user: &signer,
    ) {
        let operator_addr = signer::address_of(operator);
        let owner_addr = signer::address_of(owner);
        let user_addr = signer::address_of(user);
        let round_id = 1;

        setup_aptos(
            &aptos_framework,
            vector<address>[operator_addr, owner_addr, user_addr],
            vector<u64>[100000000, 100000000, 100000000]
        );
        qf::initialize(owner, operator_addr);

        let voting_unit = 100000000;
        let tax_adjustment_multiplier =5;
        qf::start_round<AptosCoin>(operator, tax_adjustment_multiplier, voting_unit);

        let track_id = 1;
        qf::batch_upload_project(operator, round_id, track_id, vector<address>[@0x12345, @0x23456]);
        qf::batch_vote<AptosCoin>(user, round_id, vector<u64>[1], vector<u64>[160000]);
        qf::batch_vote<AptosCoin>(user, round_id, vector<u64>[1], vector<u64>[90000]);
        qf::batch_vote<AptosCoin>(user, round_id, vector<u64>[2], vector<u64>[160000]);
        qf::end_round(operator, round_id);

        let balance = qf::round_escrow_balance<AptosCoin>(round_id);
        assert!(balance == 410000, 1);

        let area = qf::round_area(round_id);
        assert!(area == 900, 1);

        qf::withdraw_all<AptosCoin>(operator, round_id);
        let new_balance = qf::round_escrow_balance<AptosCoin>(round_id);
        assert!(new_balance == 0, 1);
    }
}
