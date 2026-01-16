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

## Pre-Check: ClusterInstance Existence

**BEFORE gathering any other data**, first check if the ClusterInstance CR exists:

1. Check for ClusterInstance CR in the cluster's namespace:
   ```bash
   oc --kubeconfig="$KUBECONFIG" get clusterinstance <cluster-name> -n <cluster-name> 2>&1
   ```

2. **If the ClusterInstance does NOT exist** (namespace not found OR ClusterInstance not found):
   - Display a simple, clear notice that the cluster is not deployed
   - **DO NOT proceed with gathering other resource data**
   - Example output:
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

3. **If the ClusterInstance EXISTS**:
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

### Data to Collect

**ClusterInstance** (namespace: cluster-name, kind: ClusterInstance, name: cluster-name) - **PRIMARY CR**:
- `metadata.creationTimestamp` - When cluster deployment was initiated
- `metadata.generation` vs `status.observedGeneration` - Check if spec changes are being processed
- `status.conditions[]` - All conditions with their status, message, and reason:
  - `ClusterInstanceValidated` - Whether the ClusterInstance spec is valid
  - `RenderedTemplates` - If manifests were successfully rendered
  - `RenderedTemplatesValidated` - If rendered templates passed validation
  - `RenderedTemplatesApplied` - If manifests were applied to cluster namespace
  - `ClusterProvisioned` - Overall provisioning status
  - `ClusterProvisioning` - Active provisioning state
  - `ClusterDeployed` - Final deployment status
- `status.manifestsRendered` - Count of rendered manifests
- `status.deployedManifests` - List of successfully deployed manifests
- Show this CR FIRST as it's the main entry point

**BareMetalHost** (namespace: cluster-name, kind: BareMetalHost, name: cluster-name):
- `status.operationalStatus`
- `status.provisioning.state`
- `status.poweredOn`
- `status.lastUpdated` (for timing info)

**InfraEnv** (namespace: cluster-name, kind: InfraEnv, name: cluster-name):
- `status.conditions[?(@.type=="ImageCreated")].status`
- `status.conditions[?(@.type=="ImageCreated")].lastTransitionTime`
- `status.createdTime` (when ISO was created)

**AgentClusterInstall** (namespace: cluster-name, kind: AgentClusterInstall, name: cluster-name):
- `status.debugInfo.state` - Current installation state
- `status.debugInfo.stateInfo` - Detailed state information
- `status.debugInfo.eventsURL` - Link to events (if available)
- `status.progress.totalPercentage` or `status.debugInfo.totalPercentage` - Overall progress
- `status.installStartedAt` - Installation start time
- **ALL conditions with messages** for detailed status:
  - `Completed` - Installation completion status
  - `Failed` - Failure status with reason
  - `Validated` - Pre-installation validation
  - `RequirementsMet` - Hardware/network requirements
  - `SpecSynced` - Configuration sync status
  - `Stopped` - If installation stopped
- `status.validationsInfo` - Detailed validation results (if available)

**Agents** (namespace: cluster-name, kind: Agent):
- Count total agents
- Count approved vs unapproved
- **For each agent:**
  - `metadata.name` (truncate to last 4 chars for display)
  - `spec.approved` - Approval status
  - `status.debugInfo.state` - Current state (discovering, known, insufficient, installing, installed)
  - `status.role` - Assigned role (master, worker)
  - `status.progress.currentStage` - Current installation stage
  - `status.progress.progressInfo` - Detailed progress
  - `status.validationsInfo` - Validation results (hardware, network, etc.)
  - `status.inventory.hostname` - Host identification
  - **Key validations to show:**
    - Hardware validation (CPU, RAM, Disk)
    - Network validation (connectivity, DNS)
    - Container runtime validation

**ManagedCluster** (kind: ManagedCluster, name: cluster-name):
- `status.conditions[?(@.type=="ManagedClusterConditionAvailable")].status`
- `status.conditions[?(@.type=="ManagedClusterJoined")].status`
- `metadata.creationTimestamp` - When cluster was registered

**Installation Events** (Optional but recommended during installation):
- Get recent events in the cluster namespace to show progress/errors:
  - `oc get events -n <cluster-name> --sort-by='.lastTimestamp' | tail -5`
  - Show only warnings/errors if installation is failing

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
+---------+-------------------+--------+------------+----------------------+----------+
| ID      | Hostname          | Role   | State      | Stage                | Progress |
+---------+-------------------+--------+------------+----------------------+----------+
| ...0005 | node1.example.com | master | installing | Writing image to disk| 35%      |
+---------+-------------------+--------+------------+----------------------+----------+

**Agent Validations:**
- ✅ Hardware: CPU(8), RAM(32GB), Disk(120GB)
- ✅ Network: Connectivity OK, DNS resolved
- ✅ Container runtime ready

**Installation Conditions:**
- ✅ Validated - All pre-flight checks passed
- ✅ RequirementsMet - Hardware and network requirements satisfied
- 🚀 Completed - False (in progress)
- ✅ Failed - False

**Recent Events:**
- 10:35:12 - Agent installation in progress: Writing image to disk
- 10:32:45 - Agent started installation
- 10:30:20 - Cluster installation initiated
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
+---------+-------------------+--------+-----------+-------+
| ID      | Hostname          | Role   | State     | Stage |
+---------+-------------------+--------+-----------+-------+
| ...0005 | node1.example.com | master | installed | Done  |
+---------+-------------------+--------+-----------+-------+

**Conditions:** ✅ Validated ✅ Requirements ✅ Completed ✅ Not Failed
```

### Display Logic - Context-Aware Detail Level

**ALWAYS show ClusterInstance status first** as it's the primary CR that drives everything.

**When cluster is INSTALLING (state: installing, insufficient-hosts, pending-for-input):**
- Show ClusterInstance conditions in detail with messages
- Show FULL details including:
  - Installation progress percentage
  - Current installation stage for each agent
  - Agent validations (hardware, network)
  - Recent events (last 3-5)
  - Installation start time and elapsed duration
  - Detailed condition messages (not just status)

**When cluster is INSTALLED/COMPLETE:**
- Show COMPACT view:
  - Summary status only
  - Agent counts and final states
  - Conditions as one-line summary with icons
  - No need for detailed validations or events

**When cluster has ERRORS (Failed=True or state contains "error"):**
- Show ERROR details:
  - Failed condition message
  - Agent validation failures
  - Recent error events
  - Troubleshooting hints if available

### Styling Rules

- **ASCII tables:** Use ASCII-style tables with +, -, and | characters (NOT markdown tables)
- **Terminal-friendly:** Format must render properly in plain text terminals
- **Table borders:** Use + for corners, - for horizontal lines, | for vertical separators
- **Column alignment:** Left-align text, pad with spaces for consistent column widths
- **Use icons consistently:** ✅ (success), ⚠️ (warning), ❌ (error), ⏳ (pending), 🚀 (installing)
- **Progress indicators:** Show percentage when available during installation
- **Timing info:** Calculate and show elapsed time during installation
- **Keep descriptions short:** Use abbreviations where clear (e.g., "AgentClusterInst" instead of "AgentClusterInstall")
- **Combine sections:** Don't create separate sections for each resource
- **Truncate IDs:** Show last 4 digits for agent IDs
- **Hostname display:** Show hostname when available (more useful than agent ID)
- **Inline conditions:** Expand during installation, compress when complete
- **No excessive whitespace:** Minimize blank lines between sections

### Error Handling

- If resource not found: Show "N/A" or "Not created" in the table row
- Don't break layout: Maintain consistent column widths and table structure even with missing data
- If data field doesn't exist (e.g., progress.currentStage), gracefully omit or show "N/A"
- Keep table borders aligned: All rows should have the same column widths for proper terminal display



