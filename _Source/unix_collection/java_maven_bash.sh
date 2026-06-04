#!/usr/bin/env zsh

# Java and Maven shell helpers sourced by 1_my_bash.sh.

# Switch JAVA_HOME to Java 21.
# Example: java21
java21() {
  export JAVA_HOME="${JAVA_HOME_21:?JAVA_HOME_21 is not set}"
}

# Switch JAVA_HOME to Java 25.
# Example: java25
java25() {
  export JAVA_HOME="${JAVA_HOME_25:?JAVA_HOME_25 is not set}"
}

# Use Java 25 by default when it is configured in private_environment.sh.
if [[ -n "${JAVA_HOME_25:-}" ]]; then
  java25
fi

# Add Maven to PATH from either MAVEN_HOME or M2_HOME.
if [[ -n "${MAVEN_HOME:-}" ]]; then
  export PATH="$MAVEN_HOME/bin:$PATH"
elif [[ -n "${M2_HOME:-}" ]]; then
  export PATH="$M2_HOME/bin:$PATH"
fi

# Build quickly by skipping tests/javadocs and using one Maven thread per CPU core.
# Example: mvnfire
alias mvnfire="mvn clean install -Dmaven.javadoc.skip=true -DskipTests -T1C"
