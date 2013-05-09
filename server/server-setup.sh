####
# Copyright (c) 2013 Chris J Daly (github user cjdaly)
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#   cjdaly - initial API and implementation
####

# add Java to $PATH
echo
if ! which java &> /dev/null ; then
  echo "Adding java to PATH"
  export JAVA_HOME=~/java/ejre1.7.0_21
  export PATH=$JAVA_HOME/bin:$PATH
fi
echo "Java version"
java -version

# add Neo4j to $PATH
echo
if ! which neo4j &> /dev/null ; then
  echo "Adding neo4j to PATH"
  export NEO4J_HOME=~/neo4j/neo4j-community-1.8.2
  export PATH=$NEO4J_HOME/bin:$PATH
fi
echo "Neo4j status"
neo4j status

# add JRuby to $PATH
echo
if ! which jruby &> /dev/null ; then
  echo "Adding jruby to PATH"
  export JRUBY_HOME=~/jruby/jruby-1.7.3
  export PATH=$JRUBY_HOME/bin:$PATH
fi
echo "JRuby version (wait for it...)"
jruby -v

echo

