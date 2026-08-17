lint-yaml:
	find . -type f -name '*.yaml' | xargs yamllint
