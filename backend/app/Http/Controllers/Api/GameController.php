<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Game;
use App\Models\Question;
use App\Models\Notification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Auth;    

class GameController extends Controller
{
    public function index()
    {
        $games = Game::with('creator', 'questions')
                    ->where('is_active', true)
                    ->orderBy('created_at', 'desc')
                    ->get();

        return response()->json($games);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'required|string',
            'questions' => 'required|array|min:5|max:10',
            'questions.*.question' => 'required|string',
            'questions.*.option_a' => 'required|string',
            'questions.*.option_b' => 'required|string',
            'questions.*.option_c' => 'required|string',
            'questions.*.option_d' => 'required|string',
            'questions.*.correct_answer' => 'required|in:A,B,C,D',
        ]);

        DB::beginTransaction();
        try {
            $game = Game::create([
                'title' => $validated['title'],
                'description' => $validated['description'],
                'creator_id' => Auth::id(),
            ]);

            foreach ($validated['questions'] as $questionData) {
                Question::create([
                    'game_id' => $game->id,
                    'question' => $questionData['question'],
                    'option_a' => $questionData['option_a'],
                    'option_b' => $questionData['option_b'],
                    'option_c' => $questionData['option_c'],
                    'option_d' => $questionData['option_d'],
                    'correct_answer' => $questionData['correct_answer'],
                ]);
            }

            DB::commit();
            return response()->json($game->load('questions'), 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['error' => 'Failed to create game'], 500);
        }
    }

    public function show(Game $game)
    {
        return response()->json($game->load(['creator', 'questions']));
    }

    public function myGames()
    {
        $games = Game::where('creator_id', Auth::id())
                    ->with('questions')
                    ->orderBy('created_at', 'desc')
                    ->get();

        return response()->json($games);
    }
}