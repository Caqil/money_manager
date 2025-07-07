import re
import sys

def extract_all_strings(input_source):
    # Regular expression to match string literals (single or double quotes)
    # Matches 'text' or "text", including strings with escaped quotes
    pattern = r'"(?:[^"\\]|\\.)*"|\'(?:[^\'\\]|\\.)*\''
    
    # Store matches with line number, full line, and string content
    matches = []
    
    try:
        # Check if input is a file
        if input_source.endswith(('.dart', '.txt', '.py', '.js', '.html')):
            with open(input_source, 'r', encoding='utf-8') as file:
                for line_number, line in enumerate(file, 1):
                    # Find all string literals in the line
                    found = re.findall(pattern, line)
                    if found:
                        for match in found:
                            # Remove surrounding quotes for cleaner output
                            clean_match = match[1:-1]
                            matches.append((line_number, line.strip(), clean_match))
        else:
            # Treat input as a string
            for line_number, line in enumerate(input_source.split('\n'), 1):
                found = re.findall(pattern, line)
                if found:
                    for match in found:
                        # Remove surrounding quotes for cleaner output
                        clean_match = match[1:-1]
                        matches.append((line_number, line.strip(), clean_match))
    
    except FileNotFoundError:
        print(f"Error: File '{input_source}' not found.")
        return []
    except Exception as e:
        print(f"Error occurred: {str(e)}")
        return []
    
    return matches

def main():
    # Check if file path is provided as command-line argument
    if len(sys.argv) > 1:
        input_source = sys.argv[1]
    else:
        # Use default input (placeholder for testing)
        input_source = """
        'recurring.basicInformation'.tr()
        some_code
        "example string"
        'validation.tooShort'.tr(args: ['2'])
        """
    
    results = extract_all_strings(input_source)
    
    if results:
        print("Found string literals in the following lines:")
        print(f"{'Line':<8} {'String':<40} {'Full Line'}")
        print("-" * 80)
        for line_number, line, string in results:
            print(f"{line_number:<8} {string:<40} {line}")
    else:
        print("No string literals found.")

if __name__ == "__main__":
    main()