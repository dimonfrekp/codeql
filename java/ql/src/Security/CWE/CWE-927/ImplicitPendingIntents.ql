/**
 * @name Use of implicit Pending Intents
 * @description Implicit and mutable PendingIntents being sent to an unspecified third party
 *              component may provide access to internal components of the application or cause
 *              other unintended effects.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 8.2
 * @precision high
 * @id java/android/pending-intents
 * @tags security
 *       external/cwe/cwe-927
 */

import java
import semmle.code.java.dataflow.DataFlow
import semmle.code.java.security.ImplicitPendingIntentsQuery
import DataFlow::PathGraph

from DataFlow::PathNode source, DataFlow::PathNode sink
where any(ImplicitPendingIntentStartConf conf).hasFlowPath(source, sink)
select sink.getNode(), source, sink,
  "An implicit and mutable pending Intent is created $@ and sent to an unspecified third party.",
  source.getNode(), "here"
