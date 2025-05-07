#!/bin/bash

# This script renames all .yml files to .yaml and updates references inside the files

# Find all .yml files
YML_FILES=$(find . -name "*.yml" | sort)

# First rename all files
for file in $YML_FILES; do
	newfile="${file%.yml}.yaml"
	echo "Renaming $file to $newfile"

	# Create directory if it doesn't exist
	mkdir -p "$(dirname "$newfile")"

	# Copy the file (we'll remove the old ones later)
	cp "$file" "$newfile"
done

# Then update references in all .yaml files
YAML_FILES=$(find . -name "*.yaml" | sort)

for file in $YAML_FILES; do
	echo "Updating references in $file"

	# Replace any reference to .yml files with .yaml
	# This handles workflow references like uses: ./.github/workflows/something.yml
	sed -i '' 's/\.yml/\.yaml/g' "$file"
done

# Remove original .yml files (uncomment when ready)
# for file in $YML_FILES; do
#   echo "Removing original $file"
#   rm "$file"
# done

echo "Conversion complete!"
echo "Please review the changes and then uncomment the removal section to delete original .yml files"
