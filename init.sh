#!/bin/bash

# Set the target folder where the repositories will be cloned
base_target_folder="/Users/mdekker/goinfre/Codam"

# Set the GitHub username
github_username="lithiumox-codam"

# Get a list of repositories from GitHub API
repos=$(curl -s "https://api.github.com/users/$github_username/repos" | jq -r '.[].ssh_url')

# Check if the list is empty
if [ -z "$repos" ]; then
    echo "No repositories found for the user $github_username."
    exit 1
fi

# Create an array to store the paths and names of the cloned repositories
repo_paths=()
repo_names=()

# Loop through the repository URLs and clone each one
for repo_url in $repos; do
    repo_name=$(basename "$repo_url" .git)
    target_folder="$base_target_folder/$repo_name"
    
    # Check if the target folder exists
    if [ -d "$target_folder" ]; then
        echo "Repository $repo_name already exists. Pulling the latest changes."
        cd "$target_folder"
        git pull
    else
        # Clone the repository to the target folder
        git clone "$repo_url" "$target_folder"
        
        # Check if the repository was cloned successfully
        if [ $? -eq 0 ]; then
            echo "Repository $repo_name cloned successfully."
        else
            echo "Failed to clone the repository $repo_name."
            continue
        fi
    fi
    
    # Add the repository's path and name to the arrays
    repo_paths+=("$target_folder")
    repo_names+=("$repo_name")
done

# Create a workspace file for Visual Studio Code
workspace_file="$base_target_folder/workspace.code-workspace"
echo "Creating workspace file $workspace_file."

cat <<EOT > "$workspace_file"
{
    "folders": [
EOT

# Add each repository as a folder in the workspace file
for i in "${!repo_paths[@]}"; do
    path="${repo_paths[$i]}"
    name="${repo_names[$i]}"
    cat <<EOT >> "$workspace_file"
        {
            "path": "$path",
            "name": "$name"
        },
EOT
done

# Remove the trailing comma from the last folder entry
sed -i '' '$s/,$//' "$workspace_file"

cat <<EOT >> "$workspace_file"
    ],
    "settings": {}
}
EOT

# Check if the workspace file was created successfully
if [ $? -eq 0 ]; then
    echo "Workspace file created successfully at $workspace_file."
else
    echo "Failed to create the workspace file."
fi

# Open the workspace file in Visual Studio Code
code "$workspace_file"

# Check if Visual Studio Code opened the workspace file successfully
if [ $? -eq 0 ]; then
    echo "Visual Studio Code opened the workspace."
else
    echo "Failed to open the workspace file with Visual Studio Code."
fi
