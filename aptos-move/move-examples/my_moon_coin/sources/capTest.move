module MyMoonCoin::capTest {
    #[test_only]
    use std::signer::address_of;
    use std::signer::address_of;

    struct Type1 has key {}
    struct Type2 has key {}
    struct Capability<phantom TYPE> has key{}

    public entry fun cap_1_need(_cap: &Capability<Type1>) {}
    public entry fun test_cap_1_need(signer:&signer) acquires Capability {
        let cap: &Capability<Type1> = borrow_global<Capability<Type1>>(address_of(signer));


    }

    public entry fun cap_2_need(_cap: &Capability<Type2>) {}

    public entry fun get_cap_type1(person_1: &signer) {
        let cap_type_1 = Capability<Type1> {
        };
        move_to<Capability<Type1>>(person_1, cap_type_1);
    }
    public entry fun get_cap_type2(person_1: &signer) {
        let cap_type_2 = Capability<Type2> {
        };
        move_to<Capability<Type2>>(person_1, cap_type_2);
    }
    #[test(person_1 = @0x100)]
    public fun test_cap_1(person_1: &signer) acquires Capability {
        get_cap_type1(person_1);
        let cap: &Capability<Type1> = borrow_global<Capability<Type1>>(address_of(person_1));
        cap_1_need(cap);
    }

}

