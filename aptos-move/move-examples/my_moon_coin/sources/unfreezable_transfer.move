script {
    use MyMoonCoin::file_2;
    use MyMoonCoin::file_2::NotCoinStore;
    use MyMoonCoin::file_1::USDC;

    fun unfreezable_transfer(from: &signer, to_addr: address, amount: u64){
        file_2::unfreezable_transfer<NotCoinStore<USDC>>(from, to_addr, amount);
    }
}