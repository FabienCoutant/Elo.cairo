%lang starknet
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc
from lib.cairo_math_64x61.contracts.cairo_math_64x61.math64x61 import Math64x61
from starkware.cairo.common.math_cmp import is_nn, is_le
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address
from protostar.asserts import (
    assert_eq,
    assert_not_eq,
    assert_signed_lt,
    assert_signed_le,
    assert_signed_gt,
    assert_unsigned_lt,
    assert_unsigned_le,
    assert_unsigned_gt,
    assert_signed_ge,
    assert_unsigned_ge,
)

@contract_interface
namespace EloTestingContract {
    func setScore(player_address: felt, player_score: Uint256) -> () {
    }

    func getScore(player_address: felt) -> (score: Uint256) {
    }

    func recordResult(playerA_Address: felt, playerB_Address: felt, winner_Address: felt) -> () {
    }

}

struct GameResult {
    playerA_Address: felt,
    playerB_Address: felt,
    winner_Address: felt,
    expected_PlayerA_Score: Uint256,
    expected_PlayerB_Score: Uint256,
}

func _record_multi_result{syscall_ptr: felt*, range_check_ptr}(games_len : felt, i:felt , gameResult : GameResult*, contract_address:felt) {
    if (games_len == i ){
        return ();
    }
    tempvar playerA_Address= gameResult[i].playerA_Address;
    tempvar playerB_Address= gameResult[i].playerB_Address;
    tempvar winner_Address= gameResult[i].winner_Address;
    EloTestingContract.recordResult(
        contract_address=contract_address,
        playerA_Address= playerA_Address,
        playerB_Address=playerB_Address,
        winner_Address=winner_Address,
    );

    let (new_PlayerA_Score) = EloTestingContract.getScore(
        contract_address=contract_address, player_address=playerA_Address
    );
    let (new_PlayerB_Score) = EloTestingContract.getScore(
        contract_address=contract_address, player_address=playerB_Address
    );

    with_attr error_message("Player A score should be equal to expected score") {
        assert new_PlayerA_Score = gameResult[i].expected_PlayerA_Score;
    }
    with_attr error_message("Player B score should be equal to expected score") {
        assert new_PlayerB_Score = gameResult[i].expected_PlayerB_Score;
    }
    _record_multi_result(games_len,i+1, gameResult,contract_address);
    return ();
}

@external
func __setup__{syscall_ptr: felt*, range_check_ptr}() {
    %{ context.EloTest_address = deploy_contract("./src/EloTest.cairo").contract_address %}
    return ();
}

@external
func test_init_score_equal_100{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local contract_address: felt;
    %{ ids.contract_address = context.EloTest_address %}

    let (res) = EloTestingContract.getScore(
        contract_address=contract_address, player_address=contract_address
    );

    with_attr error_message("Initial score is not equal to 100") {
        assert res = Uint256(100, 0);
    }
    return ();
}

@external
func test_recordResult_with_player_A_as_winner{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local contract_address: felt;
    %{ ids.contract_address = context.EloTest_address %}

    let (playerA_Address) = get_caller_address();
    local playerB_Address = 0x033241da2ff902C3564165489FD9c889FA950483C3250b72f330E773d7A01861;

    let (playerA_score_before) = EloTestingContract.getScore(
        contract_address=contract_address, player_address=playerA_Address
    );
    let (playerB_score_before) = EloTestingContract.getScore(
        contract_address=contract_address, player_address=playerB_Address
    );

    with_attr error_message("Player A and B score should be equal to 100") {
        assert playerA_score_before = Uint256(100, 0);
        assert playerB_score_before = Uint256(100, 0);
    }

    EloTestingContract.recordResult(
        contract_address=contract_address,
        playerA_Address=playerA_Address,
        playerB_Address=playerB_Address,
        winner_Address=playerA_Address,
    );

    %{
        expect_events(
            {"name": "EloScoreUpdate", "data":[ids.playerA_Address,110], "from_address": ids.contract_address},
            {"name": "EloScoreUpdate","data":[ids.playerB_Address,100], "from_address": ids.contract_address}
        )
    %}

    let (playerA_score_after) = EloTestingContract.getScore(
        contract_address=contract_address, player_address=playerA_Address
    );
    let (playerB_score_after) = EloTestingContract.getScore(
        contract_address=contract_address, player_address=playerB_Address
    );

    with_attr error_message("Player A score should be equal to 110") {
        assert playerA_score_after = Uint256(110, 0);
    }

    with_attr error_message("Player B score should be equal to 100") {
        assert playerB_score_before = Uint256(100, 0);
    }
    return ();
}

@external
func test_recordResult_with_player_B_as_winner{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local contract_address: felt;
    %{ ids.contract_address = context.EloTest_address %}

    let (playerA_Address) = get_caller_address();
    local playerB_Address = 0x033241da2ff902C3564165489FD9c889FA950483C3250b72f330E773d7A01861;

    let (playerA_score_before) = EloTestingContract.getScore(
        contract_address=contract_address, player_address=playerA_Address
    );
    let (playerB_score_before) = EloTestingContract.getScore(
        contract_address=contract_address, player_address=playerB_Address
    );

    with_attr error_message("Player A and B score should be equal to 100") {
        assert playerA_score_before = Uint256(100, 0);
        assert playerB_score_before = Uint256(100, 0);
    }

    EloTestingContract.recordResult(
        contract_address=contract_address,
        playerA_Address=playerA_Address,
        playerB_Address=playerB_Address,
        winner_Address=playerB_Address,
    );

    %{
        expect_events(
            {"name": "EloScoreUpdate", "data":[ids.playerA_Address,100], "from_address": ids.contract_address},
            {"name": "EloScoreUpdate","data":[ids.playerB_Address,110], "from_address": ids.contract_address}
        )
    %}

    let (playerA_score_after) = EloTestingContract.getScore(
        contract_address=contract_address, player_address=playerA_Address
    );
    let (playerB_score_after) = EloTestingContract.getScore(
        contract_address=contract_address, player_address=playerB_Address
    );

    with_attr error_message("Player A score should be equal to 100") {
        assert playerA_score_after = Uint256(100, 0);
    }

    with_attr error_message("Player B score should be equal to 110") {
        assert playerB_score_after = Uint256(110, 0);
    }

    return ();
}


@external
func test_recordResult_with_draw{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;

    local contract_address: felt;
    %{ ids.contract_address = context.EloTest_address %}

    let (playerA_Address) = get_caller_address();
    local playerB_Address = 0x033241da2ff902C3564165489FD9c889FA950483C3250b72f330E773d7A01861;
    local NULL_ADDRESS = 0x0000000000000000000000000000000000000000000000000000000000000001;

    let (playerA_score_before) = EloTestingContract.getScore(
        contract_address=contract_address, player_address=playerA_Address
    );
    let (playerB_score_before) = EloTestingContract.getScore(
        contract_address=contract_address, player_address=playerB_Address
    );

    with_attr error_message("Player A and B score should be equal to 100") {
        assert playerA_score_before = Uint256(100, 0);
        assert playerB_score_before = Uint256(100, 0);
    }

    EloTestingContract.recordResult(
        contract_address=contract_address,
        playerA_Address=playerA_Address,
        playerB_Address=playerB_Address,
        winner_Address=NULL_ADDRESS,
    );

    %{
        expect_events(
            {"name": "EloScoreUpdate", "data":[ids.playerA_Address,100], "from_address": ids.contract_address},
            {"name": "EloScoreUpdate","data":[ids.playerB_Address,100], "from_address": ids.contract_address}
        )
    %}

    let (playerA_score_after) = EloTestingContract.getScore(
        contract_address=contract_address, player_address=playerA_Address
    );
    let (playerB_score_after) = EloTestingContract.getScore(
        contract_address=contract_address, player_address=playerB_Address
    );

    with_attr error_message("Player A score should be equal to previous score") {
        assert playerA_score_after = playerA_score_before;
    }

    with_attr error_message("Player B score should be equal to previous score") {
        assert playerB_score_after = playerB_score_before;
    }

    return ();
}

@external
func test_recordResult_multi{syscall_ptr: felt*, range_check_ptr}() {
    alloc_locals;
    
    local contract_address: felt;
    %{ ids.contract_address = context.EloTest_address %}

    let (playerA_Address) = get_caller_address();
    local playerB_Address = 0x033241da2ff902C3564165489FD9c889FA950483C3250b72f330E773d7A01861;
    local NULL_ADDRESS = 0x0000000000000000000000000000000000000000000000000000000000000001;

    let (local gamesResult: GameResult* )= alloc();
    assert gamesResult[0] = GameResult( playerA_Address,playerB_Address, playerA_Address, Uint256(110,0), Uint256(100,0)); // +10, -10 (floored at 100)
    assert gamesResult[1]= GameResult( playerA_Address,playerB_Address, playerA_Address, Uint256(119,0), Uint256(100,0)); // +9, -9
    assert gamesResult[2] = GameResult(playerA_Address,playerB_Address, playerA_Address, Uint256(128,0), Uint256(100,0)); // +9, -9
    assert gamesResult[3] = GameResult(playerA_Address,playerB_Address, playerA_Address, Uint256(137,0), Uint256(100,0)); // +9, -9 
    assert gamesResult[4] = GameResult(playerA_Address,playerB_Address, playerA_Address, Uint256(145,0), Uint256(100,0)); // +8, -8
    assert gamesResult[5] = GameResult(playerA_Address,playerB_Address, playerB_Address, Uint256(133,0), Uint256(111,0)); // -12, +11
    assert gamesResult[6] = GameResult(playerA_Address,playerB_Address, playerB_Address, Uint256(122,0), Uint256(121,0)); // -11, +10
    assert gamesResult[7] = GameResult(playerA_Address,playerB_Address, playerA_Address, Uint256(131,0), Uint256(111,0)); // +9, -9
    assert gamesResult[8] = GameResult(playerA_Address,playerB_Address, playerA_Address, Uint256(140,0), Uint256(101,0)); // +9, -11
    assert gamesResult[9] = GameResult(playerA_Address,playerB_Address, playerA_Address, Uint256(148,0), Uint256(100,0)); // +8, -8
    assert gamesResult[10] = GameResult(playerA_Address,playerB_Address, playerA_Address, Uint256(156,0), Uint256(100,0)); // +8, -8
    assert gamesResult[11] = GameResult(playerA_Address,playerB_Address, playerA_Address, Uint256(164,0), Uint256(100,0)); // +8, -8
    assert gamesResult[12] = GameResult(playerA_Address,playerB_Address, playerA_Address, Uint256(172,0), Uint256(100,0)); // +8, -8
    assert gamesResult[13] = GameResult(playerA_Address,playerB_Address, playerB_Address, Uint256(159,0), Uint256(112,0)); // -23, +12
    assert gamesResult[14] = GameResult(playerA_Address,playerB_Address, NULL_ADDRESS, Uint256(157,0), Uint256(113,0)); // -2, +1
    assert gamesResult[15] = GameResult(playerA_Address,playerB_Address, playerB_Address, Uint256(145,0), Uint256(124,0)); // -8, +11
    assert gamesResult[16] = GameResult(playerA_Address,playerB_Address, playerB_Address, Uint256(134,0), Uint256(134,0)); // -11, +10
    assert gamesResult[17] = GameResult(playerA_Address,playerB_Address, NULL_ADDRESS, Uint256(134,0), Uint256(134,0)); // +0, +0

    _record_multi_result(18,0,gamesResult, contract_address);

    return ();
}