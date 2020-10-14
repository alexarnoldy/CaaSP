#!/bin/bash

#### Shell script to create a new vlan and bridge 

read -n 1 -p "Ready to create new network on the targeted infrastructure hosts? (y/n) " CONTINUE

case $CONTINUE in
        y)
                echo ""
                echo "Continuing..."
                sleep 2
                ;;
        *)
                echo "Exiting."
                exit
                ;;
esac

## Moved to the for loop for a per-node effect
#CREATE_NEW_BRIDGES=()

export NEW_BRIDGE=$(head -1 ./.free_nets)

## Need to communicate that ${NEW_BRIDGE} is the network that has been created for this iteration

## Move the new bridge from .free_nets to .configured_nets
bash -c "echo ${NEW_BRIDGE} >> ./.configured_nets" &&\
        bash -c "grep -v ${NEW_BRIDGE} ./.free_nets > ./.free_nets.tmp" &&\
        sort ./.free_nets.tmp | uniq > ./.free_nets &&\
        rm ./.free_nets.tmp &&\
        sort ./.configured_nets | uniq > ./.configured_nets.tmp &&\
        mv ./.configured_nets.tmp ./.configured_nets


for CONFIGURED_BRIDGES in $(cat ./.configured_nets)
do

for NODE in $(ls ./infrastructure) 
do      
        CREATE_NEW_BRIDGES=()
        test -z  $(ssh ${NODE} ip a | grep -o bridge${CONFIGURED_BRIDGES} | uniq | sed -e 's/\://') && CREATE_NEW_BRIDGES+=(${CONFIGURED_BRIDGES}) 
        ## Iterate over ${CREATE_NEW_BRIDGES[@]} to perform the creation
done
done

echo ${CREATE_NEW_BRIDGES[@]}

## Need to run the same procedure backwards to remove bridges that are configured but not listed in ./.configured_nets


