local M = {}
local job_id = nil
local html_path = ""
local server_path = ""

-- Internal helper to ensure the background Node server is active
local function ensure_server_running()
    -- If the job is already active, do nothing
    if job_id and job_id > 0 then
        return true
    end

    if vim.fn.filereadable(server_path) == 0 then
        vim.api.nvim_err_writeln("langGraphVisualizer: Cannot find server script at " .. server_path)
        return false
    end

    -- Spawn the background Node.js bridge lazily on demand
    job_id = vim.fn.jobstart({ "node", server_path }, {
        stdout_buffered = false,
        on_stdout = function(_, data)
            if data then
                for _, line in ipairs(data) do
                    if line ~= "" then M.handle_browser_message(line) end
                end
            end
        end,
        on_stderr = function(_, data)
            if data and data[1] ~= "" then
                vim.schedule(function()
                    vim.api.nvim_err_writeln("Node Server Error: " .. table.concat(data, "\n"))
                end)
            end
        end,
    })

    -- Brief pause to let the socket bind cleanly before commands push packets
    vim.fn. those_sleep = vim.fn.wait or os.execute("sleep 0.1")
    return true
end

function M.setup()
    -- Extract the absolute path of the currently executing Lua file
    local source_path = debug.getinfo(1).source:sub(2)
    -- Navigate up to the root plugin directory (e.g., from lua/langGraphVisualizer/ to root)
    local plugin_dir = vim.fn.fnamemodify(source_path, ":h:h:h")
    
    -- Dynamically resolve paths relative to the plugin root installation folder
    server_path = plugin_dir .. "/server/server.js"
    html_path = plugin_dir .. "/server/index.html"

    -- Register User Commands immediately (cost-free pointers)
    vim.api.nvim_create_user_command("LangGraphOpen", function()
        if ensure_server_running() then
            M.open_browser()
        end
    end, {})

    vim.api.nvim_create_user_command("LangGraphRender", function()
        if ensure_server_running() then
            local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
            local raw_code = table.concat(lines, "\n")
            M.send_to_browser({
                type = "RENDER_CODE",
                code = raw_code
            })
        end
    end, {})

    -- Clean up process on shutdown
    vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
            if job_id and job_id > 0 then
                vim.fn.jobstop(job_id)
            end
        end
    })
end

function M.open_browser()
    local cmd
    if vim.fn.has("win32") == 1 then
        cmd = { "cmd.exe", "/c", "start", html_path }
    elseif vim.fn.has("mac") == 1 then
        cmd = { "open", html_path }
    else
        cmd = { "xdg-open", html_path }
    end
    vim.fn.jobstart(cmd, { detach = true })
end

function M.send_to_browser(data)
    if job_id and job_id > 0 then
        local json = vim.fn.json_encode(data)
        vim.fn.chansend(job_id, json .. "\n")
    end
end

function M.handle_browser_message(raw_line)
    local ok, parsed = pcall(vim.fn.json_decode, raw_line)
    if ok and parsed and parsed.source == "browser" then
        vim.schedule(function()
            print("Browser interaction captured: " .. vim.inspect(parsed.data))
        end)
    end
end

return M
