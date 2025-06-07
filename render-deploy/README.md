# BizzyBuddy API

Backend API server for BizzyBuddy Flutter application.

## Features

- User authentication (register, login)
- JWT tokens for API security
- Video calling features (create, join, leave, end)
- Call history

## Deployment on Render

This repository is configured for easy deployment on Render.com.

### Environment Variables

- `PORT`: Port to run the server on (defaults to 5000)
- `JWT_SECRET`: Secret key for JWT token signing (defaults to a hardcoded value for development)

## API Endpoints

### Auth
- `POST /api/auth/register` - Register a new user
- `POST /api/auth/login` - Login a user
- `POST /api/auth/validate` - Validate a JWT token

### Video Calls
- `POST /api/calls` - Create a new call
- `GET /api/calls` - Get call history
- `POST /api/calls/:callId/join` - Join a call
- `POST /api/calls/:callId/leave` - Leave a call
- `POST /api/calls/:callId/end` - End a call

## Local Development

```bash
# Install dependencies
npm install

# Start server
npm start

# Start development server with hot reload
npm run dev
``` 