.PHONY: lint format-check format-apply

lint:
	bash @bin/lint.bash

format-check:
	bash @bin/format-check.bash

format-apply:
	bash @bin/format-apply.bash
