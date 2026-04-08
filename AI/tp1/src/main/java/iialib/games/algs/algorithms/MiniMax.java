package iialib.games.algs.algorithms;

import javax.lang.model.type.UnionType;

import iialib.games.algs.GameAlgorithm;
import iialib.games.algs.IHeuristic;
import iialib.games.model.IBoard;
import iialib.games.model.IMove;
import iialib.games.model.IRole;

public class MiniMax<Move extends IMove, Role extends IRole, Board extends IBoard<Move,Role,Board>> implements GameAlgorithm<Move,Role,Board> {

	// Constants
	/** Defaut value for depth limit 
  */
	private static final int DEPTH_MAX_DEFAUT = 4;

	// Attributes
	/** Role of the max player 
  */
	private final Role playerMaxRole;

	/** Role of the min player 
  */
	private final Role playerMinRole;

	/** Algorithm max depth
  */
	private int depthMax = DEPTH_MAX_DEFAUT;

	
	/** Heuristic used by the max player 
  */
	private IHeuristic<Board, Role> h;

	//
	/** number of internal visited (developed) nodes (for stats)
  */
	private int nbNodes;
	
	/** number of leaves nodes nodes (for stats)
  */
	private int nbLeaves;

	// --------- Constructors ---------
	public MiniMax(Role playerMaxRole, Role playerMinRole, IHeuristic<Board, Role> h) {
		this.playerMaxRole = playerMaxRole;
		this.playerMinRole = playerMinRole;
		this.h = h;
	}

	public MiniMax(Role playerMaxRole, Role playerMinRole, IHeuristic<Board, Role> h, int depthMax) {
		this(playerMaxRole, playerMinRole, h);
		this.depthMax = depthMax;
	}

	/*
	 * IAlgo METHODS =============
	 */

	@Override
	public Move bestMove(Board board, Role playerRole) {
		System.out.println("[MiniMax]");
    return  minimax(board, playerRole);
	}

	/*
	 * PUBLIC METHODS ==============
	 */

	public String toString() {
		return "MiniMax(ProfMax=" + depthMax + ")";
	}

	/*
	 * PRIVATE METHODS ===============
	 */
  private Move minimax(Board board, Role playerRole) {
    Move bestMove = null;
    int bestValue = Integer.MIN_VALUE;
    for(Move move : board.possibleMoves(playerRole)) {
      Board newBoard = board.play(move, playerRole);
      int value = minValue(newBoard, playerMinRole, depthMax - 1);
      if(value > bestValue) {
        bestValue = value;
        bestMove = move;
      }
    }
    return bestMove;
  }

  private int maxValue(Board board, Role playerRole, int depth) {
    if(board.isGameOver() || depth == 0) {
      nbLeaves++;
      return h.eval(board, playerMaxRole);
    }
    int value = Integer.MIN_VALUE;
    for(Move move : board.possibleMoves(playerRole)) {
      Board newBoard = board.play(move, playerRole);
      value = Math.max(value, minValue(newBoard, playerMinRole, depth - 1));
    }
    nbNodes++;
    return value;
  }

  private int minValue(Board board, Role playerRole, int depth) {
    if(board.isGameOver() || depth == 0) {
      nbLeaves++;
      return h.eval(board, playerMaxRole);
    }
    int value = Integer.MAX_VALUE;
    for(Move move : board.possibleMoves(playerRole)) {
      Board newBoard = board.play(move, playerRole);
      value = Math.min(value, maxValue(newBoard, playerMaxRole, depth - 1));
    }
    nbNodes++;
    return value;
  }
}
