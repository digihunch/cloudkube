#! /bin/bash
echo "Entering custom script"
ComName=`curl -s http://169.254.169.254/latest/meta-data/public-hostname|cut -d. -f2-`
echo "Leaving custom script"
