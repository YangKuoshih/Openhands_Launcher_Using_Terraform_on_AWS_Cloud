# OpenHands AWS Infrastructure with Terraform

Deploy OpenHands AI coding assistant on AWS EC2 with Bedrock integration.

## Prerequisites

- **AWS CLI v2** installed (verify with `aws --version`)
- **Terraform** installed (verify with `terraform --version`)
- **AWS Bedrock model access** approved (go to AWS Bedrock Console → Model Access → Request access for required models)

## Configuration

On first run, `START-HERE.bat` will automatically create configuration files from examples:
- `terraform/config.json` - Infrastructure settings
- `terraform/scripts/aws_sso_helper/config.ini` - AWS SSO configuration

Edit `config.ini` with your AWS SSO start URL if using SSO authentication.

## Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/YangKuoshih/Openhands_Launcher_Using_Terraform_on_AWS_Cloud.git
cd Openhands_Launcher_Using_Terraform_on_AWS_Cloud
```

### 2. First Time Setup
```cmd
START-HERE.bat
```
This will automatically:
- Check AWS credentials (set up SSO if needed)
- Check for existing infrastructure and give you options
- Deploy OpenHands infrastructure
- Provide access URL

### 3. Daily Usage
```cmd
launcher.bat
```
**Important:** Use `launcher.bat` (not `launch.bat`) for all daily operations:

**Launcher Options:**
1. **oh** - Open OpenHands in browser
2. **ec2** - SSH to EC2 instance
3. **portainer** - Open Portainer in browser
4. **status** - Refresh status (restart launcher)
5. **ec2start** - Manually start EC2 instance
6. **ec2stop** - Manually stop EC2 instance
7. **tfp** - Plan infrastructure changes
8. **tfa** - Update infrastructure and OpenHands containers
9. **tfd** - Destroy infrastructure
10. **cleanup** - Fix resource conflicts
11. **Exit** - Close launcher

## Docker Image Versions

This deployment **automatically detects and uses the latest stable versions**:
- OpenHands: Auto-detected latest stable version (currently `0.59.0`)
- Runtime: Matches OpenHands version for compatibility
- LiteLLM: `ghcr.io/berriai/litellm:main-latest`
- Portainer: `portainer/portainer-ce:latest`

**Version Detection:** Each deployment automatically fetches the newest stable OpenHands version from the Docker registry, ensuring compatibility between app and runtime containers.

## Portainer - Docker Management

Portainer provides a web UI to manage Docker containers, images, and volumes:
- **Access**: Launcher option 3 or `http://<your-instance-ip>:9000`
- **First-time setup**: Create admin password
- **Select Environment**: Choose "Docker" to manage local containers
- **Features**: View logs, restart containers, pull new images, monitor resources
- **Useful for**: Troubleshooting OpenHands, checking container status, viewing logs

## Configure OpenHands LLM

When you first open OpenHands, configure the AI model:

1. Click "see advanced settings" (small text on popup) or gear icon at bottom left
2. Go to LLM tab and enable "Advanced" toggle
3. Enter these settings:
   - **Custom Model**: `litellm_proxy/Claude4`
   - **Base URL**: `http://litellm`
   - **API Key**: `openhands-key-2025`
4. Click "Save Changes"
5. Complete privacy preferences popup

**Available Models:**
- `Claude3` - Claude 3 Haiku (fastest, most cost-effective)
- `Claude3.7` - Claude 3.7 Sonnet (balanced performance)
- `Claude4` - Claude 4 Sonnet (recommended - best balance)
- `ClaudeOpus4.1` - Claude Opus 4.1 (most capable, slower)
- `NovaPro1` - Amazon Nova Pro (AWS native)

## Getting Started with OpenHands

### What is OpenHands?
OpenHands is an autonomous AI coding assistant that can write, debug, and modify code directly in your projects. Unlike ChatGPT where you copy/paste code, OpenHands works like an AI developer that can:
- Read and modify files in your workspace
- Execute commands and run code
- Install packages and dependencies
- Test its own work and iterate
- Complete multi-step development tasks

### Your First Task

1. **Open OpenHands** (launcher option 1)
2. **Start with a simple task**:
   - "Create a Python script that prints Hello World"
   - "Build a simple HTML page with a contact form"
   - "Write a function to calculate fibonacci numbers"
3. **Watch OpenHands work** - it will create files, write code, and test
4. **Review the results** - check the files it created

### Example Use Cases

**Code Generation:**
- "Create a REST API with Flask that has CRUD endpoints for a todo list"
- "Build a React component for a user profile card with avatar and bio"
- "Write a Python script to parse CSV files and generate reports"

**Debugging & Fixes:**
- "This function is throwing an error, can you debug it?"
- "Fix the authentication bug in my login endpoint"
- "Why is this query slow? Optimize it"

**Refactoring:**
- "Refactor this code to follow best practices"
- "Add error handling to all API endpoints"
- "Convert this JavaScript code to TypeScript"

**Testing:**
- "Write unit tests for this React component"
- "Create integration tests for the user registration flow"
- "Add test coverage for all API endpoints"

**Documentation:**
- "Generate API documentation for these endpoints"
- "Add detailed comments explaining this algorithm"
- "Create a comprehensive README for this project"

### Best Practices

**Be Specific:**
- ❌ "Make my app better"
- ✅ "Add input validation to the signup form with email format checking and password strength requirements"

**Provide Context:**
- Share relevant files or directories
- Mention frameworks/libraries you're using
- Explain your project structure

**Start Small:**
- Begin with simple tasks to understand how OpenHands works
- Build up to more complex features
- Review changes before moving to the next task

**Use Version Control:**
- Commit your code before big changes
- Review what OpenHands modified
- Easy to revert if needed

**Iterate:**
- If results aren't perfect, provide feedback
- Ask OpenHands to adjust or improve
- Build on successful completions

### Tips for Success

1. **Clear Instructions**: Be specific about what you want
2. **One Task at a Time**: Break complex projects into smaller tasks
3. **Review Changes**: Always check what OpenHands created or modified
4. **Provide Feedback**: If something isn't right, tell OpenHands to fix it
5. **Use Portainer**: Monitor container resources and logs (launcher option 3)

### What Makes OpenHands Different

**vs ChatGPT/Claude (Chat-based AI):**
- OpenHands can execute code and see results
- Works directly in your codebase
- Can run tests and verify solutions
- Autonomous - completes multi-step tasks without constant prompting

**vs GitHub Copilot (Code Completion):**
- Handles entire features, not just autocomplete
- Can refactor existing code
- Understands full project context
- Can run and debug code independently

**vs Cursor (AI-powered IDE):**
- OpenHands is IDE-agnostic - works with any editor
- Fully autonomous agent vs assisted coding
- Can operate independently without IDE integration
- Runs in isolated sandbox environment for safety
- Cloud-based deployment vs local installation

**vs Windsurf/Cline (IDE Extensions):**
- No IDE lock-in - use your preferred editor
- Runs on dedicated AWS infrastructure (not local resources)
- Persistent environment that stays running
- Team-accessible via web interface
- Integrated with AWS Bedrock for enterprise AI models

**vs Roo Code/Aider (CLI Tools):**
- Web-based UI vs command-line interface
- Visual workspace for easier interaction
- Persistent sessions across multiple tasks
- Built-in Docker management with Portainer
- Scheduled auto-start/stop for cost optimization

**vs Google IDX/Project IDX (Cloud IDE):**
- Focused on AI agent capabilities vs full IDE
- Self-hosted on your AWS account (full control)
- Customizable infrastructure and scaling
- Direct integration with AWS services
- No vendor lock-in - you own the deployment

**Key OpenHands Advantages:**
- **Autonomous Operation**: Completes tasks end-to-end without hand-holding
- **Sandboxed Execution**: Safe environment to run and test code
- **Cloud-Based**: Access from anywhere, no local setup needed
- **AWS Integration**: Native Bedrock support for enterprise AI models
- **Cost Efficient**: Auto-scheduling saves ~58% on compute costs
- **Self-Hosted**: Full control over your infrastructure and data
- **Open Source**: Transparent, customizable, community-driven

### Common Workflows

**New Project:**
1. "Create a new [framework] project with [features]"
2. Review structure
3. "Add [specific feature]"
4. Test and iterate

**Existing Project:**
1. Upload or share your code
2. "Add [feature] to this project"
3. OpenHands analyzes and implements
4. Review and test changes

**Debugging:**
1. Share error message/logs
2. "Debug this error"
3. OpenHands investigates and fixes
4. Verify solution works

### When to Use OpenHands

**Best For:**
- Building entire features or applications from scratch
- Refactoring and modernizing existing codebases
- Debugging complex issues that require testing
- Learning new frameworks through hands-on examples
- Automating repetitive development tasks
- Working on projects that need isolated environments

**Consider Alternatives When:**
- You need real-time autocomplete while typing (use Copilot)
- You prefer tight IDE integration (use Cursor/Windsurf)
- You want quick code snippets without execution (use ChatGPT)
- You need offline development capabilities (use local tools)

### Need Help?
- Check OpenHands documentation: https://docs.all-hands.dev
- Use Portainer to view container logs if issues occur
- SSH to EC2 (launcher option 2) for advanced troubleshooting

## Resource Conflicts & Cleanup

**When you see "already exists" errors:**
```
openhands-aws-setup-openhands-policy already exists
openhands-key already exists
openhands-aws-setup-scheduler-role already exists
```

**What cleanup does:**
- Imports existing AWS resources into Terraform state
- Allows Terraform to manage resources it created previously
- **Safe operation** - never deletes or modifies existing infrastructure
- Fixes state mismatches between Terraform and AWS

**When to run cleanup:**
- After interrupting a previous Terraform deployment
- When switching between different Terraform state files
- If you see "resource already exists" errors during `terraform apply`
- When Terraform "forgets" about resources it previously created

**How to run cleanup:**
```cmd
launcher.bat
```
Select option 10 (cleanup), then option 8 (tfa) to apply changes.

## Troubleshooting

**Model Not Working?** Some Bedrock models need `us.` prefix:
- Check AWS Bedrock Console → Model Access
- If you see "Cross-region inference" → use `us.` prefix in model config
- If no "Cross-region inference" → no prefix needed

**Resource Conflicts?** See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed solutions.

## Cleanup
```cmd
launcher.bat
```
Select option 9 (tfd) to destroy all infrastructure

## Cost Optimization
- **Auto-scheduling**: Runs 8 AM - 10 PM EST (saves ~58% costs)
- **Estimated cost**: ~$17/month with scheduling vs $36/month 24/7

## License
MIT License - feel free to use and modify for your needs.