package games.dominos;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import iialib.games.model.Score;
import iialib.games.algs.AIPlayer;
import iialib.games.algs.AbstractGame;
import iialib.games.algs.GameAlgorithm;
import iialib.games.algs.algorithms.MiniMax;
import iialib.games.algs.algorithms.AlphaBeta;

public class DominosGame extends AbstractGame<DominosMove, DominosRole, DominosBoard> {

	// Algorithm references for statistics tracking
	private GameAlgorithm<DominosMove, DominosRole, DominosBoard> algV;
	private GameAlgorithm<DominosMove, DominosRole, DominosBoard> algH;
	private boolean silent;  // If true, suppress game output
	private DominosRole winner;  // Cached winner after game ends

	DominosGame(List<AIPlayer<DominosMove, DominosRole, DominosBoard>> players, DominosBoard board,
			GameAlgorithm<DominosMove, DominosRole, DominosBoard> algV,
			GameAlgorithm<DominosMove, DominosRole, DominosBoard> algH) {
		this(players, board, algV, algH, false);
	}
	
	public DominosGame(List<AIPlayer<DominosMove, DominosRole, DominosBoard>> players, DominosBoard board,
			GameAlgorithm<DominosMove, DominosRole, DominosBoard> algV,
			GameAlgorithm<DominosMove, DominosRole, DominosBoard> algH, boolean silent) {
		super(players, board);
		this.algV = algV;
		this.algH = algH;
		this.silent = silent;
		this.winner = null;
	}

	/**
	 * Override runGame to capture winner after game execution
	 */
	@Override
	public void runGame() {
		// Call parent implementation
		super.runGame();
		
		// Extract winner from game state - currentBoard is now populated
		// This must be done in a method of DominosGame since currentBoard is protected in parent
		captureWinner();
		
		// Display output only if not in silent mode
		if (!silent) {
			System.out.println("\nGame completed. Winner: " + this.winner);
		}
	}

	/**
	 * Capture the winner role after the game has ended
	 */
	private void captureWinner() {
		DominosBoard board = getCurrentBoard();
		if (board == null) {
			System.err.println("Warning: current board is null after game end. Using fallback.");
			this.winner = DominosRole.VERTICAL;
			return;
		}

		List<Score<DominosRole>> scores = board.getScores();
		if (scores == null || scores.isEmpty()) {
			System.err.println("Warning: no scores available after game end. Using fallback.");
			this.winner = DominosRole.VERTICAL;
			return;
		}

		this.winner = scores.stream()
			.max(Comparator.comparingInt(Score::getScore))
			.map(Score::getRole)
			.orElse(DominosRole.VERTICAL);
	}

	/**
	 * Public getter for the winner role after game execution
	 */
	public DominosRole getWinner() {
		return this.winner;
	}

	/**
	 * Display algorithm statistics and determine winner
	 */
	public void displayStatistics() {
		Stats statsV = collectStats(algV);
		Stats statsH = collectStats(algH);

		String labelV = algorithmLabel(algV) + (algV instanceof AlphaBeta ? " - Pruning Enabled" : " - No Pruning");
		String labelH = algorithmLabel(algH) + (algH instanceof AlphaBeta ? " - Pruning Enabled" : " - No Pruning");

		System.out.println("\n╔════════════════════════════════════════════════════════╗");
		System.out.println("║              ALGORITHM PERFORMANCE STATISTICS            ║");
		System.out.println("╚════════════════════════════════════════════════════════╝");
		
		System.out.println("\nVERTICAL (" + labelV + "):");
		System.out.println("  ├─ Nodes Explored:  " + statsV.nodes);
		System.out.println("  ├─ Leaves Evaluated: " + statsV.leaves);
		if (statsV.pruned > 0) {
			System.out.println("  └─ Branches Pruned:  " + statsV.pruned);
		} else {
			System.out.println("  └─ Branches Pruned:  (N/A - MiniMax has no pruning)");
		}
		
		System.out.println("\nHORIZONTAL (" + labelH + "):");
		System.out.println("  ├─ Nodes Explored:  " + statsH.nodes);
		System.out.println("  └─ Leaves Evaluated: " + statsH.leaves);
		
		// Comparative summary
		System.out.println("\n┌─ COMPARISON ──────────────────────────────────────┐");
		long totalNodesExp = statsV.nodes + statsH.nodes;
		long totalLeavesExp = statsV.leaves + statsH.leaves;
		long totalPrunedExp = statsV.pruned + statsH.pruned;
		System.out.println("│ Total Nodes Explored:    " + String.format("%6d", totalNodesExp));
		System.out.println("│ Total Leaves Evaluated:  " + String.format("%6d", totalLeavesExp));
		System.out.println("│ Total Branches Pruned:   " + String.format("%6d", totalPrunedExp));
		if (totalPrunedExp > 0) {
			double prunePercent = (totalPrunedExp * 100.0) / (totalNodesExp + totalLeavesExp + totalPrunedExp);
			System.out.println("│ Pruning Efficiency:      " + String.format("%5.1f%%", prunePercent));
		}
		System.out.println("└───────────────────────────────────────────────────┘\n");
	}

	private static class Stats {
		long nodes;
		long leaves;
		long pruned;
	}

	private static Stats collectStats(GameAlgorithm<DominosMove, DominosRole, DominosBoard> algorithm) {
		Stats stats = new Stats();
		if (algorithm instanceof AlphaBeta) {
			AlphaBeta<DominosMove, DominosRole, DominosBoard> ab = 
				(AlphaBeta<DominosMove, DominosRole, DominosBoard>) algorithm;
			stats.nodes = ab.getNbNodes();
			stats.leaves = ab.getNbLeaves();
			stats.pruned = ab.getNbPruned();
		} else if (algorithm instanceof MiniMax) {
			MiniMax<DominosMove, DominosRole, DominosBoard> mm = 
				(MiniMax<DominosMove, DominosRole, DominosBoard>) algorithm;
			stats.nodes = mm.getNbNodes();
			stats.leaves = mm.getNbLeaves();
		}
		return stats;
	}

	private static String algorithmLabel(GameAlgorithm<DominosMove, DominosRole, DominosBoard> algorithm) {
		if (algorithm instanceof AlphaBeta) {
			return "AlphaBeta";
		}
		if (algorithm instanceof MiniMax) {
			return "MiniMax";
		}
		return algorithm.getClass().getSimpleName();
	}

	/**
	 * Main method - can be modified to run different algorithm configurations
	 * Current configuration: AlphaBeta vs MiniMax
	 */
	public static void main(String[] args) {
		// ============================================================
		// Choose which match configuration to run:
		// Uncomment ONE of the following configurations
		// ============================================================
		
		// Configuration 1: AlphaBeta (depth 4) vs MiniMax (depth 2)
		// Tests algorithm efficiency: AlphaBeta with pruning vs basic minimax
		playMatchAlphabetaVsMinimax();
		
		// Configuration 2: AlphaBeta (depth 4) vs AlphaBeta (depth 2)
		// Tests if deeper search always wins when both use the same algorithm
		// playMatchAlphabetaVsAlphabeta();
		
		// Configuration 3: MiniMax (depth 4) vs MiniMax (depth 2)
		// Baseline comparison without pruning optimization
		// playMatchMinimaxVsMinimax();
	}

	/**
	 * AlphaBeta (optimized) vs MiniMax (basic minimax)
	 * Tests algorithm efficiency: AlphaBeta should require fewer nodes due to pruning
	 */
	private static void playMatchAlphabetaVsMinimax() {
		System.out.println("=== AlphaBeta vs MiniMax ===\n");
		
		DominosRole roleV = DominosRole.VERTICAL;
		DominosRole roleH = DominosRole.HORIZONTAL;

		// AlphaBeta algorithm with depth 4 for VERTICAL player
		GameAlgorithm<DominosMove, DominosRole, DominosBoard> algV = new AlphaBeta<>(
				roleV, roleH, DominosHeuristics.hVertical, 4);

		// MiniMax algorithm with depth 2 for HORIZONTAL player
		GameAlgorithm<DominosMove, DominosRole, DominosBoard> algH = new MiniMax<>(
				roleH, roleV, DominosHeuristics.hHorizontal, 2);

		AIPlayer<DominosMove, DominosRole, DominosBoard> playerV = new AIPlayer<>(
				roleV, algV);

		AIPlayer<DominosMove, DominosRole, DominosBoard> playerH = new AIPlayer<>(
				roleH, algH);

		List<AIPlayer<DominosMove, DominosRole, DominosBoard>> players = new ArrayList<>();

		players.add(playerV); // First Player (AlphaBeta)
		players.add(playerH); // Second Player (MiniMax)

		// Setting the initial Board
		DominosBoard initialBoard = new DominosBoard();
		
		// Reset statistics before starting the game
		((AlphaBeta<DominosMove, DominosRole, DominosBoard>) algV).resetStatistics();
		((MiniMax<DominosMove, DominosRole, DominosBoard>) algH).resetStatistics();

		DominosGame game = new DominosGame(players, initialBoard, algV, algH);
		game.runGame();
		game.displayStatistics();
		
		System.out.println("\n=== Match Complete ===");
		System.out.println("VERTICAL (AlphaBeta, depth 4) vs HORIZONTAL (MiniMax, depth 2)");
	}

	/**
	 * AlphaBeta (depth 4) vs AlphaBeta (depth 2)
	 * Tests if deeper search always wins when both use the same algorithm
	 */
	private static void playMatchAlphabetaVsAlphabeta() {
		System.out.println("=== AlphaBeta vs AlphaBeta ===\n");
		
		DominosRole roleV = DominosRole.VERTICAL;
		DominosRole roleH = DominosRole.HORIZONTAL;

		GameAlgorithm<DominosMove, DominosRole, DominosBoard> algV = new AlphaBeta<>(
				roleV, roleH, DominosHeuristics.hVertical, 4);

		GameAlgorithm<DominosMove, DominosRole, DominosBoard> algH = new AlphaBeta<>(
				roleH, roleV, DominosHeuristics.hHorizontal, 2);

		AIPlayer<DominosMove, DominosRole, DominosBoard> playerV = new AIPlayer<>(
				roleV, algV);

		AIPlayer<DominosMove, DominosRole, DominosBoard> playerH = new AIPlayer<>(
				roleH, algH);

		List<AIPlayer<DominosMove, DominosRole, DominosBoard>> players = new ArrayList<>();

		players.add(playerV);
		players.add(playerH);

		DominosBoard initialBoard = new DominosBoard();

		DominosGame game = new DominosGame(players, initialBoard, algV, algH);
		game.runGame();
		game.displayStatistics();
		
		System.out.println("\n=== Match Complete ===");
		System.out.println("VERTICAL (AlphaBeta, depth 4) vs HORIZONTAL (AlphaBeta, depth 2)");
	}

	/**
	 * MiniMax (depth 4) vs MiniMax (depth 2)
	 * Baseline comparison without pruning optimization
	 */
	private static void playMatchMinimaxVsMinimax() {
		System.out.println("=== MiniMax vs MiniMax ===\n");
		
		DominosRole roleV = DominosRole.VERTICAL;
		DominosRole roleH = DominosRole.HORIZONTAL;

		GameAlgorithm<DominosMove, DominosRole, DominosBoard> algV = new MiniMax<>(
				roleV, roleH, DominosHeuristics.hVertical, 4);

		GameAlgorithm<DominosMove, DominosRole, DominosBoard> algH = new MiniMax<>(
				roleH, roleV, DominosHeuristics.hHorizontal, 2);

		AIPlayer<DominosMove, DominosRole, DominosBoard> playerV = new AIPlayer<>(
				roleV, algV);

		AIPlayer<DominosMove, DominosRole, DominosBoard> playerH = new AIPlayer<>(
				roleH, algH);

		List<AIPlayer<DominosMove, DominosRole, DominosBoard>> players = new ArrayList<>();

		players.add(playerV);
		players.add(playerH);

		DominosBoard initialBoard = new DominosBoard();

		DominosGame game = new DominosGame(players, initialBoard, algV, algH);
		game.runGame();
		game.displayStatistics();
		
		System.out.println("\n=== Match Complete ===");
		System.out.println("VERTICAL (MiniMax, depth 4) vs HORIZONTAL (MiniMax, depth 2)");
	}

}