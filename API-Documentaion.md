# API Documentation

This document provides detailed information about the APIs available in the microservices application.
It is generated and may be not up-to-date

## Table of Contents

- [Authentication](#authentication)
- [User Service API](#user-service-api)
- [Location Service API](#location-service-api)
- [Review Service API](#review-service-api)
- [Error Handling](#error-handling)

## Authentication

Most endpoints require authentication using JSON Web Tokens (JWT). To authenticate:

1. Make a POST request to `/api/auth/login` with valid credentials
2. Receive a JWT token in the response
3. Include the token in subsequent requests in the Authorization header:
   ```
   Authorization: Bearer <your_token>
   ```

### Token Claims

The JWT token includes the following claims:
- `sub`: User ID (GUID)
- `email`: User email
- `username`: Username
- `role`: User role (Regular, Admin, SuperAdmin)
- `jti`: Unique token ID
- `exp`: Expiration time

## User Service API

Base URL: `http://localhost:5280/api`

### Authentication

#### Login

```
POST /auth/login
```

Request:
```json
{
  "username": "johndoe",
  "password": "P@ssw0rd123!"
}
```

Response (200 OK):
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### User Management

#### Get All Users

```
GET /users
```

Authorization: Required (Admin or SuperAdmin)

Response (200 OK):
```json
[
  {
    "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "username": "johndoe",
    "email": "john@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "role": 0,
    "createdAt": "2025-03-15T14:30:00Z",
    "lastLoginDate": "2025-03-19T09:45:00Z"
  },
  ...
]
```

#### Get User by ID

```
GET /users/{id}
```

Authorization: Required

Response (200 OK):
```json
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "username": "johndoe",
  "email": "john@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "role": 0,
  "createdAt": "2025-03-15T14:30:00Z",
  "lastLoginDate": "2025-03-19T09:45:00Z"
}
```

#### Get User by Email

```
GET /users/by-email/{email}
```

Authorization: Required (Admin or SuperAdmin)

Response (200 OK):
```json
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "username": "johndoe",
  "email": "john@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "role": 0,
  "createdAt": "2025-03-15T14:30:00Z",
  "lastLoginDate": "2025-03-19T09:45:00Z"
}
```

#### Get User by Username

```
GET /users/by-username/{username}
```

Authorization: Required (Admin or SuperAdmin)

Response (200 OK):
```json
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "username": "johndoe",
  "email": "john@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "role": 0,
  "createdAt": "2025-03-15T14:30:00Z",
  "lastLoginDate": "2025-03-19T09:45:00Z"
}
```

#### Create User

```
POST /users
```

Authorization: Not required

Request:
```json
{
  "username": "johndoe",
  "email": "john@example.com",
  "password": "P@ssw0rd123!",
  "firstName": "John",
  "lastName": "Doe",
  "role": 0
}
```

Role values:
- 0: Regular
- 1: Admin
- 2: SuperAdmin

Response (201 Created):
```json
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "username": "johndoe",
  "email": "john@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "role": 0,
  "createdAt": "2025-03-20T10:15:30Z",
  "lastLoginDate": null
}
```

#### Update User

```
PUT /users
```

Authorization: Required

Request:
```json
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "firstName": "John",
  "lastName": "Smith",
  "email": "john.smith@example.com",
  "role": 0
}
```

Response (200 OK):
```json
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "username": "johndoe",
  "email": "john.smith@example.com",
  "firstName": "John",
  "lastName": "Smith",
  "role": 0,
  "createdAt": "2025-03-15T14:30:00Z",
  "lastLoginDate": "2025-03-19T09:45:00Z"
}
```

#### Delete User

```
DELETE /users/{id}
```

Authorization: Required (Admin or SuperAdmin)

Response (204 No Content)

## Location Service API

Base URL: `http://localhost:5282/api`

### Location Management

#### Get All Locations

```
GET /locations
```

Authorization: Not required

Response (200 OK):
```json
[
  {
    "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "name": "Central Park",
    "latitude": 40.785091,
    "longitude": -73.968285,
    "address": "Central Park",
    "city": "New York",
    "state": "NY",
    "country": "USA",
    "postalCode": "10022",
    "createdAt": "2025-03-10T08:15:30Z",
    "details": [
      {
        "id": "4fa85f64-5717-4562-b3fc-2c963f66afa7",
        "propertyName": "type",
        "propertyValue": "park"
      },
      {
        "id": "5fa85f64-5717-4562-b3fc-2c963f66afa8",
        "propertyName": "size",
        "propertyValue": "843 acres"
      }
    ]
  },
  ...
]
```

#### Get Location by ID

```
GET /locations/{id}
```

Authorization: Not required

Response (200 OK):
```json
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "name": "Central Park",
  "latitude": 40.785091,
  "longitude": -73.968285,
  "address": "Central Park",
  "city": "New York",
  "state": "NY",
  "country": "USA",
  "postalCode": "10022",
  "createdAt": "2025-03-10T08:15:30Z",
  "details": [
    {
      "id": "4fa85f64-5717-4562-b3fc-2c963f66afa7",
      "propertyName": "type",
      "propertyValue": "park"
    },
    {
      "id": "5fa85f64-5717-4562-b3fc-2c963f66afa8",
      "propertyName": "size",
      "propertyValue": "843 acres"
    }
  ]
}
```

#### Find Nearby Locations

```
GET /locations/nearby?latitude=40.7128&longitude=-74.0060&radiusKm=5
```

Authorization: Not required

Response (200 OK):
```json
[
  {
    "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "name": "Central Park",
    "latitude": 40.785091,
    "longitude": -73.968285,
    "address": "Central Park",
    "city": "New York",
    "state": "NY",
    "country": "USA",
    "postalCode": "10022",
    "createdAt": "2025-03-10T08:15:30Z",
    "details": [...]
  },
  ...
]
```

#### Find Locations by Property

```
GET /locations/by-property?key=type&value=park
```

Authorization: Not required

Response (200 OK):
```json
[
  {
    "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "name": "Central Park",
    "latitude": 40.785091,
    "longitude": -73.968285,
    "address": "Central Park",
    "city": "New York",
    "state": "NY",
    "country": "USA",
    "postalCode": "10022",
    "createdAt": "2025-03-10T08:15:30Z",
    "details": [...]
  },
  ...
]
```

#### Create Location

```
POST /locations
```

Authorization: Required

Request:
```json
{
  "name": "Empire State Building",
  "latitude": 40.748817,
  "longitude": -73.985428,
  "address": "350 Fifth Avenue",
  "city": "New York",
  "state": "NY",
  "country": "USA",
  "postalCode": "10118",
  "details": [
    {
      "propertyName": "type",
      "propertyValue": "building"
    },
    {
      "propertyName": "height",
      "propertyValue": "381 meters"
    }
  ]
}
```

Response (201 Created):
```json
{
  "id": "6fa85f64-5717-4562-b3fc-2c963f66afa9",
  "name": "Empire State Building",
  "latitude": 40.748817,
  "longitude": -73.985428,
  "address": "350 Fifth Avenue",
  "city": "New York",
  "state": "NY",
  "country": "USA",
  "postalCode": "10118",
  "createdAt": "2025-03-20T10:25:30Z",
  "details": [
    {
      "id": "7fa85f64-5717-4562-b3fc-2c963f66afaa",
      "propertyName": "type",
      "propertyValue": "building"
    },
    {
      "id": "8fa85f64-5717-4562-b3fc-2c963f66afab",
      "propertyName": "height",
      "propertyValue": "381 meters"
    }
  ]
}
```

#### Update Location

```
PUT /locations
```

Authorization: Required

Request:
```json
{
  "id": "6fa85f64-5717-4562-b3fc-2c963f66afa9",
  "name": "Empire State Building",
  "address": "350 Fifth Avenue",
  "city": "New York",
  "state": "NY",
  "country": "USA",
  "postalCode": "10118"
}
```

Response (200 OK):
```json
{
  "id": "6fa85f64-5717-4562-b3fc-2c963f66afa9",
  "name": "Empire State Building",
  "latitude": 40.748817,
  "longitude": -73.985428,
  "address": "350 Fifth Avenue",
  "city": "New York",
  "state": "NY",
  "country": "USA",
  "postalCode": "10118",
  "createdAt": "2025-03-20T10:25:30Z",
  "details": [...]
}
```

#### Delete Location

```
DELETE /locations/{id}
```

Authorization: Required (Admin or SuperAdmin)

Response (204 No Content)

### Location Details Management

#### Add Location Detail

```
POST /locations/{locationId}/details
```

Authorization: Required

Request:
```json
{
  "propertyName": "yearBuilt",
  "propertyValue": "1931"
}
```

Response (200 OK):
```json
{
  "id": "6fa85f64-5717-4562-b3fc-2c963f66afa9",
  "name": "Empire State Building",
  "latitude": 40.748817,
  "longitude": -73.985428,
  "address": "350 Fifth Avenue",
  "city": "New York",
  "state": "NY",
  "country": "USA",
  "postalCode": "10118",
  "createdAt": "2025-03-20T10:25:30Z",
  "details": [
    {
      "id": "7fa85f64-5717-4562-b3fc-2c963f66afaa",
      "propertyName": "type",
      "propertyValue": "building"
    },
    {
      "id": "8fa85f64-5717-4562-b3fc-2c963f66afab",
      "propertyName": "height",
      "propertyValue": "381 meters"
    },
    {
      "id": "9fa85f64-5717-4562-b3fc-2c963f66afac",
      "propertyName": "yearBuilt",
      "propertyValue": "1931"
    }
  ]
}
```

#### Update Location Detail

```
PUT /locations/{locationId}/details/{detailId}
```

Authorization: Required

Request:
```json
{
  "propertyName": "height",
  "propertyValue": "381.1 meters"
}
```

Response (200 OK):
```json
{
  "id": "6fa85f64-5717-4562-b3fc-2c963f66afa9",
  "name": "Empire State Building",
  "latitude": 40.748817,
  "longitude": -73.985428,
  "address": "350 Fifth Avenue",
  "city": "New York",
  "state": "NY",
  "country": "USA",
  "postalCode": "10118",
  "createdAt": "2025-03-20T10:25:30Z",
  "details": [
    {
      "id": "7fa85f64-5717-4562-b3fc-2c963f66afaa",
      "propertyName": "type",
      "propertyValue": "building"
    },
    {
      "id": "8fa85f64-5717-4562-b3fc-2c963f66afab",
      "propertyName": "height",
      "propertyValue": "381.1 meters"
    }
  ]
}
```

#### Remove Location Detail

```
DELETE /locations/{locationId}/details/{detailId}
```

Authorization: Required

Response (200 OK):
```json
{
  "id": "6fa85f64-5717-4562-b3fc-2c963f66afa9",
  "name": "Empire State Building",
  "latitude": 40.748817,
  "longitude": -73.985428,
  "address": "350 Fifth Avenue",
  "city": "New York",
  "state": "NY",
  "country": "USA",
  "postalCode": "10118",
  "createdAt": "2025-03-20T10:25:30Z",
  "details": [
    {
      "id": "7fa85f64-5717-4562-b3fc-2c963f66afaa",
      "propertyName": "type",
      "propertyValue": "building"
    }
  ]
}
```

## Review Service API

Base URL: `http://localhost:5284/api`

### Review Management

#### Get All Reviews

```
GET /reviews
```

Authorization: Not required

Response (200 OK):
```json
[
  {
    "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "userId": "1fa85f64-5717-4562-b3fc-2c963f66afa1",
    "locationId": "6fa85f64-5717-4562-b3fc-2c963f66afa9",
    "rating": 5,
    "content": "Amazing building with a fantastic view from the observation deck!",
    "createdAt": "2025-03-20T11:15:30Z",
    "updatedAt": null
  },
  ...
]
```

#### Get Review by ID

```
GET /reviews/{id}
```

Authorization: Not required

Response (200 OK):
```json
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "userId": "1fa85f64-5717-4562-b3fc-2c963f66afa1",
  "locationId": "6fa85f64-5717-4562-b3fc-2c963f66afa9",
  "rating": 5,
  "content": "Amazing building with a fantastic view from the observation deck!",
  "createdAt": "2025-03-20T11:15:30Z",
  "updatedAt": null
}
```

#### Get Reviews by User ID

```
GET /reviews/by-user/{userId}
```

Authorization: Not required

Response (200 OK):
```json
[
  {
    "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "userId": "1fa85f64-5717-4562-b3fc-2c963f66afa1",
    "locationId": "6fa85f64-5717-4562-b3fc-2c963f66afa9",
    "rating": 5,
    "content": "Amazing building with a fantastic view from the observation deck!",
    "createdAt": "2025-03-20T11:15:30Z",
    "updatedAt": null
  },
  ...
]
```

#### Get Reviews by Location ID

```
GET /reviews/by-location/{locationId}
```

Authorization: Not required

Response (200 OK):
```json
[
  {
    "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "userId": "1fa85f64-5717-4562-b3fc-2c963f66afa1",
    "locationId": "6fa85f64-5717-4562-b3fc-2c963f66afa9",
    "rating": 5,
    "content": "Amazing building with a fantastic view from the observation deck!",
    "createdAt": "2025-03-20T11:15:30Z",
    "updatedAt": null
  },
  ...
]
```

#### Get Average Rating for Location

```
GET /reviews/average-rating/{locationId}
```

Authorization: Not required

Response (200 OK):
```json
{
  "locationId": "6fa85f64-5717-4562-b3fc-2c963f66afa9",
  "averageRating": 4.7
}
```

#### Create Review

```
POST /reviews
```

Authorization: Required

Request:
```json
{
  "locationId": "6fa85f64-5717-4562-b3fc-2c963f66afa9",
  "rating": 4,
  "content": "Great place to visit! Highly recommended."
}
```

Response (201 Created):
```json
{
  "id": "7fa85f64-5717-4562-b3fc-2c963f66afad",
  "userId": "1fa85f64-5717-4562-b3fc-2c963f66afa1",
  "locationId": "6fa85f64-5717-4562-b3fc-2c963f66afa9",
  "rating": 4,
  "content": "Great place to visit! Highly recommended.",
  "createdAt": "2025-03-20T15:20:30Z",
  "updatedAt": null
}
```

#### Update Review

```
PUT /reviews
```

Authorization: Required

Request:
```json
{
  "id": "7fa85f64-5717-4562-b3fc-2c963f66afad",
  "rating": 5,
  "content": "Great place to visit! The experience was even better than expected. Highly recommended."
}
```

Response (200 OK):
```json
{
  "id": "7fa85f64-5717-4562-b3fc-2c963f66afad",
  "userId": "1fa85f64-5717-4562-b3fc-2c963f66afa1",
  "locationId": "6fa85f64-5717-4562-b3fc-2c963f66afa9",
  "rating": 5,
  "content": "Great place to visit! The experience was even better than expected. Highly recommended.",
  "createdAt": "2025-03-20T15:20:30Z",
  "updatedAt": "2025-03-20T16:05:15Z"
}
```

#### Delete Review

```
DELETE /reviews/{id}
```

Authorization: Required

Response (204 No Content)

## Error Handling

All APIs follow a consistent error handling approach:

### Error Response Format

```json
{
  "statusCode": 400,
  "message": "Error message details"
}
```

### Common HTTP Status Codes

- **200 OK**: The request was successful
- **201 Created**: The resource was successfully created
- **204 No Content**: The request was successful, but there is no content to return
- **400 Bad Request**: The request was invalid or cannot be served
- **401 Unauthorized**: Authentication is required or failed
- **403 Forbidden**: The authenticated user does not have the required permissions
- **404 Not Found**: The requested resource does not exist
- **500 Internal Server Error**: An unexpected error occurred on the server

### Validation Errors

When validation fails, a 400 Bad Request response is returned with details about the validation errors:

```json
{
  "statusCode": 400,
  "message": "Validation error",
  "errors": {
    "username": [
      "Username must be at least 3 characters"
    ],
    "password": [
      "Password must contain at least one uppercase letter",
      "Password must contain at least one number"
    ]
  }
}
```

### Authentication Errors

When authentication fails, a 401 Unauthorized response is returned:

```json
{
  "statusCode": 401,
  "message": "Invalid username or password"
}
```

Or when the token is invalid or expired:

```json
{
  "statusCode": 401,
  "message": "Invalid or expired token"
}
```

### Authorization Errors

When the authenticated user does not have permission to access a resource:

```json
{
  "statusCode": 403,
  "message": "You do not have permission to access this resource"
}
```
