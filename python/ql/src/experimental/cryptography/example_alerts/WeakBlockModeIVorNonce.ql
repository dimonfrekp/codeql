/**
 * @name Weak block mode IV or nonce
 * @description Finds initialization vectors or nonces used by block modes that are weak, obsolete, or otherwise unaccepted.
 *              Looks for IVs or nonces that are not generated by a cryptographically secure random number generator
 *              
 *            NOTE: for simplicity, if an IV or nonce is not known or not form os.urandom it is flagged. 
 *                  More specific considerations, such as correct use of nonces are currently not handled. 
 *                  In particular, GCM requires the use of a nonce. Using urandom is possible but may still be configured 
 *                  incorrectly. We currently assume that GCM is flagged as a block mode regardless through a separate
 *                  query, and such uses will need to be reivewed by the crypto board. 
 *              
 *                  Additionally, some functions, which infer a mode and IV may be flagged by this query.
 *                  For now, we will rely on users suppressing these cases rather than filtering them out.
 *                  The exception is Fernet, which is explicitly ignored since it's implementation uses os.urandom.
 * 
 * @id py/weak-block-mode-iv-or-nonce
 * @kind problem
 * @problem.severity error
 * @precision high
 */


import python
import experimental.cryptography.Concepts

from BlockMode op, string msg, DataFlow::Node conf
where 
not op instanceof CryptographyModule::Encryption::SymmetricEncryption::Fernet::CryptographyFernet and
(not op.hasIVorNonce() or not API::moduleImport("os").getMember("urandom").getACall() = op.getIVorNonce())
and 
if not op.hasIVorNonce()
then conf = op and msg = "Block mode is missing IV/Nonce initialization."
else conf = op.getIVorNonce() and msg = "Block mode is not using an accepted IV/Nonce initialization: $@"
select op, msg, conf, conf.toString()

