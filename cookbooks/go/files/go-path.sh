#!/bin/sh --this-shebang-is-just-here-to-inform-shellcheck--

if [ "${PATH#*/usr/local/go/bin}" = "${PATH}" ]; then
    export PATH=$PATH:/usr/local/go/bin
fi
