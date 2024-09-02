-------------------------------------------------<< Indeces >>--------------------------------------------

CREATE UNIQUE INDEX dept_Manager
	ON	Department(Mang_ID)

CREATE NONCLUSTERED INDEX Emp_Hist
	ON History(Emp_ID)


-------------------------------------------------<< VIEWS >>--------------------------------------------

--1) This is a Summary View for the Mangers over their departments

CREATE VIEW dept_info
AS
	SELECT  d.Mang_ID AS Manager_Id,
			d.Dep_Name AS Department,
			Count(e.Emp_ID) AS NO_Employees,
			SUM(e.Salary) AS Total_salary,
			AVG(e.Salary) AS Average_Salary,
			AVG(r.ManagerRating) AS	Average_Performance
 	FROM Employee e INNER JOIN Review r 
		ON e.Emp_ID = r.EmployeeID INNER JOIN
		Department d ON e.Dept_id =d.Dept_ID
	WHERE e.Attrition = 0
	GROUP BY d.Dep_Name,d.Mang_ID
GO

SELECT * FROM dept_info di

--2) View to display Active Employees in the company

Create view ActiveEmployees
	as 
		select * from Employee
		where Attrition = 0
Go
select * from ActiveEmployees

--3) Rating for employees' satisfaction with their environment.

CREATE VIEW environment_satisfaction 
	AS
		SELECT EnvironmentSatisfaction AS Environment_satisfaction_rate, COUNT(EmployeeID) No_Employee
		FROM Review
		GROUP BY EnvironmentSatisfaction
GO
SELECT * 
FROM environment_satisfaction
ORDER BY Environment_satisfaction_rate

--4) Rating for employees' satisfaction with their job role. 

CREATE VIEW job_satisfaction 
	AS	
		SELECT JobSatisfaction AS job_satisfaction_rate, COUNT(EmployeeID) AS No_Employee
		FROM Review
		GROUP BY JobSatisfaction

GO		
SELECT *
FROM job_satisfaction
ORDER BY job_satisfaction_rate

--5) Rating for employees' satisfaction with their relationships at work. 


CREATE VIEW relationships_satisfaction 
	AS
		SELECT RelationshipSatisfaction	As relationship_satisfaction_rate, COUNT(EmployeeID) AS No_Employee
		FROM Review
		GROUP BY RelationshipSatisfaction
GO
SELECT *
FROM relationships_satisfaction
ORDER BY relationship_satisfaction_rate



--6) Rating for employees' satisfaction with their work-life balance. 


CREATE VIEW work_life_balance_satisfaction 
	AS
		SELECT WorkLifeBalance AS workLife_balance_rate, COUNT(EmployeeID) AS No_Employee
		FROM Review
		GROUP BY WorkLifeBalance
GO
SELECT *
FROM work_life_balance_satisfaction
ORDER BY workLife_balance_rate


--7) Rating for employees' performance based on their own views. 

CREATE VIEW self_rate 
	AS
		SELECT SelfRating AS Self_Rating , COUNT(EmployeeID) AS No_Employee
		FROM Review
		GROUP BY SelfRating
GO
SELECT *
FROM self_rate
ORDER BY Self_Rating


-------------------------------------------------<< FUNCTIONS >>--------------------------------------------

--1) Function takes  department id as an input to calculate attrition rates for this department

CREATE FUNCTION Attrition_Rate (@dept_id INT)
RETURNS NVARCHAR(100)
AS
	BEGIN
	
	declare @percent float
	declare @dept_name varchar(50)

		SELECT	@percent = Cast(COUNT(CASE WHEN e.Attrition = 'True' THEN 1 END) AS FLOAT) / cast(COUNT(e.Attrition) AS FLOAT) * 100 ,
				@dept_name = d.Dep_Name
		FROM Employee e INNER JOIN Department d
			ON	e.Dept_id = d.Dept_ID 
		WHERE d.Dept_ID = @dept_id
		GROUP BY d.Dep_Name

		return  Concat('Attrition rate in ' , @dept_name, ' department ' , ' is ' , @percent ,'%')

	END
GO
select dbo.Attrition_Rate(1)
select dbo.Attrition_Rate(2)
select dbo.Attrition_Rate(3)

/*--2) Function takes employee is as an input to detect if an employee is qualified for promotion or not based on
1- Education Level
2- Manager Rate
3- Years in Most Recent Role
4- Years Since Last Promotion */

CREATE FUNCTION promotionCritera(@Emp_id nvarchar(50))
RETURNS VARCHAR(50)
AS
	BEGIN
		declare @education_level int
		declare @manager_rate int
		declare @avg_manager_rate float
		declare @YearsInMostRecentRole int 
		declare @YearsSinceLastPromotion int 
		declare @avg_YearsInMostRecentRole float
		declare @avg_YearsSinceLastPromotion FLOAT

			SELECT 
				@avg_manager_rate = CAST(AVG(r.ManagerRating) AS FLOAT) ,
				@avg_YearsInMostRecentRole = CAST(AVG(h.YearsInMostRecentRole) AS FLOAT),
				@avg_YearsSinceLastPromotion = cast(AVG(h.YearsSinceLastPromotion) as float)
			FROM 
			ActiveEmployees ae INNER JOIN Review r
				ON ae.Emp_ID = r.EmployeeID
			INNER JOIN History h
				ON ae.Emp_ID = h.Emp_ID

			SELECT 
				@education_level = el.Edu_ID ,
				@manager_rate = r.ManagerRating ,
				@YearsInMostRecentRole = YearsInMostRecentRole,
				@YearsSinceLastPromotion = YearsSinceLastPromotion
			FROM
			ActiveEmployees ae INNER JOIN Review r
				ON ae.Emp_ID = r.EmployeeID
			INNER JOIN History h
				ON ae.Emp_ID = h.Emp_ID
			INNER JOIN EducationLevel el
				ON ae.Edu_id = ae.Edu_id
			WHERE ae.Emp_ID = @Emp_id

			RETURN 
				CASE 
                   	WHEN @education_level > 3
						AND	(@manager_rate >= @avg_manager_rate 
								OR @YearsInMostRecentRole>@avg_YearsInMostRecentRole 
								OR  @YearsSinceLastPromotion >@avg_YearsSinceLastPromotion)
					THEN 'Employee is qalified for promotion'
					else 'Employee is not qalified for promotion'	

                END

	END
Go
select dbo.promotionCritera('005C-E0FB')


--3) Create function takes DepartmentID and gets the best employee in it (without duplicates)


CREATE FUNCTION best_employee_department(@dept_id INT)
RETURNS TABLE
AS
RETURN (
    WITH RankedEmployees AS (
        SELECT
            e.F_Name + ' ' + e.L_Name AS Full_Name,
            D.Dep_Name AS Department,
            r.ManagerRating,
            ROW_NUMBER() OVER (PARTITION BY D.Dept_ID ORDER BY r.ManagerRating DESC) AS Rank
        FROM
            Employee e
            INNER JOIN Department d ON e.Dept_id = D.Dept_ID
            INNER JOIN Review r ON r.EmployeeID = e.Emp_ID
        WHERE
            D.Dept_ID = @dept_id
    )
    SELECT
        Full_Name,
        Department
    FROM
        RankedEmployees
    WHERE
        Rank = 1
)
GO

-- Example usage
SELECT * FROM best_employee_department(1)


--Function --6
--6) What is the average of "yes" and"no" in overtime?
--What is the average of "yes" and"no" in overtime for each job role?

CREATE FUNCTION overtime_average()
RETURNS VARCHAR(100)
AS 
	BEGIN
		DECLARE @yes_count FLOAT, @no_count FLOAT, @count_all FLOAT

		SELECT @yes_count = COUNT(OverTime)
		FROM Employee 
		WHERE OverTime = 'True' AND Attrition = 'False'

		SELECT @no_count = COUNT(OverTime)
		FROM Employee 
		WHERE OverTime = 'False' AND Attrition = 'False'

		SELECT @count_all = COUNT(OverTime)
		FROM Employee

		RETURN
			CONCAT('Average (Yes) in Over Time = ' ,@yes_count/@count_all * 100
					, ' And "No" average in over time = ', @no_count/@count_all * 100)

	END
GO
SELECT dbo.overtime_average()



-------------------------------------------------<< Stored Procedures >>--------------------------------------------


/*1-SP to give annual raise based on overage salary for each job role (annual raise)
if salary < average salaries raise is 15% 
if salary > average salaries raise is 10% 
*/

CREATE PROC GiveAnnualRaise
AS
BEGIN
    WITH cte AS 
    (
        SELECT ae.JobRole, AVG(ae.Salary) AS avg_salary
        FROM ActiveEmployees ae   
        GROUP BY ae.JobRole
    )
    
    UPDATE ae
    SET ae.Salary = 
        CASE 
            WHEN ae.Salary < cte.avg_salary THEN ae.Salary * 1.15
            ELSE ae.Salary * 1.1
        END
    FROM ActiveEmployees ae
    INNER JOIN cte ON ae.JobRole = cte.JobRole
END
GO

-- Execute the stored procedure
EXEC GiveAnnualRaise


--2) Sp to calculate performance for each emp(Excellent-Good-Needs Evaluation)

CREATE PROC GetEmployeePerformance (@Emp_id nvarchar(20))
AS

	DECLARE @manger_rate FLOAT
	DECLARE @Avg_manger_rate FLOAT
	DECLARE @overtime char(10)

	SELECT @Avg_manger_rate = CAST(AVG(r.ManagerRating) AS FLOAT)
	FROM Review r

	SELECT  @manger_rate = CAST(r.ManagerRating AS FLOAT) ,@overtime= e.OverTime 
	FROM ActiveEmployees e INNER JOIN Review r
		ON	e.Emp_ID = r.EmployeeID
	WHERE e.Emp_ID = @Emp_id


	IF @manger_rate > @Avg_manger_rate AND @overtime = 'True' 
		SELECT 'Excellent'
	IF	@manger_rate > @Avg_manger_rate OR @overtime = 'True' 
		SELECT 'Good'
	else select 'Needs Evaluation'
Go
GetEmployeePerformance '001A-8F88'



    
--3) Create a stored procedure responsible for DML Queries for table employee.
--Insert
GO 
CREATE PROC insert_employee(@EmployeeID VARCHAR(100), @FirstName VARCHAR(100)=NULL, 
			@LastName VARCHAR(100)=NULL, @Gender VARCHAR(50)=NULL, @Age INT=NULL, 
			@BusinessTravel VARCHAR(100)=NULL, @DepartmentID INT=NULL, 
			@DistanceFromHome INT=NULL, @State VARCHAR(20)=NULL, @edu_id INT=NULL,
			@JobRole VARCHAR(100)=NULL, @MaritalStatus VARCHAR(50)=NULL, 
			@Salary INT=NULL, @OverTime VARCHAR(20)=NULL, @HireDate DATE=NULL, 
			@Attrition VARCHAR(20)=NULL)
AS
	INSERT INTO Employee
	VALUES(@EmployeeID, @FirstName, @LastName, @Gender, @Age, 
		@BusinessTravel, @DepartmentID, @DistanceFromHome, @State,@edu_id, 
		@JobRole, @MaritalStatus, @Salary, @OverTime, @HireDate, @Attrition)
GO
insert_employee gg5248
GO
insert_employee @EmployeeID=gg5249, @LastName=ahmed
GO
insert_employee @EmployeeID=gg5250, @FirstName=sara, @LastName=ali, @Salary=6000
SELECT *
FROM Employee


--Update Salary
GO
CREATE PROC update_employee_salary(@EmployeeID VARCHAR(100), @Salary INT)
AS
	UPDATE Employee
	SET Salary = @Salary
	WHERE Emp_ID = @EmployeeID

	SELECT CONCAT('You updated the salary of the employee that has an id = ', @EmployeeID, 
	' to be ', @Salary, '$') AS Result
GO
update_employee_salary '001A-8F88', 7500
SELECT *
FROM Employee


--Update DepartmentID

CREATE PROC update_employee_departmentID(@EmployeeID VARCHAR(100), @DepartmentID INT)
AS
	UPDATE Employee
	SET Dept_id = @DepartmentID
	WHERE EXISTS(
			SELECT *
			FROM Department
			WHERE Dept_ID = @DepartmentID)
			AND Emp_ID = @EmployeeID

	SELECT CONCAT('You updated the departmentID of the employee that has an id = ', @EmployeeID, 
	' to be ', @DepartmentID, '.') AS Result
GO
update_employee_departmentID '001A-8F88', 3
SELECT *
FROM Employee



--Delete with EmployeeID
GO
CREATE PROC delete_employee(@EmployeeID VARCHAR(100))
AS
	DELETE FROM Employee
	WHERE Emp_ID = @EmployeeID
GO
delete_employee gg5248
SELECT *
FROM Employee
DROP PROC delete_employee --drop SP


-------------------------------------------------<< Triggers >>--------------------------------------------

--1) Create trigger to raise salary by 10% on updating marital status to 'married'

CREATE TRIGGER MaritalStatusRaise
ON Employee
AFTER UPDATE
AS	
	IF UPDATE(MaritalStatus)
		BEGIN
			IF EXISTS (SELECT * FROM INSERTED WHERE MaritalStatus = 'Married')
				BEGIN
                	UPDATE Employee
						SET Salary = INSERTED.Salary*1.1
						FROM Employee e INNER JOIN INSERTED 
							ON	e.Emp_ID = INSERTED.Emp_ID
						WHERE INSERTED.MaritalStatus = 'Married'
                END
		END


--2) Trigger to welcome new employees and handle error if the employee id already exists in table

CREATE TRIGGER t1
ON Employee
AFTER INSERT
AS
	BEGIN
    	begin try
			declare @emp_id  int, @Name varchar(10)

			SELECT @emp_id = inserted.Emp_ID, @Name = inserted.F_Name FROM inserted;

			if exists (select * from Employee where @emp_id =Emp_ID) 
				begin
					SELECT 5000, 'This employee ID already exists in the table',1
				end
			else select 'Welcome ' + @Name + ' !'
		end try
		begin catch
			Rollback
			select 'Error ' + ERROR_MESSAGE()
		end catch
    END


--3) Trigger that prevents users from dropping any table

CREATE TRIGGER prevent_drop
ON DATABASE
FOR DROP_TABLE
AS
	ROLLBACK 
	SELECT 'You can not drop any table in HR Database'

DROP TABLE Rate


-------------------------------------------------<< Queries >>--------------------------------------------

-- 1- Retrive for each Department its' name , total number of employee , total salary 

SELECT D.Dep_Name ,count(e.Emp_ID) AS No_Emp , SUM(e.Salary) AS Total_Salary
FROM
	Employee e INNER JOIN Department d ON e.Dept_id = d.Dept_ID
GROUP BY D.Dep_Name
ORDER BY Total_Salary DESC


-- 2- Retrive for each Department its' name , MAX SALARY , Average_Salary, Minumum_Salary

SELECT D.Dep_Name ,MAX(e.Salary) AS MAX_SALARY , MIN(e.Salary) AS Min_Salary ,AVG(e.Salary) AS Avg_Salary
FROM
	Employee e INNER JOIN Department d ON e.Dept_id = d.Dept_ID
GROUP BY D.Dep_Name



-- 3- Get the max 2 salaries??? 

SELECT TOP(2) Salary
FROM Employee 
ORDER BY Salary DESC


-- 4- Average of employees' age.

select AVG(Age ) [Average Age for Employee]
from Employee 

-- 5- How many employees age from 25 to 40 and from 40 to 60?

SELECT 
	COUNT(CASE WHEN Age BETWEEN  25 AND 40 THEN 1 END) AS Age_25_to_40,
    Count(CASE WHEN Age > 40 AND Age <= 60 THEN 1 END) AS Age_40_to_60
FROM Employee e

-- 6- Count the number of employees in each department then rank them in ascending order.

SELECT d.Dep_Name, COUNT(*) AS NumberOfEmployees
FROM Employee INNER JOIN Department d ON Employee.Dept_id = d.Dept_ID
GROUP BY d.Dep_Name
ORDER BY NumberOfEmployees ASC;


-- 8- What is the most frequently reviewed month for employees?

SELECT MONTH(ReviewDate) AS review_month , COUNT(PerformanceID) AS no_of_reviews
FROM Review 
GROUP BY MONTH(ReviewDate)
ORDER BY no_of_reviews DESC


--9- What is the job that employees are most satisfied with?

SELECT TOP 1 e.JobRole, COUNT(*) employee_count
FROM Employee e
JOIN Review r
ON r.EmployeeID = e.Emp_ID
WHERE r.JobSatisfaction = 5 AND e.Attrition = 'False'
GROUP BY e.JobRole, r.JobSatisfaction
ORDER BY employee_count DESC

--10- What is the job that employees are least satisfied with?

SELECT TOP 1 e.JobRole, COUNT(*) employee_count
FROM Employee e
JOIN Review r
ON r.EmployeeID = e.Emp_ID
WHERE r.JobSatisfaction = 1 AND e.Attrition = 'False'
GROUP BY e.JobRole, r.JobSatisfaction
ORDER BY employee_count DESC


--11- Who is the best employees in each department (have the same rank)
--	from the manager's point of view? (ManagerRating)

SELECT e.F_Name+' '+e.L_Name AS	Full_Name , d.Dep_Name ,
							ROW_NUMBER() OVER(PARTITION BY d.Dep_Name ORDER BY  Avg(r.ManagerRating) DESC) AS rn_best_average	,	--without duplicates
							DENSE_RANK() OVER(PARTITION BY d.Dep_Name ORDER BY Avg(r.ManagerRating) DESC) AS dr_best_average --with duplicates
FROM Employee e INNER JOIN Department d ON e.Dept_id = d.Dept_ID
	INNER JOIN Review r ON e.Emp_ID = r.EmployeeID
WHERE e.Attrition = 'False'
GROUP BY  d.Dep_Name, e.F_Name+' '+e.L_Name 

--13
/*Know the number of male employees and the number of female employees in the company.  
(in each department)*/

SELECT D.Dep_Name , e.Gender,COUNT(e.Gender) AS gender_count
FROM ActiveEmployees e INNER JOIN Department d ON	e.Dept_id =D.Dept_ID
WHERE  e.Gender = 'Male' OR e.Gender = 'Female'
GROUP BY D.Dep_Name , e.Gender
ORDER BY gender_count DESC


--Query --14
/*How many employees' age is greater than the average of all employees' age?*/

SELECT COUNT(Emp_ID)
FROM Employee 
WHERE Age >(SELECT AVG(Age) FROM Employee ) AND Attrition = 'False'


--Query --15
/*Count Frequency of the three categories of business travel*/

SELECT BusinessTravel,COUNT(emp_id) AS business_travel_frequency 
FROM Employee 
WHERE BusinessTravel IS NOT NULL AND Attrition = 'False'
GROUP BY BusinessTravel 
ORDER BY business_travel_frequency DESC

--Query --16
/*How many employees are more than 35 km away from work? and What is their average age?*/

SELECT COUNT(e.Emp_ID) AS NO_Emp ,AVG(Age) AS Avg_Age
FROM ActiveEmployees e
WHERE e.DistanceFromHome_KM > 35 


--Query --17
/*What is the number of employees in each state and what are their departments?*/

SELECT d.Dep_Name , e.State , count(e.Emp_ID) AS NO_Emp
FROM Employee e INNER JOIN Department d ON e.Dept_id = d.Dept_ID
WHERE e.State IS NOT NULL AND e.Attrition = 'false'
GROUP BY d.Dep_Name , e.State


--Query --18
/*Does the level of education affect the job role or salary?*/
--From the result we fined that level 5 in education affects the salay in a good way

SELECT el.EducationLevel , Avg(e.Salary) AS Avg_salary
FROM Employee e INNER JOIN EducationLevel el ON e.Edu_id = el.Edu_ID
WHERE Attrition = 'false'
GROUP BY el.EducationLevel
ORDER BY Avg_salary DESC

--Query --19
/*How many employees are in each job role?*/

SELECT JobRole, COUNT(Emp_ID) employees_count
FROM Employee
WHERE JobRole IS NOT NULL AND Attrition = 'false'
GROUP BY JobRole
ORDER BY employees_count DESC


--Query --20
/*What is the average salary for each job role?*/

SELECT JobRole, AVG(Salary) average_salary
FROM Employee
WHERE JobRole IS NOT NULL AND Attrition = 'False'
GROUP BY JobRole
ORDER BY AVG(Salary) DESC

--Query --21
/*What is the count of "yes" and"no" in overtime for each job role?*/

SELECT JobRole,OverTime, COUNT(OverTime) yes_OverTime
FROM Employee
WHERE OverTime = 'True' OR OverTime = 'False' AND Attrition = 'False'
GROUP BY JobRole , OverTime
ORDER BY JobRole DESC

--Query --22
/*Does marital status affect the performance of the employee? (use rating)*/
--From the insights we see that marital status doesn't affect the performance

SELECT MaritalStatus, AVG(r.ManagerRating) average_manager_rate
FROM Employee e
JOIN Review r
ON r.EmployeeID = e.Emp_ID
WHERE MaritalStatus IS NOT NULL AND e.Attrition = 'False'
GROUP BY MaritalStatus


--Query --23
/*What is the most and least hiring year?*/
--From the insights we see that 2022 is the most hiring year and 2017 is the least hiring year

SELECT YEAR(HireDate) hiring_year, COUNT(Emp_ID) employee_count
FROM Employee
WHERE YEAR(HireDate) IS NOT NULL
GROUP BY YEAR(HireDate)
ORDER BY employee_count DESC

--Query --24
/*Does gender affect performance?*/
--From the insights we see that gender doesn't affect the performance

SELECT Gender, AVG(r.ManagerRating) average_manager_rate
FROM Employee e
JOIN Review r
ON r.EmployeeID = e.Emp_ID
WHERE Gender IN ('Male', 'Female') AND e.Attrition = 'False'
GROUP BY Gender

--Query --25
/*What is the state which has the best employees?*/
--We see that all states have the same average employees rate, so there is not the best state

SELECT State, AVG(r.ManagerRating) average_manager_rate
FROM Employee e
JOIN Review r
ON r.EmployeeID = e.Emp_ID
WHERE State IS NOT NULL AND e.Attrition = 'False'
GROUP BY State


