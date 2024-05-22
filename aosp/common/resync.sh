#!/bin/bash
# Copyright (c) 2016-2024 Crave.io Inc. All rights reserved

main() {
    # Run repo sync command and capture the output
    find .repo -name '*.lock' -delete
    repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags --prune 2>&1 | tee /tmp/output.txt

    # Check if there are any failing repositories
    if grep -q "Failing repos:" /tmp/output.txt ; then
        echo "Deleting failing repositories..."
        # Extract failing repositories from the error message and echo the deletion path
        rm -f deleted_repositories.txt
        while IFS= read -r line; do
            # Extract repository name and path from the error message
            repo_info=$(echo "$line" | awk -F': ' '{print $NF}')
            repo_path=$(dirname "$repo_info")
            repo_name=$(basename "$repo_info")
            # Save the deletion path to a text file
            echo "Deleted repository: $repo_info" | tee -a deleted_repositories.txt
            # Delete the repository
            rm -rf "$repo_path/$repo_name"
        done <<< "$(cat /tmp/output.txt | awk '/Failing repos:/ {flag=1; next} /Try/ {flag=0} flag')"

        # Re-sync all repositories after deletion
        echo "Re-syncing all repositories..."
        find .repo -name '*.lock' -delete
        repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags --prune
    else
        echo "All repositories synchronized successfully."
    fi
}

main $*
