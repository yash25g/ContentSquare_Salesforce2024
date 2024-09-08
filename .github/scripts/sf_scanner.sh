# Define filename variable
filename="./tempOutputScanner.json"

# Run Salesforce scanner command and capture output
sf scanner run --target . --severity-threshold 2 --outfile $filename --format json
scanner_exit_code=$?

# Filter JSON data based on severity 1 or 2, and colorize file names
jq -r '.[] | .fileName as $file | .violations[] | select(.severity == 1 or .severity == 2) | "\($file)\n  Line: \(.line)\n  Column: \(.column)\n  End Line: \(.endLine)\n  End Column: \(.endColumn)\n  Severity: \(.severity)\n  Rule Name: \(.ruleName)\n  Category: \(.category)\n  URL: \(.url)\n  Message: \(.message)\n  Normalized Severity: \(.normalizedSeverity)\n"' "$filename" | awk '
BEGIN {
    color["1"] = "\033[1;31m"; # Red for severity 1
    color["2"] = "\033[1;33m"; # Yellow for severity 2
    file_color = "\033[1;34m"; # Blue for file name
    category_color = "\033[1;32m"; # Green for category
    no_color = "\033[0m";
}
/^\/.*$/ {print file_color $0 no_color; next}
/Category:/ {print category_color $0 no_color; next}
/Severity: 1/ {print color["1"] $0 no_color; last = "1"; next}
/Severity: 2/ {
    print color["2"] $0 no_color;
    getline; # Read following line (message)
    if (last == "1") print color["1"] "  Message: " $0 no_color;
    else if (last == "2") print color["2"] "  Message: " $0 no_color;
    next;
}
{print $0}
'

# Remove temporary JSON output file
rm -rf $filename

# Echo scanner output
exit $scanner_exit_code
