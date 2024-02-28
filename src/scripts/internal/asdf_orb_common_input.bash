#!/bin/bash

ASDF_DIR="${PARAM_ASDF_DIR:-${ASDF_DIR:-~/.asdf}}"
eval ASDF_DIR="${ASDF_DIR}"
# eval to resolve possible ~
