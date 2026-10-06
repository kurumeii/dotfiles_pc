function y --description "yazi, resuming in the last visited directory"
    set -l state ~/.local/state/yazi-last-cwd
    set -l start $argv
    if test (count $argv) -eq 0; and test -f $state
        set -l last (cat $state)
        test -d "$last"; and set start $last
    end
    set -l tmp (mktemp -t yazi-cwd.XXXXXX)
    command yazi $start --cwd-file=$tmp
    if set -l cwd (cat -- $tmp); and test -n "$cwd"
        mkdir -p (dirname $state)
        printf %s $cwd >$state
    end
    rm -f -- $tmp
end
