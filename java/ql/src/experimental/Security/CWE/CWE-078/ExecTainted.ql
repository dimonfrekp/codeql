/**
 * @name Uncontrolled command line (experimental sinks)
 * @description Using externally controlled strings in a command line is vulnerable to malicious
 *              changes in the strings (includes experimental sinks).
 * @kind path-problem
 * @problem.severity error
 * @precision high
 * @id java/command-line-injection-experimental
 * @tags security
 *       external/cwe/cwe-078
 *       external/cwe/cwe-088
 *       experimental
 */

import java
import semmle.code.java.dataflow.FlowSources
import semmle.code.java.security.ExternalProcess
import semmle.code.java.security.CommandLineQuery
import JSchOSInjection
import DataFlow::PathGraph

// This is a clone of query `java/command-line-injection` that also includes experimental sinks.
from DataFlow::PathNode source, DataFlow::PathNode sink, ArgumentToExec execArg
where execTainted(source, sink, execArg)
select execArg, source, sink, "This command line depends on a $@.", source.getNode(),
  "user-provided value"
