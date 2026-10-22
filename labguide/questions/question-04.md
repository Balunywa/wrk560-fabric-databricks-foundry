## MetaData
Question Type : Single Choice

## Question
Why did you copy the pipeline's gold results into the curated schema before you mirrored the catalog into Fabric?

## Options
Option 1 : Fabric mirroring doesn't support streaming tables and materialized views, which the DLT pipeline creates.

Option 2 : Fabric mirroring can only read tables that are stored in OneLake.

Option 3 : The medallion schema is deleted when the pipeline finishes.

Option 4 : T-SQL can only query tables with names that end in _by_product or _by_contract.

## Answers
Option 1 : 1

## Correct Answer Feedback
Correct. A DLT pipeline produces streaming tables and materialized views. Fabric mirroring reads regular Delta tables, so you published the gold results as tables in the curated schema.

## Incorrect Answer Feedback
Not quite. Mirroring reads the Unity Catalog tables in place in ADLS Gen2, but it doesn't support streaming tables or materialized views. That's why you published the gold results as regular Delta tables.

## Number of Retries
1
