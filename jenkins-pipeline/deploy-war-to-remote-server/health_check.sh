ssh -i ~/.ssh/jenkins_rsa ${REMOTE_USER}@${REMOTE_HOST} <<EOF
    URL='http://localhost:8080/health'
    CURL_CMD="curl -s -o /dev/null -w %{http_code} \$URL"

    # Function to perform health check
    perform_health_check() {
        response_code=\$(eval \$CURL_CMD)
        echo "Health check response code: \$response_code"
    }

    # Exponential backoff function
    exponential_backoff() {
        max_retries=3
        retries=0

        while [ \$retries -lt \$max_retries ]; do
            perform_health_check

            if [ \$response_code -eq 200 ]; then
                echo "Health check succeeded."
                break
            else
                ((retries++))
                sleep \$((2 ** retries))
                echo "Retrying health check (attempt \$retries)..."
            fi
        done

        if [ \$response_code -ne 200 ]; then
            echo "Health check failed after \$max_retries attempts. Exiting."
            exit 1
        fi
    }

	echo ""
    echo ""
    echo ""
    echo "**************** HEALTH CHECK ****************"
    echo "* service : ${SERVICE_NAME}"
    # Perform exponential backoff health check
    exponential_backoff
    echo "**********************************************"
    echo ""
    echo ""
    echo ""

EOF
