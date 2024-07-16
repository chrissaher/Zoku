#!/bin/bash
bash ./install.sh
# poetry run sphinx-apidoc -f -o docs/source ../your_project
poetry run sphinx-build -b html docs/source docs/build
# python -m http.server -d docs/build/
