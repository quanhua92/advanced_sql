PYTHON ?= python3
.PHONY: up down psql test concurrency-test capstone validate backup reset
up:
	$(PYTHON) scripts/course.py up
down:
	$(PYTHON) scripts/course.py down
psql:
	$(PYTHON) scripts/course.py psql
test:
	$(PYTHON) scripts/course.py test
concurrency-test:
	$(PYTHON) scripts/course.py concurrency-test
capstone:
	$(PYTHON) scripts/course.py capstone
validate:
	$(PYTHON) scripts/validate_package.py
backup:
	$(PYTHON) scripts/course.py backup
reset:
	@echo 'Destructive reset requires: python scripts/course.py reset --yes'
