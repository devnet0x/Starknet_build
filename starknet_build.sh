######################################################
#                                                    #
# Starknet Build. A basic shell for Starknet compile,#
# declare and deploy.                                #
# Version: 0.1 may 2023                              #
# By     : devnet0x                                  #
#                                                    #
######################################################
#!/bin/bash

if [[ ($# -lt 3) || ($1 != "devnet" && $1 != "testnet" && $1 != "testnet2") ]]
then
   echo "Usage: starknet_build.sh <devnet|testnet|testnet2> <account_name> <cairo file> [constructor parameters as felt252]"
   exit
fi

# Set environment parameters
if [ $1 == "devnet" ]
then
   export STARKNET_NETWORK=alpha-goerli
   export STARKNET_WALLET=starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount

   ENVIRONMENT1="--gateway_url http://127.0.0.1:5050 --feeder_gateway_url http://127.0.0.1:5050"
fi

if [ $1 == "testnet" ]
then
   export STARKNET_NETWORK=alpha-goerli
   export STARKNET_WALLET=starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount
fi

if [ $1 == "testnet2" ]
then
   export STARKNET_NETWORK=alpha-goerli2
   export STARKNET_WALLET=starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount
fi

# Set keys parameters
#PUBLIC_KEY=`cat ${2} | awk 'FNR == 1 {print $1}'`
#export PROTOSTAR_ACCOUNT_PRIVATE_KEY=`cat ${2} | awk 'FNR == 2 {print $1}'`


# Set contructor inputs
if [ $# -gt 3 ]
then
   INPUTS="--inputs ${@:4}"
fi

###################################################
#                                                 #
# Compile                                         #
#                                                 #
###################################################

# Start process
echo -e "\033[1;32mCompiling...\033[0m"
FILENAME=`basename $3 .cairo`
cargo run --bin starknet-compile ./${3} ./${FILENAME}.sierra

if [ $? -ne 0 ]
then
   echo -e "\n\033[0;41mFAILED COMPILE.\033[0m"
   exit
fi

###################################################
#                                                 #
# Declare                                         #
#                                                 #
###################################################

echo -e "\033[1;32mDeclaring...\033[0m"
DECLARE_STATEMENT="starknet ${ENVIRONMENT1} --account ${2} declare --contract ${FILENAME}.sierra > build.tmp"
echo ${DECLARE_STATEMENT}
eval ${DECLARE_STATEMENT}
if [ $? -ne 0 ]
then
   echo -e "\n\033[0;41mFailed declare:\033[0m\n"${DECLARE_STATEMENT}
   exit
fi

CLASS_HASH=`cat build.tmp | awk 'FNR == 3 {print $4}'`
TX_HASH=`cat build.tmp | awk 'FNR == 4 {print $3}'`

echo "Class Hash:" ${CLASS_HASH}
echo "Tx.Hash:" ${TX_HASH}

TX_STATUS=`starknet ${ENVIRONMENT1} tx_status --hash ${TX_HASH} | grep tx_status | awk 'FNR == 1 {print $2}'`

start=$SECONDS
while [[ (${TX_STATUS} == "\"RECEIVED\"") || (${TX_STATUS} == "\"PENDING\"") ]]
do
   echo -ne "${TX_STATUS} $(( SECONDS - start )) secs.\r"
   sleep 1
   TX_STATUS=`starknet ${ENVIRONMENT1} tx_status --hash ${TX_HASH} | grep tx_status | awk 'FNR == 1 {print $2}'`
done
TX_STATUS=`starknet ${ENVIRONMENT1} tx_status --hash ${TX_HASH} | grep tx_status | awk 'FNR == 1 {print $2}'`
echo -ne "${TX_STATUS} $(( SECONDS - start )) secs.\n"
if [ ${TX_STATUS} != "\"ACCEPTED_ON_L2\"" ]
then
   echo -e '\033[0;41mFAILED DECLARE.\033[0m'
   TX_STATUS=`starknet ${ENVIRONMENT1} tx_status --hash ${TX_HASH}`
   exit
fi

###################################################
#                                                 #
# Deploy                                          #
#                                                 #
###################################################

echo -e "\033[1;32mDeploying...\033[0m"
DEPLOY_STATEMENT="starknet ${ENVIRONMENT1} --account ${2} deploy --max_fee 10000000000000 --class_hash ${CLASS_HASH} ${INPUTS} > build.tmp"
echo ${DEPLOY_STATEMENT}
eval ${DEPLOY_STATEMENT}
if [ $? -ne 0 ]
then
   echo -e "\n\033[0;41mFailed command:\033[0m\n"${DEPLOY_STATEMENT}
   exit
fi

CONTRACT_ADDRESS=`cat build.tmp | awk 'FNR == 2 {print $3}'`
TX_HASH=`cat build.tmp | awk 'FNR == 3 {print $3}'`

TX_STATUS=`starknet ${ENVIRONMENT1} tx_status --hash ${TX_HASH} | grep tx_status | awk 'FNR == 1 {print $2}'`

echo "Tx.Hash:" ${TX_HASH}

start=$SECONDS
while [[ (${TX_STATUS} == "\"RECEIVED\"") || (${TX_STATUS} == "\"PENDING\"") ]]
do
   echo -ne "${TX_STATUS} $(( SECONDS - start )) secs.\r"
   sleep 1
   TX_STATUS=`starknet ${ENVIRONMENT1} tx_status --hash ${TX_HASH} | grep tx_status | awk 'FNR == 1 {print $2}'`
done
TX_STATUS=`starknet ${ENVIRONMENT1} tx_status --hash ${TX_HASH} | grep tx_status | awk 'FNR == 1 {print $2}'`
echo -ne "${TX_STATUS} $(( SECONDS - start )) secs.\n"
if [ ${TX_STATUS} != "\"ACCEPTED_ON_L2\"" ]
then
   cat build.tmp
   echo -e '\033[0;41mFAILED DEPLOY.\033[0m'
   starknet ${ENVIRONMENT1} tx_status --hash ${TX_HASH}
   exit
fi

echo "Contract Address:" ${CONTRACT_ADDRESS}
rm build.tmp
