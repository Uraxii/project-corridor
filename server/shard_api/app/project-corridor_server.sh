#!/bin/sh
echo -ne '\033c\033]0;project-corridor\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/project-corridor_0-0-0.x86_64" "$@"
