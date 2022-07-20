pragma solidity >=0.7.0 <0.9.0;
pragma abicoder v2;

contract __Template {
    mapping(address => __state_comp_element_NAME) public __state_comp_dict_NAME;

    struct __pending_state_element_NAME {
        bytes32 StateHash;
        bytes32 FunctionArgHash;
    }

    struct __state_comp_element_NAME {
        __pending_state_element_NAME[] PendingStates;
        __state_def_NAME Latest;
    }

    function __tx_online_NAME(address[] memory addr, __tx_arg_def_NAME memory arg) public {
        __state_def_NAME[] memory currentStates = new __state_def_NAME[](addr.length);
        for (uint256 i = 0; i < addr.length; i++) {
            require(__state_comp_dict_NAME[addr[i]].PendingStates.length == 0, "account has unfinished commitments");
            currentStates[i] = (__state_comp_dict_NAME[addr[i]].Latest);
        }

        __state_def_NAME[] memory newStates = __tx_do_NAME(addr, currentStates, arg);

        for (uint256 i = 0; i < addr.length; i++) {
            __state_comp_dict_NAME[addr[i]].Latest = newStates[i];
        }
    }

    function __tx_proof_NAME(address[] memory addr, __tx_arg_def_NAME memory arg) public {
        __state_def_NAME[] memory currentStates = new __state_def_NAME[](addr.length);
        for (uint i = 0; i < addr.length; i++) {
            require(__state_comp_dict_NAME[addr[i]].PendingStates.length >= 1, "account does not have unfinished commitments");
            // unnecessary. let it crash
            currentStates[i] = (__state_comp_dict_NAME[addr[i]].Latest);
        }
        __state_def_NAME[] memory newStates = __tx_do_NAME(addr, currentStates, arg);

        for (uint i = 0; i < addr.length; i++) {
            bytes32 stateHash = __state_hash_NAME(newStates[i]);
            bytes32 argHash = __tx_arg_hash_NAME(arg);
            require(stateHash == __state_comp_dict_NAME[addr[i]].PendingStates[0].StateHash, "commitment mismatch");
            require(argHash == __state_comp_dict_NAME[addr[i]].PendingStates[0].FunctionArgHash, "commitment mismatch");
        }

        // https://stackoverflow.com/questions/70752502/how-to-remove-an-array-elemet-from-a-certain-prosition-in-solidity

        for (uint i = 0; i < addr.length; i++) {
            uint index = 0;
            for (uint j = index; j < __state_comp_dict_NAME[addr[i]].PendingStates.length - 1; j++) {
                __state_comp_dict_NAME[addr[i]].PendingStates[j] = __state_comp_dict_NAME[addr[i]].PendingStates[j + 1];
            }
            __state_comp_dict_NAME[addr[i]].PendingStates.pop();
            __state_comp_dict_NAME[addr[i]].Latest = newStates[i];
        }

    }

    function __tx_offline_NAME(address[] memory addr, __state_def_NAME[] memory states, __tx_arg_def_NAME memory arg) public pure
    returns (__state_def_NAME[] memory newStates, __pending_state_element_NAME[] memory newStateHashes){
        newStates = __tx_do_NAME(addr, states, arg);
        newStateHashes = new __pending_state_element_NAME[](addr.length);
        for (uint i = 0; i < addr.length; i++) {
            newStateHashes[i].StateHash = __state_hash_NAME(newStates[i]);
            newStateHashes[i].FunctionArgHash = __tx_arg_hash_NAME(arg);
        }
        return (newStates, newStateHashes);
    }

    function __tx_commit_NAME(address[] memory addr, __pending_state_element_NAME[] memory pendingStates) public {
        for (uint i = 0; i < addr.length; i++) {
            __state_comp_dict_NAME[addr[i]].PendingStates.push(pendingStates[i]);
        }
    }

    function __tx_pending_len_NAME(address addr) public view returns (uint){
        return __state_comp_dict_NAME[addr].PendingStates.length;
    }

    function __tx_state_latest_NAME(address addr) public view returns (__state_def_NAME memory){
        return __state_comp_dict_NAME[addr].Latest;
    }

    function __tx_last_pending_state_NAME(address addr) public view returns (__pending_state_element_NAME memory){
        return __state_comp_dict_NAME[addr].PendingStates[__state_comp_dict_NAME[addr].PendingStates.length - 1];
    }
}