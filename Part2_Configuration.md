Preview
# 🛠️ Part 2: AD Users, OUs, Groups, and GPO Configuration

In this section, we create Organizational Units, add user accounts and groups, and apply Group Policy Objects (GPOs) to manage security and configurations.

---

## 🧱 OU Structure

- `OU=Secora Users`
- `OU=Secora Computers`
- `OU=Secora Service Accounts`

---

## 👥 Create Users from CSV

Use `create-users.ps1` to generate users in bulk with attributes like display name, email, and password.

---

## 👥 Create Security Groups

Groups like `HR`, `IT`, and `Finance` are created using `bulk-group-creation.ps1`.

---

## 🔐 Group Policy Objects

Example policies applied:

- Password complexity enforcement
- Lockout threshold and duration
- Folder redirection (Desktop/Documents)

```powershell
New-GPO -Name "Secora - Password Policy"
New-GPLink -Name "Secora - Password Policy" -Target "OU=Secora Users,DC=secora,DC=lab"
