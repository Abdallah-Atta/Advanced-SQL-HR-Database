# Advanced-SQL-HR-Database

•	Business Description
1.	Each Employee has an ID, Name, Gender, Age, Department in which he works, hire date, Salary, Job role, Whether he works overtime or not, whether he travels for business or not, and whether he is still in the company or left.
2.	Additionally, we must keep track of each employee's educational history, level, and field.
3.	We also need to maintain track of the employee's past, including when they last received a promotion, how long they've been employed by the company, how long they've been under the same manager, and how long they've been in their current position.
4.	We must also keep track of the number and nature of our departments.
5.	Each employee receives an annual review with HR and their direct manager. During this review, the employee completes a survey in which they rate their level of satisfaction with their job, the environment, their relationships with coworkers, and their work-life balance on a scale of 1 to 5. In addition, students score their own performance in the previous year on a scale of 1 to 5. While their managers also rate them on a scale of 1 to 5.

•	Project Steps
1. From Business Description to ERD
  - Understand Requirements: Thoroughly review the business requirements document to understand the entities, relationships, and constraints.
  - Identify Entities and Relationships: Determine the key entities (e.g., employees, departments) and their relationships (e.g., employees belong to departments).
  - Create ERD: Use an ERD tool (like Microsoft Visio, Lucidchart, or an online ERD tool) to create a visual representation of the entities, their attributes, and      their relationships.
2. To Mapping
  - Map Entities to Tables: Convert the entities identified in the ERD into database tables.
  - Define Attributes and Data Types: Determine the columns for each table based on the attributes from the ERD and assign appropriate data types.
  - Establish Relationships: Implement primary keys, foreign keys, and constraints to maintain data integrity and enforce relationships.
3. To Build Database in MSSQL
  - Create Database: Use SQL Server Management Studio (SSMS) or T-SQL to create the database.
  - Create Tables: Define the schema using CREATE TABLE statements, specifying columns and data types.
  - Implement Constraints: Add primary keys, foreign keys, and other constraints to ensure data integrity.
4. Upload Data from Excel Files to HR Database
  - Prepare Excel Files: Ensure that Excel files are properly formatted and cleaned.
  - Use SQL Server Import and Export Wizard: Utilize SSMS’s Import and Export Wizard to import data from Excel to SQL Server.
  - Verify Data Import: Check that data has been imported correctly and matches the expected format.
5. Create Indexes
  - Identify Performance Needs: Determine which columns will benefit from indexing based on query performance needs.
  - Create Indexes: Use CREATE INDEX statements to improve query performance for frequently accessed columns.
6. Using Views, Subqueries, Functions, Stored Procedures, Triggers, and Advanced DQL Queries
  - Views: Create views to simplify complex queries or to present data in a specific format using CREATE VIEW.
  - Subqueries: Use subqueries within SELECT, UPDATE, DELETE, and INSERT statements to perform complex data retrieval.
  - Functions: Define user-defined functions to encapsulate reusable logic and calculations using CREATE FUNCTION.
  - Stored Procedures: Implement stored procedures for recurring tasks or complex operations using CREATE PROCEDURE.
  - Triggers: Set up triggers to automatically perform actions in response to data modifications using CREATE TRIGGER.
  - Advanced DQL Queries: Utilize advanced SQL queries to extract insights, such as complex joins, window functions, or common table expressions (CTEs).
