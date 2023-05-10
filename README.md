# Starknet_build
A bash shell to compile, declare and deploy Starknet Smart Contracts in just one call.
(only tested in ubuntu).

Any comments/corrections please reach me at my twitter account: [@devnet0x](https://twitter.com/devnet0x/)

## Requirements ##

[Cairo 1.0](https://github.com/starkware-libs/cairo)

[Starknet-devnet (if you want to use it in devnet)](https://github.com/0xSpaceShard/starknet-devnet)

## Usage ##


```
./starknet_build.sh <environment> <account> <cairo_file> [constructor parameters]
```
Where:

environment            : devnet or testnet or testnet2

key                    : Account name configurated in starknet_open_zeppelin_accounts.json

cairo_file             : Cairo source code file

constructor parameters : Constructor parameters (felt formatted)

## Example ##

In devnet:

![alt text](https://github.com/devnet0x/Starknet_build/blob/main/builddev.png)

In testnet:

![alt text](https://github.com/devnet0x/Starknet_build/blob/main/buildtest.png)
