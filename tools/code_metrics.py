#!/usr/bin/env python3
"""Code size and structure metrics (docs/producto/plan-limpieza.md, phase L0).

    python tools/code_metrics.py            report
    python tools/code_metrics.py --check    fail if any metric is above tools/code_metrics.json
    python tools/code_metrics.py --update   write the current numbers as the new limits

The limits only go down: a PR that improves a metric lowers its limit with --update.
"""

import hashlib
import json
import os
import re
import sys
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIMITS_FILE = os.path.join(ROOT, 'tools', 'code_metrics.json')

SOURCES = [
    ('server/src/main/java', '.java'),
    ('app/lib', '.dart'),
    ('admin/lib', '.dart'),
    ('packages/brackety_core/lib', '.dart'),
]
MAX_FILE_LINES = {'.dart': 400, '.java': 300}
# Lines are capped by the docs CI job; long lines hide a long doc, so characters are capped too.
MAX_DOC_CHARS = 12000
MAX_METHOD_LINES = 60
DUPLICATE_WINDOW = 8
# The formatters (dart format, Spotless) put class members at this indentation.
MEMBER_INDENT = {'.dart': (0, 2), '.java': (4,)}

TYPE_DECLARATION = re.compile(
    r'^\s*(?:@\w+\s+)*(?:(?:public|private|protected|abstract|final|sealed|base|static|interface)\s+)*'
    r'(?:class|enum|mixin|extension|interface|record)\b'
)


def source_files():
    for base, ext in SOURCES:
        for directory, _, names in os.walk(os.path.join(ROOT, base)):
            relative_dir = os.path.relpath(directory, ROOT).replace(os.sep, '/')
            if '/l10n' in relative_dir:
                continue
            for name in sorted(names):
                if name.endswith(ext) and not name.endswith('.g.dart'):
                    yield f'{relative_dir}/{name}', ext


def read_lines(path):
    with open(os.path.join(ROOT, path), encoding='utf8') as file:
        return file.read().split('\n')


def indent_of(line):
    return len(line) - len(line.lstrip(' '))


def body_start(lines, start):
    """Index of the line that opens the member's block, or None for fields and `=>` members."""
    for index in range(start, min(start + 8, len(lines))):
        code = lines[index].split('//')[0].rstrip()
        if '=>' in code or code.endswith(';'):
            return None
        if code.endswith('{'):
            return index
    return None


def long_methods(path, ext, lines):
    found = []
    index = 0
    while index < len(lines):
        line = lines[index]
        stripped = line.strip()
        is_member = (
            stripped
            and indent_of(line) in MEMBER_INDENT[ext]
            and ('(' in stripped or ' get ' in f' {stripped}')
            and not stripped.startswith(('}', '//', '*', '/*', '@', 'import', 'package', 'part', 'return'))
            and not TYPE_DECLARATION.match(line)
        )
        opening = body_start(lines, index) if is_member else None
        if opening is None:
            index += 1
            continue
        end = opening + 1
        while end < len(lines) and not (indent_of(lines[end]) == indent_of(line) and lines[end].strip().startswith('}')):
            end += 1
        length = end - index + 1
        if length >= MAX_METHOD_LINES:
            name = re.search(r'(\w+)\s*(?:=|\(|\{)', stripped)
            found.append(f'{path}:{index + 1} {name.group(1) if name else "?"} ({length})')
        index = end + 1
    return found


def duplicate_windows(files):
    seen = defaultdict(set)
    for path, lines in files:
        code = [
            re.sub(r'\s+', ' ', line.strip())
            for line in lines
            if len(line.strip()) > 3 and not line.strip().startswith(('import', '//', '*', '/*', 'package', '@', '}', ')', ']'))
        ]
        for start in range(len(code) - DUPLICATE_WINDOW):
            window = '\n'.join(code[start:start + DUPLICATE_WINDOW])
            seen[hashlib.md5(window.encode()).hexdigest()].add(path)
    groups = defaultdict(int)
    for paths in seen.values():
        if len(paths) > 1:
            groups[' | '.join(sorted(paths))] += 1
    return sorted(((count, paths) for paths, count in groups.items()), reverse=True)


def feature_of(path, app_root):
    prefix = f'{app_root}/lib/features/'
    return path[len(prefix):].split('/')[0] if path.startswith(prefix) else None


def feature_cycles(app_root, package):
    """Features of a Flutter app that import each other, directly or through others."""
    graph = defaultdict(set)
    for path, ext in source_files():
        source = feature_of(path, app_root)
        if source is None:
            continue
        for target in re.findall(r"^import '([^']+)'", '\n'.join(read_lines(path)), re.M):
            if target.startswith(f'package:{package}/'):
                resolved = f'{app_root}/lib/{target.split("/", 1)[1]}'
            elif ':' in target:
                continue
            else:
                resolved = os.path.normpath(os.path.join(os.path.dirname(path), target)).replace(os.sep, '/')
            destination = feature_of(resolved, app_root)
            if destination and destination != source:
                graph[source].add(destination)
    return strongly_connected(graph)


def strongly_connected(graph):
    """Tarjan: groups of nodes that all reach each other, with more than one node."""
    index, low, stack, on_stack, groups = {}, {}, [], set(), []

    def visit(node):
        index[node] = low[node] = len(index)
        stack.append(node)
        on_stack.add(node)
        for neighbour in sorted(graph[node]):
            if neighbour not in index:
                visit(neighbour)
                low[node] = min(low[node], low[neighbour])
            elif neighbour in on_stack:
                low[node] = min(low[node], index[neighbour])
        if low[node] == index[node]:
            group = []
            while True:
                member = stack.pop()
                on_stack.discard(member)
                group.append(member)
                if member == node:
                    break
            if len(group) > 1:
                groups.append(sorted(group))

    for node in sorted(list(graph)):
        if node not in index:
            visit(node)
    return groups


def long_docs():
    found = []
    for directory, _, names in os.walk(os.path.join(ROOT, 'docs')):
        for name in sorted(names):
            path = os.path.join(directory, name)
            relative = os.path.relpath(path, ROOT).replace(os.sep, '/')
            if not name.endswith('.md') or relative.startswith('docs/historico/'):
                continue
            with open(path, encoding='utf8') as file:
                size = len(file.read())
            if size > MAX_DOC_CHARS:
                found.append(f'{relative} ({size})')
    return sorted(found)


def measure():
    """Each metric: its name, the number the limit applies to and the details that explain it."""
    files = [(path, ext, read_lines(path)) for path, ext in source_files()]
    big_files = defaultdict(list)
    methods = []
    for path, ext, lines in files:
        if len(lines) > MAX_FILE_LINES[ext]:
            big_files[ext].append(f'{path} ({len(lines)})')
        methods += long_methods(path, ext, lines)
    cycles = feature_cycles('app', 'brackety') + feature_cycles('admin', 'brackety_admin')
    docs = long_docs()
    duplicates = duplicate_windows([(path, lines) for path, _, lines in files])
    return [
        (f'Dart files over {MAX_FILE_LINES[".dart"]} lines', len(big_files['.dart']), big_files['.dart']),
        (f'Java files over {MAX_FILE_LINES[".java"]} lines', len(big_files['.java']), big_files['.java']),
        (f'Methods of {MAX_METHOD_LINES} lines or more', len(methods), methods),
        (
            'Features in an import cycle (app, admin)',
            sum(len(group) for group in cycles),
            [', '.join(group) + ' reach each other' for group in cycles],
        ),
        (
            f'Duplicated {DUPLICATE_WINDOW}-line windows',
            sum(count for count, _ in duplicates),
            [f'{count} windows: {paths}' for count, paths in duplicates[:20]],
        ),
        (f'Docs over {MAX_DOC_CHARS} characters', len(docs), docs),
    ]


def read_limits():
    if not os.path.exists(LIMITS_FILE):
        return {}
    with open(LIMITS_FILE, encoding='utf8') as file:
        return json.load(file)


def main():
    metrics = measure()
    limits = read_limits()
    print('| Metric | Now | Limit |')
    print('|---|---|---|')
    for name, count, _ in metrics:
        print(f'| {name} | {count} | {limits.get(name, "-")} |')
    for name, _, details in metrics:
        if details:
            print(f'\n### {name}')
            print('\n'.join(f'- {item}' for item in details))

    counts = {name: count for name, count, _ in metrics}
    if '--update' in sys.argv:
        with open(LIMITS_FILE, 'w', encoding='utf8', newline='\n') as file:
            json.dump(counts, file, indent=2, ensure_ascii=False)
            file.write('\n')
        print(f'\nLimits written to {os.path.relpath(LIMITS_FILE, ROOT)}.')
    elif '--check' in sys.argv:
        worse = [name for name, count in counts.items() if count > limits.get(name, 0)]
        better = [name for name, count in counts.items() if count < limits.get(name, 0)]
        if worse:
            print(f'\nWorse than the limit: {"; ".join(worse)}. Fix it, do not raise the limit.')
            return 1
        if better:
            print(f'\nBetter than the limit: {"; ".join(better)}. Lower it with --update in this PR.')
    return 0


if __name__ == '__main__':
    sys.exit(main())


