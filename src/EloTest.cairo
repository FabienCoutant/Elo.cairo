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
  func recordResult{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(playerA_Address: felt, playerB_Address: felt, winner_Address:felt) -> ():
    ELO.recordResult(playerA_Address, playerB_Address, winner_Address)
    return ()
end

@view
func getScore{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(player_address: felt) -> (score: Uint256):
    let (score) = ELO.getScore(player_address)
    return (score)
end

