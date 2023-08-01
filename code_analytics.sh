#!/bin/bash

# Function to calculate file size category
get_size_category() {
    local file_size=$1

    if [ $file_size -le 200 ]; then
        echo "small"
    elif [ $file_size -le 400 ]; then
        echo "medium"
    else
        echo "large"
    fi
}

# Function to increment count for a file type and size category
increment_count() {
    local file_type=$1
    local size_category=$2

    case "$size_category" in
        small)
            ((file_counts[0+$file_type]++))
            ;;
        medium)
            ((file_counts[1+$file_type]++))
            ;;
        large)
            ((file_counts[2+$file_type]++))
            ;;
    esac
}

# Check if the directory argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

# Get the directory path from the command-line argument
folder_path="$1"

# Check if the directory exists
if [ ! -d "$folder_path" ]; then
    echo "Error: Directory not found."
    exit 1
fi

# Array to store file counts per type and size category
declare -a file_counts

# Loop through all files in the directory
while IFS= read -r -d $'\0' file; do
    # Check if the file is a regular file (not a directory or special file)
    if [ -f "$file" ]; then
        # Get the file size in lines
        file_size=$(wc -l < "$file")

        # Get the file extension
        file_extension="${file##*.}"
        if [ -z "$file_extension" ]; then
            file_extension="Unknown"
        fi

        # Get the file type based on the size
        file_type=$(get_size_category $file_size)

        # Increment the corresponding count based on the file type and extension
        increment_count "$file_extension" "$file_type"
    fi
done < <(find "$folder_path" -type f -print0)

# Display the first table - Code analytics report
echo "Code analytics report for directory: '$folder_path'"
printf "+----------------+-------+\n"
printf "| Size Category  | Count |\n"
printf "+----------------+-------+\n"
printf "| Small          | %-5s |\n" "${file_counts[0+small]:-0}"
printf "| Medium         | %-5s |\n" "${file_counts[1+medium]:-0}"
printf "| Large          | %-5s |\n" "${file_counts[2+large]:-0}"
printf "+----------------+-------+\n"

# Calculate and display the total count in the first table
total=$(( ${file_counts[0+small]:-0} + ${file_counts[1+medium]:-0} + ${file_counts[2+large]:-0} ))
printf "| Total          | %-5s |\n" "$total"
printf "+----------------+-------+\n\n"

# Get a list of all files in the folder and their extensions
file_list=$(find "$folder_path" -type f | sed 's/.*\.//' | sort)

# Count occurrences of each extension
extension_counts=$(echo "$file_list" | uniq -c)

# Function to print table rows with borders
print_table_row() {
    printf "| %-20s | %-10s |\n" "$1" "$2"
}

# Display the second table - File extension counts
echo "File Extension Counts for directory: '$folder_path'"
echo "+-----------------------+ ----------+"
echo "| Extension             | Count     |"
echo "+-----------------------+ ----------+"

# Loop through the extensions and counts, print the table rows, and calculate the total count
total_count=0
while read -r line; do
    count=$(echo "$line" | awk '{print $1}')
    extension=$(echo "$line" | awk '{print $2}')
    total_count=$((total_count + count))
    print_table_row ".$extension" "$count"
done <<< "$extension_counts"

# Print the bottom-most row with the total count
echo "+-----------------------+ ----------+"
print_table_row "Total" "$total_count"
echo "+-----------------------+ ----------+"
