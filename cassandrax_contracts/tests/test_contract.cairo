use starknet::SyscallResultTrait;
use starknet::ContractAddress;

use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};

fn deploy_contract(contract_name: ByteArray) -> ContractAddress {
    let _contract: @snforge_std::ContractClass = declare(contract_name).unwrap_syscall().contract_class();
    let (contract_address, _) = _contract.deploy(@ArrayTrait::new()).unwrap_syscall();

    contract_address
}

#[cfg(test)]
mod tests {

use cassandrax_contracts::ICassandraXSafeDispatcherTrait;
use cassandrax_contracts::ICassandraXSafeDispatcher;
use starknet::ContractAddress;
use super::deploy_contract;

#[test]
#[feature("safe_dispatcher")]
    fn test_read_balance() {
        let contract_address: ContractAddress = deploy_contract("CassandraX");

        let safe_dispatcher: ICassandraXSafeDispatcher = ICassandraXSafeDispatcher { contract_address };
        let balance: u256 = safe_dispatcher.read_account_balance(contract_address).unwrap();

        println!("balance: {:?}", balance);

        assert_eq!(balance , 0)
    }

}

