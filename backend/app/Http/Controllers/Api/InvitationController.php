<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\GameInvitation;
use App\Models\User;
use App\Models\Notification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class InvitationController extends Controller
{
    public function send(Request $request)
    {
        $validated = $request->validate([
            'game_id' => 'required|exists:games,id',
            'receiver_identifier' => 'required|string',
        ]);

        $receiver = User::where('email', $validated['receiver_identifier'])
                       ->orWhere('username', $validated['receiver_identifier'])
                       ->first();

        if (!$receiver) {
            return response()->json(['error' => 'User not found'], 404);
        }

        $invitation = GameInvitation::create([
            'game_id' => $validated['game_id'],
            'sender_id' => Auth::id(),
            'receiver_id' => $receiver->id,
        ]);

        // Create notification
        Notification::create([
            'user_id' => $receiver->id,
            'type' => 'game_invitation',
            'message' =>  Auth::user()->name . ' invited you to play a trivia game',
            'data' => ['invitation_id' => $invitation->id],
        ]);

        return response()->json($invitation, 201);
    }

    public function myInvitations()
    {
        $invitations = GameInvitation::where('receiver_id',  Auth::id())
                                   ->with(['game', 'sender'])
                                   ->orderBy('created_at', 'desc')
                                   ->get();

        return response()->json($invitations);
    }

    public function respond(Request $request, GameInvitation $invitation)
    {
        if ($invitation->receiver_id !== Auth::id()) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'status' => 'required|in:accepted,declined',
        ]);

        $invitation->update(['status' => $validated['status']]);

        // Notify sender
        Notification::create([
            'user_id' => $invitation->sender_id,
            'type' => 'invitation_response',
            'message' => Auth::user()->name . ' ' . $validated['status'] . ' your game invitation',
            'data' => ['invitation_id' => $invitation->id],
        ]);

        return response()->json($invitation);
    }
}