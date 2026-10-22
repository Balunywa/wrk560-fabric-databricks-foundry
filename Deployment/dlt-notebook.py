# Databricks notebook source
# MAGIC %md
# MAGIC # 01 DLT Notebook: Litware medallion pipeline
# MAGIC
# MAGIC This notebook defines a Lakeflow Declarative Pipeline (Delta Live Tables) over Litware's raw CSV files.
# MAGIC
# MAGIC - **Bronze** ingests the raw files from the `raw.litwaredata` volume with Auto Loader.
# MAGIC - **Silver** types the columns and drops bad records with data quality expectations.
# MAGIC - **Gold** aggregates churn by store contract and sales by product for Zava's analysts.
# MAGIC
# MAGIC Run it as a pipeline, not cell by cell. The setup script filled in this lab's catalog name below.

# COMMAND ----------

import dlt
from pyspark.sql import functions as F

RAW_PATH = "/Volumes/__CATALOG__/raw/litwaredata/"


def read_raw_csv(file_name):
    """Streams one CSV file from the raw volume with Auto Loader and adds lineage columns."""
    return (
        spark.readStream.format("cloudFiles")
        .option("cloudFiles.format", "csv")
        .option("header", "true")
        .option("pathGlobFilter", file_name)
        .load(RAW_PATH)
        .withColumn("_ingested_at", F.current_timestamp())
        .withColumn("_source_file", F.col("_metadata.file_path"))
    )

# COMMAND ----------

# MAGIC %md
# MAGIC ## Bronze: raw files as they arrive

# COMMAND ----------

@dlt.table(comment="Raw Litware customer churn records")
def bronze_customer_churn():
    return read_raw_csv("CustomerChurnData.csv")


@dlt.table(comment="Raw Litware internet sales lines")
def bronze_internet_sales():
    return read_raw_csv("factinternetsales.csv")


@dlt.table(comment="Raw Litware product list")
def bronze_products():
    return read_raw_csv("dimproduct.csv")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Silver: typed and validated

# COMMAND ----------

@dlt.table(comment="Customer churn records with a valid churn flag and amount")
@dlt.expect_or_drop("valid_churn_flag", "Churn IN ('Yes', 'No')")
@dlt.expect_or_drop("valid_total_amount", "TotalAmount IS NOT NULL AND TotalAmount >= 0")
@dlt.expect("has_store_contract", "StoreContract IS NOT NULL")
def silver_customer_churn():
    return (
        spark.readStream.table("bronze_customer_churn")
        .withColumn("TotalAmount", F.col("TotalAmount").cast("double"))
    )


@dlt.table(comment="Internet sales lines with numeric keys and amounts")
@dlt.expect_or_drop("valid_product", "ProductKey IS NOT NULL")
@dlt.expect_or_drop("valid_sales_amount", "SalesAmount IS NOT NULL")
def silver_internet_sales():
    return (
        spark.readStream.table("bronze_internet_sales")
        .withColumn("ProductKey", F.col("ProductKey").cast("int"))
        .withColumn("OrderQuantity", F.col("OrderQuantity").cast("int"))
        .withColumn("SalesAmount", F.col("SalesAmount").cast("double"))
    )


@dlt.table(comment="One row per product with its English name")
def silver_products():
    return (
        spark.read.table("bronze_products")
        .select(F.col("ProductKey").cast("int").alias("ProductKey"), "EnglishProductName")
        .dropDuplicates(["ProductKey"])
    )

# COMMAND ----------

# MAGIC %md
# MAGIC ## Gold: business aggregates

# COMMAND ----------

@dlt.table(comment="Churn rate and projected annual revenue by store contract")
def gold_churn_by_contract():
    churned = F.col("Churn") == "Yes"
    return (
        spark.read.table("silver_customer_churn")
        .groupBy("StoreContract")
        .agg(
            F.count("*").alias("Customers"),
            F.sum(F.when(churned, 1).otherwise(0)).alias("ChurnedCustomers"),
            F.round(F.sum(F.when(churned, F.col("TotalAmount") * 12).otherwise(0)), 2).alias("ProjectedLostRevenue"),
            F.round(F.sum(F.when(~churned, F.col("TotalAmount") * 12).otherwise(0)), 2).alias("ProjectedRetainedRevenue"),
        )
        .withColumn("ChurnRate", F.round(F.col("ChurnedCustomers") / F.col("Customers"), 4))
    )


@dlt.table(comment="Internet sales revenue and units by product")
def gold_sales_by_product():
    return (
        spark.read.table("silver_internet_sales")
        .join(spark.read.table("silver_products"), "ProductKey", "left")
        .groupBy("ProductKey", "EnglishProductName")
        .agg(
            F.round(F.sum("SalesAmount"), 2).alias("TotalRevenue"),
            F.sum("OrderQuantity").alias("UnitsSold"),
        )
    )
