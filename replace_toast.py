import os
import re

directory = r'e:\Project\zelvira\zelvira-mobile\lib'

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # If ScaffoldMessenger is not in the file, skip
    if 'ScaffoldMessenger.of' not in content:
        return

    # Add import if needed
    if 'package:zelvira/components/notifcation_widget.dart' not in content:
        content = "import 'package:zelvira/components/notifcation_widget.dart';\n" + content

    # Replace ScaffoldMessenger...showSnackBar(SnackBar(content: Text(...)))
    # with AppToast.error(context, ...) or AppToast.success(context, ...)
    
    # We will use regex to find the pattern
    # ScaffoldMessenger.of(context).showSnackBar(\s*SnackBar(\s*content:\s*Text\((.*?)\)\s*)\s*);
    
    pattern1 = r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\((.*?)\)\s*,?\s*\)\s*,?\s*\);"
    
    def replacer(match):
        text_arg = match.group(1)
        if 'berhasil' in text_arg.lower() or 'success' in text_arg.lower() or 'disimpan' in text_arg.lower() or 'dihapus' in text_arg.lower():
            return f"AppToast.success(context, {text_arg});"
        else:
            return f"AppToast.error(context, {text_arg});"
            
    content = re.sub(pattern1, replacer, content, flags=re.DOTALL)
    
    # Also handle some edge cases like:
    # ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('...')));
    pattern2 = r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*const\s*SnackBar\(\s*content:\s*Text\((.*?)\)\s*,?\s*\)\s*,?\s*\);"
    content = re.sub(pattern2, replacer, content, flags=re.DOTALL)

    # Some might be chained: .showSnackBar(SnackBar(...))
    pattern3 = r"\.showSnackBar\(\s*const\s*SnackBar\(\s*content:\s*Text\((.*?)\)\s*,?\s*\)\s*,?\s*\);"
    content = re.sub(pattern3, lambda m: f"; AppToast.error(context, {m.group(1)});", content, flags=re.DOTALL)

    # Some might not have const
    pattern4 = r"\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\((.*?)\)\s*,?\s*\)\s*,?\s*\);"
    content = re.sub(pattern4, lambda m: f"; AppToast.error(context, {m.group(1)});", content, flags=re.DOTALL)
    
    # Finally, write back
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

for root, _, files in os.walk(directory):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))

print('Done replacing ScaffoldMessenger with AppToast')
