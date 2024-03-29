#!/usr/bin/env bash

PATH=$PATH:/usr/local/bin

source ./scripts/environmets.sh > /dev/null 2>&1 || source environmets.sh > /dev/null 2>&1
source ./scripts/functions.sh > /dev/null 2>&1 || source functions.sh > /dev/null 2>&1

case "$1" in
    init)
        ########## ZABBIX DEPLOYMENT ##########
        echo ""
        echo -e '\E[1m'"\033\DOCKERIZED ZABBIX DEPLOYMENT AND CONFIGURATION SCRIPT \033[0m"
        echo -e '\E[1m'"\033\Version: 2.0.0"
        echo ""
        echo -e '\E[1m'"\033\By this script, the steps listed below will be done: \033[0m"
        echo ""
        echo -e '\E[1m'"\033\- Latest Docker(CE) engine and docker-compose installation. \033[0m"
        echo -e '\E[1m'"\033\- Dockerized zabbix server deployment by using the official zabbix docker images and compose file. \033[0m"
        echo -e '\E[1m'"\033\- Required packages installation like epel-repo and jq.\033[0m"
        echo -e '\E[1m'"\033\- Creating auto registration actions for Linux & Windows hosts. \033[0m"
        echo -e '\E[1m'"\033\- Creating some additional check items/triggers for Linux & Windows templates. \033[0m"
        echo -e '\E[1m'"\033\- Grafana integration and deployment of some useful custom dashboards. \033[0m"
        echo -e '\E[1m'"\033\- SMTP settings and admin email configurations. (Optional) \033[0m"
        echo -e '\E[1m'"\033\- Slack integration. (Optional) \033[0m"
        echo ""
        echo -e '\E[1m'"\033\NOTE: Any deployed zabbix server containers will be taken down and re-created.\033[0m"
        GetConfirmation

        # Install dependencies
        echo -e ""
        echo -e '\E[96m'"\033\- Install dependencies.\033[0m"
        sleep 1
        #check if epel repo installed
        EPEL=$(rpm -qa |egrep epel-release || echo "epel-release is not installed")
        if [[ $EPEL == "epel-release is not installed" ]]; then
            yum install -y epel-release
            echo -n "Enable epel repo:" && \
            echo -ne "\t\t\t\t" && Done
        else
        echo -n "Epel repo is already enabled:" && \
        echo -ne "\t\t\t" && Skip
        fi

        #check if jq installed
        JQ=$(rpm -qa |egrep "^jq" || echo "jq is not installed")
        if [[ $JQ == "jq is not installed" ]]; then
            yum install -y jq
            echo -n "Install jq:" && \
            echo -ne "\t\t\t\t" && Done
            sleep 1
            EchoDash
        else
        echo -n "jq is already installed:" && \
        echo -ne "\t\t\t" && Skip
        sleep 1
        EchoDash
        fi

        #check if openssl installed
        OSSL=$(rpm -qa |egrep "^openssl" || echo "openssl is not installed")
        if [[ $OSSL == "openssl is not installed" ]]; then
            yum install -y openssl
            echo -n "Install openssl:" && \
            echo -ne "\t\t\t\t" && Done
            sleep 1
            EchoDash
        else
        echo -n "openssl is already installed:" && \
        echo -ne "\t\t\t" && Skip
        sleep 1
        EchoDash
        fi

        # Install docker engine if it's not installed
        echo -e ""
        echo -e '\E[96m'"\033\- Install Docker CE. \033[0m"

        check_docker=$(rpm -qa |egrep "docker-ce" || echo "Docker not installed")
        if [[ $check_docker == "Docker not installed" ]]; then
            yum install -y yum-utils device-mapper-persistent-data lvm2
            yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            yum -y install docker-ce
            systemctl enable docker && systemctl start docker
            echo -n "Docker installation:" && \
            echo -ne "\t\t\t" && Done
            sleep 1
            EchoDash
        else
            echo -n "Docker engine is already installed." && \
            echo -ne "\t\t" && Skip
            sleep 1
            EchoDash
        fi

        # Install docker-compose if it's not installed
        echo -e ""
        echo -e '\E[96m'"\033\- Install Docker Compose. \033[0m"
        if [ ! -x "/usr/local/bin/docker-compose" ]; then
            LATEST_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r '.tag_name')
            curl -L "https://github.com/docker/compose/releases/download/$LATEST_VERSION/docker-compose-$(uname -s)-$(uname -m)" > /usr/local/bin/docker-compose
            chmod +x /usr/local/bin/docker-compose
            echo -n "Docker Compose installation:" && \
            echo -ne "\t\t\t" && Done
            sleep 1
            EchoDash
        else
            echo -n "Docker compose is already installed." && \
            echo -ne "\t\t" && Skip
            sleep 1
            EchoDash
        fi

        # Create a self signed SSL cert for zabbix frontend.
        echo -e ""
        echo -e '\E[96m'"\033\- Deploy self signed SSL cert for Zabbix UI. \033[0m"
        sleep 1
        if [ ! -e $BASEDIR/../zbx_env/etc/ssl/nginx/ssl.crt ] && [ ! -e $BASEDIR/../zbx_env/etc/ssl/nginx/ssl.key ]; then
            openssl req -x509 -nodes -newkey rsa:2048 -days 1365 \
              -out $BASEDIR/../zbx_env/etc/ssl/nginx/ssl.crt \
              -keyout $BASEDIR/../zbx_env/etc/ssl/nginx/ssl.key \
              -subj "/C=RO/ST=TR/L=IST/O=IT/CN=zabbix-server.local"
            openssl dhparam -out $BASEDIR/../zbx_env/etc/ssl/nginx/dhparam.pem 2048
            chmod 644 $BASEDIR/../zbx_env/etc/ssl/nginx/ssl.key
	    echo -n "Self signed SSL deployment for zabbix:" && \
            echo -ne "\t\t\t" && Done
            sleep 1
            EchoDash
        else
            echo -n "Zabbix UI SSL cert is already deployed" && \
            echo -ne "\t\t" && Skip
            sleep 1
            EchoDash
        fi

        # Create a self signed SSL cert for grafana frontend.
        echo -e ""
        echo -e '\E[96m'"\033\- Deploy self signed SSL cert for Grafana UI. \033[0m"
        sleep 1
        if [ ! -e $BASEDIR/../zbx_env/etc/ssl/grafana/ssl.crt ] && [ ! -e $BASEDIR/../zbx_env/etc/ssl/grafana/ssl.key ]; then
            openssl req -x509 -nodes -newkey rsa:2048 -days 1365 \
              -out $BASEDIR/../zbx_env/etc/ssl/grafana/ssl.crt \
              -keyout $BASEDIR/../zbx_env/etc/ssl/grafana/ssl.key \
              -subj "/C=RO/ST=TR/L=IST/O=IT/CN=grafana-server.local"
            openssl dhparam -out $BASEDIR/../zbx_env/etc/ssl/grafana/dhparam.pem 2048
            echo -n "Self signed SSL deployment for grafana:" && \
            echo -ne "\t\t\t" && Done
            sleep 1
            EchoDash
        else
            echo -n "Grafana UI SSL cert is already deployed" && \
            echo -ne "\t\t" && Skip
            sleep 1
            EchoDash
        fi

        # Check if zabbix-server is already up
        CheckZabbix
        if [[ "$status" == "Not deployed" ]]; then
            echo -e ""
            echo -e '\E[96m'"\033\- Dockerized zabbix server deployment. \033[0m"
            sleep 1
            EchoDash
            docker-compose up -d

            # Wait until zabbix getting up
            for (( i=0; i<23; ++i)); do
                GetZabbixAuthToken
                [[ "$ZBX_AUTH_TOKEN" != "null" ]] && [[ -n "$ZBX_AUTH_TOKEN" ]] && break
                echo -e '\E[1m'"\033\- Waiting for 5 seconds to zabbix server getting be ready... ( $(expr $(echo 23) - $i) retries left ) \033[0m"
                sleep 5
            done
            if [[ "$ZBX_AUTH_TOKEN" == "null" ]] || [[ -z "$ZBX_AUTH_TOKEN" ]]; then
                echo -e "\e[91m- [ERROR]: Zabbix server still not ready after 2 minutes. Please check zabbix server container.\e[0m"
                exit 1
            fi

            echo ""
            echo -n "Zabbix deployment:" && \
            echo -ne "\t\t\t\t" && Done
            sleep 1
            EchoDash
        else
            echo -e ""
            echo -e '\E[91m'"\033\WARNING:\033[0m"
            echo -e '\E[91m'"\033\Zabbix server is already running. It will be taken down and recreated!\033[0m"
            echo -e '\E[91m'"\033\Note: Your persistent data won't be deleted.\033[0m"
            echo ""
            GetConfirmation
            docker-compose down && docker-compose up -d
            # Wait until zabbix getting up
            GetZabbixAuthToken
            echo -e '\E[1m'"\033\- Waiting for Zabbix server getting ready... \033[0m"
            while [ "$ZBX_AUTH_TOKEN" == "null" ] || [ -z "$ZBX_AUTH_TOKEN" ]
            do
                sleep 2
                GetZabbixAuthToken
                echo -e '\E[1m'"\033\- Waiting for Zabbix server getting ready... \033[0m"
            done
            echo ""
            echo -n "Zabbix deployment:" && \
            echo -ne "\t\t\t" && Done
            sleep 1
            EchoDash
        fi

        ########## HOST GROUPS CONFIGURATIONS ##########
        # This creates all defined host groups in environment file
        echo -e ""
        echo -e '\E[96m'"\033\- Create hosts groups.\033[0m"
        sleep 1
        CreateHostGroups
        sleep 1
        EchoDash

        ########## AUTO REGISTRATION CONFIGURATIONS ##########
        # Get Windows host group ID to use it on creating the auto registration action.
        WGROUPID=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -X POST --data "$(WinHostGroupIDPD)" "$ZBX_SERVER_URL/api_jsonrpc.php"  |jq .result[].groupid |tr -d '"')

        # Create an auto registration action for Linux servers
        echo -e ""
        echo -e '\E[96m'"\033\- Create auto registration actions.\033[0m"
        sleep 1
        POST=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -X POST --data "$(AutoRegisterLinuxPD)" "$ZBX_SERVER_URL/api_jsonrpc.php"  |jq .)

        if [[ "$POST" == *"error"* ]]; then
            if [[ "$POST" == *"already exists"* ]]; then
                echo -n "Linux auto registration action is already exists."
                echo -ne "\t\t" && Skip
            else

                echo ""
                echo -n "Linux auto registration action:"
                echo -ne "\t\t\t\t" && Failed
                echo -n "An error occured. Please check the error output"
                echo $POST |jq .
                sleep 1
            fi
        else
            echo -n "Linux auto registration action:"
            echo -ne "\t\t\t\t" && Done
            sleep 1
        fi

        # Create an auto registration action for Windows servers
        POST=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -X POST --data "$(AutoRegisterWinPD)" "$ZBX_SERVER_URL/api_jsonrpc.php"  |jq .)

        if [[ "$POST" == *"error"* ]]; then
            if [[ "$POST" == *"already exists"* ]]; then
                echo -n "Windows auto registration action is already exists."
                echo -ne "\t\t" && Skip
            else
                echo ""
                echo -n "Win auto registration action:"
                echo -ne "\t\t\t\t" && Failed
                echo -n "An error occured. Please check the error output"
                echo $POST |jq .
                sleep 1
            fi
        else
            echo -n "Win auto registration action:"
            echo -ne "\t\t\t\t" && Done
            sleep 1
            EchoDash
        fi


        ########## TEMPLATE CONFIGURATIONS ##########
        echo -e ""
        echo -e '\E[96m'"\033\- Tune Linux OS Template.\033[0m"
        sleep 1

        POST=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -X POST --data "$(LLDFSRuleLinuxPD)" "$ZBX_SERVER_URL/api_jsonrpc.php"  |jq .)

        if [[ "$POST" == *"error"* ]]; then
            if [[ "$POST" == *"already exists"* ]]; then
                echo -n "LLD rule is already set to 1m."
                echo -ne "\t\t" && Skip
            else
                echo ""
                echo -n "Set filesystem discovery LLD interval to 30m:"
                echo -ne "\t\t" && Failed
                echo -n "An error occured. Please check the error output"
                echo $POST |jq .
                sleep 1
            fi
        else
            echo -n "Set filesystem discovery LLD interval to 30m:" && \
            echo -ne "\t\t" && Done
            sleep 1
        fi

        sleep 1

        POST=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -X POST --data "$(FreeDiskSpacePercentLinuxPD)" "$ZBX_SERVER_URL/api_jsonrpc.php"  |jq .)

        if [[ "$POST" == *"error"* ]]; then
            if [[ "$POST" == *"already exists"* ]]; then
                echo -n "Create an item protoype to get free disk space as percentage for all partitions:"
                echo -ne "\t\t" && Skip
            else
                echo ""
                echo -n "Create an item protoype to get free disk space as percentage for all partitions:"
                echo -ne "\t\t" && Failed
                echo -n "An error occured. Please check the error output"
                echo $POST |jq .
                sleep 1
            fi
        else
            echo -n "Create an item protoype to get free disk space as percentage for all partitions:" && \
            echo -ne "\t\t" && Done
            sleep 1
        fi

        sleep 1

        POST=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -X POST --data "$(LLDNetIfRuleLinuxPD)" "$ZBX_SERVER_URL/api_jsonrpc.php"  |jq .)

        if [[ "$POST" == *"error"* ]]; then
            if [[ "$POST" == *"already exists"* ]]; then
                echo -n "LLD rule is already set to 30m."
                echo -ne "\t\t\t\t" && Skip
            else
                echo -n "Set netif discovery LLD interval to 30m:"
                echo -ne "\t\t\t" && Failed
                echo -n "An error occured. Please check the error output"
                echo $POST |jq .
                sleep 1
            fi
        else
            echo -n "Set netif discovery LLD interval to 5m:"
            echo -ne "\t\t\t" && Done
            sleep 1
        fi
        sleep 1

        POST=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -X POST --data "$(TotalMemoryCheckIntervalPD)" "$ZBX_SERVER_URL/api_jsonrpc.php"  |jq .)

        if [[ "$POST" == *"error"* ]]; then
            if [[ "$POST" == *"already exists"* ]]; then
                echo -n "Total memory check interval is already set to 5m."
                echo -ne "\t\t\t\t" && Skip
            else
                echo -n "Set total memory check interval to 5m:"
                echo -ne "\t\t\t" && Failed
                echo -n "An error occured. Please check the error output"
                echo $POST |jq .
                sleep 1
            fi
        else
            echo -n "Set total memory check interval to 5m:"
            echo -ne "\t\t\t" && Done
            sleep 1
        fi
        sleep 1

        POST=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -X POST --data "$(TotalSwapCheckIntervalPD)" "$ZBX_SERVER_URL/api_jsonrpc.php"  |jq .)

        if [[ "$POST" == *"error"* ]]; then
            if [[ "$POST" == *"already exists"* ]]; then
                echo -n "Total swap check interval is already set to 30m."
                echo -ne "\t\t\t\t" && Skip
            else
                echo -n "Set total swap check interval to 30m:"
                echo -ne "\t\t\t" && Failed
                echo -n "An error occured. Please check the error output"
                echo $POST |jq .
                sleep 1
            fi
        else
            echo -n "Set total swap check interval to 30m:"
            echo -ne "\t\t\t" && Done
            sleep 1
        fi

        POST=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -X POST --data "$(NumberofCpusIntervalPD)" "$ZBX_SERVER_URL/api_jsonrpc.php"  |jq .)

        if [[ "$POST" == *"error"* ]]; then
            if [[ "$POST" == *"already exists"* ]]; then
                echo -n "Number of CPUs interval is already set to 5m."
                echo -ne "\t\t\t\t" && Skip
            else
                echo -n "Set Number of CPUs interval to 5m:"
                echo -ne "\t\t\t" && Failed
                echo -n "An error occured. Please check the error output"
                echo $POST |jq .
                sleep 1
            fi
        else
            echo -n "Set Number of CPUs interval to 5m:"
            echo -ne "\t\t\t" && Done
            sleep 1
        fi
        EchoDash

        echo -e ""
        echo -e '\E[96m'"\033\- Tune Windows OS Template.\033[0m"
        sleep 1

        POST=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -X POST --data "$(FreeDiskSpacePercentWinPD)" "$ZBX_SERVER_URL/api_jsonrpc.php"  |jq .)

        if [[ "$POST" == *"error"* ]]; then
            if [[ "$POST" == *"already exists"* ]]; then
                echo -n "Create an item protoype to get free disk space as percentage for all partitions:"
                echo -ne "\t\t" && Skip
            else
                echo ""
                echo -n "Create an item protoype to get free disk space as percentage for all partitions:"
                echo -ne "\t\t" && Failed
                echo -n "An error occured. Please check the error output"
                echo $POST |jq .
                sleep 1
            fi
        else
            echo -n "Create an item protoype to get free disk space as percentage for all partitions:" && \
            echo -ne "\t\t" && Done
            sleep 1
        fi

        sleep 1

        POST=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -X POST --data "$(LLDFSRuleWinPD)" "$ZBX_SERVER_URL/api_jsonrpc.php"  |jq .)

        if [[ "$POST" == *"error"* ]]; then
            if [[ "$POST" == *"already exists"* ]]; then
                echo -n "LLD rule is already set to 30m."
                echo -ne "\t\t" && Skip
            else
                echo ""
                echo -n "Set filesystem discovery LLD interval to 30m:"
                echo -ne "\t\t" && Failed
                echo -n "An error occured. Please check the error output"
                echo $POST |jq .
                sleep 1
            fi
        else
            echo -n "Set filesystem discovery LLD interval to 30m:" && \
            echo -ne "\t\t" && Done
            sleep 1
        fi
        sleep 1

        POST=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -X POST --data "$(LLDNetIfRuleWinPD)" "$ZBX_SERVER_URL/api_jsonrpc.php"  |jq .)

        if [[ "$POST" == *"error"* ]]; then
            if [[ "$POST" == *"already exists"* ]]; then
                echo -n "LLD rule is already set to 30m."
                echo -ne "\t\t\t\t" && Skip
            else
                echo -n "Set netif discovery LLD interval to 30m:"
                echo -ne "\t\t\t" && Failed
                echo -n "An error occured. Please check the error output"
                echo $POST |jq .
                sleep 1
            fi
        else
            echo -n "Set netif discovery LLD interval to 30m:"
            echo -ne "\t\t\t" && Done
            sleep 1
        fi

        POST=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -X POST --data "$(FreeMemPercentWinPD)" "$ZBX_SERVER_URL/api_jsonrpc.php"  |jq .)

        if [[ "$POST" == *"error"* ]]; then
            if [[ "$POST" == *"already exists"* ]]; then
                echo -n "Free mem in % item is already exist."
                echo -ne "\t\t\t" && Skip
            else
                echo -n "Create fee mem item as percentage:"
                echo -ne "\t\t\t" && Failed
                echo -n "An error occured. Please check the error output"
                echo $POST |jq .
                sleep 1
            fi
        else
            echo -n "Create fee mem item as percentage:"
            echo -ne "\t\t\t" && Done
            sleep 1
        fi

        POST=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -X POST --data "$(DisableAnnoyingWinServiceDiscovery)" "$ZBX_SERVER_URL/api_jsonrpc.php"  |jq .)

        if [[ "$POST" == *"error"* ]]; then
            if [[ "$POST" == *"already exists"* ]]; then
                echo -n "Annoying Windows service discovery already disabled."
                echo -ne "\t" && Skip
            else
                echo ""
                echo -n "Disable annoying Windows service LLD rule:"
                echo -ne "\t" && Failed
                echo -n "An error occured. Please check the error output"
                echo $POST |jq .
                sleep 1
            fi
        else
            echo -n "Disable annoying Windows service items LLD rule:"
            echo -ne "\t" && Done
            sleep 1
        fi

        ########## ZABBIX API USER CONFIGURATIONS ##########
        echo -e ""
        echo -e '\E[96m'"\033\- Create a read-only user for Zabbix API.\033[0m"
        sleep 1

        # Generate an array variable and fill it with created group IDs for API user read permission
        POST=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -X POST --data "$(HostGroupIDSPD)" "$ZBX_SERVER_URL/api_jsonrpc.php"  |jq .)
        GRP_IDS=$(echo $POST |jq .result[].groupid |tr -d '"' |sed ':a;N;$!ba;s/\n/ /g')
        unset IFS
        GRP_IDS_ARRAY=( $GRP_IDS )

        # Create a group for API user
        POST=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -X POST --data "$(CreateAPIUserGroupPD)" "$ZBX_SERVER_URL/api_jsonrpc.php"  |jq .)

        if [[ "$POST" == *"error"* ]]; then
            if [[ "$POST" == *"already exists"* ]]; then
                echo -n "API user group is already exists"
                echo -ne "\t" && Skip
            else
                echo ""
                echo -n "Create API user group:"
                echo -ne "\t\t\t\t" && Failed
                echo -n "An error occured. Please check the error output"
                echo $POST |jq .
                sleep 1
            fi
        else
            echo -n "Create API user group:"
            echo -ne "\t\t\t\t" && Done
            sleep 1
        fi

        # Get API User Group ID
        API_USERS_GROUP_ID=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -X POST --data "$(GetAPIUserGroupIDPD)" "$ZBX_SERVER_URL/api_jsonrpc.php" \
        |jq '.result[] | select(.name == "API Users") | .usrgrpid' | tr -d '"')

        # Create an user for API
        POST=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -X POST --data "$(CreateAPIUserPD)" "$ZBX_SERVER_URL/api_jsonrpc.php"  |jq .)

        if [[ "$POST" == *"error"* ]]; then
            if [[ "$POST" == *"already exists"* ]]; then
                echo -n "API user is already exists"
                echo -ne "\t\t\t" && Skip
            else
                echo ""
                echo -n "Create API user:"
                echo -ne "\t\t\t\t" && Failed
                echo -n "An error occured. Please check the error output"
                echo $POST |jq .
                sleep 1
            fi
        else
            echo -n "Create API user:"
            echo -ne "\t\t\t\t" && Done
            sleep 1
            EchoDash
        fi

        ########## ZABBIX AGENT CONFIGURATIONS ##########
        echo -e ""
        echo -e '\E[96m'"\033\- Monitor Zabbix Server itself.\033[0m"
        sleep 1

        # Get Zabbix server Host ID
        GetZabbixAuthToken
        ZBX_AGENT_HOST_ID=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -X POST --data "$(GetHostIDPD)" "$ZBX_SERVER_URL/api_jsonrpc.php" \
        |jq '.result[] | select(.name == "Zabbix server") | .hostid' | tr -d '"')

        # Change zabbix server's host interface to use DNS instead of IP
        # in order to connect dockerized zabbix-agent.
        POST=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -X POST --data "$(UpdateHostInterfacePD)" "$ZBX_SERVER_URL/api_jsonrpc.php"  |jq .)

        if [[ "$POST" == *"error"* ]]; then
                echo ""
                echo -n "Update Zabbix host interface:"
                echo -ne "\t\t\t" && Failed
                echo -n "An error occured. Please check the error output"
                echo $POST |jq .
                sleep 1
        else
            echo -n "Update Zabbix host interface:"
            echo -ne "\t\t\t" && Done
            sleep 1
        fi

        # Get zabbix-agent container ID and enable it to become a monitored host.
        ZBX_AGENT_CONTAINER_ID=$(docker ps |egrep zabbix-agent |awk '{print $1}')

        POST=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -X POST --data "$(EnableZbxAgentonServerPD)" "$ZBX_SERVER_URL/api_jsonrpc.php"  |jq .)

        if [[ "$POST" == *"error"* ]]; then
                echo ""
                echo -n "Enable Zabbix agent:"
                echo -ne "\t\t\t" && Failed
                echo -n "An error occured. Please check the error output"
                echo $POST |jq .
                sleep 1
        else
            echo -n "Enable Zabbix agent:"
            echo -ne "\t\t\t\t" && Done
            sleep 1
            EchoDash
        fi

        ########## GRAFANA CONFIGURATIONS ##########
        echo -e ""
        echo -e '\E[96m'"\033\- Grafana configurations.\033[0m"
        sleep 1
        # Wait for grafana server to be ready
        for (( i=0; i<23; ++i)); do
            GRAFANA_HEALTH=$(curl -s --insecure https://localhost:3000/healthz)
            [ "$GRAFANA_HEALTH" == "Ok" ] && break
            echo -e '\E[1m'"\033\- Waiting for 5 seconds to grafana server getting be ready... ( $(expr $(echo 23) - $i) retries left ) \033[0m"
            sleep 5
        done

        if [[ "$GRAFANA_HEALTH" != "Ok" ]]; then
                echo -e "\e[91m- [ERROR]: Grafana server still not ready after 2 minutes. Please check grafana container.\e[0m"
                exit 1
        fi
        # Enable zabbix datasource plugin
        POST=$(curl --insecure -s \
        -H "Content-Type:application/x-www-form-urlencoded" \
        -X POST $GRF_SERVER_URL/api/plugins/alexanderzobnin-zabbix-app/settings?enabled=true)

        if [[ "$POST" == *"error"* ]]; then
                echo ""
                echo -n "Enable grafana zabbix plugin:"
                echo -ne "\t\t\t" && Failed
                echo -n "An error occured. Please check the error output"
                echo $POST |jq .
                sleep 1
        else
            echo -n "Enable grafana zabbix plugin:"
            echo -ne "\t\t\t" && Done
            sleep 1
        fi

        # Create a grafana API key
        CreateGRFAPIKey
        if [[ "$GRF_API_KEY" == "null" ]]; then
            # Delete existing key
            GRF_API_KEY_ID=$(curl -s --insecure -XGET $GRF_SERVER_URL/api/auth/keys |jq .[].id)
            curl -s --insecure -XDELETE $GRF_SERVER_URL/api/auth/keys/$GRF_API_KEY_ID >/dev/null
            # and recreate
            CreateGRFAPIKey
        fi
        echo -n "Create a grafana API key:" && \
        echo -ne "\t\t\t" && Done
        sleep 1

        # Create Zabbix Datasource
        POST=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -H "Authorization:Bearer $GRF_API_KEY" \
        -X POST --data "$(CreateZbxDataSourcePD)" "$GRF_SERVER_URL/api/datasources"  |jq .)

        if [[ "$POST" == *"error"* ]]; then
            if [[ "$POST" == *"already exists"* ]]; then
                echo -n "Grafana datasource is already exists" && \
                echo -ne "\t\t\t" && Skip
            else
                echo ""
                echo -n "Create Grafana datasource for zabbix:"
                echo -ne "\t\t" && Failed
                echo -n "An error occured. Please check the error output"
                echo $POST |jq .
                sleep 1
            fi
        else
            echo -n "Create Grafana datasource for zabbix:"
            echo -ne "\t\t" && Done
            sleep 1
        fi

        # Get uid of the dashboard
        ZABBIX_DASHBOARD_ID=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -H "Authorization:Bearer $GRF_API_KEY" \
        -X GET "$GRF_SERVER_URL/api/search?folderIds=0&query=&starred=false" |jq .[].uid |tr -d '"')

        # Delete existing Zabbix Server Dashboard
        POST=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        -H "Authorization:Bearer $GRF_API_KEY" \
        -X DELETE "$GRF_SERVER_URL/api/dashboards/uid/$ZABBIX_DASHBOARD_ID"  |jq .)

        if [[ "$POST" == *"Not found"* ]]; then
                echo -n "Default zabbix dashboard not found."
                echo -ne "\t\t" && Skip
        elif [[ "$POST" == *"error"* ]]; then
                echo ""
                echo -n "Delete default zabbix dashboard:"
                echo -ne "\t\t" && Failed
                echo -n "An error occured. Please check the error output"
                echo $POST |jq .
                sleep 1
        else
            echo -n "Delete default zabbix dashboard:"
            echo -ne "\t\t" && Done
            sleep 1
        fi

        # Import Linux servers dashboard
        POST=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type: application/json;charset=UTF-8" \
        -H "Authorization:Bearer $GRF_API_KEY" \
        -d "@../grafana_dashboards/linux_servers_dashboard.json" \
        -X POST "$GRF_SERVER_URL/api/dashboards/db" |jq .)

        if [[ "$POST" == *"success"* ]]; then
            echo -n "Import Linux servers dashboard:"
            echo -ne "\t\t\t" && Done
            sleep 1
        else
            echo ""
            echo -n "Import Linux servers dashboard:"
            echo -ne "\t\t" && Failed
            echo -n "An error occured. Please check the error output"
            echo $POST |jq .
            sleep 1
        fi

        # Import Windows servers dashboard
        POST=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type: application/json;charset=UTF-8" \
        -H "Authorization:Bearer $GRF_API_KEY" \
        -d "@../grafana_dashboards/windows_servers_dashboard.json" \
        -X POST "$GRF_SERVER_URL/api/dashboards/db" |jq .)

        if [[ "$POST" == *"success"* ]]; then
            echo -n "Import Windows servers dashboard:"
            echo -ne "\t\t" && Done
            sleep 1
        else
            echo ""
            echo -n "Import Windows servers dashboard:"
            echo -ne "\t\t" && Failed
            echo -n "An error occured. Please check the error output"
            echo $POST |jq .
            sleep 1
        fi

        # Import Zabbix system status dashboard
        POST=$(curl -s --insecure \
        -H "Accept: application/json" \
        -H "Content-Type: application/json;charset=UTF-8" \
        -H "Authorization:Bearer $GRF_API_KEY" \
        -d "@../grafana_dashboards/zabbix-system-status.json" \
        -X POST "$GRF_SERVER_URL/api/dashboards/db" |jq .)

        if [[ "$POST" == *"success"* ]]; then
            echo -n "Import Zabbix system status dashboard:"
            echo -ne "\t\t" && Done
            sleep 1
        else
            echo ""
            echo -n "Import Zabbix system status dashboard:"
            echo -ne "\t\t" && Failed
            echo -n "An error occured. Please check the error output"
            echo $POST |jq .
            sleep 1
        fi
        EchoDash


        ########## NOTIFICATION CONFIGURATIONS ##########
        echo -e ""
        echo -e '\E[96m'"\033\- NOTIFICATION CONFIGURATIONS.\033[0m"
        sleep 1

        ########## EMAIL CONFIGURATION ##########
        echo ""
        GetSMTPNotifAnswer
        if [[ "$SMTPEnable" =~ $yesPattern ]]; then
            POST=$(curl -s --insecure \
            -H "Accept: application/json" \
            -H "Content-Type:application/json" \
            -X POST --data "$(SMTPConfigPD)" "$ZBX_SERVER_URL/api_jsonrpc.php" |jq .)

            if [[ "$POST" == *"error"* ]]; then
                echo -n "SMTP notification configuration:"
                echo -ne "\t\t" && Failed
                echo "An error occured. Please check the error output"
                echo "$POST" |jq .
                sleep 1
                else
                echo -n "SMTP notification configuration:"
                echo -ne "\t\t" && Done
                sleep 1
            fi

            POST=$(curl -s --insecure \
            -H "Accept: application/json" \
            -H "Content-Type:application/json" \
            -X POST --data "$(AdminSmtpMediaTypePD)" "$ZBX_SERVER_URL/api_jsonrpc.php" |jq .)

            if [[ "$POST" == *"error"* ]]; then
                echo -n "Set admin's email address:"
                echo -ne "\t\t\t" && Failed
                echo "An error occured. Please check the error output"
                echo "$POST" |jq .
                sleep 1
                else
                echo -n "Set admin's email address:"
                echo -ne "\t\t\t" && Done
                sleep 1
            fi

            POST=$(curl -s --insecure \
            -H "Accept: application/json" \
            -H "Content-Type:application/json" \
            -X POST --data "$(NotifTriggerPD)" "$ZBX_SERVER_URL/api_jsonrpc.php"  |jq .)

            if [[ "$POST" == *"error"* ]]; then
                echo -n "Enable notifications for admin group:"
                echo -ne "\t" && Failed
                echo -n "An error occured. Please check the error output"
                echo "$POST" |jq .
                sleep 1
                else
                echo -n "Enable notifications for admin group:"
                echo -ne "\t\t" && Done
                sleep 1
                EchoDash
            fi
        fi

        ########## SLACK CONFIGURATION ##########
        echo ""
        GetSlackNotifAnswer
        if [[ "$SlackEnable" =~ $yesPattern ]]; then

            GetZabbixAuthToken
            POST=$(curl -s --insecure \
            -H "Accept: application/json" \
            -H "Content-Type:application/json" \
            -X POST --data "$(ZabbixUrlGlobalMacroPD)" "$ZBX_SERVER_URL/api_jsonrpc.php" |jq .)

                if [[ "$POST" == *"error"* ]]; then
                    echo -n "Creating a global macro for Zabbix URL:"
                    echo -ne "\t\t" && Failed
                    echo "An error occured. Please check the error output"
                    echo "$POST" |jq .
                    sleep 1
                    else
                    echo -n "Creating a global macro for Zabbix URL:"
                    echo -ne "\t\t" && Done
                    sleep 1
                fi

            POST=$(curl -s --insecure \
            -H "Accept: application/json" \
            -H "Content-Type:application/json" \
            -X POST --data "$(SetSlackBotTokenPD)" "$ZBX_SERVER_URL/api_jsonrpc.php" |jq .)

                if [[ "$POST" == *"error"* ]]; then
                    echo -n "Adding bot token to slack medita type:"
                    echo -ne "\t\t" && Failed
                    echo "An error occured. Please check the error output"
                    echo "$POST" |jq .
                    sleep 1
                    else
                    echo -n "Adding bot token to slack medita type:"
                    echo -ne "\t\t" && Done
                    sleep 1
                fi

            if [[ "$SMTPEnable" =~ $yesPattern ]]; then
                POST=$(curl -s --insecure \
                -H "Accept: application/json" \
                -H "Content-Type:application/json" \
                -X POST --data "$(AdminSmtpSlackMediaTypePD)" "$ZBX_SERVER_URL/api_jsonrpc.php" |jq .)

                    if [[ "$POST" == *"error"* ]]; then
                        echo -n "Adding slack and smtp media types to admin user:"
                        echo -ne "\t\t" && Failed
                        echo "An error occured. Please check the error output"
                        echo "$POST" |jq .
                        sleep 1
                        else
                        echo -n "Adding slack and smtp media types to admin user:"
                        echo -ne "\t\t" && Done
                        sleep 1
                    fi
            else
                POST=$(curl -s --insecure \
                -H "Accept: application/json" \
                -H "Content-Type:application/json" \
                -X POST --data "$(AdminSlackMediaTypePD)" "$ZBX_SERVER_URL/api_jsonrpc.php" |jq .)

                    if [[ "$POST" == *"error"* ]]; then
                        echo -n "Adding slack media type to admin user:"
                        echo -ne "\t\t" && Failed
                        echo "An error occured. Please check the error output"
                        echo "$POST" |jq .
                        sleep 1
                        else
                        echo -n "Adding slack media type to admin user:"
                        echo -ne "\t\t" && Done
                        sleep 1
                    fi
            fi

            POST=$(curl -s --insecure \
            -H "Accept: application/json" \
            -H "Content-Type:application/json" \
            -X POST --data "$(NotifTriggerPD)" "$ZBX_SERVER_URL/api_jsonrpc.php"  |jq .)

                if [[ "$POST" == *"error"* ]]; then
                    echo -n "Enable notifications for admin group:"
                    echo -ne "\t" && Failed
                    echo -n "An error occured. Please check the error output"
                    echo "$POST" |jq .
                    sleep 1
                else
                    echo -n "Enable notifications for admin group:"
                    echo -ne "\t\t" && Done
                    sleep 1
                    EchoDash
                    FinisMessage
                fi
        else
            FinisMessage
            exit 0
        fi
    ;;

    enable-slack)
        ########## SLACK CONFIGURATION ##########
        echo ""
        GetSlackNotifAnswer
        if [[ "$SlackEnable" =~ $yesPattern ]]; then

            GetZabbixAuthToken
            POST=$(curl -s --insecure \
            -H "Accept: application/json" \
            -H "Content-Type:application/json" \
            -X POST --data "$(ZabbixUrlGlobalMacroPD)" "$ZBX_SERVER_URL/api_jsonrpc.php" |jq .)

                if [[ "$POST" == *"error"* ]]; then
                    echo -n "Creating a global macro for Zabbix URL:"
                    echo -ne "\t\t" && Failed
                    echo "An error occured. Please check the error output"
                    echo "$POST" |jq .
                    sleep 1
                    else
                    echo -n "Creating a global macro for Zabbix URL:"
                    echo -ne "\t\t" && Done
                    sleep 1
                fi

            POST=$(curl -s --insecure \
            -H "Accept: application/json" \
            -H "Content-Type:application/json" \
            -X POST --data "$(SetSlackBotTokenPD)" "$ZBX_SERVER_URL/api_jsonrpc.php" |jq .)

                if [[ "$POST" == *"error"* ]]; then
                    echo -n "Adding bot token to slack medita type:"
                    echo -ne "\t\t" && Failed
                    echo "An error occured. Please check the error output"
                    echo "$POST" |jq .
                    sleep 1
                    else
                    echo -n "Adding bot token to slack medita type:"
                    echo -ne "\t\t" && Done
                    sleep 1
                fi

            if [[ "$SMTPEnable" =~ $yesPattern ]]; then
                POST=$(curl -s --insecure \
                -H "Accept: application/json" \
                -H "Content-Type:application/json" \
                -X POST --data "$(AdminSmtpSlackMediaTypePD)" "$ZBX_SERVER_URL/api_jsonrpc.php" |jq .)

                    if [[ "$POST" == *"error"* ]]; then
                        echo -n "Adding slack and smtp media types to admin user:"
                        echo -ne "\t\t" && Failed
                        echo "An error occured. Please check the error output"
                        echo "$POST" |jq .
                        sleep 1
                        else
                        echo -n "Adding slack and smtp media types to admin user:"
                        echo -ne "\t\t" && Done
                        sleep 1
                    fi
            else
                POST=$(curl -s --insecure \
                -H "Accept: application/json" \
                -H "Content-Type:application/json" \
                -X POST --data "$(AdminSlackMediaTypePD)" "$ZBX_SERVER_URL/api_jsonrpc.php" |jq .)

                    if [[ "$POST" == *"error"* ]]; then
                        echo -n "Adding slack media type to admin user:"
                        echo -ne "\t\t" && Failed
                        echo "An error occured. Please check the error output"
                        echo "$POST" |jq .
                        sleep 1
                        else
                        echo -n "Adding slack media type to admin user:"
                        echo -ne "\t\t" && Done
                        sleep 1
                    fi
            fi

            POST=$(curl -s --insecure \
            -H "Accept: application/json" \
            -H "Content-Type:application/json" \
            -X POST --data "$(NotifTriggerPD)" "$ZBX_SERVER_URL/api_jsonrpc.php"  |jq .)

                if [[ "$POST" == *"error"* ]]; then
                    echo -n "Enable notifications for admin group:"
                    echo -ne "\t" && Failed
                    echo -n "An error occured. Please check the error output"
                    echo "$POST" |jq .
                    sleep 1
                    else
                    echo -n "Enable notifications for admin group:"
                    echo -ne "\t\t" && Done
                    sleep 1
                    EchoDash
                fi
        else
            exit 0
        fi
    ;;

    *)
        echo $"Usage: $0 {init}"
        exit 1
esac
