/*==============================================================================
  IVConnect - ImpleVista IT India Pvt Ltd
  Employee & Business Portal - MSSQL Schema Baseline
  Version : 1.0
  Target  : SQL Server 2019 or later (Standard Edition recommended)
  Author  : Solution Architecture pack, Document 3 of 3
--------------------------------------------------------------------------------
  RUN ORDER
    Section 1  Database, options, schemas
    Section 2  core   - identity, files, audit plumbing
    Section 3  hr     - employees, resumes
    Section 4  payroll- periods, batches, payslips
    Section 5  leave  - types, calendar, ledger, requests
    Section 6  sales  - leads, activities, website enquiries
    Section 7  Foreign keys
    Section 8  Indexes
    Section 9  Views and functions
    Section 10 Seed data
    Section 11 Security (roles / least privilege)

  NOTE ON TEMPORAL TABLES
    hr.Employees and sales.Leads use SYSTEM_VERSIONING for free audit history.
    If your edition/version rejects ROWVERSION inside a temporal table, replace
    the RowVersion column with:  ConcurrencyStamp UNIQUEIDENTIFIER NOT NULL
    and set it in the application on every update.
==============================================================================*/

/*------------------------------------------------------------------------------
  SECTION 1 - DATABASE, OPTIONS, SCHEMAS
------------------------------------------------------------------------------*/
IF DB_ID('IVConnect') IS NULL
    CREATE DATABASE IVConnect;
GO
ALTER DATABASE IVConnect SET READ_COMMITTED_SNAPSHOT ON WITH ROLLBACK IMMEDIATE;
ALTER DATABASE IVConnect SET ALLOW_SNAPSHOT_ISOLATION ON;
ALTER DATABASE IVConnect SET RECOVERY FULL;
GO
USE IVConnect;
GO

/*  Transparent Data Encryption - run once, keep the certificate backup safe.
    Without the certificate backup you CANNOT restore the database. Do not skip.

    USE master;
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = '<strong-password>';
    CREATE CERTIFICATE IVConnectTDECert WITH SUBJECT = 'IVConnect TDE Certificate';
    BACKUP CERTIFICATE IVConnectTDECert
        TO FILE = 'D:\keys\IVConnectTDECert.cer'
        WITH PRIVATE KEY (FILE = 'D:\keys\IVConnectTDECert.pvk',
                          ENCRYPTION BY PASSWORD = '<strong-password>');
    USE IVConnect;
    CREATE DATABASE ENCRYPTION KEY WITH ALGORITHM = AES_256
        ENCRYPTION BY SERVER CERTIFICATE IVConnectTDECert;
    ALTER DATABASE IVConnect SET ENCRYPTION ON;
*/

IF SCHEMA_ID('core')    IS NULL EXEC('CREATE SCHEMA core');
IF SCHEMA_ID('hr')      IS NULL EXEC('CREATE SCHEMA hr');
IF SCHEMA_ID('payroll') IS NULL EXEC('CREATE SCHEMA payroll');
IF SCHEMA_ID('leave')   IS NULL EXEC('CREATE SCHEMA [leave]');
IF SCHEMA_ID('sales')   IS NULL EXEC('CREATE SCHEMA sales');
IF SCHEMA_ID('audit')   IS NULL EXEC('CREATE SCHEMA audit');
GO


/*------------------------------------------------------------------------------
  SECTION 2 - CORE
------------------------------------------------------------------------------*/
CREATE TABLE core.Files (
    FileId            INT IDENTITY(1,1) CONSTRAINT PK_Files PRIMARY KEY,
    FileGuid          UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Files_Guid DEFAULT NEWID(),
    Container         VARCHAR(40)   NOT NULL,
    StorageKey        NVARCHAR(400) NOT NULL,
    OriginalFileName  NVARCHAR(255) NOT NULL,
    ContentType       VARCHAR(100)  NOT NULL,
    SizeBytes         BIGINT        NOT NULL,
    Sha256            VARBINARY(32) NOT NULL,
    ScanStatus        VARCHAR(12)   NOT NULL CONSTRAINT DF_Files_Scan DEFAULT 'Pending',
    UploadedBy        INT           NOT NULL,
    UploadedAtUtc     DATETIME2(3)  NOT NULL CONSTRAINT DF_Files_Upl DEFAULT SYSUTCDATETIME(),
    IsDeleted         BIT           NOT NULL CONSTRAINT DF_Files_Del DEFAULT 0,
    CONSTRAINT UQ_Files_Key   UNIQUE (Container, StorageKey),
    CONSTRAINT UQ_Files_Guid  UNIQUE (FileGuid),
    CONSTRAINT CK_Files_Scan  CHECK (ScanStatus IN ('Pending','Clean','Infected')),
    CONSTRAINT CK_Files_Size  CHECK (SizeBytes > 0)
);

CREATE TABLE core.Users (
    UserId              INT IDENTITY(1,1) CONSTRAINT PK_Users PRIMARY KEY,
    UserGuid            UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Users_Guid DEFAULT NEWID(),
    EmployeeId          INT NULL,
    UserName            NVARCHAR(100) NOT NULL,
    NormalizedUserName  NVARCHAR(100) NOT NULL,
    PasswordHash        NVARCHAR(500) NULL,
    SecurityStamp       UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Users_Stamp DEFAULT NEWID(),
    IsActive            BIT NOT NULL CONSTRAINT DF_Users_Active DEFAULT 1,
    MustChangePassword  BIT NOT NULL CONSTRAINT DF_Users_MustChg DEFAULT 0,
    MfaEnabled          BIT NOT NULL CONSTRAINT DF_Users_Mfa DEFAULT 0,
    MfaSecretEncrypted  VARBINARY(256) NULL,
    FailedLoginCount    TINYINT NOT NULL CONSTRAINT DF_Users_Fail DEFAULT 0,
    LockoutEndUtc       DATETIME2(3) NULL,
    LastLoginUtc        DATETIME2(3) NULL,
    LastPasswordChgUtc  DATETIME2(3) NULL,
    CreatedAtUtc        DATETIME2(3) NOT NULL CONSTRAINT DF_Users_Cr DEFAULT SYSUTCDATETIME(),
    CreatedBy           INT NOT NULL CONSTRAINT DF_Users_CrBy DEFAULT 0,
    ModifiedAtUtc       DATETIME2(3) NULL,
    ModifiedBy          INT NULL,
    RowVersion          ROWVERSION NOT NULL,
    CONSTRAINT UQ_Users_NormName UNIQUE (NormalizedUserName),
    CONSTRAINT UQ_Users_Guid     UNIQUE (UserGuid),
    CONSTRAINT UQ_Users_Employee UNIQUE (EmployeeId)
);

CREATE TABLE core.Roles (
    RoleId    INT IDENTITY(1,1) CONSTRAINT PK_Roles PRIMARY KEY,
    RoleCode  VARCHAR(30)  NOT NULL CONSTRAINT UQ_Roles_Code UNIQUE,
    RoleName  NVARCHAR(80) NOT NULL,
    Description NVARCHAR(200) NULL,
    IsSystem  BIT NOT NULL CONSTRAINT DF_Roles_Sys DEFAULT 0
);

CREATE TABLE core.Permissions (
    PermissionId    INT IDENTITY(1,1) CONSTRAINT PK_Permissions PRIMARY KEY,
    PermissionCode  VARCHAR(80) NOT NULL CONSTRAINT UQ_Perm_Code UNIQUE,
    Module          VARCHAR(30) NOT NULL,
    Description     NVARCHAR(200) NULL
);

CREATE TABLE core.RolePermissions (
    RoleId       INT NOT NULL,
    PermissionId INT NOT NULL,
    CONSTRAINT PK_RolePermissions PRIMARY KEY (RoleId, PermissionId)
);

CREATE TABLE core.UserRoles (
    UserId        INT NOT NULL,
    RoleId        INT NOT NULL,
    AssignedAtUtc DATETIME2(3) NOT NULL CONSTRAINT DF_UserRoles_At DEFAULT SYSUTCDATETIME(),
    AssignedBy    INT NOT NULL,
    CONSTRAINT PK_UserRoles PRIMARY KEY (UserId, RoleId)
);

CREATE TABLE core.RefreshTokens (
    RefreshTokenId  BIGINT IDENTITY(1,1) CONSTRAINT PK_RefreshTokens PRIMARY KEY,
    UserId          INT NOT NULL,
    TokenHash       VARBINARY(32) NOT NULL,
    ExpiresUtc      DATETIME2(3)  NOT NULL,
    CreatedUtc      DATETIME2(3)  NOT NULL CONSTRAINT DF_RT_Cr DEFAULT SYSUTCDATETIME(),
    CreatedIp       VARCHAR(45)   NULL,
    RevokedUtc      DATETIME2(3)  NULL,
    RevokedReason   NVARCHAR(100) NULL,
    ReplacedByHash  VARBINARY(32) NULL,
    CONSTRAINT UQ_RefreshTokens_Hash UNIQUE (TokenHash)
);

CREATE TABLE core.SecurityTokens (          -- activation / password reset
    SecurityTokenId BIGINT IDENTITY(1,1) CONSTRAINT PK_SecurityTokens PRIMARY KEY,
    UserId       INT NOT NULL,
    Purpose      VARCHAR(25) NOT NULL,      -- Activation | PasswordReset | EmailChange
    TokenHash    VARBINARY(32) NOT NULL,
    ExpiresUtc   DATETIME2(3) NOT NULL,
    ConsumedUtc  DATETIME2(3) NULL,
    CreatedUtc   DATETIME2(3) NOT NULL CONSTRAINT DF_ST_Cr DEFAULT SYSUTCDATETIME(),
    CONSTRAINT UQ_SecurityTokens_Hash UNIQUE (TokenHash),
    CONSTRAINT CK_SecurityTokens_Purpose
        CHECK (Purpose IN ('Activation','PasswordReset','EmailChange'))
);

CREATE TABLE core.Notifications (
    NotificationId   BIGINT IDENTITY(1,1) CONSTRAINT PK_Notifications PRIMARY KEY,
    UserId           INT NOT NULL,
    NotificationType VARCHAR(40) NOT NULL,
    Title            NVARCHAR(150) NOT NULL,
    Body             NVARCHAR(600) NULL,
    DeepLink         NVARCHAR(300) NULL,
    IsRead           BIT NOT NULL CONSTRAINT DF_Notif_Read DEFAULT 0,
    CreatedAtUtc     DATETIME2(3) NOT NULL CONSTRAINT DF_Notif_Cr DEFAULT SYSUTCDATETIME()
);

CREATE TABLE core.EmailOutbox (
    EmailId           BIGINT IDENTITY(1,1) CONSTRAINT PK_EmailOutbox PRIMARY KEY,
    ToAddress         NVARCHAR(300) NOT NULL,
    CcAddress         NVARCHAR(300) NULL,
    Subject           NVARCHAR(250) NOT NULL,
    BodyHtml          NVARCHAR(MAX) NOT NULL,
    AttachmentFileIds NVARCHAR(200) NULL,
    Status            VARCHAR(12) NOT NULL CONSTRAINT DF_Email_Status DEFAULT 'Queued',
    AttemptCount      TINYINT NOT NULL CONSTRAINT DF_Email_Att DEFAULT 0,
    LastError         NVARCHAR(1000) NULL,
    QueuedAtUtc       DATETIME2(3) NOT NULL CONSTRAINT DF_Email_Q DEFAULT SYSUTCDATETIME(),
    SentAtUtc         DATETIME2(3) NULL,
    CONSTRAINT CK_Email_Status CHECK (Status IN ('Queued','Sending','Sent','Failed','DeadLetter'))
);

CREATE TABLE core.AppSettings (
    SettingKey   VARCHAR(80) NOT NULL CONSTRAINT PK_AppSettings PRIMARY KEY,
    SettingValue NVARCHAR(400) NOT NULL,
    Description  NVARCHAR(300) NULL,
    ModifiedAtUtc DATETIME2(3) NULL,
    ModifiedBy   INT NULL
);

CREATE TABLE audit.AuditLogs (
    AuditId           BIGINT IDENTITY(1,1) CONSTRAINT PK_AuditLogs PRIMARY KEY,
    EventType         VARCHAR(40) NOT NULL,
    EntityName        VARCHAR(60) NULL,
    EntityKey         VARCHAR(60) NULL,
    ActorUserId       INT NULL,
    ActorEmployeeCode NVARCHAR(20) NULL,
    OccurredAtUtc     DATETIME2(3) NOT NULL CONSTRAINT DF_Audit_At DEFAULT SYSUTCDATETIME(),
    IpAddress         VARCHAR(45) NULL,
    CorrelationId     UNIQUEIDENTIFIER NULL,
    OldValuesJson     NVARCHAR(MAX) NULL,
    NewValuesJson     NVARCHAR(MAX) NULL,
    Notes             NVARCHAR(400) NULL
);
GO


/*------------------------------------------------------------------------------
  SECTION 3 - HR
------------------------------------------------------------------------------*/
CREATE TABLE hr.Designations (
    DesignationId INT IDENTITY(1,1) CONSTRAINT PK_Designations PRIMARY KEY,
    Code          VARCHAR(20) NOT NULL CONSTRAINT UQ_Designations_Code UNIQUE,
    Title         NVARCHAR(80) NOT NULL,
    GradeLevel    TINYINT NULL,
    IsActive      BIT NOT NULL CONSTRAINT DF_Desig_Active DEFAULT 1
);

CREATE TABLE hr.Departments (
    DepartmentId   INT IDENTITY(1,1) CONSTRAINT PK_Departments PRIMARY KEY,
    Code           VARCHAR(20) NOT NULL CONSTRAINT UQ_Departments_Code UNIQUE,
    Name           NVARCHAR(80) NOT NULL,
    HeadEmployeeId INT NULL,
    IsActive       BIT NOT NULL CONSTRAINT DF_Dept_Active DEFAULT 1
);

CREATE TABLE hr.Employees (
    EmployeeId         INT IDENTITY(1,1) CONSTRAINT PK_Employees PRIMARY KEY,
    EmployeeGuid       UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Emp_Guid DEFAULT NEWID(),
    EmployeeCode       NVARCHAR(20) NOT NULL,
    FirstName          NVARCHAR(60) NOT NULL,
    MiddleName         NVARCHAR(60) NULL,
    LastName           NVARCHAR(60) NOT NULL,
    FullName AS (LTRIM(RTRIM(FirstName + N' ' + ISNULL(MiddleName + N' ', N'') + LastName))) PERSISTED,
    DateOfBirth        DATE NULL,
    Gender             CHAR(1) NULL,
    OfficialEmail      NVARCHAR(100) NOT NULL,
    PersonalEmail      NVARCHAR(100) NULL,

    DesignationId      INT NOT NULL,
    DepartmentId       INT NULL,
    ManagerId          INT NULL,

    PanEncrypted       VARBINARY(256) NULL,
    PanHash            VARBINARY(32)  NULL,
    PanMasked          NVARCHAR(12)   NULL,      -- e.g. XXXXX1234Z, written by the app
    ContactNoEncrypted VARBINARY(256) NULL,
    ContactNoLast4     CHAR(4) NULL,
    AltContactNoEnc    VARBINARY(256) NULL,
    EncryptionKeyVer   SMALLINT NOT NULL CONSTRAINT DF_Emp_KeyVer DEFAULT 1,

    DateOfJoining      DATE NOT NULL,
    ConfirmationDate   DATE NULL,
    DateOfExit         DATE NULL,
    EmploymentStatus   VARCHAR(20) NOT NULL CONSTRAINT DF_Emp_Status DEFAULT 'Active',
    EmploymentType     VARCHAR(20) NOT NULL CONSTRAINT DF_Emp_Type DEFAULT 'FullTime',
    WorkLocationCode   VARCHAR(20) NOT NULL CONSTRAINT DF_Emp_Loc DEFAULT 'ALL',

    IsDeleted          BIT NOT NULL CONSTRAINT DF_Emp_Del DEFAULT 0,
    DeletedAtUtc       DATETIME2(3) NULL,
    DeletedBy          INT NULL,
    CreatedAtUtc       DATETIME2(3) NOT NULL CONSTRAINT DF_Emp_Cr DEFAULT SYSUTCDATETIME(),
    CreatedBy          INT NOT NULL,
    ModifiedAtUtc      DATETIME2(3) NULL,
    ModifiedBy         INT NULL,
    RowVersion         ROWVERSION NOT NULL,

    ValidFrom DATETIME2(3) GENERATED ALWAYS AS ROW START HIDDEN NOT NULL,
    ValidTo   DATETIME2(3) GENERATED ALWAYS AS ROW END   HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo),

    CONSTRAINT UQ_Employees_Code   UNIQUE (EmployeeCode),
    CONSTRAINT UQ_Employees_Guid   UNIQUE (EmployeeGuid),
    CONSTRAINT UQ_Employees_Email  UNIQUE (OfficialEmail),
    CONSTRAINT UQ_Employees_PanHash UNIQUE (PanHash),
    CONSTRAINT CK_Emp_Gender       CHECK (Gender IS NULL OR Gender IN ('M','F','O')),
    CONSTRAINT CK_Emp_Status       CHECK (EmploymentStatus IN ('Active','OnNotice','Exited','Suspended')),
    CONSTRAINT CK_Emp_Type         CHECK (EmploymentType IN ('FullTime','PartTime','Contract','Intern')),
    CONSTRAINT CK_Emp_NotSelfMgr   CHECK (ManagerId IS NULL OR ManagerId <> EmployeeId),
    CONSTRAINT CK_Emp_ExitAfterJoin CHECK (DateOfExit IS NULL OR DateOfExit >= DateOfJoining),
    CONSTRAINT CK_Emp_ExitStatus   CHECK (EmploymentStatus <> 'Exited' OR DateOfExit IS NOT NULL)
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = hr.EmployeesHistory));

CREATE TABLE hr.EmployeeAddresses (
    AddressId   INT IDENTITY(1,1) CONSTRAINT PK_EmployeeAddresses PRIMARY KEY,
    EmployeeId  INT NOT NULL,
    AddressType VARCHAR(15) NOT NULL,
    Line1Enc    VARBINARY(512) NOT NULL,
    Line2Enc    VARBINARY(512) NULL,
    Landmark    NVARCHAR(100) NULL,
    City        NVARCHAR(60) NOT NULL,
    StateName   NVARCHAR(60) NOT NULL,
    PostalCode  VARCHAR(10)  NOT NULL,
    Country     NVARCHAR(60) NOT NULL CONSTRAINT DF_Addr_Country DEFAULT N'India',
    IsPrimary   BIT NOT NULL CONSTRAINT DF_Addr_Primary DEFAULT 0,
    CreatedAtUtc DATETIME2(3) NOT NULL CONSTRAINT DF_Addr_Cr DEFAULT SYSUTCDATETIME(),
    CreatedBy    INT NOT NULL,
    ModifiedAtUtc DATETIME2(3) NULL,
    ModifiedBy   INT NULL,
    CONSTRAINT UQ_EmpAddr UNIQUE (EmployeeId, AddressType),
    CONSTRAINT CK_EmpAddr_Type CHECK (AddressType IN ('Permanent','Current')),
    CONSTRAINT CK_EmpAddr_Pin  CHECK (PostalCode NOT LIKE '%[^0-9]%' AND LEN(PostalCode) = 6)
);

CREATE TABLE hr.Resumes (
    ResumeId        INT IDENTITY(1,1) CONSTRAINT PK_Resumes PRIMARY KEY,
    EmployeeId      INT NOT NULL,
    VersionNo       SMALLINT NOT NULL,
    IsCurrent       BIT NOT NULL CONSTRAINT DF_Resume_Cur DEFAULT 0,
    Status          VARCHAR(15) NOT NULL CONSTRAINT DF_Resume_Status DEFAULT 'Draft',
    ProfileSummary  NVARCHAR(2000) NOT NULL,
    TotalExpMonths  SMALLINT NOT NULL,
    PrimarySkillSet NVARCHAR(200) NOT NULL,
    ContentHash     VARBINARY(32) NULL,      -- change detection for the monthly mandate
    LastUpdatedDate DATE NOT NULL,           -- MANDATORY - server-assigned on submit
    SubmittedAtUtc  DATETIME2(3) NULL,
    PdfFileId       INT NULL,
    CreatedAtUtc    DATETIME2(3) NOT NULL CONSTRAINT DF_Resume_Cr DEFAULT SYSUTCDATETIME(),
    CreatedBy       INT NOT NULL,
    ModifiedAtUtc   DATETIME2(3) NULL,
    ModifiedBy      INT NULL,
    RowVersion      ROWVERSION NOT NULL,
    CONSTRAINT UQ_Resume_Version UNIQUE (EmployeeId, VersionNo),
    CONSTRAINT CK_Resume_Status  CHECK (Status IN ('Draft','Submitted')),
    CONSTRAINT CK_Resume_Exp     CHECK (TotalExpMonths BETWEEN 0 AND 720),
    CONSTRAINT CK_Resume_Submitted
        CHECK (Status <> 'Submitted' OR (SubmittedAtUtc IS NOT NULL AND PdfFileId IS NOT NULL))
);

CREATE TABLE hr.ResumeSkills (
    ResumeSkillId     INT IDENTITY(1,1) CONSTRAINT PK_ResumeSkills PRIMARY KEY,
    ResumeId          INT NOT NULL,
    SkillName         NVARCHAR(80) NOT NULL,
    Category          NVARCHAR(50) NOT NULL,
    Proficiency       VARCHAR(15)  NOT NULL,
    YearsOfExperience DECIMAL(4,1) NULL,
    DisplayOrder      SMALLINT NOT NULL CONSTRAINT DF_RSkill_Ord DEFAULT 0,
    CONSTRAINT UQ_ResumeSkill UNIQUE (ResumeId, SkillName),
    CONSTRAINT CK_RSkill_Prof CHECK (Proficiency IN ('Beginner','Intermediate','Advanced','Expert')),
    CONSTRAINT CK_RSkill_Cat  CHECK (Category IN (N'Technical',N'Functional',N'Tool',N'Soft',N'Domain'))
);

CREATE TABLE hr.ResumeProjects (
    ResumeProjectId  INT IDENTITY(1,1) CONSTRAINT PK_ResumeProjects PRIMARY KEY,
    ResumeId         INT NOT NULL,
    ProjectName      NVARCHAR(120) NOT NULL,
    ClientName       NVARCHAR(120) NULL,
    RoleTitle        NVARCHAR(80)  NOT NULL,
    StartDate        DATE NOT NULL,
    EndDate          DATE NULL,
    TeamSize         SMALLINT NULL,
    TechStack        NVARCHAR(400)  NOT NULL,
    Description      NVARCHAR(1500) NOT NULL,
    Responsibilities NVARCHAR(2000) NOT NULL,
    IsPreImpleVista  BIT NOT NULL CONSTRAINT DF_RProj_Pre DEFAULT 0,
    DisplayOrder     SMALLINT NOT NULL CONSTRAINT DF_RProj_Ord DEFAULT 0,
    CONSTRAINT CK_RProj_Dates CHECK (EndDate IS NULL OR EndDate >= StartDate)
);

CREATE TABLE hr.ResumeEducation (
    ResumeEducationId INT IDENTITY(1,1) CONSTRAINT PK_ResumeEducation PRIMARY KEY,
    ResumeId       INT NOT NULL,
    Degree         NVARCHAR(80) NOT NULL,
    Specialization NVARCHAR(80) NULL,
    Institution    NVARCHAR(150) NOT NULL,
    University     NVARCHAR(150) NULL,
    YearOfPassing  SMALLINT NOT NULL,
    Percentage     DECIMAL(5,2) NULL,
    DisplayOrder   SMALLINT NOT NULL CONSTRAINT DF_REdu_Ord DEFAULT 0,
    CONSTRAINT CK_REdu_Year CHECK (YearOfPassing BETWEEN 1950 AND 2100),
    CONSTRAINT CK_REdu_Pct  CHECK (Percentage IS NULL OR Percentage BETWEEN 0 AND 100)
);

CREATE TABLE hr.ResumeCertifications (
    ResumeCertificationId INT IDENTITY(1,1) CONSTRAINT PK_ResumeCertifications PRIMARY KEY,
    ResumeId          INT NOT NULL,
    CertificationName NVARCHAR(150) NOT NULL,
    IssuingBody       NVARCHAR(120) NOT NULL,
    IssuedOn          DATE NULL,
    ExpiresOn         DATE NULL,
    CredentialId      NVARCHAR(80) NULL,
    DisplayOrder      SMALLINT NOT NULL CONSTRAINT DF_RCert_Ord DEFAULT 0,
    CONSTRAINT CK_RCert_Dates CHECK (ExpiresOn IS NULL OR IssuedOn IS NULL OR ExpiresOn >= IssuedOn)
);

CREATE TABLE hr.ResumeNoChangeConfirmations (
    ConfirmationId  INT IDENTITY(1,1) CONSTRAINT PK_ResumeNoChange PRIMARY KEY,
    EmployeeId      INT NOT NULL,
    ConfirmedForYear  SMALLINT NOT NULL,
    ConfirmedForMonth TINYINT  NOT NULL,
    ConfirmedAtUtc  DATETIME2(3) NOT NULL CONSTRAINT DF_RNC_At DEFAULT SYSUTCDATETIME(),
    CONSTRAINT UQ_ResumeNoChange UNIQUE (EmployeeId, ConfirmedForYear, ConfirmedForMonth),
    CONSTRAINT CK_RNC_Month CHECK (ConfirmedForMonth BETWEEN 1 AND 12)
);
GO


/*------------------------------------------------------------------------------
  SECTION 4 - PAYROLL
------------------------------------------------------------------------------*/
CREATE TABLE payroll.SalaryComponents (
    ComponentId     INT IDENTITY(1,1) CONSTRAINT PK_SalaryComponents PRIMARY KEY,
    ComponentCode   VARCHAR(30)  NOT NULL CONSTRAINT UQ_SalComp_Code UNIQUE,
    ComponentName   NVARCHAR(80) NOT NULL,
    ComponentType   CHAR(1)      NOT NULL,
    ExcelHeaderName NVARCHAR(80) NOT NULL CONSTRAINT UQ_SalComp_Header UNIQUE,
    DisplaySequence SMALLINT     NOT NULL,
    IsTaxable       BIT NOT NULL CONSTRAINT DF_SalComp_Tax DEFAULT 1,
    IsActive        BIT NOT NULL CONSTRAINT DF_SalComp_Active DEFAULT 1,
    CONSTRAINT CK_SalComp_Type CHECK (ComponentType IN ('E','D','I'))
);

CREATE TABLE payroll.PayrollPeriods (
    PeriodId    INT IDENTITY(1,1) CONSTRAINT PK_PayrollPeriods PRIMARY KEY,
    PeriodYear  SMALLINT NOT NULL,
    PeriodMonth TINYINT  NOT NULL,
    PeriodLabel AS (CAST(PeriodYear AS VARCHAR(4)) + '-'
                    + RIGHT('0' + CAST(PeriodMonth AS VARCHAR(2)), 2)) PERSISTED,
    Status      VARCHAR(15) NOT NULL CONSTRAINT DF_Period_Status DEFAULT 'Open',
    LockedAtUtc DATETIME2(3) NULL,
    LockedBy    INT NULL,
    CreatedAtUtc DATETIME2(3) NOT NULL CONSTRAINT DF_Period_Cr DEFAULT SYSUTCDATETIME(),
    CreatedBy    INT NOT NULL,
    CONSTRAINT UQ_PayrollPeriods UNIQUE (PeriodYear, PeriodMonth),
    CONSTRAINT CK_Period_Month  CHECK (PeriodMonth BETWEEN 1 AND 12),
    CONSTRAINT CK_Period_Year   CHECK (PeriodYear BETWEEN 2000 AND 2100),
    CONSTRAINT CK_Period_Status CHECK (Status IN ('Open','Published','Locked'))
);

CREATE TABLE payroll.PayslipBatches (
    BatchId          INT IDENTITY(1,1) CONSTRAINT PK_PayslipBatches PRIMARY KEY,
    BatchGuid        UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Batch_Guid DEFAULT NEWID(),
    PeriodId         INT NOT NULL,
    SourceFileId     INT NOT NULL,
    TemplateVersion  VARCHAR(10) NOT NULL,
    Status           VARCHAR(20) NOT NULL,
    TotalRows        INT NOT NULL CONSTRAINT DF_Batch_Total DEFAULT 0,
    ValidRows        INT NOT NULL CONSTRAINT DF_Batch_Valid DEFAULT 0,
    ErrorRows        INT NOT NULL CONSTRAINT DF_Batch_Err DEFAULT 0,
    WarningRows      INT NOT NULL CONSTRAINT DF_Batch_Warn DEFAULT 0,
    ControlTotalNet  DECIMAL(18,2) NULL,
    ComputedTotalNet DECIMAL(18,2) NULL,
    WarningsAcknowledged BIT NOT NULL CONSTRAINT DF_Batch_Ack DEFAULT 0,
    UploadedBy       INT NOT NULL,
    UploadedAtUtc    DATETIME2(3) NOT NULL CONSTRAINT DF_Batch_Upl DEFAULT SYSUTCDATETIME(),
    CommittedBy      INT NULL,
    CommittedAtUtc   DATETIME2(3) NULL,
    FailureReason    NVARCHAR(1000) NULL,
    CONSTRAINT UQ_Batch_Guid UNIQUE (BatchGuid),
    CONSTRAINT CK_Batch_Status CHECK (Status IN
        ('Uploaded','Validating','ValidationFailed','ReadyToCommit',
         'Committing','Committed','Cancelled')),
    CONSTRAINT CK_Batch_MakerChecker CHECK (CommittedBy IS NULL OR CommittedBy <> UploadedBy)
);

CREATE TABLE payroll.PayslipStaging (
    StagingId          BIGINT IDENTITY(1,1) CONSTRAINT PK_PayslipStaging PRIMARY KEY,
    BatchId            INT NOT NULL,
    ExcelRowNumber     INT NOT NULL,
    EmployeeCode       NVARCHAR(20) NULL,
    ResolvedEmployeeId INT NULL,
    RawRowJson         NVARCHAR(MAX) NOT NULL,
    PaidDays           DECIMAL(5,2) NULL,
    LopDays            DECIMAL(5,2) NULL,
    ComputedGross      DECIMAL(18,2) NULL,
    ComputedDeduct     DECIMAL(18,2) NULL,
    ComputedNet        DECIMAL(18,2) NULL,
    Severity           VARCHAR(10) NOT NULL CONSTRAINT DF_Staging_Sev DEFAULT 'Ok',
    Messages           NVARCHAR(MAX) NULL,
    CONSTRAINT UQ_Staging_Row UNIQUE (BatchId, ExcelRowNumber),
    CONSTRAINT CK_Staging_Sev CHECK (Severity IN ('Ok','Warning','Error'))
);

CREATE TABLE payroll.Payslips (
    PayslipId       INT IDENTITY(1,1) CONSTRAINT PK_Payslips PRIMARY KEY,
    PayslipGuid     UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Payslip_Guid DEFAULT NEWID(),
    PeriodId        INT NOT NULL,
    EmployeeId      INT NOT NULL,
    BatchId         INT NOT NULL,
    VersionNo       SMALLINT NOT NULL CONSTRAINT DF_Payslip_Ver DEFAULT 1,
    IsCurrent       BIT NOT NULL CONSTRAINT DF_Payslip_Cur DEFAULT 1,
    SupersededByPayslipId INT NULL,

    PaidDays        DECIMAL(5,2)  NOT NULL,
    LopDays         DECIMAL(5,2)  NOT NULL CONSTRAINT DF_Payslip_Lop DEFAULT 0,
    GrossEarnings   DECIMAL(18,2) NOT NULL,
    TotalDeductions DECIMAL(18,2) NOT NULL,
    NetPay          DECIMAL(18,2) NOT NULL,
    NetPayInWords   NVARCHAR(300) NOT NULL,

    BankNameMasked  NVARCHAR(60) NULL,
    BankAccLast4    CHAR(4) NULL,
    UanNumber       VARCHAR(12) NULL,
    PfNumber        VARCHAR(30) NULL,
    EsiNumber       VARCHAR(20) NULL,

    PdfFileId       INT NULL,
    PdfGeneratedUtc DATETIME2(3) NULL,
    PublishedUtc    DATETIME2(3) NULL,
    Remarks         NVARCHAR(300) NULL,
    CreatedAtUtc    DATETIME2(3) NOT NULL CONSTRAINT DF_Payslip_Cr DEFAULT SYSUTCDATETIME(),
    CreatedBy       INT NOT NULL,

    CONSTRAINT UQ_Payslip_Version UNIQUE (PeriodId, EmployeeId, VersionNo),
    CONSTRAINT UQ_Payslip_Guid    UNIQUE (PayslipGuid),
    CONSTRAINT CK_Payslip_Net     CHECK (NetPay = GrossEarnings - TotalDeductions),
    CONSTRAINT CK_Payslip_NonNeg  CHECK (GrossEarnings >= 0 AND TotalDeductions >= 0),
    CONSTRAINT CK_Payslip_Days    CHECK (PaidDays >= 0 AND PaidDays <= 31 AND LopDays >= 0)
);

CREATE TABLE payroll.PayslipComponents (
    PayslipComponentId BIGINT IDENTITY(1,1) CONSTRAINT PK_PayslipComponents PRIMARY KEY,
    PayslipId   INT NOT NULL,
    ComponentId INT NOT NULL,
    Amount      DECIMAL(18,2) NOT NULL,
    CONSTRAINT UQ_PayslipComp UNIQUE (PayslipId, ComponentId)
);
GO


/*------------------------------------------------------------------------------
  SECTION 5 - LEAVE
------------------------------------------------------------------------------*/
CREATE TABLE [leave].LeaveTypes (
    LeaveTypeId  INT IDENTITY(1,1) CONSTRAINT PK_LeaveTypes PRIMARY KEY,
    Code         VARCHAR(10)  NOT NULL CONSTRAINT UQ_LeaveTypes_Code UNIQUE,
    Name         NVARCHAR(60) NOT NULL,
    IsPaid       BIT NOT NULL CONSTRAINT DF_LType_Paid DEFAULT 1,
    AnnualQuota  DECIMAL(5,2) NOT NULL,
    AccrualMode  VARCHAR(12) NOT NULL CONSTRAINT DF_LType_Accr DEFAULT 'Monthly',
    AllowHalfDay BIT NOT NULL CONSTRAINT DF_LType_Half DEFAULT 1,
    MinNoticeDays SMALLINT NOT NULL CONSTRAINT DF_LType_Notice DEFAULT 0,
    MaxConsecutiveDays SMALLINT NULL,
    AttachmentRequiredAfterDays SMALLINT NULL,
    CarryForwardAllowed BIT NOT NULL CONSTRAINT DF_LType_CF DEFAULT 0,
    MaxCarryForwardDays DECIMAL(5,2) NULL,
    AllowNegativeBalance BIT NOT NULL CONSTRAINT DF_LType_Neg DEFAULT 0,
    DisplayOrder SMALLINT NOT NULL CONSTRAINT DF_LType_Ord DEFAULT 0,
    IsActive     BIT NOT NULL CONSTRAINT DF_LType_Active DEFAULT 1,
    CONSTRAINT CK_LType_Accrual CHECK (AccrualMode IN ('Monthly','Annual','None')),
    CONSTRAINT CK_LType_Quota   CHECK (AnnualQuota >= 0)
);

CREATE TABLE [leave].HolidayCalendar (
    HolidayId    INT IDENTITY(1,1) CONSTRAINT PK_HolidayCalendar PRIMARY KEY,
    HolidayDate  DATE NOT NULL,
    HolidayName  NVARCHAR(80) NOT NULL,
    CalendarYear AS (YEAR(HolidayDate)) PERSISTED,
    LocationCode VARCHAR(20) NOT NULL CONSTRAINT DF_Hol_Loc DEFAULT 'ALL',
    IsOptional   BIT NOT NULL CONSTRAINT DF_Hol_Opt DEFAULT 0,
    CreatedAtUtc DATETIME2(3) NOT NULL CONSTRAINT DF_Hol_Cr DEFAULT SYSUTCDATETIME(),
    CreatedBy    INT NOT NULL,
    CONSTRAINT UQ_Holiday UNIQUE (HolidayDate, LocationCode)
);

CREATE TABLE [leave].WeeklyOffPattern (
    PatternId    INT IDENTITY(1,1) CONSTRAINT PK_WeeklyOffPattern PRIMARY KEY,
    LocationCode VARCHAR(20) NOT NULL CONSTRAINT DF_WOff_Loc DEFAULT 'ALL',
    DayOfWeekNo  TINYINT NOT NULL,          -- 1 = Sunday .. 7 = Saturday
    OffType      VARCHAR(12) NOT NULL,      -- Full | Alternate | None
    CONSTRAINT UQ_WeeklyOff UNIQUE (LocationCode, DayOfWeekNo),
    CONSTRAINT CK_WOff_Day  CHECK (DayOfWeekNo BETWEEN 1 AND 7),
    CONSTRAINT CK_WOff_Type CHECK (OffType IN ('Full','Alternate','None'))
);

CREATE TABLE [leave].LeaveBalanceLedger (
    LedgerId        BIGINT IDENTITY(1,1) CONSTRAINT PK_LeaveBalanceLedger PRIMARY KEY,
    EmployeeId      INT NOT NULL,
    LeaveTypeId     INT NOT NULL,
    LeaveYear       SMALLINT NOT NULL,
    TransactionType VARCHAR(15) NOT NULL,
    Days            DECIMAL(6,2) NOT NULL,
    ReferenceType   VARCHAR(20) NULL,
    ReferenceId     INT NULL,
    EffectiveDate   DATE NOT NULL,
    Remarks         NVARCHAR(250) NULL,
    CreatedAtUtc    DATETIME2(3) NOT NULL CONSTRAINT DF_Ledger_Cr DEFAULT SYSUTCDATETIME(),
    CreatedBy       INT NOT NULL,
    CONSTRAINT CK_Ledger_NonZero CHECK (Days <> 0),
    CONSTRAINT CK_Ledger_Type CHECK (TransactionType IN
        ('Opening','Accrual','Deduction','Reversal','CarryForward','Encashment','Adjustment','Lapse'))
);

CREATE TABLE [leave].LeaveRequests (
    LeaveRequestId INT IDENTITY(1,1) CONSTRAINT PK_LeaveRequests PRIMARY KEY,
    RequestNo AS ('LR-' + RIGHT('00000000' + CAST(LeaveRequestId AS VARCHAR(8)), 8)) PERSISTED,
    EmployeeId     INT NOT NULL,
    LeaveTypeId    INT NOT NULL,
    FromDate       DATE NOT NULL,
    ToDate         DATE NOT NULL,
    FromSession    TINYINT NOT NULL CONSTRAINT DF_Leave_FS DEFAULT 1,
    ToSession      TINYINT NOT NULL CONSTRAINT DF_Leave_TS DEFAULT 2,
    TotalDays      DECIMAL(5,2) NOT NULL,
    Reason         NVARCHAR(500) NOT NULL,
    ContactDuringLeave NVARCHAR(50) NULL,
    Status         VARCHAR(22) NOT NULL CONSTRAINT DF_Leave_Status DEFAULT 'Draft',
    ApproverEmployeeId INT NULL,
    ActionedAtUtc  DATETIME2(3) NULL,
    ApproverComments NVARCHAR(500) NULL,
    AttachmentFileId INT NULL,
    AppliedAtUtc   DATETIME2(3) NULL,
    CreatedAtUtc   DATETIME2(3) NOT NULL CONSTRAINT DF_Leave_Cr DEFAULT SYSUTCDATETIME(),
    CreatedBy      INT NOT NULL,
    ModifiedAtUtc  DATETIME2(3) NULL,
    ModifiedBy     INT NULL,
    RowVersion     ROWVERSION NOT NULL,
    CONSTRAINT CK_Leave_Dates   CHECK (ToDate >= FromDate),
    CONSTRAINT CK_Leave_Days    CHECK (TotalDays > 0),
    CONSTRAINT CK_Leave_Session CHECK (FromSession IN (1,2) AND ToSession IN (1,2)),
    CONSTRAINT CK_Leave_Status  CHECK (Status IN
        ('Draft','Submitted','Approved','Rejected','Cancelled',
         'WithdrawalRequested','Withdrawn')),
    CONSTRAINT CK_Leave_RejectComment
        CHECK (Status <> 'Rejected' OR ApproverComments IS NOT NULL)
);

CREATE TABLE [leave].LeaveApprovalHistory (
    HistoryId      BIGINT IDENTITY(1,1) CONSTRAINT PK_LeaveApprovalHistory PRIMARY KEY,
    LeaveRequestId INT NOT NULL,
    FromStatus     VARCHAR(22) NULL,
    ToStatus       VARCHAR(22) NOT NULL,
    ActionByUserId INT NOT NULL,
    ActionAtUtc    DATETIME2(3) NOT NULL CONSTRAINT DF_LHist_At DEFAULT SYSUTCDATETIME(),
    Comments       NVARCHAR(500) NULL
);
GO


/*------------------------------------------------------------------------------
  SECTION 6 - SALES
------------------------------------------------------------------------------*/
CREATE TABLE sales.Leads (
    LeadId          INT IDENTITY(1,1) CONSTRAINT PK_Leads PRIMARY KEY,
    LeadGuid        UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Lead_Guid DEFAULT NEWID(),
    LeadNo AS ('LD-' + RIGHT('000000' + CAST(LeadId AS VARCHAR(6)), 6)) PERSISTED,
    CompanyName     NVARCHAR(150) NOT NULL,
    ContactPerson   NVARCHAR(100) NOT NULL,
    ContactDesignation NVARCHAR(80) NULL,
    Email           NVARCHAR(120) NULL,
    Phone           NVARCHAR(30)  NULL,
    Website         NVARCHAR(150) NULL,
    Industry        NVARCHAR(60)  NULL,
    Country         NVARCHAR(60)  NULL CONSTRAINT DF_Lead_Country DEFAULT N'India',
    City            NVARCHAR(60)  NULL,
    LeadSource      VARCHAR(30)   NOT NULL,
    ServiceInterest NVARCHAR(200) NULL,
    Stage           VARCHAR(20)   NOT NULL CONSTRAINT DF_Lead_Stage DEFAULT 'New',
    Probability     TINYINT       NOT NULL CONSTRAINT DF_Lead_Prob DEFAULT 10,
    EstimatedValue  DECIMAL(18,2) NULL,
    Currency        CHAR(3)       NOT NULL CONSTRAINT DF_Lead_Ccy DEFAULT 'INR',
    ExpectedCloseDate DATE NULL,
    OwnerEmployeeId INT NOT NULL,
    NextActionDate  DATE NULL,
    NextActionNote  NVARCHAR(300) NULL,
    LastContactedDate DATE NULL,
    LostReason      NVARCHAR(200) NULL,
    SourceEnquiryId INT NULL,
    IsDeleted       BIT NOT NULL CONSTRAINT DF_Lead_Del DEFAULT 0,
    CreatedAtUtc    DATETIME2(3) NOT NULL CONSTRAINT DF_Lead_Cr DEFAULT SYSUTCDATETIME(),
    CreatedBy       INT NOT NULL,
    ModifiedAtUtc   DATETIME2(3) NULL,
    ModifiedBy      INT NULL,
    RowVersion      ROWVERSION NOT NULL,
    ValidFrom DATETIME2(3) GENERATED ALWAYS AS ROW START HIDDEN NOT NULL,
    ValidTo   DATETIME2(3) GENERATED ALWAYS AS ROW END   HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo),
    CONSTRAINT UQ_Lead_Guid UNIQUE (LeadGuid),
    CONSTRAINT CK_Lead_Prob  CHECK (Probability BETWEEN 0 AND 100),
    CONSTRAINT CK_Lead_Stage CHECK (Stage IN
        ('New','Contacted','Qualified','Proposal','Negotiation','Won','Lost','Dormant')),
    CONSTRAINT CK_Lead_Source CHECK (LeadSource IN
        ('Website','Referral','ColdCall','LinkedIn','Event','Partner','Existing','Other')),
    CONSTRAINT CK_Lead_Lost  CHECK (Stage <> 'Lost' OR LostReason IS NOT NULL),
    CONSTRAINT CK_Lead_Value CHECK (EstimatedValue IS NULL OR EstimatedValue >= 0)
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = sales.LeadsHistory));

CREATE TABLE sales.LeadActivities (
    ActivityId    BIGINT IDENTITY(1,1) CONSTRAINT PK_LeadActivities PRIMARY KEY,
    LeadId        INT NOT NULL,
    ActivityType  VARCHAR(20) NOT NULL,
    Subject       NVARCHAR(150) NOT NULL,
    Comments      NVARCHAR(MAX) NOT NULL,
    ActivityDate  DATE NOT NULL,
    Outcome       VARCHAR(20) NULL,
    NextActionDate DATE NULL,
    NextActionNote NVARCHAR(300) NULL,
    AttachmentFileId INT NULL,
    CreatedBy     INT NOT NULL,
    CreatedAtUtc  DATETIME2(3) NOT NULL CONSTRAINT DF_LAct_Cr DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_LAct_Type CHECK (ActivityType IN
        ('Call','Email','Meeting','Demo','Note','ProposalSent','FollowUp','SiteVisit')),
    CONSTRAINT CK_LAct_Outcome CHECK (Outcome IS NULL OR Outcome IN
        ('Positive','Neutral','Negative','NoResponse'))
);

CREATE TABLE sales.LeadStageHistory (
    StageHistoryId BIGINT IDENTITY(1,1) CONSTRAINT PK_LeadStageHistory PRIMARY KEY,
    LeadId         INT NOT NULL,
    FromStage      VARCHAR(20) NULL,
    ToStage        VARCHAR(20) NOT NULL,
    ChangedBy      INT NOT NULL,
    ChangedAtUtc   DATETIME2(3) NOT NULL CONSTRAINT DF_LSH_At DEFAULT SYSUTCDATETIME(),
    DaysInPreviousStage INT NULL
);

CREATE TABLE sales.LeadShares (
    LeadId      INT NOT NULL,
    EmployeeId  INT NOT NULL,
    AccessLevel VARCHAR(10) NOT NULL CONSTRAINT DF_LShare_Lvl DEFAULT 'Read',
    SharedBy    INT NOT NULL,
    SharedAtUtc DATETIME2(3) NOT NULL CONSTRAINT DF_LShare_At DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_LeadShares PRIMARY KEY (LeadId, EmployeeId),
    CONSTRAINT CK_LShare_Lvl CHECK (AccessLevel IN ('Read','Write'))
);

CREATE TABLE sales.WebsiteEnquiries (
    EnquiryId   INT IDENTITY(1,1) CONSTRAINT PK_WebsiteEnquiries PRIMARY KEY,
    ReceivedAtUtc DATETIME2(3) NOT NULL CONSTRAINT DF_Enq_At DEFAULT SYSUTCDATETIME(),
    EnquiryRef AS ('IVE-' + CAST(YEAR(ReceivedAtUtc) AS VARCHAR(4)) + '-'
                   + RIGHT('00000' + CAST(EnquiryId AS VARCHAR(5)), 5)) PERSISTED,
    FullName    NVARCHAR(100) NOT NULL,
    Email       NVARCHAR(120) NOT NULL,
    Phone       NVARCHAR(30)  NULL,
    CompanyName NVARCHAR(150) NULL,
    ServiceInterest NVARCHAR(120) NULL,
    Message     NVARCHAR(2000) NOT NULL,
    SourcePageUrl NVARCHAR(300) NULL,
    IpAddress   VARCHAR(45) NULL,
    UserAgent   NVARCHAR(300) NULL,
    CaptchaScore DECIMAL(3,2) NULL,
    ProcessingStatus VARCHAR(15) NOT NULL CONSTRAINT DF_Enq_Status DEFAULT 'New',
    ConvertedLeadId INT NULL,
    ProcessedAtUtc DATETIME2(3) NULL,
    CONSTRAINT CK_Enq_Status CHECK (ProcessingStatus IN ('New','Converted','Spam','Duplicate','Ignored'))
);
GO


/*------------------------------------------------------------------------------
  SECTION 7 - FOREIGN KEYS
------------------------------------------------------------------------------*/
ALTER TABLE core.Users            ADD CONSTRAINT FK_Users_Employee
    FOREIGN KEY (EmployeeId)   REFERENCES hr.Employees(EmployeeId);
ALTER TABLE core.RolePermissions  ADD CONSTRAINT FK_RolePerm_Role
    FOREIGN KEY (RoleId)       REFERENCES core.Roles(RoleId) ON DELETE CASCADE;
ALTER TABLE core.RolePermissions  ADD CONSTRAINT FK_RolePerm_Perm
    FOREIGN KEY (PermissionId) REFERENCES core.Permissions(PermissionId) ON DELETE CASCADE;
ALTER TABLE core.UserRoles        ADD CONSTRAINT FK_UserRoles_User
    FOREIGN KEY (UserId)       REFERENCES core.Users(UserId) ON DELETE CASCADE;
ALTER TABLE core.UserRoles        ADD CONSTRAINT FK_UserRoles_Role
    FOREIGN KEY (RoleId)       REFERENCES core.Roles(RoleId);
ALTER TABLE core.RefreshTokens    ADD CONSTRAINT FK_RefreshTokens_User
    FOREIGN KEY (UserId)       REFERENCES core.Users(UserId) ON DELETE CASCADE;
ALTER TABLE core.SecurityTokens   ADD CONSTRAINT FK_SecurityTokens_User
    FOREIGN KEY (UserId)       REFERENCES core.Users(UserId) ON DELETE CASCADE;
ALTER TABLE core.Notifications    ADD CONSTRAINT FK_Notifications_User
    FOREIGN KEY (UserId)       REFERENCES core.Users(UserId) ON DELETE CASCADE;

ALTER TABLE hr.Employees          ADD CONSTRAINT FK_Employees_Designation
    FOREIGN KEY (DesignationId) REFERENCES hr.Designations(DesignationId);
ALTER TABLE hr.Employees          ADD CONSTRAINT FK_Employees_Department
    FOREIGN KEY (DepartmentId)  REFERENCES hr.Departments(DepartmentId);
ALTER TABLE hr.Employees          ADD CONSTRAINT FK_Employees_Manager
    FOREIGN KEY (ManagerId)     REFERENCES hr.Employees(EmployeeId);
ALTER TABLE hr.Departments        ADD CONSTRAINT FK_Departments_Head
    FOREIGN KEY (HeadEmployeeId) REFERENCES hr.Employees(EmployeeId);
ALTER TABLE hr.EmployeeAddresses  ADD CONSTRAINT FK_EmpAddr_Employee
    FOREIGN KEY (EmployeeId)    REFERENCES hr.Employees(EmployeeId);

ALTER TABLE hr.Resumes            ADD CONSTRAINT FK_Resumes_Employee
    FOREIGN KEY (EmployeeId) REFERENCES hr.Employees(EmployeeId);
ALTER TABLE hr.Resumes            ADD CONSTRAINT FK_Resumes_Pdf
    FOREIGN KEY (PdfFileId)  REFERENCES core.Files(FileId);
ALTER TABLE hr.ResumeSkills         ADD CONSTRAINT FK_RSkills_Resume
    FOREIGN KEY (ResumeId) REFERENCES hr.Resumes(ResumeId) ON DELETE CASCADE;
ALTER TABLE hr.ResumeProjects       ADD CONSTRAINT FK_RProjects_Resume
    FOREIGN KEY (ResumeId) REFERENCES hr.Resumes(ResumeId) ON DELETE CASCADE;
ALTER TABLE hr.ResumeEducation      ADD CONSTRAINT FK_REducation_Resume
    FOREIGN KEY (ResumeId) REFERENCES hr.Resumes(ResumeId) ON DELETE CASCADE;
ALTER TABLE hr.ResumeCertifications ADD CONSTRAINT FK_RCerts_Resume
    FOREIGN KEY (ResumeId) REFERENCES hr.Resumes(ResumeId) ON DELETE CASCADE;
ALTER TABLE hr.ResumeNoChangeConfirmations ADD CONSTRAINT FK_RNC_Employee
    FOREIGN KEY (EmployeeId) REFERENCES hr.Employees(EmployeeId);

ALTER TABLE payroll.PayslipBatches ADD CONSTRAINT FK_Batches_Period
    FOREIGN KEY (PeriodId)     REFERENCES payroll.PayrollPeriods(PeriodId);
ALTER TABLE payroll.PayslipBatches ADD CONSTRAINT FK_Batches_File
    FOREIGN KEY (SourceFileId) REFERENCES core.Files(FileId);
ALTER TABLE payroll.PayslipStaging ADD CONSTRAINT FK_Staging_Batch
    FOREIGN KEY (BatchId)      REFERENCES payroll.PayslipBatches(BatchId) ON DELETE CASCADE;
ALTER TABLE payroll.PayslipStaging ADD CONSTRAINT FK_Staging_Employee
    FOREIGN KEY (ResolvedEmployeeId) REFERENCES hr.Employees(EmployeeId);
ALTER TABLE payroll.Payslips       ADD CONSTRAINT FK_Payslips_Period
    FOREIGN KEY (PeriodId)     REFERENCES payroll.PayrollPeriods(PeriodId);
ALTER TABLE payroll.Payslips       ADD CONSTRAINT FK_Payslips_Employee
    FOREIGN KEY (EmployeeId)   REFERENCES hr.Employees(EmployeeId);
ALTER TABLE payroll.Payslips       ADD CONSTRAINT FK_Payslips_Batch
    FOREIGN KEY (BatchId)      REFERENCES payroll.PayslipBatches(BatchId);
ALTER TABLE payroll.Payslips       ADD CONSTRAINT FK_Payslips_Pdf
    FOREIGN KEY (PdfFileId)    REFERENCES core.Files(FileId);
ALTER TABLE payroll.Payslips       ADD CONSTRAINT FK_Payslips_Superseded
    FOREIGN KEY (SupersededByPayslipId) REFERENCES payroll.Payslips(PayslipId);
ALTER TABLE payroll.PayslipComponents ADD CONSTRAINT FK_PayComp_Payslip
    FOREIGN KEY (PayslipId)   REFERENCES payroll.Payslips(PayslipId) ON DELETE CASCADE;
ALTER TABLE payroll.PayslipComponents ADD CONSTRAINT FK_PayComp_Component
    FOREIGN KEY (ComponentId) REFERENCES payroll.SalaryComponents(ComponentId);

ALTER TABLE [leave].LeaveBalanceLedger ADD CONSTRAINT FK_Ledger_Employee
    FOREIGN KEY (EmployeeId)  REFERENCES hr.Employees(EmployeeId);
ALTER TABLE [leave].LeaveBalanceLedger ADD CONSTRAINT FK_Ledger_Type
    FOREIGN KEY (LeaveTypeId) REFERENCES [leave].LeaveTypes(LeaveTypeId);
ALTER TABLE [leave].LeaveRequests ADD CONSTRAINT FK_LeaveReq_Employee
    FOREIGN KEY (EmployeeId)  REFERENCES hr.Employees(EmployeeId);
ALTER TABLE [leave].LeaveRequests ADD CONSTRAINT FK_LeaveReq_Type
    FOREIGN KEY (LeaveTypeId) REFERENCES [leave].LeaveTypes(LeaveTypeId);
ALTER TABLE [leave].LeaveRequests ADD CONSTRAINT FK_LeaveReq_Approver
    FOREIGN KEY (ApproverEmployeeId) REFERENCES hr.Employees(EmployeeId);
ALTER TABLE [leave].LeaveRequests ADD CONSTRAINT FK_LeaveReq_Attachment
    FOREIGN KEY (AttachmentFileId)   REFERENCES core.Files(FileId);
ALTER TABLE [leave].LeaveApprovalHistory ADD CONSTRAINT FK_LHist_Request
    FOREIGN KEY (LeaveRequestId) REFERENCES [leave].LeaveRequests(LeaveRequestId) ON DELETE CASCADE;

ALTER TABLE sales.Leads          ADD CONSTRAINT FK_Leads_Owner
    FOREIGN KEY (OwnerEmployeeId) REFERENCES hr.Employees(EmployeeId);
ALTER TABLE sales.Leads          ADD CONSTRAINT FK_Leads_Enquiry
    FOREIGN KEY (SourceEnquiryId) REFERENCES sales.WebsiteEnquiries(EnquiryId);
ALTER TABLE sales.LeadActivities ADD CONSTRAINT FK_LeadAct_Lead
    FOREIGN KEY (LeadId) REFERENCES sales.Leads(LeadId);
ALTER TABLE sales.LeadActivities ADD CONSTRAINT FK_LeadAct_File
    FOREIGN KEY (AttachmentFileId) REFERENCES core.Files(FileId);
ALTER TABLE sales.LeadStageHistory ADD CONSTRAINT FK_LSH_Lead
    FOREIGN KEY (LeadId) REFERENCES sales.Leads(LeadId);
ALTER TABLE sales.LeadShares     ADD CONSTRAINT FK_LShare_Lead
    FOREIGN KEY (LeadId) REFERENCES sales.Leads(LeadId) ON DELETE CASCADE;
ALTER TABLE sales.LeadShares     ADD CONSTRAINT FK_LShare_Employee
    FOREIGN KEY (EmployeeId) REFERENCES hr.Employees(EmployeeId);
ALTER TABLE sales.WebsiteEnquiries ADD CONSTRAINT FK_Enq_Lead
    FOREIGN KEY (ConvertedLeadId) REFERENCES sales.Leads(LeadId);
GO


/*------------------------------------------------------------------------------
  SECTION 8 - INDEXES
------------------------------------------------------------------------------*/
-- Employees
CREATE INDEX IX_Employees_Manager ON hr.Employees(ManagerId)
    INCLUDE (EmployeeCode, FullName, DesignationId) WHERE IsDeleted = 0;
CREATE INDEX IX_Employees_Status_Dept ON hr.Employees(EmploymentStatus, DepartmentId)
    INCLUDE (EmployeeCode, FullName, DesignationId, DateOfJoining) WHERE IsDeleted = 0;
CREATE INDEX IX_Employees_DOJ ON hr.Employees(DateOfJoining);

-- Resumes
CREATE UNIQUE INDEX UX_Resume_Current ON hr.Resumes(EmployeeId) WHERE IsCurrent = 1;
CREATE INDEX IX_Resume_LastUpdated ON hr.Resumes(LastUpdatedDate) WHERE IsCurrent = 1;
CREATE INDEX IX_ResumeSkills_Skill ON hr.ResumeSkills(SkillName)
    INCLUDE (ResumeId, Proficiency, YearsOfExperience);

-- Payroll  (this filtered unique index enforces one live payslip per Year+Month+Employee)
CREATE UNIQUE INDEX UX_Payslip_Current ON payroll.Payslips(PeriodId, EmployeeId)
    WHERE IsCurrent = 1;
CREATE INDEX IX_Payslips_Employee ON payroll.Payslips(EmployeeId, PeriodId)
    INCLUDE (NetPay, PdfFileId, IsCurrent, VersionNo);
CREATE INDEX IX_Payslips_Period ON payroll.Payslips(PeriodId)
    INCLUDE (EmployeeId, GrossEarnings, TotalDeductions, NetPay) WHERE IsCurrent = 1;
CREATE INDEX IX_Batches_Period_Status ON payroll.PayslipBatches(PeriodId, Status);
CREATE INDEX IX_Staging_Batch_Sev ON payroll.PayslipStaging(BatchId, Severity);

-- Leave
CREATE INDEX IX_Ledger_Emp_Type_Year ON [leave].LeaveBalanceLedger(EmployeeId, LeaveTypeId, LeaveYear)
    INCLUDE (Days, TransactionType, EffectiveDate);
CREATE INDEX IX_LeaveReq_Emp_Dates ON [leave].LeaveRequests(EmployeeId, FromDate, ToDate)
    INCLUDE (Status, LeaveTypeId, TotalDays);
CREATE INDEX IX_LeaveReq_Approver_Pending ON [leave].LeaveRequests(ApproverEmployeeId)
    INCLUDE (EmployeeId, FromDate, ToDate, TotalDays) WHERE Status = 'Submitted';
CREATE INDEX IX_LeaveReq_Dates ON [leave].LeaveRequests(FromDate, ToDate)
    INCLUDE (EmployeeId, Status);

-- Sales
CREATE INDEX IX_Leads_Owner_Stage ON sales.Leads(OwnerEmployeeId, Stage)
    INCLUDE (CompanyName, EstimatedValue, NextActionDate) WHERE IsDeleted = 0;
CREATE INDEX IX_Leads_NextAction ON sales.Leads(NextActionDate)
    INCLUDE (OwnerEmployeeId, CompanyName, Stage) WHERE IsDeleted = 0;
CREATE INDEX IX_Leads_Stage ON sales.Leads(Stage) WHERE IsDeleted = 0;
CREATE INDEX IX_LeadAct_Lead ON sales.LeadActivities(LeadId, ActivityDate DESC);
CREATE INDEX IX_Enq_Status ON sales.WebsiteEnquiries(ProcessingStatus, ReceivedAtUtc);

-- Audit / plumbing
CREATE INDEX IX_Audit_Time ON audit.AuditLogs(OccurredAtUtc DESC)
    INCLUDE (EventType, ActorUserId, EntityName, EntityKey);
CREATE INDEX IX_Audit_Entity ON audit.AuditLogs(EntityName, EntityKey, OccurredAtUtc DESC);
CREATE INDEX IX_Notif_User_Unread ON core.Notifications(UserId, CreatedAtUtc DESC)
    WHERE IsRead = 0;
CREATE INDEX IX_Email_Status ON core.EmailOutbox(Status, QueuedAtUtc) WHERE Status = 'Queued';
CREATE INDEX IX_RefreshTokens_User ON core.RefreshTokens(UserId, ExpiresUtc);
GO


/*------------------------------------------------------------------------------
  SECTION 9 - VIEWS AND FUNCTIONS
------------------------------------------------------------------------------*/
GO
CREATE OR ALTER FUNCTION hr.fn_WouldCreateManagerCycle (@EmployeeId INT, @NewManagerId INT)
RETURNS BIT
AS
BEGIN
    IF @NewManagerId IS NULL RETURN 0;
    IF @NewManagerId = @EmployeeId RETURN 1;
    DECLARE @cycle BIT = 0;
    ;WITH Chain AS (
        SELECT EmployeeId, ManagerId, 1 AS Lvl
        FROM hr.Employees WHERE EmployeeId = @NewManagerId
        UNION ALL
        SELECT e.EmployeeId, e.ManagerId, c.Lvl + 1
        FROM hr.Employees e JOIN Chain c ON e.EmployeeId = c.ManagerId
        WHERE c.Lvl < 50
    )
    SELECT @cycle = 1 FROM Chain WHERE EmployeeId = @EmployeeId;
    RETURN ISNULL(@cycle, 0);
END;
GO

CREATE OR ALTER VIEW [leave].vw_LeaveBalance AS
SELECT  EmployeeId, LeaveTypeId, LeaveYear,
        SUM(CASE WHEN Days > 0 THEN Days  ELSE 0 END) AS Credited,
        SUM(CASE WHEN Days < 0 THEN -Days ELSE 0 END) AS Consumed,
        SUM(Days) AS AvailableDays
FROM    [leave].LeaveBalanceLedger
GROUP BY EmployeeId, LeaveTypeId, LeaveYear;
GO

CREATE OR ALTER VIEW hr.vw_ResumeCompliance AS
SELECT  e.EmployeeId, e.EmployeeCode, e.FullName,
        d.Title AS Designation, m.FullName AS ManagerName,
        r.LastUpdatedDate,
        DATEDIFF(DAY, r.LastUpdatedDate, CAST(SYSDATETIME() AS DATE)) AS DaysSinceUpdate,
        CASE WHEN r.ResumeId IS NULL THEN 'NeverSubmitted'
             WHEN DATEDIFF(DAY, r.LastUpdatedDate, CAST(SYSDATETIME() AS DATE)) <= 30 THEN 'Compliant'
             WHEN DATEDIFF(DAY, r.LastUpdatedDate, CAST(SYSDATETIME() AS DATE)) <= 45 THEN 'DueSoon'
             ELSE 'Overdue' END AS ComplianceStatus
FROM    hr.Employees e
JOIN    hr.Designations d ON d.DesignationId = e.DesignationId
LEFT JOIN hr.Employees m  ON m.EmployeeId    = e.ManagerId
LEFT JOIN hr.Resumes   r  ON r.EmployeeId    = e.EmployeeId AND r.IsCurrent = 1
WHERE   e.IsDeleted = 0 AND e.EmploymentStatus = 'Active';
GO

/* Admin payslip register - keyed by Year, Month, EmployeeCode */
CREATE OR ALTER VIEW payroll.vw_PayslipRegister AS
SELECT  pp.PeriodYear, pp.PeriodMonth, pp.PeriodLabel,
        e.EmployeeCode, e.FullName, d.Title AS Designation,
        p.PayslipGuid, p.VersionNo, p.PaidDays, p.LopDays,
        p.GrossEarnings, p.TotalDeductions, p.NetPay,
        p.PdfFileId, p.PublishedUtc
FROM    payroll.Payslips p
JOIN    payroll.PayrollPeriods pp ON pp.PeriodId = p.PeriodId
JOIN    hr.Employees e            ON e.EmployeeId = p.EmployeeId
JOIN    hr.Designations d         ON d.DesignationId = e.DesignationId
WHERE   p.IsCurrent = 1;
GO

/* Sales pipeline summary */
CREATE OR ALTER VIEW sales.vw_PipelineSummary AS
SELECT  l.Stage, l.OwnerEmployeeId, e.FullName AS OwnerName,
        COUNT(*) AS LeadCount,
        SUM(ISNULL(l.EstimatedValue,0)) AS TotalValue,
        SUM(CASE WHEN l.NextActionDate < CAST(SYSDATETIME() AS DATE) THEN 1 ELSE 0 END)
            AS OverdueNextActions
FROM    sales.Leads l
JOIN    hr.Employees e ON e.EmployeeId = l.OwnerEmployeeId
WHERE   l.IsDeleted = 0
GROUP BY l.Stage, l.OwnerEmployeeId, e.FullName;
GO


/*------------------------------------------------------------------------------
  SECTION 10 - SEED DATA
------------------------------------------------------------------------------*/
INSERT INTO core.Roles (RoleCode, RoleName, Description, IsSystem) VALUES
 ('EMPLOYEE',      N'Employee',       N'Base role for all staff', 1),
 ('MANAGER',       N'Manager',        N'Approves leave for direct reportees', 1),
 ('HR_ADMIN',      N'HR Admin',       N'Employee master, resume compliance, leave register', 1),
 ('PAYROLL_ADMIN', N'Payroll Admin',  N'Payslip upload, commit and register', 1),
 ('SALES_REP',     N'Sales Rep',      N'Own leads', 1),
 ('SALES_MANAGER', N'Sales Manager',  N'All leads and pipeline', 1),
 ('SYS_ADMIN',     N'System Admin',   N'Users, roles, audit. No payroll amounts.', 1);

INSERT INTO core.Permissions (PermissionCode, Module, Description) VALUES
 ('employee.read.self','Employee',N'View own profile'),
 ('employee.read.team','Employee',N'View direct reportees'),
 ('employee.read.all','Employee',N'View all employees'),
 ('employee.write','Employee',N'Create and update employees'),
 ('employee.pan.reveal','Employee',N'Reveal unmasked PAN (audited)'),
 ('payslip.read.self','Payroll',N'View own payslips'),
 ('payslip.read.all','Payroll',N'View all payslips'),
 ('payslip.batch.upload','Payroll',N'Upload and validate payroll Excel'),
 ('payslip.batch.commit','Payroll',N'Commit a validated batch'),
 ('resume.write.self','Resume',N'Maintain own resume'),
 ('resume.read.all','Resume',N'View all resumes and compliance'),
 ('leave.apply','Leave',N'Apply for leave'),
 ('leave.approve.team','Leave',N'Approve or reject reportee leave'),
 ('leave.read.all','Leave',N'Yearly leave register'),
 ('leave.admin','Leave',N'Maintain leave types, holidays, adjustments'),
 ('lead.read.own','Sales',N'View own and shared leads'),
 ('lead.read.all','Sales',N'View all leads'),
 ('lead.write','Sales',N'Create and update leads and activities'),
 ('lead.reassign','Sales',N'Change lead owner'),
 ('admin.users','Admin',N'User and role administration'),
 ('admin.audit','Admin',N'View audit logs');

INSERT INTO [leave].LeaveTypes
 (Code, Name, IsPaid, AnnualQuota, AccrualMode, AllowHalfDay, MinNoticeDays,
  MaxConsecutiveDays, AttachmentRequiredAfterDays, CarryForwardAllowed,
  MaxCarryForwardDays, AllowNegativeBalance, DisplayOrder)
VALUES
 ('CL',  N'Casual Leave',    1, 12, 'Monthly', 1, 1, 3,    NULL, 0, NULL, 0, 1),
 ('SL',  N'Sick Leave',      1, 12, 'Monthly', 1, 0, NULL, 2,    0, NULL, 0, 2),
 ('EL',  N'Earned Leave',    1, 15, 'Monthly', 1, 7, 15,   NULL, 1, 30,   0, 3),
 ('LOP', N'Loss of Pay',     0,  0, 'None',    1, 1, NULL, NULL, 0, NULL, 1, 4),
 ('COMP',N'Compensatory Off',1,  0, 'None',    1, 1, NULL, NULL, 0, NULL, 0, 5),
 ('MAT', N'Maternity Leave', 1,182,'None',     0,30, NULL, 1,    0, NULL, 0, 6),
 ('PAT', N'Paternity Leave', 1,  5, 'None',    0, 7, NULL, NULL, 0, NULL, 0, 7);

INSERT INTO [leave].WeeklyOffPattern (LocationCode, DayOfWeekNo, OffType) VALUES
 ('ALL', 1, 'Full'),        -- Sunday
 ('ALL', 7, 'Alternate');   -- Saturday (2nd and 4th) - adjust to your policy

INSERT INTO payroll.SalaryComponents
 (ComponentCode, ComponentName, ComponentType, ExcelHeaderName, DisplaySequence, IsTaxable) VALUES
 ('BASIC',    N'Basic Salary',            'E', N'Basic',            10, 1),
 ('HRA',      N'House Rent Allowance',    'E', N'HRA',              20, 1),
 ('CONVEY',   N'Conveyance Allowance',    'E', N'Conveyance',       30, 1),
 ('SPECIAL',  N'Special Allowance',       'E', N'SpecialAllowance', 40, 1),
 ('MEDICAL',  N'Medical Allowance',       'E', N'Medical',          50, 1),
 ('BONUS',    N'Bonus / Incentive',       'E', N'Bonus',            60, 1),
 ('ARREARS',  N'Arrears',                 'E', N'Arrears',          70, 1),
 ('PF_EE',    N'Provident Fund (Employee)','D', N'PF',              110, 0),
 ('ESI_EE',   N'ESI (Employee)',          'D', N'ESI',             120, 0),
 ('PT',       N'Professional Tax',        'D', N'ProfessionalTax', 130, 0),
 ('TDS',      N'Income Tax (TDS)',        'D', N'TDS',             140, 0),
 ('ADVANCE',  N'Salary Advance Recovery', 'D', N'AdvanceRecovery', 150, 0),
 ('OTHERDED', N'Other Deductions',        'D', N'OtherDeductions', 160, 0),
 ('PF_ER',    N'Provident Fund (Employer)','I', N'PFEmployer',     210, 0);

INSERT INTO hr.Designations (Code, Title, GradeLevel) VALUES
 ('TRN',  N'Trainee', 1), ('SE', N'Software Engineer', 2),
 ('SSE',  N'Senior Software Engineer', 3), ('TL', N'Team Lead', 4),
 ('PM',   N'Project Manager', 5), ('AM', N'Account Manager', 5),
 ('SC',   N'SAP Consultant', 3), ('SSC', N'Senior SAP Consultant', 4),
 ('DM',   N'Delivery Manager', 6), ('DIR', N'Director', 8);

INSERT INTO hr.Departments (Code, Name) VALUES
 ('SAP',   N'SAP Practice'), ('WEB', N'Web & Application Development'),
 ('SALES', N'Sales & Business Development'), ('HR', N'Human Resources'),
 ('FIN',   N'Finance & Accounts'), ('ADM', N'Administration');

INSERT INTO core.AppSettings (SettingKey, SettingValue, Description) VALUES
 ('Payroll.TemplateVersion',      '1.0',  N'Accepted payroll Excel template version'),
 ('Payroll.MakerCheckerEnabled',  'true', N'Commit must be by a different user than the uploader'),
 ('Payroll.PdfPasswordEnabled',   'true', N'Password-protect payslip PDFs'),
 ('Resume.ComplianceDays',        '30',   N'Days after which a resume is no longer Compliant'),
 ('Resume.OverdueDays',           '45',   N'Days after which a resume is Overdue'),
 ('Resume.ReminderDayOfMonth',    '25',   N'Day of month for the resume reminder job'),
 ('Leave.BackdateLimitDays',      '30',   N'Maximum backdating allowed on a leave application'),
 ('Leave.ApprovalEscalationDays', '3',    N'Escalate pending approvals after N days'),
 ('Sales.DormancyDays',           '90',   N'Open leads untouched for N days become Dormant'),
 ('Sales.AutoConvertEnquiries',   'true', N'Automatically convert website enquiries to leads'),
 ('Security.SessionMinutes',      '15',   N'Access token lifetime'),
 ('Security.RefreshDays',         '7',    N'Refresh token lifetime');
GO


/*------------------------------------------------------------------------------
  SECTION 11 - SECURITY (least privilege)
  Run after creating the SQL logins on the server.
------------------------------------------------------------------------------*/
/*
CREATE USER svc_ivconnect_app      FOR LOGIN svc_ivconnect_app;
CREATE USER svc_ivconnect_report   FOR LOGIN svc_ivconnect_report;

CREATE ROLE ivc_app_role;
CREATE ROLE ivc_report_role;

GRANT SELECT, INSERT, UPDATE ON SCHEMA::core    TO ivc_app_role;
GRANT SELECT, INSERT, UPDATE ON SCHEMA::hr      TO ivc_app_role;
GRANT SELECT, INSERT, UPDATE ON SCHEMA::payroll TO ivc_app_role;
GRANT SELECT, INSERT, UPDATE ON SCHEMA::[leave] TO ivc_app_role;
GRANT SELECT, INSERT, UPDATE ON SCHEMA::sales   TO ivc_app_role;
GRANT SELECT, EXECUTE          ON SCHEMA::hr    TO ivc_app_role;

-- Audit is append-only for the application
GRANT INSERT, SELECT ON audit.AuditLogs TO ivc_app_role;
DENY  UPDATE, DELETE ON audit.AuditLogs TO ivc_app_role;

-- Payslips are never deleted
DENY  DELETE ON payroll.Payslips           TO ivc_app_role;
DENY  DELETE ON payroll.PayslipComponents  TO ivc_app_role;
-- Leave ledger is append-only
DENY  UPDATE, DELETE ON [leave].LeaveBalanceLedger TO ivc_app_role;

GRANT SELECT ON [leave].vw_LeaveBalance      TO ivc_report_role;
GRANT SELECT ON hr.vw_ResumeCompliance       TO ivc_report_role;
GRANT SELECT ON payroll.vw_PayslipRegister   TO ivc_report_role;
GRANT SELECT ON sales.vw_PipelineSummary     TO ivc_report_role;

ALTER ROLE ivc_app_role    ADD MEMBER svc_ivconnect_app;
ALTER ROLE ivc_report_role ADD MEMBER svc_ivconnect_report;
*/

/*==============================================================================
  END OF SCRIPT
  Post-deployment checklist:
    [ ] TDE enabled and certificate backed up to a separate secure location
    [ ] Full + differential + 15-minute log backup jobs scheduled and verified
    [ ] DBCC CHECKDB weekly
    [ ] Index maintenance / statistics update job (Ola Hallengren scripts)
    [ ] Application, migrator and report logins created with least privilege
    [ ] sa account disabled or renamed; SQL Browser disabled if not required
    [ ] Port 1433 firewalled to application-tier addresses only
==============================================================================*/
