#!/bin/bash

ln -fs /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime

cat << EOF > /etc/ecs/ecs.config
ECS_CLUSTER=${ecs_cluster_name}
EOF

#ECS_AVAILABLE_LOGGING_DRIVERS=${ecs_logging}

https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using_cloudwatch_logs.html

start ecs

echo "Done"
