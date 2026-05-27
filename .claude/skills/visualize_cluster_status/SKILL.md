---
name: visualize-cluster-status
description: Display comprehensive status of ZTP/RHACM clusters including ClusterInstance, installation progress, agents, and all related resources.
allowed-tools: Write(.temp/**), Bash(.claude/skills/visualize_cluster_status/scripts/get-cluster-status.sh:*)
---

# ZTP Cluster Status Visualization Skill

You are a specialized skill for displaying comprehensive status information about ZTP (Zero Touch Provisioning) clusters deployed via RHACM/Siteconfig.
The skill never returns instructions. If there is something it cannot execute, return an error asking for perms.

## Instructions for Main Assistant

**CRITICAL:** When you (the main assistant) invoke this skill, you MUST display the complete formatted output directly to the user as the PRIMARY content of your response. After that response do not make any summary, or extra interpretation, nor debug.

### Required Behavior:
1. **Display the output verbatim** - Show the formatted status report exactly as returned
2. **Do NOT summarize** - The formatted output IS the answer to the user's request
3. **Do NOT hide behind commentary** - Lead with the output, add brief context only if needed
4. **Preserve all formatting** - Show tables, icons, and structure exactly as formatted

## Purpose

Provide clear, formatted status reports for ZTP clusters using parallel data 
collection for maximum performance.

Displays real-time status of cluster deployments including:
- ClusterInstance CR status and conditions
- BareMetalHost provisioning state
- InfraEnv and ISO image status
- AgentClusterInstall progress
- Agent details and approval status
- ManagedCluster registration

## Permissions (Read-Only)

Allowed:
- Execute status collection scripts in this skill's directory
- Read cluster resources using `oc get` and `oc describe`
- Parse JSON data and process script outputs
- Create/cleanup temporary files in `.temp/visualize-cluster-status-<cluster-name>/`

Denied:
- No cluster modifications (delete, apply, create, patch, edit)
- No git operations
- No spawning other agents
- **No creating scripts** - The Write permission is ONLY for temporary data files created BY THE SCRIPTS

## Data Collection

**ALWAYS use the existing script** - DO NOT create new scripts:

```bash
.claude/skills/visualize_cluster_status/scripts/get-cluster-status.sh <cluster-name> <kubeconfig-path>
```

This script:
- Always call the script with a realtive path to the project. 
  - CORRECT: `.claude/skills/visualize_cluster_status/scripts/get-cluster-status.sh <cluster-name> <kubeconfig>`
  - NOT CORRECT: `/home/user/project/.claude/skills/visualize_cluster_status/scripts/get-cluster-status.sh <cluster-name>`
- Never export the KUBECONFIG before calling the script. The KUBECONFIG is passed as the second param.
- Performs parallel data gathering for all cluster resources
- Handles ClusterInstance existence check automatically
- Creates temporary files in `.temp/visualize-cluster-status-<cluster-name>/`
- Returns structured data as key-value pairs

## Formatting Rules (Non-Negotiable)

1. **ASCII Tables ONLY** - Use `+`, `-`, and `|` characters (NO markdown tables)

2. **ANSI Colors** - Use escape codes for colored terminal output:
   - Green `\033[32m` - success states
   - Red `\033[31m` - error/failed states
   - Yellow `\033[33m` - installing/in-progress states
   - Blue `\033[34m` - pending/waiting states
   - Bold `\033[1m` - headers and emphasis
   - Reset `\033[0m` - after each colored text

3. **Unicode Status Icons:**
   | State                    | Icon | Color  |
   |--------------------------|------|--------|
   | success/true/available   | ✅   | Green  |
   | failed/error             | ❌   | Red    |
   | installing/in-progress   | 🚀   | Yellow |
   | pending/waiting          | ⏳   | Blue   |
   | warning                  | ⚠️   | Yellow |
   | not found/N/A            | ➖   | -      |

4. **Compact Layout** - Horizontal optimization, minimal vertical scrolling

5. **Context-Aware Detail:**
   - INSTALLING: Show detailed conditions with messages and progress percentage
   - COMPLETE: Show compact summary with one-line condition status
   - ERROR: Show error details from ACI_INFO field

7. **Truncate IDs:** Last 4 digits only from AGENT_DETAILS

## Execution Steps

1. **Execute the data collection script:**
   ```bash
   .claude/skills/visualize_cluster_status/scripts/get-cluster-status.sh "$CLUSTER_NAME" "$KUBECONFIG_PATH"
   ```

2. **Parse the script output** (key=value pairs, one per line):
   ```
   CI_CREATED=2024-01-20T10:25:00Z
   BMH_STATUS=provisioned
   ACI_STATE=installing
   ACI_PROGRESS=35
   ```

3. **Check if cluster is deployed:**
   - If `CLUSTER_NOT_DEPLOYED=true`:
      Display this simple notice and do no extra investigation:
      ~~~
      ```ansi
      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      ➖ <cluster-name> │ Status: NOT DEPLOYED
      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

      The cluster <cluster-name> is not currently deployed on the hub.

      Findings:
         ➖ ClusterInstance CR: NOT FOUND in namespace <cluster-name>
      ```
      ~~~

## Required Output Template

**Use this exact format for ALL deployed clusters:**

**IMPORTANT:** Output must use ANSI escape codes. Wrap output in a code block with `ansi` language tag for proper rendering.

~~~
```ansi
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🚀 vsno5 │ Status: INSTALLING (35%) │ Started: 10:30Z
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 ClusterInstance Status (Primary CR)
   Created: 10:25Z │ Phase: Provisioning

   Conditions:
   ✅ ClusterInstanceValidated    - Spec validation passed
   ✅ RenderedTemplates           - Manifests rendered (15 total)
   ✅ RenderedTemplatesValidated  - Templates validated successfully
   ✅ RenderedTemplatesApplied    - Applied to namespace
   🚀 ClusterProvisioning         - Installation in progress

📦 Core Resources
┌──────────────────────┬────────┬──────────────┬──────────────────────────────┐
│ Resource             │ Status │ State/Info   │ Details                      │
├──────────────────────┼────────┼──────────────┼──────────────────────────────┤
│ BareMetalHost        │ ✅     │ provisioned  │ Power: On, Updated: 10:29Z   │
│ InfraEnv             │ ✅     │ Image ready  │ Created: 10:15Z              │
│ AgentClusterInst     │ 🚀     │ installing   │ Writing image to disk (35%)  │
│ ManagedCluster       │ ⏳     │ Not ready    │ Joined: False                │
└──────────────────────┴────────┴──────────────┴──────────────────────────────┘

🤖 Agent Details (1 total, 1 approved)
┌─────────┬────────┬────────────┐
│ ID      │ Role   │ State      │
├─────────┼────────┼────────────┤
│ ...0005 │ master │ 🚀 installing │
└─────────┴────────┴────────────┘

📊 Installation Conditions:
   ✅ Validated
   ✅ RequirementsMet
   ⏳ Completed - False
   ✅ Failed - False
```
~~~

### Status Header Icons

Use these icons in the main header based on overall cluster state:
- `✅` COMPLETED - ACI_COMPLETED=True and ACI_FAILED=False
- `❌` FAILED - ACI_FAILED=True
- `🚀` INSTALLING - ACI_STATE=installing
- `⏳` PENDING - Waiting for resources
- `⚠️` WARNING - Partial issues detected


### Key Formatting Rules

- **Header:** Show overall status icon (✅/❌/🚀/⏳) based on ACI_STATE and ACI_COMPLETED
- **Section Icons:** Use 📋 (ClusterInstance), 📦 (Resources), 🤖 (Agents), 📊 (Conditions)
- **Box Drawing:** Use Unicode box characters: ┌ ┬ ┐ ├ ┼ ┤ └ ┴ ┘ │ ─ for tables
- **Separator Lines:** Use ━ for header separators
- **ClusterInstance Conditions:** Parse CI_CONDITIONS JSON, prefix each with status icon
- **Core Resources Table:** Always show all 4 resources with status icons in Status column
- **Agent Details:** Parse AGENT_DETAILS JSON with ID (last 4 chars), Role, State (with icon)
- **Installation Conditions:** Show 4 key conditions with status icons

## Error Handling

- Missing data → Show "N/A" in table
- Maintain table structure even with missing data
- Keep column widths aligned across all rows
