"""Which server tests a pull request to development runs (docs/04-testing.md): those of the modules it touches.

Reads the changed paths (one per line) from stdin and prints the value for Maven's -Dtest, or nothing when
everything has to run: a change outside the module folders (pom, resources, migrations, shared cases) can break
any module. Releases (pull requests to main) and pushes always run everything; the CI does not call this then.
"""

import re
import sys

PACKAGE = "dev/rgal/brackety"
MODULE = re.compile(rf"^server/src/(?:main|test|devdata)/java/{PACKAGE}/([a-z]+)/")
ROOT_TEST = re.compile(rf"^server/src/test/java/{PACKAGE}/(\w+)\.java$")
# Cheap and about every module: the package rules. A changed controller also checks the permission matrix
# (every endpoint has its row).
ALWAYS = ["ArchitectureTest"]
CONTROLLER = re.compile(r"Controller\.java$")


def tests_for(paths):
    """The -Dtest patterns for these changed paths, or None for everything."""
    modules, classes = set(), set(ALWAYS)
    for path in paths:
        if not path.startswith(("server/", "spec/")):
            continue
        if module := MODULE.match(path):
            modules.add(module.group(1))
            if CONTROLLER.search(path):
                classes.add("PermissionMatrixTest")
        elif root := ROOT_TEST.match(path):
            classes.add(root.group(1))
        else:
            return None
    patterns = [f"dev.rgal.brackety.{m}.**.*Test,dev.rgal.brackety.{m}.**.*Tests" for m in sorted(modules)]
    return ",".join(patterns + sorted(classes))


if __name__ == "__main__":
    tests = tests_for(line.strip() for line in sys.stdin if line.strip())
    print(tests or "")
