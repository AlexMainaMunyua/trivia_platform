# Gamification Trivia Platform

A full-stack trivia gaming platform built with Laravel (backend) and Flutter (frontend).

## Features

- User authentication (register/login)
- Create and manage trivia games (5-10 MCQs)
- Invite users to play games
- Play trivia games and track scores
- In-app notifications
- Leaderboards
- Game history

## Tech Stack

### Backend
- Laravel 10.x
- Laravel Sanctum for authentication
- MySQL database
- RESTful API architecture

### Frontend
- Flutter 3.x
- Provider for state management
- Material Design UI

## Setup Instructions

### Backend Setup

1. Clone the repository
```bash
git clone <repository-url>
cd backend
```

2. Install dependencies
```bash
composer install
```

3. Copy environment file
```bash
cp .env.example .env
```

4. Generate application key
```bash
php artisan key:generate
```

5. Configure database in `.env` file
```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=trivia_platform
DB_USERNAME=root
DB_PASSWORD=
```

6. Run migrations and seeders
```bash
php artisan migrate --seed
```

7. Start the development server
```bash
php artisan serve
```

The API will be available at `http://localhost:8000/api`

### Frontend Setup

1. Navigate to the Flutter directory
```bash
cd frontend
```

2. Install dependencies
```bash
flutter pub get
```

3. Update the API URL in `lib/services/api_service.dart`
```dart
static const String baseUrl = 'http://localhost:8000/api';
```

4. Run the app
```bash
flutter run
```

## Architecture Overview

### Backend Architecture

- **Controllers**: Handle HTTP requests and responses
- **Models**: Define database relationships and business logic
- **Migrations**: Database schema definitions
- **Routes**: API endpoint definitions
- **Middleware**: Authentication and request filtering

### Frontend Architecture

- **Models**: Data structures for API responses
- **Providers**: State management and business logic
- **Services**: API communication and local storage
- **Screens**: UI components and pages
- **Widgets**: Reusable UI components

## API Documentation

The API is documented using Postman. Import the `Trivia_Platform_API.postman_collection.json` file into Postman to view all endpoints and examples.

### Main API Endpoints

- `POST /api/register` - User registration
- `POST /api/login` - User login
- `GET /api/games` - List all games
- `POST /api/games` - Create a new game
- `POST /api/invitations` - Send game invitation
- `GET /api/play/{game}` - Get game for playing
- `POST /api/play/{game}/submit` - Submit game answers
- `GET /api/leaderboard` - Global leaderboard

## Time Spent

- Backend Development: 10 hours
- Frontend Development: 12 hours
- Testing & Documentation: 6 hours
- Total: 28 hours

## Assumptions

1. Users must register with a unique email and username
2. Games must have between 5-10 questions
3. All questions are multiple choice with 4 options (A, B, C, D)
4. Users can only play games they created or were invited to
5. Leaderboard shows top 10 scores for each game and globally
6. Notifications are handled within the app (no push notifications)

## Future Enhancements

1. Admin dashboard for managing users and games
2. Real-time leaderboard updates
3. Timer for gameplay
4. Firebase/Event System for notifications
5. More question types (true/false, fill in the blank)
6. Categories and tags for games
7. Achievement system
8. Social sharing features

## Demo Credentials

- Email: john@example.com
- Password: password123

## License

This project is licensed under the MIT License.