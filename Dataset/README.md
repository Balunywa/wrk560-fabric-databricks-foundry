# Lab data: litwaredata.zip

The lab VM downloads `litwaredata.zip` during deployment and uploads its CSV files to `stbuild<id>/data/litwaredata/`. In Exercise 01 they appear in Fabric through the **litwaredata** shortcut, and in Exercise 04 through the Unity Catalog volume `litware_uc_<id>.raw.litwaredata`.

| File | Rows | Source | Used in |
|---|---|---|---|
| `CustomerChurnData.csv` | 2,500 | Generated | Exercise 03 data agent and example query, Exercise 04 pipeline |
| `website_bounce_rate.csv` | 576 | Generated | Exercise 02 semantic model and Copilot report |
| `dimcustomer.csv` | 18,484 | AdventureWorksDW | Exercise 03 |
| `dimdate.csv` | 3,652 | AdventureWorksDW | Exercise 03 |
| `dimproduct.csv` | 606 | AdventureWorksDW | Exercises 03 and 04 |
| `dimreseller.csv` | 701 | AdventureWorksDW | Exercise 03 |
| `factinternetsales.csv` | 60,398 | AdventureWorksDW | Exercises 03 and 04 |
| `factresellersales.csv` | 60,855 | AdventureWorksDW | Exercise 03 |

The generated files follow the story in the lab:

- Millennials have the highest website bounce rate.
- Month-to-month store contracts churn the most.

To rebuild the zip, download the AdventureWorksDW `.csv` files and `instawdbdw.sql` from [microsoft/sql-server-samples](https://github.com/microsoft/sql-server-samples/tree/master/samples/databases/adventure-works/data-warehouse-install-script) into a folder, then run:

```bash
python -I tools/build-standin-data.py <that folder> Dataset/litwaredata.zip
```

If you get the original WRK560 data from the session owner, zip the eight CSV files with the same names and replace `litwaredata.zip`.
