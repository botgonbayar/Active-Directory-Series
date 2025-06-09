# 📁 Part 3: File Sharing and Access Management

This section covers creating shared folders for departments, assigning NTFS and share-level permissions to security groups, and managing service accounts for task automation.

---

## 📂 Department Shared Folders

We’ve created the following shared folders on the domain controller:

- `\\Secora-DC01\HR_Share`
- `\\Secora-DC01\Finance_Share`
- `\\Secora-DC01\IT_Share`

Use the script `setup-file-share.ps1` to automate this process.

---

## 🔐 NTFS & Share Permissions

Each folder is protected by assigning access to specific Active Directory groups.

| Share            | Group         | Access Type    |
|------------------|---------------|----------------|
| HR_Share         | HR Group      | Modify         |
| Finance_Share    | Finance Group | Read           |
| IT_Share         | IT Group      | Full Control   |

---

## 💻 Example: Creating a Secure Share (Script Excerpt)

```powershell
New-Item -Path "C:\Shares\HR_Share" -ItemType Directory
New-SmbShare -Name "HR_Share" -Path "C:\Shares\HR_Share" -FullAccess "Secora\\HR Group"
