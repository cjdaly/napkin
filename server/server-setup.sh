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
echo "Adding java to PATH"
case `uname -i` in
  x86*) export JAVA_HOME=~/java/jdk1.7.0_45;;
  arm*) export JAVA_HOME=~/java/sflt/ejre1.7.0_45;;
esac
export PATH=$JAVA_HOME/bin:$PATH
echo "Java version"
java -version

# add Neo4j to $PATH
echo
echo "Adding neo4j to PATH"
export NEO4J_HOME=~/neo4j/neo4j-community-2.0.0
export PATH=$NEO4J_HOME/bin:$PATH
echo "Neo4j status"
neo4j status

# add JRuby to $PATH
echo
echo "Adding jruby to PATH"
export JRUBY_HOME=~/jruby/jruby-1.7.9
export PATH=$JRUBY_HOME/bin:$PATH
echo "JRuby version"
jruby -v

echo

