nohup ../loki-linux-amd64 \
-config.expand-env=true \
-config.file=../loki-config.yaml \
-server.http-listen-port=3110 \
-server.grpc-listen-port=9085 \
-memberlist.nodename=read-01 \
-memberlist.advertise-addr=10.1.39.192 \
-memberlist.advertise-port=7956 \
-memberlist.bind-port=7956 \
-target=read &
