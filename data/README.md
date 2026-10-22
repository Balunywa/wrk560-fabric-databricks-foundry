# 📦 Lab data: litwaredata.zip

The WRK560 GitHub repo doesn't include the lab data. Its `data/` folder is an empty placeholder because Skillable pre-loads the storage account from the lab profile. For CloudLabs, you host the data yourself, and the VM's setup script uploads it during deployment.

## What the deployment expects

`deploy/psscript.ps1` downloads the zip from the `labDataZipUrl` parameter and uploads every `.csv` file in it (at any folder depth) to:

```
https://stbuild<DeploymentID>.blob.core.windows.net/data/litwaredata/
```

In the lab, learners select **data** > **litwaredata** in the shortcut wizard, so the shortcut appears as `Files/litwaredata/` and the notebook reads `/lakehouse/default/Files/litwaredata/`.

| File | Becomes table | Used in | Columns the lab depends on |
|---|---|---|---|
| `CustomerChurnData.csv` | `customerchurndata` | Ex 03 data agent, example query | `StoreContract`, `Churn` (`Yes`/`No`), `TotalAmount` |
| `dimcustomer.csv` | `dimcustomer` | Ex 03 | AdventureWorksDW `DimCustomer` |
| `dimdate.csv` | `dimdate` | Ex 03 | AdventureWorksDW `DimDate` |
| `dimproduct.csv` | `dimproduct` | Ex 03 | AdventureWorksDW `DimProduct` |
| `dimreseller.csv` | `dimreseller` | Ex 03 | AdventureWorksDW `DimReseller` |
| `factinternetsales.csv` | `factinternetsales` | Ex 03 "most sold product" | AdventureWorksDW `FactInternetSales` |
| `factresellersales.csv` | `factresellersales` | Ex 03 | AdventureWorksDW `FactResellerSales` |
| `website_bounce_rate.csv` | `website_bounce_rate` | Ex 02 semantic model and Copilot | `CustomerGeneration` (includes `Millennials`), `CustomerSentiment`, `DeviceType`, `ProductAvailability`, `ProductCategory`, `ProductMatch`, `Number_of_times_products_searches_did_not_matched`, `total_number_of_time_products_searches`, `Website_Bounce_rate`, `Website_visitors`, `SemanticModel_key` |

All files need a header row. The Fabric notebook reads them with `pandas.read_csv` defaults (comma-delimited).

**Full variant (Exercise 04):** In Unity Catalog, the same folder is exposed as the external volume `litware_uc_<id>.raw.litwaredata`. The DLT notebook (`deploy/dlt-notebook.py`) also relies on these columns:

| File | Columns the DLT notebook uses |
|---|---|
| `CustomerChurnData.csv` | `StoreContract`, `Churn`, `TotalAmount` |
| `factinternetsales.csv` | `ProductKey`, `OrderQuantity`, `SalesAmount` |
| `dimproduct.csv` | `ProductKey`, `EnglishProductName` |

The sales columns are standard AdventureWorksDW names. If the real files differ, update the notebook before you publish.

## Where to get it

1. **Recommended:** Ask the WRK560 content owner (Someleze Diko, listed in the repo README) or the AI Tour lab team for the exact `litwaredata` files from the Skillable lab profile. This keeps Copilot's and the agents' answers matching the screenshots.
2. **Partial public sources** (check each license before you redistribute):
    - `website_bounce_rate.csv` with the same columns is in [dreamdemos-ms/PowerBI-Copilot](https://github.com/dreamdemos-ms/PowerBI-Copilot). That repo has no license file.
    - The AdventureWorksDW tables are in [microsoft/sql-server-samples](https://github.com/microsoft/sql-server-samples/tree/master/samples/databases/adventure-works/data-warehouse-install-script) (MIT). Those files are pipe-delimited without headers, so you'd need to convert them.
    - I found no public copy of `CustomerChurnData.csv`.

## Hosting the zip

Upload `litwaredata.zip` to a blob container that CloudLabs deployments can read: either public read access, or a long-lived read-only SAS appended to the URL. Then set `labDataZipUrl` in `deploy/deploy-01.parameters.json`. Don't commit customer or licensed data to a public repo.
