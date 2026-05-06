return {
  {
    "OGBlackDiamond/transparent-nordic.nvim",
    lazy = false,    -- load at startup
    priority = 1000, -- load before all other plugins
    config = function()
      require("nordic").setup({})
      vim.cmd.colorscheme("nordic")
      -- Visual selection highlight (theme leaves it empty)
      local c = require("nordic.colors")
      vim.api.nvim_set_hl(0, "Visual",    { bg = c.gray3, fg = "NONE" })
      vim.api.nvim_set_hl(0, "VisualNOS", { bg = c.gray3, fg = "NONE" })

      -- snacks.picker: transparent background, orange borders
      vim.api.nvim_set_hl(0, "SnacksPicker",              { bg = "NONE" })
      vim.api.nvim_set_hl(0, "SnacksPickerBorder",        { fg = c.orange.dim,  bg = "NONE" })
      vim.api.nvim_set_hl(0, "SnacksPickerTitle",         { fg = c.orange.base, bg = "NONE" })
      vim.api.nvim_set_hl(0, "SnacksPickerList",          { bg = "NONE" })
      vim.api.nvim_set_hl(0, "SnacksPickerListBorder",    { fg = c.orange.dim,  bg = "NONE" })
      vim.api.nvim_set_hl(0, "SnacksPickerPreview",       { bg = "NONE" })
      vim.api.nvim_set_hl(0, "SnacksPickerPreviewBorder", { fg = c.orange.dim,  bg = "NONE" })
      vim.api.nvim_set_hl(0, "SnacksPickerInput",         { bg = "NONE" })
      vim.api.nvim_set_hl(0, "SnacksPickerInputBorder",   { fg = c.orange.dim,  bg = "NONE" })
      vim.api.nvim_set_hl(0, "SnacksPickerSearch",        { fg = c.orange.base, bg = "NONE" })

      -- tabline: make the fill/background transparent
      vim.api.nvim_set_hl(0, "TabLineFill", { bg = "NONE" })
      vim.api.nvim_set_hl(0, "TabLine",     { bg = "NONE" })
      vim.api.nvim_set_hl(0, "TabLineSel",  { bg = "NONE" })

      -- diagnostic virtual text: remove background tint so it doesn't render
      -- a solid box over the transparent terminal background
      for _, kind in ipairs({ "Error", "Warn", "Info", "Hint" }) do
        local group = "DiagnosticVirtualText" .. kind
        local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
        vim.api.nvim_set_hl(0, group, { fg = hl.fg, bg = nil })
      end
    end,
  },
}
