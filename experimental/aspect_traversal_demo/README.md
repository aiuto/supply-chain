# Aspect traversal vs. package_metadata

Demonstration of an unexpected problem with aspect traversal
and the global `package_metadata` attribute.

The aspect will only visit the top level labels of targets
specified via `package_metadata`, and not their deps.

This makes it difficult to gather all attributes at analysis time,
you must read the generated files.
