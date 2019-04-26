#!/usr/bin/env python

import json
import sys
import datetime


if __name__ == '__main__':
  now = datetime.datetime.now().isoformat()
  hosts = [h.strip() for h in sys.stdin.readlines()]

  output = {
    "description" : "Generated on %s" % now,
    "name" : "combined little-snitch blocked domains",
    "denied-remote-hosts" : hosts
  }

  json.dump(output, sys.stdout, indent=2)