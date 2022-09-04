%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from src.Elo.library import ELO


@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    return ()
end

@external
func setScore{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(player_address: felt, player_score: Uint256) -> ():
    ELO.setScore(player_address, player_score)
    return ()
end

@external
  func recordResult{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(player1Address: felt, player2Address: felt, winnerAddress:felt) -> ():
    ELO.recordResult(player1Address, player2Address, winnerAddress)
    return ()
end

@view
func getScore{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(player_address: felt) -> (score: Uint256):
    let (score) = ELO.getScore(player_address)
    return (score)
end


