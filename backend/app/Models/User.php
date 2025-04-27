<?php

namespace App\Models;

use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
        'username',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
    ];

    public function createdGames()
    {
        return $this->hasMany(Game::class, 'creator_id');
    }

    public function gameResults()
    {
        return $this->hasMany(GameResult::class);
    }

    public function sentInvitations()
    {
        return $this->hasMany(GameInvitation::class, 'sender_id');
    }

    public function receivedInvitations()
    {
        return $this->hasMany(GameInvitation::class, 'receiver_id');
    }

    public function notifications()
    {
        return $this->hasMany(Notification::class);
    }
}