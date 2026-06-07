--==============================================================================
-- ESQUEMA HR (Human Resources) - VERSION ADAPTADA PARA ORACLE APEX FREE WORKSPACE
-- Asignatura: Bases de Datos Avanzadas (UNIR) - Tema 8
-- Autor: Tatiana Betancur
-- Fecha: 2026-06-07
--
-- Como APEX free workspace NO trae el esquema HR preinstalado, este script lo
-- crea desde cero dentro de TU schema personal con la misma estructura y datos
-- representativos del HR estandar de Oracle.
--
-- USO: copiar y pegar TODO el contenido en "SQL Workshop > SQL Commands" y
--      ejecutar con el boton "Run". Confirma que se crearon 7 tablas y los
--      registros pedidos.
--==============================================================================

-- Limpieza previa (idempotente: ignora errores si las tablas aun no existen)
BEGIN
  FOR t IN (SELECT table_name FROM user_tables
            WHERE table_name IN ('JOB_HISTORY','EMPLOYEES','JOBS','DEPARTMENTS','LOCATIONS','COUNTRIES','REGIONS','DEPARTMENTS2'))
  LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS PURGE';
  END LOOP;
END;
/

-- =============================================================================
-- 1. REGIONS
-- =============================================================================
CREATE TABLE regions (
    region_id    NUMBER       CONSTRAINT reg_id_nn NOT NULL,
    region_name  VARCHAR2(25)
);
ALTER TABLE regions ADD CONSTRAINT reg_id_pk PRIMARY KEY (region_id);

INSERT INTO regions VALUES (1,'Europe');
INSERT INTO regions VALUES (2,'Americas');
INSERT INTO regions VALUES (3,'Asia');
INSERT INTO regions VALUES (4,'Middle East and Africa');

-- =============================================================================
-- 2. COUNTRIES
-- =============================================================================
CREATE TABLE countries (
    country_id    CHAR(2)       CONSTRAINT country_id_nn NOT NULL,
    country_name  VARCHAR2(40),
    region_id     NUMBER,
    CONSTRAINT country_c_id_pk PRIMARY KEY (country_id)
);
ALTER TABLE countries ADD CONSTRAINT countr_reg_fk
   FOREIGN KEY (region_id) REFERENCES regions(region_id);

INSERT INTO countries VALUES ('AR','Argentina',2);
INSERT INTO countries VALUES ('AU','Australia',3);
INSERT INTO countries VALUES ('BE','Belgium',1);
INSERT INTO countries VALUES ('BR','Brazil',2);
INSERT INTO countries VALUES ('CA','Canada',2);
INSERT INTO countries VALUES ('CH','Switzerland',1);
INSERT INTO countries VALUES ('CN','China',3);
INSERT INTO countries VALUES ('DE','Germany',1);
INSERT INTO countries VALUES ('DK','Denmark',1);
INSERT INTO countries VALUES ('EG','Egypt',4);
INSERT INTO countries VALUES ('FR','France',1);
INSERT INTO countries VALUES ('IL','Israel',4);
INSERT INTO countries VALUES ('IN','India',3);
INSERT INTO countries VALUES ('IT','Italy',1);
INSERT INTO countries VALUES ('JP','Japan',3);
INSERT INTO countries VALUES ('KW','Kuwait',4);
INSERT INTO countries VALUES ('ML','Malaysia',3);
INSERT INTO countries VALUES ('MX','Mexico',2);
INSERT INTO countries VALUES ('NG','Nigeria',4);
INSERT INTO countries VALUES ('NL','Netherlands',1);
INSERT INTO countries VALUES ('SG','Singapore',3);
INSERT INTO countries VALUES ('UK','United Kingdom',1);
INSERT INTO countries VALUES ('US','United States of America',2);
INSERT INTO countries VALUES ('ZM','Zambia',4);
INSERT INTO countries VALUES ('ZW','Zimbabwe',4);

-- =============================================================================
-- 3. LOCATIONS
-- =============================================================================
CREATE TABLE locations (
    location_id     NUMBER(4),
    street_address  VARCHAR2(40),
    postal_code     VARCHAR2(12),
    city            VARCHAR2(30) CONSTRAINT loc_city_nn NOT NULL,
    state_province  VARCHAR2(25),
    country_id      CHAR(2)
);
ALTER TABLE locations ADD CONSTRAINT loc_id_pk PRIMARY KEY (location_id);
ALTER TABLE locations ADD CONSTRAINT loc_c_id_fk
   FOREIGN KEY (country_id) REFERENCES countries(country_id);

INSERT INTO locations VALUES (1000,'1297 Via Cola di Rie','00989','Roma',NULL,'IT');
INSERT INTO locations VALUES (1100,'93091 Calle della Testa','10934','Venice',NULL,'IT');
INSERT INTO locations VALUES (1200,'2017 Shinjuku-ku','1689','Tokyo','Tokyo Prefecture','JP');
INSERT INTO locations VALUES (1300,'9450 Kamiya-cho','6823','Hiroshima',NULL,'JP');
INSERT INTO locations VALUES (1400,'2014 Jabberwocky Rd','26192','Southlake','Texas','US');
INSERT INTO locations VALUES (1500,'2011 Interiors Blvd','99236','South San Francisco','California','US');
INSERT INTO locations VALUES (1600,'2007 Zagora St','50090','South Brunswick','New Jersey','US');
INSERT INTO locations VALUES (1700,'2004 Charade Rd','98199','Seattle','Washington','US');
INSERT INTO locations VALUES (1800,'147 Spadina Ave','M5V 2L7','Toronto','Ontario','CA');
INSERT INTO locations VALUES (1900,'6092 Boxwood St','YSW 9T2','Whitehorse','Yukon','CA');
INSERT INTO locations VALUES (2000,'40-5-12 Laogianggen','190518','Beijing',NULL,'CN');
INSERT INTO locations VALUES (2100,'1298 Vileparle (E)','490231','Bombay','Maharashtra','IN');
INSERT INTO locations VALUES (2200,'12-98 Victoria Street','2901','Sydney','New South Wales','AU');
INSERT INTO locations VALUES (2300,'198 Clementi North','540198','Singapore',NULL,'SG');
INSERT INTO locations VALUES (2400,'8204 Arthur St',NULL,'London',NULL,'UK');
INSERT INTO locations VALUES (2500,'Magdalen Centre, The Oxford Science Park','OX9 9ZB','Oxford','Oxford','UK');
INSERT INTO locations VALUES (2600,'9702 Chester Road','09629850293','Stretford','Manchester','UK');
INSERT INTO locations VALUES (2700,'Schwanthalerstr. 7031','80925','Munich','Bavaria','DE');
INSERT INTO locations VALUES (2800,'Rua Frei Caneca 1360','01307-002','Sao Paulo','Sao Paulo','BR');
INSERT INTO locations VALUES (2900,'20 Rue des Corps-Saints','1730','Geneva','Geneve','CH');
INSERT INTO locations VALUES (3000,'Murtenstrasse 921','3095','Bern','BE','CH');
INSERT INTO locations VALUES (3100,'Pieter Breughelstraat 837','3029SK','Utrecht','Utrecht','NL');
INSERT INTO locations VALUES (3200,'Mariano Escobedo 9991','11932','Mexico City','Distrito Federal,','MX');

-- =============================================================================
-- 4. JOBS
-- =============================================================================
CREATE TABLE jobs (
    job_id      VARCHAR2(10),
    job_title   VARCHAR2(35) CONSTRAINT job_title_nn NOT NULL,
    min_salary  NUMBER(6),
    max_salary  NUMBER(6)
);
ALTER TABLE jobs ADD CONSTRAINT job_id_pk PRIMARY KEY (job_id);

INSERT INTO jobs VALUES ('AD_PRES','President',20080,40000);
INSERT INTO jobs VALUES ('AD_VP','Administration Vice President',15000,30000);
INSERT INTO jobs VALUES ('AD_ASST','Administration Assistant',3000,6000);
INSERT INTO jobs VALUES ('FI_MGR','Finance Manager',8200,16000);
INSERT INTO jobs VALUES ('FI_ACCOUNT','Accountant',4200,9000);
INSERT INTO jobs VALUES ('AC_MGR','Accounting Manager',8200,16000);
INSERT INTO jobs VALUES ('AC_ACCOUNT','Public Accountant',4200,9000);
INSERT INTO jobs VALUES ('SA_MAN','Sales Manager',10000,20080);
INSERT INTO jobs VALUES ('SA_REP','Sales Representative',6000,12008);
INSERT INTO jobs VALUES ('PU_MAN','Purchasing Manager',8000,15000);
INSERT INTO jobs VALUES ('PU_CLERK','Purchasing Clerk',2500,5500);
INSERT INTO jobs VALUES ('ST_MAN','Stock Manager',5500,8500);
INSERT INTO jobs VALUES ('ST_CLERK','Stock Clerk',2008,5000);
INSERT INTO jobs VALUES ('SH_CLERK','Shipping Clerk',2500,5500);
INSERT INTO jobs VALUES ('IT_PROG','Programmer',4000,10000);
INSERT INTO jobs VALUES ('MK_MAN','Marketing Manager',9000,15000);
INSERT INTO jobs VALUES ('MK_REP','Marketing Representative',4000,9000);
INSERT INTO jobs VALUES ('HR_REP','Human Resources Representative',4000,9000);
INSERT INTO jobs VALUES ('PR_REP','Public Relations Representative',4500,10500);

-- =============================================================================
-- 5. DEPARTMENTS  (sin la FK a EMPLOYEES por ahora; se anade despues)
-- =============================================================================
CREATE TABLE departments (
    department_id    NUMBER(4),
    department_name  VARCHAR2(30) CONSTRAINT dept_name_nn NOT NULL,
    manager_id       NUMBER(6),
    location_id      NUMBER(4)
);
ALTER TABLE departments ADD CONSTRAINT dept_id_pk PRIMARY KEY (department_id);
ALTER TABLE departments ADD CONSTRAINT dept_loc_fk
   FOREIGN KEY (location_id) REFERENCES locations(location_id);

INSERT INTO departments VALUES (10,'Administration',200,1700);
INSERT INTO departments VALUES (20,'Marketing',201,1800);
INSERT INTO departments VALUES (30,'Purchasing',114,1700);
INSERT INTO departments VALUES (40,'Human Resources',203,2400);
INSERT INTO departments VALUES (50,'Shipping',121,1500);
INSERT INTO departments VALUES (60,'IT',103,1400);
INSERT INTO departments VALUES (70,'Public Relations',204,2700);
INSERT INTO departments VALUES (80,'Sales',145,2500);
INSERT INTO departments VALUES (90,'Executive',100,1700);
INSERT INTO departments VALUES (100,'Finance',108,1700);
INSERT INTO departments VALUES (110,'Accounting',205,1700);
INSERT INTO departments VALUES (120,'Treasury',NULL,1700);
INSERT INTO departments VALUES (130,'Corporate Tax',NULL,1700);
INSERT INTO departments VALUES (140,'Control And Credit',NULL,1700);
INSERT INTO departments VALUES (150,'Shareholder Services',NULL,1700);
INSERT INTO departments VALUES (160,'Benefits',NULL,1700);
INSERT INTO departments VALUES (170,'Manufacturing',NULL,1700);
INSERT INTO departments VALUES (180,'Construction',NULL,1700);
INSERT INTO departments VALUES (190,'Contracting',NULL,1700);
INSERT INTO departments VALUES (200,'Operations',NULL,1700);
INSERT INTO departments VALUES (210,'IT Support',NULL,1700);
INSERT INTO departments VALUES (220,'NOC',NULL,1700);
INSERT INTO departments VALUES (230,'IT Helpdesk',NULL,1700);
INSERT INTO departments VALUES (240,'Government Sales',NULL,1700);
INSERT INTO departments VALUES (250,'Retail Sales',NULL,1700);
INSERT INTO departments VALUES (260,'Recruiting',NULL,1700);
INSERT INTO departments VALUES (270,'Payroll',NULL,1700);

-- =============================================================================
-- 6. EMPLOYEES
-- =============================================================================
CREATE TABLE employees (
    employee_id     NUMBER(6),
    first_name      VARCHAR2(20),
    last_name       VARCHAR2(25) CONSTRAINT emp_last_name_nn NOT NULL,
    email           VARCHAR2(25) CONSTRAINT emp_email_nn NOT NULL,
    phone_number    VARCHAR2(20),
    hire_date       DATE         CONSTRAINT emp_hire_date_nn NOT NULL,
    job_id          VARCHAR2(10) CONSTRAINT emp_job_nn NOT NULL,
    salary          NUMBER(8,2),
    commission_pct  NUMBER(2,2),
    manager_id      NUMBER(6),
    department_id   NUMBER(4)
);
ALTER TABLE employees ADD CONSTRAINT emp_emp_id_pk PRIMARY KEY (employee_id);
ALTER TABLE employees ADD CONSTRAINT emp_email_uk  UNIQUE (email);
ALTER TABLE employees ADD CONSTRAINT emp_salary_min CHECK (salary > 0);
ALTER TABLE employees ADD CONSTRAINT emp_dept_fk
   FOREIGN KEY (department_id) REFERENCES departments(department_id);
ALTER TABLE employees ADD CONSTRAINT emp_job_fk
   FOREIGN KEY (job_id) REFERENCES jobs(job_id);
ALTER TABLE employees ADD CONSTRAINT emp_manager_fk
   FOREIGN KEY (manager_id) REFERENCES employees(employee_id);

-- Carga de empleados (subset representativo del HR estandar)
INSERT INTO employees VALUES (100,'Steven','King','SKING','515.123.4567',DATE '2003-06-17','AD_PRES',24000,NULL,NULL,90);
INSERT INTO employees VALUES (101,'Neena','Kochhar','NKOCHHAR','515.123.4568',DATE '2005-09-21','AD_VP',17000,NULL,100,90);
INSERT INTO employees VALUES (102,'Lex','De Haan','LDEHAAN','515.123.4569',DATE '2001-01-13','AD_VP',17000,NULL,100,90);
INSERT INTO employees VALUES (103,'Alexander','Hunold','AHUNOLD','590.423.4567',DATE '2006-01-03','IT_PROG',9000,NULL,102,60);
INSERT INTO employees VALUES (104,'Bruce','Ernst','BERNST','590.423.4568',DATE '2007-05-21','IT_PROG',6000,NULL,103,60);
INSERT INTO employees VALUES (105,'David','Austin','DAUSTIN','590.423.4569',DATE '2005-06-25','IT_PROG',4800,NULL,103,60);
INSERT INTO employees VALUES (106,'Valli','Pataballa','VPATABAL','590.423.4560',DATE '2006-02-05','IT_PROG',4800,NULL,103,60);
INSERT INTO employees VALUES (107,'Diana','Lorentz','DLORENTZ','590.423.5567',DATE '2007-02-07','IT_PROG',4200,NULL,103,60);
INSERT INTO employees VALUES (108,'Nancy','Greenberg','NGREENBE','515.124.4569',DATE '2002-08-17','FI_MGR',12008,NULL,101,100);
INSERT INTO employees VALUES (109,'Daniel','Faviet','DFAVIET','515.124.4169',DATE '2002-08-16','FI_ACCOUNT',9000,NULL,108,100);
INSERT INTO employees VALUES (110,'John','Chen','JCHEN','515.124.4269',DATE '2005-09-28','FI_ACCOUNT',8200,NULL,108,100);
INSERT INTO employees VALUES (111,'Ismael','Sciarra','ISCIARRA','515.124.4369',DATE '2005-09-30','FI_ACCOUNT',7700,NULL,108,100);
INSERT INTO employees VALUES (112,'Jose Manuel','Urman','JMURMAN','515.124.4469',DATE '2006-03-07','FI_ACCOUNT',7800,NULL,108,100);
INSERT INTO employees VALUES (113,'Luis','Popp','LPOPP','515.124.4567',DATE '2007-12-07','FI_ACCOUNT',6900,NULL,108,100);
INSERT INTO employees VALUES (114,'Den','Raphaely','DRAPHEAL','515.127.4561',DATE '2002-12-07','PU_MAN',11000,NULL,100,30);
INSERT INTO employees VALUES (115,'Alexander','Khoo','AKHOO','515.127.4562',DATE '2003-05-18','PU_CLERK',3100,NULL,114,30);
INSERT INTO employees VALUES (116,'Shelli','Baida','SBAIDA','515.127.4563',DATE '2005-12-24','PU_CLERK',2900,NULL,114,30);
INSERT INTO employees VALUES (117,'Sigal','Tobias','STOBIAS','515.127.4564',DATE '2005-07-24','PU_CLERK',2800,NULL,114,30);
INSERT INTO employees VALUES (118,'Guy','Himuro','GHIMURO','515.127.4565',DATE '2006-11-15','PU_CLERK',2600,NULL,114,30);
INSERT INTO employees VALUES (119,'Karen','Colmenares','KCOLMENA','515.127.4566',DATE '2007-08-10','PU_CLERK',2500,NULL,114,30);
INSERT INTO employees VALUES (120,'Matthew','Weiss','MWEISS','650.123.1234',DATE '2004-07-18','ST_MAN',8000,NULL,100,50);
INSERT INTO employees VALUES (121,'Adam','Fripp','AFRIPP','650.123.2234',DATE '2005-04-10','ST_MAN',8200,NULL,100,50);
INSERT INTO employees VALUES (122,'Payam','Kaufling','PKAUFLIN','650.123.3234',DATE '2003-05-01','ST_MAN',7900,NULL,100,50);
INSERT INTO employees VALUES (123,'Shanta','Vollman','SVOLLMAN','650.123.4234',DATE '2005-10-10','ST_MAN',6500,NULL,100,50);
INSERT INTO employees VALUES (124,'Kevin','Mourgos','KMOURGOS','650.123.5234',DATE '2007-11-16','ST_MAN',5800,NULL,100,50);
INSERT INTO employees VALUES (145,'John','Russell','JRUSSEL','011.44.1344.429268',DATE '2004-10-01','SA_MAN',14000,0.4,100,80);
INSERT INTO employees VALUES (146,'Karen','Partners','KPARTNER','011.44.1344.467268',DATE '2005-01-05','SA_MAN',13500,0.3,100,80);
INSERT INTO employees VALUES (200,'Jennifer','Whalen','JWHALEN','515.123.4444',DATE '2003-09-17','AD_ASST',4400,NULL,101,10);
INSERT INTO employees VALUES (201,'Michael','Hartstein','MHARTSTE','515.123.5555',DATE '2004-02-17','MK_MAN',13000,NULL,100,20);
INSERT INTO employees VALUES (202,'Pat','Fay','PFAY','603.123.6666',DATE '2005-08-17','MK_REP',6000,NULL,201,20);
INSERT INTO employees VALUES (203,'Susan','Mavris','SMAVRIS','515.123.7777',DATE '2002-06-07','HR_REP',6500,NULL,101,40);
INSERT INTO employees VALUES (204,'Hermann','Baer','HBAER','515.123.8888',DATE '2002-06-07','PR_REP',10000,NULL,101,70);
INSERT INTO employees VALUES (205,'Shelley','Higgins','SHIGGINS','515.123.8080',DATE '2002-06-07','AC_MGR',12008,NULL,101,110);
INSERT INTO employees VALUES (206,'William','Gietz','WGIETZ','515.123.8181',DATE '2002-06-07','AC_ACCOUNT',8300,NULL,205,110);

COMMIT;

-- Cierre del ciclo: FK de DEPARTMENTS.manager_id -> EMPLOYEES.employee_id
ALTER TABLE departments ADD CONSTRAINT dept_mgr_fk
   FOREIGN KEY (manager_id) REFERENCES employees(employee_id);

-- =============================================================================
-- 7. JOB_HISTORY
-- =============================================================================
CREATE TABLE job_history (
    employee_id  NUMBER(6)   CONSTRAINT jhist_employee_nn NOT NULL,
    start_date   DATE        CONSTRAINT jhist_start_date_nn NOT NULL,
    end_date     DATE        CONSTRAINT jhist_end_date_nn NOT NULL,
    job_id       VARCHAR2(10) CONSTRAINT jhist_job_nn NOT NULL,
    department_id NUMBER(4)
);
ALTER TABLE job_history ADD CONSTRAINT jhist_emp_id_st_date_pk PRIMARY KEY (employee_id, start_date);
ALTER TABLE job_history ADD CONSTRAINT jhist_date_interval CHECK (end_date > start_date);
ALTER TABLE job_history ADD CONSTRAINT jhist_job_fk
   FOREIGN KEY (job_id) REFERENCES jobs(job_id);
ALTER TABLE job_history ADD CONSTRAINT jhist_emp_fk
   FOREIGN KEY (employee_id) REFERENCES employees(employee_id);
ALTER TABLE job_history ADD CONSTRAINT jhist_dept_fk
   FOREIGN KEY (department_id) REFERENCES departments(department_id);

INSERT INTO job_history VALUES (102,DATE '2001-01-13',DATE '2006-07-24','IT_PROG',60);
INSERT INTO job_history VALUES (101,DATE '1997-09-21',DATE '2001-10-27','AC_ACCOUNT',110);
INSERT INTO job_history VALUES (101,DATE '2001-10-28',DATE '2005-03-15','AC_MGR',110);
INSERT INTO job_history VALUES (201,DATE '2004-02-17',DATE '2007-12-19','MK_REP',20);
INSERT INTO job_history VALUES (114,DATE '2006-03-24',DATE '2007-12-31','ST_CLERK',50);
INSERT INTO job_history VALUES (122,DATE '2007-01-01',DATE '2007-12-31','ST_CLERK',50);
INSERT INTO job_history VALUES (200,DATE '1995-09-17',DATE '2001-06-17','AD_ASST',90);
INSERT INTO job_history VALUES (176,DATE '2006-03-24',DATE '2006-12-31','SA_REP',80);
INSERT INTO job_history VALUES (176,DATE '2007-01-01',DATE '2007-12-31','SA_MAN',80);
INSERT INTO job_history VALUES (200,DATE '2002-07-01',DATE '2006-12-31','AC_ACCOUNT',90);

COMMIT;

-- =============================================================================
-- INDICES SECUNDARIOS (replicando los del HR estandar)
-- =============================================================================
CREATE INDEX emp_department_ix ON employees (department_id);
CREATE INDEX emp_job_ix        ON employees (job_id);
CREATE INDEX emp_manager_ix    ON employees (manager_id);
CREATE INDEX emp_name_ix       ON employees (last_name, first_name);
CREATE INDEX dept_location_ix  ON departments (location_id);
CREATE INDEX loc_city_ix       ON locations (city);
CREATE INDEX loc_state_province_ix ON locations (state_province);
CREATE INDEX loc_country_ix    ON locations (country_id);
CREATE INDEX jhist_job_ix      ON job_history (job_id);
CREATE INDEX jhist_employee_ix ON job_history (employee_id);
CREATE INDEX jhist_department_ix ON job_history (department_id);

-- =============================================================================
-- VERIFICACION FINAL
-- =============================================================================
SELECT table_name, num_rows FROM user_tables WHERE table_name IN
  ('REGIONS','COUNTRIES','LOCATIONS','JOBS','DEPARTMENTS','EMPLOYEES','JOB_HISTORY')
ORDER BY table_name;

SELECT 'REGIONS'     AS tabla, COUNT(*) AS filas FROM regions     UNION ALL
SELECT 'COUNTRIES'   , COUNT(*) FROM countries UNION ALL
SELECT 'LOCATIONS'   , COUNT(*) FROM locations UNION ALL
SELECT 'JOBS'        , COUNT(*) FROM jobs       UNION ALL
SELECT 'DEPARTMENTS' , COUNT(*) FROM departments UNION ALL
SELECT 'EMPLOYEES'   , COUNT(*) FROM employees  UNION ALL
SELECT 'JOB_HISTORY' , COUNT(*) FROM job_history;

-- Esperado aproximado: regions=4, countries=25, locations=23, jobs=19,
-- departments=27, employees=34 (subset), job_history=10
