"""Same-seed gate: compare the autotest summary / metric lines of two logs (wall-clock bits masked)."""
import re
import sys


def lines(path):
    out = []
    for ln in open(path, errors='replace'):
        ln = ln.rstrip('\n')
        if not (ln.startswith('[autotest]') or ln.startswith('[metric]')):
            continue
        ln = re.sub(r'[\d.]+ s real time', 'X s real time', ln)
        ln = re.sub(r'step_avg=[\d.]+ms', 'step_avg=X', ln)
        ln = re.sub(r'(avg|worst|max)[ _]step[^|,]*', 'STEP', ln)
        ln = re.sub(r'real [\d.]+ ?s', 'real X', ln)
        ln = re.sub(r'\d+(\.\d+)? ?ms', 'Xms', ln)
        out.append(ln)
    return out


a, b = lines(sys.argv[1]), lines(sys.argv[2])
import difflib
d = [x for x in difflib.unified_diff(a, b, lineterm='', n=0) if not x.startswith('@@')]
print('\n'.join(d[2:]) if d else 'IDENTICAL')
print('lines: %d vs %d' % (len(a), len(b)))
