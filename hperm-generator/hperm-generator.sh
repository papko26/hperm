echo "Starting kubeconfig generator for user $USERNAME_HPERM"

help_f ()
{
    echo ""
    echo "KUBECONFIG_PATH_HPERM should be passed as first argument, file should be present"
    echo "CA_DATA_HPERM should be populated from env"
    echo "API_ENDPOINT_HPERM should be populated from env"
    echo "CLUSTER_NAME_HPERM should be populated from env"
    echo "NS_HPERM should be populated from env"
    echo ""
    echo "run example:"
    echo "$0 /tmp/kubeconfig"

}
check_f ()
{
    echo ""
    echo "checking required envs:"
    STATUS=0;
    if [ -z ${CA_DATA_HPERM} ]; then echo " CA_DATA_HPERM is unset"; STATUS=1; else echo " CA_DATA_HPERM is set"; fi
    if [ -z ${API_ENDPOINT_HPERM} ]; then echo " API_ENDPOINT_HPERM is unset"; STATUS=1; else echo " API_ENDPOINT_HPERM is set"; fi
    if [ -z ${CLUSTER_NAME_HPERM} ]; then echo " CLUSTER_NAME_HPERM is unset"; STATUS=1; else echo " CLUSTER_NAME_HPERM is set"; fi
    if [ -z ${NS_HPERM} ]; then echo " NS_HPERM is unset"; STATUS=1; else echo " NS_HPERM is set"; fi
    if [ -z ${KUBECONFIG_PATH_HPERM} ]
     then
        echo " KUBECONFIG_PATH_HPERM is unset"; STATUS=1
     else
        echo " KUBECONFIG_PATH_HPERM is set"
        if [ ! -f ${KUBECONFIG_PATH_HPERM} ]; then echo " KUBECONFIG_PATH_HPERM file is not present"; STATUS=1; else echo " KUBECONFIG_PATH_HPERM file is present"; fi
    fi
    if [ $STATUS == 1 ]; then echo -e "\nI cant proceed, please set all vars"; help_f; exit 1; else echo -e "\nvars are present, lets query some data!"; fi
    ACCES_OK=$(kubectl --kubeconfig "$KUBECONFIG_PATH_HPERM" -n "$NS_HPERM" auth can-i get secrets)
    if [ "$ACCES_OK" != "yes" ]; then echo "I cant access cluster or NS secrets at $NS_HPERM namespace"; exit 1; fi
    echo "checks OK"
}

act_f ()
{
    echo "searching SA..."
    SA_NAME_HPERM=$(kubectl --kubeconfig "$KUBECONFIG_PATH_HPERM" -n "$NS_HPERM" get secrets | grep "hperm-sa-secret" | grep "$USERNAME_HPERM" | awk '{print $1}')
    SA_NAME_HPERM_L=$(echo $SA_NAME_HPERM | wc -l)
    if  [ "$SA_NAME_HPERM_L" != 1 ]; then echo "unexpected cound of SA for user ${USERNAME_HPERM}"; exit 1; else echo "Found this SA: $SA_NAME_HPERM"; fi
    echo "loading SA token..."
    TOKEN_HPERM=$(kubectl --kubeconfig "$KUBECONFIG_PATH_HPERM" -n "$NS_HPERM" get secrets "$SA_NAME_HPERM" -o=jsonpath='{.data.token}' | base64 -d)
    TOKEN_L="0"
    TOKEN_L=$(echo $TOKEN_HPERM | wc -c)
    if [ -z ${TOKEN_HPERM} ] || [ "$TOKEN_HPERM" == 0 ]; then echo "token load fail for user ${USERNAME_HPERM}"; exit 1; else echo "TOKEN length is $TOKEN_L"; fi
    echo "templating kubeconfig..."

    export USERNAME_HPERM
    export TOKEN_HPERM

    envsubst < kubeconfig.template > /tmp/${USERNAME_HPERM}.kubeconfig

    echo "Local config built. Lets check connection with cluster:"
    kubectl --kubeconfig /tmp/${USERNAME_HPERM}.kubeconfig version
    echo ""
    if [ $? -eq 0 ]; then
        echo "Looks good. Saving to secrets"
    else
        echo "Something went wrong, secret is not working. Aborting"; exit 1;
    fi


    kubectl --kubeconfig "$KUBECONFIG_PATH_HPERM" -n "$NS_HPERM" create secret generic ${USERNAME_HPERM}-kubeconfig --from-file=/tmp/${USERNAME_HPERM}.kubeconfig

    echo "User ${USERNAME_HPERM} done."
    unset USERNAME_HPERM
    unset TOKEN_HPERM
}

KUBECONFIG_PATH_HPERM=$1
check_f

echo "Loading list of existing SA"
USERS_LIST=$(kubectl --kubeconfig "$KUBECONFIG_PATH_HPERM" -n "$NS_HPERM" get sa | grep "hperm" | awk '{print $1}' |  cut -d "-" -f 4-)
for USERNAME_HPERM in $USERS_LIST
do
    CNT=$(kubectl --kubeconfig "$KUBECONFIG_PATH_HPERM" -n "$NS_HPERM" get secrets | grep $USERNAME_HPERM-kubeconfig | wc -l)
    if [ "${CNT}" == "1" ]
    then
        echo "user $USERNAME_HPERM is present" 
    elif [ "${CNT}" == "0" ]
    then
        echo "user $USERNAME_HPERM is not present"
        echo "creating..."
        act_f
    else
        echo "user $USERNAME_HPERM secret is in unexpected state, please check it manually"
    fi
done