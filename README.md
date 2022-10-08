# Elo.cairo

Elo.cairo is a library that allow you to integrate easily a ranking system to your project.
The algorithm is based on the classic [chest ranking system](https://en.wikipedia.org/wiki/Elo_rating_system#Mathematical_details)


## Installation

### Protostar project
run :
```bash 
protostar install FabienCoutant/Elo.cairo
```

### Non-Protostar project
Copy/paste the [library file](/src/Elo/library.cairo) into your project.


## Usage

Import the library file into your logic file 

```cairo
from src.Elo.library import ELO
```

Add a getter in order to get the current Elo for a specfic address : 

```cairo
@view
func getScore{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    player_address: felt
) -> (score: Uint256) {
    let (score) = ELO.getScore(player_address);
    return (score,);
}
```

Add a function to record game result : 
```cairo 
@external
func recordResult{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    playerA_Address: felt, playerB_Address: felt, winner_Address: felt
) -> () {
    ELO.recordResult(playerA_Address, playerB_Address, winner_Address);
    return ();
}
```

**Enjoy your ranking system 😉**


