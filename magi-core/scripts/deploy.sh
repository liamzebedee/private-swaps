#!/usr/bin/env bash
set -ex
forge build --optimizer-runs 200 --via-ir

# niacin deploy MockDAI Tempest MiMC DepositVerifier WithdrawVerifier SwapVerifier -y

niacin deploy -m manifest.json MockDAI Tempest MiMC DepositVerifier WithdrawVerifier SwapVerifier -y
