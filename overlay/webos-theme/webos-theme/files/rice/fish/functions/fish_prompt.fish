function fish_prompt
    set_color white
    echo -n (prompt_pwd)
    echo -n ' ❯ '
    set_color normal
end
