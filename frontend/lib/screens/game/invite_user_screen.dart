import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game.dart';
import '../../providers/game_provider.dart';

class InviteUserScreen extends StatefulWidget {
  final Game game;

  const InviteUserScreen({super.key, required this.game});

  @override
  State<InviteUserScreen> createState() => _InviteUserScreenState();
}

class _InviteUserScreenState extends State<InviteUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _sendInvitation() async {
    if (_formKey.currentState!.validate()) {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      await gameProvider.sendInvitation(
        widget.game.id,
        _identifierController.text,
      );

      if (gameProvider.error == null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invitation sent successfully!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(gameProvider.error!)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite User'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Invite user to: ${widget.game.title}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _identifierController,
                decoration: const InputDecoration(
                  labelText: 'Email or Username',
                  border: OutlineInputBorder(),
                  helperText: 'Enter the email or username of the user you want to invite',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email or username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Consumer<GameProvider>(
                builder: (context, gameProvider, child) {
                  return ElevatedButton(
                    onPressed: gameProvider.isLoading ? null : _sendInvitation,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: gameProvider.isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Send Invitation'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}