script {
    use MyMoonCoin::file_2;

    fun notCoinStore(signer: &signer, amount: u64){
        file_2::notCoinStoreRegisterAndGenerate(signer, amount);
    }


}