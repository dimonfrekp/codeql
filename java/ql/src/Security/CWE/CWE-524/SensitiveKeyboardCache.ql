/**
 * @name Android sensetive keyboard cache
 * @description Sensitive information should not be saved to the keyboard cache.
 * @kind problem
 * @problem.severity warning
 * @id java/android/sensetive-keyboard-cache
 * @tags security
 *       external/cwe/cwe-524
 * @precision high
 */

import java
import semmle.code.java.security.SensitiveKeyboardCacheQuery

from AndroidEditableXmlElement el
where el = getASensitiveCachedInput()
select el, "This input field may contain sensitive information that is saved to the keyboard cache."
