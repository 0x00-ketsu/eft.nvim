---@class HighlightColor
---@field gui? string
---@field guifg? string
---@field cterm? string

---@class Highlight
---@field name string
---@field allow_space boolean
---@field color HighlightColor

---@class Option
---@field ignore_case boolean
---@field highlights Highlight[]
local defaults = {
  ignore_case = false,
  highlights = {
    {
      name = "EftChar",
      allow_space = true,
      color = { gui = "bold,underline", guifg = "Orange", cterm = "bold,underline" },
    },
    {
      name = "EftSubChar",
      allow_space = false,
      color = { gui = "bold,underline", guifg = "Gray", cterm = "bold,underline" },
    },
  },
}

---Define highlight groups based on the resolved config.
---Invalid entries are skipped with a warning instead of raising an error.
---
---@param highlights Highlight[]
local function define_highlights(highlights)
  for _, highlight in ipairs(highlights) do
    local name, color = highlight["name"], highlight["color"]
    if type(name) ~= "string" or type(color) ~= "table" then
      vim.notify(
        string.format("[eft.nvim] invalid highlight definition: %s", vim.inspect(highlight)),
        vim.log.levels.WARN
      )
      goto continue
    end

    local attrs = {}
    for key, value in pairs(color) do
      if type(value) == "string" and #value == 0 then
        value = "NONE"
      end
      table.insert(attrs, string.format("%s=%s", key, value))
    end

    local ok, err =
      pcall(vim.cmd, string.format("hi! default %s %s", name, table.concat(attrs, " ")))
    if not ok then
      vim.notify(
        string.format("[eft.nvim] failed to define highlight `%s`: %s", name, err),
        vim.log.levels.WARN
      )
    end

    ::continue::
  end
end

local M = {}

---@type Option
M.config = vim.deepcopy(defaults)

---Entrance
---
---@param opts? Option
M.setup = function(opts)
  if opts ~= nil and type(opts) ~= "table" then
    vim.notify("[eft.nvim] setup() expects a table, ignoring invalid options", vim.log.levels.WARN)
    opts = nil
  end

  M.config = vim.tbl_deep_extend("force", defaults, opts or {})

  if type(M.config["highlights"]) ~= "table" then
    vim.notify(
      "[eft.nvim] `highlights` must be a table, falling back to defaults",
      vim.log.levels.WARN
    )
    M.config["highlights"] = defaults["highlights"]
  end

  define_highlights(M.config["highlights"])
end

return M
