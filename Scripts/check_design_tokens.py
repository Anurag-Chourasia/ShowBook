"""Reject visual literals in app source; keep data/algorithm constants out of this policy."""
from pathlib import Path
import re, sys
root = Path(__file__).resolve().parents[1]
source = root / ('myTV' if (root / 'myTV').is_dir() else 'ShowBook')
patterns = {
    'shorthand color': r'(?<![\w.])\.(?:primary|secondary|accentColor|white|black|gray|red|green|blue|yellow|orange|clear)\b',
    'inline font role': r'\.font\(\.(?:largeTitle|title|title2|title3|headline|subheadline|body|callout|footnote|caption|caption2)\b',
    'raw color': r'\b(?:Color|UIColor)\s*\(|\bColor\.(?:primary|secondary|accentColor|white|black|gray|red|green|blue|yellow|orange|clear)\b',
    'numeric visual argument': r'\b(?:spacing|width|height|minWidth|minHeight|maxWidth|maxHeight|minimum|cornerRadius|lineWidth|radius|minLength|size)\s*:\s*\d',
    'numeric visual modifier': r'\.(?:padding|cornerRadius|opacity|scaleEffect|lineLimit)\(\s*\d',
    'numeric edge padding': r'\.padding\((?:\.[A-Za-z]+|\[[^]]+\])\s*,\s*\d',
    'raw point property': r'\b(?:var|let)\s+\w+\s*:\s*CGFloat\s*(?:=\s*\d|\{\s*\d)',
    'conditional line limit': r'\.lineLimit\([^\n]*(?:\?|:)\s*\d',
    'implicit padding': r'\.padding\((?:\.[A-Za-z]+)?\)',
}
failures=[]
for path in source.rglob('*.swift'):
    if '.generated.' in path.name: continue
    for number, line in enumerate(path.read_text().splitlines(), 1):
        if line.lstrip().startswith('//'): continue
        # Mutable model state is not a design dimension. Hex parsing is a data conversion utility.
        if '@Published var scrollOffset:' in line: continue
        for rule, pattern in patterns.items():
            if re.search(pattern, line): failures.append(f'{path.relative_to(root)}:{number}: {rule}: {line.strip()}')
if failures:
    print('\n'.join(failures)); sys.exit(1)
print('No raw colors, point dimensions, spacing, opacity, or padding in app source.')
