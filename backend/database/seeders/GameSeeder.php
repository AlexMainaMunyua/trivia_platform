<?php

namespace Database\Seeders;

use App\Models\Game;
use App\Models\Question;
use App\Models\User;
use Illuminate\Database\Seeder;

class GameSeeder extends Seeder
{
    public function run(): void
    {
        $users = User::all();

        foreach ($users as $user) {
            $game = Game::create([
                'title' => 'General Knowledge Quiz ' . rand(1, 100),
                'description' => 'Test your general knowledge with this fun quiz!',
                'creator_id' => $user->id,
            ]);

            $questions = [
                [
                    'question' => 'What is the capital of France?',
                    'option_a' => 'London',
                    'option_b' => 'Paris',
                    'option_c' => 'Berlin',
                    'option_d' => 'Madrid',
                    'correct_answer' => 'B',
                ],
                [
                    'question' => 'Which planet is known as the Red Planet?',
                    'option_a' => 'Venus',
                    'option_b' => 'Jupiter',
                    'option_c' => 'Mars',
                    'option_d' => 'Saturn',
                    'correct_answer' => 'C',
                ],
                [
                    'question' => 'Who painted the Mona Lisa?',
                    'option_a' => 'Vincent van Gogh',
                    'option_b' => 'Pablo Picasso',
                    'option_c' => 'Leonardo da Vinci',
                    'option_d' => 'Michelangelo',
                    'correct_answer' => 'C',
                ],
                [
                    'question' => 'What is the largest ocean on Earth?',
                    'option_a' => 'Atlantic Ocean',
                    'option_b' => 'Indian Ocean',
                    'option_c' => 'Arctic Ocean',
                    'option_d' => 'Pacific Ocean',
                    'correct_answer' => 'D',
                ],
                [
                    'question' => 'Which country invented pizza?',
                    'option_a' => 'Italy',
                    'option_b' => 'Greece',
                    'option_c' => 'United States',
                    'option_d' => 'Spain',
                    'correct_answer' => 'A',
                ],
            ];

            foreach ($questions as $questionData) {
                Question::create(array_merge(
                    ['game_id' => $game->id],
                    $questionData
                ));
            }
        }
    }
}