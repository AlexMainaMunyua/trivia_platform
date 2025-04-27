<?php

use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "web" middleware group. Make something great!
|
*/

// Since this is an API-only application, we can redirect all web requests to an info page
Route::get('/', function () {
    return response()->json([
        'name' => 'Trivia Platform API',
        'version' => '1.0.0',
        'documentation' => '/api/documentation',
        'api_endpoints' => '/api',
    ]);
});

// API documentation route (optional)
Route::get('/api/documentation', function () {
    return response()->json([
        'message' => 'Please import the Postman collection for full API documentation.',
        'postman_collection_url' => 'https://example.com/postman-collection.json',
    ]);
});