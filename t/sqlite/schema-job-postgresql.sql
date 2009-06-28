CREATE TABLE funcmap (
    funcid SERIAL,
    funcname            VARCHAR(255) NOT NULL,
    UNIQUE (funcname)
);

CREATE TABLE job (
    jobid               SERIAL,
    funcid              INT NOT NULL,
    arg                 BYTEA,
    uniqkey             VARCHAR(255) NULL,
    insert_time         INTEGER,
    run_after           INTEGER NOT NULL,
    grabbed_until       INTEGER NOT NULL,
    priority            SMALLINT,
    coalesce            VARCHAR(255)
);
CREATE UNIQUE INDEX job_funcid_uniqkey ON job (funcid, uniqkey);
CREATE INDEX job_funcid_runafter ON job (funcid, run_after);
CREATE INDEX job_funcid_coalesce ON job (funcid, coalesce);

CREATE TABLE note (
    jobid               BIGINT NOT NULL,
    notekey             VARCHAR(255),
    value               BYTEA,
    PRIMARY KEY (jobid, notekey)
);

CREATE TABLE error (
    error_time          INTEGER NOT NULL,
    jobid               BIGINT NOT NULL,
    message             VARCHAR(255) NOT NULL,
    funcid              INT NOT NULL DEFAULT 0
);
CREATE INDEX error_funcid_errortime ON error (funcid, error_time);
CREATE INDEX error_time ON error (error_time);
CREATE INDEX error_jobid ON error (jobid);

CREATE TABLE exitstatus (
    jobid               BIGINT PRIMARY KEY NOT NULL,
    funcid              INT NOT NULL DEFAULT 0,
    status              SMALLINT,
    completion_time     INTEGER,
    delete_after        INTEGER
);
CREATE INDEX exitstatus_funcid ON exitstatus (funcid);
CREATE INDEX exitstatus_deleteafter ON exitstatus (delete_after);

