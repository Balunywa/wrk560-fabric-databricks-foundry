# WRK560 on CloudLabs (Spektra Systems)

This package re-authors the Microsoft AI Tour 2026 workshop **WRK560: Modernize your data estate with Microsoft Fabric, Azure Databricks, and Microsoft Foundry** as a CloudLabs lab. The source is a Skillable lab: [microsoft/aitour26-WRK560-...](https://github.com/microsoft/aitour26-WRK560-modernize-your-data-estate-ms-fabric-azure-databricks-and-microsoft-foundry). The lab steps, prompts, and code are adapted from that repo (docs under CC BY 4.0, code under MIT).

It ships **two variants from one template**:

| Variant | Master document | Parameter file | Pages | Duration |
|---|---|---|---|---|
| **Full**: Fabric, Azure Databricks, and Foundry | `masterdoc.json` | `deploy/deploy-01.parameters.json` (`deployDatabricks = true`) | Getting Started, Exercises 01-04, knowledge check | 100 min |
| **Fabric-only**: Fabric and Foundry, retitled | `masterdoc-fabric.json` | `deploy/deploy-01-fabric.parameters.json` (`deployDatabricks = false`) | Getting Started (Fabric), Exercises 01-03, knowledge check | 75 min |

It contains:

- A CloudLabs lab guide: two master documents, seven pages, and four questions.
- A CloudLabs ARM template and two parameter files.
- The lab VM setup scripts, including the Databricks Unity Catalog setup.
- A Delta Live Tables notebook.
- Three validation scripts that back six validation steps.

Part 1 explains how CloudLabs labs are built. Part 2 explains how WRK560 maps onto that format. Part 3 is the setup checklist.

---

## Part 1: How a CloudLabs lab is built

A CloudLabs lab has three layers. You configure the first and third in the CloudLabs portal. The lab guide lives in GitHub.

| Layer | What it is | Where it lives |
|---|---|---|
| **Template** | The environment: cloud platform, ARM template and parameter file URLs, VM access (RDP over HTTPS), licenses, role permissions, validations, and the master document URL | CloudLabs portal > Templates |
| **Lab guide** | Markdown pages listed in a `masterdoc.json` manifest, rendered in the **Guide** pane | GitHub (public, or private with CloudLabs access enabled) |
| **ODL (On-Demand Lab)** | One event or delivery of a template: dates, seats, duration | CloudLabs portal > On Demand Labs |

### The lab guide

**Master document (`masterdoc.json`).** This is an array with one object per language. CloudLabs reads it from the **GitHub Master Document URL** field on the template. A repo can hold several master documents, one per lab variant, that share pages.

```json
[
  {
    "Name": "Lab title",
    "Language": "English",
    "BaseURL": "https://github.com/ORG/REPO",
    "Files": [
      { "RawFilePath": "https://raw.githubusercontent.com/ORG/REPO/main/labguide/00-getting-started.md", "Order": 1 },
      {
        "RawFilePath": "https://raw.githubusercontent.com/ORG/REPO/main/labguide/01-exercise.md",
        "Order": 2,
        "UnlockingRules": [
          { "UnlockDependency": "Validations", "DependentValidations": ["<step-id>"], "UnlockCriteria": "Execution" }
        ]
      }
    ]
  }
]
```

- **`RawFilePath`** must be an absolute `raw.githubusercontent.com` URL. Spektra has hit a known pitfall here: a raw-domain `BaseURL` combined with relative paths paginates correctly but renders every page as "unavailable".
- **`UnlockingRules`** (optional) gates a page. `UnlockDependency` is `Validations`, `Questions`, or `GroupedQuestions`. `UnlockCriteria` is `Execution`, `Answered`, or `Score` (with `UnlockPercentageThreshold`).
- The CloudLabs API also returns `PageDuration` per file, plus `EnableLabGuidePageDuration`, which turns on timed pages.

**Page conventions.** These come from the HorizonDB preview you shared and from Spektra's Fabric labs.

- Getting Started page: `# Title`, `### Overall Duration`, then 📘 Lab Scenario, 📖 Lab Overview, 🎯 Lab Objectives, ⚙️ Prerequisites, 🏗️ Architecture, 🖼️ Architecture Diagram, 🔍 Explanation of Components. These are followed by the standard CloudLabs orientation blocks (zoom, resize, Environment tab, Split Window, Resources tab), sign-in steps, 📞 Support Contact, and the **Next** image.
- Exercise pages: `# Exercise 0N: ...`, `### Estimated Duration`, 📘 Scenario, 📖 Overview, 🎯 Objectives (a task list), then `## Task N:` sections. They close with 🧾 Summary and a `### Click on Next ...` footer.
- Steps use `1.` numbering throughout, bold UI labels, numbered screenshot callouts **(1)**, and `> **Note:**` blockquotes. Images are relative (`./media/x.png`) and resolve next to the page's raw URL. Each code block gets a copy button.

**Inject tags.** These insert per-learner values.

| Syntax | Notes |
|---|---|
| `<inject key="AzureAdUserEmail" enableCopy="true"/>` | Built-in keys: `AzureAdUserEmail`, `AzureAdUserPassword`, `DeploymentID`, `ApplicationID`, `DisplayName`, `SecretKey`, `SubscriptionID`, `TenantID`, `TenantDomainName` |
| `<inject key="Fabric Workspace Name"/>` | Any ARM template **output name** becomes a key, and also shows on the **Environment** tab |
| `enableCopy="true\|false"` | Shows or hides the copy icon |
| `style="color:blue"` | Colors the value |

Inject tags work inline, in tables, and inside code blocks (Exercise 04 injects the catalog name into SQL).

**Validations.** A validation step sits after the "Congratulations… Hit the Validate button" blockquote:

```html
<validation step="22466566-151d-4c22-aa45-3bc3c4867d8e" />
```

The GUID is the step ID that CloudLabs assigns when you create the validation in the portal. Each step runs a script (Script Type **PowerShellV2**) in the CloudLabs validation Function App. The script follows this contract:

- Step parameters (for example `DeploymentId = GET-DEPLOYMENT-ID`) are injected as variables, so the script has no `param()` block.
- The script returns `{"Status":"Succeeded|Failed","Message":"..."}` through `Push-OutputBinding`.

**Questions.**

- `<question source="./questions/q1.md" />` adds an inline question.
- `<grouped-questions source="./questions/set/metadata.md" />` adds a scored set. The metadata file lists the questions and the number of retries.

A question file has these `##` sections: `MetaData` (`Question Type : Single Choice` or `Text Input`), `Question`, `Options` (`Option 1 : ...`), `Answers` (`Option 2 : 1`), `Correct Answer Feedback`, `Incorrect Answer Feedback`, `Tags`, and `Number of Retries`.

### The environment

**ARM parameter placeholders.** CloudLabs swaps these in the parameter file at deploy time.

| Placeholder | Value |
|---|---|
| `GET-DEPLOYMENT-ID` | Unique per-learner ID (use it in every resource name) |
| `GET-AZUSER-UPN` / `GET-AZUSER-PASSWORD` / `GET-AZUSER-OBJECTID` | The lab user's UPN, password (often a Temporary Access Pass), and object ID |
| `GET-TENANT-ID`, `GET-TENANT-FQDN` | Tenant ID and domain |
| `GET-SERVICEPRINCIPAL-APPLICATION-ID` / `-SECRET` / `-SPOBJECT-ID` | The deployment's service principal |
| `GEN-PASSWORD`, `GEN-UNIQUE[-n]`, `GEN-GUID`, `GEN-SSH-PUB-KEY` | Generated values |
| `GET-TEMPLATE-FILE-BASEURI`, `GET-PARAMETER-FILE-BASEURI` | Where the template files are hosted |

**Outputs.** Template outputs become **Environment** tab entries and inject keys. Outputs can carry an ARM `condition`, so a variant only shows the outputs it deploys. CloudLabs needs `LabVM DNS Name`, `LabVM Admin Username`, `LabVM Admin Password`, `TrainerUserName`, and `TrainerUserPassword` to configure browser-based RDP. List the trainer outputs under **Excluding Output Parameters** to hide them from learners.

**VM bootstrap.** The VM's Custom Script Extension downloads Spektra's shared library `https://experienceazure.blob.core.windows.net/templates/cloudlabs-common/cloudlabs-windows-functions.ps1` next to your script and dot-sources it. The usual calls are:

- `WindowsServerCommon`: TLS 1.2, IE ESC off, Chocolatey, Edge, `C:\LabFiles`, firewall off
- `CreateCredFile`: puts `AzureCreds.txt` on the desktop
- `Enable-CloudLabsEmbeddedShadow`: lets instructors shadow the learner's session
- `Install*` helpers: VS Code, Python, Az CLI, Power BI Desktop, and so on

---

## Part 2: How WRK560 maps to CloudLabs

### Syntax mapping

| Skillable (source) | CloudLabs (this package) |
|---|---|
| One `lab/README.md` with `===` page breaks and `!INSTRUCTIONS[title](url)` includes | One Markdown file per page, ordered by `masterdoc.json` |
| `@lab.CloudPortalCredential(User1).Username` | `<inject key="AzureAdUserEmail" enableCopy="true"/>` |
| `@lab.CloudPortalCredential(User1).AccessToken` (TAP) | `<inject key="AzureAdUserPassword" enableCopy="true"/>` |
| `@lab.LabInstance.Id` | `<inject key="DeploymentID" enableCopy="false"/>`, or a dedicated output such as `Fabric Workspace Name` |
| `@lab.Variable(storageaccountkey)`, `@lab.Variable(workspaceurl)` | ARM outputs, injected by name (`Databricks Workspace URL`) |
| `@lab.VirtualMachine(...).Username/Password` and "Sign into Windows" | Removed: CloudLabs signs the learner in to the VM over HTTPS RDP |
| `> [!NOTE]`, `> [!IMPORTANT]` | `> **Note:**`, `> **Important:**` (GitHub alert syntax also renders) |
| "Select **Next >**" | "Click on **Next** from the page navigation bar" + `next.png` |
| Skillable lab profile (VM image, cloud slice, life-cycle scripts) | CloudLabs template + `deploy-01.json` + `psscript.ps1` + `databricks-setup.ps1` |
| `ADB Connection Details.txt` on the desktop with a service principal secret | Removed: the Fabric connection uses the learner's **Organizational account** |
| No scoring in the source | `<validation step="..."/>` steps + `validation/*.ps1`, and a knowledge check |

### Page mapping

| Skillable page | CloudLabs page | Variant |
|---|---|---|
| `lab/README.md` intro, `overview.md`, Windows sign-in | `00-getting-started.md` (full) or `00-getting-started-fabric.md` | one each |
| Tutorial 1.1, 1.2, 1.3 | `01-ingest-data.md`: Tasks 1-3, plus validation | both |
| Tutorial 2 | `02-power-bi-copilot.md`: Tasks 1-2, plus validation | both |
| Tutorial 3.1, 3.2, 3.3 | `03-data-agents.md`: Tasks 1-3, plus two validations | both |
| Removed in Dec 2025: `tutorial-2-dlt-pipeline-with-azure-databricks.md` and `tutorial-4-mirror-azure-databricks.md` | `04-databricks-mirroring.md`: Tasks 1-3, two validations, and an inline question | full |
| Tutorial 4 (clean up) | `05-knowledge-check.md`: knowledge check, optional clean up, conclusion | both |

### Environment mapping

| Skillable resource | CloudLabs resource (`deploy-01.json`) | Inject key |
|---|---|---|
| `rg-build25` | CloudLabs per-learner resource group | `Resource Group Name` |
| Shared tenant Fabric capacity | `Microsoft.Fabric/capacities` **fabcap&lt;id&gt;** (F8 by default), with the learner as capacity admin | `Fabric Capacity Name` |
| `stbuild<id>`, pre-loaded with `litwaredata` | ADLS Gen2 **stbuild&lt;id&gt;**, with `data/litwaredata/*.csv` seeded by `psscript.ps1`. The learner gets Storage Blob Data Reader. The full variant adds a `unity` container for catalog storage. | `Storage Account Name`, `ADLS Gen2 Endpoint` |
| Hub-based project `prj-build-<id>`, plus a separate Azure OpenAI resource with `gpt-4o` | Foundry resource **aif-build-&lt;id&gt;** + project **prj-build-&lt;id&gt;** + model deployment. The learner gets Azure AI User. | `Foundry Project Name`, `Model Deployment Name` |
| `adb-build-<id>`, pre-built `litware_unity_catalog`, shared "Analytics with ADB" notebook (full only) | Premium **adb-build-&lt;id&gt;** + access connector **adbac-build-&lt;id&gt;**. `databricks-setup.ps1` creates catalog **litware_uc_&lt;id&gt;** (schemas `raw`, `medallion`, `curated`), the `raw.litwaredata` volume, the grants, and `/Shared/Analytics with ADB/01 DLT Notebook`. | `Databricks Workspace Name`, `Databricks Workspace URL`, `Unity Catalog Name` |
| Win11 VM | Windows Server 2022 lab VM with a managed identity, and Edge shortcuts for Fabric, the Azure portal, and Foundry | `LabVM ...` (CloudLabs RDP) |

### How the Databricks exercise was restored

The source repo's history shows the original design. Commit `919e407e` (December 2025) removed two Databricks tutorials, and commit `2910e615` (January 2026) removed a Unity Catalog shortcut step. Both relied on assets baked into the Skillable image that were never in the repo:

- the "01 DLT Notebook"
- the `litware_unity_catalog` catalog
- a service principal whose secret sat in a desktop text file

This package rebuilds them for CloudLabs. `04-databricks-mirroring.md` follows the original flow: Launch Workspace > ETL pipeline `DLT_Pipeline` from the shared notebook > Start > lineage, then a Mirrored Azure Databricks catalog > SQL analytics endpoint. It reuses the 13 orphaned Databricks screenshots. The changes are:

1. **New DLT notebook** (`deploy/dlt-notebook.py`). The original notebook wasn't published. The new one has these layers:
    - **Bronze:** Auto Loader over the `raw.litwaredata` volume
    - **Silver:** typed columns, plus `expect_or_drop` checks such as `Churn IN ('Yes','No')`
    - **Gold:** `gold_churn_by_contract`, which mirrors the data agent's example query, and `gold_sales_by_product`
2. **A publish step.** Fabric mirroring doesn't support streaming tables, materialized views, or views, which are exactly what a DLT pipeline produces. Learners therefore run two `CREATE OR REPLACE TABLE ... AS SELECT` statements into `curated` before they mirror.
3. **A per-learner, workspace-bound catalog.** Unity Catalog objects live in the regional metastore, which every lab in the CloudLabs tenant shares. So the catalog is `litware_uc_<id>`, not `litware_unity_catalog`, and it's isolated to the learner's workspace. Storage credentials and external locations carry the ID too.
4. **Organizational account** for the Fabric connection, instead of a service principal secret file.
5. **Automated setup.** The VM's managed identity has Contributor on the workspace, so its first API call makes it a workspace admin. In auto-enabled Unity Catalog workspaces, workspace admins hold `CREATE CATALOG`, `CREATE EXTERNAL LOCATION`, and `CREATE STORAGE CREDENTIAL` by default. As catalog owner, the identity can also grant the learner `EXTERNAL USE SCHEMA`. That privilege is never included in `ALL PRIVILEGES` and must be granted explicitly.

### What changed from the source, and why

1. **Dedicated Fabric capacity per learner, no trial.** Copilot for Power BI and Fabric data agents don't run on trial capacity, so the workspace is assigned to `fabcap<id>`.
2. **Foundry project instead of a hub with a separate Azure OpenAI resource.** The model is deployed in the project's own Foundry resource, so the source step "Management center > New connection > Azure OpenAI" is gone. Only the Microsoft Fabric connection remains.
3. **Model default is `gpt-5.1` (2025-11-13), not `gpt-4o`.** As of the September 2026 retirement schedule, gpt-4o 2024-11-20 is *Legacy*, and 2024-05-13 and 2024-08-06 are *Deprecated*, which blocks new subscriptions. gpt-4.1 is also deprecated. gpt-5.1 is the listed replacement and is GA until 2027-05-15. The model is a parameter, and the guide injects the deployment name.
4. **Agent name `Zava-Insights-Agent`.** Agents created in the new Foundry experience don't allow spaces in names. The validator ignores spaces and hyphens either way.
5. **Removed:** the regale.cloud "Click-by-Click" backup link and the Windows sign-in step.
6. **Added:** a resources table, an Organizational-account fallback for the shortcut, a report name (`Website Bounce Rate Report`), six validation steps, and four questions.
7. **Exercise order.** Databricks is Exercise 04, not 02 as in the original. Exercises 01-03 are then identical in both variants, and the Fabric-only variant simply stops after Exercise 03.

### Open issues for the content owner

- **Lab data isn't in the source repo.** See [data/README.md](data/README.md). `CustomerChurnData.csv` has no public copy, so ask the WRK560 owner for the `litwaredata` set. Without it the lab can't run.
- **The DLT notebook depends on column names** that the lab guide doesn't use elsewhere: `ProductKey`, `SalesAmount`, `OrderQuantity` (factinternetsales) and `ProductKey`, `EnglishProductName` (dimproduct). These are standard AdventureWorksDW columns, but check them against the real files.
- **Persona mismatch.** The source overview names the data analyst *Eric*, but Tutorial 2 calls her *Wendy*. This package uses Wendy throughout.
- **UI drift.** Re-capture these against the portals you'll deliver on:
    - Exercise 03 Tasks 2-3 (Foundry, classic versus new experience)
    - Exercise 04 Task 2 (the Databricks pipeline creation page changes often)
- **Leftover Unity Catalog objects.** Deleting the CloudLabs resource group removes the workspace and the storage account, but `litware_uc_<id>`, `el_build_<id>_*`, and `sc_build_<id>` stay in the shared metastore. Schedule a cleanup job (as a metastore admin) that drops those objects for deployments that no longer exist.

---

## Part 3: CloudLabs setup checklist

**Tenant (once, by the admins of the CloudLabs lab tenant):**

1. Turn on these Fabric admin portal settings:
    - **Users can create Fabric items**
    - **Users can use Copilot and other features powered by Azure OpenAI**
    - **Data agent** item creation
    - If your capacity region has no Azure OpenAI, also allow processing outside the capacity's geographic region
2. Create the Fabric validation app and security group, and allow the group in the two service-principal API settings ([validation/README.md](validation/README.md)).
3. **Full variant only.** In the Azure Databricks account console:
    - Assign a **metastore admin** group for the region's metastore. Auto-created metastores have none.
    - As that admin, turn on **External data access** for the metastore (Catalog > gear > Metastore > Details). Fabric mirroring can't read the catalog without it.
    - Confirm serverless compute is enabled for pipelines and SQL warehouses.
    - Confirm `RestrictWorkspaceAdmins` isn't blocking the default workspace-admin privileges.

**Templates (CloudLabs portal > Templates > + Add).** Create one template per variant. Both use the same `deploy/deploy-01.json`, with a different parameter file and master document.

1. **Cloud Platform:** Microsoft Azure. **Deployment Plan:** Single Resource Group. **Region:** one that has Fabric capacities, Foundry Agent Service, `gpt-5.1` Global Standard, and, for the full variant, Fabric mirroring for Azure Databricks. East US 2 and Sweden Central qualify. **Approx. Deployment Duration:** about 20 minutes (Fabric-only) or 30 minutes (full).
2. **ARM Template URL** / **Parameter Template URL:** publicly readable URLs for `deploy/deploy-01.json`, plus `deploy-01.parameters.json` (full) or `deploy-01-fabric.parameters.json`. Set `scriptBaseUrl` and `labDataZipUrl` in the parameter file first.
3. **Enable VM Access Over Http:** on. **Virtual Machine Configuration:** Name `labvm-{GET-DEPLOYMENT-ID}`, Type `RDP`, and the server DNS name, username, and password from `LabVM DNS Name`, `LabVM Admin Username`, and `LabVM Admin Password`. Set the instructor from `TrainerUserName` / `TrainerUserPassword`.
4. **Excluding Output Parameters:** `TrainerUserName`, `TrainerUserPassword`.
5. **Template Permissions:** Contributor (or Owner) on the resource group for the attendee, applied at launch. This is needed to read storage access keys in Exercise 01 and to become a Databricks workspace admin.
6. **MS Cloud Licenses:** Power BI Pro, which learners need to create reports in a workspace on an F SKU below F64.
7. **GitHub Master Document URL:** the raw URL of `masterdoc.json` (full) or `masterdoc-fabric.json`, for example `https://raw.githubusercontent.com/Balunywa/wrk560-cloudlabs/main/masterdoc.json`. If you move the repo, update the URLs in both master documents and in `scriptBaseUrl` in both parameter files.
8. **Validations:** create the steps from [validation/README.md](validation/README.md) (four for Fabric-only, six for full), then paste each step ID into the matching `<validation step>` tag.

**Repository:**

1. Push this package to GitHub. Run `pwsh ./tools/fetch-source-media.ps1` to pull the 70 reusable screenshots, then capture the CloudLabs-specific ones ([labguide/media/cloudlabs/README.md](labguide/media/cloudlabs/README.md)).
2. Do a full test run of each variant on a test ODL, including every validation, both passing and failing.
3. In the full variant, check `C:\WindowsAzure\Logs\CloudLabsCustomScriptExtension.txt` on the VM. The last line should read `Databricks setup complete`.

**Cost.** The F8 capacity is billed from deployment until CloudLabs deletes the resource group, at roughly 4× the F2 rate. The full variant adds serverless DBUs for one pipeline update and a 2X-Small SQL warehouse that auto-stops after 10 minutes. Check current Fabric and Databricks pricing for your region.

---

## Package layout

| Path | What it is |
|---|---|
| `masterdoc.json`, `masterdoc-fabric.json` | CloudLabs master documents (full: 6 pages, Fabric-only: 5 pages) |
| `labguide/00-getting-started.md`, `labguide/00-getting-started-fabric.md` | Getting Started pages per variant |
| `labguide/01-ingest-data.md` ... `labguide/03-data-agents.md` | Shared exercise pages |
| `labguide/04-databricks-mirroring.md` | Exercise 04 (full only) |
| `labguide/05-knowledge-check.md`, `labguide/questions/question-0N.md` | Knowledge check (questions 1-3) and Exercise 04's inline question (4) |
| `labguide/media/cloudlabs/README.md` | Screenshot capture list |
| `deploy/deploy-01.json`, `deploy/deploy-01.parameters.json`, `deploy/deploy-01-fabric.parameters.json` | CloudLabs ARM template and the two variant parameter files |
| `deploy/psscript.ps1` | Lab VM setup: CloudLabs common functions, Edge shortcuts, data seeding with AzCopy |
| `deploy/databricks-setup.ps1`, `deploy/dlt-notebook.py` | Unity Catalog setup and the DLT notebook (full only) |
| `validation/VAL-fabric.ps1`, `VAL-foundry.ps1`, `VAL-databricks.ps1`, `validation/README.md` | Validation scripts and their CloudLabs settings |
| `data/README.md` | The lab data contract and where to get the data |
| `tools/fetch-source-media.ps1` | Copies the source screenshots into `labguide/media/` |

## Sources

- [CloudLabs: Authoring Lab Guides using GitHub](https://help.cloudlabs.ai/docs/authoring-lab-guides)
- [CloudLabs: Best Practices (parameter placeholders)](https://help.cloudlabs.ai/docs/best-practices-for-cloudlabs)
- [CloudLabs: Onboarding VM with an ARM template](https://help.cloudlabs.ai/docs/onboarding-vm-with-azure-based-azure-resource-manager-template)
- [CloudLabs: Create User Specified ARM Template](https://help.cloudlabs.ai/docs/create-user-specified-arm-template) and its sample [`deploy-05.json`](https://cloudlabsai.blob.core.windows.net/templates/deploy-05.json)
- [CloudLabs-AI/sample-lab-guide](https://github.com/CloudLabs-AI/sample-lab-guide): official masterdoc, unlocking rules, and question format
- [CloudLabs-MOC/mslearn-fabric](https://github.com/CloudLabs-MOC/mslearn-fabric): Spektra's Fabric labs in CloudLabs format
- [fardeena-spektra/AWS-IoT-ML-GenAI-Bedrock-Lab](https://github.com/fardeena-spektra/AWS-IoT-ML-GenAI-Bedrock-Lab): Spektra's validator contract and package layout
- [praveens-git-bit/LAB364...](https://github.com/praveens-git-bit/LAB364Modernize-data-estate-MS-Fabric-Azure-Databricks-and-AI-Foundry): an earlier CloudLabs version of this lab's predecessor
- The HorizonDB CloudLabs preview you shared (`experience.cloudlabs.ai/#labguidepreview/ec53acf2-...`)
- [Foundry model retirement schedule](https://learn.microsoft.com/azure/foundry/openai/concepts/model-retirement-schedule) (updated 2026-09-23)
- [Fabric: Mirrored Azure Databricks catalog tutorial](https://learn.microsoft.com/fabric/mirroring/azure-databricks-tutorial) and [limitations](https://learn.microsoft.com/fabric/mirroring/azure-databricks-limitations)
- [Databricks: Admin privileges in Unity Catalog](https://learn.microsoft.com/azure/databricks/data-governance/unity-catalog/manage-privileges/admin-privileges) and [Enable external data access](https://learn.microsoft.com/azure/databricks/external-access/admin)
