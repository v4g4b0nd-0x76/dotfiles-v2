local function reset_buffer(name, filetype, lines)
	vim.cmd("silent! only!")
	vim.cmd("enew!")
	vim.api.nvim_buf_set_name(0, name)
	vim.bo.filetype = filetype
	vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
	vim.bo.modified = false
end

local function same(actual, expected, label)
	assert(vim.deep_equal(actual, expected), label .. "\nexpected: " .. vim.inspect(expected) .. "\nactual: " .. vim.inspect(actual))
end

reset_buffer("/tmp/dotfiles-runner-go/window_test.go", "go", {
	"package math",
	"func TestAdds(t *testing.T) {}",
})
local source_win = vim.api.nvim_get_current_win()
local source_buf = vim.api.nvim_get_current_buf()
local before_wins = #vim.api.nvim_tabpage_list_wins(0)
assert(type(YorhaRonin.open_test_result_window) == "function", "runner must expose its result window opener")
YorhaRonin.open_test_result_window()
local result_win = vim.api.nvim_get_current_win()
assert(#vim.api.nvim_tabpage_list_wins(0) == before_wins + 1, "runner must open one result window")
assert(vim.api.nvim_win_get_buf(source_win) == source_buf, "runner must keep the source buffer visible")
assert(vim.api.nvim_get_current_buf() ~= source_buf, "runner result window must not reuse the source buffer")
assert(vim.api.nvim_win_get_position(result_win)[2] > vim.api.nvim_win_get_position(source_win)[2], "runner result window must open vertically to the right")
vim.cmd("close")
vim.api.nvim_set_current_win(source_win)

reset_buffer("/tmp/dotfiles-runner-go/math_test.go", "go", {
	"package math",
	"",
	"func TestAdds(t *testing.T) {",
	"}",
	"",
	"func TestSubtracts(t *testing.T) {",
	"}",
	"",
	"func BenchmarkAdds(b *testing.B) {",
	"}",
})
vim.api.nvim_win_set_cursor(0, { 3, 0 })
same(YorhaRonin.test_runner_command("test", "unit").args, { "go", "test", "-v", "-run", "^TestAdds$", "." }, "go unit test")
same(
	YorhaRonin.test_runner_command("test", "file").args,
	{ "go", "test", "-v", "-run", "^(TestAdds|TestSubtracts)$", "." },
	"go file tests"
)
same(
	YorhaRonin.test_runner_command("bench", "file").args,
	{ "go", "test", "-run", "^$", "-bench", "^(BenchmarkAdds)$", "." },
	"go file benches"
)

reset_buffer("/tmp/dotfiles-runner-ts/example.test.ts", "typescript", {
	"describe('math', () => {",
	"  test('adds numbers', () => {",
	"  })",
	"})",
})
vim.api.nvim_win_set_cursor(0, { 2, 2 })
same(
	YorhaRonin.test_runner_command("test", "unit").args,
	{ "npm", "test", "--", "example.test.ts", "-t", "adds numbers" },
	"typescript unit test"
)

local rust_root = "/tmp/dotfiles-runner-rust"
vim.fn.mkdir(rust_root .. "/tests", "p")
vim.fn.mkdir(rust_root .. "/benches", "p")
vim.fn.writefile({ "[package]", 'name = "runner"', 'version = "0.1.0"', 'edition = "2021"' }, rust_root .. "/Cargo.toml")

reset_buffer(rust_root .. "/tests/math.rs", "rust", {
	"#[test]",
	"fn parses() {",
	"}",
})
vim.api.nvim_win_set_cursor(0, { 1, 0 })
same(YorhaRonin.test_runner_command("test", "unit").args, { "cargo", "test", "parses" }, "rust unit test")
same(YorhaRonin.test_runner_command("test", "file").args, { "cargo", "test", "--test", "math" }, "rust test file")

reset_buffer(rust_root .. "/benches/parse.rs", "rust", {
	"fn parse_bench(c: &mut Criterion) {",
	"}",
})
same(YorhaRonin.test_runner_command("bench", "file").args, { "cargo", "bench", "--bench", "parse" }, "rust bench file")
