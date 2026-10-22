# CloudLabs screenshots to capture

These images are specific to the CloudLabs environment, so they can't come from the WRK560 source repo. Capture them from a test deployment, and annotate click targets with numbered callouts (**(1)**, **(2)**) to match CloudLabs guide style.

| File | Page | What to show |
|---|---|---|
| `architecture.png` | Getting Started | Lab architecture: ADLS Gen2 → OneLake shortcut → ZavaLakehouse (Delta) → semantic model / Copilot report → Fabric data agent → Foundry agent (model + Code Interpreter) |
| `labguide.png` | Getting Started | CloudLabs window with the VM on the left and the Guide on the right |
| `zoominout.png` | Getting Started | The **A↕** zoom control next to the timer |
| `vmresizing.png` | Getting Started | The three-dot slider between the VM and Guide panes |
| `environment.png` | Getting Started | The **Environment** tab with the lab outputs |
| `splitwindow.png` | Getting Started | The **Split Window** button |
| `resources.png` | Getting Started | The **Resources** tab with Start, Stop, and Restart |
| `fabric-shortcut.png` | Getting Started | The **Microsoft Fabric** desktop shortcut on the lab VM |
| `signin-email.png` | Getting Started | Microsoft sign-in page, email step |
| `signin-tap.png` | Getting Started | Microsoft sign-in page, Temporary Access Pass step |
| `next.png` | All pages | The **Next** button in the guide's page navigation bar |

You can reuse the generic ones (`labguide`, `zoominout`, `vmresizing`, `environment`, `splitwindow`, `resources`, `next`) from any recent CloudLabs lab, because the CloudLabs chrome is the same across labs.

## Source screenshots to re-capture

Run `tools/fetch-source-media.ps1` to copy the 70 Fabric, Foundry, and Databricks screenshots from the source repo into `labguide/media/`. These ones show Skillable-specific names or flows and should be re-captured:

- `azure-portal-search-rg.png` and `azure-portal-select-storage-account.png` show `rg-build25` and `stbuild<id>`. CloudLabs uses its own resource group name.
- `create-workspace-side-pane-advanced.png` shows the Skillable shared capacity, not `fabric<id>`.
- `azure-ai-foundry-select-project.png` shows a hub-based project with **Studio web URL**. This package deploys a Foundry project, which has **Go to Foundry portal**.
- `azure-ai-foundry-*` agent screenshots show the `gpt-4o` deployment. This package deploys `gpt-5.1` by default.
- The Exercise 04 Databricks screenshots (`databricks-*`, `azure-databricks-launch-workspace.png`) come from the original November 2025 lab. They show the `Analytics with ADB` folder, but also the old `dbo` destination schema and Skillable names. Re-capture them with `litware_uc_<id>` and the `medallion` schema.
- `fabric-connect.png` shows **Service principal** authentication. This package uses **Organizational account**.
- `fabric-choose-catalog.png` and `fabric-explorer-pane.png` show `litware_unity_catalog` with the `default` and `rag` schemas. This package uses `litware_uc_<id>` with the `curated` schema.
