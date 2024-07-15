nohup ../loki-linux-amd64 \
-config.expand-env=true \
-config.file=../loki-config.yaml \
-server.http-listen-port=3120 \
-server.grpc-listen-port=9095 \
-memberlist.nodename=write-01 \
-memberlist.advertise-addr=10.1.39.192 \
-memberlist.advertise-port=7966 \
-memberlist.bind-port=7966 \
-target=write &