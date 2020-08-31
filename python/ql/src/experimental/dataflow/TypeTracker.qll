/** Step Summaries and Type Tracking */

import python
import internal.DataFlowPublic
import internal.DataFlowPrivate

/** Any string that may appear as the name of an attribute or access path. */
class AttributeName extends string {
  AttributeName() { this = any(Attribute a).getName() }
}

/** Either an attribute name, or the empty string (representing no attribute). */
class OptionalAttributeName extends string {
  OptionalAttributeName() { this instanceof AttributeName or this = "" }
}

/**
 * A description of a step on an inter-procedural data flow path.
 */
private newtype TStepSummary =
  LevelStep() or
  CallStep() or
  ReturnStep() or
  StoreStep(AttributeName attr) or
  LoadStep(AttributeName attr)

/**
 * INTERNAL: Use `TypeTracker` or `TypeBackTracker` instead.
 *
 * A description of a step on an inter-procedural data flow path.
 */
class StepSummary extends TStepSummary {
  /** Gets a textual representation of this step summary. */
  string toString() {
    this instanceof LevelStep and result = "level"
    or
    this instanceof CallStep and result = "call"
    or
    this instanceof ReturnStep and result = "return"
    or
    exists(string attr | this = StoreStep(attr) | result = "store " + attr)
    or
    exists(string attr | this = LoadStep(attr) | result = "load " + attr)
  }
}

module StepSummary {
  cached
  predicate step(Node pred, Node succ, StepSummary summary) {
    exists(Node mid | EssaFlow::essaFlowStep*(pred, mid) and smallstep(mid, succ, summary))
  }

  predicate smallstep(Node pred, Node succ, StepSummary summary) {
    EssaFlow::essaFlowStep(pred, succ) and
    summary = LevelStep()
    or
    callStep(pred, succ) and summary = CallStep()
    or
    returnStep(pred, succ) and
    summary = ReturnStep()
    or
    exists(string attr |
      basicStoreStep(pred, succ, attr) and
      summary = StoreStep(attr)
      or
      basicLoadStep(pred, succ, attr) and summary = LoadStep(attr)
    )
  }
}

/** Holds if `pred` steps to `succ` by being passed as a parameter in a call. */
predicate callStep(ArgumentNode pred, ParameterNode succ) {
  // TODO: Support special methods?
  exists(DataFlowCall call, int i |
    pred.argumentOf(call, i) and succ.isParameterOf(call.getCallable(), i)
  )
}

/** Holds if `pred` steps to `succ` by being returned from a call. */
predicate returnStep(ReturnNode pred, Node succ) {
  exists(DataFlowCall call |
    pred.getEnclosingCallable() = call.getCallable() and succ.asCfgNode() = call
  )
}

/**
 * Holds if `pred` is being written to the `attr` attribute of the object in `succ`.
 *
 * Note that the choice of `succ` does not have to make sense "chronologically".
 * All we care about is whether the `attr` attribute of `succ` can have a specific type,
 * and the assumption is that if a specific type appears here, then any access of that
 * particular attribute can yield something of that particular type.
 *
 * Thus, in an example such as
 *
 * ```python
 * def foo(y):
 *    x = Foo()
 *    bar(x)
 *    x.attr = y
 *    baz(x)
 *
 * def bar(x):
 *    z = x.attr
 * ```
 * for the attribute write `x.attr = y`, we will have `attr` being the literal string `"attr"`,
 * `pred` will be `y`, and `succ` will be the object `Foo()` created on the first line of the
 * function. This means we will track the fact that `x.attr` can have the type of `y` into the
 * assignment to `z` inside `bar`, even though this attribute write happens _after_ `bar` is called.
 */
predicate basicStoreStep(Node pred, Node succ, string attr) {
  exists(AttributeAssignment a, Node var |
    a.getName() = attr and
    EssaFlow::essaFlowStep*(succ, var) and
    var.asVar() = a.getInput() and
    pred.asCfgNode() = a.getValue()
  )
}

/**
 * Holds if `succ` is the result of accessing the `attr` attribute of `pred`.
 */
predicate basicLoadStep(Node pred, Node succ, string attr) {
  exists(AttrNode s | succ.asCfgNode() = s and s.getObject(attr) = pred.asCfgNode())
}

/**
 * A utility class that is equivalent to `boolean` but does not require type joining.
 */
private class Boolean extends boolean {
  Boolean() { this = true or this = false }
}

private newtype TTypeTracker = MkTypeTracker(Boolean hasCall, OptionalAttributeName attr)

/**
 * Summary of the steps needed to track a value to a given dataflow node.
 *
 * This can be used to track objects that implement a certain API in order to
 * recognize calls to that API. Note that type-tracking does not by itself provide a
 * source/sink relation, that is, it may determine that a node has a given type,
 * but it won't determine where that type came from.
 *
 * It is recommended that all uses of this type are written in the following form,
 * for tracking some type `myType`:
 * ```
 * Node myType(DataFlow::TypeTracker t) {
 *   t.start() and
 *   result = < source of myType >
 *   or
 *   exists (TypeTracker t2 |
 *     result = myType(t2).track(t2, t)
 *   )
 * }
 *
 * DataFlow::SourceNode myType() { result = myType(DataFlow::TypeTracker::end()) }
 * ```
 *
 * Instead of `result = myType(t2).track(t2, t)`, you can also use the equivalent
 * `t = t2.step(myType(t2), result)`. If you additionally want to track individual
 * intra-procedural steps, use `t = t2.smallstep(myCallback(t2), result)`.
 */
class TypeTracker extends TTypeTracker {
  Boolean hasCall;
  OptionalAttributeName attr;

  TypeTracker() { this = MkTypeTracker(hasCall, attr) }

  /** Gets the summary resulting from appending `step` to this type-tracking summary. */
  cached
  TypeTracker append(StepSummary step) {
    step = LevelStep() and result = this
    or
    step = CallStep() and result = MkTypeTracker(true, attr)
    or
    step = ReturnStep() and hasCall = false and result = this
    or
    step = LoadStep(attr) and result = MkTypeTracker(hasCall, "")
    or
    exists(string p | step = StoreStep(p) and attr = "" and result = MkTypeTracker(hasCall, p))
  }

  /** Gets a textual representation of this summary. */
  string toString() {
    exists(string withCall, string withAttr |
      (if hasCall = true then withCall = "with" else withCall = "without") and
      (if attr != "" then withAttr = " with attribute " + attr else withAttr = "") and
      result = "type tracker " + withCall + " call steps" + withAttr
    )
  }

  /**
   * Holds if this is the starting point of type tracking.
   */
  predicate start() { hasCall = false and attr = "" }

  /**
   * Holds if this is the starting point of type tracking, and the value starts in the attribute named `attrName`.
   * The type tracking only ends after the attribute has been loaded.
   */
  predicate startInAttr(AttributeName attrName) { hasCall = false and attr = attrName }

  /**
   * Holds if this is the starting point of type tracking
   * when tracking a parameter into a call, but not out of it.
   */
  predicate call() { hasCall = true and attr = "" }

  /**
   * Holds if this is the end point of type tracking.
   */
  predicate end() { attr = "" }

  /**
   * INTERNAL. DO NOT USE.
   *
   * Holds if this type has been tracked into a call.
   */
  boolean hasCall() { result = hasCall }

  /**
   * INTERNAL. DO NOT USE.
   *
   * Gets the attribute associated with this type tracker.
   */
  string getAttr() { result = attr }

  /**
   * Gets a type tracker that starts where this one has left off to allow continued
   * tracking.
   *
   * This predicate is only defined if the type has not been tracked into an attribute.
   */
  TypeTracker continue() { attr = "" and result = this }

  /**
   * Gets the summary that corresponds to having taken a forwards
   * heap and/or inter-procedural step from `pred` to `succ`.
   */
  pragma[inline]
  TypeTracker step(Node pred, Node succ) {
    exists(StepSummary summary |
      StepSummary::step(pred, succ, summary) and
      result = this.append(summary)
    )
  }

  /**
   * Gets the summary that corresponds to having taken a forwards
   * local, heap and/or inter-procedural step from `pred` to `succ`.
   *
   * Unlike `TypeTracker::step`, this predicate exposes all edges
   * in the flow graph, and not just the edges between `Node`s.
   * It may therefore be less performant.
   *
   * Type tracking predicates using small steps typically take the following form:
   * ```ql
   * DataFlow::Node myType(DataFlow::TypeTracker t) {
   *   t.start() and
   *   result = < source of myType >
   *   or
   *   exists (DataFlow::TypeTracker t2 |
   *     t = t2.smallstep(myType(t2), result)
   *   )
   * }
   *
   * DataFlow::Node myType() {
   *   result = myType(DataFlow::TypeTracker::end())
   * }
   * ```
   */
  pragma[inline]
  TypeTracker smallstep(Node pred, Node succ) {
    exists(StepSummary summary |
      StepSummary::smallstep(pred, succ, summary) and
      result = this.append(summary)
    )
    or
    EssaFlow::essaFlowStep(pred, succ) and
    result = this
  }
}
