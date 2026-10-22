## MetaData
Question Type : Single Choice

## Question
1. What happens to Litware's data when you create an ADLS Gen2 shortcut in the ZavaLakehouse lakehouse?

## Options
Option 1 : The data is copied into OneLake and kept in sync on a schedule.

Option 2 : The data stays in ADLS Gen2, and OneLake references it in place.

Option 3 : The data is moved into OneLake and deleted from ADLS Gen2.

Option 4 : The data is converted to Delta tables automatically.

## Answers
Option 2 : 1

## Correct Answer Feedback
Correct. A shortcut is a reference. The data isn't copied or moved, so there is no ETL pipeline to build or maintain.

## Incorrect Answer Feedback
Not quite. A OneLake shortcut references data where it already lives. You converted the CSV files to Delta tables yourself, with the notebook in Task 3.

## Number of Retries
1
