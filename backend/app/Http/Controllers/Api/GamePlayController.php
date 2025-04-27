<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Game;
use App\Models\GameResult;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;


class GamePlayController extends Controller
{
    public function play(Game $game)
    {
        // Check if user has access to play
        $hasAccess = $game->creator_id === Auth::id() ||
                    $game->invitations()
                         ->where('receiver_id',  Auth::id())
                         ->where('status', 'accepted')
                         ->exists();

        if (!$hasAccess) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        return response()->json($game->load('questions'));
    }

    public function submit(Request $request, Game $game)
    {
        $validated = $request->validate([
            'answers' => 'required|array',
            'answers.*' => 'required|in:A,B,C,D',
        ]);

        $questions = $game->questions;
        $score = 0;

        foreach ($questions as $index => $question) {
            if (isset($validated['answers'][$index]) && 
                $validated['answers'][$index] === $question->correct_answer) {
                $score++;
            }
        }

        $result = GameResult::create([
            'game_id' => $game->id,
            'user_id' => Auth::id(),
            'score' => $score,
            'completed_at' => now(),
        ]);

        return response()->json([
            'score' => $score,
            'total' => count($questions),
            'percentage' => round(($score / count($questions)) * 100, 2),
        ]);
    }
}