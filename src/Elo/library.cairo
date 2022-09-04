%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import (Uint256, uint256_lt, uint256_add)
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math_cmp import (is_nn, is_le)
from starkware.cairo.common.math import (abs_value,assert_lt)


#
# Events
#

@event
func EloScoreUpdate(player: felt, newScore: Uint256):
end

#
# Storage
#

struct Score:
    member score: Uint256
end

@storage_var
func ELO_scores(player_address: felt) -> (player_score: Score):
end

namespace ELO:

    #
    # Getters
    #
    func getScore{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(player_address: felt) -> (score: Uint256):
        alloc_locals
        let (player_score) = ELO_scores.read(player_address)

        let (is_lt) = uint256_lt(player_score.score, Uint256(100,0))
        if is_lt == TRUE: 
            return(Uint256(100,0))
        end
        return(player_score.score)
    end

    #
    # Setters
    #
    func recordResult{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(player1Address: felt, player2Address: felt, winnerAddress:felt) -> ():
        alloc_locals

        let(player1Score) = getScore(player1Address)
        let(player2Score) = getScore(player2Address)

        let (resultA) = _getResultSide(player1Address,player2Address, winnerAddress)
        
        let diff = player1Score.low - player2Score.low
        let (changeA, changeB) = _getScoreChange(diff, resultA)
        
        let newPlayerAScore = player1Score.low + changeA
        setScore(player1Address, Uint256(newPlayerAScore,0))
        EloScoreUpdate.emit(player1Address,Uint256(newPlayerAScore,0))

        let newPlayerBScore = player2Score.low + changeB
        setScore(player2Address, Uint256(newPlayerBScore,0))
        EloScoreUpdate.emit(player2Address,Uint256(newPlayerBScore,0))

        return()
    end


    func setScore{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(player_address: felt, player_score: Uint256) -> ():
        let (is_lt) = uint256_lt(player_score, Uint256(100,0))
        if is_lt == 1: 
            ELO_scores.write(player_address, Score(Uint256(100,0)))
            return()
        end
        ELO_scores.write(player_address, Score(player_score))
        return()
    end
end


func _getResultSide{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(player1Address: felt, player2Address: felt, winnerAddress:felt) -> (resultA: felt):
    if winnerAddress == player2Address:
        return(0)
    end
    if winnerAddress == player1Address:
        return(2)
    end
    return(1)
end 

func _getScoreChange{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(difference: felt, resultA: felt) -> (changeValueA: felt, changeValueB:felt):
    alloc_locals
    let (is_diff_positive) = is_nn(difference)
    let (diff) = abs_value(difference)

    let (scoreChange) = _getScoreDiff(diff)
    if resultA == 2 :
        let inter = 20 - scoreChange
        if is_diff_positive == TRUE:
            return(inter, -scoreChange)
        end
        return(scoreChange, -inter)
    end
        if resultA == 1 :
        let inter1 = 10 - scoreChange
        let inter2 = scoreChange - 10
        if is_diff_positive == TRUE:
            return(inter1, -inter1)
        end
        return(inter2, -inter2)
    end
    let inter = scoreChange - 20
    if is_diff_positive == TRUE:
        return(inter, scoreChange)
    end
    return(-scoreChange, -inter)
end

func _getScoreDiff{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(difference: felt)->(scoreChange:felt):
    let (is_sup) = is_le(636,difference)
    if is_sup == TRUE:
        return(20)
    end
    let (is_sup) = is_le(436,difference)
        if is_sup == TRUE:
        return(19)
    end
    let (is_sup) = is_le(338,difference)
    if is_sup == TRUE:
        return(18)
    end
    
    let (is_sup) = is_le(269,difference)
    if is_sup == TRUE:
        return(17)
    end
    let (is_sup) = is_le(214,difference)
        if is_sup == TRUE:
        return(16)
    end
    let (is_sup) = is_le(168,difference)
    if is_sup == TRUE:
        return(15)
    end
    let (is_sup) = is_le(126,difference)
        if is_sup == TRUE:
        return(14)
    end
    let (is_sup) = is_le(88,difference)
        if is_sup == TRUE:
        return(13)
    end
    let (is_sup) = is_le(52,difference)
        if is_sup == TRUE:
        return(12)
    end
    let (is_sup) = is_le(17,difference)
        if is_sup == TRUE:
        return(11)
    end
        return(10)
end