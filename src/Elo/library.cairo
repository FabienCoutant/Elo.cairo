%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_lt, uint256_add
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.cairo.common.math import (abs_value, assert_lt, assert_not_equal, sign)
from lib.cairo_math_64x61.contracts.cairo_math_64x61.math64x61 import Math64x61

//
// Events
//

@event
func EloScoreUpdate(player: felt, newScore: felt) {
}

//
// Storage
//

struct Score {
    score: Uint256,
}

@storage_var
func ELO_scores(player_address: felt) -> (player_score: Score) {
}

namespace ELO {


    //
    // Getters
    //
    func getScore{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        player_address: felt
    ) -> (score: Uint256) {
        alloc_locals;
        let (player_score) = ELO_scores.read(player_address);

        let (is_lt) = uint256_lt(player_score.score, Uint256(100, 0));
        if (is_lt == TRUE) {
            return (Uint256(100, 0),);
        }
        return (player_score.score,);
    }

    //
    // Setters
    //

    // The algo is base on https://en.wikipedia.org/wiki/Elo_rating_system#Mathematical_details
    func recordResult{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        playerA_Address: felt, playerB_Address: felt, winner_Address: felt
    ) -> () {
        alloc_locals;

        let (playerA_Score) = getScore(playerA_Address);
        let (playerB_Score) = getScore(playerB_Address);

        let (resultA, resultB) = _getResultSide(playerA_Address, playerB_Address, winner_Address);

        let (changeA) = _getExpectedScore(playerB_Score, playerA_Score);
        let (changeB) = _getExpectedScore(playerA_Score, playerB_Score);

         // update PlayerA_Score
        let (newPlayerA_Score,) = _getNewScore(playerA_Score,20,resultA,changeA);
        setScore(playerA_Address, newPlayerA_Score);

        // emit event with new PlayerA_Score
        let (updated_PlayerA_Score) = getScore(playerA_Address);
        EloScoreUpdate.emit(playerA_Address, updated_PlayerA_Score.low);

        // update PlayerB_Score
        let (newPlayerB_Score,) =  _getNewScore(playerB_Score,20,resultB,changeB);
        setScore(playerB_Address, newPlayerB_Score);
        
        // emit event with new PlayerB_Score
        let (updatedPlayerB_Score) = getScore(playerB_Address);
        EloScoreUpdate.emit(playerB_Address, updatedPlayerB_Score.low);

        return();
    }

    func setScore{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        player_address: felt, player_score: Uint256
    ) -> () {
        let (is_lt) = uint256_lt(player_score, Uint256(100, 0));
        if (is_lt == 1) {
            ELO_scores.write(player_address, Score(Uint256(100, 0)));
            return ();
        }
        ELO_scores.write(player_address, Score(player_score));
        return ();
    }

}

// 0 = lose | 0.5 = draw | 1 = win
func _getResultSide{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    playerA_Address: felt, playerB_Address: felt, winner_Address: felt
) -> (resultA: felt, resultB:felt) {
    if (winner_Address == playerA_Address) {
        return (Math64x61.fromFelt(1), Math64x61.fromFelt(0),);
    }
    if (winner_Address == playerB_Address) {
        return (Math64x61.fromFelt(0), Math64x61.fromFelt(1),);
    }
    let drawValue = Math64x61.div(Math64x61.fromFelt(1),Math64x61.fromFelt(2));
    return (drawValue, drawValue,);
}

// The ExpectedScore formula is:
// E = 1 / ( 1 + 10**((difference)/400))
func _getExpectedScore{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    otherPlayerScore: Uint256, playerScore: Uint256
) -> (expectedScore: felt) {
    alloc_locals;
    let valueDiff = Math64x61.sub(Math64x61.fromUint256(otherPlayerScore),Math64x61.fromUint256(playerScore));
    let abs_diff = abs_value(valueDiff);
    let diff_sign = sign(valueDiff);
    let powValue = Math64x61.pow(Math64x61.fromFelt(10),Math64x61.div(Math64x61.fromFelt(abs_diff),Math64x61.fromFelt(400))*diff_sign);
    let expectedScore = Math64x61.div(Math64x61.fromFelt(1),Math64x61.add(Math64x61.fromFelt(1),powValue));
    return (expectedScore,);
}

func _getNewScore{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    current_player_Score: Uint256, K_factor: felt, player_Result: felt, expected_change: felt
) -> (newScore_uint: Uint256) {
    let newScore = Math64x61.add(Math64x61.fromUint256(current_player_Score),Math64x61.mul(Math64x61.fromFelt(K_factor),Math64x61.sub(player_Result, expected_change)));
    let newScore_uint = Math64x61.toUint256(Math64x61.toFelt(newScore));
    return(newScore_uint,);
}
