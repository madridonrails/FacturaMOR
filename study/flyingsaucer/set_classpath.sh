# source this file to set the classpath:
#
#  $ source set_classpath.sh
#

cwd=`pwd`
CLASSPATH=.

for jar in $cwd/../../lib/flyingsaucer/*.jar
do
    CLASSPATH=$CLASSPATH:$jar
done

export CLASSPATH

