#!/bin/bash

echo "🌅 Starting daily SurveyForge development session..."

# Update date in project state
if [ -f .mds/memory/project_state.md ]; then
    sed -i '' "s/Last Updated:.*/Last Updated: $(date)/" .mds/memory/project_state.md
fi

# Start PM agent if not running
if ! tmux has-session -t pm-agent 2>/dev/null; then
    tmux new-session -d -s pm-agent
    tmux send-keys -t pm-agent "cd /Users/akoscz/workspace/survery-forge" C-m
    tmux send-keys -t pm-agent "echo 'PM Agent Ready - $(date)'" C-m
    tmux send-keys -t pm-agent "echo 'Load prompt from .mds/prompts/pm_agent.md'" C-m
    echo "✅ Started PM agent session"
else
    echo "ℹ️  PM agent already running"
fi

echo ""
echo "📋 Daily session ready!"
echo "Next steps:"
echo "1. tmux attach -t pm-agent"
echo "2. Load PM agent prompt from docs/AI_Agent_Orchestration_Guide.md"
echo "3. Review task assignments"
echo "4. Deploy worker agents as needed"
echo ""
echo "💡 Useful commands:"
echo "  ./scripts/check_agents.sh     - Check all agent status"
echo "  ./scripts/deploy_agent.sh     - Deploy new agent"
echo "  tmux list-sessions            - List all sessions"