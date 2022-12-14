.NOTPARALLEL: ;          # wait for this target to finish
.EXPORT_ALL_VARIABLES: ; # send all vars to shell
.PHONY: all 			 			 # All targets are accessible for user
.DEFAULT: help 			 		 # Running Make will run the help target

PYTHON = @.venv/bin/python -m

# -------------------------------------------------------------------------------------------------
# help: @ List available tasks on this project
# -------------------------------------------------------------------------------------------------
help:
	@grep -oE '^#.[a-zA-Z0-9]+:.*?@ .*$$' $(MAKEFILE_LIST) | tr -d '#' |\
	awk 'BEGIN {FS = ":.*?@ "}; {printf "  make%-10s%s\n", $$1, $$2}'
	 
# -------------------------------------------------------------------------------------------------
# init: @ Setup local environment
# -------------------------------------------------------------------------------------------------
init: activate install

# -------------------------------------------------------------------------------------------------
# update: @ Update package dependencies and install them
# -------------------------------------------------------------------------------------------------
update: compile install

# -------------------------------------------------------------------------------------------------
# Activate virtual environment
# -------------------------------------------------------------------------------------------------
activate:
	@python3 -m venv .venv
	@. .venv/bin/activate 
	$(PYTHON) pip install pip-tools

# -------------------------------------------------------------------------------------------------
# Update package dependencies
# -------------------------------------------------------------------------------------------------
compile:
	$(PYTHON) piptools compile --upgrade requirements.in 
	$(PYTHON) piptools compile --upgrade requirements-dev.in
	
# -------------------------------------------------------------------------------------------------
# Install packages to current environment
# -------------------------------------------------------------------------------------------------
install:
	$(PYTHON) piptools sync requirements.txt requirements-dev.txt

# -------------------------------------------------------------------------------------------------
# run: @ Build and launch application in development mode
# -------------------------------------------------------------------------------------------------
run:
	$(PYTHON) app.main

# -------------------------------------------------------------------------------------------------
# serve: @ Run application with production web server
# -------------------------------------------------------------------------------------------------
serve:
	$(PYTHON) gunicorn app.main:app --worker-class aiohttp.GunicornWebWorker

# -------------------------------------------------------------------------------------------------
# up: @ Deploy test infrastructure
# -------------------------------------------------------------------------------------------------
up:
	@docker run -d \
	--name database \
	-e MONGO_INITDB_ROOT_USERNAME=demo \
	-e MONGO_INITDB_ROOT_PASSWORD=demo \
	-p 27017:27017 \
	mongo:latest
	
# -------------------------------------------------------------------------------------------------
# down: @ Destroy test infrastructure
# -------------------------------------------------------------------------------------------------
down:
	@docker stop database
	@docker rm database

# -------------------------------------------------------------------------------------------------
# test: @ Run tests using pytest
# -------------------------------------------------------------------------------------------------
test:
	$(PYTHON) pytest tests --cov=.

# -------------------------------------------------------------------------------------------------
# lint: @ Checks the source code against coding standard rules and safety
# -------------------------------------------------------------------------------------------------
lint: lint.flake8 lint.safety lint.docs

# -------------------------------------------------------------------------------------------------
# flake8 
# -------------------------------------------------------------------------------------------------
lint.flake8: 
	$(PYTHON) flake8 --exclude=.venv,.eggs,*.egg,.git,migrations \
									 --filename=*.py,*.pyx \
									 --max-line-length=100 .

# -------------------------------------------------------------------------------------------------
# safety 
# -------------------------------------------------------------------------------------------------
lint.safety: 
	$(PYTHON) safety check --full-report -r requirements.txt

# -------------------------------------------------------------------------------------------------
# pydocstyle
# -------------------------------------------------------------------------------------------------
# Ignored error codes:
#   D100	Missing docstring in public module
#   D101	Missing docstring in public class
#   D102	Missing docstring in public method
#   D103	Missing docstring in public function
#   D104	Missing docstring in public package
#   D105	Missing docstring in magic method
#   D106	Missing docstring in public nested class
#   D107	Missing docstring in __init__
lint.docs: 
	$(PYTHON) pydocstyle --convention=numpy --add-ignore=D100,D101,D102,D103,D104,D105,D106,D107 .

# -------------------------------------------------------------------------------------------------
# clean: @ Remove artifacts and temp files
# -------------------------------------------------------------------------------------------------
clean:
	@while read -r line; do echo "${line}"; done < .gitignore
