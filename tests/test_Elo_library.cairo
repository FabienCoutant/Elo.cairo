%lang starknet
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address
from protostar.asserts import (
    assert_eq, assert_not_eq, assert_signed_lt, assert_signed_le, assert_signed_gt,
    assert_unsigned_lt, assert_unsigned_le, assert_unsigned_gt, assert_signed_ge,
    assert_unsigned_ge
    )

@contract_interface
namespace EloTestingContract:
    func setScore(player_address: felt, player_score: Uint256) -> ():
    end

    func getScore(player_address: felt) -> (score: Uint256):
    end

    func recordResult(player1Address: felt, player2Address: felt, winnerAddress:felt) -> ():
    end

end

@external
func __setup__{syscall_ptr : felt*, range_check_ptr}():
    # deploy
    %{
        context.EloTest_address = deploy_contract("./src/EloTest.cairo").contract_address
    %}
    return()
end

@external
func test_init_score_equal_100{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    local contract_address: felt
    %{ ids.contract_address = context.EloTest_address %}

    let (res) = EloTestingContract.getScore(contract_address=contract_address, player_address=contract_address)

    with_attr error_message("Initial score is not equal to 100"):
        assert res = Uint256(100,0)
    end
    return()
end


@external
func test_setScore{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    local contract_address: felt
    %{ ids.contract_address = context.EloTest_address %}


    EloTestingContract.setScore(contract_address=contract_address,player_address=contract_address, player_score=Uint256(200, 0))

    let (res) = EloTestingContract.getScore(contract_address=contract_address, player_address=contract_address)
    
    with_attr error_message("New score is not equal to 200"):
        assert res = Uint256(200,0)
    end
    return ()
end

@external
func test_recordResult_with_playerA_as_winner{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    local contract_address: felt
    %{ ids.contract_address = context.EloTest_address %}

    let (sender_address) = get_caller_address()


    let (playerA_score_before) = EloTestingContract.getScore(contract_address=contract_address, player_address=contract_address)
    let (playerB_score_before) = EloTestingContract.getScore(contract_address=contract_address, player_address=sender_address)
    
    with_attr error_message("Player A and B score should be equal to 100"):
        assert playerA_score_before = Uint256(100,0)
        assert playerB_score_before = Uint256(100,0)
    end

    EloTestingContract.recordResult(contract_address=contract_address, player1Address=contract_address, player2Address=sender_address, winnerAddress=contract_address)


    let (playerA_score_after) = EloTestingContract.getScore(contract_address=contract_address, player_address=contract_address)
    let (playerB_score_after) = EloTestingContract.getScore(contract_address=contract_address, player_address=sender_address)

    with_attr error_message("Player A score should be equal to 110"):
        assert playerA_score_after = Uint256(110,0)
    end
    
    with_attr error_message("Player B score should be equal to 100"):
        assert playerB_score_before = Uint256(100,0)
    end
        
    
    return ()
end