/// A simple token (Coin) module on Aptos.
module 0xd770607472ef1e29a2f9efe6c9f6c1c87a0c3caec8db23737345ca732a6d002c::MyCoin {

    use std::signer;
    use std::string;
    // Removed unused import 'std::option'.

    use aptos_framework::coin;
    // Fixed: Removed unused import 'aptos_framework::object'.
    // use aptos_framework::object;


    /// The type of the coin. An empty struct is sufficient.
    struct MyCoin has store {}

    /// A resource to hold the mint capability.
    /// This allows only the owner of this resource to mint new tokens.
    struct MintCapStore has key {
        cap: coin::MintCapability<MyCoin>, // Field name is 'cap'
    }

    /// Called automatically when the module is published.
    /// Initializes the coin and stores the mint capability under the deployer's account.
    fun init_module(account: &signer) {
        // Ensure this is called by the correct account (the one defined in Move.toml)
        assert!(signer::address_of(account) == @0xd770607472ef1e29a2f9efe6c9f6c1c87a0c3caec8db23737345ca732a6d002c, 0);

        // Initialize the coin with basic metadata.
        // Adjusted assignment based on compiler error 'provided 3' return values.
        // This implies this version/call of initialize returns (BurnCap, FreezeCap, MintCap).
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<MyCoin>(
            account,                  // Account creating the coin
            string::utf8(b"AptosUSBD"), // Coin name
            string::utf8(b"AUSBD"),     // Coin symbol
            6,                        // Decimals (e.g., 6 for uAPT)
            false                     // Ensure unique symbol
        );
        // Note: The standard initialize *usually* returns 4 capabilities (Burn, Freeze, Store, Mint).
        // The compiler error suggests this specific call is returning only 3.
        // We proceed assuming the return is (BurnCap, FreezeCap, MintCap).
        // The StoreCap is *not* returned here based on your error message.


        // Transfer the MintCapability to the deployer's account as a resource.
        // Only this account can call functions that borrow or move this resource.
        move_to(account, MintCapStore { cap: mint_cap }); // Store in the 'cap' field

        // Destroy or transfer other capabilities if not needed.
        coin::destroy_burn_cap(burn_cap);
        coin::destroy_freeze_cap(freeze_cap);

        // The StoreCap is not returned by initialize based on your compiler errors.
        // We cannot transfer it as it's not declared.
    }

    /// Entry function to mint tokens and deposit them into a recipient's account.
    /// Callable only by the account holding the MintCapStore resource.
    public entry fun mint(
        minter_account: &signer, // The account with the MintCapStore resource (the deployer)
        recipient_address: address, // The address to mint tokens to
        amount: u64 // The amount to mint
    ) acquires MintCapStore {
        // Assert that the caller is the account that holds the MintCapStore resource
        let minter_address = signer::address_of(minter_account);
        assert!(minter_address == @0xd770607472ef1e29a2f9efe6c9f6c1c87a0c3caec8db23737345ca732a6d002c, 1); // Only the deployer can mint

        // Get a reference to the mint capability stored under the minter's account
        let mint_cap_store = borrow_global<MintCapStore>(minter_address);
        let mint_cap = &mint_cap_store.cap; // Access the field named 'cap' in MintCapStore

        // Mint the coins using the capability
        let coins_minted = coin::mint<MyCoin>(amount, mint_cap);

        // Deposit the minted coins into the recipient's account
        // The recipient must have already registered for this coin type using the 'register' function.
        coin::deposit(recipient_address, coins_minted);
    }

    /// Entry function to register a user's account for this coin type.
    /// Must be called by any account that wants to receive this coin.
    public entry fun register(account: &signer) {
        // This uses the coin framework's register function, which handles the CoinStore internally.
        // No 'acquires' annotation is needed on this function because we are calling into the framework.
        coin::register<MyCoin>(account);
    }

    #[view(disable)]
    /// Helper function to get the balance of an account for this coin type.
    /// Not an entry function, typically called by other modules or for testing/views.
    // Fixed: Removed 'acquires coin::CoinStore'. Access is handled by coin::balance.
    public fun balance_of(owner: address): u64 { // Removed acquires annotation here
        // This calls the coin framework's balance function, which handles reading the CoinStore internally.
        coin::balance<MyCoin>(owner)
    }
}