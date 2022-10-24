# QF-Aptos
a quadratic funding implementation on Aptos

## Quick Start

[Setup Aptos](https://aptos.dev/guides/getting-started)

```
git clone https://github.com/aptos-labs/aptos-core.git
cd aptos-core
./scripts/dev_setup.sh
source ~/.cargo/env
```

Run tests

```
aptos move test
```

## Entry

### initialize
Initialize the contract.

### start_round
Start a new round. The valut controlled by the program derrived address. If the init valut is not empty, the value will be treated as a fund in the round.

### donate
Add more fund in a round.

### batch_upload_project
Register projects to the round.

### batch_vote
Vote to projects which you like.

### end_round
Only owenr of round can end a round.

### withdraw_all
After withdraw_grants be called, the administrator can withdraw all coin.

## Publish

```
aptos move publish  --named-addresses QF=default
```