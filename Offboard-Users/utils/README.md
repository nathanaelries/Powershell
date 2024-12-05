# PowerShell Utility Functions

This directory contains utility functions used in the user offboarding process. Each file is focused on a specific domain of functionality to maintain clean separation of concerns and improve maintainability.

## Files Overview

### `adUtils.ps1`
Active Directory utility functions for managing user information and relationships.

Functions:
- `Get-UserManager`: Retrieves the manager of a specified user from Active Directory
  - Parameters:
    - `UserName`: The username to query (mandatory)
  - Returns: AD user object of the manager or null if not found

### `exchangeUtils.ps1`
Exchange-related utilities for managing mailboxes and calendar items.

Functions:
- `Remove-CalendarMeetings`: Removes all calendar meetings for a specified user
  - Parameters:
    - `UserEmail`: The email address of the user (mandatory)

- `Set-MailboxDelegation`: Sets up mailbox delegation permissions
  - Parameters:
    - `UserEmail`: The email address of the user being offboarded (mandatory)
    - `ManagerEmail`: The email address of the manager receiving delegation rights (mandatory)

### `userManagement.ps1`
Core user account management functions.

Functions:
- `Disable-UserAccount`: Disables a user account and moves it to the specified OU
  - Parameters:
    - `UserName`: The username to disable (mandatory)
    - `DisabledOU`: The OU path where disabled accounts should be moved (mandatory)
  - Returns: Boolean indicating success/failure

- `Remove-SecurityGroups`: Removes user from all security groups except Domain Users
  - Parameters:
    - `UserName`: The username to process (mandatory)

## Usage

These utility functions are designed to be imported and used by the main offboarding script. They should not be executed directly.

Example of importing the utilities:
```powershell
. ".\utils\adUtils.ps1"
. ".\utils\exchangeUtils.ps1"
. ".\utils\userManagement.ps1"
```

## Error Handling

All functions include proper error handling and logging:
- Errors are caught and logged using `Write-Error`
- Functions return appropriate status indicators (boolean/null) on failure
- Detailed error messages are provided for troubleshooting

## Dependencies

These utilities require:
- Active Directory PowerShell module
- Exchange Online Management PowerShell module
- Appropriate administrative permissions in both AD and Exchange

## Best Practices

When modifying these utilities:
1. Maintain single responsibility principle
2. Include proper error handling
3. Add appropriate logging
4. Keep functions focused and concise
5. Document any changes or new parameters
6. Test thoroughly before deployment
