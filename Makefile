package=rest
pyenv=ENV2
UNAME=$(shell uname)
export ROOT_DIR=${PWD}/cloudmesh/$(package)/
MONGOD=mongod --dbpath ~/.cloudmesh/data/db --bind_ip 127.0.0.1
EVE=cd $(ROOT_DIR); $(pyenv); python service.py
VERSION=`head -1 VERSION`

define banner
	@echo
	@echo "###################################"
	@echo $(1)
	@echo "###################################"
endef

ifeq ($(UNAME),Darwin)
define terminal
	osascript -e 'tell application "Terminal" to do script "$(1)"'
endef
endif
ifeq ($(UNAME),Linux)
define terminal
	echo "THIS HAS NOT YET BEEN TESTED"
	xterm -e '"$(1)"'
	# konsole -e '"$(1)"'
	# gnome-terminal -e '"$(1)"'
endef
endif
ifeq ($(UNAME),Windows)
define terminal
	echo "Windows not yet supported, fix me"
endef
endif

pull:
	cd ../common; git pull
	cd ../cmd5; git pull
	git pull

install:
	cd ../cloudmesh.cmd5; make install
	python setup.py install; pip install -e .

source:
	python setup.py install; pip install -e .
	cms help

setup:
	# brew update
	# brew install mongodb
	# brew install jq
	rm -rf ~/.cloudmesh/data/db
	mkdir -p ~/.cloudmesh/data/db

kill:
	killall mongod

mongo:
	$(call terminal, $(MONGOD))

eve:
	$(call terminal, $(EVE))




deploy: setup mongo eve
	pip install .
	echo deployed

test:
	$(call banner, "LIST SERVICE")
	curl -s -i http://127.0.0.1:5000 
	$(call banner, "LIST PROFILE")
	@curl -s http://127.0.0.1:5000/profile  | jq

other:
	$(call banner, "LIST CLUSTER")
	@curl -s http://127.0.0.1:5000/cluster  | jq
	$(call banner, "LIST COMPUTER")
	@curl -s http://127.0.0.1:5000/computer  | jq
	$(call banner, "INSERT COMPUTER")
	curl -d '{"name": "myCLuster",	"label": "c0","ip": "127.0.0.1","memoryGB": 16}' -H 'Content-Type: application/json'  http://127.0.0.1:5000/computer  
	$(call banner, "LIST COMPUTER")
	@curl -s http://127.0.0.1:5000/computer  | jq
	$(call banner, "LIST TEST")
	@curl -s http://127.0.0.1:5000/test  | jq

schema:
	cd cloudmesh/specification; cms schema cat examples settings.json
	cd cloudmesh/specification; cms schema convert settings.json

nosetests:
	nosetests -v --nocapture tests/test_mongo.py

envclean:
	pyenv uninstall ENV2
	rm -f /Users/grey/.pyenv/shims/cms
	pyenv virtualenv 2.7.13 ENV2 


clean:
	rm -rf *.zip
	rm -rf *.egg-info
	rm -rf *.eggs
	rm -rf docs/build
	rm -rf build
	rm -rf dist
	find . -name '__pycache__' -delete
	find . -name '*.pyc' -delete
	rm -rf .tox
	rm -f *.whl


#genie:
#	git clone https://github.com/drud/evegenie.git
#	cd evegenie; pip install -r requirements.txt

genie:
	git clone https://github.com/cloudmesh/evegenie.git
	cd evegenie; pip install -r requirements.txt
	cd evegenie; python setup.py install
	cd evegenie; pip install .


json:
	python evegenie/evegenie/geneve.py cluster_new.json
	cp cluster_new.settings.py $(ROOT_DIR)/settings.py
	cat $(ROOT_DIR)/settings.py

######################################################################
# PYPI
######################################################################

dist: clean
	@echo "######################################"
	@echo "# $(VERSION)"
	@echo "######################################"
	python setup.py sdist --formats=gztar,zip
	python setup.py bdist
	python setup.py bdist_wheel

upload_test:
	python setup.py	 sdist bdist bdist_wheel upload -r https://testpypi.python.org/pypi

log:
	gitchangelog | fgrep -v ":dev:" | fgrep -v ":new:" > ChangeLog
	git commit -m "chg: dev: Update ChangeLog" ChangeLog
	git push

register: dist
	@echo "######################################"
	@echo "# $(VERSION)"
	@echo "######################################"
	twine register dist/cloudmesh.$(package)-$(VERSION)-py2.py3-none-any.whl
	twine register dist/cloudmesh.$(package)-$(VERSION).macosx-10.12-x86_64.tar.gz
	twine register dist/cloudmesh.$(package)-$(VERSION).tar.gz
	twine register dist/cloudmesh.$(package)-$(VERSION).zip

upload: dist
	twine upload dist/*

#
# GIT
#

tag:
	touch README.rst
	git tag $(VERSION)
	git commit -a -m "$(VERSION)"
	git push
