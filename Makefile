.PHONY: _format_shell_deps format_shell_check format_shell format_shell_update_patches format_yaml_check format_yaml _lint_deps lint

_format_shell_deps: @bin/format.bash
	sosh fetch @bin/format.bash

format_shell_check: _format_shell_deps
	WITH_PATCHES=1 @bin/format.bash check

format_shell: _format_shell_deps
	WITH_PATCHES=1 @bin/format.bash apply

# Since formatting doesn't allow to ignore some parts, I apply patches before and after formatting to overcome this.
# Here are commands to update these patches
format_shell_update_patches:
	WITH_PATCHES=0 @bin/format.bash apply
	git commit -a --no-gpg-sign -m "patch"
	git revert --no-commit HEAD
	git commit -a --no-gpg-sign -m "patch revert"
	git diff HEAD~2..HEAD~1 > @bin/res/pre-format.patch
	git diff HEAD~1..HEAD > @bin/res/post-format.patch
	git reset HEAD~2
	git add @bin/res/pre-format.patch @bin/res/post-format.patch
	git commit -m "ci: Update patches"


format_yaml_check:
	yamlfmt --lint .

format_yaml:
	yamlfmt .

_lint_deps: @bin/lint.bash
	sosh fetch @bin/lint.bash

lint: _format_shell_deps _lint_deps
	\@bin/lint.bash

validate:
	circleci orb pack ./src > /tmp/orb
	circleci orb validate /tmp/orb
