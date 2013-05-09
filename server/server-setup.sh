
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
echo "JRuby version"
jruby -v

echo

