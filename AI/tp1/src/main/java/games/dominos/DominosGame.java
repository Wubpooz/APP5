package games.dominos;

import java.util.ArrayList;

import iialib.games.algs.AIPlayer;
import iialib.games.algs.AbstractGame;
import iialib.games.algs.GameAlgorithm;
import iialib.games.algs.algorithms.MiniMax;
import iialib.games.algs.algorithms.AlphaBeta;

public class DominosGame extends AbstractGame<DominosMove, DominosRole, DominosBoard> {

	DominosGame(ArrayList<AIPlayer<DominosMove, DominosRole, DominosBoard>> players, DominosBoard board) {
		super(players, board);
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

		ArrayList<AIPlayer<DominosMove, DominosRole, DominosBoard>> players = new ArrayList<>();

		players.add(playerV); // First Player (AlphaBeta)
		players.add(playerH); // Second Player (MiniMax)

		// Setting the initial Board
		DominosBoard initialBoard = new DominosBoard();

		DominosGame game = new DominosGame(players, initialBoard);
		game.runGame();
		
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

		DominosGame game = new DominosGame(players, initialBoard);
		game.runGame();
		
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

		DominosGame game = new DominosGame(players, initialBoard);
		game.runGame();
		
		System.out.println("\n=== Match Complete ===");
		System.out.println("VERTICAL (MiniMax, depth 4) vs HORIZONTAL (MiniMax, depth 2)");
	}

}