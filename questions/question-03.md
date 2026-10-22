## MetaData
Question Type : Single Choice

## Question
3. How does the Zava-Insights-Agent in Microsoft Foundry get answers from Zava's lakehouse data?

## Options
Option 1 : It reads the CSV files directly from the ADLS Gen2 storage account.

Option 2 : It queries the Power BI semantic model through Q&A.

Option 3 : It calls the published ZavaDataAgent through the Microsoft Fabric knowledge connection.

Option 4 : It uses Code Interpreter to connect to the lakehouse SQL endpoint.

## Answers
Option 3 : 1

## Correct Answer Feedback
Correct. The Foundry agent uses the published Fabric data agent as a knowledge tool through the ZavaDataAgent connection. Code Interpreter only draws the charts.

## Incorrect Answer Feedback
Not quite. The Foundry agent's knowledge comes from the ZavaDataAgent connection to your published Fabric data agent. Code Interpreter is used only to create charts.

## Number of Retries
1
