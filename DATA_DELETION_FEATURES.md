# Data Deletion Features - StartupWorld

This document outlines the new data deletion features added to the StartupWorld application.

## Features Added

### 1. Terms and Conditions Page
- **Location**: `lib/screens/terms_conditions_screen.dart`
- **Access**: Available in the app drawer for both staff and student users
- **Content**: Comprehensive terms covering data protection, user rights, and deletion procedures

### 2. Delete User Data Screen
- **Location**: `lib/screens/delete_user_data_screen.dart`
- **Access**: Available in the app drawer for both staff and student users
- **Features**:
  - Reason selection dropdown
  - Custom reason input (if "Other" is selected)
  - Optional feedback collection
  - Confirmation checkbox
  - Final confirmation dialog
  - Contact information for support

### 3. Public Data Deletion Portal
- **Location**: `web/data_deletion.html`
- **Access**: Publicly accessible via direct URL
- **URL**: `https://startupworld.com/data_deletion.html`
- **Features**:
  - No login required
  - Email-based identification
  - Same form fields as in-app deletion
  - Responsive design
  - Contact information

## How to Access

### In-App Access
1. Open the StartupWorld app
2. Log in with your credentials
3. Open the app drawer (hamburger menu)
4. Select "Terms & Conditions" or "Delete User Data"

### Public Access
1. Visit: `https://startupworld.com/data_deletion.html`
2. Fill out the form with your email and reason
3. Submit the deletion request

## API Integration

### New API Endpoints
- **Delete User Data**: `POST /Webservices/api3.php?action=delete_user_data`
- **Parameters**:
  - `user_id`: User identifier
  - `reason`: Selected reason for deletion
  - `feedback`: Optional user feedback
  - `custom_reason`: Custom reason if "Other" selected
  - `deletion_date`: Timestamp of deletion request

### Service Methods Added
- `AuthService.deleteUserData()`: Handles user data deletion
- `ApiService.deleteUserData()`: Makes API call to backend

## Data Collection

The deletion process collects the following information:
1. **Required**:
   - User identification (email or user ID)
   - Reason for deletion
   - Confirmation of understanding

2. **Optional**:
   - Custom reason (if "Other" selected)
   - Feedback about the service
   - Suggestions for improvement

## Privacy Compliance

The implementation follows GDPR and other privacy regulations:
- Clear information about data deletion
- Multiple access points for deletion requests
- Reason collection for service improvement
- Confirmation steps to prevent accidental deletion
- Contact information for support

## Security Features

- Confirmation dialogs to prevent accidental deletion
- Form validation for required fields
- Secure API communication
- User authentication for in-app deletion
- Email verification for public portal

## Support Information

Users can contact support through:
- **Email**: support@startupworld.com
- **Phone**: +1-555-0123
- **Response Time**: Within 24 hours

## Technical Implementation

### Files Modified
- `lib/main.dart`: Added routes for new screens
- `lib/widgets/app_drawer.dart`: Added menu items
- `lib/services/auth_service.dart`: Added deleteUserData method
- `lib/services/api_service.dart`: Added deleteUserData API call

### Files Created
- `lib/screens/terms_conditions_screen.dart`
- `lib/screens/delete_user_data_screen.dart`
- `web/data_deletion.html`

## Testing

To test the features:
1. **In-App Testing**:
   - Log in as staff or student
   - Navigate to app drawer
   - Test both Terms & Conditions and Delete User Data

2. **Public Portal Testing**:
   - Open `web/data_deletion.html` in browser
   - Test form validation
   - Test submission process

3. **API Testing**:
   - Verify API endpoints are accessible
   - Test with valid and invalid data
   - Check error handling

## Future Enhancements

Potential improvements:
- Email confirmation for deletion requests
- Deletion status tracking
- Bulk deletion for administrators
- Data export before deletion
- Integration with external privacy tools 