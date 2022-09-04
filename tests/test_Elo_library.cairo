%lang starknet
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math_cmp import (is_nn, is_le)
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

    func recordResult(playerA_Address: felt, playerB_Address: felt, winner_Address:felt) -> ():
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
func test_recordResult_with_player_A_as_winner{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    local contract_address: felt
    %{ ids.contract_address = context.EloTest_address %}

    let (playerA_Address) = get_caller_address()
    local playerB_Address = 0x033241da2ff902C3564165489FD9c889FA950483C3250b72f330E773d7A01861

    let (playerA_score_before) = EloTestingContract.getScore(contract_address=contract_address, player_address=playerA_Address)
    let (playerB_score_before) = EloTestingContract.getScore(contract_address=contract_address, player_address=playerB_Address)
    
    with_attr error_message("Player A and B score should be equal to 100"):
        assert playerA_score_before = Uint256(100,0)
        assert playerB_score_before = Uint256(100,0)
    end

    EloTestingContract.recordResult(contract_address=contract_address, playerA_Address=playerA_Address, playerB_Address=playerB_Address, winner_Address=playerA_Address)

    
    %{ 
        expect_events(
            {"name": "EloScoreUpdate", "data":[ids.playerA_Address,110], "from_address": ids.contract_address},
            {"name": "EloScoreUpdate","data":[ids.playerB_Address,100], "from_address": ids.contract_address}
        )
    %}

    let (playerA_score_after) = EloTestingContract.getScore(contract_address=contract_address, player_address=playerA_Address)
    let (playerB_score_after) = EloTestingContract.getScore(contract_address=contract_address, player_address=playerB_Address)

    with_attr error_message("Player A score should be equal to 110"):
        assert playerA_score_after = Uint256(110,0)
    end
    
    with_attr error_message("Player B score should be equal to 100"):
        assert playerB_score_before = Uint256(100,0)
    end 
    return ()
end

@external
func test_recordResult_with_player_B_as_winner{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    local contract_address: felt
    %{ 
        ids.contract_address = context.EloTest_address 
    %}

    let (playerA_Address) = get_caller_address()
    local playerB_Address = 0x033241da2ff902C3564165489FD9c889FA950483C3250b72f330E773d7A01861

    let (playerA_score_before) = EloTestingContract.getScore(contract_address=contract_address, player_address=playerA_Address)
    let (playerB_score_before) = EloTestingContract.getScore(contract_address=contract_address, player_address=playerB_Address)
    
    with_attr error_message("Player A and B score should be equal to 100"):
        assert playerA_score_before = Uint256(100,0)
        assert playerB_score_before = Uint256(100,0)
    end

    EloTestingContract.recordResult(contract_address=contract_address, playerA_Address=playerA_Address, playerB_Address=playerB_Address, winner_Address=playerB_Address)

    %{ 
        expect_events(
            {"name": "EloScoreUpdate", "data":[ids.playerA_Address,100], "from_address": ids.contract_address},
            {"name": "EloScoreUpdate","data":[ids.playerB_Address,110], "from_address": ids.contract_address}
        )
    %}

    let (playerA_score_after) = EloTestingContract.getScore(contract_address=contract_address, player_address=playerA_Address)
    let (playerB_score_after) = EloTestingContract.getScore(contract_address=contract_address, player_address=playerB_Address)

    with_attr error_message("Player A score should be equal to 100"):
        assert playerA_score_after = Uint256(100,0)
    end
    
    with_attr error_message("Player B score should be equal to 110"):
        assert playerB_score_after = Uint256(110,0)
    end
        
    return ()
end

@external
func test_recordResult_with_draw{syscall_ptr : felt*, range_check_ptr}():
    alloc_locals

    local contract_address: felt
    %{ 
        ids.contract_address = context.EloTest_address 
    %}

    let (playerA_Address) = get_caller_address()
    local playerB_Address = 0x033241da2ff902C3564165489FD9c889FA950483C3250b72f330E773d7A01861
    local NULL_ADDRESS = 0x0000000000000000000000000000000000000000000000000000000000000000

    let (playerA_score_before) = EloTestingContract.getScore(contract_address=contract_address, player_address=playerA_Address)
    let (playerB_score_before) = EloTestingContract.getScore(contract_address=contract_address, player_address=playerB_Address)
    
    with_attr error_message("Player A and B score should be equal to 100"):
        assert playerA_score_before = Uint256(100,0)
        assert playerB_score_before = Uint256(100,0)
    end


    EloTestingContract.recordResult(contract_address=contract_address, playerA_Address=playerA_Address, playerB_Address=playerB_Address, winner_Address=NULL_ADDRESS)
    
    %{ 
        expect_events(
            {"name": "EloScoreUpdate", "data":[ids.playerA_Address,100], "from_address": ids.contract_address},
            {"name": "EloScoreUpdate","data":[ids.playerB_Address,100], "from_address": ids.contract_address}
        )
    %}

    let (playerA_score_after) = EloTestingContract.getScore(contract_address=contract_address, player_address=playerA_Address)
    let (playerB_score_after) = EloTestingContract.getScore(contract_address=contract_address, player_address=playerB_Address)

    with_attr error_message("Player A score should be equal to previous score"):
        assert playerA_score_after = playerA_score_before
    end
    
    with_attr error_message("Player B score should be equal to previous score"):
        assert playerB_score_after = playerB_score_before
    end
        
    return ()
end