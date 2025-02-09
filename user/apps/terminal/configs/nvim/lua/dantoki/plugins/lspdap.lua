return {
	{
		"mfussenegger/nvim-dap",
		enabled = false,
		keys = {
			{ ",db", "<CMD>DapToggleBreakpoint<CR>", desc = "Toggle dap breakpoint" },
			{ ",dc", "<CMD>DapContinue<CR>", desc = "Continue run" },
			{ ",do", "<CMD>DapStepOver<CR>", desc = "Step over" },
			{ ",de", "<CMD>DapTerminate<CR>", desc = "Terminate" },
			{ ",dfs", "<CMD>!firefox -start-debugger-server<CR>", desc = "Start firefox debug server" },
		},
		dependencies = {
			{
				"rcarriga/nvim-dap-ui",
				keys = {
					{
						",dt",
						function()
							local ok, dapui = pcall(require, "dapui")
							if not ok then
								return
							end

							dapui.toggle()
						end,
						desc = "Toggle DAP UI",
					},
				},
			},
			-- { "nvim-neotest/nvim-nio" }
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			dap.adapters.codelldb = {
				type = "server",
				host = "127.0.0.1",
				port = 13000, -- 💀 Use the port printed out or specified with `--port`
			}

			dap.configurations.cpp = {
				{
					name = "Launch file",
					type = "codelldb",
					request = "launch",
					program = function()
						return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
					end,
					cwd = "${workspaceFolder}",
					stopOnEntry = false,
				},
			}

			dap.configurations.c = dap.configurations.cpp
			dap.configurations.rust = dap.configurations.cpp

			dap.adapters.delve = {
				type = "server",
				port = "${port}",
				executable = {
					command = vim.fn.expand("$HOME/.local/share/nvim/mason/bin/dlv"),
					args = { "dap", "-l", "127.0.0.1:${port}" },
				},
			}

			-- https://github.com/go-delve/delve/blob/master/Documentation/usage/dlv_dap.md
			dap.configurations.go = {
				{
					type = "delve",
					name = "Debug",
					request = "launch",
					program = "${file}",
				},
				{
					type = "delve",
					name = "Debug test", -- configuration for debugging test files
					request = "launch",
					mode = "test",
					program = "${file}",
				},
				-- works with go.mod packages and sub packages
				{
					type = "delve",
					name = "Debug test (go.mod)",
					request = "launch",
					mode = "test",
					program = "./${relativeFileDirname}",
				},
			}

			dap.adapters.node2 = {
				type = "executable",
				command = "node",
				args = { vim.fn.expand("$HOME/.local/share/nvim/mason/bin/node-debug2-adapter") },
			}

			dap.configurations.javascript = {
				{
					name = "Launch",
					type = "node2",
					request = "launch",
					program = "${file}",
					cwd = vim.fn.getcwd(),
					sourceMaps = true,
					protocol = "inspector",
					console = "integratedTerminal",
				},
				{
					-- For this to work you need to make sure the node process is started with the `--inspect` flag.
					name = "Attach to process",
					type = "node2",
					request = "attach",
					processId = require("dap.utils").pick_process,
				},
			}
			dap.configurations.typescript = dap.configurations.javascript

			dap.adapters.firefox = {
				type = "executable",
				command = vim.fn.expand("$HOME/.local/share/nvim/mason/bin/firefox-debug-adapter"),
			}

			dap.configurations.typescriptreact = {
				{
					name = "Debug with Firefox",
					type = "firefox",
					request = "launch",
					url = "http://localhost:3000",
					webRoot = "${workspaceFolder}",
					firefoxExecutable = "/usr/bin/firefox",
					timeout = 30000,
				},
				{
					-- For this to work you need to make sure the node process is started with the `--inspect` flag.
					name = "Attach to process",
					type = "firefox",
					request = "attach",
					host = "127.0.0.1",
					timeout = 30000,
					processId = require("dap.utils").pick_process,
				},
			}

			-- DAP UI Setup
			dapui.setup()

			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close()
			end
		end,
	},
}
