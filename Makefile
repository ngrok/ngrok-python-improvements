# system python interpreter. used only to create virtual environment
PY = python3
VENV = venv
BIN=$(VENV)/bin
SHELL=/bin/bash

# make it work on windows too
ifeq ($(OS), Windows_NT)
	BIN=$(VENV)/Scripts
	PY=python
endif

all: venv run

venv:
	: # Create venv if it doesn't exist
	test -d $(VENV) || ($(PY) -m venv $(VENV) && $(BIN)/pip install -r requirements.txt)

install: venv
	. $(BIN)/activate && pip install -r requirements.txt

examples-install: venv
	. $(BIN)/activate && pip install -r examples/requirements.txt --quiet

develop: venv
	. $(BIN)/activate && maturin develop

build: venv
	. $(BIN)/activate && maturin build

run: develop
	. $(BIN)/activate && ./examples/ngrok-http-minimal.py

run-aio: develop examples-install
	. $(BIN)/activate && python ./examples/aiohttp-ngrok.py

run-forward-full: develop
	. $(BIN)/activate && python ./examples/ngrok-forward-full.py

run-forward-minimal: develop
	. $(BIN)/activate && python ./examples/ngrok-forward-minimal.py

run-django: develop examples-install
	. $(BIN)/activate && python ./examples/django-single-file.py

# Run django using the manage.py which is auto-generated by "django-admin startproject"
# The manage.py file has the ngrok listener setup code.
run-djangosite: develop examples-install
	. $(BIN)/activate && python ./examples/djangosite/manage.py runserver localhost:1234

# Run django ASGI via uvicorn. The ngrok-asgi.py file has the ngrok listener setup code.
run-django-uvicorn: develop examples-install
	. $(BIN)/activate && pushd ./examples/djangosite && python -m uvicorn djangosite.ngrok-asgi:application

# Run django ASGI via gunicorn. The ngrok-asgi.py file has the ngrok listener setup code.
run-django-gunicorn: develop examples-install
	. $(BIN)/activate && pushd ./examples/djangosite && python -m gunicorn djangosite.ngrok-asgi:application -k uvicorn.workers.UvicornWorker

# Run ngrok ASGI via uvicorn. The python/ngrok/__main__.py file has the ngrok listener setup code.
run-ngrok-uvicorn: develop examples-install
	. $(BIN)/activate && pushd ./examples/djangosite && python -m ngrok uvicorn djangosite.asgi:application $(args)

# Run ngrok ASGI via gunicorn. The python/ngrok/__main__.py file has the ngrok listener setup code.
run-ngrok-gunicorn: develop examples-install
	. $(BIN)/activate && pushd ./examples/djangosite && python -m ngrok gunicorn djangosite.asgi:application -k uvicorn.workers.UvicornWorker $(args)

# Run ngrok-asgi script via uvicorn. The python/ngrok/__main__.py file has the ngrok listener setup code.
run-ngrok-asgi: develop examples-install
	. $(BIN)/activate && pushd ./examples/djangosite && ngrok-asgi uvicorn djangosite.asgi:application $(args)

run-flask: develop examples-install
	. $(BIN)/activate && python ./examples/flask-ngrok.py

run-flasksite: develop examples-install
	. $(BIN)/activate && python ./examples/flasksite/app.py

run-gradio: develop
	. $(BIN)/activate && pip install -r examples/gradio/requirements.txt
	. $(BIN)/activate && gradio ./examples/gradio/gradio-ngrok.py

run-gradio-asgi: develop
	. $(BIN)/activate && pip install -r examples/gradio/requirements.txt
	. $(BIN)/activate && ngrok-asgi uvicorn examples.gradio.gradio-asgi:demo.app --port 7860 --reload

run-tornado: develop examples-install
	. $(BIN)/activate && python ./examples/tornado-ngrok.py

run-streamlit: develop examples-install
	. $(BIN)/activate && pushd ./examples/streamlit && python streamlit-ngrok.py

run-full: develop
	. $(BIN)/activate && ./examples/ngrok-http-full.py

run-labeled: develop
	. $(BIN)/activate && ./examples/ngrok-labeled.py

run-openplayground: develop
	. $(BIN)/activate && pip install -r examples/openplayground/requirements.txt
	. $(BIN)/activate && python examples/openplayground/run.py

run-gpt4all: develop
	. $(BIN)/activate && pip install -r examples/gpt4all/requirements.txt --quiet
	. $(BIN)/activate && python examples/gpt4all/run.py

run-tcp: develop
	. $(BIN)/activate && ./examples/ngrok-tcp.py

run-tls: develop
	. $(BIN)/activate && ./examples/ngrok-tls.py

run-uvicorn: develop examples-install
	. $(BIN)/activate && python ./examples/uvicorn-ngrok.py


run-sanic-asgi: develop examples-install
	. $(BIN)/activate && ngrok-asgi uvicorn examples.sanic.sanic-ngrok:app $(args) --policy-file examples/sanic/block-shadow.json

mypy: develop
	. $(BIN)/activate && mypy ./examples/ngrok-forward-minimal.py
	. $(BIN)/activate && mypy ./examples/ngrok-forward-full.py
	. $(BIN)/activate && mypy ./examples/ngrok-http-minimal.py
	. $(BIN)/activate && mypy ./examples/ngrok-http-full.py
	. $(BIN)/activate && mypy ./examples/ngrok-labeled.py
	. $(BIN)/activate && mypy ./examples/ngrok-tcp.py
	. $(BIN)/activate && mypy ./examples/ngrok-tls.py

# e.g.: make test='-k TestNgrok.test_gzip_listener' test
test: develop
	. $(BIN)/activate && python -m unittest discover test $(test)

# testfast is called by github workflow in ci.yml
testfast: develop
	. $(BIN)/activate && py.test -n 4 ./test/test*.py

testpublish:
	. $(BIN)/activate && maturin publish --repository testpypi

docs: clean develop black docsfast

docsfast : develop
	. $(BIN)/activate && sphinx-build -a -E -b html doc_source/ docs/

black: develop
	. $(BIN)/activate && black examples/ test/ python/ ngrok_extra/

clean:
	rm -rf $(VENV) target/
