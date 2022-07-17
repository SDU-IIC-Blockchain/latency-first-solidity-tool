pragma solidity >=0.7.0 <0.9.0;
pragma abicoder v2;

contract TransferBalance {
    uint256 constant PerformanceFactor = 1;
    uint256 constant StateSizeFactor = 1;

    struct __state_def_Transfer {
        uint64 Balance;
        bytes32[StateSizeFactor] Sig; // A time-consuming hash for simulating various gas costs
    }

    struct __tx_arg_Transfer {
        uint64 Value;
    }

    function __tx_do_Transfer(address[] memory addr, __state_def_Transfer[] memory states, __tx_arg_Transfer memory arg) public pure returns (__state_def_Transfer[] memory newStates) {
        require(addr.length == states.length, "assert error");
        require(addr.length == 2, "the number of accounts must be 2");
        newStates = new __state_def_Transfer[](addr.length);
        require(states[0].Balance >= arg.Value, "insufficient funds");
        newStates[0].Balance = states[0].Balance - arg.Value;
        newStates[1].Balance = states[1].Balance + arg.Value;
        for (uint256 i = 0; i < 2; i++) {
            newStates[i].Sig[i % StateSizeFactor] = states[i].Sig[i % StateSizeFactor];
            for (uint256 j = 0; j < PerformanceFactor; j++) {
                newStates[i].Sig[i % StateSizeFactor] = keccak256(
                    abi.encodePacked(newStates[i].Sig[i % StateSizeFactor], newStates[i].Balance)
                );
            }
        }
        return newStates;
    }

    function __state_hash_Transfer(__state_def_Transfer memory state, __tx_arg_Transfer memory arg) public pure returns (bytes32){
        return keccak256(abi.encodePacked(state.Balance, arg.Value));
    }

    function FundAccounts(address[] memory addr) public {
        for (uint i = 0; i < addr.length; i++) {
            __state_comp_dict_Transfer[addr[i]].Latest.Balance = 10000;
        }
    }

    function GetAccountBalance(address addr) public returns (uint64){
        return __state_comp_dict_Transfer[addr].Latest.Balance;
    }

}