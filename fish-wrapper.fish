#!/usr/bin/env fish

function run_zsh_script
    set script_path $argv[1]
    if test -f "$script_path"
        echo "🐟 Running $script_path via zsh..."
        SHELL=/bin/zsh zsh $script_path
    else
        echo "Error: Script not found: $script_path"
        return 1
    end
end

# Check command argument
if test (count $argv) -lt 1
    echo "Usage: fish fish-wrapper.fish [command]"
    echo ""
    echo "Available commands:"
    echo "  setup       - Run complete installation script"
    echo "  start       - Start all services"
    echo "  stop        - Stop all services"
    echo "  restart     - Restart all services"
    echo "  status      - Show status of all services"
    echo "  help        - Show this help message"
    exit 1
end

set command $argv[1]

switch $command
    case setup
        run_zsh_script "./scripts/setup.sh"
    case start
        run_zsh_script "./scripts/start.sh"
    case stop
        run_zsh_script "./scripts/stop.sh"
    case restart
        run_zsh_script "./scripts/restart.sh"
    case restart-backend
        run_zsh_script "./scripts/restart-backend.sh"
    case restart-force
        run_zsh_script "./scripts/restart-force.sh"
    case status
        run_zsh_script "./scripts/status.sh"
    case help
        echo "🐟 Second-Me Fish Wrapper"
        echo ""
        echo "This is a simple fish shell wrapper for the Second-Me project scripts."
        echo "It allows you to run the zsh scripts from fish shell without changing your shell."
        echo ""
        echo "Available commands:"
        echo "  setup          - Run complete installation script"
        echo "  start          - Start all services"
        echo "  stop           - Stop all services"
        echo "  restart        - Restart all services"
        echo "  restart-backend - Restart only backend service"
        echo "  restart-force  - Force restart and reset data"
        echo "  status         - Show status of all services"
        echo "  help           - Show this help message"
    case '*'
        echo "Unknown command: $command"
        echo "Run 'fish fish-wrapper.fish help' for usage information."
        exit 1
end 
