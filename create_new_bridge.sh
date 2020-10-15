#!/bin/bash

#### Shell script to create a new vlan and bridge via ansible-playbooks

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

## Iterate over the ./.configured_nets file to review what networks should be configured on the infrastructure hosts
for CONFIGURED_BRIDGES in $(cat ./.configured_nets)
do

## Iterate over the infrastructure hosts to create any bridges that are listed in ./.configured_nets but not configured on each host
for NODE in $(ls ./infrastructure) 
do      
        CREATE_NEW_BRIDGES=()
        test -z  $(ssh ${NODE} ip a | grep -o bridge${CONFIGURED_BRIDGES} | uniq | sed -e 's/\://') && CREATE_NEW_BRIDGES+=(${CONFIGURED_BRIDGES}) 
        ## Iterate over ${CREATE_NEW_BRIDGES[@]} to perform the bridge and vlan creation
        for BRIDGE_NUM in "${CREATE_NEW_BRIDGES[@]}"
        do
                echo "nmcli connection add type bridge ifname bridge${BRIDGE_NUM} con-name bridge${BRIDGE_NUM} connection.autoconnect yes" > .${BRIDGE_NUM}.tmp
                echo "#nmcli connection mod bridge${BRIDGE_NUM} ipv4.method manual ipv4.address 172.16.${BRIDGE_NUM}.10/24 ipv4.gateway 172.16.${BRIDGE_NUM}.1 ipv4.dns 172.16.250.2" >> .${BRIDGE_NUM}.tmp
                echo "nmcli connection add type vlan con-name vlan${BRIDGE_NUM} dev bond0 id ${BRIDGE_NUM} master bridge${BRIDGE_NUM} connection.autoconnect yes" >> .${BRIDGE_NUM}.tmp
                echo "nmcli connection down bridge${BRIDGE_NUM}" >> .${BRIDGE_NUM}.tmp
                echo "nmcli connection up bridge${BRIDGE_NUM}" >> .${BRIDGE_NUM}.tmp
                scp .${BRIDGE_NUM}.tmp ${NODE}:~
                ssh ${NODE} sudo bash .${BRIDGE_NUM}.tmp
        done

        ## Deploy vyos router
done
done

#echo ${CREATE_NEW_BRIDGES[@]}

## Need to run the same procedure backwards to remove bridges that are configured but not listed in ./.configured_nets


