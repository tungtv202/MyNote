#!/bin/bash

# Get a list of orphaned images (dangling images)
orphan_images=$(docker images)

# Get the current date and calculate the date 3 months ago
current_date=$(date +%s)
three_months_ago=$((current_date - (60 * 60 * 24 * 30 * 2)))  # 60s * 60m * 24h * 30d * 2mo

# Remove orphaned images created more than 2 months ago
for image_id in $orphan_images; do
    image_created_date=$(docker inspect -f '{{.Created}}' "$image_id")
    image_timestamp=$(date -d "$image_created_date" +%s)
    
    if [[ $image_timestamp -lt $three_months_ago ]]; then
        echo "Removing image: $image_id (Created on: $image_created_date)"
        docker rmi "$image_id"
    fi
done
