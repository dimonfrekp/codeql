/** Provides models of commonly used functions in the `github.com/sirupsen/logrus` package. */

import go

/** Provides models of commonly used functions in the `github.com/sirupsen/logrus` package. */
module Logrus {
  /** Gets the package name `github.com/sirupsen/logrus`. */
  string packagePath() {
    result = package(["github.com/sirupsen/logrus", "github.com/Sirupsen/logrus"], "")
  }

  bindingset[result]
  private string getALogResultName() {
    result
        .matches([
            "Debug%", "Error%", "Fatal%", "Info%", "Log%", "Panic%", "Print%", "Trace%", "Warn%"
          ])
  }

  bindingset[result]
  private string getAnEntryUpdatingMethodName() {
    result.regexpMatch("With(Context|Error|Fields?|Time)")
  }

  private class LogFunction extends Function {
    LogFunction() {
      exists(string name | name = getALogResultName() or name = getAnEntryUpdatingMethodName() |
        this.hasQualifiedName(packagePath(), name) or
        this.(Method).hasQualifiedName(packagePath(), ["Entry", "Logger"], name)
      )
    }
  }

  private class LogCall extends LoggerCall::Range, DataFlow::CallNode {
    LogCall() {
      // find calls to logrus logging functions
      this = any(LogFunction f).getACall() and
      // unless all formatters that get assigned may be sanitizing formatters
      not allFormattersMayBeSanitizing()
    }

    override DataFlow::Node getAMessageComponent() { result = this.getAnArgument() }
  }

  private class StringFormatters extends StringOps::Formatting::Range instanceof LogFunction {
    int argOffset;

    StringFormatters() {
      this.getName().matches("%f") and
      if this.getName() = "Logf" then argOffset = 1 else argOffset = 0
    }

    override int getFormatStringIndex() { result = argOffset }

    override int getFirstFormattedParameterIndex() { result = argOffset + 1 }
  }

  private class SetFormatterFunction extends Function {
    SetFormatterFunction() {
      this.hasQualifiedName(packagePath(), "SetFormatter") or
      this.(Method).hasQualifiedName(packagePath(), "Logger", "SetFormatter")
    }
  }

  private class JsonFormatter extends SanitizingFormatter {
    JsonFormatter() { this.hasQualifiedName(packagePath(), "JSONFormatter") }
  }

  /**
   * A type which represents a sanitizing formatter for Logrus.
   *
   * Extend this class to add support for additional, sanitizing formatters.
   */
  abstract class SanitizingFormatter extends Type { }

  /**
   * An assignment statement that assigns a value to the `Formatter` property of a `Logger` object.
   */
  private class SetFormatterAssignment extends AssignStmt {
    SetFormatterAssignment() {
      exists(Field field |
        this.getAnLhs().(SelectorExpr).uses(field) and
        field.hasQualifiedName(packagePath(), "Logger", "Formatter")
      )
    }
  }

  /**
   * Holds if there is local data flow to `node` that, at some point, has a sanitizing formatter
   * type.
   */
  private predicate mayBeSanitizingFormatter(DataFlow::Node node) {
    // is there data flow from something of a sanitizing formatter type to the node?
    exists(DataFlow::Node source |
      // this is a slight approximation since a variable could be set to a
      // sanitizing formatter and then replaced with another one that isn't
      DataFlow::localFlow(source, node) and
      source.getType() = any(SanitizingFormatter f).getPointerType()
    )
  }

  /**
   * Holds if `node` is the first argument to a call to the `SetFormatter` function or if `node`
   * is the value being assigned to the `Formatter` property of a `Logger` object.
   */
  private predicate isFormatter(DataFlow::Node node) {
    node = any(SetFormatterFunction f).getACall().getArgument(0)
    or
    node.asExpr() = any(SetFormatterAssignment stmt).getRhs()
  }

  /**
   * Holds if all calls to `SetFormatter` have a sanitizing formatter as argument and all
   * assignments to the `Formatter` property of `Logger` values are also sanitizing formatters.
   * Also holds if there are not any calls to `SetFormatter` or assignments to the `Formatter`
   * property in the codebase.
   */
  private predicate allFormattersMayBeSanitizing() {
    forex(DataFlow::Node node | isFormatter(node) | mayBeSanitizingFormatter(node))
  }
}
