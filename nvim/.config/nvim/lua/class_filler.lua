local function get_lines(class_name, ext)
    if ext == "hpp" or ext == "h" then
        local guard = class_name:upper() .. "_" .. ext:upper()
        return {
            "#ifndef " .. guard,
            "#define " .. guard,
            "",
            "class " .. class_name .. " {",
            "public:",
            "    " .. class_name .. "();",
            "    " .. class_name .. "(const " .. class_name .. "& other);",
            "    " .. class_name .. "& operator=(const " .. class_name .. "& other);",
            "    ~" .. class_name .. "();",
            "",
            "private:",
            "    ",
            "};",
            "",
            "#endif // " .. guard
        }
    elseif ext == "cpp" or ext == "cxx" or ext == "cc" then
        local header_ext = "hpp"
        return {
            '#include "' .. class_name .. '.' .. header_ext .. '"',
            "",
            class_name .. "::" .. class_name .. "() {",
            "",
            "}",
            "",
            class_name .. "::" .. class_name .. "(const " .. class_name .. "& other) {",
            "    *this = other;",
            "}",
            "",
            class_name .. "& " .. class_name .. "::operator=(const " .. class_name .. "& other) {",
            "    if (this != &other) {",
            "        // TODO: copy members",
            "    }",
            "    return *this;",
            "}",
            "",
            class_name .. "::~" .. class_name .. "() {",
            "",
            "}"
        }
    end
end

local function fill_class(opts)
    local class_name = opts.args
    local base_dir = vim.fn.getcwd()

    if class_name == "" then
        local filepath = vim.api.nvim_buf_get_name(0)
        if filepath == "" then
            vim.notify("No file name associated with buffer, and no class name provided", vim.log.levels.ERROR)
            return
        end
        class_name = vim.fn.fnamemodify(filepath, ":t:r")
        base_dir = vim.fn.fnamemodify(filepath, ":h")
    end

    if class_name == "" then
        vim.notify("Could not determine class name.", vim.log.levels.ERROR)
        return
    end

    local hpp_path = base_dir .. "/" .. class_name .. ".hpp"
    local cpp_path = base_dir .. "/" .. class_name .. ".cpp"
    
    local function process_file(path, ext)
        -- Check if buffer already exists for this path
        local buf = vim.fn.bufnr(path)
        if buf == -1 then
            -- Create buffer for path
            buf = vim.fn.bufadd(path)
            -- Load buffer (reads from disk if exists)
            vim.fn.bufload(buf)
            vim.api.nvim_set_option_value("buflisted", true, { buf = buf })
        end
        
        -- Check if buffer is empty
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        if #lines > 1 or (#lines == 1 and lines[1] ~= "") then
            return buf, false
        end

        local new_lines = get_lines(class_name, ext)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_lines)
        return buf, true
    end

    local hpp_buf, hpp_filled = process_file(hpp_path, "hpp")
    local cpp_buf, cpp_filled = process_file(cpp_path, "cpp")

    if opts.args ~= "" then
        -- Open hpp and vsplit cpp
        vim.cmd("edit " .. vim.fn.fnameescape(hpp_path))
        vim.api.nvim_win_set_cursor(0, {12, 4})
        
        vim.cmd("vsplit " .. vim.fn.fnameescape(cpp_path))
        vim.api.nvim_win_set_cursor(0, {4, 0})
        
        -- focus back to hpp window
        vim.cmd("wincmd p")
    else
        local current_path = vim.api.nvim_buf_get_name(0)
        if current_path == hpp_path and cpp_filled then
            vim.api.nvim_win_set_cursor(0, {12, 4})
            vim.cmd("vsplit " .. vim.fn.fnameescape(cpp_path))
            vim.api.nvim_win_set_cursor(0, {4, 0})
            vim.cmd("wincmd p")
        elseif current_path == cpp_path and hpp_filled then
            vim.api.nvim_win_set_cursor(0, {4, 0})
            vim.cmd("vsplit " .. vim.fn.fnameescape(hpp_path))
            vim.api.nvim_win_set_cursor(0, {12, 4})
            vim.cmd("wincmd p")
        elseif current_path == hpp_path and hpp_filled then
            vim.api.nvim_win_set_cursor(0, {12, 4})
        elseif current_path == cpp_path and cpp_filled then
            vim.api.nvim_win_set_cursor(0, {4, 0})
        end
    end
    
    local msgs = {}
    if hpp_filled then table.insert(msgs, ".hpp") end
    if cpp_filled then table.insert(msgs, ".cpp") end
    
    if #msgs > 0 then
        vim.notify("Filled " .. class_name .. " (" .. table.concat(msgs, " & ") .. ")", vim.log.levels.INFO)
    else
        vim.notify("Files for " .. class_name .. " are already non-empty.", vim.log.levels.INFO)
    end
end

-- Update the user command to accept an optional argument
vim.api.nvim_create_user_command("Fill", fill_class, { nargs = "?" })
