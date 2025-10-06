#!/bin/bash
# Mission DB007 - Hybrid Demo Setup

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Mission DB007 - Hybrid Demo Setup${NC}"
echo "===================================="

# Check Python
if ! command -v python3 >/dev/null 2>&1; then
    echo -e "${YELLOW}Installing Python3...${NC}"
    sudo yum install -y python3 python3-pip
fi

# Create virtual environment
echo -e "${YELLOW}Setting up Python environment...${NC}"
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Setup environment file
if [ ! -f ".env" ]; then
    cp .env.example .env
    echo -e "${GREEN}✅ Created .env file${NC}"
    echo -e "${YELLOW}⚠️  IMPORTANT: Edit .env with your RDS endpoint and credentials${NC}"
fi

# Setup aliases
echo -e "${YELLOW}Setting up convenience aliases...${NC}"
CURRENT_DIR=$(pwd)
cat >> ~/.bashrc << EOF

# Mission DB007 aliases
alias demo-activate='cd $CURRENT_DIR && source .venv/bin/activate'
alias demo-start='cd $CURRENT_DIR && source .venv/bin/activate && python main.py'
alias demo-status='cd $CURRENT_DIR && ./scripts/check-rds.sh'
alias demo-failover='cd $CURRENT_DIR && ./scripts/trigger-failover.sh'
EOF

echo -e "${GREEN}🎉 Setup completed!${NC}"
echo ""
echo "Next steps:"
echo "1. Edit .env with your RDS details"
echo "2. Run: source ~/.bashrc"
echo "3. Run: demo-start"