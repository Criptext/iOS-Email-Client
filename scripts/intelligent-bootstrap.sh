#!/bin/sh
if ! cmp -s Cartfile.resolved Carthage/Cartfile.resolved; then
  scripts/bootstrap.sh
fi