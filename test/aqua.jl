using Aqua

# Ambiguities are checked against dependencies we do not control; the extras
# check is disabled because Aqua itself is a test-only extra.
Aqua.test_all(Kezdi; ambiguities=false, deps_compat=(check_extras=false,))
