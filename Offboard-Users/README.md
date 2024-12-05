# User Offboarding PowerShell Scripts

This directory contains the main user offboarding script and its supporting utility modules for managing the automated offboarding process in Active Directory and Exchange environments.

## Main Script

### `Disable-UserOffboarding.ps1`
The primary script that orchestrates the complete user offboarding process.

#### Features
- Disables user accounts in Active Directory
- Moves disabled accounts to a designated OU
- Updates account description with disable date
- Removes user from security groups (preserves Domain Users)
- Hides user from Global Address List (GAL)
- Disables ActiveSync for mobile devices
- Removes calendar meetings
- Sets up mailbox delegation to user's manager

#### Usage
```powershell
Start-UserOffboarding -UserName "john.doe" -DisabledOU "OU=Disabled Users,DC=contoso,DC=com"
```

#### Parameters
- `UserName`: The username of the account to be offboarded (mandatory)
- `DisabledOU`: The Distinguished Name of the OU where disabled accounts should be moved (mandatory)

## Directory Structure
```
src/
├── Disable-UserOffboarding.ps1    # Main offboarding script
├── utils/                         # Utility functions directory
│   ├── adUtils.ps1               # Active Directory utilities
│   ├── exchangeUtils.ps1         # Exchange management utilities
│   └── userManagement.ps1        # User account management utilities
└── README.md                     # This documentation file
```

## Prerequisites
- Windows PowerShell 5.1 or later
- Required PowerShell Modules:
  - ActiveDirectory
  - ExchangeOnlineManagement
- Administrative permissions:
  - Domain Admin or delegated AD permissions
  - Exchange Administrator rights
  - Appropriate OU permissions

## Error Handling
The script implements comprehensive error handling:
- Each operation is wrapped in try-catch blocks
- Detailed error messages are logged
- Script execution stops on critical failures
- Warning messages for non-critical issues

## Logging
- All operations are logged using Write-Host and Write-Error
- Success/failure status is reported for each step
- Detailed error messages for troubleshooting

## Security Considerations
- Script requires appropriate administrative privileges
- Implements checks before critical operations
- Maintains security group membership documentation
- Ensures proper mailbox delegation

## Best Practices for Modifications
1. Test all changes in a non-production environment
2. Maintain modular structure
3. Update documentation when adding features
4. Follow PowerShell best practices
5. Implement proper error handling
6. Add appropriate logging for new functionality

## Support
For issues or enhancements:
1. Check error logs
2. Verify prerequisites
3. Ensure proper permissions
4. Test in isolated environment
5. Document any modifications
