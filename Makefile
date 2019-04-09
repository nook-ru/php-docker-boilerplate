ARGS = $(filter-out $@,$(MAKECMDGOALS))
MAKEFLAGS += --silent

list:
	sh -c "echo; $(MAKE) -p no_targets__ | awk -F':' '/^[a-zA-Z0-9][^\$$#\/\\t=]*:([^=]|$$)/ {split(\$$1,A,/ /);for(i in A)print A[i]}' | grep -v '__\$$' | grep -v 'Makefile'| sort"

#############################
# Create new project
#############################

create:
	bash bin/create-project.sh $(ARGS)

bx-restore:
	bash bin/bx-restore.sh $(ARGS)
	restart

#############################
# Docker machine states
#############################

up:
	docker-compose up -d

down:
	docker-compose stop
	docker-compose down -v

start:
	docker-compose start

stop:
	docker-compose stop

restart: stop start

state:
	docker-compose ps

rebuild:
	docker-compose stop
	docker-compose pull
	docker-compose rm --force app
	docker-compose build --no-cache --pull
	docker-compose up -d --force-recreate

#############################
# Files
#############################

files-backup:
	bash ./bin/backup-files.sh

files-restore:
	bash ./bin/restore-files.sh

#############################
# MySQL
#############################

mysql-backup:
	bash ./bin/backup.sh mysql

mysql-restore:
	bash ./bin/restore.sh mysql

#############################
# Solr
#############################

solr-backup:
	bash ./bin/backup.sh solr

solr-restore:
	bash ./bin/restore.sh solr

#############################
# General
#############################

backup:  mysql-backup  solr-backup	files-backup
restore: mysql-restore solr-restore files-restore

build:
	bash bin/build.sh

bash: shell

shell:
	docker-compose exec --user application app /bin/bash

root:
	docker-compose exec --user root app /bin/bash

#############################
# Argument fix workaround
#############################
%:
	@:
