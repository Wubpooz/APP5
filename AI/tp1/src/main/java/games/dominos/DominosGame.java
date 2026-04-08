package games.dominos;

import java.util.ArrayList;
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

	DominosGame(ArrayList<AIPlayer<DominosMove, DominosRole, DominosBoard>> players, DominosBoard board,
			GameAlgorithm<DominosMove, DominosRole, DominosBoard> algV,
			GameAlgorithm<DominosMove, DominosRole, DominosBoard> algH) {
		this(players, board, algV, algH, false);
	}
	
	public DominosGame(ArrayList<AIPlayer<DominosMove, DominosRole, DominosBoard>> players, DominosBoard board,
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
	 * Uses reflection to access parent's package-private currentBoard field
	 */
	private void captureWinner() {
		try {
			// Use reflection to access the package-private currentBoard field
			java.lang.reflect.Field boardField = AbstractGame.class.getDeclaredField("currentBoard");
			boardField.setAccessible(true);
			DominosBoard board = (DominosBoard) boardField.get(this);
			
			// Get the scores from the board
			ArrayList<Score<DominosRole>> scores = board.getScores();
			
			// Find the role with maximum score
			int maxScore = -1;
			DominosRole winnerRole = null;
			
			for (Score<DominosRole> score : scores) {
				if (score.getScore() > maxScore) {
					maxScore = score.getScore();
					winnerRole = score.getRole();
				}
			}
			
			// Store the winner
			this.winner = winnerRole;
			
		} catch (NoSuchFieldException | IllegalAccessException e) {
			// Fallback: default to first player's role if reflection fails
			System.err.println("Warning: Could not access game board to determine winner. Using fallback.");
			this.winner = DominosRole.VERTICAL;
		}
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
		// Capture final stats from algorithms
		long finalNodesV = 0, finalLeavesV = 0, finalPrunedV = 0;
		long finalNodesH = 0, finalLeavesH = 0, finalPrunedH = 0;
		
		if (algV instanceof AlphaBeta) {
			AlphaBeta<DominosMove, DominosRole, DominosBoard> ab = 
				(AlphaBeta<DominosMove, DominosRole, DominosBoard>) algV;
			finalNodesV = ab.getNbNodes();
			finalLeavesV = ab.getNbLeaves();
			finalPrunedV = ab.getNbPruned();
		} else if (algV instanceof MiniMax) {
			MiniMax<DominosMove, DominosRole, DominosBoard> mm = 
				(MiniMax<DominosMove, DominosRole, DominosBoard>) algV;
			finalNodesV = mm.getNbNodes();
			finalLeavesV = mm.getNbLeaves();
		}
		
		if (algH instanceof AlphaBeta) {
			AlphaBeta<DominosMove, DominosRole, DominosBoard> ab = 
				(AlphaBeta<DominosMove, DominosRole, DominosBoard>) algH;
			finalNodesH = ab.getNbNodes();
			finalLeavesH = ab.getNbLeaves();
			finalPrunedH = ab.getNbPruned();
		} else if (algH instanceof MiniMax) {
			MiniMax<DominosMove, DominosRole, DominosBoard> mm = 
				(MiniMax<DominosMove, DominosRole, DominosBoard>) algH;
			finalNodesH = mm.getNbNodes();
			finalLeavesH = mm.getNbLeaves();
		}

		System.out.println("\n╔════════════════════════════════════════════════════════╗");
		System.out.println("║              ALGORITHM PERFORMANCE STATISTICS            ║");
		System.out.println("╚════════════════════════════════════════════════════════╝");
		
		System.out.println("\nVERTICAL (AlphaBeta - Pruning Enabled):");
		System.out.println("  ├─ Nodes Explored:  " + finalNodesV);
		System.out.println("  ├─ Leaves Evaluated: " + finalLeavesV);
		if (finalPrunedV > 0) {
			System.out.println("  └─ Branches Pruned:  " + finalPrunedV);
		} else {
			System.out.println("  └─ Branches Pruned:  (N/A - MiniMax has no pruning)");
		}
		
		System.out.println("\nHORIZONTAL (MiniMax - No Pruning):");
		System.out.println("  ├─ Nodes Explored:  " + finalNodesH);
		System.out.println("  └─ Leaves Evaluated: " + finalLeavesH);
		
		// Comparative summary
		System.out.println("\n┌─ COMPARISON ──────────────────────────────────────┐");
		long totalNodesExp = finalNodesV + finalNodesH;
		long totalLeavesExp = finalLeavesV + finalLeavesH;
		long totalPrunedExp = finalPrunedV + finalPrunedH;
		System.out.println("│ Total Nodes Explored:    " + String.format("%6d", totalNodesExp));
		System.out.println("│ Total Leaves Evaluated:  " + String.format("%6d", totalLeavesExp));
		System.out.println("│ Total Branches Pruned:   " + String.format("%6d", totalPrunedExp));
		if (totalPrunedExp > 0) {
			double prunePercent = (totalPrunedExp * 100.0) / (totalNodesExp + totalLeavesExp + totalPrunedExp);
			System.out.println("│ Pruning Efficiency:      " + String.format("%5.1f%%", prunePercent));
		}
		System.out.println("└───────────────────────────────────────────────────┘\n");
	}
	
	/**
	
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

		ArrayList<AIPlayer<DominosMove, DominosRole, DominosBoard>> players = new ArrayList<>();

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

		ArrayList<AIPlayer<DominosMove, DominosRole, DominosBoard>> players = new ArrayList<>();

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

		ArrayList<AIPlayer<DominosMove, DominosRole, DominosBoard>> players = new ArrayList<>();

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