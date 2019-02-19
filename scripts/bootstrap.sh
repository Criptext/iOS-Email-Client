#!/bin/bash
carthage bootstrap --platform iOS --no-use-binaries --cache-builds
cp Cartfile.resolved Carthage