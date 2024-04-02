.PHONY: _format_deps format-check format format-update-patches _lint_deps lint

_format_deps: @bin/format.bash
	sosh fetch @bin/format.bash

format-check: _format_deps
	WITH_PATCHES=1 @bin/format.bash check

format: _format_deps
	WITH_PATCHES=1 @bin/format.bash apply

# Since formatting doesn't allow to ignore some parts, I apply patches before and after formatting to overcome this.
# Here are commands to update these patches
format-update-patches:
	WITH_PATCHES=0 @bin/format.bash apply
	git commit -a --no-gpg-sign -m "patch"
	git revert --no-commit HEAD
	git commit -a --no-gpg-sign -m "patch revert"
	git diff HEAD~2..HEAD~1 > @bin/res/pre-format.patch
	git diff HEAD~1..HEAD > @bin/res/post-format.patch
	git reset HEAD~2
	git add @bin/res/pre-format.patch @bin/res/post-format.patch
	git commit -m "ci: Update patches"

_lint_deps: @bin/lint.bash
	sosh fetch @bin/lint.bash

lint: _format_deps _lint_deps
	\@bin/lint.bash
