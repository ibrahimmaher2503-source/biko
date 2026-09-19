$ErrorActionPreference = 'Stop'

$migration = Get-Content -LiteralPath "$PSScriptRoot\..\supabase\migrations\202608290001_foundation.sql" -Raw
$requiredStatements = @(
    'create table public.profiles',
    'create table public.offices',
    'create table public.office_members',
    'create table public.drivers',
    'create table public.motorcycles',
    'create table public.driver_documents',
    'create table public.service_types',
    'create table public.roles',
    'create table public.permissions',
    'create table public.role_permissions',
    'create table public.user_roles',
    'drivers_office_ownership',
    'alter table public.profiles enable row level security',
    'create trigger auth_user_created'
)

foreach ($statement in $requiredStatements) {
    if (-not $migration.Contains($statement)) {
        throw "Missing foundation statement: $statement"
    }
}

$implementationFiles = Get-ChildItem -File -Recurse -Path @(
    "$PSScriptRoot\..\apps\user_app\lib",
    "$PSScriptRoot\..\apps\driver_app\lib",
    "$PSScriptRoot\..\apps\dashboard\src",
    "$PSScriptRoot\..\packages\app_core\lib",
    "$PSScriptRoot\..\supabase\migrations"
)

# Product policy permits one final Delivery Confirmation Code, but forbids
# authentication/phone OTP flows. Keep this gate focused on executable APIs.
$forbiddenAuthOtp = 'signInWithOtp|verifyOTP|phone[_ -]?otp|sms[_ -]?otp|auth[_ -]?otp|login[_ -]?otp'
if ($implementationFiles | Select-String -Pattern $forbiddenAuthOtp -CaseSensitive:$false) {
    throw 'Forbidden authentication/phone OTP implementation detected.'
}

Write-Output 'Foundation structure checks passed.'
