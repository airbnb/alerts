#!/bin/bash

!(find . -name \*.rb -exec ruby -c '{}' \; 2>&1 | grep -v "Syntax OK")
