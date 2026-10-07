if test -x /home/linuxbrew/.linuxbrew/bin/brew
    eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
end

if status is-interactive
    set -g fish_greeting
    set -gx EDITOR nvim
    fish_vi_key_bindings

    mise activate fish | source
    oh-my-posh init fish --config "~/andrew.omp.json" | source
    fastfetch
    zoxide init fish | source
    fzf --fish | source

    set -gx TAVILY_API_KEY "{{TAVILY_API_KEY}}"
    set -gx CONTEXT_7_API_KEY "{{CONTEXT_7_API_KEY}}"
    set -gx BRAVE_API_KEY "{{BRAVE_API_KEY}}"
    set -g fish_user_paths "~/.bun/bin"

    alias cd z
    alias grep rg
    alias ll "eza --long --icons"
    alias ls eza
    alias vim nvim
    alias cat bat
    alias find fd

    for _f in $HOME/.config/herdr/plugins/github/herdr-automatic-rename-*/shell/hook.fish
        test -r "$_f"; and source "$_f"; and break
    end
end

# pnpm
set -gx PNPM_HOME "/home/andrew/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
    set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end
#
if status is-login
    set -gx GTK_IM_MODULE fcitx
    set -gx QT_IM_MODULE fcitx
    set -gx XMODIFIERS @im=fcitx
    set -gx SDL_IM_MODULE fcitx
    set -gx GLFW_IM_MODULE ibus
end
