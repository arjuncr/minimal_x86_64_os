# @author ARJUN C R (arjuncr00@gmail.com)
#
# web site https://www.acrlinux.com
#
#!/bin/bash

set -e

for script in $(ls | grep '^[000-999]*_.*.sh'); do
  echo "Executing script '$script'."
  ./$script $1
done
