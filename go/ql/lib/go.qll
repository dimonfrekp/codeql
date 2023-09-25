/**
 * Provides classes for working with Go programs.
 */

import Customizations
import semmle.go.Architectures
import semmle.go.AST
import semmle.go.Comments
import semmle.go.Concepts
import semmle.go.Decls
import semmle.go.Errors
import semmle.go.Expr
import semmle.go.Files
import semmle.go.GoMod
import semmle.go.HTML
import semmle.go.Locations
import semmle.go.Packages
import semmle.go.Scopes
import semmle.go.Stmt
import semmle.go.StringOps
import semmle.go.Types
import semmle.go.Util
import semmle.go.VariableWithFields
import semmle.go.controlflow.BasicBlocks
import semmle.go.controlflow.ControlFlowGraph
import semmle.go.controlflow.IR
import semmle.go.dataflow.DataFlow
import semmle.go.dataflow.DataFlow2
import semmle.go.dataflow.GlobalValueNumbering
import semmle.go.dataflow.SSA
import semmle.go.dataflow.TaintTracking
import semmle.go.dataflow.TaintTracking2
import semmle.go.frameworks.Beego
import semmle.go.frameworks.BeegoOrm
import semmle.go.frameworks.Chi
import semmle.go.frameworks.Couchbase
import semmle.go.frameworks.Echo
import semmle.go.frameworks.ElazarlGoproxy
import semmle.go.frameworks.Email
import semmle.go.frameworks.Encoding
import semmle.go.frameworks.Gin
import semmle.go.frameworks.Fasthttp
import semmle.go.frameworks.Glog
import semmle.go.frameworks.GoMicro
import semmle.go.frameworks.GoRestfulHttp
import semmle.go.frameworks.Gqlgen
import semmle.go.frameworks.K8sIoApimachineryPkgRuntime
import semmle.go.frameworks.K8sIoApiCoreV1
import semmle.go.frameworks.K8sIoClientGo
import semmle.go.frameworks.Logrus
import semmle.go.frameworks.Macaron
import semmle.go.frameworks.Mux
import semmle.go.frameworks.NoSQL
import semmle.go.frameworks.Protobuf
import semmle.go.frameworks.Revel
import semmle.go.frameworks.Spew
import semmle.go.frameworks.SQL
import semmle.go.frameworks.Stdlib
import semmle.go.frameworks.SystemCommandExecutors
import semmle.go.frameworks.Testing
import semmle.go.frameworks.Twirp
import semmle.go.frameworks.WebSocket
import semmle.go.frameworks.XNetHtml
import semmle.go.frameworks.XPath
import semmle.go.frameworks.Yaml
import semmle.go.frameworks.Zap
import semmle.go.security.FlowSources
