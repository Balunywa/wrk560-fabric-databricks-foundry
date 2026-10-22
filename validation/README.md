# ✅ Validation scripts: WRK560

Three scripts back six CloudLabs validation steps: four in the Fabric-only variant, six in the full lab. Each script prints its checks to the function log and returns `{"Status":"Succeeded|Failed","Message":"..."}`. On failure, the message is a numbered list of what is missing and how to fix it.

The scripts follow the CloudLabs PowerShellV2 pattern used in Spektra-authored validators: no `param()` block (CloudLabs injects step parameters as variables), and the result is returned with `Push-OutputBinding`. Confirm this contract with your CloudLabs contact before go-live.

## 🗂️ Steps

| Guide page | Placeholder step GUID | Script | `Stage` | Variant | What it checks |
|---|---|---|---|---|---|
| `01-ingest-data.md`, end of Task 3 | `00000000-0000-0000-0000-0000000000a1` | `VAL-fabric.ps1` | `ingest` | both | Workspace `ZavaWorkspace_<id>` exists and is on a Fabric capacity; lakehouse `ZavaLakehouse`; at least one notebook |
| `02-power-bi-copilot.md`, end of Task 2 | `00000000-0000-0000-0000-0000000000a2` | `VAL-fabric.ps1` | `report` | both | Semantic model `website_bounce_rate_model`; at least one report |
| `03-data-agents.md`, end of Task 1 | `00000000-0000-0000-0000-0000000000a3` | `VAL-fabric.ps1` | `dataagent` | both | Data agent `ZavaDataAgent` (item type `DataAgent`, or the older `AISkill`) |
| `03-data-agents.md`, end of Task 3 | `00000000-0000-0000-0000-0000000000a4` | `VAL-foundry.ps1` | n/a | both | Project connection `ZavaDataAgent`; agent `Zava-Insights-Agent` with a Microsoft Fabric tool |
| `04-databricks-mirroring.md`, end of Task 2 | `00000000-0000-0000-0000-0000000000a5` | `VAL-databricks.ps1` | n/a | full | Pipeline `DLT_Pipeline` whose latest update is `COMPLETED`; tables `curated.churn_by_contract` and `curated.sales_by_product` that aren't streaming tables or views |
| `04-databricks-mirroring.md`, end of Task 3 | `00000000-0000-0000-0000-0000000000a6` | `VAL-fabric.ps1` | `mirror` | full | A `MirroredAzureDatabricksCatalog` item in the workspace |

After you create each validation step in CloudLabs, replace the placeholder GUID in the guide with the step ID CloudLabs gives you. Pages 01-03 are shared by both variants, so steps a1-a4 can be shared too, if CloudLabs lets two templates use the same step.

## ⚙️ CloudLabs settings

| Setting | `VAL-fabric.ps1` | `VAL-foundry.ps1` and `VAL-databricks.ps1` |
|---|---|---|
| Script Type | PowerShellV2 | PowerShellV2 |
| Run As | System | System |
| `DeploymentId` | `GET-DEPLOYMENT-ID` | `GET-DEPLOYMENT-ID` |
| `TenantId` | `GET-TENANT-ID` | `GET-TENANT-ID` |
| `ClientId` | App ID of a fixed **Fabric validation app** | `GET-SERVICEPRINCIPAL-APPLICATION-ID` |
| `ClientSecret` | Secret of the Fabric validation app | `GET-SERVICEPRINCIPAL-SECRET` |
| `Stage` | `ingest`, `report`, `dataagent`, or `mirror` (one per step) | not used |

## 🔐 Permissions

**Fabric validation app (one per lab tenant):**

- Register one app in the lab tenant and add its service principal to a security group, for example `sg-fabric-validators`.
- In the Fabric admin portal, allow that group in **Service principals can use Fabric APIs** and **Service principals can access read-only admin APIs**.
- No workspace roles are needed. The script only calls `GET /v1/admin/workspaces` and `GET /v1/admin/items`.

**Deployment service principal (Foundry and Databricks checks):**

- Reader on the lab subscription to find the resources. This is the CloudLabs default.
- **Azure AI User** on the Foundry resource to list agents.
- **Contributor** on the Databricks workspace, so the principal is added as a workspace admin on its first call (the `X-Databricks-Azure-SP-Management-Token` header flow).
- `deploy-01.json` assigns both roles when `validationSpObjectId` is set to `GET-SERVICEPRINCIPAL-SPOBJECT-ID`.
- `databricks-setup.ps1` grants `BROWSE` on the lab catalog to `account users`, so the validator can list the curated tables without data access.

## ⚠️ Known limits

- **Admin API throttling:** Fabric admin list APIs are rate-limited (documented at about 200 requests per hour). Each `VAL-fabric.ps1` run makes two calls. At an event with many learners, keep these validations optional rather than gating pages on them, or switch to pre-provisioned workspaces (see the main README) so you can use non-admin APIs.
- **Delta tables aren't checked in Fabric:** The admin APIs list items, not lakehouse tables. Checking the eight tables needs workspace access (OneLake or lakehouse APIs).
- **Two agent APIs:** Agents made in the classic Foundry experience are listed under `/assistants?api-version=v1`. Agents made in the new experience are listed under `/agents`. The script checks both, and ignores spaces and hyphens in the agent name.
- **Not run live yet:** All three scripts parse cleanly and pass stubbed success and failure runs, but they haven't been run against a live CloudLabs deployment. Run each step once on a test deployment, with both a completed lab and an empty one.
