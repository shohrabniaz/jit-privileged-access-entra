# Just-in-time privileged access for a small IT team

Fictional case: Coastal Managed IT, the same laboratory directory used for the joiner-mover-leaver work. Entra ID Free only. No employer tenant and no client tenant.

## Question

Standing membership of `SG-CMIT-Privileged-Admins` stays on after the job is done. Entra Privileged Identity Management can time-limit that access, and it needs a paid licence. This pilot asks whether a small team can get the same control on the free directory: a named approver, a reason, a maximum of 120 minutes, and removal when the window ends.

## What the scripts do

1. `01_Inventory_Standing_Privilege.ps1` lists privileged-group members. A member with no open grant is standing privilege. A disabled member is the orphan case from the earlier lab.
2. `02_Grant_JIT_Elevation.ps1` adds an enabled engineer for 15 to 120 minutes and writes the reason and approver. It refuses a disabled account, a non-engineer, and anyone who already has standing privileged membership.
3. `03_Revoke_Expired_JIT.ps1` removes the group membership when `ExpiresUtc` has passed.
4. `04_Measure_Exposure.ps1` compares one always-on admin for 7 days (168 hours) with the minutes that were actually granted.

## Run

From this folder, in Windows PowerShell, after `Connect-MgGraph` to tenant `a76a68a8-6243-4b0e-b11c-98e815e91820`:

```powershell
.\01_Inventory_Standing_Privilege.ps1
.\02_Grant_JIT_Elevation.ps1 -UserPrincipalName "mover.test01@niazkhanghostgmail.onmicrosoft.com" -Minutes 15 -Reason "Lab pilot of time-boxed admin" -Approver "Lab supervisor"
.\03_Revoke_Expired_JIT.ps1
.\04_Measure_Exposure.ps1
```

Run the revoke script after the 15 minutes, or it will report that nothing has expired yet. Do not point these scripts at any directory other than the laboratory tenant. The tenant check stops them if the signed-in directory does not match.

## Limits

This is not Privileged Identity Management. There is no second-person click in the portal, no access review, and no just-in-time role in Azure Resource Manager. The approver is a name stored in the JSON file. The exposure percentage is a model of standing access against granted minutes, not a study of a live helpdesk. The next measurement is to run one real grant and one expiry in this tenant and keep those two JSON files.
