package games.dominos.ranking;

import games.dominos.*;
import iialib.games.algs.AIPlayer;
import iialib.games.algs.GameAlgorithm;
import iialib.games.model.Score;

import java.util.*;
import java.util.stream.Collectors;

/**
 * Tournament ranking system for AI algorithms.
 * Executes comprehensive "All vs All" tournament matches and ranks algorithms by win rate.
 */
public class AIRankingSystem {
    
    private final int matchesPerPairing;
    private final List<AlgorithmConfig> algorithms;
    private final Map<String, MatchResult> results;
    private final Map<String, Integer> winCounts;
    
    /**
     * Creates ranking system with specified algorithms and matches per pairing
     */
    public AIRankingSystem(int matchesPerPairing) {
        this.matchesPerPairing = matchesPerPairing;
        this.algorithms = new ArrayList<>();
        this.results = new HashMap<>();
        this.winCounts = new HashMap<>();
    }
    
    /**
     * Adds an algorithm configuration to the tournament
     */
    public void addAlgorithm(AlgorithmConfig config) {
        if (!algorithms.contains(config)) {
            algorithms.add(config);
            winCounts.put(config.toString(), 0);
        }
    }
    
    /**
     * Executes the full "All vs All" tournament
     */
    public void executeFullTournament() {
        System.out.println("\n" + "=".repeat(60));
        System.out.println("AI TOURNAMENT RANKING SYSTEM");
        System.out.println("Matches per pairing: " + matchesPerPairing);
        System.out.println("Total algorithms: " + algorithms.size());
        System.out.println("=".repeat(60) + "\n");
        
        int totalMatchups = 0;
        for (int i = 0; i < algorithms.size(); i++) {
            for (int j = i + 1; j < algorithms.size(); j++) {
                totalMatchups++;
            }
        }
        
        int currentMatchup = 0;
        for (int i = 0; i < algorithms.size(); i++) {
            for (int j = i + 1; j < algorithms.size(); j++) {
                currentMatchup++;
                AlgorithmConfig algo1 = algorithms.get(i);
                AlgorithmConfig algo2 = algorithms.get(j);
                
                System.out.println("[" + currentMatchup + "/" + totalMatchups + "] " +
                    algo1 + " vs " + algo2);
                
                executeMatchSeries(algo1, algo2);
                System.out.println();
            }
        }
        
        displayRankings();
    }
    
    /**
     * Executes a series of matches between two algorithms
     */
    private void executeMatchSeries(AlgorithmConfig algo1, AlgorithmConfig algo2) {
        MatchResult result = new MatchResult(algo1, algo2, matchesPerPairing);
        
        for (int match = 0; match < matchesPerPairing; match++) {
            // Alternate who goes first to be fair
            boolean algo1First = (match % 2 == 0);
            
            DominosRole roleAlgo1 = algo1First ? DominosRole.VERTICAL : DominosRole.HORIZONTAL;
            DominosRole roleAlgo2 = algo1First ? DominosRole.HORIZONTAL : DominosRole.VERTICAL;
            
            DominosRole winner = executeSingleMatch(algo1, algo2, roleAlgo1, roleAlgo2);
            
            if (winner == roleAlgo1) {
                result.recordWin(algo1);
                winCounts.put(algo1.toString(), winCounts.get(algo1.toString()) + 1);
            } else if (winner == roleAlgo2) {
                result.recordWin(algo2);
                winCounts.put(algo2.toString(), winCounts.get(algo2.toString()) + 1);
            } else {
                result.recordDraw();
            }
            
            // Progress indicator
            if ((match + 1) % 10 == 0) {
                System.out.print(".");
            }
        }
        
        System.out.println(" Complete: " + algo1 + " " + 
            String.format("%.1f%%", result.getWinRate1() * 100) + " vs " + 
            String.format("%.1f%%", result.getWinRate2() * 100) + " " + algo2);
        
        String key = algo1 + " vs " + algo2;
        results.put(key, result);
    }
    
    /**
     * Executes a single match between two algorithms
     */
    private DominosRole executeSingleMatch(AlgorithmConfig algo1, AlgorithmConfig algo2,
                                          DominosRole roleAlgo1, DominosRole roleAlgo2) {
        try {
            // Create algorithm instances
            GameAlgorithm<DominosMove, DominosRole, DominosBoard> algInstance1 = 
                algo1.createInstance(roleAlgo1, roleAlgo2);
            GameAlgorithm<DominosMove, DominosRole, DominosBoard> algInstance2 = 
                algo2.createInstance(roleAlgo2, roleAlgo1);
            
            // Reset statistics
            resetStatistics(algInstance1);
            resetStatistics(algInstance2);
            
            // Create players
            AIPlayer<DominosMove, DominosRole, DominosBoard> player1 = 
                new AIPlayer<>(roleAlgo1, algInstance1);
            AIPlayer<DominosMove, DominosRole, DominosBoard> player2 = 
                new AIPlayer<>(roleAlgo2, algInstance2);
            
            // Create game
            ArrayList<AIPlayer<DominosMove, DominosRole, DominosBoard>> players = new ArrayList<>();
            players.add(player1);
            players.add(player2);
            
            DominosBoard initialBoard = new DominosBoard();
            
            // Silent game execution (no output)
            DominosGame game = new DominosGame(players, initialBoard, algInstance1, algInstance2, true);
            game.runGame();
            
            // Get winner from game after execution
            DominosRole winner = game.getWinner();
            
            return winner;
            
        } catch (Exception e) {
            System.err.println("Error in match execution: " + e.getMessage());
            return null;
        }
    }
    
    /**
     * Resets statistics counters if algorithm supports it
     */
    private void resetStatistics(GameAlgorithm<DominosMove, DominosRole, DominosBoard> algorithm) {
        try {
            if (algorithm instanceof iialib.games.algs.algorithms.AlphaBeta) {
                ((iialib.games.algs.algorithms.AlphaBeta) algorithm).resetStatistics();
            } else if (algorithm instanceof iialib.games.algs.algorithms.MiniMax) {
                ((iialib.games.algs.algorithms.MiniMax) algorithm).resetStatistics();
            }
        } catch (Exception e) {
            // Silently ignore if reset not available
        }
    }
    
    /**
     * Displays final rankings in a formatted table
     */
    public void displayRankings() {
        System.out.println("\n" + "=".repeat(70));
        System.out.println("FINAL RANKINGS (by Total Wins)");
        System.out.println("=".repeat(70));
        
        // Sort algorithms by win count
        List<Map.Entry<String, Integer>> sorted = winCounts.entrySet().stream()
            .sorted((a, b) -> b.getValue().compareTo(a.getValue()))
            .collect(Collectors.toList());
        
        int totalPairings = algorithms.size() * (algorithms.size() - 1) / 2;
        int maxWinsPerAlgo = totalPairings * matchesPerPairing;
        
        System.out.println("┌─────────────────────────────────────────────────┬─────────────────┐");
        System.out.println("│ Algorithm Configuration                          │ Wins (Ranking)  │");
        System.out.println("├─────────────────────────────────────────────────┼─────────────────┤");
        
        int rank = 1;
        for (Map.Entry<String, Integer> entry : sorted) {
            String algo = entry.getKey();
            int wins = entry.getValue();
            double winPercentage = (double) wins / maxWinsPerAlgo * 100;
            
            System.out.printf("│ %-47s │ %3d/%3d (%.1f%%)  │%n", 
                algo, wins, maxWinsPerAlgo, winPercentage);
            rank++;
        }
        
        System.out.println("└─────────────────────────────────────────────────┴─────────────────┘");
        
        // Display detailed matchup results
        System.out.println("\nDETAILED MATCHUP RESULTS:");
        System.out.println("─".repeat(70));
        
        for (Map.Entry<String, MatchResult> entry : results.entrySet()) {
            MatchResult result = entry.getValue();
            System.out.printf("%-30s: %s  [%3d/%3d games]%n",
                result.getAlgorithm1(),
                String.format("%d-%d", result.getWins1(), result.getWins2()),
                result.getWins1() + result.getWins2(),
                result.getTotalMatches()
            );
        }
        
        System.out.println("─".repeat(70) + "\n");
    }
    
    /**
     * Returns total wins for an algorithm
     */
    public int getTotalWins(String algorithmName) {
        return winCounts.getOrDefault(algorithmName, 0);
    }
    
    /**
     * Returns all match results
     */
    public Collection<MatchResult> getResults() {
        return results.values();
    }
}
