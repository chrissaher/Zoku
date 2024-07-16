# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

# Example configurations in conf.py
# Add your project's source code directory to the Python path
import os
import sys

# pylint: disable=missing-module-docstring, redefined-builtin, invalid-name
from typing import List

sys.path.insert(0, os.path.abspath("../../"))

project = "Zoku"
copyright = "2024, chrissaher"
author = "chrissaher"

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

templates_path = ["_templates"]


# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = "alabaster"
html_static_path = ["_static"]

# Configure extensions
extensions: List[str] = [
    "sphinx.ext.autodoc",
    "sphinx.ext.viewcode",
    # Add more extensions as needed
]
