import { connect } from '@starknet-io/get-starknet'; // v4.0.3 min
import { WalletAccount, RpcProvider, Contract, shortString, num } from 'starknet'; // v7.0.1 min

import Mustache from 'mustache';


const node_instance              = 'https://api.zan.top/public/starknet-sepolia/rpc/v0_10' //https://api.zan.top/public/starknet-sepolia/rpc/v0_10';
const cassandra_contract_address = '0x061614391f4da506daf33f7ac70324570f109c937a909608f3c9b640bda62b29'
const usdc_contract_address      = '0x0512feac6339ff7889822cb5aa2a86c848e9d392bb0e3e237c008674feed8343'

const cassandraProvider = new RpcProvider({
  nodeUrl: node_instance,
});

// standard UI to select a wallet:
const selectedWalletSWO = await connect({ modalMode: 'alwaysAsk', modalTheme: 'dark' });

const userWalletAccount = await WalletAccount.connect(
  { 
    nodeUrl: node_instance
   },
  selectedWalletSWO
);

//get contract abi
const cassandra_abi = await cassandraProvider.getClassAt(cassandra_contract_address);
const usdc_abi = await cassandraProvider.getClassAt(usdc_contract_address);


/*
contract instances
*/
const cassandra_contract_call_instance = new Contract({
  abi: cassandra_abi.abi,
  address: cassandra_contract_address, 
  providerOrAccount: cassandraProvider
});

const cassandra_contract_invoke_instance = new Contract({
  abi: cassandra_abi.abi,
  address: cassandra_contract_address, 
  providerOrAccount: userWalletAccount
});

const usdc_contract_invoke_instance = new Contract({
  abi: usdc_abi.abi,
  address: usdc_contract_address, 
  providerOrAccount: userWalletAccount
});


/*
contract call operations
*/
//
// list_all_contracts()
async function list_all_contracts() {
  let value = await cassandra_contract_call_instance.list_all_contracts()
  return value
}

// list_option_contract_by_id(option_txn_id: u256)
async function list_option_contract_by_id(option_txn_id) {
  let value = await cassandra_contract_call_instance.list_option_contract_by_id(option_txn_id)
  return value
}

// get_option_writer_cash_security(address: ContractAddress)
async function get_option_writer_cash_security(address) {
  let value = await cassandra_contract_call_instance.get_option_writer_cash_security(address)
  return value
}

//
// read_account_balance(account_address: ContractAddress)
async function read_account_balance(account_address) {
  let value = await cassandra_contract_call_instance.read_account_balance(account_address)
  return value
}

// read_oracle_contract_address()
async function read_oracle_contract_address() {
  let value = await cassandra_contract_call_instance.read_oracle_contract_address()
  return value

}
// read_btc_price()
async function read_btc_price() {
  let value = await cassandra_contract_call_instance.read_btc_price()
  return value

}
// read_usdc_contract_address()
async function read_usdc_contract_address() {
  let value = await cassandra_contract_call_instance.read_usdc_contract_address()
  return value
}

/*
contract invoke operations
*/

// write_option_contract(option_contract: OptionContract)
async function write_option_contract(option_contract) {
  option_contract.strike_price = (option_contract.strike_price * 1000000)
  option_contract.premium      = (option_contract.premium * 1000000)

  console.log("option_contract", option_contract)

  const _txn_hash  = await cassandra_contract_invoke_instance.write_option_contract(option_contract)
  const result = await cassandraProvider.waitForTransaction(_txn_hash.transaction_hash);

  if (result.isSuccess) {
    await update_total_balance()
    await update_cash_security()
    await update_available_account_balance()
    await update_available_options()
  } else {
    console.log("err")
  }

  return result
}

// buy_option_contract(option_txn_id: u256)
async function buy_option_contract(option_txn_id) {
  const _txn_hash = await cassandra_contract_invoke_instance.buy_option_contract(option_txn_id)
  const result = await cassandraProvider.waitForTransaction(_txn_hash.transaction_hash);

  if (result.isSuccess) {
      await update_total_balance()
      await update_cash_security()
      await update_available_account_balance()
      await update_available_options()
  } else {
    console.log('err')
  }
  return result
}

// deposit_usdc(amount: u256)
async function deposit_usdc(amount) {
  //amount * (10**6)
  const _txn_hash = await cassandra_contract_invoke_instance.deposit_usdc((amount * (10**6)))
  const result = await cassandraProvider.waitForTransaction(_txn_hash.transaction_hash);

  if (result.isSuccess) {
    // update account balance
    await update_total_balance()
    await update_available_account_balance()
  } else {
    console.log('err')
  }

  return result
}

//
// withdraw_usdc(amount: u256)
async function withdraw_usdc(amount) {
  // amount * (10**6)
  const _txn_hash = await cassandra_contract_invoke_instance.withdraw_usdc(amount * (10**6))
  const result    = await cassandraProvider.waitForTransaction(_txn_hash.transaction_hash);

  if (result.isSuccess) {
    // update account balance 
    await update_total_balance()
    await update_available_account_balance()  } else {
    console.log('err')
  }
  
}

// update_bitcoin_price(price: u256)
async function update_bitcoin_price(price) {
  // price * (10**6)
  const _txn_hash = await cassandra_contract_invoke_instance.update_bitcoin_price((price/100) * (10**6))
  const result = await cassandraProvider.waitForTransaction(_txn_hash.transaction_hash);
  return result
}

// settle_contract(option_txn_id: u256)
async function settle_contract(option_txn_id) {
  const _txn_hash = await cassandra_contract_invoke_instance.settle_contract(option_txn_id)
  const result = await cassandraProvider.waitForTransaction(_txn_hash.transaction_hash);
  if (result.isSuccess) {
    // update settlement prices
    await update_btc_settlement_prices_on_website()
    await update_total_balance()
    await update_cash_security()
    await update_available_account_balance()
  }
  return result
}

// change_oracle(oracle: ContractAddress)
async function change_oracle(oracle) {
  const _txn_hash = await cassandra_contract_invoke_instance.change_oracle(oracle)
  const result = await cassandraProvider.waitForTransaction(_txn_hash.transaction_hash);
  return result
}

// update_usdc_contract_address(usdc_contract_address: ContractAddress)
async function update_usdc_contract_address(usdc_contract_address) {
  const  _txn_hash  = await cassandra_contract_invoke_instance.update_usdc_contract_address(usdc_contract_address)
  const result = await cassandraProvider.waitForTransaction(_txn_hash.transaction_hash);
  return result
}


// 
// usdc_erc20.approve(this_contract, amount)
async function approve_usdc_deposit(cassandra_contract_address, amount) {
  // amount * 10^6
  const transaction_hash = await usdc_contract_invoke_instance.approve(cassandra_contract_address, ((amount)*(10**6)))
  // console.log("transaction_hash", transaction_hash.transaction_hash)

  const result = await cassandraProvider.waitForTransaction(transaction_hash.transaction_hash);

  if (result.isSuccess()) {
    // make deposit 
    await deposit_usdc(amount)
    return "deposit sucessfully made"

  } else {
    return "Transaction Error"
  }
}

// get_btc_index_price
async function get_btc_index_price() {
  try {
    const response = await fetch('https://fapi.binance.com/fapi/v1/premiumIndex?symbol=BTCUSDC');
    
    if (!response.ok) {
     return 71000
    }

    const data = await response.json(); 
    return parseInt(data.indexPrice);     
    
  } catch (error) {
    return 71000
  }
}


/*
Update front end data
*/
async function update_btc_prices_on_website(){
      const latest_price = await get_btc_index_price()
      const price_element = document.querySelectorAll('.current-btc-price');

      // update
      price_element.forEach(el => {
        el.textContent = latest_price.toLocaleString(); 
      });
}
await update_btc_prices_on_website()
setInterval(update_btc_prices_on_website, 5000)

//read_btc_price
async function update_btc_settlement_prices_on_website(){
      const latest_price = await read_btc_price()
      const price_element = document.getElementById('current-btc-settlement-price');

      // update
      price_element.textContent = (Number(latest_price)/(10**6)).toLocaleString(); 
}
await update_btc_settlement_prices_on_website()
// setInterval(update_btc_settlement_prices_on_website, 5000)

async function update_available_account_balance(){
      const value = await read_account_balance(userWalletAccount.address)
      const element = document.querySelectorAll('#available-balance');

      // update
      element.forEach(el => {
        el.textContent = (Number(value)/1000000).toLocaleString(); 
      });
}
await update_available_account_balance()
// setInterval(update_available_account_balance, 5000)

async function update_cash_security(){
      const value = await get_option_writer_cash_security(userWalletAccount.address)
      const element = document.querySelectorAll('#locked-balance');

      // update
      element.forEach(el => {
        el.textContent = (Number(value)/1000000).toLocaleString(); 
      });
}
await update_cash_security()
// setInterval(update_cash_security, 5000)


async function update_total_balance(){
      const cash_security_value = await get_option_writer_cash_security(userWalletAccount.address)
      const balance_value = await read_account_balance(userWalletAccount.address)
      const value = cash_security_value + balance_value

      const element = document.querySelectorAll('#total-balance');

      // update
      element.forEach(el => {
        el.textContent = (Number(value)/1000000).toLocaleString(); 
      });
}
await update_total_balance()
// setInterval(update_total_balance, 5000)

async function update_available_options(){
      const value = await list_all_contracts()

      const options_table = document.getElementById('available-options-list');
  
      let available_options_list = []

      // format & filter options
      for (let index = 0; index < value.length; index++) {
        const element = value[index];

        const options_id = element[0]
        const option_details = element[1]

        const decimals = 10**6

        //shortString.decodeShortString()

        const decoded_options_contract = {
          options_id: Number(options_id), 

          // strings
          expiry : shortString.decodeShortString((option_details.expiry)),
          option_type:   shortString.decodeShortString(Number(option_details.option_type)),

          // Contract addresses
          option_buyer:  num.toHex(option_details.option_buyer),
          option_writer: num.toHex(option_details.option_writer),

          pay_off: Number(option_details.pay_off)/decimals,
          premium: Number(option_details.premium)/decimals,
          strike_price: Number(option_details.strike_price)/decimals
        }

        if (decoded_options_contract['option_buyer'] == '0x0') {
          available_options_list.push(decoded_options_contract)
        }

      }

     // generate table with mustache
     const available_options_table_template = `
      {{#options_list}}
        <tr>
            <th>
            <a class="option-buy-link"  href="#" style="color: #029764; text-decoration: none;" data-id="{{options_id}}">
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 48 48"><g fill="none" stroke="currentColor" stroke-width="4"><path stroke-linejoin="round" d="M6 15h36l-2 27H8z" clip-rule="evenodd" /><path stroke-linecap="round" stroke-linejoin="round" d="M16 19V6h16v13" /><path stroke-linecap="round" d="M16 34h16" /></g></svg> 
            BUY</a>
            </th>

            <th scope="row">{{ expiry }}</th>
            <td> \${{ premium }} </td>
            <td>  {{ option_type }} </td>
            <td> \${{ strike_price }}</td>
        </tr>
      {{/options_list}}
     `

    const rendered_html_table = Mustache.render(available_options_table_template, { options_list: available_options_list })

    //console.log(rendered_html_table)

    options_table.innerHTML = rendered_html_table;

    await buy_option_link_events()

    return available_options_list

}

await update_available_options()
// setInterval(update_available_options, 5000)

async function update_unsettled_options_contracts() {
    const value = await list_all_contracts()
    const unsettled_options_list_container = document.getElementById('unsettled-options-list');
  
    let unsettled_options_list = []

       // format & filter options
      for (let index = 0; index < value.length; index++) {
        const element = value[index];

        const options_id = element[0]
        const option_details = element[1]

        const decimals = 10**6

        //shortString.decodeShortString()

        const decoded_options_contract = {
          options_id: Number(options_id), 

          // strings
          expiry : shortString.decodeShortString((option_details.expiry)),
          option_type:   shortString.decodeShortString(Number(option_details.option_type)),

          // Contract addresses
          option_buyer:  num.toHex(option_details.option_buyer),
          option_writer: num.toHex(option_details.option_writer),

          pay_off: Number(option_details.pay_off)/decimals,
          premium: Number(option_details.premium)/decimals,
          strike_price: Number(option_details.strike_price)/decimals
        }

        if ((decoded_options_contract['pay_off'] == '0')) {
          unsettled_options_list.push(decoded_options_contract)
        }

        //console.log(unsettled_options_list)
      }

      const unsettled_options_table_template = `
      {{#options_list}}
        <ul>
          <li><b>options_id: {{options_id}}</b></li>
        
          <!--<li>expiry:    {{expiry}}</li>
          <li>option_type:   {{option_type}}</li>
          <li>option_buyer:  {{option_buyer}}</li>
          <li>option_writer: {{option_writer}}</li>
          <li>pay_off:       {{pay_off}}</li>
          <li>premium:       {{premium}}</li>
          <li>strike_price:  {{strike_price}}</li> -->
        </ul>
      {{/options_list}}
      `
      const rendered_html_list = Mustache.render(unsettled_options_table_template, { options_list: unsettled_options_list })

      unsettled_options_list_container.innerHTML = rendered_html_list;

      // .insertAdjacentHTML('beforeend', `<li>New Item</li>`)
}

await update_unsettled_options_contracts()

/*
click events
*/
// buy option links

async function buy_option_link_events() {
  const option_buy_links = document.querySelectorAll('.option-buy-link');

  option_buy_links.forEach(option_buy_links => {
      option_buy_links.addEventListener('click', async function(event) {
          event.preventDefault();

          // 'this' refers to the element that was clicked
          const option_txn_id = this.dataset.id;

          console.log('option_txn_id', option_txn_id)

          await buy_option_contract(option_txn_id)

      });
  });
}

await buy_option_link_events()




//  write option button
const write_option_form = document.getElementById('options-details-form');

write_option_form.addEventListener('submit', async function(event) {
    event.preventDefault();

    const formData = new FormData(write_option_form);
    const data     = Object.fromEntries(formData.entries());

    const options_details = {
      expiry:       data.expiry_date,
      option_type:  data.option_type,
      strike_price: (data.strike_price/100),
      premium:      data.option_premium,

      // initialise to 0
      option_buyer: 0,
      option_writer: 0,
      pay_off: 0
    }
    // write option
    await write_option_contract(options_details)

});

// Deposit USDC
const deposit_usdc_button = document.getElementById('deposit-usdc-button');

// open dialogue
deposit_usdc_button.addEventListener('click', async function(event) {
    event.preventDefault();

    const depositDialog = document.getElementById('deposit-usdc-dialog');
    depositDialog.showModal();
});

// close deposit dialoge
const close_deposit_dialogue_button = document.getElementById('deposit-cancel-button');
close_deposit_dialogue_button.addEventListener('click', async function(event) {
    event.preventDefault();

    const depositDialog = document.getElementById('deposit-usdc-dialog');
    depositDialog.close();
});

// confirm deposit
const confirm_deposit_dialogue_button = document.getElementById('deposit-confirm-button');
confirm_deposit_dialogue_button.addEventListener('click', async function(event) {
    event.preventDefault();

    // close dialogue
    const depositDialog = document.getElementById('deposit-usdc-dialog');
    depositDialog.close();

    // confirm withdraw
    // form data
    const deposit_form_data = new FormData(document.getElementById('deposit-form')); 
    const data   = Object.fromEntries(deposit_form_data.entries());
    const amount = data.deposit_amount

    await approve_usdc_deposit(cassandra_contract_address, amount)
});

// Withdraw USDC
const withdraw_usdc_button = document.getElementById('withdraw-usdc-button');

// open dialogue
withdraw_usdc_button.addEventListener('click', async function(event) {
    event.preventDefault();

    const withdrawDialog = document.getElementById('withdraw-usdc-dialog');
    withdrawDialog.showModal();
});

// close withdraw dialoge
const close_withdraw_dialogue_button = document.getElementById('withdraw-cancel-button');
close_withdraw_dialogue_button.addEventListener('click', async function(event) {
    event.preventDefault();

    const withdrawDialog = document.getElementById('withdraw-usdc-dialog');
    withdrawDialog.close();
});

// confirm withdraw
const confirm_withdraw_dialogue_button = document.getElementById('withdraw-confirm-button');
confirm_withdraw_dialogue_button.addEventListener('click', async function(event) {
    event.preventDefault();

    // close dialogue
    const withdrawDialog = document.getElementById('withdraw-usdc-dialog');
    withdrawDialog.close();

    // confirm withdraw
    // form data
    const withdraw_form_data = new FormData(document.getElementById('withdraw-form')); 

    const data = Object.fromEntries(withdraw_form_data.entries());

    const amount = data.withdraw_amount

    console.log("withdraw amount", amount)

    await withdraw_usdc(amount)
});

// settle options contract
const settle_option_form = document.getElementById('settle-options-contract-form');

settle_option_form.addEventListener('submit', async function(event) {
    event.preventDefault();

    const formData = new FormData(settle_option_form);
    const data     = Object.fromEntries(formData.entries());

    // get btc price & update settlement price
    const current_btc_price = await get_btc_index_price()
    await update_bitcoin_price(current_btc_price)

    await settle_contract(parseInt(data.option_id))

});




/*
Front end function calls
*/

// make deposit
// await approve_usdc_deposit(cassandra_contract_address, 20)

// // read_account_balance
// const account_balance_1 = await read_account_balance(userWalletAccount.address)
// console.log("account_balance_1", account_balance_1)

//get_option_writer_cash_security(address: ContractAddress)
// const writer_security1 = await get_option_writer_cash_security(userWalletAccount.address)
// console.log("writer_security1", writer_security1)

//write_option_contract
// await write_option_contract({
//   expiry: "2026-MAR-31",
//   option_type: "C",
//   strike_price: 50,
//   premium: 5,
//   option_buyer: 0,
//   option_writer: 0,
//   pay_off: 0
// })


// buy_option_contract
// await buy_option_contract(2)

// await settle_contract(2)

// list_option_contract_by_id
// const list_option_by_id = await list_option_contract_by_id(0)
// console.log("list_option_by_id", list_option_by_id)

// const writer_security2 = await get_option_writer_cash_security(userWalletAccount.address)
// console.log("writer_security2", writer_security2)


// // read_account_balance
// const account_balance = await read_account_balance(userWalletAccount.address)
// console.log("account_balance_2", account_balance)

// const options_list = await list_all_contracts()
// console.log("options_list", options_list)

// await withdraw_usdc(5);

//read_btc_price
// let btc_price1 = await read_btc_price()
// console.log("btc_price1", btc_price1)

// // update_bitcoin_price
// await update_bitcoin_price(600)

// // read 
// let btc_price2 = await read_btc_price()
// console.log("btc_price2", btc_price2)

// userWalletAccount.address
// console.log("userWalletAccount.address",userWalletAccount.address)





