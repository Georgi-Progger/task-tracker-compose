#!/bin/bash

create_topic() {
    local topic=$1
    local partitions=$2
    local replication=$3
    local config=$4
    
    echo "Checking topic: $topic"
    
    if kafka-topics --bootstrap-server kafka:${KAFKA_INTERNAL_PORT} --list | grep -q "^$topic$"; then
        echo "Topic '$topic' already exists"
        return 0
    fi
    
    echo "Creating topic: $topic"
    
    local cmd="kafka-topics --create \
      --topic $topic \
      --partitions $partitions \
      --replication-factor $replication \
      --bootstrap-server kafka:${KAFKA_INTERNAL_PORT}"
    
    if [ -n "$config" ]; then
        cmd="$cmd --config $config"
    fi
    
    if eval "$cmd"; then
        echo "Successfully created topic: $topic"
        return 0
    else
        echo "Failed to create topic: $topic"
        return 1
    fi
}

echo "Waiting for Kafka to be ready..."
for i in {1..30}; do
    if kafka-topics --bootstrap-server kafka:${KAFKA_INTERNAL_PORT} --list > /dev/null 2>&1; then
        echo "Kafka is ready!"
        break
    fi
    echo "Attempt $i/30 - Kafka not ready, waiting 2 seconds..."
    sleep 2
done

echo "Creating topics..."

create_topic "EMAIL_SENDING_TASKS" 10 1
create_topic "EVENTS_NOTIFICATIONS" 10 1

echo ""
echo "=== All Topics ==="
kafka-topics --list --bootstrap-server kafka:${KAFKA_INTERNAL_PORT}

echo ""
echo "=== Topic Details ==="
for topic in EMAIL_SENDING_TASKS EVENTS_NOTIFICATIONS; do
    echo "--- $topic ---"
    kafka-topics --describe --topic "$topic" --bootstrap-server kafka:${KAFKA_INTERNAL_PORT} 2>/dev/null || true
done

echo "Topic initialization completed successfully"