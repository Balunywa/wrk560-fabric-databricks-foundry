# Modernize your data estate with Microsoft Fabric and Microsoft Foundry

### Overall Duration: 75 Minutes

## 📘 Lab Scenario

Zava is a regional DIY retailer with brick-and-mortar stores and an online store. Zava is acquiring **Litware Inc.**, which keeps curated marketing and sales data in the gold layer of **Azure Data Lake Storage (ADLS) Gen2**. Zava's customer churn data lives in the same storage layer.

The lab begins on January 30th. Zava's new CEO, Kayo, is worried about several KPIs: high customer churn, falling sales, a high website bounce rate, rising operating costs, poor customer experience, and low market sentiment. Kayo asks Carlos, the CTO, to make Zava a data-driven organization. Carlos hands the work to his team: **Bryan** (data engineer), **Wendy** (data analyst), and **Reta** (data scientist).

In this lab, you step into their shoes to unify Zava's and Litware's data in OneLake, analyze it with Copilot for Power BI, and build AI agents that answer business questions in natural language.

## 📖 Lab Overview

You start by creating a Fabric workspace and a lakehouse, then bring Litware's data into OneLake with an ADLS Gen2 shortcut, without copying it. You convert the raw CSV files into Delta tables with a Spark notebook. Next, you build a semantic model and use Copilot for Power BI to generate a report page, recommendations, and an executive summary. Finally, you build a Fabric data agent over the lakehouse, tune it with instructions and example queries, and connect it to a Microsoft Foundry agent that can also run code to chart the results.

## 🎯 Lab Objectives

- **Ingest data into OneLake:** Create a Fabric workspace and a lakehouse, reference Litware's ADLS Gen2 data with a OneLake shortcut, and load it into Delta tables with a Spark notebook.
- **Analyze campaign performance with Copilot for Power BI:** Create a semantic model, generate a report page with Copilot, and summarize it with the Narrative visual.
- **Build AI agents:** Create and tune a Fabric data agent, then ground a Microsoft Foundry agent with it and add the Code Interpreter tool.

## ⚙️ Prerequisites

- Basic familiarity with Microsoft Fabric concepts such as workspaces, lakehouses, and notebooks.
- Basic knowledge of SQL and Python.
- General awareness of generative AI concepts such as prompts and agents.

## 🏗️ Architecture

Litware's curated CSV files sit in an ADLS Gen2 storage account in your lab resource group. A OneLake shortcut in the **ZavaLakehouse** lakehouse references that data in place, and a Spark notebook writes it into Delta tables. The workspace runs on a dedicated Microsoft Fabric capacity. A Direct Lake semantic model on the bounce-rate table feeds a Power BI report that Copilot builds and summarizes. A Fabric data agent answers questions over the lakehouse tables. A Microsoft Foundry agent, backed by an Azure OpenAI model deployment, calls the published Fabric data agent as a knowledge tool and uses Code Interpreter to draw charts.

## 🖼️ Architecture Diagram

![Architecture diagram](./Images/architecture-fabric.png)

## 🔍 Explanation of Components

- **Microsoft Fabric capacity:** The dedicated compute your workspace runs on. Copilot and data agents need a paid capacity (F2 or larger).
- **OneLake and lakehouse:** OneLake is Fabric's single data lake. The lakehouse stores Delta tables and files, and a SQL analytics endpoint is created for it automatically.
- **OneLake shortcut:** A reference to data in another location (here, ADLS Gen2). The data is not copied or moved.
- **Spark notebook:** Runs Python code to turn the shortcut's CSV files into Delta tables.
- **Semantic model and Copilot for Power BI:** The semantic model defines tables for reporting. Copilot generates report pages, answers questions, and writes summaries.
- **Fabric data agent:** A conversational agent that writes and runs queries over selected lakehouse tables. Its behavior can be tuned with instructions and example queries.
- **Microsoft Foundry:** The platform for building agents. Your Foundry project has an Azure OpenAI model deployment and uses the Fabric data agent as a knowledge tool.

## 🧰 Your Lab Resources

These values are unique to your lab. You will use them throughout the exercises.

| Resource | Value |
|:---------|:------|
| Resource group | <inject key="Resource Group Name" enableCopy="true"/> |
| Fabric capacity | <inject key="Fabric Capacity Name" enableCopy="true"/> |
| Fabric workspace name to create | <inject key="Fabric Workspace Name" enableCopy="true"/> |
| Storage account | <inject key="Storage Account Name" enableCopy="true"/> |
| Foundry project | <inject key="Foundry Project Name" enableCopy="true"/> |
| Model deployment | <inject key="Model Deployment Name" enableCopy="true"/> |

## 🚀 Getting Started with the Lab

Welcome to the lab. Your environment is pre-provisioned with everything you need. Let's start by getting familiar with it.

## Accessing Your Lab Environment

Once you're ready to dive in, your virtual machine and **Guide** will be right at your fingertips within your web browser.

## Lab Guide Zoom In/Zoom Out

To adjust the zoom level for the environment page, click the **A↕** icon located next to the timer in the lab environment.

## Resize the Virtual Machine View

Use the **slider (three vertical dots)** located between the **Virtual Machine** and the **Guide** panes to adjust the display size, allowing you to customize the layout based on your preference.

## Exploring Your Lab Resources

To get a better understanding of your lab resources and credentials, navigate to the **Environment** tab.

## Utilizing the Split Window Feature

For convenience, you can open the lab guide in a separate window by selecting the **Split Window** button from the top right corner.

## Managing Your Virtual Machine

Feel free to **Start, Stop, or Restart (2)** your virtual machine as needed from the **Resources (1)** tab. Your experience is in your hands!

## Let's Get Started with Microsoft Fabric

1. On your virtual machine desktop, double-click the **Microsoft Fabric** shortcut. It opens `https://app.fabric.microsoft.com` in Microsoft Edge.

1. On the **Sign in** page, enter the following email/username and select **Next**:

    - **Email/Username:** <inject key="AzureAdUserEmail" enableCopy="true"/>

1. Enter the following Temporary Access Pass and select **Sign in**:

    - **Temporary Access Pass:** <inject key="AzureAdUserPassword" enableCopy="true"/>

1. If you're prompted to stay signed in, select **No**.

    > **Note:** Close any pop-up dialogs that appear on the screen.

1. If you're asked for your personal information, select **Continue**. In the **Job Title** field, enter `Data Expert`. In the **Business Phone Number** field, enter `1230000849`. Then select **Get Started**.

    > **Note:** Wait for the Fabric home page to load, and close the top banner for a better view.

1. Keep the Microsoft Fabric tab open. You will use it in the next exercise.

    > **Note:** Your workspace runs on the dedicated Fabric capacity **<inject key="Fabric Capacity Name" enableCopy="false"/>**, which was created for you. You don't need to start a Fabric trial.

## 📞 Support Contact

The **CloudLabs support team** is available 24/7, 365 days a year, via email and live chat to ensure seamless assistance at any time. We offer dedicated support channels tailored specifically for both learners and instructors, ensuring that all your needs are promptly and efficiently addressed.

Learner Support Contacts:

- Email Support: [cloudlabs-support@spektrasystems.com](mailto:cloudlabs-support@spektrasystems.com)
- Live Chat Support: https://cloudlabs.ai/labs-support

Click **Next** in the bottom right corner to embark on your Lab journey!

Now you're all set to explore the powerful world of technology. Feel free to reach out if you have any questions along the way. Enjoy your workshop!
