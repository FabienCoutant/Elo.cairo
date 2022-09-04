%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import (Uint256, uint256_lt, uint256_add)
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math_cmp import (is_nn, is_le)
from starkware.cairo.common.math import (abs_value,assert_lt, assert_not_equal)


#
# Events
#

@event
func EloScoreUpdate(player: felt, newScore: felt):
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
    func recordResult{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(playerA_Address: felt, playerB_Address: felt, winner_Address:felt) -> ():
        alloc_locals


        let(playerA_Score) = getScore(playerA_Address)
        let(playerB_Score) = getScore(playerB_Address)

        let (resultA) = _getResultSideForA(playerA_Address,playerB_Address, winner_Address)
        
        let delta = playerA_Score.low - playerB_Score.low
        let (changeA, changeB) = _getScoreChange(delta, resultA)
        
        # update PlayerA_Score
        let newPlayerA_Score = playerA_Score.low + changeA
        setScore(playerA_Address, Uint256(newPlayerA_Score,0))

        #emit event with new PlayerA_Score
        let (updated_PlayerA_Score) = getScore(playerA_Address)
        EloScoreUpdate.emit(playerA_Address,updated_PlayerA_Score.low)

        # update PlayerB_Score
        let newPlayerB_Score = playerB_Score.low + changeB
        setScore(playerB_Address, Uint256(newPlayerB_Score,0))
        
        #emit event with new PlayerB_Score
        let (updatedPlayerB_Score) = getScore(playerB_Address)
        EloScoreUpdate.emit(playerB_Address,updatedPlayerB_Score.low)

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


# 0 = lose | 1 = draw | 2 = win
func _getResultSideForA{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(playerA_Address: felt, playerB_Address: felt, winner_Address:felt) -> (resultA: felt):
    if winner_Address == playerB_Address:
        return(0)
    end
    if winner_Address == playerA_Address:
        return(2)
    end
    return(1)
end 


#  Table based expectation formula
#  E = 1 / ( 1 + 10**((difference)/400))
#  Table calculated based on inverse: difference = (400*log(1/E-1))/(log(10))
#  scoreChange = Round( K * (result - E) )
#  K = 20
#  Because curve is mirrored around 0, uses only one table for positive side
#  Returns (scoreChangeA, scoreChangeB)     
func _getScoreChange{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(delta: felt, resultA: felt) -> (scoreChangeA: felt, scoreChangeB:felt):
    alloc_locals

    let (is_delta_positive) = is_nn(delta)
    let (abs_delta) = abs_value(delta)

    let (scoreChange) = _getScoreChangeFromDelta(abs_delta)

    # Depending on result (win/draw/lose), calculate score changes
    #Win
    if resultA == 2 :
        local inter = 20 - scoreChange
        if is_delta_positive == TRUE:
            return(inter, -scoreChange)
        end
        return(scoreChange, -inter)
    end

    #Draw
    if resultA == 1 :
        if is_delta_positive == TRUE:
            local inter = 10 - scoreChange
            return(inter, -inter)
        end
        local inter = scoreChange - 10
        return(inter, -inter)
    end

    #Lose
    local inter = scoreChange - 20
    if is_delta_positive == TRUE:
        return(inter, scoreChange)
    end
    return(-scoreChange, -inter)
end

func _getScoreChangeFromDelta{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(abs_delta: felt)->(scoreChange:felt):
    let (is_sup) = is_le(636,abs_delta)
    if is_sup == TRUE:
        return(20)
    end
    let (is_sup) = is_le(436,abs_delta)
        if is_sup == TRUE:
        return(19)
    end
    let (is_sup) = is_le(338,abs_delta)
    if is_sup == TRUE:
        return(18)
    end
    
    let (is_sup) = is_le(269,abs_delta)
    if is_sup == TRUE:
        return(17)
    end
    let (is_sup) = is_le(214,abs_delta)
        if is_sup == TRUE:
        return(16)
    end
    let (is_sup) = is_le(168,abs_delta)
    if is_sup == TRUE:
        return(15)
    end
    let (is_sup) = is_le(126,abs_delta)
        if is_sup == TRUE:
        return(14)
    end
    let (is_sup) = is_le(88,abs_delta)
        if is_sup == TRUE:
        return(13)
    end
    let (is_sup) = is_le(52,abs_delta)
        if is_sup == TRUE:
        return(12)
    end
    let (is_sup) = is_le(17,abs_delta)
        if is_sup == TRUE:
        return(11)
    end
    return(10)
end
