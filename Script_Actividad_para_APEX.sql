--==============================================================================
-- Trabajo: Indices y restricciones en Oracle - Esquema HR
-- VERSION ADAPTADA PARA ORACLE APEX FREE WORKSPACE
-- Asignatura: Bases de Datos Avanzadas (UNIR) - Tema 8
-- Autor:  Tatiana Betancur
-- Fecha:  2026-06-07
--
-- ENTORNO DE EJECUCION:
--   Oracle Cloud APEX Free Workspace (apex.oracle.com)
--   Modulo: SQL Workshop > SQL Scripts (para cargar y ejecutar de extremo a extremo)
--           o SQL Workshop > SQL Commands (para ejecutar bloques individuales)
--
-- PREREQUISITO: ejecutar primero "Script_HR_para_APEX.sql" para crear las tablas.
--
-- LIMITACIONES DEL ENTORNO RESPECTO AL ENUNCIADO ORIGINAL (justificadas en
-- la memoria APA, Entregable 2, seccion "Decision de entorno"):
--   * No se puede usar SET TIMING ON; SET AUTOTRACE ON: solo aplican en SQL*Plus
--     y SQL Developer; APEX usa otro motor de ejecucion.
--   * No se puede consultar V$LOG, V$LOGFILE, V$DATABASE: en Autonomous y APEX
--     compartido, Oracle restringe el acceso a vistas dinamicas de la instancia.
--   * No se puede usar ALTER SYSTEM SWITCH LOGFILE ni cambiar modo ARCHIVELOG.
--   * Punto 12 del enunciado queda como respuesta TEORICA, sin captura ejecutiva.
--==============================================================================


-- =============================================================================
-- 0. VERIFICACION DE QUE EL ESQUEMA HR ESTA CARGADO
-- =============================================================================
SELECT USER AS usuario_actual FROM dual;

SELECT table_name
FROM   user_tables
WHERE  table_name IN ('REGIONS','COUNTRIES','LOCATIONS','JOBS',
                      'DEPARTMENTS','EMPLOYEES','JOB_HISTORY')
ORDER BY table_name;
-- Esperado: 7 filas. Si faltan, ejecutar Script_HR_para_APEX.sql primero.


-- =============================================================================
-- 1. CONSULTA DE INDICES SOBRE employees Y departments
-- =============================================================================

-- 1.1 Indices y su estado
SELECT index_name,
       table_name,
       uniqueness,
       index_type,
       status
FROM   user_indexes
WHERE  table_name IN ('EMPLOYEES','DEPARTMENTS')
ORDER BY table_name, index_name;

-- 1.2 Columnas de cada indice (orden importa, sobre todo en compuestos)
SELECT ic.table_name,
       ic.index_name,
       ic.column_position,
       ic.column_name,
       ic.descend
FROM   user_ind_columns ic
WHERE  ic.table_name IN ('EMPLOYEES','DEPARTMENTS')
ORDER BY ic.table_name, ic.index_name, ic.column_position;

-- 1.3 Relacion indice <-> restriccion (PK/UNIQUE generan indice automatico)
SELECT c.table_name,
       c.constraint_name,
       c.constraint_type,
       c.index_name
FROM   user_constraints c
WHERE  c.table_name IN ('EMPLOYEES','DEPARTMENTS')
  AND  c.constraint_type IN ('P','U')
ORDER BY c.table_name, c.constraint_type;


-- =============================================================================
-- 2. CONSULTA DE RESTRICCIONES
-- =============================================================================

SELECT table_name,
       constraint_name,
       constraint_type,        -- P=PK, U=UNIQUE, R=FK, C=Check/NOT NULL
       search_condition,
       r_constraint_name,
       delete_rule,
       status,
       deferrable,
       validated
FROM   user_constraints
WHERE  table_name IN ('EMPLOYEES','DEPARTMENTS')
ORDER BY table_name, constraint_type, constraint_name;

SELECT cc.table_name,
       cc.constraint_name,
       cc.column_name,
       cc.position
FROM   user_cons_columns cc
WHERE  cc.table_name IN ('EMPLOYEES','DEPARTMENTS')
ORDER BY cc.table_name, cc.constraint_name, cc.position;


-- =============================================================================
-- 3. DESACTIVACION DE RESTRICCIONES
--    Orden: FK hijas primero, luego PK; NOT NULL via MODIFY.
-- =============================================================================

-- 3.1 Tablas hijas que apuntan a EMPLOYEES o DEPARTMENTS
SELECT  fk.table_name        AS tabla_hija,
        fk.constraint_name   AS fk_nombre,
        pk.table_name        AS tabla_padre,
        pk.constraint_name   AS pk_nombre
FROM    user_constraints fk
JOIN    user_constraints pk ON pk.constraint_name = fk.r_constraint_name
WHERE   fk.constraint_type = 'R'
  AND   pk.table_name IN ('EMPLOYEES','DEPARTMENTS')
ORDER BY tabla_padre, tabla_hija;

-- 3.2 Desactivar FKs en hijas que apuntan a EMPLOYEES
ALTER TABLE departments DISABLE CONSTRAINT dept_mgr_fk;
ALTER TABLE job_history DISABLE CONSTRAINT jhist_emp_fk;

-- 3.3 Desactivar FKs en hijas que apuntan a DEPARTMENTS
ALTER TABLE employees   DISABLE CONSTRAINT emp_dept_fk;
ALTER TABLE job_history DISABLE CONSTRAINT jhist_dept_fk;

-- 3.4 Desactivar FKs propias de EMPLOYEES
ALTER TABLE employees DISABLE CONSTRAINT emp_manager_fk;
ALTER TABLE employees DISABLE CONSTRAINT emp_job_fk;

-- 3.5 Desactivar FK propia de DEPARTMENTS
ALTER TABLE departments DISABLE CONSTRAINT dept_loc_fk;

-- 3.6 Desactivar PRIMARY KEYs (con CASCADE por seguridad)
ALTER TABLE employees   DISABLE CONSTRAINT emp_emp_id_pk      CASCADE;
ALTER TABLE departments DISABLE CONSTRAINT dept_id_pk          CASCADE;

-- 3.7 Desactivar UNIQUE de EMPLOYEES (email)
ALTER TABLE employees DISABLE CONSTRAINT emp_email_uk;

-- 3.8 Desactivar CHECK de EMPLOYEES (salary > 0)
ALTER TABLE employees DISABLE CONSTRAINT emp_salary_min;

-- 3.9 NOT NULL: no admite DISABLE CONSTRAINT; se usa MODIFY ... NULL.
ALTER TABLE employees   MODIFY (last_name      NULL);
ALTER TABLE employees   MODIFY (email          NULL);
ALTER TABLE employees   MODIFY (hire_date      NULL);
ALTER TABLE employees   MODIFY (job_id         NULL);
ALTER TABLE departments MODIFY (department_name NULL);

-- 3.10 Verificacion
SELECT table_name, constraint_name, constraint_type, status
FROM   user_constraints
WHERE  table_name IN ('EMPLOYEES','DEPARTMENTS')
ORDER BY table_name, status, constraint_type;


-- =============================================================================
-- 4. INSERCIONES QUE INCUMPLEN RESTRICCIONES
-- =============================================================================

-- 4.1 Viola PK (employee_id duplicado: 100 ya existe)
INSERT INTO employees (employee_id, last_name, email, hire_date, job_id)
VALUES (100, 'DUPLICADO_PK', 'duplicado1@dup.com', SYSDATE, 'IT_PROG');

-- 4.2 Viola NOT NULL (varios campos en NULL)
INSERT INTO employees (employee_id, last_name, email, hire_date, job_id)
VALUES (9001, NULL, NULL, NULL, NULL);

-- 4.3 Viola UNIQUE de email (SKING ya existe)
INSERT INTO employees (employee_id, last_name, email, hire_date, job_id)
VALUES (9002, 'CopiaEmail', 'SKING', SYSDATE, 'IT_PROG');

-- 4.4 Viola CHECK (salary > 0)
INSERT INTO employees (employee_id, last_name, email, hire_date, job_id, salary)
VALUES (9003, 'SalNegativo', 'sneg@dup.com', SYSDATE, 'IT_PROG', -500);

-- 4.5 Viola FK (department_id 9999 y manager_id 9999 no existen)
INSERT INTO employees (employee_id, last_name, email, hire_date, job_id, department_id, manager_id)
VALUES (9004, 'FKInexistente', 'fkinex@dup.com', SYSDATE, 'IT_PROG', 9999, 9999);

-- 4.6 Viola PK en departments (10 ya existe)
INSERT INTO departments (department_id, department_name)
VALUES (10, 'DEPT_DUPLICADO');

-- 4.7 Viola NOT NULL en department_name
INSERT INTO departments (department_id, department_name) VALUES (9101, NULL);

-- 4.8 Viola FK en departments (location_id 5555 no existe)
INSERT INTO departments (department_id, department_name, location_id)
VALUES (9102, 'DEPT_LOC_FAKE', 5555);

COMMIT;

-- 4.9 Verificacion
SELECT employee_id, last_name, email, salary, department_id, manager_id
FROM   employees
WHERE  employee_id IN (100, 9001, 9002, 9003, 9004)
   OR  email = 'SKING'
ORDER BY employee_id;

SELECT department_id, department_name, location_id
FROM   departments
WHERE  department_id IN (10, 9101, 9102)
ORDER BY department_id;


-- =============================================================================
-- 5. REACTIVACION DE RESTRICCIONES
-- =============================================================================

-- 5.1 Limpiar tuplas invalidas insertadas en el paso 4
DELETE FROM employees
WHERE employee_id IN (9001, 9002, 9003, 9004)
   OR (employee_id = 100 AND last_name = 'DUPLICADO_PK');

DELETE FROM departments
WHERE department_id IN (9101, 9102)
   OR (department_id = 10 AND department_name = 'DEPT_DUPLICADO');

COMMIT;

-- 5.2 Reponer NOT NULL
ALTER TABLE employees   MODIFY (last_name      NOT NULL);
ALTER TABLE employees   MODIFY (email          NOT NULL);
ALTER TABLE employees   MODIFY (hire_date      NOT NULL);
ALTER TABLE employees   MODIFY (job_id         NOT NULL);
ALTER TABLE departments MODIFY (department_name NOT NULL);

-- 5.3 Habilitar PRIMARY KEYs primero
ALTER TABLE employees   ENABLE CONSTRAINT emp_emp_id_pk;
ALTER TABLE departments ENABLE CONSTRAINT dept_id_pk;

-- 5.4 UNIQUE y CHECK
ALTER TABLE employees ENABLE CONSTRAINT emp_email_uk;
ALTER TABLE employees ENABLE CONSTRAINT emp_salary_min;

-- 5.5 FKs
ALTER TABLE employees   ENABLE CONSTRAINT emp_dept_fk;
ALTER TABLE employees   ENABLE CONSTRAINT emp_job_fk;
ALTER TABLE employees   ENABLE CONSTRAINT emp_manager_fk;
ALTER TABLE departments ENABLE CONSTRAINT dept_mgr_fk;
ALTER TABLE departments ENABLE CONSTRAINT dept_loc_fk;
ALTER TABLE job_history ENABLE CONSTRAINT jhist_emp_fk;
ALTER TABLE job_history ENABLE CONSTRAINT jhist_dept_fk;

-- 5.6 Verificacion final
SELECT table_name, constraint_name, constraint_type, status, validated
FROM   user_constraints
WHERE  table_name IN ('EMPLOYEES','DEPARTMENTS','JOB_HISTORY')
ORDER BY table_name, status, constraint_type;


-- =============================================================================
-- 6. CREACION DE departments2 (CTAS)
-- =============================================================================
DROP TABLE departments2 CASCADE CONSTRAINTS;

CREATE TABLE departments2 AS SELECT * FROM departments;

SELECT COUNT(*) AS filas_copiadas FROM departments2;

-- Verificar que CTAS NO copio constraints ni indices
SELECT table_name, constraint_name, constraint_type, status
FROM   user_constraints WHERE table_name = 'DEPARTMENTS2';

SELECT table_name, index_name, uniqueness
FROM   user_indexes    WHERE table_name = 'DEPARTMENTS2';


-- =============================================================================
-- 7. INSERCION DE TRES TUPLAS EN departments2
-- =============================================================================
INSERT INTO departments2 (department_id, department_name, manager_id, location_id)
VALUES (300, 'Investigacion y Desarrollo', 200, 1700);

INSERT INTO departments2 (department_id, department_name, manager_id, location_id)
VALUES (310, 'Innovacion Digital', 201, 1800);

INSERT INTO departments2 (department_id, department_name, manager_id, location_id)
VALUES (320, 'Analitica de Datos', NULL, 1500);

COMMIT;

SELECT * FROM departments2
WHERE  department_id IN (300, 310, 320)
ORDER BY department_id;


-- =============================================================================
-- 8. CIERRE DE SESION
--    En APEX no hay un "Disconnect" como en SQL Developer; equivale a cerrar
--    sesion del workspace. APEX hace COMMIT automatico al desconectar (no
--    ROLLBACK como SQL Developer). Por eso explicitamos COMMIT al final del 7.
-- =============================================================================
-- Equivalente conceptual en APEX:
--   1) Menu superior > tu usuario > Sign Out  (o cerrar pestana del navegador)
--   2) Para reconectar, volver a apex.oracle.com con tu workspace + usuario.


-- =============================================================================
-- 9. CONSULTA POSTERIOR DE departments2 (tras reconectar)
-- =============================================================================
SELECT department_id, department_name, manager_id, location_id
FROM   departments2
ORDER BY department_id;


-- =============================================================================
-- 10. BLOQUE ANONIMO PL/SQL
--    En APEX SQL Workshop > SQL Commands, este bloque se pega completo y se
--    ejecuta con el boton "Run". Los DBMS_OUTPUT.PUT_LINE aparecen en la
--    pestana "Statement Results" o en la salida de script.
-- =============================================================================
SET SERVEROUTPUT ON;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- INICIO DE TRANSACCION sobre DEPARTMENTS2 ---');

    INSERT INTO departments2 (department_id, department_name, manager_id, location_id)
    VALUES (330, 'Gobierno del Dato', 205, 1700);

    UPDATE departments2
       SET department_name = 'Innovacion Digital y Cloud'
     WHERE department_id   = 310;

    DELETE FROM departments2
     WHERE department_id   = 320;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Transaccion confirmada con COMMIT.');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM || '. Transaccion deshecha con ROLLBACK.');
END;
/

SELECT * FROM departments2 ORDER BY department_id;


-- =============================================================================
-- 11. EJEMPLO DE ROLLBACK
-- =============================================================================

-- Estado actual antes de la prueba
SELECT department_id, department_name FROM departments2 WHERE department_id = 330;

UPDATE departments2
   SET department_name = 'Cambio temporal (sera deshecho)'
 WHERE department_id   = 330;

SELECT department_id, department_name FROM departments2 WHERE department_id = 330;

ROLLBACK;

SELECT department_id, department_name FROM departments2 WHERE department_id = 330;
-- El valor original vuelve.

-- Variante con SAVEPOINT
INSERT INTO departments2 (department_id, department_name, location_id) VALUES (340,'Prueba SP1',1700);
SAVEPOINT sp1;
INSERT INTO departments2 (department_id, department_name, location_id) VALUES (341,'Prueba SP2',1700);
ROLLBACK TO SAVEPOINT sp1;
COMMIT;
SELECT department_id, department_name FROM departments2 WHERE department_id IN (340,341);
-- Esperado: solo 340.


-- =============================================================================
-- 12. REDO LOGS - LIMITACION DEL ENTORNO APEX FREE
-- =============================================================================
-- Justificacion academica de la limitacion (a citar en la memoria APA):
--
-- "Oracle APEX Free Workspace y Oracle Autonomous Database son entornos
--  compartidos administrados por Oracle Cloud Infrastructure. Como parte de
--  la abstraccion de servicio, Oracle restringe a los tenants individuales el
--  acceso a las vistas dinamicas de la instancia (V$LOG, V$LOGFILE,
--  V$DATABASE) y a las operaciones de instancia (ALTER SYSTEM SWITCH LOGFILE,
--  ALTER DATABASE ARCHIVELOG). La gestion de los archivos redo y del modo
--  de archivado (siempre ARCHIVELOG en Autonomous, no modificable por el
--  tenant) corre a cargo de Oracle. Por lo tanto, el punto 12 del enunciado
--  se responde en el documento APA con base teorica y documentacion oficial
--  Oracle, sin captura ejecutiva en este entorno."
--
-- Consultas que SE INTENTAN (probablemente devuelvan ORA-00942 'table or view
-- does not exist' o ORA-01031 'insufficient privileges' - eso ES la evidencia):

SELECT name, log_mode, open_mode, database_role FROM v$database;
-- Esperado en APEX free: ORA-00942 (no se ve V$DATABASE).

SELECT group#, sequence#, bytes/1024/1024 AS mb, members, status FROM v$log;
-- Esperado: ORA-00942.

-- Captura ESPERADA: la pantalla mostrara el error ORA - eso es la evidencia
-- de la limitacion. Pegarla en la memoria APA en la seccion 12.


--==============================================================================
-- FIN DEL SCRIPT
--==============================================================================
