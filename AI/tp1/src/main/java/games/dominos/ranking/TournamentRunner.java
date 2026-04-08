package games.dominos.ranking;

/**
 * Entry point for running the AI Tournament Ranking System.
 * Executes comprehensive "All vs All" tournaments with multiple algorithm configurations.
 */
public class TournamentRunner {
    
    public static void main(String[] args) {
        System.out.println("\n╔════════════════════════════════════════════════════════╗");
        System.out.println("║         DOMINOS AI TOURNAMENT RANKING SYSTEM            ║");
        System.out.println("╚════════════════════════════════════════════════════════╝\n");
        
        // Create ranking system: 50 matches per pairing
        AIRankingSystem ranking = new AIRankingSystem(50);
        
        // Configure algorithms to test
        configureAlgorithms(ranking);
        
        // Execute the tournament
        ranking.executeFullTournament();
    }
    
    private static void configureAlgorithms(AIRankingSystem ranking) {
        System.out.println("Configuring algorithms for tournament...\n");
        
        // AlphaBeta configurations
        ranking.addAlgorithm(new AlgorithmConfig(AlgorithmConfig.AlgorithmType.ALPHABETA, 3, "DEFAULT"));
        ranking.addAlgorithm(new AlgorithmConfig(AlgorithmConfig.AlgorithmType.ALPHABETA, 4, "DEFAULT"));
        
        // MiniMax configurations
        ranking.addAlgorithm(new AlgorithmConfig(AlgorithmConfig.AlgorithmType.MINIMAX, 1, "DEFAULT"));
        ranking.addAlgorithm(new AlgorithmConfig(AlgorithmConfig.AlgorithmType.MINIMAX, 2, "DEFAULT"));
        ranking.addAlgorithm(new AlgorithmConfig(AlgorithmConfig.AlgorithmType.MINIMAX, 3, "DEFAULT"));
        
        System.out.println("✓ 5 algorithm configurations registered");
        System.out.println("✓ Total matchups: 10 (5 choose 2)");
        System.out.println("✓ Total games: 500 (10 matchups × 50 games)\n");
    }
}
