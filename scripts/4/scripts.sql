/*
 Найти всех сотрудников, подчиняющихся Ивану Иванову (с EmployeeID = 1), включая их подчиненных и подчиненных подчиненных. Для каждого сотрудника вывести следующую информацию:
 - EmployeeID: идентификатор сотрудника.
 - Имя сотрудника.
 - ManagerID: Идентификатор менеджера.
 - Название отдела, к которому он принадлежит.
 - Название роли, которую он занимает.
 - Название проектов, к которым он относится (если есть, конкатенированные в одном столбце через запятую).
 - Название задач, назначенных этому сотруднику (если есть, конкатенированные в одном столбце через запятую).
 - Если у сотрудника нет назначенных проектов или задач, отобразить NULL.
 */
--  Находим нужных сотрудников
WITH RECURSIVE reporters AS (
    SELECT employeeid, managerid
    FROM employees
    WHERE employeeid = 1
    UNION ALL
    SELECT e.employeeid, e.managerid
    FROM employees e
    INNER JOIN reporters r
        ON e.managerid = r.employeeid
),
-- Собираем проекты
projects_agg AS (
    SELECT
        p.departmentid,
        STRING_AGG(DISTINCT p.projectname, ', ') AS names
    FROM projects p
    GROUP BY p.departmentid
),
-- Собираем задачи
tasks_agg AS (
   SELECT
       t.assignedto as employeeid,
       STRING_AGG(DISTINCT t.taskname, ', ') AS names
   FROM tasks t
   GROUP BY t.assignedto
)
SELECT
    e.employeeid as EmployeeID,
    e.name as EmployeeName,
    e.managerid as ManagerID,
    d.departmentname as DepartmentName,
    roles.rolename as RoleName,
    p.names as ProjectNames,
    t.names as TaskNames
FROM reporters r
LEFT JOIN employees e USING (employeeid)
LEFT JOIN roles USING (roleid)
LEFT JOIN departments d USING (departmentid)
LEFT JOIN tasks_agg t USING (employeeid)
LEFT JOIN projects_agg p USING (departmentid)
ORDER BY EmployeeName;

/*
 Найти всех сотрудников, подчиняющихся Ивану Иванову с EmployeeID = 1, включая их подчиненных и подчиненных подчиненных. Для каждого сотрудника вывести следующую информацию:
 - EmployeeID: идентификатор сотрудника.
 - Имя сотрудника.
 - Идентификатор менеджера.
 - Название отдела, к которому он принадлежит.
 - Название роли, которую он занимает.
 - Название проектов, к которым он относится (если есть, конкатенированные в одном столбце).
 - Название задач, назначенных этому сотруднику (если есть, конкатенированные в одном столбце).
 - Общее количество задач, назначенных этому сотруднику.
 - Общее количество подчиненных у каждого сотрудника (не включая подчиненных их подчиненных).
 - Если у сотрудника нет назначенных проектов или задач, отобразить NULL.
 */
--  Дополним прошлый запрос
--  Находим нужных сотрудников
WITH RECURSIVE reporters AS (
    SELECT employeeid, managerid
    FROM employees
    WHERE employeeid = 1
    UNION ALL
    SELECT e.employeeid, e.managerid
    FROM employees e
    INNER JOIN reporters r ON e.managerid = r.employeeid
),
-- Подсчитываем подчиненных
reports_count AS (
    SELECT
        r.managerid as employeeid,
        COUNT(*) as count
    FROM reporters r
    GROUP BY r.managerid
),
-- Собираем проекты
projects_agg AS (
   SELECT
       p.departmentid,
       STRING_AGG(DISTINCT p.projectname, ', ') AS names
   FROM projects p
   GROUP BY p.departmentid
),
-- Собираем задачи
tasks_agg AS (
   SELECT
       t.assignedto as employeeid,
       STRING_AGG(DISTINCT t.taskname, ', ') AS names,
       COUNT(*) AS count
   FROM tasks t
   GROUP BY t.assignedto
)
SELECT
    e.employeeid as EmployeeID,
    e.name as EmployeeName,
    e.managerid as ManagerID,
    d.departmentname as DepartmentName,
    roles.rolename as RoleName,
    p.names as ProjectNames,
    t.names as TaskNames,
    COALESCE(t.count, 0) as TotalTasks,
    COALESCE(rc.count, 0) as TotalSubordinates
FROM reporters r
LEFT JOIN employees e USING (employeeid)
LEFT JOIN roles USING (roleid)
LEFT JOIN departments d USING (departmentid)
LEFT JOIN tasks_agg t USING (employeeid)
LEFT JOIN projects_agg p USING (departmentid)
LEFT JOIN reports_count rc USING (employeeid)
ORDER BY EmployeeName;

/*
 Найти всех сотрудников, которые занимают роль менеджера и имеют подчиненных (то есть число подчиненных больше 0). Для каждого такого сотрудника вывести следующую информацию:
 - EmployeeID: идентификатор сотрудника.
 - Имя сотрудника.
 - Идентификатор менеджера.
 - Название отдела, к которому он принадлежит.
 - Название роли, которую он занимает.
 - Название проектов, к которым он относится (если есть, конкатенированные в одном столбце).
 - Название задач, назначенных этому сотруднику (если есть, конкатенированные в одном столбце).
 - Общее количество подчиненных у каждого сотрудника (включая их подчиненных).
 - Если у сотрудника нет назначенных проектов или задач, отобразить NULL.
 */
--  Опять дополним прошлый запрос
WITH RECURSIVE reporters AS (
    SELECT employeeid, managerid
    FROM employees
    WHERE employeeid = 1
    UNION ALL
    SELECT e.employeeid, e.managerid
    FROM employees e
    INNER JOIN reporters r ON e.managerid = r.employeeid
),
-- Подсчитываем подчиненных
reports_count AS (
   SELECT
       r.managerid as employeeid,
       COUNT(*) as count
   FROM reporters r
   GROUP BY r.managerid
),
-- Собираем проекты
projects_agg AS (
   SELECT
       p.departmentid,
       STRING_AGG(DISTINCT p.projectname, ', ') AS names
   FROM projects p
   GROUP BY p.departmentid
),
-- Собираем задачи
tasks_agg AS (
   SELECT
       t.assignedto as employeeid,
       STRING_AGG(DISTINCT t.taskname, ', ') AS names
   FROM tasks t
   GROUP BY t.assignedto
)
SELECT
    e.employeeid as EmployeeID,
    e.name as EmployeeName,
    e.managerid as ManagerID,
    d.departmentname as DepartmentName,
    roles.rolename as RoleName,
    p.names as ProjectNames,
    t.names as TaskNames,
    COALESCE(rc.count, 0) as TotalSubordinates
FROM reporters r
         LEFT JOIN employees e USING (employeeid)
         LEFT JOIN roles USING (roleid)
         LEFT JOIN departments d USING (departmentid)
         LEFT JOIN tasks_agg t USING (employeeid)
         LEFT JOIN projects_agg p USING (departmentid)
         LEFT JOIN reports_count rc USING (employeeid)
WHERE roles.rolename = 'Менеджер' AND rc.count > 0
ORDER BY EmployeeName;