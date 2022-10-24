/// Quadratic Funding 
/// noodles@dorahacks.com
/// 2020-09-30
module QF::qf {
    friend QF::qf_tests;

    // use std::debug;
    use std::bcs;
    use std::error;
    use std::vector;
    use std::signer;    
    use std::string;
    use aptos_std::event;
    use aptos_std::type_info;
    use aptos_std::table::{Self, Table};
    use aptos_framework::coin;    
    use aptos_framework::account;

    use QF::math;

//:!:>const
    const ROUND_STATUS__OK: u64 = 0;
    const ROUND_STATUS__ENDED: u64 = 1;
    const ROUND_STATUS__WITHDRAWN: u64 = 2;

    const PROJECT_STATUS__OK: u64 = 0;
    const PROJECT_STATUS__BANNED: u64 = 1;
    const PROJECT_STATUS__WITHDRAWN: u64 = 2;

    const EVENT_TYPE__START_ROUND: u64 = 1;
    const EVENT_TYPE__DONATE: u64 = 2;
    const EVENT_TYPE__UPLOAD_PROJECT: u64 = 3;
    const EVENT_TYPE__VOTE: u64 = 4;
    const EVENT_TYPE__END_ROUND: u64 = 5;
    const EVENT_TYPE__WITHDRAW_GRANTS: u64 = 6;
    const EVENT_TYPE__WITHDRAW_FEE: u64 = 7;
    const EVENT_TYPE__BAN_PROJECT: u64 = 8;
    const EVENT_TYPE__WITHDRAW_ALL: u64 = 9;
    const EVENT_TYPE__SET_FUND: u64 = 10;
    const EVENT_TYPE__ADD_TRACK: u64 = 11;
//<:!:const

//:!:>error
    const ERR_PERMISSION_DENIED: u64 = 3000;
    const ERR_HAS_PUBLISHED: u64 = 3001;
    const ERR_NOT_PUBLISHED: u64 = 3002;
    const ERR_IS_NOT_COIN: u64 = 3003;
    const ERR_HAS_REGISTERED: u64 = 3004;
    const ERR_ROUND_STATUS_NOT_OK: u64 = 3005;
    const ERR_ROUND_STATUS_NOT_ENDED: u64 = 3006;
    const ERR_PROJECT_STATUS_NOT_OK: u64 = 3007;
    const ERR_INSUFFICIENT_BALANCES: u64 = 3008;
    const ERR_COIN_TYPE_MISMATCH: u64 = 3009;
    const ERR_INVALID_VOTING_UNIT: u64 = 3010;
    const ERR_VOTING_AMOUNT_TOO_SMALL: u64 = 3011;
    const ERR_INVALID_ROUND_ID: u64 = 3012;
    const ERR_INVALID_PROJECT_ID: u64 = 3013;
    const ERR_HACKER_NOT_IN_ROUND_WHITELIST: u64 = 3014;
    const ERR_PROJECT_NUMBER_NOT_MATCH: u64 = 3015;
    const ERR_INVALID_ARGUMENT: u64 = 3016;
//<:!:error

//:!:>resource
    struct Data has key {
        admin: address,
        rounds: vector<Round>,
        current_round: u64,
        events: event::EventHandle<QFEvent>,
    }

    struct Round has store {
        id: u64,
        owner: address,
        escrow_address: address,
        coin_type: string::String,
        tax_adjustment_multiplier: u64,
        voting_unit: u64,
        status: u64,
        fund: u64,
        project_number: u64,
        project_number_banned: u64,
        total_area: u64,
        top_area: u64,
        min_area: u64,
        min_area_index: u64,
        tracks: vector<Track>,
        projects: vector<Project>,
    }

    struct Track has store {
        id: u64,
        area: u64,
        project_number: u64,
        total_area: u64,
        top_area: u64,
        min_area: u64,
        min_area_index: u64,
    }

    struct Project has store {
        id: u64,
        track_id: u64,
        owner: address,
        area: u64,
        status: u64,
        votes: u64,
        contribution: u64,
        voters: Table<address, u64>,
    }

    struct Escrow<phantom CoinType> has key {
        coin: coin::Coin<CoinType>,
    }
//<:!:resource


//:!:>event
    struct QFEvent has drop, store {
        type: u64,
        account: address,
        round: u64,
        project: u64,
        amount: u64,
    }
//<:!:event

//:!:>helper
    public(friend) fun assert_is_coin<CoinType>() {
        assert!(coin::is_coin_initialized<CoinType>(), ERR_IS_NOT_COIN);
    }

    public(friend) fun merge_coin<CoinType>(
        resource: address,
        coin: coin::Coin<CoinType>
    ) acquires Escrow {
        let escrow = borrow_global_mut<Escrow<CoinType>>(resource);
        coin::merge(&mut escrow.coin, coin);
    }

    public(friend) fun check_operator(
        operator_address: address,
        require_admin: bool
    ) acquires Data {
        assert!(
            exists<Data>(@QF),
            error::already_exists(ERR_NOT_PUBLISHED),
        );
        assert!(
            !require_admin || admin() == operator_address || @QF == operator_address,
            error::permission_denied(ERR_PERMISSION_DENIED),
        );
    }

    public(friend) fun check_round_id(round_id: u64) acquires Data {
        assert!(
            round_id > 0 && round_id <= borrow_global<Data>(@QF).current_round,
            error::invalid_argument(ERR_INVALID_ROUND_ID),
        );
    }

    public(friend) fun check_project_id(round_id: u64, project_id: u64) acquires Data {
        check_round_id(round_id);
        let data = borrow_global<Data>(@QF);
        let round = vector::borrow(&data.rounds, round_id-1);
        assert!(
            project_id > 0 && project_id <= round.project_number,
            error::invalid_argument(ERR_INVALID_PROJECT_ID),
        );
    }

    public(friend) fun admin(): address acquires Data {
        borrow_global<Data>(@QF).admin
    }

    public(friend) fun upload_project(
        account_addr: address,
        round_id: u64,
        track_id: u64,
    ) acquires Data {
        let data = borrow_global_mut<Data>(@QF);
        let round = vector::borrow_mut(&mut data.rounds, round_id-1);
        assert!(
            round.status == ROUND_STATUS__OK,
            error::invalid_state(ERR_ROUND_STATUS_NOT_OK)
        );
        assert!(
            track_id > 0 && track_id <= vector::length(&round.tracks),
            error::invalid_argument(ERR_INVALID_ARGUMENT)
        );
        let id = round.project_number + 1;
        round.project_number = id;

        let track = vector::borrow_mut(&mut round.tracks, track_id-1);
        track.project_number = track.project_number + 1;

        let project = Project {
            id,
            track_id,
            owner: account_addr,
            area: 0,
            status: PROJECT_STATUS__OK,
            votes: 0,
            contribution: 0,
            voters: table::new(),
        };
        vector::push_back(&mut round.projects, project);

        event::emit_event(&mut data.events, QFEvent {
            type: EVENT_TYPE__UPLOAD_PROJECT,
            account: account_addr,
            round: round_id,
            project: round.project_number,
            amount: 0,
        });
    }

    #[test_only]
    public fun round_coin_type(round_id: u64): string::String acquires Data {
        let data = borrow_global<Data>(@QF);
        let round = vector::borrow(&data.rounds, round_id-1);
        round.coin_type
    }

    #[test_only]
    public fun round_project_number(round_id: u64): u64 acquires Data {
        let data = borrow_global<Data>(@QF);
        let round = vector::borrow(&data.rounds, round_id-1);
        round.project_number
    }

    #[test_only]
    public fun round_escrow_address(round_id: u64): address acquires Data {
        let data = borrow_global<Data>(@QF);
        let round = vector::borrow(&data.rounds, round_id-1);
        round.escrow_address
    }

    #[test_only]
    public fun round_escrow_balance<CoinType>(round_id: u64): u64 acquires Data, Escrow {
        let escrow_address = round_escrow_address(round_id);
        let escrow_coin = borrow_global<Escrow<CoinType>>(escrow_address);
        coin::value(&escrow_coin.coin)
    }

    #[test_only]
    public fun round_status(round_id: u64): u64 acquires Data {
        let data = borrow_global<Data>(@QF);
        let round = vector::borrow(&data.rounds, round_id-1);
        round.status
    }

    #[test_only]
    public fun round_area(round_id: u64): u64 acquires Data {
        let data = borrow_global<Data>(@QF);
        let round = vector::borrow(&data.rounds, round_id-1);
        round.total_area
    }

    #[test_only]
    public fun project_area(round_id: u64, project_id: u64): u64 acquires Data {
        check_project_id(round_id, project_id);
        let data = borrow_global<Data>(@QF);
        let round = vector::borrow(&data.rounds, round_id-1);
        let project = vector::borrow(&round.projects, project_id-1);
        project.area
    }
//<:!:helper

//:!:>publish
    /// Initialize the QF contract, set the admin address.
    public entry fun initialize(
        owner: &signer,
        admin: address,
    ) {
        let owner_addr = signer::address_of(owner);
        assert!(
            @QF == owner_addr,
            error::permission_denied(ERR_PERMISSION_DENIED),
        );
        assert!(
            !exists<Data>(@QF), 
            error::already_exists(ERR_HAS_PUBLISHED));

        move_to(
            owner,
            Data {
                admin,
                rounds: vector::empty<Round>(),
                current_round: 0,
                events: account::new_event_handle<QFEvent>(owner),
            }
        );
    }

    /// Create a new round.
    public entry fun start_round<CoinType>(
        admin: &signer,
        tax_adjustment_multiplier: u64,
        voting_unit: u64,
    ) acquires Data {
        let admin_addr = signer::address_of(admin);
        check_operator(admin_addr, true);
        assert_is_coin<CoinType>();

        let decimals = coin::decimals<CoinType>();
        assert!(
            voting_unit > 0 && voting_unit <= math::pow_10(decimals),
            error::invalid_argument(ERR_INVALID_VOTING_UNIT)
        );

        let data = borrow_global_mut<Data>(@QF);
        data.current_round = data.current_round + 1;

        let coin_type = type_info::type_name<CoinType>();
        let seed = *string::bytes(&coin_type);
        vector::append(&mut seed, bcs::to_bytes(&data.current_round));
        let (resource, _signer_cap) = account::create_resource_account(
            admin, 
            seed
        );
        assert!(
            !exists<Escrow<CoinType>>(signer::address_of(&resource)),
            error::already_exists(ERR_HAS_REGISTERED)
        );

        move_to(
            &resource,
            Escrow<CoinType> {
                coin: coin::zero<CoinType>()
            }
        );

        let tracks = vector::empty<Track>();
        let first_track = Track {
            id: 1,
            area: 0,
            project_number: 0,
            total_area: 0,
            top_area: 0,
            min_area: 0,
            min_area_index: 0,
        };
        vector::push_back(&mut tracks, first_track);

        let round = Round {
            id: data.current_round,
            owner: admin_addr,
            escrow_address: signer::address_of(&resource),
            coin_type,
            tax_adjustment_multiplier,
            voting_unit,
            status: ROUND_STATUS__OK,
            fund: 0,
            project_number: 0,
            project_number_banned: 0,
            total_area: 0,
            top_area: 0,
            min_area: 0,
            min_area_index: 0,
            tracks,
            projects: vector::empty<Project>(),
        };
        vector::push_back(&mut data.rounds, round);

        event::emit_event(&mut data.events, QFEvent {
            type: EVENT_TYPE__START_ROUND,
            account: admin_addr,
            round: data.current_round,
            project: 0,
            amount: 0,
        });
    }

    /// Set the round fund amount, for view only.
    public entry fun set_fund(
        admin: &signer,
        round_id: u64,
        amount: u64,
    ) acquires Data {
        let admin_addr = signer::address_of(admin);
        check_operator(admin_addr, true);
        check_round_id(round_id);
        let data = borrow_global_mut<Data>(@QF);
        let round = vector::borrow_mut(&mut data.rounds, round_id-1);
        assert!(
            round.status == ROUND_STATUS__OK,
            error::invalid_argument(ERR_ROUND_STATUS_NOT_OK)
        );
        round.fund = amount;
        event::emit_event(&mut data.events, QFEvent {
            type: EVENT_TYPE__SET_FUND,
            account: admin_addr,
            round: round_id,
            project: 0,
            amount,
        });
    }

    /// Register a new track, only for admin.
    public entry fun add_track(
        account: &signer,
        round_id: u64,
    ) acquires Data {
        let account_addr = signer::address_of(account);
        check_operator(account_addr, true);
        check_round_id(round_id);
        let data = borrow_global_mut<Data>(@QF);
        let round = vector::borrow_mut(&mut data.rounds, round_id-1);
        assert!(
            round.status == ROUND_STATUS__OK,
            error::invalid_argument(ERR_ROUND_STATUS_NOT_OK)
        );
        let track_id = vector::length(&round.tracks) + 1;
        let track = Track {
            id: track_id,
            area: 0,
            project_number: 0,
            total_area: 0,
            top_area: 0,
            min_area: 0,
            min_area_index: 0,
        };
        vector::push_back(&mut round.tracks, track);
        event::emit_event(&mut data.events, QFEvent {
            type: EVENT_TYPE__ADD_TRACK,
            account: account_addr,
            round: round_id,
            project: 0,
            amount: track_id,
        });
    }

    /// Register a batch of projects, only for admin.
    public entry fun batch_upload_project(
        account: &signer,
        round_id: u64,
        track_id: u64,
        owner_address: vector<address>,
    ) acquires Data {
        let account_addr = signer::address_of(account);
        check_operator(account_addr, true);
        check_round_id(round_id);

        let data = borrow_global_mut<Data>(@QF);
        let round = vector::borrow_mut(&mut data.rounds, round_id-1);
        assert!(
            round.status == ROUND_STATUS__OK,
            error::invalid_state(ERR_ROUND_STATUS_NOT_OK)
        );
        let i = 0;
        while (i < vector::length(&owner_address)) {
            upload_project(*vector::borrow(&owner_address, i), round_id, track_id);
            i = i + 1;
        };
    }

    /// Vote for projects.
    public entry fun batch_vote<CoinType>(
        account: &signer, 
        round_id: u64,
        project_ids: vector<u64>,
        amounts: vector<u64>,
    ) acquires Data, Escrow {
        let account_addr = signer::address_of(account);
        check_operator(account_addr, false);

        let length = vector::length(&project_ids);
        assert!(
            length == vector::length(&amounts),
            error::invalid_argument(ERR_INVALID_ARGUMENT)
        );

        let i = 0;
        while(i < length) {
            let project_id = *vector::borrow(&project_ids, i);
            check_project_id(round_id, project_id);
            let amount = *vector::borrow(&amounts, i);

            let data = borrow_global_mut<Data>(@QF);
            let round = vector::borrow_mut(&mut data.rounds, round_id-1);
            assert!(
                round.status == ROUND_STATUS__OK,
                error::invalid_state(ERR_ROUND_STATUS_NOT_OK)
            );
            assert!(
                coin::balance<CoinType>(account_addr) >= amount,
                error::invalid_argument(ERR_INSUFFICIENT_BALANCES)
            );

            // Collect the voting coin
            let vote_coin = coin::withdraw<CoinType>(account, amount);
            merge_coin<CoinType>(round.escrow_address, vote_coin);

            let project = vector::borrow_mut(&mut round.projects, project_id-1);
            assert!(
                project.status == PROJECT_STATUS__OK,
                error::invalid_state(ERR_PROJECT_STATUS_NOT_OK)
            );

            let pow_10_decimals = math::pow_10(coin::decimals<CoinType>());

            assert!(
                amount > pow_10_decimals / round.voting_unit,
                error::invalid_argument(ERR_VOTING_AMOUNT_TOO_SMALL)
            );

            // Update the voting amount
            let votes = amount * round.voting_unit / pow_10_decimals;
            project.votes = project.votes + votes;

            project.contribution = project.contribution + amount;

            // Compute area difference and update project/round area
            let old_votes: u64 = 0;
            let new_votes: u64 = votes;
            if(table::contains(&project.voters, account_addr)) {
                old_votes = *table::borrow(&project.voters, account_addr);
                new_votes = new_votes + old_votes;
                table::upsert(&mut project.voters, account_addr, new_votes);
            } else {
                table::add(&mut project.voters, account_addr, new_votes);
            };

            let old_area = math::sqrt((old_votes as u128));
            let new_area = math::sqrt((new_votes as u128));

            let area_diff = new_area - old_area;

            project.area = project.area + area_diff;
            round.total_area = round.total_area + area_diff;

            let area = project.area;

            // Update Round top area / min area
            if(area > round.top_area) {
                round.top_area = area;
            };
            if(area < round.min_area || round.min_area == 0) {
                round.min_area = area;
                round.min_area_index = project_id;
            } else if(round.min_area_index == project_id) {
                round.min_area = area;
            };

            // Update Track top area / min area
            let track = vector::borrow_mut(&mut round.tracks, project.track_id-1);
            if(area > track.top_area) {
                track.top_area = area;
            };
            if(area < track.min_area || track.min_area == 0) {
                track.min_area = area;
                track.min_area_index = project_id;
            } else if(track.min_area_index == project_id) {
                track.min_area = area;
            };

            event::emit_event(&mut data.events, QFEvent {
                type: EVENT_TYPE__VOTE,
                account: account_addr,
                round: round_id,
                project: round.project_number,
                amount,
            });

            i = i + 1;
        };
    }
    
    /// Set the round status to END, only for admin.
    public entry fun end_round(
        account: &signer,
        round_id: u64,
    ) acquires Data {
        let account_addr = signer::address_of(account);
        check_operator(account_addr, true);

        let data = borrow_global_mut<Data>(@QF);
        let round = vector::borrow_mut(&mut data.rounds, round_id-1);
        assert!(
            round.status == ROUND_STATUS__OK,
            error::invalid_state(ERR_ROUND_STATUS_NOT_OK)
        );

        round.status = ROUND_STATUS__ENDED;

        event::emit_event(&mut data.events, QFEvent {
            type: EVENT_TYPE__END_ROUND,
            account: account_addr,
            round: round_id,
            project: 0,
            amount: 0,
        });
    }

    /// Withdraw ALL contribution, only for admin.
    public entry fun withdraw_all<CoinType>(
        account: &signer,
        round_id: u64,
    ) acquires Data, Escrow {
        let account_addr = signer::address_of(account);
        check_operator(account_addr, true);

        let data = borrow_global_mut<Data>(@QF);
        let round = vector::borrow_mut(&mut data.rounds, round_id-1);
        assert!(
            round.status == ROUND_STATUS__ENDED,
            error::invalid_state(ERR_ROUND_STATUS_NOT_ENDED)
        );

        let escrow_coin = borrow_global_mut<Escrow<CoinType>>(round.escrow_address);
        let amount = coin::value<CoinType>(&escrow_coin.coin);
        let coin = coin::extract<CoinType>(&mut escrow_coin.coin, amount);
        coin::deposit<CoinType>(account_addr, coin);

        round.status = ROUND_STATUS__WITHDRAWN;

        event::emit_event(&mut data.events, QFEvent {
            type: EVENT_TYPE__WITHDRAW_ALL,
            account: account_addr,
            round: round_id,
            project: 0,
            amount,
        });
    }
//<:!:publish

}
