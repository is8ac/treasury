#!/bin/bash
# This file is used for starting a fresh set of all contracts & configs
set -e

if [ -d "res" ]; then
  echo ""
else
  mkdir res
fi

cd "`dirname $0`"

if [ -z "$KEEP_NAMES" ]; then
  export RUSTFLAGS='-C link-arg=-s'
else
  export RUSTFLAGS=''
fi

# build the things
cargo build --all --target wasm32-unknown-unknown --release
cp ../target/wasm32-unknown-unknown/release/*.wasm ../res/

# Uncomment the desired network
export NEAR_ENV=testnet
# export NEAR_ENV=mainnet
# export NEAR_ENV=guildnet
# export NEAR_ENV=betanet

export FACTORY=testnet
# export FACTORY=near
# export FACTORY=registrar

export MAX_GAS=300000000000000

if [ -z ${NEAR_ACCT+x} ]; then
  export NEAR_ACCT=weicat.$FACTORY
else
  export NEAR_ACCT=$NEAR_ACCT
fi

export TREASURY_ACCOUNT_ID=treasury.$NEAR_ACCT

# add/remove staking pools
near call $TREASURY_ACCOUNT_ID add_staking_pool '{"pool_account_id": "node0"}' --accountId $AIRDROP_ACCOUNT_ID --gas $MAX_GAS
near call $TREASURY_ACCOUNT_ID add_staking_pool '{"pool_account_id": "meta-v2.pool.testnet"}' --accountId $AIRDROP_ACCOUNT_ID --gas $MAX_GAS
near call $TREASURY_ACCOUNT_ID add_staking_pool '{"pool_account_id": "hotones.pool.f863973.m0"}' --accountId $AIRDROP_ACCOUNT_ID --gas $MAX_GAS
# near call $TREASURY_ACCOUNT_ID remove_staking_pool '{"pool_account_id": "hotones.pool.f863973.m0"}' --accountId $AIRDROP_ACCOUNT_ID --gas $MAX_GAS
near view $TREASURY_ACCOUNT_ID get_delegations

# deposit&stake
near call $TREASURY_ACCOUNT_ID deposit_and_stake '{"pool_account_id": "meta-v2.pool.testnet", "amount": "100000000000000000000000000"}' --accountId $TREASURY_ACCOUNT_ID
near call $TREASURY_ACCOUNT_ID deposit_and_stake '{"pool_account_id": "hotones.pool.f863973.m0", "amount": "100000000000000000000000000"}' --accountId $TREASURY_ACCOUNT_ID

# update internal balance
near call $TREASURY_ACCOUNT_ID get_staked_balance '{"pool_account_id": "meta-v2.pool.testnet"}' --accountId $TREASURY_ACCOUNT_ID
near call $TREASURY_ACCOUNT_ID get_staked_balance '{"pool_account_id": "hotones.pool.f863973.m0"}' --accountId $TREASURY_ACCOUNT_ID

# liquidunstake
near call $TREASURY_ACCOUNT_ID liquid_unstake '{"pool_account_id": "meta-v2.pool.testnet", "amount": "100000000000000000000000000"}' --accountId $TREASURY_ACCOUNT_ID

# unstake
near call $TREASURY_ACCOUNT_ID unstake '{"pool_account_id": "hotones.pool.f863973.m0"}' --accountId $TREASURY_ACCOUNT_ID

# withdraw
near call $TREASURY_ACCOUNT_ID withdraw '{"pool_account_id": "hotones.pool.f863973.m0"}' --accountId $TREASURY_ACCOUNT_ID

echo "Staking Flows Complete"