<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\GameResult;
use App\Models\Game;
use Illuminate\Http\Request;

class LeaderboardController extends Controller
{
    public function global()
    {
        $leaderboard = GameResult::with(['user', 'game'])
                                ->selectRaw('user_id, SUM(score) as total_score, COUNT(*) as games_played')
                                ->groupBy('user_id')
                                ->orderByDesc('total_score')
                                ->limit(10)
                                ->get();

        return response()->json($leaderboard);
    }

    public function game(Game $game)
    {
        $leaderboard = GameResult::where('game_id', $game->id)
                                ->with('user')
                                ->orderByDesc('score')
                                ->limit(10)
                                ->get();

        return response()->json($leaderboard);
    }
}