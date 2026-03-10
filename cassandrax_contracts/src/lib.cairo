use openzeppelin_interfaces::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};
/// Dependencies
use starknet::ContractAddress;

/// Custom types
#[derive(Drop, Serde, Copy, starknet::Store)]
struct OptionContract {
    expiry: felt252,
    option_type: felt252,
    strike_price: u256,
    premium: u256,
    option_buyer: ContractAddress,
    option_writer: ContractAddress,
    pay_off: u256,
}

/// Interface definitions for `Cassandra` that can be called externally.
#[starknet::interface]
pub trait ICassandraX<TContractState> {
    /// modify contract state
    //  write an options contract
    fn write_option_contract(ref self: TContractState, option_contract: OptionContract);

    // buy an options contract
    fn buy_option_contract(ref self: TContractState, option_txn_id: u256);

    // deposit USDC
    fn deposit_usdc(ref self: TContractState, amount: u256);

    // withdraw USDC
    fn withdraw_usdc(ref self: TContractState, amount: u256);

    // update btc price
    fn update_bitcoin_price(ref self: TContractState, price: u256);

    // settle contract
    fn settle_contract(ref self: TContractState, option_txn_id: u256);

    // change oracle
    fn change_oracle(ref self: TContractState, oracle: ContractAddress);

    // update USDC adddress
    fn update_usdc_contract_address(
        ref self: TContractState, usdc_contract_address: ContractAddress,
    );


    /// read contract state
    // all contracts
    fn list_all_contracts(self: @TContractState) -> Array<(u256, OptionContract)>;

    // by owner
    //fn list_all_available_contracts_by_owner(self: @TContractState);

    // by buyer
    //fn list_all_available_contracts_by_buyer(self: @TContractState);

    // get option by id
    fn list_option_contract_by_id(self: @TContractState, option_txn_id: u256) -> OptionContract;

    // get option writer cash security
    fn get_option_writer_cash_security(self: @TContractState, account_address: ContractAddress) -> u256;

    // read account balance
    fn read_account_balance(self: @TContractState, account_address: ContractAddress) -> u256;

    // read oracle contract
    fn read_oracle_contract_address(self: @TContractState) -> ContractAddress;

    // read btc price
    fn read_btc_price(self: @TContractState) -> u256;

    // read usdc address price
    fn read_usdc_contract_address(self: @TContractState) -> ContractAddress;
}

/// Contract Events
// #[derive(Drop, starknet::Event)]
// enum CassandraEvents {
//     SettlementBitcoinPriceChange: ChangeRequested,
// }

#[derive(Drop, starknet::Event)]
struct ChangeRequested {
    #[key]
    caller: ContractAddress,
    oracle: ContractAddress,
    price: u256,
}

#[derive(Drop, starknet::Event)]
struct ContractLog {
    #[key]
    variable: felt252,
    msg: felt252,
}

#[derive(Drop, starknet::Event)]
struct ContractLogNumber {
    #[key]
    variable: u256,
    msg: felt252,
}

#[derive(Drop, starknet::Event)]
struct ContractLogAddress {
    #[key]
    variable: ContractAddress,
    msg: felt252,
}

/// Options contract.
#[starknet::contract]
mod CassandraX {
use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use crate::OptionContract;
    use super::{ChangeRequested, ContractLog, ContractLogNumber, ContractLogAddress, IERC20Dispatcher, IERC20DispatcherTrait};

    #[storage]
    struct Storage {
        /// Storage of contract data

        // account balance
        account_balance: Map<ContractAddress, u256>,
        // options contract registry
        option_txn_id_counter: u256,
        option_contract_map: Map<u256, OptionContract>,
        // cash security
        cash_security_map: Map<ContractAddress, u256>,
        // current btc price
        current_btc_price: u256,
        // usdc contract address
        usdc_contract_address: ContractAddress,
        // oracle contract address
        oracle_contract_address: ContractAddress,
    }

    // Events
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        SettlementBitcoinPriceChange: ChangeRequested,
        ContractLogs: ContractLog,
        ContractLogsNumber: ContractLogNumber,
        ContractLogsAddress : ContractLogAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        // initial values for oracle_contract_address and usdc_contract_address
        let _oracle_contract_address_felt: felt252 =
            0x01909473ba2299c0aef645125fa8443d7aac05fda521ae0eda61fff5d008efb6;
        let _usdc_contract_address_felt: felt252 =
            0x0512feac6339ff7889822cb5aa2a86c848e9d392bb0e3e237c008674feed8343;

        let _oracle_contract_address: ContractAddress = _oracle_contract_address_felt
            .try_into()
            .unwrap();
        let _usdc_contract_address: ContractAddress = _usdc_contract_address_felt
            .try_into()
            .unwrap();

        // oracle
        self.oracle_contract_address.write(_oracle_contract_address);

        // usdc contract
        self.usdc_contract_address.write(_usdc_contract_address);
    }

    #[abi(embed_v0)]
    impl CassandraXImpl of super::ICassandraX<ContractState> {
        /// implimentation public functions

        fn write_option_contract(ref self: ContractState, option_contract: OptionContract) {
            let _contract_writer_address: ContractAddress = get_caller_address();

            // compute max pay off for option
            let _strikePrice_value: u256 = option_contract.strike_price;
            let _max_payoff_value: u256 = max_payoff(_strikePrice_value);

            // account balance
            let _options_writer_account_balance: u256 = self
                ._read_account_balance(_contract_writer_address);

            // check if options writer has sufficent funds to secure option
            let _options_writer_account_suffiucient: bool =
                (_options_writer_account_balance > _max_payoff_value);

            // returns err if _options_writer_account_suffiucient is false
            // assert!(!_options_writer_account_suffiucient, "You dont have enough USDC to write a
            // contract")

            if (_options_writer_account_suffiucient) {
                // update cash security for contract writer
                self._update_cash_security(_contract_writer_address, _max_payoff_value);

                // log _max_payoff_value
                self.emit(Event::ContractLogsNumber(
                            ContractLogNumber { variable: _max_payoff_value, msg: '_max_payoff_value' },
                        )
                    );

                // update option writer with function caller
                let mut _option_contract_with_writer: OptionContract = option_contract;
                _option_contract_with_writer.option_writer = _contract_writer_address;

                // store options contract on chain
                self._write_option_contract(_option_contract_with_writer);
            }

            if (!_options_writer_account_suffiucient) {
                self.emit(Event::ContractLogs(
                            ContractLog { variable: (!_options_writer_account_suffiucient).into(), msg: 'Not enough USDC' },
                        )
                    );
            }
        }

        fn buy_option_contract(ref self: ContractState, option_txn_id: u256) {
            let _contract_buyer_address: ContractAddress = get_caller_address();
            self._buy_option_contract(option_txn_id, _contract_buyer_address);
            
        }

        fn deposit_usdc(ref self: ContractState, amount: u256) {
            let _account_owner: ContractAddress = get_caller_address();
            let _cassandra_contract: ContractAddress = get_contract_address();

            // User must have called erc20.approve(this_contract, amount) via front end
            let _usdc_token = IERC20Dispatcher {
                contract_address: self.usdc_contract_address.read(),
            };

            _usdc_token.transfer_from(_account_owner, _cassandra_contract, amount);

            // update account balance
            self._credit_balance(_account_owner, amount);
        }

        fn withdraw_usdc(ref self: ContractState, amount: u256) {
            let _account_owner: ContractAddress = get_caller_address();

            // User must have called erc20.approve(this_contract, amount) via front end
            let _usdc_token = IERC20Dispatcher {
                contract_address: self.usdc_contract_address.read(),
            };

            let _owner_account_balance: u256 = self._read_account_balance(_account_owner);
            let are_funds_sufficient: bool = _owner_account_balance >= amount;

            //assert!(!are_funds_sufficient, "Insfuccicent funds");

            if (are_funds_sufficient) {
                // send usdc to owner wallet
                _usdc_token.transfer(_account_owner, amount);

                // update account balance
                self._debit_balance(_account_owner, amount);
            }

            if (!are_funds_sufficient) {
                self.emit(Event::ContractLogs(
                            ContractLog { variable: (!are_funds_sufficient).into(), msg: 'Insfuccicent funds' },
                        )
                    );
            }
        }

        fn update_bitcoin_price(ref self: ContractState, price: u256) {
            let _caller_address: ContractAddress = get_caller_address();
            let _oracle_address: ContractAddress = self.oracle_contract_address.read();

            let caller_is_oracle: bool = (_caller_address == _oracle_address);

            self
                .emit(
                    Event::SettlementBitcoinPriceChange(
                        ChangeRequested {
                            caller: _caller_address, oracle: _oracle_address, price: price,
                        },
                    ),
                );

            //assert!(!caller_is_oracle, "Only an oracle can set prices")

            if (caller_is_oracle) {
                // update btc price
                self._update_bitcoin_price(price);
            }

            if (!caller_is_oracle) {
                self.emit(Event::ContractLogs(
                            ContractLog { variable: (!caller_is_oracle).into(), msg: 'Only an oracle can set prices' },
                        )
                    );
            }
        }

        fn settle_contract(ref self: ContractState, option_txn_id: u256) {
            let _caller_address: ContractAddress = get_caller_address();
            let _oracle_address: ContractAddress = self.oracle_contract_address.read();

            let caller_is_oracle: bool = (_caller_address == _oracle_address);

            //assert!(!caller_is_oracle, "Only an can set settle contracts");

            if (caller_is_oracle) {
                // settle contract
                self._settle_option_contract(option_txn_id);
            }

            if (!caller_is_oracle) {
                self.emit(Event::ContractLogs(
                            ContractLog { variable: (!caller_is_oracle).into(), msg: 'Only oracle can settle' },
                        )
                    );
            }
        }

        fn change_oracle(ref self: ContractState, oracle: ContractAddress) {
            let _caller_address: ContractAddress = get_caller_address();
            let _oracle_address: ContractAddress = self.oracle_contract_address.read();

            let caller_is_oracle: bool = (_caller_address == _oracle_address);

            //assert!(!caller_is_oracle, "Only an can set settle contracts");

            if (caller_is_oracle) {
                // change oracle
                self._change_oracle(oracle);
            }

            if (!caller_is_oracle) {
                self.emit(Event::ContractLogs(
                            ContractLog { variable: (!caller_is_oracle).into(), msg: 'Only an can set oracle' },
                        )
                    );
            }
        }

        fn update_usdc_contract_address(
            ref self: ContractState, usdc_contract_address: ContractAddress,
        ) {
            let _caller_address: ContractAddress = get_caller_address();
            let _oracle_address: ContractAddress = self.oracle_contract_address.read();

            let caller_is_oracle: bool = (_caller_address == _oracle_address);

            //assert!(!caller_is_oracle, "Only an can set settle contracts");

            if (caller_is_oracle) {
                // update usdc contract address
                self._update_usdc_contract_address(usdc_contract_address);
            }

            if (!caller_is_oracle) {
                self.emit(Event::ContractLogs(
                            ContractLog { variable: (!caller_is_oracle).into(), msg: 'Only an can set usdc contract' },
                        )
                    );
            }
        }

        fn list_all_contracts(self: @ContractState) -> Array<(u256, OptionContract)> {
            let options_contract_list: Array<(u256, OptionContract)> = self._list_all_contracts();
            options_contract_list
        }

        fn list_option_contract_by_id(self: @ContractState, option_txn_id: u256) -> OptionContract {
            let _optioncontract: OptionContract = self._list_option_contract_by_id(option_txn_id);
            _optioncontract
        }

        fn get_option_writer_cash_security(self: @ContractState, account_address: ContractAddress) -> u256 {
            let option_writer_cash_security: u256 = self._get_option_writer_cash_security(account_address);
            option_writer_cash_security
        }

        fn read_account_balance(self: @ContractState, account_address: ContractAddress) -> u256 {
            self._read_account_balance(account_address)
        }

        // read oracle contract
        fn read_oracle_contract_address(self: @ContractState) -> ContractAddress {
            self._read_oracle_contract_address()
        }

        // read btc price
        fn read_btc_price(self: @ContractState) -> u256 {
            let _btc_price: u256 = self._read_btc_price();
            _btc_price
        }

        // read usdc address price
        fn read_usdc_contract_address(self: @ContractState) -> ContractAddress {
            let _usdc_contract_address: ContractAddress = self._read_usdc_contract_address();
            _usdc_contract_address
        }
    }

    #[generate_trait]
    impl Internal of InternalTrait {
        /// internal functions with access to contract state
        /// can only be called with in the contract, start with _

        fn _write_option_contract(ref self: ContractState, option_contract: OptionContract) {
            // update counter
            let current_txn_id_counter: u256 = self.option_txn_id_counter.read();

            // write new contract to option contract map
            self.option_contract_map.entry(current_txn_id_counter).write(option_contract);

            // update counter
            let newest_txn_id_counter: u256 = current_txn_id_counter + 1;
            self.option_txn_id_counter.write(newest_txn_id_counter);
        }

        fn _buy_option_contract(ref self: ContractState, option_txn_id: u256, option_buyer_address: ContractAddress,) {
            // buyers account balance
            let _option_buyer_account_balance: u256 = self
                ._read_account_balance(option_buyer_address);
            let _option_contract_details: OptionContract = self
                .option_contract_map
                .entry(option_txn_id)
                .read();
            let _option_contract_premuim: u256 = _option_contract_details.premium;

            let _current_option_buyer: ContractAddress = _option_contract_details.option_buyer;
            let _default_option_buyer: ContractAddress = (0).try_into().unwrap();

            if (_current_option_buyer == _default_option_buyer) {
              // only new buyers
              if (_option_buyer_account_balance > _option_contract_premuim) {
                //  update account balance
                let new_account_balance: u256 = _option_buyer_account_balance
                    - _option_contract_premuim;
                self.account_balance.entry(option_buyer_address).write(new_account_balance);

                // log options buyer address
                self.emit(Event::ContractLogsAddress(
                            ContractLogAddress { variable: option_buyer_address, msg: 'option_buyer_address' },
                        )
                    );

                // logic to buy options contract
                let mut _updated_options_contract: OptionContract = _option_contract_details;
                _updated_options_contract.option_buyer = option_buyer_address;

                // write updated contract to db
                self.option_contract_map.entry(option_txn_id).write(_updated_options_contract);

                // credit account of options writer with premuim
                let _options_writer: ContractAddress = _updated_options_contract.option_buyer;
                self._credit_balance(_options_writer, _option_contract_premuim);
            }

            if (_option_buyer_account_balance < _option_contract_premuim) {
                self.emit(Event::ContractLogs(
                            ContractLog { variable: (_option_buyer_account_balance < _option_contract_premuim).into(), msg: 'Insufficient funds' },
                        )
                    );
            }
            }

            //assert!(!(_option_buyer_account_balance > _option_contract_premuim), "Deposit not
            //sufficient to buy Options contract");

            
        }

        // compute options pay off
        fn _compute_option_pay_off(
            ref self: ContractState, option_contract: OptionContract,
        ) -> u256 {
            let _option_type_value: felt252 = option_contract.option_type;

            let _option_strike_price_value: u256 = option_contract.strike_price;
            let _underlying_price_value: u256 = self.current_btc_price.read();

            // log _option_type_value
            self.emit(Event::ContractLogs(
                            ContractLog { variable: _option_type_value, msg: '_option_type_value, C or P' },
                        )
                    );

            self.emit(Event::ContractLogsNumber(
                            ContractLogNumber { variable: _option_strike_price_value, msg: '_option_strike_price_value' },
                        )
                    );

            self.emit(Event::ContractLogsNumber(
                            ContractLogNumber { variable: _underlying_price_value, msg: '_underlying_price_value' },
                        )
                    );

            match _option_type_value {
                'C' => call_option_payoff(_option_strike_price_value, _underlying_price_value),
                'P' => put_option_payoff(_option_strike_price_value, _underlying_price_value),
                _ => '',
            }
        }

        fn _update_cash_security(
            ref self: ContractState, option_writer: ContractAddress, amount: u256,
        ) {
            // reduce account balance by cash security amount parameter
            let _current_option_writer_balance: u256 = self
                .account_balance
                .entry(option_writer)
                .read();

            // log current optionwriter balance
            self.emit(Event::ContractLogsNumber(
                            ContractLogNumber { variable: _current_option_writer_balance, msg: '_current_option_writer_balance' },
                        )
                    );

            
            // update account balance of option writer
            self
                .account_balance
                .entry(option_writer)
                .write(_current_option_writer_balance - amount);

            // read current cash security
            let _current_cash_security: u256 = self.cash_security_map.entry(option_writer).read();

            // log _current_cash_security
            self.emit(Event::ContractLogsNumber(
                            ContractLogNumber { variable: _current_cash_security, msg: '_current_cash_security' },
                        )
                    );

            // update cash security balance
            let _new_cash_security: u256 = (_current_cash_security + amount);
            self.cash_security_map.entry(option_writer).write(_new_cash_security);

            // log _new_cash_security
            self.emit(Event::ContractLogsNumber(
                            ContractLogNumber { variable: _new_cash_security, msg: '_new_cash_security' },
                        )
                    );

            // log amount of cash secuirty to add
            self.emit(Event::ContractLogsNumber(
                            ContractLogNumber { variable: amount, msg: 'amount' },
                        )
                    );
        }

        fn _credit_balance(ref self: ContractState, account: ContractAddress, amount: u256) {
            // increase account balance
            let _current_account_balance: u256 = self.account_balance.entry(account).read();
            let _new_account_balance: u256 = _current_account_balance + amount;

            // update account balance
            self.account_balance.entry(account).write(_new_account_balance);
        }

        fn _debit_balance(ref self: ContractState, account: ContractAddress, amount: u256) {
            // increase account balance
            let _current_account_balance: u256 = self.account_balance.entry(account).read();
            let _new_account_balance: u256 = _current_account_balance - amount;

            // update account balance
            self.account_balance.entry(account).write(_new_account_balance);
        }

        fn _update_bitcoin_price(ref self: ContractState, price: u256) {
            self.current_btc_price.write(price);
        }

        fn _settle_option_contract(ref self: ContractState, options_contact_id: u256) {
            // get options contract
            let _option_contract: OptionContract = self
                .option_contract_map
                .entry(options_contact_id)
                .read();
            let _option_writer: ContractAddress = _option_contract.option_writer;
            let _option_buyer:  ContractAddress = _option_contract.option_buyer;

            // compute actual pay off
            let mut _actual_option_payoff: u256 = self._compute_option_pay_off(_option_contract);

            // compute maximum pay off
            let _strike_price: u256 = _option_contract.strike_price;
            let _max_pay_off: u256 = max_payoff(_strike_price);

            // maximum pay off is 2x
            if (_actual_option_payoff > _max_pay_off) {
                _actual_option_payoff = _max_pay_off;
            }

            // populate "pay off" field in options contract, with actual pay off
            let mut updated_option_contract: OptionContract = _option_contract;
            updated_option_contract.pay_off = _actual_option_payoff;

            self.option_contract_map.entry(options_contact_id).write(updated_option_contract);

            self.emit(Event::ContractLogsNumber(
                            ContractLogNumber { variable: options_contact_id, msg: 'options_contact_id' },
                        )
                    );

            self.emit(Event::ContractLogsNumber(
                            ContractLogNumber { variable: _actual_option_payoff, msg: '_actual_option_payoff' },
                        )
                    );

            // deduct "maximum pay off"  from option writer cash security
            let _option_writer_cash_security: u256 = self
                .cash_security_map
                .entry(_option_writer)
                .read();

            if (_option_writer_cash_security >= _max_pay_off) {

               let _new_cash_security: u256 = _option_writer_cash_security - _max_pay_off;
               self.cash_security_map.entry(_option_writer).write(_new_cash_security);

            } else {
                self.emit(Event::ContractLogsNumber(
                            ContractLogNumber { variable: _option_writer_cash_security, msg: '_option_writer_cash_security' },
                        )
                    );

                self.emit(Event::ContractLogsNumber(
                            ContractLogNumber { variable: _max_pay_off, msg: '_max_pay_off' },
                        )
                    );

                self.emit(Event::ContractLogsNumber(
                        ContractLogNumber { variable: 0, msg: 'cash_security !> _max_pay_off' },
                    )
                );
            }


            // credit "actual pay off" to options buyer
            let _option_buyer_account_balance: u256 = self
                .account_balance
                .entry(_option_buyer)
                .read();
            let _new_option_buyer_account_balance: u256 = _option_buyer_account_balance
                + _actual_option_payoff;
            self.account_balance.entry(_option_buyer).write(_new_option_buyer_account_balance);

            // credit "maximum pay off" - "actual pay off" to options writer
            if (_max_pay_off >= _actual_option_payoff) {
                let _residual_payoff: u256 = _max_pay_off - _actual_option_payoff;

                let _current_options_writer_account_balance: u256 = self
                .account_balance
                .entry(_option_writer)
                .read();

                let _new_options_writer_account_balance: u256 = _current_options_writer_account_balance + _residual_payoff;
                self.account_balance.entry(_option_writer).write(_new_options_writer_account_balance)
            } else {

                self.emit(Event::ContractLogsNumber(
                            ContractLogNumber { variable: _option_writer_cash_security, msg: '_option_writer_cash_security' },
                        )
                    );

                self.emit(Event::ContractLogsNumber(
                            ContractLogNumber { variable: _actual_option_payoff, msg: '_actual_option_payoff' },
                        )
                    );

                self.emit(Event::ContractLogsNumber(
                        ContractLogNumber { variable: 0, msg: '_max_pay_off !> _actual_payoff' },
                    )
                );

            }

            
        }

        fn _change_oracle(ref self: ContractState, oracle_contract_address: ContractAddress) {
            self.oracle_contract_address.write(oracle_contract_address);
        }

        // update_usdc_contract_address
        fn _update_usdc_contract_address(
            ref self: ContractState, usdc_contract_address: ContractAddress,
        ) {
            self.usdc_contract_address.write(usdc_contract_address);
        }

        /// Read Operations
        ///

        fn _read_account_balance(self: @ContractState, account_address: ContractAddress) -> u256 {
            self.account_balance.entry(account_address).read()
        }

        fn _list_all_contracts(self: @ContractState) -> Array<(u256, OptionContract)> {
            //list all options contracts
            let mut _all_options_list: Array<(u256, OptionContract)> = ArrayTrait::new();
            let _number_of_option_contracts: u256 = self.option_txn_id_counter.read();

            let mut _counter: u256 = 0;
            while _counter < _number_of_option_contracts {
                // loop over all options contracts
                let _option_contract: OptionContract = self
                    .option_contract_map
                    .entry(_counter)
                    .read();
                _all_options_list.append((_counter, _option_contract));

                _counter += 1;
            }

            _all_options_list
        }

        // // by owner
        // fn _list_all_available_contracts_by_owner(self: @ContractState) -> Array<(u256,
        // OptionContract) {

        // }

        // // by buyer
        // fn list_all_contracts_of_buyer(self: @ContractState){}

        // get option by id
        fn _list_option_contract_by_id(
            self: @ContractState, option_txn_id: u256,
        ) -> OptionContract {
            let _option_contract: OptionContract = self
                .option_contract_map
                .entry(option_txn_id)
                .read();
            _option_contract
        }

        // get cash security of option writer
        fn _get_option_writer_cash_security(self: @ContractState, address: ContractAddress) -> u256 {
            let _option_writer_address: ContractAddress = address;
            let _option_writer_cash_security: u256 = self
                .cash_security_map
                .entry(_option_writer_address)
                .read();
            _option_writer_cash_security
        }

        // read oracle contract
        fn _read_oracle_contract_address(self: @ContractState) -> ContractAddress {
            let _oracle_contract_address: ContractAddress = self.oracle_contract_address.read();
            _oracle_contract_address
        }

        // read btc price
        fn _read_btc_price(self: @ContractState) -> u256 {
            let _btc_price: u256 = self.current_btc_price.read();
            _btc_price
        }

        // read usdc address price
        fn _read_usdc_contract_address(self: @ContractState) -> ContractAddress {
            let _usdc_contract_address: ContractAddress = self.usdc_contract_address.read();
            _usdc_contract_address
        }
    }

    // pure functions that don't need contract state
    fn call_option_payoff(strike_price: u256, underlying_price: u256) -> u256 {
        if (underlying_price >= strike_price) {

            let full_contract_payoff: u256 = (underlying_price - strike_price);
            return (full_contract_payoff / 100);

        } else {
            return 0;
        }
    }

    fn put_option_payoff(strike_price: u256, underlying_price: u256) -> u256 {
        if (strike_price >= underlying_price){

            let full_contract_payoff: u256 = (strike_price - underlying_price);
            return (full_contract_payoff / 100);

        } else {
            return 0;
        }
    }

    fn max_payoff(strike_price: u256) -> u256 {
        return (strike_price / 100);
    }
}
