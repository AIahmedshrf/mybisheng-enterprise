#!/bin/sh
curl -f http://localhost:3001/health || exit 1
