ssh -i ~/.ssh/jenkins_rsa ${REMOTE_USER}@${REMOTE_HOST} <<EOF
PGREP="pgrep -f java.*${SERVICE_NAME}"

chk_start() {
    TIMEOUT=15
    SECONDS=0
    
    while  [ \$SECONDS -lt \$TIMEOUT ] && [ -z "\$(\$PGREP)" ]; do
        echo "Process for service '${SERVICE_NAME}' not ready..."
        sleep 1
    done

    if [ \$SECONDS -ge \$TIMEOUT ]; then
        echo "Timeout. Process did not start within \$TIMEOUT seconds"
        exit 1
    fi
    echo "Process for service '$SERVICE_NAME' is ready."
}

chk_stop() {
    TIMEOUT=15
    SECONDS=0
    
    while [ \$SECONDS -lt \$TIMEOUT ] && [ -n "\$(\$PGREP)" ]; do
        echo "Process for service '${SERVICE_NAME}' still running..."
        sleep 1
    done

    if [ \$SECONDS -ge \$TIMEOUT ]; then
        echo "Timeout. Process did not stop within \$TIMEOUT seconds"
        exit 1
    fi
    echo "Process for service '${SERVICE_NAME}' has stopped."
}

echo ""
echo ""
echo ""
echo "**************** DEPLOY START ****************"
echo "* host    : ${REMOTE_HOST}"
echo "* service : ${SERVICE_NAME}"
echo "* deploy  : ${DEPLOY_DIR}"
echo "* webapps : ${WEBAPPS}"

# make sure new ROOT.war is copied
if [ "\$(ls ${DEPLOY_DIR} | wc -l)" -ne 1 ]; then
    echo "Error: no files to deploy."
    exit 1
fi

# shutdown tomcat
cd ${CATALINA_BASE}
./stop.sh
chk_stop

# copy a new docbase into the tomcat webapp directory
cd ${WEBAPPS}
if [ "\$(pwd)" != "${WEBAPPS}" ]; then 
    pwd
    echo "Error: Unable to change to the webapps."
    exit 1
fi
rm -rf *
cp ${REMOTE_DIRECTORY}/ROOT.war .

# startup tomcat
cd ${CATALINA_BASE}
./start.sh
chk_start

# keep this directory clean for next deployments
cd ${DEPLOY_DIR}
if [ "\$(pwd)" != "${DEPLOY_DIR}" ]; then 
    echo "Error: Unable to change to the desired directory."
    exit 1
fi
rm -rf *

echo "**********************************************"
echo ""
echo ""
echo ""
EOF
