---@type vim.lsp.Config
return {
  cmd = { "jdtls" },
  filetypes = { "java" },
  root_markers = {
    "pom.xml",
    "build.gradle",
    "build.gradle.kts",
    "settings.gradle",
    "settings.gradle.kts",
    "mvnw",
    "gradlew",
    ".git",
  },
  settings = {
    java = {
      configuration = {
        updateBuildConfiguration = "interactive",
      },
      signatureHelp = {
        enabled = true,
      },
    },
  },
}
