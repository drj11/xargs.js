# xargs.js

Unix xargs for node.js

POSIX compliant.

The following POSIX options are implemented:

    ptxnsE

The options from XSI are not:

    IL

Any remaining deviations from the POSIX spec are bugs, and you should
[report them](https://github.com/drj11/xargs.js/issues).

# Technical Notes

POSIX requires that the exit status of xargs is 126 when the
utility can be located, but not invoked. It's basically
impossible to detect this correctly from Node.js
(child_process.spawn doesn't report errors from execvp
particularly usefuly), so this POSIX requirement isn't
implemented yet.

# Tests

    npm test
