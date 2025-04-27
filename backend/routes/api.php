<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\GameController;
use App\Http\Controllers\Api\InvitationController;
use App\Http\Controllers\Api\GamePlayController;
use App\Http\Controllers\Api\LeaderboardController;
use App\Http\Controllers\Api\NotificationController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// Public routes
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// Protected routes
Route::middleware('auth:sanctum')->group(function () {
    // Authentication
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/profile', [AuthController::class, 'profile']);
    
    // Games
    Route::get('/games', [GameController::class, 'index']);
    Route::post('/games', [GameController::class, 'store']);
    Route::get('/games/{game}', [GameController::class, 'show']);
    Route::get('/my-games', [GameController::class, 'myGames']);
    
    // Invitations
    Route::post('/invitations', [InvitationController::class, 'send']);
    Route::get('/invitations', [InvitationController::class, 'myInvitations']);
    Route::put('/invitations/{invitation}/respond', [InvitationController::class, 'respond']);
    
    // Game Play
    Route::get('/play/{game}', [GamePlayController::class, 'play']);
    Route::post('/play/{game}/submit', [GamePlayController::class, 'submit']);
    
    // Leaderboard
    Route::get('/leaderboard', [LeaderboardController::class, 'global']);
    Route::get('/leaderboard/game/{game}', [LeaderboardController::class, 'game']);
    
    // Notifications
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::put('/notifications/{notification}/read', [NotificationController::class, 'markAsRead']);
    Route::put('/notifications/read-all', [NotificationController::class, 'markAllAsRead']);
});