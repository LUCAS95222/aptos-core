script {
    use MyMoonCoin::file_2;

    fun freezable_transfer(from: &signer,to_addr: address, amount: u64){
        file_2::freezable_transfer(from, to_addr, amount);
    }

}