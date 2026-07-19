if status is-interactive
    set -g fish_greeting
    set -u EDITOR neovim
    fish_vi_key_bindings

    mise activate fish | source
    oh-my-posh init fish --config "~/andrew.omp.json" | source
    fastfetch -c examples/13.jsonc
    zoxide init fish | source

    set -gx TAVILY_API_KEY "{{TAVILY_API_KEY}}"
    set -gx CONTEXT_7_API_KEY "{{CONTEXT_7_API_KEY}}"
    set -gx BRAVE_API_KEY "{{BRAVE_API_KEY}}"

    alias cd z
    alias grep rg
    alias ll "eza --long --icons"
    alias ls eza
    alias vim nvim
end

# pnpm
set -gx PNPM_HOME "/home/andrew/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
    set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end
