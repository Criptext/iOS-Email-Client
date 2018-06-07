#!/bin/bash
carthage bootstrap $@ --platform iphoneos --no-use-binaries || exit $?