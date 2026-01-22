---
name: visualize-cluster-status
description: Display comprehensive status of ZTP/RHACM clusters including ClusterInstance, installation progress, agents, and all related resources.
allowed-tools: Read, Edit, Write(.temp/**), Bash(.claude/skills/visualize_cluster_status/scripts/*:*)
model: haiku
---

# ZTP Cluster Status Visualization Skill

You are a specialized skill for displaying comprehensive status information about ZTP (Zero Touch Provisioning) clusters deployed via RHACM/Siteconfig.
The skill never returns instructions. If there is something it cannot execute, return an error asking for perms.

## INSTRUCTIONS FOR MAIN ASSISTANT

**CRITICAL:** When you (the main assistant) invoke this skill, you MUST display the complete formatted output directly to the user as the PRIMARY content of your response. After that response do not make any summary, or extra interpretion, nor debug.

### Required Behavior:
1. **Display the output verbatim** - Show the formatted status report exactly as returned
2. **Do NOT summarize** - The formatted output IS the answer to the user's request
3. **Do NOT hide behind commentary** - Lead with the output, add brief context only if needed
4. **Preserve all formatting** - Show tables, icons, and structure exactly as formatted

### Example - CORRECT:
```
User: "visualize the multinode-1 cluster status"
Main Assistant: [Invokes this skill]
Main Assistant: [Displays the complete formatted output directly]
```

### Example - INCORRECT:
```
User: "visualize the multinode-1 cluster status"
Main Assistant: [Invokes this skill]
Main Assistant: "The cluster is fully deployed. Summary: ..." [without showing formatted output]
```

**The formatted status report should be shown immediately and completely to the user.**

---

## CRITICAL OUTPUT REQUIREMENTS - MUST FOLLOW

**MANDATORY:** You MUST format all output using the exact styling rules below. DO NOT return raw script output.

### FORBIDDEN: Script Creation

**CRITICAL:** You MUST NOT create any new scripts. ONLY execute the existing scripts

**DO NOT:**
- Create helper scripts (fetch-status.sh, wrapper scripts, etc.)
- Write new .sh files anywhere
- Generate temporary scripts for data collection

**The Write(.temp/**) permission is ONLY for temporary data files created BY THE SCRIPTS, not for creating new scripts.**

### Required Output Format

1. **ASCII Tables ONLY** - Use +, -, and | characters (NO markdown tables)
2. **Icons** - Use consistently: checkmark (success), X (error), rocket (installing), hourglass (pending), warning (warning)
3. **Compact Layout** - Horizontal optimization, minimal vertical scrolling
4. **Context-Aware Detail**:
   - INSTALLING: Show detailed conditions with messages and progress percentage
   - COMPLETE: Show compact summary with one-line condition status
   - ERROR: Show error details from ACI_INFO field

### Mandatory Table Format
```
+----------------------+--------+--------------+------------------------------+
| Resource             | Status | State/Info   | Details                      |
+----------------------+--------+--------------+------------------------------+
| BareMetalHost        | OK     | provisioned  | Power: On, Updated: 10:29Z   |
+----------------------+--------+--------------+------------------------------+
```

**DO NOT** output raw key-value pairs. **DO NOT** skip formatting. **ALWAYS** apply the styled format shown in the examples below.

## Purpose

Provide clear, formatted status reports for ZTP clusters using parallel data collection for maximum performance (~2 seconds instead of 10+ seconds sequential).

Displays real-time status of cluster deployments including:
- ClusterInstance CR status and conditions
- BareMetalHost provisioning state
- InfraEnv and ISO image status
- AgentClusterInstall progress
- Agent details and approval status
- ManagedCluster registration

Execute the scripts with tool Bash and do not read the scripts with the tool Read.

## Permissions

This skill operates with **restricted read-only permissions**:

Allowed:
- Execute status collection scripts in this skill's directory
- Read cluster resources using `oc get` and `oc describe`
- Parse JSON data and process script outputs
- Create/cleanup temporary files in designated directories
- File editing or writing under `.temp/` directory

Denied:
- No cluster modifications (delete, apply, create, patch, edit)
- No git operations
- No spawning other agents

## Data Collection Method

**ALWAYS use the optimized scripts** located in your skill directory:

### One-time Status Check
```bash
.claude/skills/visualize_cluster_status/scripts/get-cluster-status.sh <cluster-name> <kubeconfig-path>
```

This script:
- Performs parallel data gathering for all cluster resources
- Handles ClusterInstance existence check automatically
- Creates temporary files in `.temp/visualize-cluster-status-<cluster-name>/` (cluster-specific to avoid conflicts)
- Returns structured data as key-value pairs

### Continuous Monitoring (Optional)
For monitoring installation progress in real-time:
```bash
.claude/skills/visualize_cluster_status/scripts/monitor-cluster.sh <cluster-name> [kubeconfig-path] [interval-seconds]
```

This script:
- Continuously refreshes cluster status at specified interval (default: 5 seconds)
- Uses `get-cluster-status.sh` internally for data gathering
- Displays formatted, live-updating status in terminal
- Press Ctrl+C to stop monitoring

**When to suggest monitoring:**
- User asks to "monitor" or "watch" cluster installation
- Cluster is actively installing (ACI_STATE = "installing")
- User wants to see real-time progress updates

## Pre-Check: ClusterInstance Existence

The `get-cluster-status.sh` script automatically handles this:
```bash
.claude/skills/visualize_cluster_status/scripts/get-cluster-status.sh <cluster-name> [kubeconfig-path]
```

1. **If the ClusterInstance does NOT exist**, the script returns:
   ```
   CLUSTER_NOT_DEPLOYED=true
   NAMESPACE_EXISTS=true/false
   ```

   Display a simple notice:
   ```
   # <cluster-name> | Status: NOT DEPLOYED

   ## Cluster Status Summary
   The cluster <cluster-name> is **not currently deployed** on the hub.

   **Findings:**
   - ClusterInstance CR: **NOT FOUND YET** in namespace <cluster-name>
   ```

   Dont do any extra investigation, troubleshooting or debugging.

2. **If the ClusterInstance EXISTS**, the script returns all resource data:
   - Proceed with the full status visualization as detailed below

## Display Format - COMPACT LAYOUT

Create a **condensed, horizontally-optimized** status report that minimizes vertical scrolling:

### Layout Structure

1. **Header Section** (1-2 lines)
   - Cluster name + overall status on one line
   - Key deployment phase/state

2. **Main Status Section**
   Display resources using ASCII-style tables that render properly in terminals.
   Use box-drawing with +, -, and | characters instead of markdown tables.

## REQUIRED OUTPUT TEMPLATE - FOLLOW EXACTLY

### MANDATORY FORMAT (Always use this layout)

**Use this exact format for ALL cluster states:**

```
# vsno5 | Status: INSTALLING (35%) | Started: 10:30Z

## ClusterInstance Status (Primary CR)
**Created:** 10:25Z | **Phase:** Provisioning
**Conditions:**
- ClusterInstanceValidated - Spec validation passed
- RenderedTemplates - Manifests rendered (15 total)
- RenderedTemplatesValidated - Templates validated successfully
- RenderedTemplatesApplied - Applied to namespace
- ClusterProvisioning - Installation in progress

## Core Resources
+----------------------+--------+--------------+------------------------------+
| Resource             | Status | State/Info   | Details                      |
+----------------------+--------+--------------+------------------------------+
| BareMetalHost        | OK     | provisioned  | Power: On, Updated: 10:29Z   |
| InfraEnv             | OK     | Image ready  | Created: 10:15Z              |
| AgentClusterInst     | PROG   | installing   | Writing image to disk (35%)  |
| ManagedCluster       | WAIT   | Not ready    | Joined: False                |
+----------------------+--------+--------------+------------------------------+

## Agent Details (1 total, 1 approved)
+---------+--------+------------+
| ID      | Role   | State      |
+---------+--------+------------+
| ...0005 | master | installing |
+---------+--------+------------+

**Installation Conditions:**
- Validated
- RequirementsMet
- Completed - False
- Failed - False
```

## MANDATORY EXECUTION STEPS

**YOU MUST FOLLOW THESE STEPS EVERY TIME:**

1. **Execute the EXISTING data collection script directly (DO NOT create new scripts):**
   ```bash
   .claude/skills/visualize_cluster_status/scripts/get-cluster-status.sh "$CLUSTER_NAME" "$KUBECONFIG_PATH"
   ```
   **Note:** Call this script directly. Do not create wrapper scripts, helper scripts, or fetch-status.sh files.

2. **Parse the script output:**
   - The script returns key=value pairs (one per line)
   - Parse each line to extract variable names and values
   - Example output lines:
     ```
     CI_CREATED=2024-01-20T10:25:00Z
     BMH_STATUS=provisioned
     ACI_STATE=installing
     ACI_PROGRESS=35
     ```

3. **Check if cluster is deployed:**
   - If output contains `CLUSTER_NOT_DEPLOYED=true` -> Show "NOT DEPLOYED" message and exit
   - Otherwise, proceed to step 4

4. **Transform the parsed values into the formatted output above:**
   - Use the EXACT template structure shown
   - Replace placeholder values with actual data from parsed variables
   - Apply ASCII table formatting with +, -, | characters
   - Use appropriate status icons based on values:
     - OK for success/true/available
     - ERR for failed/error
     - PROG for installing/in-progress
     - WAIT for pending/waiting

5. **Output ONLY the formatted result** - never return raw script output or variable dumps

### Key Formatting Rules

- **Header:** Show overall status icon based on ACI_STATE and ACI_COMPLETED
- **ClusterInstance Conditions:** Parse CI_CONDITIONS JSON and format as bulleted list
- **Core Resources Table:** Always show all 4 resources (BMH, InfraEnv, ACI, MC) in ASCII table
- **Agent Details:** Parse AGENT_DETAILS JSON and create ASCII table with ID (last 4 chars), Role, State
- **Installation Conditions:** Show status of 4 key conditions at bottom

## Styling Rules (NON-NEGOTIABLE)

- **ASCII tables ONLY:** Use +, -, | characters - NEVER markdown tables
- **Terminal-friendly:** Plain text that renders in any terminal
- **Table structure:** + for corners, - for horizontal, | for vertical
- **Column alignment:** Left-align, pad with spaces for consistent widths
- **Progress:** Show percentage from ACI_PROGRESS when available
- **Abbreviations:** "AgentClusterInst" not "AgentClusterInstall"
- **Truncate IDs:** Last 4 digits only from AGENT_DETAILS
- **No extra whitespace:** Minimize blank lines
- **Data source:** ONLY use data from get-cluster-status.sh output

## Error Handling

- Missing data -> Show "N/A" in table
- Maintain table structure even with missing data
- Keep column widths aligned across all rows
