-- File: ~/.config/nvim/lua/flutter-preview/init.lua
local M = {}
local api = vim.api
local fn = vim.fn

-- Utility functions
local utils = {
  get_word_under_cursor = function()
    return fn.expand('<cword>')
  end,
  
  is_flutter_project = function()
    return fn.findfile('pubspec.yaml', '.;') ~= ''
  end,
  
  create_float_window = function(content, opts)
    opts = opts or {}
    local width = opts.width or 60
    local height = opts.height or 10
    
    local buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_lines(buf, 0, -1, true, content)
    
    local win_opts = {
      relative = 'cursor',
      row = 1,
      col = 0,
      width = width,
      height = height,
      style = 'minimal',
      border = 'rounded'
    }
    
    local win = api.nvim_open_win(buf, false, win_opts)
    api.nvim_create_autocmd({"BufLeave", "CursorMoved"}, {
      buffer = buf,
      once = true,
      callback = function()
        if api.nvim_win_is_valid(win) then
          api.nvim_win_close(win, true)
        end
      end
    })
    
    return buf, win
  end
}

-- Image Preview functionality
function M.setup_image_preview()
  local image_extensions = { 'png', 'jpg', 'jpeg', 'gif', 'svg' }
  
  api.nvim_create_autocmd({ "CursorHold" }, {
    group = api.nvim_create_augroup("FlutterImagePreview", { clear = true }),
    pattern = "*.dart",
    callback = function()
      local line = api.nvim_get_current_line()
      local match = line:match("'([^']+%.(%w+))'")
      
      if match then
        local ext = match:match("%.(%w+)$")
        if vim.tbl_contains(image_extensions, ext:lower()) then
          -- For terminal preview (if supported)
          local content = {
            "Image Preview:",
            match,
            "Type: " .. ext:upper()
          }
          utils.create_float_window(content, { width = 40, height = 3 })
        end
      end
    end
  })
end

-- Icon Preview functionality
function M.setup_icon_preview()
  api.nvim_create_autocmd({ "CursorHold" }, {
    group = api.nvim_create_augroup("FlutterIconPreview", { clear = true }),
    pattern = "*.dart",
    callback = function()
      local word = utils.get_word_under_cursor()
      if word:match("^Icons?%.") then
        local icon_name = word:match("Icons?%.(.+)")
        if icon_name then
          local content = {
            "Icon Preview:",
            icon_name,
            "Material Icons"
          }
          utils.create_float_window(content, { width = 30, height = 3 })
        end
      end
    end
  })
end

-- Import analysis
function M.analyze_imports()
  if not utils.is_flutter_project() then
    vim.notify("Not a Flutter project!", vim.log.levels.ERROR)
    return
  end
  
  local content = {
    "Analyzing imports...",
    "This may take a moment..."
  }
  
  local buf, win = utils.create_float_window(content, { width = 50, height = 10 })
  
  vim.fn.jobstart("flutter pub deps --style=compact", {
    on_stdout = function(_, data)
      if data then
        api.nvim_buf_set_lines(buf, -1, -1, true, data)
      end
    end,
    on_exit = function()
      api.nvim_buf_set_lines(buf, 0, 1, true, {"Import Analysis Results:"})
    end
  })
end

-- Release helper
function M.release_helper()
  local actions = {
    "Flutter Release Helper",
    "",
    "1. Update pubspec version",
    "2. Flutter clean",
    "3. Flutter pub get",
    "4. Build release APK",
    "5. Build release iOS",
    "6. Generate changelog",
    "",
    "Press number to execute action"
  }
  
  local buf, win = utils.create_float_window(actions, { width = 40, height = #actions })
  
  local opts = { buffer = buf, silent = true }
  local commands = {
    [1] = function() vim.cmd('edit pubspec.yaml') end,
    [2] = function() vim.cmd('!flutter clean') end,
    [3] = function() vim.cmd('!flutter pub get') end,
    [4] = function() vim.cmd('!flutter build apk --release') end,
    [5] = function() vim.cmd('!flutter build ios --release') end,
    [6] = function() 
      local changelog = {
        "# Changelog",
        "",
        "## [Version]",
        "",
        "### Added",
        "- ",
        "",
        "### Changed",
        "- ",
        "",
        "### Fixed",
        "- "
      }
      vim.cmd('new CHANGELOG.md')
      api.nvim_buf_set_lines(0, 0, -1, true, changelog)
    end
  }
  
  for num, func in pairs(commands) do
    vim.keymap.set('n', tostring(num), function()
      if api.nvim_win_is_valid(win) then
        api.nvim_win_close(win, true)
      end
      func()
    end, opts)
  end
end

-- Setup function
function M.setup(opts)
  opts = opts or {}
  
  -- Create commands
  api.nvim_create_user_command('FlutterAnalyzeImports', M.analyze_imports, {})
  api.nvim_create_user_command('FlutterRelease', M.release_helper, {})
  
  -- Setup features
  M.setup_image_preview()
  M.setup_icon_preview()
  
  -- Set up keymaps
  local keymaps = opts.keymaps or {
    analyze_imports = '<Leader>fa',
    release_helper = '<Leader>fr'
  }
  
  vim.keymap.set('n', keymaps.analyze_imports, M.analyze_imports, 
    { desc = 'Analyze Flutter imports' })
  vim.keymap.set('n', keymaps.release_helper, M.release_helper, 
    { desc = 'Flutter release helper' })
  
  -- Notify successful setup
  vim.notify("Flutter Preview plugin loaded successfully!", vim.log.levels.INFO)
end

return M