#!/bin/sh
if [ $# != 1 ]; then
    echo You need to set the project id in the argument.
    exit 1
else
	firebase use $1
	firebase deploy --only firestore:rules
	firebase deploy --only firestore:indexes
fi