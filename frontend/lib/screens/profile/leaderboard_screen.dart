import 'package:flutter/material.dart';
import 'package:frontend/models/userScore.dart';
import 'package:provider/provider.dart';
import '../../models/game.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  List<UserScore> _leaderboard = [];
  Game? _selectedGame;
  List<Game> _myGames = [];
  
  // Animation controllers
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();
  bool _showElevation = false;
  
  // Filter options
  String _timeFilter = 'All Time'; // All Time, This Week, This Month
  final List<String> _timeFilters = ['All Time', 'This Week', 'This Month'];
  
  // User search
  TextEditingController _searchController = TextEditingController();
  List<UserScore> _filteredLeaderboard = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _scrollController.addListener(_onScroll);
    
    _fetchGlobalLeaderboard();
    _fetchMyGames();
    
    _searchController.addListener(_filterLeaderboard);
  }
  
  void _filterLeaderboard() {
    final query = _searchController.text.toLowerCase();
    
    if (query.isEmpty) {
      setState(() {
        _filteredLeaderboard = _leaderboard;
        _isSearching = false;
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
      _filteredLeaderboard = _leaderboard.where((user) {
        return user.name.toLowerCase().contains(query) || 
               (user.username?.toLowerCase() ?? '').contains(query);
      }).toList();
    });
  }
  
  void _onScroll() {
    if (_scrollController.offset > 0 && !_showElevation) {
      setState(() {
        _showElevation = true;
      });
    } else if (_scrollController.offset <= 0 && _showElevation) {
      setState(() {
        _showElevation = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchGlobalLeaderboard() async {
    setState(() {
      _isLoading = true;
      _selectedGame = null;
    });

    try {
      // Pass the context to handle 401 errors
      _leaderboard = await ApiService.getGlobalLeaderboard();
      
      // Assign ranks if they're not provided by the API
      if (_leaderboard.isNotEmpty && _leaderboard[0].rank == 0) {
        _assignRanks();
      }
      
      // Apply any search filter that might be active
      _filterLeaderboard();
      
      // Start animation after data is loaded
      _animationController.reset();
      _animationController.forward();
    } catch (e) {
      // Avoid showing error if widget is disposed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load leaderboard: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      // Only update state if the widget is still mounted
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Assign ranks based on score
  void _assignRanks() {
    // Sort by score descending
    _leaderboard.sort((a, b) => b.score.compareTo(a.score));
    
    // Create a temporary list with ranks
    final rankedList = <UserScore>[];
    
    int currentRank = 1;
    int previousScore = -1;
    
    for (int i = 0; i < _leaderboard.length; i++) {
      final score = _leaderboard[i];
      
      // If the score is different from the previous one, increment the rank
      if (previousScore != score.score && i > 0) {
        currentRank = i + 1;
      }
      
      // Create a new UserScore with the assigned rank
      rankedList.add(UserScore(
        userId: score.userId,
        score: score.score,
        rank: currentRank,
        name: score.name,
        username: score.username,
        avatar: score.avatar,
        gamesPlayed: score.gamesPlayed,
      ));
      
      previousScore = score.score;
    }
    
    _leaderboard = rankedList;
    _filteredLeaderboard = rankedList;
  }

  Future<void> _fetchGameLeaderboard(int gameId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Pass the context to handle 401 errors
      _leaderboard = await ApiService.getGameLeaderboard(gameId);
      
      // Assign ranks if they're not provided by the API
      if (_leaderboard.isNotEmpty && _leaderboard[0].rank == 0) {
        _assignRanks();
      }
      
      _selectedGame = _myGames.firstWhere(
        (game) => game.id == gameId,
        orElse: () => Game(
          id: gameId,
          title: 'Game #$gameId',
          description: '',
          questions: [],
          creatorId: 0,
          isActive: true,
        ),
      );
      
      // Apply any search filter that might be active
      _filterLeaderboard();
      
      // Start animation after data is loaded
      _animationController.reset();
      _animationController.forward();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load game leaderboard: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchMyGames() async {
    try {
      _myGames = await ApiService.getMyGames();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load games: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final currentUser = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180.0,
              floating: false,
              pinned: true,
              elevation: _showElevation ? 4 : 0,
              backgroundColor: primaryColor,
              systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
              ),
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16, right: 20),
                title: Text(
                  _selectedGame != null 
                    ? _selectedGame!.title 
                    : 'Leaderboard',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background pattern
                    CustomPaint(
                      painter: LeaderboardPatternPainter(Colors.white.withOpacity(0.1)),
                    ),
                    
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primaryColor.withOpacity(0.8),
                            primaryColor,
                          ],
                        ),
                      ),
                    ),
                    
                    // Content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 70, 20, 60),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.emoji_events,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedGame != null 
                                  ? 'Game Rankings' 
                                  : 'Global Rankings',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                // Search icon
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.search, color: Colors.white, size: 20),
                  ),
                  onPressed: () {
                    _showSearchDialog(context);
                  },
                  tooltip: 'Search players',
                ),
                
                // Filter icon
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.filter_list, color: Colors.white, size: 20),
                  ),
                  onPressed: () {
                    _showGameFilterBottomSheet(context);
                  },
                  tooltip: 'Filter by game',
                ),
                const SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: primaryColor,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: _timeFilters.map((filter) {
                        final isSelected = _timeFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8, bottom: 8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            child: ChoiceChip(
                              label: Text(filter),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _timeFilter = filter;
                                    // In a real app, you would refetch the data with the new filter
                                    HapticFeedback.selectionClick();
                                  });
                                }
                              },
                              backgroundColor: Colors.white.withOpacity(0.2),
                              selectedColor: Colors.white,
                              labelStyle: TextStyle(
                                color: isSelected ? primaryColor : Colors.white,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              avatar: isSelected 
                                ? Icon(
                                    _getFilterIcon(filter),
                                    size: 16,
                                    color: primaryColor,
                                  )
                                : null,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: _isLoading
          ? _buildLoadingState()
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Column(
                key: ValueKey<bool>(_isSearching),
                children: [
                  if (_isSearching) 
                    _buildSearchInfoBanner(),
                    
                  if (_selectedGame != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.public),
                        label: const Text('Show Global Leaderboard'),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _isSearching = false;
                          });
                          _fetchGlobalLeaderboard();
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                      ),
                    ),
                  Expanded(
                    child: _filteredLeaderboard.isEmpty
                      ? _buildEmptyState()
                      : _buildLeaderboardList(currentUser, primaryColor),
                  ),
                ],
              ),
            ),
      ),
    );
  }
  
  Widget _buildSearchInfoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.amber.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing results for "${_searchController.text}"',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _isSearching = false;
                _filteredLeaderboard = _leaderboard;
              });
            },
            child: const Text('Clear'),
          )
        ],
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading leaderboard...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'All Time':
        return Icons.history;
      case 'This Week':
        return Icons.view_week;
      case 'This Month':
        return Icons.calendar_today;
      default:
        return Icons.access_time;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isSearching ? Icons.search_off : Icons.emoji_events,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _isSearching 
                ? 'No Players Found' 
                : 'No Rankings Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _isSearching 
                  ? 'Try a different search term'
                  : 'Play more games to appear on the leaderboard!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: TextButton.icon(
                icon: const Icon(Icons.clear),
                label: const Text('Clear Search'),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _isSearching = false;
                    _filteredLeaderboard = _leaderboard;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(currentUser, primaryColor) {
    // Find user's position in leaderboard
    final userRankIndex = currentUser != null
        ? _filteredLeaderboard.indexWhere((score) => score.userId == currentUser.id)
        : -1;

    // Only show podium if not searching and we have the global view
    final showPodium = !_isSearching && _filteredLeaderboard.length >= 3;

    return RefreshIndicator(
      onRefresh: _selectedGame != null 
          ? () => _fetchGameLeaderboard(_selectedGame!.id) 
          : _fetchGlobalLeaderboard,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80), // Added bottom padding for navigation bar
        itemCount: _filteredLeaderboard.length + (showPodium ? 1 : 0), // +1 for the top section if showing podium
        itemBuilder: (context, index) {
          // Top section with podium for top 3 (only if not searching)
          if (showPodium && index == 0) {
            return _buildTopPlayersSection(primaryColor);
          }

          final scoreIndex = showPodium ? index - 1 : index;
          final score = _filteredLeaderboard[scoreIndex];
          final bool isCurrentUser = currentUser != null && 
              score.userId == currentUser.id;

          // Create staggered animation for each item
          final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Interval(
                math.min(0.1 * scoreIndex, 0.9), // Stagger the animations
                math.min(0.1 * scoreIndex + 0.6, 1.0),
                curve: Curves.easeOut,
              ),
            ),
          );

          // Skip top 3 players in the main list if showing podium
          if (showPodium && scoreIndex < 3) {
            return const SizedBox.shrink();
          }

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(animation),
              child: _buildPlayerCard(score, isCurrentUser, primaryColor, scoreIndex),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopPlayersSection(Color primaryColor) {
    // Get top 3 players or fewer if not enough
    final topPlayers = _filteredLeaderboard.length >= 3 
        ? _filteredLeaderboard.sublist(0, 3) 
        : _filteredLeaderboard;

    // Animate the podium section
    final animation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.2),
          end: Offset.zero,
        ).animate(animation),
        child: Card(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.emoji_events, size: 20, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      'Top Players',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (topPlayers.length >= 2)
                      _buildPodiumPosition(
                        topPlayers[1], // 2nd place
                        2,
                        Colors.grey[400]!, // Silver
                        120.0,
                      ),
                    if (topPlayers.isNotEmpty)
                      _buildPodiumPosition(
                        topPlayers[0], // 1st place
                        1,
                        Colors.amber, // Gold
                        140.0,
                      ),
                    if (topPlayers.length >= 3)
                      _buildPodiumPosition(
                        topPlayers[2], // 3rd place
                        3,
                        Colors.brown[300]!, // Bronze
                        100.0,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumPosition(UserScore player, int position, Color color, double height) {
    final avatarText = player.avatar ?? player.name[0].toUpperCase();
    
    return Column(
      children: [
        // Crown for 1st place
        if (position == 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Icon(Icons.stars, color: Colors.amber, size: 24),
          ),
        
        // Avatar with shine effect
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: position == 1 ? 80 : 70,
              height: position == 1 ? 80 : 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color,
                    color.withOpacity(0.8),
                  ],
                  stops: const [0.7, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            CircleAvatar(
              radius: position == 1 ? 36 : 30,
              backgroundColor: color.withOpacity(0.2),
              child: CircleAvatar(
                radius: position == 1 ? 32 : 26,
                backgroundColor: color,
                child: Text(
                  avatarText,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: position == 1 ? 24 : 20,
                  ),
                ),
              ),
            ),
            // Shine effect
            Positioned(
              top: position == 1 ? 10 : 8,
              left: position == 1 ? 16 : 14,
              child: Container(
                width: position == 1 ? 16 : 14,
                height: position == 1 ? 6 : 5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: position == 1 ? 90 : 80,
          child: Column(
            children: [
              Text(
                player.name,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: position == 1 ? 14 : 12,
                ),
              ),
              if (player.username != null && player.username!.isNotEmpty)
                Text(
                  '@${player.username}',
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: position == 1 ? 12 : 10,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.star, color: color, size: position == 1 ? 18 : 16),
            const SizedBox(width: 4),
            Text(
              player.score.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: position == 1 ? 16 : 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: position == 1 ? 70 : 60,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '#$position',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerCard(UserScore score, bool isCurrentUser, Color primaryColor, int index) {
    return Hero(
      tag: 'player-${score.userId}',
      child: Card(
        margin: const EdgeInsets.symmetric(
          vertical: 4, 
          horizontal: 16,
        ),
        elevation: isCurrentUser ? 3 : 1,
        color: isCurrentUser 
            ? primaryColor.withOpacity(0.05)
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isCurrentUser
              ? BorderSide(color: primaryColor.withOpacity(0.5), width: 1)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: () {
            // TODO: Navigate to player profile
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("View ${score.name}'s profile"),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                _buildRankBadge(score.rank),
                const SizedBox(width: 16),
                
                // User avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _getCategoryColor(score.name).withOpacity(0.2),
                  child: Text(
                    score.avatar ?? score.name[0].toUpperCase(),
                    style: TextStyle(
                      color: _getCategoryColor(score.name),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        score.name,
                        style: TextStyle(
                          fontWeight: isCurrentUser 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (score.username != null && score.username!.isNotEmpty)
                        Text(
                          '@${score.username}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Game stats
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCurrentUser
                        ? primaryColor.withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: isCurrentUser ? primaryColor : Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${score.score} pts',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isCurrentUser ? primaryColor : Colors.grey[800],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${score.gamesPlayed} games',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color badgeColor;
    IconData? badgeIcon;
    
    // Determine badge color and icon based on rank
    if (rank == 1) {
      badgeColor = Colors.amber; // Gold
      badgeIcon = Icons.emoji_events;
    } else if (rank == 2) {
      badgeColor = Colors.grey[400]!; // Silver
      badgeIcon = Icons.emoji_events;
    } else if (rank == 3) {
      badgeColor = Colors.brown[300]!; // Bronze
      badgeIcon = Icons.emoji_events;
    } else {
      badgeColor = Colors.grey[200]!;
      badgeIcon = null;
    }
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: badgeColor,
          width: rank <= 3 ? 2 : 1,
        ),
      ),
      child: Center(
        child: badgeIcon != null 
            ? Icon(badgeIcon, color: badgeColor, size: 20)
            : Text(
                '$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
  
  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Search Players'),
          content: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter player name or username',
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (_) {
              Navigator.pop(context);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _searchController.clear();
                setState(() {
                  _isSearching = false;
                  _filteredLeaderboard = _leaderboard;
                });
              },
              child: const Text('Clear'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Search'),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  void _showGameFilterBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: DraggableScrollableSheet(
                initialChildSize: 0.7,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                expand: false,
                builder: (context, scrollController) {
                  return Column(
                    children: [
                      // Handle indicator
                      Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.filter_list,
                              color: Colors.grey[800],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Filter Leaderboard',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const Spacer(),
                            if (_myGames.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.search),
                                onPressed: () {
                                  // Show search bar for games
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Game search coming soon!'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      const Divider(),
                      
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: EdgeInsets.zero,
                          children: [
                            // Global option
                            _buildFilterOption(
                              icon: Icons.public,
                              color: primaryColor,
                              title: 'Global Leaderboard',
                              subtitle: 'Rankings across all games',
                              isSelected: _selectedGame == null,
                              onTap: () {
                                Navigator.pop(context);
                                _fetchGlobalLeaderboard();
                              },
                            ),
                            
                            if (_myGames.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.games,
                                      color: Colors.grey[800],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Your Games',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                              // Game list
                              ..._myGames.map((game) => _buildFilterOption(
                                icon: _getCategoryIcon(game.title),
                                color: _getCategoryColor(game.title),
                                title: game.title,
                                subtitle: game.description,
                                isSelected: _selectedGame?.id == game.id,
                                onTap: () {
                                  Navigator.pop(context);
                                  _fetchGameLeaderboard(game.id);
                                },
                              )).toList(),
                            ] else ...[
                              // Empty state for games
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.games,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No games found',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Create games to see their leaderboards',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        // TODO: Navigate to create game
                                        Navigator.pop(context);
                                      },
                                      icon: const Icon(Icons.add),
                                      label: const Text('Create Game'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildFilterOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitle,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      selected: isSelected,
      trailing: isSelected
          ? Icon(Icons.check_circle, color: color)
          : null,
      onTap: onTap,
    );
  }
  
  // Helper method to get an icon based on game title
  IconData _getCategoryIcon(String title) {
    final icons = [
      Icons.history,
      Icons.science,
      Icons.movie,
      Icons.sports_basketball,
      Icons.public,
      Icons.music_note,
      Icons.psychology,
      Icons.auto_stories,
      Icons.emoji_objects,
    ];
    
    // Use hash of title to choose an icon
    final hash = title.hashCode.abs() % icons.length;
    return icons[hash];
  }

  // Helper method to get color based on game title
  Color _getCategoryColor(String title) {
    final colors = [
      Colors.blue[700]!,
      Colors.purple[700]!,
      Colors.green[700]!,
      Colors.orange[700]!,
      Colors.red[700]!,
      Colors.teal[700]!,
      Colors.indigo[700]!,
      Colors.pink[700]!,
      Colors.amber[700]!,
    ];
    
    // Use hash of title to choose a color
    final hash = title.hashCode.abs() % colors.length;
    return colors[hash];
  }
}

// Custom painter for background pattern
class LeaderboardPatternPainter extends CustomPainter {
  final Color color;

  LeaderboardPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    // Create a more interesting pattern with trophies and medals
    final random = math.Random(45); // Unique seed for this screen
    
    // Draw different shapes representing trophies, medals, and stars
    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 3.0 + random.nextDouble() * 8;
      
      final shape = i % 5; // Create 5 different shapes
      
      switch (shape) {
        case 0: // Circle (medal)
          canvas.drawCircle(Offset(x, y), radius, paint);
          break;
        case 1: // Trophy (simplified)
          final path = Path();
          path.moveTo(x, y);
          path.lineTo(x + radius, y - radius * 1.5);
          path.lineTo(x - radius, y - radius * 1.5);
          path.close();
          canvas.drawPath(path, paint);
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset(x, y + radius * 0.7),
              width: radius * 0.6,
              height: radius * 1.5,
            ),
            paint,
          );
          break;
        case 2: // Star (simplified)
          final path = Path();
          path.moveTo(x, y - radius);
          path.lineTo(x + radius * 0.4, y - radius * 0.4);
          path.lineTo(x + radius, y - radius * 0.2);
          path.lineTo(x + radius * 0.5, y + radius * 0.2);
          path.lineTo(x + radius * 0.7, y + radius);
          path.lineTo(x, y + radius * 0.6);
          path.lineTo(x - radius * 0.7, y + radius);
          path.lineTo(x - radius * 0.5, y + radius * 0.2);
          path.lineTo(x - radius, y - radius * 0.2);
          path.lineTo(x - radius * 0.4, y - radius * 0.4);
          path.close();
          canvas.drawPath(path, paint);
          break;
        case 3: // Diamond
          final path = Path();
          path.moveTo(x, y - radius);
          path.lineTo(x + radius, y);
          path.lineTo(x, y + radius);
          path.lineTo(x - radius, y);
          path.close();
          canvas.drawPath(path, paint);
          break;
        case 4: // Small dot
          canvas.drawCircle(Offset(x, y), radius * 0.5, paint);
          break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}