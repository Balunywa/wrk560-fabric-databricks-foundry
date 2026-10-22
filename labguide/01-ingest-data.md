# Exercise 01: Ingest Data from Analytical Data Sources into OneLake

### Estimated Duration: 20 Minutes

## 📘 Scenario

Zava is preparing for its merger with Litware Inc. Bryan, Zava's data engineer, needs to bring Litware's curated data from ADLS Gen2 into Zava's lakehouse so that analysts and data scientists can work with it. He wants to do this without building and maintaining copy pipelines.

## 📖 Overview

In this exercise, you act as Bryan. You create a Fabric workspace on your lab's Fabric capacity and a lakehouse inside it. You then create a OneLake shortcut that references Litware's data in ADLS Gen2 in place, and use a Spark notebook to load the CSV files into Delta tables.

## 🎯 Objectives

In this exercise, you will complete the following tasks:

- Task 1: Create a Fabric workspace and a lakehouse
- Task 2: Create a OneLake shortcut to ADLS Gen2
- Task 3: Create Delta tables with a Spark notebook

## Task 1: Create a Fabric workspace and a lakehouse

In this task, you create Zava's workspace on your dedicated Fabric capacity, and then create a lakehouse in it.

1. In Microsoft Fabric, select **Workspaces** from the left navigation pane, and then select **+ New workspace**.

    ![Create a new workspace](./media/create-new-workspace.png)

1. In the **Create a workspace** pane, enter the following name:

    - **Name:** <inject key="Fabric Workspace Name" enableCopy="true"/>

    ![Create workspace pane](./media/create-workspace-side-pane.png)

1. Expand **Advanced**. Under **License mode**, select **Fabric capacity**, select **<inject key="Fabric Capacity Name" enableCopy="false"/>** from the **Capacity** list, and then select **Apply**.

    ![Advanced workspace options](./media/create-workspace-side-pane-advanced.png)

    > **Note:** If you don't see your capacity in the list, wait one minute and refresh the browser page. The capacity is assigned to your account when the lab is provisioned.

    > **Note:** Close any pop-up dialogs that appear on the screen.

1. In the **<inject key="Fabric Workspace Name" enableCopy="false"/>** workspace, select **+ New item** from the top menu.

    ![Create a new item](./media/create-new-item.png)

1. In the **New item** pane, search for **Lakehouse** and select **Lakehouse**.

    ![Select Lakehouse](./media/create-lakehouse.png)

1. In the **New lakehouse** dialog, enter the following name, select the **Lakehouse schemas** checkbox, and then select **Create**:

    - **Name:** `ZavaLakehouse`

    ![New lakehouse dialog](./media/create-new-lakehouse.png)

    > **Note:** In a few seconds the lakehouse is ready. You didn't have to set up storage accounts, networking, key vaults, or subscriptions. With the right access, any department can create a lakehouse just by giving it a name.

## Task 2: Create a OneLake shortcut to ADLS Gen2

In this task, you reference Litware's curated data in ADLS Gen2 with a OneLake shortcut. The data stays where it is, and the lakehouse reads it in place.

### Get the storage account key

1. On your virtual machine desktop, double-click the **Azure Portal** shortcut. If you're prompted to sign in, use the same credentials as in the Getting Started page.

1. In the Azure portal search box, enter **<inject key="Resource Group Name" enableCopy="true"/>**, and then select the resource group from the search results.

    ![Search for the resource group](./media/azure-portal-search-rg.png)

1. In the resource group, select the **<inject key="Storage Account Name" enableCopy="false"/>** storage account.

    ![Select the storage account](./media/azure-portal-select-storage-account.png)

1. In the storage account pane, expand **Security + networking**, and then select **Access keys**.

    ![Access keys](./media/azure-portal-access-keys.png)

1. Next to **key1**, select **Show**, and then select the **Copy to clipboard** icon to copy the key.

### Create the shortcut

1. Return to the **Microsoft Fabric** tab in your browser and open the **ZavaLakehouse** lakehouse.

1. In the **Explorer** pane, select the **ellipsis (...)** next to **Files**, and then select **New shortcut**.

    > **Note:** Make sure you create the shortcut under **Files**, not under **Tables**.

    ![New shortcut](./media/create-new-shortcut.png)

1. In the **New shortcut** window, under **External sources**, select **Azure Data Lake Storage Gen2**.

    ![Select ADLS Gen2](./media/adls-gen2-source.png)

1. Select **Create new connection**, and enter the following connection details:

    - **URL:** <inject key="ADLS Gen2 Endpoint" enableCopy="true"/>
    - **Authentication kind:** **Account key**
    - **Account key:** Paste the **key1** value you copied from the Azure portal.

    Then select **Next**.

    ![ADLS Gen2 connection details](./media/adls-gen2-connection.png)

    > **Note:** If you copied another value from the lab guide after copying the key, your clipboard no longer contains the key. Copy **key1** again from the Azure portal.

    > **Note:** If account key authentication is blocked, select **Organizational account** as the **Authentication kind** instead. Your lab account has read access to the storage account.

1. Expand **data**, select the **litwaredata** checkbox, and then select **Next**.

    ![Select litwaredata](./media/litwaredata-checkboxes.png)

1. The data isn't in Delta format, so Fabric offers to transform it. You'll do that with a notebook in the next task, so select **Skip**.

    ![Skip the transform](./media/create-new-shortcut-transform.png)

1. Select **Create**.

    ![Create the shortcut](./media/adls-gen2-creation.png)

1. Your shortcut is ready. Under **Files**, select (don't expand) the new **litwaredata** shortcut to preview its files.

    ![The litwaredata shortcut](./media/new-shortcut-created.png)

    > **Note:** Before Fabric, Zava's departments moved the data they needed from other departments through slow ETL processes. With a shortcut, there is no copy to build or keep in sync.

## Task 3: Create Delta tables with a Spark notebook

In this task, you help Bryan load the remaining data into OneLake by converting the shortcut's CSV files into Delta tables. Delta tables give Zava reliable, scalable storage for big data workloads.

1. In the **ZavaLakehouse** lakehouse, select **Open notebook**, and then select **New notebook**.

    ![New notebook](./media/create-new-notebook.png)

1. Paste the following code into the first cell, and then select the **Run cell** icon:

    ```python
    import os
    import pandas as pd

    # List all CSV files in the 'litwaredata' folder
    file_path = '/lakehouse/default/Files/litwaredata/'
    csv_files = [file for file in os.listdir(file_path) if file.endswith('.csv')]

    # Load each CSV file into a table
    for file in csv_files:
        table_name = file.split('.')[0]
        df = pd.read_csv(file_path + file)
        spark.createDataFrame(df).write.mode("ignore").format("delta").saveAsTable(table_name)
    ```

    > **Note:** The first run in a session starts a Spark session, so it can take a minute or two. Later runs are faster.

1. When the cell finishes, a green check mark appears below it. In the **Explorer** pane, expand **Tables**, select the **ellipsis (...)** next to **dbo**, and then select **Refresh**. The new Delta tables appear under **dbo**.

    ![Refreshed Delta tables](./media/refresh-delta-tables.png)

    > **Note:** You should see eight tables: **customerchurndata**, **dimcustomer**, **dimdate**, **dimproduct**, **dimreseller**, **factinternetsales**, **factresellersales**, and **website_bounce_rate**.

1. All of Zava's tables are now in OneLake, ready for analysis.

    > **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
    > - Hit the Validate button for the corresponding task.
    > - If you receive a success message, you can proceed to the next task.
    > - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
    > - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

    <validation step="00000000-0000-0000-0000-0000000000a1" />

## 🧾 Summary

In this exercise, you created a Fabric workspace on a dedicated capacity and a lakehouse with schemas. You referenced Litware's ADLS Gen2 data with a OneLake shortcut, without moving it, and turned the CSV files into Delta tables with a Spark notebook.

### Click on **Next** from the page navigation bar at the end of the lab guide page to proceed to the next page.

![Next](./media/cloudlabs/next.png)
