#!/usr/bin/env python3
"""Backward-compatible shim → fs-organize.py --by smart

usage:
  fs-smart-organize.py [--dry-run] [--dest DIR] <source-dir>
"""
from __future__ import annotations

import runpy
import sys
from pathlib import Path

# Rewrite argv to call the unified organizer
script = Path(__file__).resolve().parent / "fs-organize.py"
# insert --by smart after program name if not already present
args = sys.argv[1:]
if "--by" not in args:
    args = ["--by", "smart", *args]
sys.argv = [str(script), *args]
runpy.run_path(str(script), run_name="__main__")
