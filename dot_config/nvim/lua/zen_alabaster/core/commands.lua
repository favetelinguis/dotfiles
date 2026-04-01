vim.api.nvim_create_user_command("InspectHere", function()
  vim.cmd("Inspect")
end, { desc = "Inspect highlights under cursor" })
