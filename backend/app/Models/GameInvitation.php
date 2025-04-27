<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class GameInvitation extends Model
{
    use HasFactory;

    protected $fillable = [
        'game_id',
        'sender_id',
        'receiver_id',
        'status',
    ];

    public function game()
    {
        return $this->belongsTo(Game::class);
    }

    public function sender()
    {
        return $this->belongsTo(User::class, 'sender_id');
    }

    public function receiver()
    {
        return $this->belongsTo(User::class, 'receiver_id');
    }
}
