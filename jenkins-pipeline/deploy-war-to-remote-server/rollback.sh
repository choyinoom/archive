ssh -i ~/.ssh/jenkins_rsa ${REMOTE_USER}@${REMOTE_HOST} <<EOF
    chk_stop() {
        TIMEOUT=15
        SECONDS=0
        
        while [ \$SECONDS -lt \$TIMEOUT ] && pgrep -f "java.*${SERVICE_NAME}" >/dev/null; do
            sleep 1
        done

        echo \$((\$SECONDS >= \$TIMEOUT))
    }

	echo ""
    echo ""
    echo ""
    echo "**************** ROLLBACK START ****************"
    echo "* service : ${SERVICE_NAME}"

    # if your tomcat process is still alive,
	# it is highly likely that it is in an abnormal state. 
    PGREP="pgrep -f java.*${SERVICE_NAME}"
    pid=\$(eval \$PGREP)
    echo "pid: \$pid"
    if [ -n \$pid ]; then
        # SIGTERM
        kill -15 \$pid
        echo "Tomcat Shutdown..."
    fi

    ret_value=\$(chk_stop)

    if [ \$ret_value -eq 1 ]; then
        # SIGKILL
        kill -9 \$pid
        echo "Tomcat Killed..."
    fi


    # choose a latest version of docbase among your backups 
	# and restore your tomcat's appbase using it.
    cd ${WEBAPPS}
	if [ "\$(pwd)" != "${WEBAPPS}" ]; then 
        pwd
        echo "Error: Unable to change to the webapps."
        exit 1
    fi
    rm -rf *
    
    CMD_FIND="find \$HOME/backup -type f -exec ls -t {} + | head -1"
    backup=\$(eval \$CMD_FIND)
	if [ -z "\$backup" ]; then
        echo "Error: Could not find any backup file."
        exit 1
    fi
    echo \$backup
    cp \$backup .
    
    ${JAVA_HOME}/bin/jar xf ${SERVICE_NAME}*
    rm ${SERVICE_NAME}*
    ls -lt
    
    # restart your tomcat
    cd ${CATALINA_BASE}
    ./start.sh
    echo "================== ROLLBACK PROCESS END ======================"
    echo ""
    echo ""
	echo ""
EOF
