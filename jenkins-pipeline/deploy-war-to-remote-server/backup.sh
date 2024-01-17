ssh -i ~/.ssh/jenkins_rsa -T ${REMOTE_USER}@${REMOTE_HOST} <<EOF
    DATE=`date +%y%m%d`
    TIME=`date +%H%M%S`
    mkdir -p ${BACKUP_DIR}/\$DATE
	if [ "\$(ls ${WEBAPPS} | wc -l)" -ge 1 ]; then
        $JAVA_HOME/bin/jar cf ${BACKUP_DIR}/\$DATE/${SERVICE_NAME}.war.\$TIME -C ${WEBAPPS} .
    else
        echo "Nothing to back up!"
    fi
EOF
