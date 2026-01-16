---
name: visualize-cluster-status
description: Display comprehensive status of ZTP/RHACM clusters including ClusterInstance, installation progress, agents, and all related resources. Use this when the user asks to check cluster status, monitor installation, view cluster state, or troubleshoot deployment issues.
triggers:
  - "show cluster status"
  - "check cluster"
  - "monitor cluster"
  - "cluster installation progress"
  - "view cluster state"
  - "what's the status of"
  - "how is cluster"
  - "display cluster"
  - "visualize cluster"
---

# ZTP Cluster Status Visualization

Takes a cluster name or list of cluster names and displays comprehensive status information.
When visualizing a ZTP cluster (provided by RHACM), focuses on all relevant OpenShift CRs with context-aware detail levels.

**Performance:** Uses parallel data gathering - all OpenShift API queries execute simultaneously, completing in ~2 seconds instead of 10+ seconds with sequential queries.

## Data Collection Method

**Use the optimized data collection scripts** located in the same directory as this skill:

### One-time Status Check
```bash
.claude/skills/visualize-cluster-status/get-cluster-status.sh <cluster-name> <kubeconfig-path>
```

This script:
- Performs parallel data gathering for maximum performance (~2 seconds vs 10+ seconds)
- Handles the ClusterInstance existence check automatically
- Creates temporary files in `.temp/visualize-cluster-status/` (project-relative)
- Returns structured data as key-value pairs

**Usage:**
```bash
SKILL_DIR="<path-to>/.claude/skills/visualize-cluster-status"
DATA=$("$SKILL_DIR/get-cluster-status.sh" "$CLUSTER_NAME" "$KUBECONFIG_PATH")
```

### Continuous Monitoring (Optional)
For monitoring installation progress in real-time:
```bash
.claude/skills/visualize-cluster-status/monitor-cluster.sh <cluster-name> [kubeconfig-path] [interval-seconds]
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

1. **If the ClusterInstance does NOT exist**, the script returns:
   ```
   CLUSTER_NOT_DEPLOYED=true
   NAMESPACE_EXISTS=true/false
   ```

   Display a simple notice:
   ```
   # 🎯 <cluster-name> | Status: ❌ NOT DEPLOYED

   ## Cluster Status Summary
   The cluster <cluster-name> is **not currently deployed** on <hub-name>.

   **Findings:**
   - ❌ ClusterInstance CR: **NOT FOUND** in namespace <cluster-name>

   ## Next Steps
   To deploy this cluster, use:
   ```
   /deploy_clusters <cluster-name>
   ```
   ```

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

### Data Available from Script Output

The `get-cluster-status.sh` script returns the following variables (source the output or parse as key=value):

**ClusterInstance** - **PRIMARY CR** (show this FIRST):
- `CI_CREATED` - When cluster deployment was initiated
- `CI_GENERATION` - Current spec generation
- `CI_OBSERVED_GEN` - Last observed generation (compare to detect spec changes being processed)
- `CI_CONDITIONS` - JSON array of all conditions with type, status, message, and reason
- `CI_MANIFESTS_RENDERED` - JSON array of rendered manifests

**BareMetalHost**:
- `BMH_STATUS` - Operational status
- `BMH_PROV_STATE` - Provisioning state
- `BMH_POWER` - Power state (on/off)
- `BMH_LAST_UPDATED` - Last update timestamp

**InfraEnv**:
- `INFRAENV_IMAGE` - Whether ISO image was created (True/False)
- `INFRAENV_TIME` - When image was created
- `INFRAENV_CREATED_TIME` - InfraEnv creation timestamp

**AgentClusterInstall**:
- `ACI_STATE` - Current installation state (installing, adding-hosts, etc.)
- `ACI_INFO` - Detailed state information/message
- `ACI_PROGRESS` - Overall installation progress percentage
- `ACI_COMPLETED` - Completed condition status
- `ACI_FAILED` - Failed condition status
- `ACI_VALIDATED` - Validated condition status
- `ACI_REQS` - RequirementsMet condition status

**Agents**:
- `AGENT_COUNT` - Total number of agents
- `AGENT_APPROVED` - Number of approved agents
- `AGENT_DETAILS` - JSON array with agent info: `[{id, approved, state, role}, ...]`

**ManagedCluster**:
- `MC_AVAILABLE` - Available condition status
- `MC_JOINED` - Joined condition status
- `MC_CREATED` - When cluster was registered with hub

**Parsing the output:**
```bash
# Source the script output to get all variables
eval "$($SKILL_DIR/get-cluster-status.sh "$CLUSTER_NAME" "$KUBECONFIG_PATH")"

# Or parse manually:
while IFS='=' read -r key value; do
  export "$key=$value"
done < <($SKILL_DIR/get-cluster-status.sh "$CLUSTER_NAME" "$KUBECONFIG_PATH")
```

**Use ONLY the data returned by the script** - do not query for additional information, events, or troubleshooting details.

### Enhanced Output Example (During Installation)

```
# 🎯 vsno5 | Status: 🚀 INSTALLING (35%) | Started: 10:30Z

## ClusterInstance Status (Primary CR)
**Created:** 10:25Z | **Phase:** Provisioning
**Conditions:**
- ✅ ClusterInstanceValidated - Spec validation passed
- ✅ RenderedTemplates - Manifests rendered (15 total)
- ✅ RenderedTemplatesValidated - Templates validated successfully
- ✅ RenderedTemplatesApplied - Applied to namespace
- 🚀 ClusterProvisioning - Installation in progress

## Core Resources
+----------------------+--------+--------------+------------------------------+
| Resource             | Status | State/Info   | Details                      |
+----------------------+--------+--------------+------------------------------+
| 📦 BareMetalHost     | ✅     | provisioned  | Power: On, Updated: 10:29Z   |
| 💿 InfraEnv          | ✅     | Image ready  | Created: 10:15Z              |
| 🚀 AgentClusterInst  | 🚀     | installing   | Writing image to disk (35%)  |
| 🎮 ManagedCluster    | ⏳     | Not ready    | Joined: False                |
+----------------------+--------+--------------+------------------------------+

## Agent Details (1 total, 1 approved)
+---------+--------+------------+
| ID      | Role   | State      |
+---------+--------+------------+
| ...0005 | master | installing |
+---------+--------+------------+

**Installation Conditions:**
- ✅ Validated
- ✅ RequirementsMet
- 🚀 Completed - False
- ✅ Failed - False
```

### Compact Output Example (Completed Installation)

```
# 🎯 vsno5 | Status: ✅ INSTALLED | Duration: 25m

## ClusterInstance Status (Primary CR)
**Created:** 10:25Z | **Phase:** Deployed
- ✅ ClusterInstanceValidated - Validated
- ✅ RenderedTemplatesApplied - All manifests applied
- ✅ ClusterProvisioned - Provisioning complete
- ✅ ClusterDeployed - Cluster successfully deployed

## Core Resources
+----------------------+--------+--------------------+----------------------+
| Resource             | Status | State/Info         | Details              |
+----------------------+--------+--------------------+----------------------+
| 📦 BareMetalHost     | ✅     | provisioned/det.   | Power: Off           |
| 💿 InfraEnv          | ✅     | Image ready        | Created: 10:15Z      |
| 🚀 AgentClusterInst  | ✅     | adding-hosts       | Cluster is installed |
| 🎮 ManagedCluster    | ✅     | Available & Joined | Ready                |
+----------------------+--------+--------------------+----------------------+

## Agent Details (1 total, 1 approved)
+---------+--------+-----------+
| ID      | Role   | State     |
+---------+--------+-----------+
| ...0005 | master | installed |
+---------+--------+-----------+

**Conditions:** ✅ Validated ✅ Requirements ✅ Completed ✅ Not Failed
```

### Display Logic - Context-Aware Detail Level

**ALWAYS show ClusterInstance status first** as it's the primary CR that drives everything.

**Show ONLY the data returned by get-cluster-status.sh script** - no additional queries or troubleshooting information.

**When cluster is INSTALLING (state: installing, insufficient-hosts, pending-for-input):**
- Show ClusterInstance conditions in detail with messages
- Show installation progress percentage (from ACI_PROGRESS)
- Show agent details from AGENT_DETAILS (id, role, state, approved)
- Show condition statuses (ACI_VALIDATED, ACI_REQS, ACI_COMPLETED, ACI_FAILED)

**When cluster is INSTALLED/COMPLETE:**
- Show COMPACT view:
  - Summary status only
  - Agent counts and final states
  - Conditions as one-line summary with icons

**When cluster has ERRORS (Failed=True or state contains "error"):**
- Display the status as-is from the script data
- Show ACI_INFO field which contains error details
- Do NOT query for additional troubleshooting information

### Styling Rules

- **ASCII tables:** Use ASCII-style tables with +, -, and | characters (NOT markdown tables)
- **Terminal-friendly:** Format must render properly in plain text terminals
- **Table borders:** Use + for corners, - for horizontal lines, | for vertical separators
- **Column alignment:** Left-align text, pad with spaces for consistent column widths
- **Use icons consistently:** ✅ (success), ⚠️ (warning), ❌ (error), ⏳ (pending), 🚀 (installing)
- **Progress indicators:** Show percentage when available during installation (from ACI_PROGRESS)
- **Keep descriptions short:** Use abbreviations where clear (e.g., "AgentClusterInst" instead of "AgentClusterInstall")
- **Combine sections:** Don't create separate sections for each resource
- **Truncate IDs:** Show last 4 digits for agent IDs (from AGENT_DETAILS)
- **Inline conditions:** Expand during installation, compress when complete
- **No excessive whitespace:** Minimize blank lines between sections
- **Data scope:** Use ONLY data from get-cluster-status.sh output - no additional fields or queries

### Error Handling

- If resource not found: Show "N/A" or "Not created" in the table row
- Don't break layout: Maintain consistent column widths and table structure even with missing data
- If data field doesn't exist (e.g., progress.currentStage), gracefully omit or show "N/A"
- Keep table borders aligned: All rows should have the same column widths for proper terminal display



