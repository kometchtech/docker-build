#!/usr/bin/env python3
"""Select Docker builds and registry syncs for a workflow run."""
import json
import os
import subprocess
from pathlib import Path


def git(*args):
    return subprocess.check_output(['git', *args], text=True).splitlines()


def main():
    event = os.environ['EVENT_NAME']
    if event == 'workflow_dispatch':
        if os.environ['GITHUB_REF'] != 'refs/heads/master':
            raise ValueError('Manual builds must run on master')
        directory = os.environ['INPUT_DIRECTORY']
        variant = os.environ['INPUT_VARIANT']
        if not directory or not all(part not in ('', '.', '..') for part in directory.split('/')):
            raise ValueError('Invalid image directory')
        if variant not in ('stable', 'alpha'):
            raise ValueError('Invalid build variant')
        dockerfile = Path(directory, 'Dockerfile' + ('.alpha' if variant == 'alpha' else ''))
        if not dockerfile.is_file():
            raise ValueError(f'Dockerfile not found: {dockerfile}')
        targets = [{'directory': directory, 'variant': variant}]
    else:
        before = os.environ.get('BEFORE_COMMIT', '')
        if not before or subprocess.run(['git', 'cat-file', '-e', f'{before}^{{commit}}'], stderr=subprocess.DEVNULL).returncode:
            before = 'HEAD^'
        files = git('diff', '--name-only', before, 'HEAD')
        targets = []
        for directory in sorted({str(Path(f).parent) for f in files if Path(f).name in ('Dockerfile', 'Dockerfile.alpha', 'VERSION', 'VERSION.alpha', 'entrypoint.sh')}):
            changed = {Path(f).name for f in files if str(Path(f).parent) == directory}
            for variant, relevant, dockerfile in (
                ('stable', {'Dockerfile', 'VERSION', 'entrypoint.sh'}, 'Dockerfile'),
                ('alpha', {'Dockerfile.alpha', 'VERSION.alpha', 'entrypoint.sh'}, 'Dockerfile.alpha'),
            ):
                if changed & relevant and Path(directory, dockerfile).is_file():
                    targets.append({'directory': directory, 'variant': variant})
    directories = sorted({target['directory'] for target in targets})
    with open(os.environ['GITHUB_OUTPUT'], 'a', encoding='utf-8') as output:
        print('targets=' + json.dumps(targets, separators=(',', ':')), file=output)
        print('directories=' + json.dumps(directories, separators=(',', ':')), file=output)
    print('Build targets:', targets)


if __name__ == '__main__':
    main()
